#include <Servo.h>

struct CmdMessage {
  byte command[3];
  byte value[3];
};

Servo tempServo;
int pos = 0;    // variable to store the servo position

void setup() {
  tempServo.attach(9);  // attaches the servo on pin 9 to the servo object
  Serial.begin(57600); 
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
  for (int i=0; i<3; i++) {
    if (isDigit(cmdMsg.value[i]) || '-' == cmdMsg.value[i]) {
      valStr += (char)cmdMsg.value[i];
    }
  }
  int val = valStr.toInt();
  return val;
}

bool isTemperatureCommand(CmdMessage cmdMsg) {
  return 't' == cmdMsg.command[0] && 'm' == cmdMsg.command[1] && 'p' == cmdMsg.command[2];
}

void loop() {
  if (Serial.available() > 0) {
    CmdMessage cmdMsg;
    Serial.readBytes((uint8_t*)&cmdMsg, sizeof(cmdMsg));
    if (isTemperatureCommand(cmdMsg)) {
      showTemperature(getCommandVal(cmdMsg));
    }
  } 
}
