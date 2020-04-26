/* SOC DRIVER
  For all 8 motors with python serial communication
  Uses external interrupts for encoders 3-8, pin change interrupts for 1 & 2 
  No motor sleep function incorporated 

     * Serial Communication Mini-language
     * From GUI:
     * - to set leaflet position: magic 2-bytes followed by 2-byte integer positions for each leaflet
     *    Ex. To set leaflets to (0,0,100,50,25,200,120,400)
     *      will send: 0xFF,0xD7,0x00,0x00,0x00,0x00,0x00,0x64,0x00,0x32,0x00,0x19,0x00,0xC8,0x00,0x78,0x01,0x90
     *      (2 for each leaf position - signed 2's complement)
     *  - to initiate leaf calibration: magic bytes followed by 0xB3   
     *  To GUI:
     *  - successful leaf repositioning: send 0xA0 
     *  - hardware error: send 0xA1
     */

    #define DEBUG
 
//Declare pin functions on Arduino MEGA 2560
    //Motor 1
    #define dir_1 33
    #define stp_1 31
    #define ms2_1 29
    #define en_1  27
    #define ms1_1 25

    //Motor 2
    #define dir_2 32
    #define stp_2 30
    #define ms2_2 28
    #define en_2  26
    #define ms1_2 24
  
    //Motor 3
    #define dir_3 43
    #define stp_3 41
    #define ms2_3 39
    #define en_3  37
    #define ms1_3 35
   
    //Motor 4
    #define dir_4 42
    #define stp_4 40
    #define ms2_4 38
    #define en_4  36
    #define ms1_4 34

    //Motor 5
    #define dir_5 A4
    #define stp_5 A3
    #define ms2_5 A2
    #define en_5  A1
    #define ms1_5 A0  

    //Motor 6
    #define dir_6 53
    #define stp_6 51
    #define ms2_6 49
    #define en_6  47
    #define ms1_6 45
    
    //Motor 7
    #define dir_7 52
    #define stp_7 50
    #define ms2_7 48
    #define en_7  46
    #define ms1_7 44

    //Motor 8
    #define dir_8 A15
    #define stp_8 A14
    #define ms2_8 A13
    #define en_8  A12
    #define ms1_8 A11
  
    #include <Encoder.h>
    //Pin change interrupts
    Encoder enc1(12,13); 
    Encoder enc2(14,15);
    //External interrupts
    Encoder enc3(3,17); 
    Encoder enc4(2,16); 
    Encoder enc5(19,5); 
    Encoder enc6(18,4); 
    Encoder enc7(21,7);
    Encoder enc8(20,6);  

    //PORTB pins; 
    #define enc1a 12 //PB6 (PCINT6)
    #define enc1b 13 //PB7 (PCINT7)

    //PORTJ pins; 
    #define enc2a 14 //PJ1 (PCINT10)
    #define enc2b 15 //PJ0 (PCINT9)

  //Define signals for GUI communication
    #define MAGIC1 0xFF //magic 2-bytes sent by GUI before every command
    #define MAGIC2 0xD7
    #define PRE_ABSPOS_ONE 0xB1 //if sending just one leaf position - not incorporated
    #define PRE_ABSPOS_ALL 0xB2 //if sending all leaf positions (default)
    #define PRE_CALIBRATE  0xB3 //signals that leaves have been calibrated to "zero"
    #define SIG_MOVE_OK    0xA0 //send to GUI after successful leaf repositioning
    #define SIG_HWERROR    0xA1 //send to GUI in case of hardware error
  
  //Declare variables for functions
    int motor1;
    int motor2;
    int motor3;
    int motor4;
    int motor5;
    int motor6;
    int motor7;
    int motor8;
    int m1_last;
    int m2_last;
    int m3_last;
    int m4_last;
    int m5_last;
    int m6_last;
    int m7_last;
    int m8_last;
    volatile int pos1;
    volatile int pos2;
    int pos3;
    int pos4;
    int pos5;
    int pos6;
    int pos7;
    int pos8;
    int m1_stpTaken;
    int m2_stpTaken;
    int m3_stpTaken;
    int m4_stpTaken;
    int m5_stpTaken;
    int m6_stpTaken;
    int m7_stpTaken;
    int m8_stpTaken;
    int m1_init;
    int m2_init;
    int m3_init;
    int m4_init;
    int m5_init;
    int m6_init;
    int m7_init;
    int m8_init;
    unsigned char bufIn[19];
    int leafCollision; 
    int sensorAgreement=1;
    int n;
  
    int totalStepsUpper=5200;
    int totalStepsLower=5400;
  
    
  //SETUP
  
  void setup() {

    SetOutputPins(stp_1, dir_1, ms1_1, ms2_1, en_1);  //Set pins to output mode for control
    SetOutputPins(stp_2, dir_2, ms1_2, ms2_2, en_2);
    SetOutputPins(stp_3, dir_3, ms1_3, ms2_3, en_3);
    SetOutputPins(stp_4, dir_4, ms1_4, ms2_4, en_4);
    SetOutputPins(stp_5, dir_5, ms1_5, ms2_5, en_5);
    SetOutputPins(stp_6, dir_6, ms1_6, ms2_6, en_6);
    SetOutputPins(stp_7, dir_7, ms1_7, ms2_7, en_7);
    SetOutputPins(stp_8, dir_8, ms1_8, ms2_8, en_8);

    EnablePCInterrupts();
    ZeroEncoders();  //Set encoder positions to "home"   
    Reset();  //Set step, direction, microstep and enable pins to default states
    Serial.begin(115200);
  }

  //LOOP
  
  void loop() {
    if (Serial.readBytes(bufIn, 1)) {
      DigWriteAllEn(LOW); //Pull enable pins low to allow motor control
      
      if (bufIn[0] == MAGIC1 && Serial.readBytes(&bufIn[1], 1)) {      
        if (bufIn[1] == MAGIC2 && Serial.readBytes(&bufIn[2], 1)) { //If magic number received from GUI
          if (bufIn[2] == PRE_ABSPOS_ALL && Serial.readBytes(&bufIn[3], 16)) {  //If leaf position command received
            #ifdef DEBUG
              Serial.println("Leaf positions received");
            #endif
            motor1 = (uint16_t)( (bufIn[3]<<8)|(bufIn[4]) );
            motor2 = (uint16_t)( (bufIn[5]<<8)|(bufIn[6]) );
            motor3 = (uint16_t)( (bufIn[7]<<8)|(bufIn[8]) );
            motor4 = (uint16_t)( (bufIn[9]<<8)|(bufIn[10]) );
            motor5 = (uint16_t)( (bufIn[11]<<8)|(bufIn[12]) );
            motor6 = (uint16_t)( (bufIn[13]<<8)|(bufIn[14]) );
            motor7 = (uint16_t)( (bufIn[15]<<8)|(bufIn[16]) );
            motor8 = (uint16_t)( (bufIn[17]<<8)|(bufIn[18]) );
            motor1 = motor1*5.2;
            motor2 = motor2*5.2;
            motor3 = motor3*5.3;
            motor4 = motor4*5.3;
            motor5 = motor5*5.2;
            motor6 = motor6*5.2;
            motor7 = motor7*5.3;
            motor8 = motor8*5.3;
            
            #ifdef DEBUG
              Serial.println(motor1);
              Serial.println(motor2);
              Serial.println(motor3);
              Serial.println(motor4);
              Serial.println(motor5);
              Serial.println(motor6);
              Serial.println(motor7);
              Serial.println(motor8);
            #endif
            
            //Check if new positions will cause collision
            if ((motor1+motor6<=totalStepsUpper) && (motor2+motor5<=totalStepsUpper) && (motor3+motor8<=totalStepsLower) && (motor4+motor7<=totalStepsLower)) {
              
             MoveLeavesToPosition(motor1, motor2, motor3, motor4, motor5, motor6, motor7, motor8);
            #ifdef DEBUG
              Serial.println("New encoder positions:");
              Serial.println(pos1);
              Serial.println(pos2);
              Serial.println(pos3);
              Serial.println(pos4);
              Serial.println(pos5);
              Serial.println(pos6);
              Serial.println(pos7);
              Serial.println(pos8);
            #endif
  
              //CheckSensorAgreement();
              if (sensorAgreement==1) { //change to "if no time out"
                SendSignal(SIG_MOVE_OK); //Send confirmation of successful leaf respositioning
                #ifdef DEBUG
                  Serial.println("Wooh, leaves moved successfully!");
                #endif
              }
              else {
                SendSignal(SIG_HWERROR); //Send error message - unsuccessful leaf repositioning
                #ifdef DEBUG
                  Serial.println("Oh no, there was a leaf positioning error...");
                #endif         
              }
            }  
            else {
              SendSignal(SIG_HWERROR);  //Send error message - new leaf positions will cause a potential collision
              #ifdef DEBUG
                Serial.println("Oops, those new leaf positions may cause a collision.");
              #endif
            }
          }
  
          else if (bufIn[2] == PRE_CALIBRATE) { //&& Serial.readBytes(&bufIn[3], 16)) { //If leaf calibration command received
            ZeroEncoders();
            SendSignal(SIG_MOVE_OK); //Send confirmation of successful leaf homing 
            #ifdef DEBUG
              Serial.println("Wooh, leaves calibrated successfully!");
            #endif  
          }
        }   
      }    
      Reset();
    }  
  }  
  

