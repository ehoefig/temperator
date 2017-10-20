/**
 * Beuth & MeteoGroup Hackathon '17 entry by Martin & Ed
 *
 * Attribution:
 * Click2-Sebastian-759472264.wav by Sebastian
 */
 
 
 /*
 struct CmdMessage {
  byte command[3];
  byte value[3];
};

CMD:
tmp  zahl (-30..+60)
led  zahl (0..9) 100 is off
tim  4byte (hb, hl, mb, ml)
  
  
  To DO
  get temperature from API
  
 */
 
import java.util.Map;
import processing.sound.*;
import processing.serial.*;

final static float tolerance = 5.0;  // Tolerance of a guess (number of +- degrees in Celsius)
final static int numberOfTries = 3;
final static int maxTimeCounter = 200;  // How many frames until time is fixed
final static int maxLocationCounter = 400; // How many frames until location is fixed
final static int maxSolutionCounter = 300; // How many frames to show solution for
final static int minTemperature = -23;
final static int maxTemperature = +50;
final static int maxLocations = Place.class.getEnumConstants().length - 1;
final static byte ledOff = 100;
final static int delayForServoMS = 25;

Serial port;

int tries = numberOfTries;

PImage bg;  // world map
PFont font;
PFont ledFont;

SoundFile clickSound, fanfareSound, honkSound, cheerSound, whooshSound;

// LED Time
byte hb = 8;
byte hl = 8;
byte mb = 8;
byte ml = 8;

int temperature = -minTemperature;
int temperatureFromAPI = 23;

int counter = 0;
int counterB = 0;
int counterGoal = 0;
int counterLocation = 0;
int increment = +1;  // decides upon direction of temperature pointer 

int hours = 88;
int minutes = 88;

enum State {
  Idle, PlayIntro, TimeSelection, LocationSelection, GuessTheTemperature, GuessGiven, ShowSolution, PlayOutro
}

State oldState = State.PlayOutro;
State currentState = State.Idle;

enum Event {
  ButtonPressed, None
};

Event currentEvent = Event.None;

enum Place {
  Anchorage, Berlin, Moskau, Sidney, Alindao, LaPaz, Peking, Denver, Kabul, Tiksi, None
};

Place currentPlace = Place.None;

class Pair {
  int x, y;
  public Pair(int x, int y) {
    this.x = x; 
    this.y = y;
  }
}

class Coord {
  float longitude, latitude;
  public Coord(float lon, float lat) {
    this.longitude = lon; 
    this.latitude = lat;
  }
}

Map<Place,Pair> location = new HashMap() { {
    this.put(Place.Anchorage, new Pair(142,356));
    this.put(Place.Berlin, new Pair(529,433));
    this.put(Place.Moskau, new Pair(586,415));
    this.put(Place.Sidney, new Pair(904,705));
    this.put(Place.Alindao, new Pair(556,575));
    this.put(Place.LaPaz, new Pair(323,642));
    this.put(Place.Peking, new Pair(809,469));
    this.put(Place.Denver, new Pair(226,468));
    this.put(Place.Kabul, new Pair(678,493));
    this.put(Place.Tiksi, new Pair(763,304));
    this.put(Place.None, new Pair(-100,-100));
  }
};

Map<Place,Coord> position = new HashMap() { {
    this.put(Place.Anchorage, new Coord(-150.4939985,61.1042028));
    this.put(Place.Berlin, new Coord(13.1459682,52.5072111));
    this.put(Place.Moskau, new Coord(37.35232,55.7494733));
    this.put(Place.Sidney, new Coord(150.3715133,-33.8470219));
    this.put(Place.Alindao, new Coord(5.039914,12.2464949));
    this.put(Place.LaPaz, new Coord(-72.5739368,-16.5207007));
    this.put(Place.Peking, new Coord(98.4677453,39.9385466));
    this.put(Place.Denver, new Coord(-113.8199617,39.7642548));
    this.put(Place.Kabul, new Coord(68.9175433,34.5533869));
    this.put(Place.Tiksi, new Coord(93.0050991,70.6211055));
    this.put(Place.None, new Coord(0,0));
  }
};

void keyPressed() {
  currentEvent = Event.ButtonPressed;
} //<>//

void setup() {
  size(1000, 800);
  
  // Serial
  printArray(Serial.list());
  // Open the port you are using at the rate you want:
  port = new Serial(this, Serial.list()[3], 57600);
  port.write("led1");
  
  bg = loadImage("worldmap.png");
  font = loadFont("BiomeMeteoGroup-BoldNarrow-24.vlw");
  ledFont = loadFont("DSEG7Classic-Bold-48.vlw");
  clickSound = new SoundFile(this, "Click2-Sebastian-759472264.wav");
  fanfareSound = new SoundFile(this, "castle_horn.mp3");
  honkSound = new SoundFile(this, "honk.mp3");
  cheerSound = new SoundFile(this, "cheer.mp3");
  whooshSound = new SoundFile(this, "whoosh.mp3");
  fanfareSound.rate(0.5);
  textFont(font);
  lightLed(ledOff);
  setTemperature((byte)minTemperature);
  setTime(88,88);
}

