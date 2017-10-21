#include <Servo.h>
#include <FastLED.h>
#include <Wire.h>
#include "Adafruit_LEDBackpack.h"

Adafruit_7segment display = Adafruit_7segment();

#define NUM_LEDS 10
#define DATA_PIN 3
#define SERVO_PIN 9
#define CLOCK_OFF 9999

struct CmdMessage {
  byte command[3];
  byte value[4];
};

CRGB leds[NUM_LEDS];
Servo tempServo;
int pos = 0;    // variable to store the servo position

void setup() {
  tempServo.attach(SERVO_PIN);
  Serial.begin(57600); 
  FastLED.addLeds<WS2812, DATA_PIN, GRB>(leds, NUM_LEDS);
  display.begin(0x70);
}

void showTemperature(float temperatureValue) {
  const float maxTempVal = 50;
  const float minTempVal = -23;
  const float maxServoVal = 165;
  const float minServoVal = 5;
  temperatureValue = constrain(temperatureValue, minTempVal, maxTempVal);
  int servoValue = round(map(temperatureValue, minTempVal, maxTempVal, maxServoVal, minServoVal));
  tempServo.write(servoValue);
}

int getCommandVal(CmdMessage cmdMsg) {
  String valStr = "";
  for (int i=0; i<4; i++) {
    if (isDigit(cmdMsg.value[i]) || '-' == cmdMsg.value[i]) {
      valStr += (char)cmdMsg.value[i];
    }
  }
  int val = valStr.toInt();
  return val;
}

void showCity(int index) {
  for (int i=0; i<NUM_LEDS; i++) {
    leds[i] = CRGB::Black;  
  }
  if (index >= 0 && index < NUM_LEDS) {
    leds[index] = CRGB::Red;
  }
  FastLED.show();
}

void showClock(int time) {
  if (CLOCK_OFF == time) {
    display.writeDigitRaw(0, 0);
    display.writeDigitRaw(1, 0);
    display.writeDigitRaw(2, 0);
    display.writeDigitRaw(3, 0);
    display.writeDigitRaw(4, 0);
  } else {
    display.print(time);
    display.drawColon(true);
  }
  display.writeDisplay();
}

bool isTemperatureCommand(CmdMessage cmdMsg) {
  return 't' == cmdMsg.command[0] && 'm' == cmdMsg.command[1] && 'p' == cmdMsg.command[2];
}

bool isCityCommand(CmdMessage cmdMsg) {
  return 'l' == cmdMsg.command[0] && 'e' == cmdMsg.command[1] && 'd' == cmdMsg.command[2];
}

bool isClockCommand(CmdMessage cmdMsg) {
  return 'c' == cmdMsg.command[0] && 'l' == cmdMsg.command[1] && 'k' == cmdMsg.command[2];
}

void loop() {
  if (Serial.available() > 0) {
    CmdMessage cmdMsg;
    memset((void*)&cmdMsg, 0, sizeof(cmdMsg));
    Serial.readBytes((uint8_t*)&cmdMsg, sizeof(cmdMsg));
    if (isTemperatureCommand(cmdMsg)) {
      showTemperature(getCommandVal(cmdMsg));
    }
    if (isCityCommand(cmdMsg)) {
      showCity(getCommandVal(cmdMsg));
    }
    if (isClockCommand(cmdMsg)) {
      showClock(getCommandVal(cmdMsg));
    }
  }
  
}
