#include <Adafruit_CircuitPlayground.h>

#define DEBUG_PRINT

void setup() {
    Serial.begin(9600);
    CircuitPlayground.begin();

    /* Startup Seqeunce */
    uint8_t nloops = 3;
    for (int i=0; i<10*nloops; i++) {
        /* if (i%10 == 0) { CircuitPlayground.clearPixels(); } */
        if (i < (nloops-1)*10) {
            CircuitPlayground.setPixelColor(i%10 + 1, 0, 0, 0);
            CircuitPlayground.setPixelColor(i%10, 255, 0, 0);
        } else {
            CircuitPlayground.setPixelColor(i%10 + 1, 0, 0, 0);
            CircuitPlayground.setPixelColor(i%10, 0, 255, 0);
        }
        delay(70);
    }

    CircuitPlayground.clearPixels();
    for (int i=0; i<8; i++) {
        CircuitPlayground.setPixelColor(i, 0, 0, 30);
        delay(125);
    }
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

    unsigned char buf[5];
    uint8_t       leaflet;
    uint16_t      pos;
    if (Serial.readBytes(buf, 1)) {
#ifdef DEBUG_PRINT
        /* Serial.print("Beginning to read bytes: "); */
        /* Serial.println(buf[0], HEX); */
#endif
        if (buf[0] == 0xFF && Serial.readBytes(&buf[1], 1)) {
#ifdef DEBUG_PRINT
            Serial.print("Mag1: ");
            Serial.println(buf[0], HEX);
#endif
            if (buf[1] == 0xD7 && Serial.readBytes(&buf[2], 3)) {
#ifdef DEBUG_PRINT
                Serial.print("Mag2: ");
                Serial.println(buf[1], HEX);
#endif

                leaflet = (uint8_t)buf[2];
                pos     = (uint16_t)( (buf[3]<<8)|(buf[4]) );

#ifdef DEBUG_PRINT
                Serial.print("Set #");
                Serial.print(leaflet+1);
                Serial.print(" (idx: ");
                Serial.print(leaflet);
                Serial.print(")");
                Serial.print(" to ext: ");
                Serial.println(pos);
#endif

                CircuitPlayground.setPixelColor(leaflet, pos, 0, 30);
            }
        }
    }

}

