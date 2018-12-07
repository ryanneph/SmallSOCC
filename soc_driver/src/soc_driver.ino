#include <Adafruit_CircuitPlayground.h>
#include <math.h>

#define MAGIC1 0xFF
#define MAGIC2 0xD7

#define PRE_ABSPOS_ONE 0xB1
#define PRE_ABSPOS_ALL 0xB2
#define PRE_CALIBRATE  0xB3

#define SIG_MOVE_OK    0xA0
#define SIG_HWERROR    0xA1

int time_to_error = 5;

void setup() {
    Serial.begin(115200);
    CircuitPlayground.begin();

    /* Startup Seqeunce */
    uint8_t nloops = 4;
    for (int i=0; i<10*nloops; i++) {
        /* if (i%10 == 0) { CircuitPlayground.clearPixels(); } */
        if (i < (nloops-1)*10) {
            CircuitPlayground.setPixelColor(i%10 + 1, 0, 0, 0);
            CircuitPlayground.setPixelColor(i%10, 255, 0, 0);
        } else {
            CircuitPlayground.setPixelColor(i%10 + 1, 0, 0, 0);
            CircuitPlayground.setPixelColor(i%10, 0, 255, 0);
        }
        delay(40);
    }

    CircuitPlayground.clearPixels();
    for (int i=0; i<9; i++) {
        CircuitPlayground.setPixelColor(i+1, 0, 0, 30);
        delay(100);
    }
}

uint8_t normalize(int x, int l=0, int h=800) {
    /* convert range from [l,h] to [0,256) */
    return min(255, max(0, floor((x-l)*255.0/(h-l))));
}

void send_signal(byte signal) {
    byte buf[2] = {signal, 0x00};
    Serial.write(buf, 2);
}
void send_bytes(byte buf[], int len) {
    byte* b = new byte[len+1] {0x00};
    memcpy(b, buf, len);
    b[len] = 0x00;
    Serial.write(b, len+1);
}

void move_leaf(int i, int ext) {
    if (ext < 0) {
        Serial.write(byte(SIG_HWERROR));
        return;
    }
    CircuitPlayground.setPixelColor(i+1, ext, 0, 30);
}

void loop() {
  /* Serial Communication Mini-language
   * to set leaflet position, send magic 2-bytes 0xFF 0xD7 followed by
   *   leaflet number (0-indexed - single byte) then the 2-byte integer position
   * Ex. To set leaflet 3 of 8 to mid-field (127) assuming full extension is 255,
   *   no extension is 0:
   *     send the sequence: 0xFF, 0xD7, 0x02, 0x00, 0x7F
   *     echo -en "\xFF\xD7\x02\x00\x7F" > /dev/ttyACM0
   */

    byte buf[16];
    byte mode;

    // leaf motion commands
    uint8_t leaflet;
    int16_t pos;
    if (Serial.read() == MAGIC1 && Serial.read() == MAGIC2) {
        mode = Serial.read();
        if (mode == PRE_ABSPOS_ALL) {
            if (Serial.readBytes(buf, 16)) {
                for (int ii=0; ii<8; ii++) {
                    pos = (int16_t(buf[ii*2])<<8)|int16_t(buf[ii*2+1]);
                    uint8_t upos = normalize(pos);
                    move_leaf(ii+1, upos);

                    /* Serial.print("leaflet "); */
                    /* Serial.print(ii); */
                    /* Serial.print(" | pos "); */
                    /* Serial.println(upos); */
                    /* Serial.println(""); */
                }
                if (--time_to_error <= 0) {
                    // emulate a hardware error
                    time_to_error = 5;
                    send_signal(SIG_HWERROR);
                } else {
                    send_signal(SIG_MOVE_OK);
                }
            }
        } else if (mode == PRE_ABSPOS_ONE) {
            if (Serial.readBytes(buf, 3)) {
                leaflet = buf[0];
                pos = (int16_t(buf[1])<<8)|int16_t(buf[2]);
                /* Serial.println(pos, BIN); */
                uint8_t upos = normalize(pos, 0, 255);
                /* Serial.println(upos, BIN); */
                /* Serial.println(""); */

                move_leaf(leaflet+1, upos);
                /* Serial.print("leaflet "); */
                /* Serial.print(leaflet); */
                /* Serial.print(" | pos "); */
                /* Serial.println(upos); */

                send_signal(SIG_MOVE_OK);
            }
        } else if (mode == PRE_CALIBRATE) {
            Serial.println("Calibration Signal Received");
            Serial.println("test1");
            byte buf[4] = {0xD0, 0xD1, 0xD2, 0xD3};
            send_bytes(buf, 4);
            Serial.println("test2");
            Serial.print("test3");
            Serial.println(" test4");
        }
    }
}
