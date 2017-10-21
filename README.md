# temperator
World Wide Temperature Quiz (Meteo&amp;Beuth Hackathon '17)

## Arduino Nano pin-layout

D3  LED     10 x WS2812 LED, showing the worl map
D9  Servo   temperature gauge
A4	I2C     7-segment clock
A5	I2C     7-segment clock

## Known Issues

Processing's sound library crashes JVM under Windows.
Hence, the sound support is deactivated.