#include "buttons.h"
#include <Arduino.h>
#include <Adafruit_CircuitPlayground.h>

unsigned long debounceDelay = 50;
static bool buttonState[] = {false, false};
static bool lastButtonState[] = {false, false};
static unsigned long lastDebounceTime[] = {0, 0};

bool isButtonPressed(::CPBUTTON btn) {
    bool reading = btn==CPBUTTON::LEFT ? CircuitPlayground.leftButton() : CircuitPlayground.rightButton();
    bool result = false;
    if (reading != lastButtonState[btn]) {
        lastDebounceTime[btn] = millis();
    }
    if ((millis() - lastDebounceTime[btn]) > debounceDelay) {
        if (reading != buttonState[btn]) {
            buttonState[btn] = reading;
        }
        if (buttonState[btn]) {
            result = true;
        }
    }
    lastButtonState[btn] = reading;
    return result;
}