//PC INTERRUPTS
  ISR (PCINT0_vect) { //handle pin change interrupt for encoder 1
    pos1 = enc1.read();
  }
  ISR (PCINT1_vect) { //handle pin change interrupt for encoder 2 
    pos2 = enc2.read();
  }


//FUNCTIONS

  void SetOutputPins(int stp_motor, int dir_motor, int ms1_motor, int ms2_motor, int en_motor) {
    pinMode(stp_motor, OUTPUT);
    pinMode(dir_motor, OUTPUT);
    pinMode(ms1_motor, OUTPUT);
    pinMode(ms2_motor, OUTPUT);
    pinMode(en_motor, OUTPUT);
  }

  //Enable pin change interrupts on pins for encoders 1 and 2
  void EnablePCInterrupts() {
    pinMode(enc1a, INPUT_PULLUP); 
    pinMode(enc1b, INPUT_PULLUP);
    pinMode(enc2a, INPUT_PULLUP); 
    pinMode(enc2b, INPUT_PULLUP);

    PCICR |= (1<<PCIE0);//enable group interrupts on PORTB
    PCMSK0 |= (1<<PCINT6);//enable interrupt pin 12
    PCMSK0 |= (1<<PCINT7);//enable interrupt pin 13

    PCICR |= (1<<PCIE1);//enable group interrupts on PORTJ
    PCMSK1 |= (1<<PCINT10);//enable interrupt pin 14
    PCMSK1 |= (1<<PCINT9);//enable interrupt pin 15
  }

  //Set last leaf position values and encoder positions to zero ("home" - open square)
  void ZeroEncoders() {
    enc1.write(0);
    enc2.write(0); 
    enc3.write(0); 
    enc4.write(0); 
    enc5.write(0); 
    enc6.write(0); 
    enc7.write(0); 
    enc8.write(0); 
  }

  //Reset pins to default states and step tallies to zero
  void Reset() {
    DigWriteAllStp(LOW); //LOW -> HIGH triggers one step
    DigWriteAllEn(HIGH); //Disabled - set to LOW to allow motor control

    m1_stpTaken=0;
    m2_stpTaken=0;
    m3_stpTaken=0;
    m4_stpTaken=0;
    m5_stpTaken=0;
    m6_stpTaken=0;
    m7_stpTaken=0;
    m8_stpTaken=0;
  }

  //Set step for all motors
  void DigWriteAllStp(int state) {
    digitalWrite(stp_1, state);
    digitalWrite(stp_2, state);
    digitalWrite(stp_3, state);
    digitalWrite(stp_4, state);
    digitalWrite(stp_5, state);
    digitalWrite(stp_6, state);
    digitalWrite(stp_7, state);
    digitalWrite(stp_8, state);
  }
  
  //Set direction for all motors
  void DigWriteAllDir(int state) {
    digitalWrite(dir_1, state);
    digitalWrite(dir_2, state);
    digitalWrite(dir_3, state);
    digitalWrite(dir_4, state);
    digitalWrite(dir_5, state);
    digitalWrite(dir_6, state);
    digitalWrite(dir_7, state);
    digitalWrite(dir_8, state);
  }

  //Set MS1 for all motors
  void DigWriteAllMS1(int state) {
    digitalWrite(ms1_1, state);
    digitalWrite(ms1_2, state);
    digitalWrite(ms1_3, state);
    digitalWrite(ms1_4, state);
    digitalWrite(ms1_5, state);
    digitalWrite(ms1_6, state);
    digitalWrite(ms1_7, state);
    digitalWrite(ms1_8, state);
  }
  
  //Set MS2 for all motors
  void DigWriteAllMS2(int state) {
    digitalWrite(ms2_1, state);
    digitalWrite(ms2_2, state);
    digitalWrite(ms2_3, state);
    digitalWrite(ms2_4, state);
    digitalWrite(ms2_5, state);
    digitalWrite(ms2_6, state);
    digitalWrite(ms2_7, state);
    digitalWrite(ms2_8, state);
  }
  
  //Set EN for all motors
  void DigWriteAllEn(int state) {
    digitalWrite(en_1, state);
    digitalWrite(en_2, state);
    digitalWrite(en_3, state);
    digitalWrite(en_4, state);
    digitalWrite(en_5, state);
    digitalWrite(en_6, state);
    digitalWrite(en_7, state);
    digitalWrite(en_8, state);
  }

  //Move motor one 1/8 step forward
  void EighthStepForward(int dir_motor, int stp_motor, int ms1_motor, int ms2_motor) {
    digitalWrite(dir_motor, LOW);
    digitalWrite(ms1_motor, HIGH);
    digitalWrite(ms2_motor, HIGH);
    digitalWrite(stp_motor,HIGH); //Trigger motor one step forward
    delayMicroseconds(300);
    digitalWrite(stp_motor,LOW); //Pull step pin low so it can be triggered again
    delayMicroseconds(300); 
  }
  
  //Move motor one full step forward
  void FullStepForward(int dir_motor, int stp_motor, int ms1_motor, int ms2_motor) {
    digitalWrite(dir_motor, LOW);
    digitalWrite(ms1_motor, LOW);
    digitalWrite(ms2_motor, LOW);
    digitalWrite(stp_motor,HIGH); //Trigger motor one step forward
    delayMicroseconds(300);
    digitalWrite(stp_motor,LOW); //Pull step pin low so it can be triggered again
    delayMicroseconds(300); 
  }

  //Move motor one 1/8 step backward
  void EighthStepReverse(int dir_motor, int stp_motor, int ms1_motor, int ms2_motor) {
    digitalWrite(dir_motor, HIGH);
    digitalWrite(ms1_motor, HIGH);
    digitalWrite(ms2_motor, HIGH);
    digitalWrite(stp_motor,HIGH); //Trigger motor one step forward
    delayMicroseconds(300);
    digitalWrite(stp_motor,LOW); //Pull step pin low so it can be triggered again
    delayMicroseconds(300); 
  }

  //Move motor one full step backward
  void FullStepReverse(int dir_motor, int stp_motor, int ms1_motor, int ms2_motor) {
    digitalWrite(dir_motor, HIGH);
    digitalWrite(ms1_motor, LOW);
    digitalWrite(ms2_motor, LOW);
    digitalWrite(stp_motor,HIGH); //Trigger motor one step forward
    delayMicroseconds(300);
    digitalWrite(stp_motor,LOW); //Pull step pin low so it can be triggered again
    delayMicroseconds(300); 
  }
 
  //Get encoder positions
  void ReadEncoders() {
    pos1 = enc1.read();
    pos2 = enc2.read();
    pos3 = enc3.read();
    pos4 = enc4.read();
    pos5 = enc5.read();
    pos6 = enc6.read();
    pos7 = enc7.read();
    pos8 = enc8.read();
  }

  //Move leaf a single step
  int SingleStep(int m, int pos, int dir_motor, int stp_motor, int ms1_motor, int ms2_motor) {
    int diff = m-pos;
    if (diff>=10) {  //if leaf travel distance is large (and forward)
      FullStepForward(dir_motor, stp_motor, ms1_motor, ms2_motor);  
      return 8; //return steps taken (units of positive eighth steps)
    }
    else if ((diff>0) && (diff<10)) { //if leaf travel distance is small (and forward)
      EighthStepForward(dir_motor, stp_motor, ms1_motor, ms2_motor);
      return 1;
    }
    else if (diff<=-10) { //if leaf travel distance is large (and backward)
      FullStepReverse(dir_motor, stp_motor, ms1_motor, ms2_motor);
      return -8;
    }
    else if ((diff<0) && (diff>-10)) { //if leaf travel distance is small (and backward)
      EighthStepReverse(dir_motor, stp_motor, ms1_motor, ms2_motor);
      return -1;
    }
  }

  //Move leaves to new position
  void MoveLeavesToPosition(int m1, int m2, int m3, int m4, int m5, int m6, int m7, int m8) {
    ReadEncoders();
    m1_init = pos1; //Save initial leaf positions
    m2_init = pos2;
    m3_init = pos3;
    m4_init = pos4;
    m5_init = pos5;
    m6_init = pos6;
    m7_init = pos7;
    m8_init = pos8;

    int done=0;
    int a=0;
    int n;
  
    while(done==0) {  //step each motor consecutively until all encoder positions are correct
      if (abs(pos1-m1)>10){  
        n = SingleStep(m1, pos1, dir_1, stp_1, ms1_1, ms2_1);
        m1_stpTaken = m1_stpTaken+n;
        a=a+1;
      }
      if (abs(pos2-m2)>10){  
        n = SingleStep(m2, pos2, dir_2, stp_2, ms1_2, ms2_2);
        m2_stpTaken = m2_stpTaken+n;
        a=a+1;
      }
      if (abs(pos3-m3)>10){  
        n = SingleStep(m3, pos3, dir_3, stp_3, ms1_3, ms2_3);
        m3_stpTaken = m3_stpTaken+n;
        a=a+1;
      }
      if (abs(pos4-m4)>10){  
        n = SingleStep(m4, pos4, dir_4, stp_4, ms1_4, ms2_4);
        m4_stpTaken = m4_stpTaken+n;
        a=a+1;
      }
      if (abs(pos5-m5)>10){  
        n = SingleStep(m5, pos5, dir_5, stp_5, ms1_5, ms2_5);
        m5_stpTaken = m5_stpTaken+n;
        a=a+1;
      }
      if (abs(pos6-m6)>10){  
        n = SingleStep(m6, pos6, dir_6, stp_6, ms1_6, ms2_6);
        m6_stpTaken = m6_stpTaken+n;
        a=a+1;
      }
      if (abs(pos7-m7)>10){  
        n = SingleStep(m7, pos7, dir_7, stp_7, ms1_7, ms2_7);
        m7_stpTaken = m7_stpTaken+n;
        a=a+1;
      }
      if (abs(pos8-m8)>10){  
        n = SingleStep(m8, pos8, dir_8, stp_8, ms1_8, ms2_8);
        m8_stpTaken = m8_stpTaken+n;
        a=a+1;
      }
      if (a==0){
        done=1;
        break;
      }
      ReadEncoders();
      a=0;
    }
  }