public int getTemperatureFromAPI(Place place) {
  
  if (place == Place.None) return 0;
  
  // TODO: Ask API
  Coord pos = position.get(place);
  int result = 23;
  
  return result;
}

public void lightLed(byte ledNum) {
 
  // Talk to Arduino
  port.write("led");
  port.write(str(ledNum));
}

public void setTemperature(byte t) {
  temperature = t;
 
  // Talk to Arduino
  port.write("tmp");
  port.write(str(t));
  
  delay(delayForServoMS);
}

public void setTime(int hours, int minutes) {
  hb = (byte)(hours / 10);
  hl = (byte)(hours % 10);
  mb = (byte)(minutes / 10);
  ml = (byte)(minutes % 10);
  
  // Talk to Arduino
  port.write("tim");
  port.write(str(hb));
  port.write(str(hl));
  port.write(str(mb));
  port.write(str(ml));
}

public void calculateRandomTime() {
  hours = round(random (0, 23));
  minutes = round(random (0, 59));
}

public void step() {
  
  switch (currentState) {
    
  case Idle:
    if (currentEvent == Event.ButtonPressed) {
      currentState = State.PlayIntro;
      tries = numberOfTries;
    }
    break;
    
  case PlayIntro:
    fanfareSound.play();
    delay(5500);
    currentState = State.TimeSelection;
    counter = maxTimeCounter;
    break;
    
  case TimeSelection:
      calculateRandomTime();
      setTime(hours, minutes);
      if (currentEvent == Event.ButtonPressed) {
        currentState = State.LocationSelection;
        counter = maxLocationCounter;
        counterGoal = maxLocationCounter - 1;
        counterB = 1;
        counterLocation = floor(random(0, maxLocations));
        lightLed((byte)counterLocation);
      }
    break;
    
  case LocationSelection:
      // Select random location
      if (counter-- <= 0) {
        // Advance to next state
        currentState = State.GuessTheTemperature;
        temperatureFromAPI = getTemperatureFromAPI(currentPlace);
        counter = 0;
      } else {
        if (counter <= counterGoal) {
          // "Wheel ticks to next place"
          clickSound.play();
          currentPlace = Place.class.getEnumConstants()[counterLocation];
          float delta = pow(counterB++, 2);
          counterGoal = maxLocationCounter - round(delta);
          if (++counterLocation == maxLocations) counterLocation = 0;
          lightLed((byte)counterLocation);
        }
      }
    break;
    
  case GuessTheTemperature:
      counter += increment;
      setTemperature((byte)counter);
      if (counter == minTemperature) increment = +1;
      else if (counter == maxTemperature) increment = -1;
      if (currentEvent == Event.ButtonPressed) {
        currentState = State.GuessGiven;
      }
    break;
    
  case GuessGiven:
      // Show the guess
      println("Guess / API: " + temperature + " / " + temperatureFromAPI);
      delay(500);
      if (abs(temperatureFromAPI - temperature) < tolerance) {
        // Success!
        cheerSound.play();
        delay(2000);
      } else {
        // Failure!
        honkSound.play();
        delay(1000);
      }
      currentState = State.ShowSolution;
      counter = 0;
      setTemperature((byte)temperatureFromAPI);
    break;
    
  case ShowSolution:
      // Show the solution
      if (counter++ > maxSolutionCounter) {
        if (tries == 1) currentState = State.PlayOutro;
        else {
          --tries;
          currentState = State.TimeSelection;
        }
        lightLed(ledOff);
        setTime(88,88);
        setTemperature((byte)minTemperature);
        println("tries " + tries);
        currentPlace = Place.None;
      }
    break;
    
  case PlayOutro:
      whooshSound.play();
      delay(3000);
      currentState = State.Idle;
    break;
    
  default:
  }
  
  if (oldState != currentState) {
    oldState = currentState;
    println (currentState);
  }
  currentEvent = Event.None;
}

void drawTime() {
  fill(#FF0000);
  textFont(ledFont);
  text(str(hb) + str(hl) + ":" + str(mb) + str(ml), 105, 708);
}

void drawPlaces(Place current) {
  
  // Set style
  stroke(#000000);
  strokeWeight(1);
  ellipseMode(CENTER);
  
  for (Place place: Place.values()) {
    Pair position = location.get(place);
    if (place.equals(current)) fill(#3377FF, 255);
    else fill(#0000FF, 0);
    ellipse(position.x, position.y, 15, 15);
  }
}

void drawTemperature() {
  // Set style
  stroke(#FF0000);
  strokeWeight(3);
  float rotation = map(temperature, minTemperature, maxTemperature, 0, PI);
  float xEnd = 120 * cos(rotation + PI);
  float yEnd = 120 * sin(rotation + PI);
  line(500, 230, xEnd + 500, yEnd + 230);
}

void draw() {
  
  // Update
  step();
  
  // Draw
  background(bg);
  drawTime();
  drawTemperature();
  
  drawPlaces(currentPlace);
  
}