#include <Adafruit_CircuitPlayground.h>
#include <math.h>

#define DEBUG_PRINT

#define MAGIC1 0xFF
#define MAGIC2 0xD7
#define PRE_ABSPOS_ONE 0xB1
#define PRE_ABSPOS_ALL 0xB2
#define PRE_RELPOS_ONE 0xC1
#define PRE_RELPOS_ALL 0xC2

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
    for (int i=0; i<8; i++) {
        CircuitPlayground.setPixelColor(i, 0, 0, 30);
        delay(100);
    }
}

int normalize(uint16_t x, int l=0, int h=800) {
    /* convert range from [l,h] to [0,256) */
    return min(255, max(0, floor((x-l)*255/(h-l))));
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

    unsigned char buf[16];
    uint16_t state[8] = {0};
    uint8_t       leaflet;
    uint16_t      pos;
    if (Serial.readBytes(buf, 2) && buf[0] == MAGIC1 && buf[1] == MAGIC2) {
        unsigned char mode;
        Serial.readBytes(&mode, 1);
        switch (mode) {
            case PRE_ABSPOS_ONE:
                Serial.readBytes(buf, 3);
                leaflet = (uint8_t)buf[0];
                pos     = (uint16_t)( (buf[1]<<8)|(buf[2]) );
                pos = normalize(pos);
                if (state[leaflet] != pos) {
                    CircuitPlayground.setPixelColor(leaflet, pos, 0, 30);
                    state[leaflet] = pos;
                }
                break;

            case PRE_ABSPOS_ALL:
                Serial.readBytes(buf, 16);
                for (int ii=0; ii<8; ii++) {
                    pos = (uint16_t)( (buf[ii*2]<<8)|(buf[ii*2+1]) );
                    pos = normalize(pos);
                    if (state[ii] != pos) {
                        CircuitPlayground.setPixelColor(ii, pos, 0, 30);
                        state[ii] = pos;
                    }
                }
                break;
            default:
                break;
        }

    }
}

