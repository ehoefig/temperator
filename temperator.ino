/*
 * World Wide Temperature Quiz
 * An entry in the Meteo Group & Beuth Hackathon '17
 */

const int led = D7;

void setup() {
  pinMode(led, OUTPUT);
}

void loop() {
  digitalWrite(led, HIGH);
  delay(200);
  digitalWrite(led, LOW);
  delay(200);
}
