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
  Particle.publish("led", "on");
  delay(3000);
  digitalWrite(led, LOW);
  Particle.publish("led", "off");
  delay(3000);
}