//  //Make sure number of steps taken agrees (roughly) with difference in encoder position - NEED TO TEST!
//  void CheckSensorAgreement() {
//    sensorAgreement=1;
//    
//    float cps1 = (float)(pos1-m1_init)/m1_stpTaken; //Counts (encoder) per step (motor) - should be about 1.25
//    float cps2 = (float)(pos2-m2_init)/m2_stpTaken;
//    float cps3 = (float)(pos3-m3_init)/m3_stpTaken;
//    float cps4 = (float)(pos4-m4_init)/m4_stpTaken;
//    float cps5 = (float)(pos5-m5_init)/m5_stpTaken;
//    float cps6 = (float)(pos6-m6_init)/m6_stpTaken;
//    float cps7 = (float)(pos7-m7_init)/m7_stpTaken;
//    float cps8 = (float)(pos8-m8_init)/m8_stpTaken;
//
//    if ((cps1<cps_min) or (cps1>cps_max)){  //If cps outside normal range, set sensor agreement to false
//      sensorAgreement=0;
//    }
//    if ((cps2<cps_min) or (cps2>cps_max)){
//      sensorAgreement=0;
//    }
//    if ((cps3<cps_min) or (cps3>cps_max)){
//      sensorAgreement=0;
//    }
//    if ((cps4<cps_min) or (cps4>cps_max)){
//      sensorAgreement=0;
//    }
//    if ((cps5<cps_min) or (cps5>cps_max)){
//      sensorAgreement=0;
//    }
//    if ((cps6<cps_min) or (cps6>cps_max)){
//      sensorAgreement=0;
//    }
//    if ((cps7<cps_min) or (cps7>cps_max)){
//      sensorAgreement=0;
//    }
//    if ((cps8<cps_min) or (cps8>cps_max)){
//      sensorAgreement=0;
//    }
//  }

  //Send signal to GUI (for confirmation or error)
  void SendSignal(byte signal) {
    byte buf[2] = {signal, 0x00};
    Serial.write(buf,2);
  }

    
    
