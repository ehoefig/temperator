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
CHSV hsv[NUM_LEDS];

Servo tempServo;
int pos = 0;    // variable to store the servo position

// All lights on (for testing)
void lightUp() {
  display.print(8888);
  display.drawColon(true);
  display.writeDisplay();

  for (int i = 0; i < NUM_LEDS; ++i)
    leds[i] = CRGB::Green;
  FastLED.show();
}

void setup() {
  tempServo.attach(SERVO_PIN);
  Serial.begin(57600);
  FastLED.addLeds<WS2812, DATA_PIN, GRB>(leds, NUM_LEDS);
  display.begin(0x70);
  randomSeed(analogRead(0));
  for (int i = 0; i < NUM_LEDS; ++i) {
    hsv[i] = rgb2hsv_approximate(CRGB::Black);
    hsv[i].saturation = 255;
  }
  showClock(CLOCK_OFF);
}

void showTemperature(float temperatureValue) {
  const float maxTempVal = 50;
  const float minTempVal = -40;
  const float maxServoVal = 164;
  const float minServoVal = 4;
  temperatureValue = constrain(temperatureValue, minTempVal, maxTempVal);
  int servoValue = round(map(temperatureValue, minTempVal, maxTempVal, minServoVal, maxServoVal));
  servoValue = minServoVal - servoValue + maxServoVal; // because of flipped direction
  tempServo.write(servoValue);
}

int getCommandVal(CmdMessage cmdMsg) {
  String valStr = "";
  for (int i = 0; i < 4; i++) {
    if (isDigit(cmdMsg.value[i]) || '-' == cmdMsg.value[i]) {
      valStr += (char)cmdMsg.value[i];
    }
  }
  int val = valStr.toInt();
  return val;
}

void showCity(int index) {
  for (int i = 0; i < NUM_LEDS; i++) {
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
    display.writeDigitNum(0, (time / 1000) % 10);
    display.writeDigitNum(1, (time / 100) % 10);
    display.writeDigitNum(3, (time / 10) % 10);
    display.writeDigitNum(4, time % 10);
    display.drawColon(true);
  }
  display.writeDisplay();
}

void showIntro() {
  unsigned long start = millis();
  int ticks = 0;
  while (millis() - start < 3900) {
    for (int i = 0; i < NUM_LEDS; ++i) {
      hsv[i].value = max(0, hsv[i].value > 0 ? hsv[i].value - 2 : 0);
      hsv2rgb_rainbow(hsv[i], leds[i]);
    }
    if (ticks % 25 == 0) {
      int index = random(10);
      if (hsv[index].val == 0) {
        hsv[index].hue = random(256);
        hsv[index].val = 255;
      }

    }
    FastLED.show();
    delay(5);
    ticks++;
  }
  for (int t = 0; t < 128; ++t) {
    for (int i = 0; i < NUM_LEDS; ++i) {
      hsv[i].value = max(0, hsv[i].value > 0 ? hsv[i].value - 2 : 0);
      hsv2rgb_rainbow(hsv[i], leds[i]);
    }
    FastLED.show();
    delay(5);
  }
}

// < 2000ms
void showSuccess() {
  for (int j=0; j<256; ++j) {
    for (int i = 0; i < NUM_LEDS; ++i) {
      hsv[i] = rgb2hsv_approximate(CRGB::Green);
      hsv[i].saturation = 255;
      hsv[i].value = j;
      hsv2rgb_rainbow(hsv[i], leds[i]);
    }
    FastLED.show();
    delay(2);
  }
  for (int j=255; j>0; --j) {
    for (int i = 0; i < NUM_LEDS; ++i) {
      hsv[i] = rgb2hsv_approximate(CRGB::Green);
      hsv[i].saturation = 255;
      hsv[i].value = j;
      hsv2rgb_rainbow(hsv[i], leds[i]);
    }
    FastLED.show();
    delay(2);
  }
  for (int i = 0; i < NUM_LEDS; ++i) 
    leds[i] = CRGB::Black;
  FastLED.show();
}

// < 1000ms
void showFail() {
  for (int i = 0; i < NUM_LEDS; ++i) 
    leds[i] = CRGB::Red;
  FastLED.show();
  delay(800);
  for (int i = 0; i < NUM_LEDS; ++i) 
    leds[i] = CRGB::Black;
  FastLED.show();
}

// < 2000ms
void showOutro() {
  for (int j=255; j>0; --j) {
    for (int i = 0; i < NUM_LEDS; ++i) {
      hsv[i] = rgb2hsv_approximate(CRGB::Blue);
      hsv[i].saturation = 255;
      hsv[i].value = j;
      hsv2rgb_rainbow(hsv[i], leds[i]);
    }
    FastLED.show();
    delay(4);
    for (int i = 0; i < NUM_LEDS; ++i) 
      leds[i] = CRGB::Black;
    FastLED.show();
  }
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

bool isIntroCommand(CmdMessage cmdMsg) {
  return 'd' == cmdMsg.command[0] && 'o' == cmdMsg.command[1] && 'i' == cmdMsg.command[2];
}

bool isSuccessCommand(CmdMessage cmdMsg) {
  return 'w' == cmdMsg.command[0] && 'i' == cmdMsg.command[1] && 'n' == cmdMsg.command[2];
}

bool isFailCommand(CmdMessage cmdMsg) {
  return 'f' == cmdMsg.command[0] && 'a' == cmdMsg.command[1] && 'i' == cmdMsg.command[2];
}

bool isOutroCommand(CmdMessage cmdMsg) {
  return 'd' == cmdMsg.command[0] && 'o' == cmdMsg.command[1] && 'o' == cmdMsg.command[2];
}


void loop() {
  if (Serial.available() > 0) {
    CmdMessage cmdMsg;
    memset((void*)&cmdMsg, 0, sizeof(cmdMsg));
    Serial.readBytes((uint8_t*)&cmdMsg, sizeof(cmdMsg));
    if (isTemperatureCommand(cmdMsg)) showTemperature(getCommandVal(cmdMsg));
    else if (isCityCommand(cmdMsg)) showCity(getCommandVal(cmdMsg));
    else if (isClockCommand(cmdMsg)) showClock(getCommandVal(cmdMsg));
    else if (isIntroCommand(cmdMsg)) showIntro();
    else if (isSuccessCommand(cmdMsg)) showSuccess();
    else if (isFailCommand(cmdMsg)) showFail();
    else if (isOutroCommand(cmdMsg)) showOutro();
  }

}
