/**
 * Beuth & MeteoGroup Hackathon '17 / '18 entry by Martin & Ed
 *
 * Attribution:
 * Click2-Sebastian-759472264.wav by Sebastian
 */
 
 

 
import java.util.Map;
import processing.sound.*;
import processing.serial.*;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.Charset;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoField;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.net.URLEncoder;

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

final WeatherApiClient weatherApiClient = new WeatherApiClient();
ArduinoController arduino;

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
  /* Name     index on wire */
  Anchorage,  //0000
  Denver,     //0001
  LaPaz,      //0002
  Alindao,    //0003
  Berlin,     //0004
  Moskau,     //0005
  Tiksi,      //0006
  Kabul,      //0007
  Peking,     //0008
  Sidney,     //0009
  None
};

class ScreenLocation {
  int x, y;
  public ScreenLocation(int x, int y) {
    this.x = x; 
    this.y = y;
  }
}

Place currentPlace = Place.None;

Map<Place,ScreenLocation> screenLocationMapping = new HashMap() { {
    this.put(Place.Anchorage, new ScreenLocation(142,356));
    this.put(Place.Berlin, new ScreenLocation(529,433));
    this.put(Place.Moskau, new ScreenLocation(586,415));
    this.put(Place.Sidney, new ScreenLocation(904,705));
    this.put(Place.Alindao, new ScreenLocation(556,575));
    this.put(Place.LaPaz, new ScreenLocation(323,642));
    this.put(Place.Peking, new ScreenLocation(809,469));
    this.put(Place.Denver, new ScreenLocation(226,468));
    this.put(Place.Kabul, new ScreenLocation(678,493));
    this.put(Place.Tiksi, new ScreenLocation(763,304));
    this.put(Place.None, new ScreenLocation(-100,-100));
  }
};

Map<Place, GeoLocation> geoLocationMapping = new HashMap() { {
    this.put(Place.Anchorage, new GeoLocation(-150.4939985,61.1042028));
    this.put(Place.Berlin, new GeoLocation(13.1459682,52.5072111));
    this.put(Place.Moskau, new GeoLocation(37.35232,55.7494733));
    this.put(Place.Sidney, new GeoLocation(150.3715133,-33.8470219));
    this.put(Place.Alindao, new GeoLocation(5.039914,12.2464949));
    this.put(Place.LaPaz, new GeoLocation(-72.5739368,-16.5207007));
    this.put(Place.Peking, new GeoLocation(98.4677453,39.9385466));
    this.put(Place.Denver, new GeoLocation(-113.8199617,39.7642548));
    this.put(Place.Kabul, new GeoLocation(68.9175433,34.5533869));
    this.put(Place.Tiksi, new GeoLocation(93.0050991,70.6211055));
    this.put(Place.None, new GeoLocation(0,0));
  }
};

Map<Place, ZoneId> timezoneMapping = new HashMap() { {
    this.put(Place.Anchorage, ZoneId.of("America/Anchorage"));
    this.put(Place.Berlin, ZoneId.of("Europe/Berlin"));
    this.put(Place.Moskau, ZoneId.of("Europe/Moscow"));
    this.put(Place.Sidney, ZoneId.of("Australia/Sydney"));
    this.put(Place.Alindao, ZoneId.of("Africa/Bangui"));
    this.put(Place.LaPaz, ZoneId.of("America/La_Paz"));
    this.put(Place.Peking, ZoneId.of("Asia/Shanghai"));
    this.put(Place.Denver, ZoneId.of("America/Denver"));
    this.put(Place.Kabul, ZoneId.of("Asia/Kabul"));
    this.put(Place.Tiksi, ZoneId.of("Asia/Yakutsk"));
    this.put(Place.None, ZoneId.of("GMT"));
  }
};



void keyPressed() {
  currentEvent = Event.ButtonPressed; //<>//
} //<>//

void setup() {
  size(1000, 800);
  
  // Serial
  printArray(Serial.list());
  // Open the port you are using at the rate you want:
  Serial port = new Serial(this, Serial.list()[0], 57600);
  port.write("led1");
  arduino = new ArduinoController(port);
  
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
  arduino.lightLed(ledOff);
  arduino.setTemperature((byte)minTemperature);
  arduino.setTime(88,88);
  weatherApiClient.setup();
}

public int getTemperatureFromAPI(Place place) {
  if (place == Place.None) return 0;
  try {
    float temperature = weatherApiClient.getYesterdaysTemperature(place,hours, minutes);
    return round(temperature);
  } catch (IOException e) {
    throw new RuntimeException(e);
  }
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
      arduino.setTime(hours, minutes);
      if (currentEvent == Event.ButtonPressed) {
        currentState = State.LocationSelection;
        counter = maxLocationCounter;
        counterGoal = maxLocationCounter - 1;
        counterB = 1;
        counterLocation = floor(random(0, maxLocations));
        arduino.lightLed((byte)counterLocation);
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
          float delta = pow(counterB++, 2);
          counterGoal = maxLocationCounter - round(delta);
          if (++counterLocation == maxLocations) counterLocation = 0;
          currentPlace = Place.class.getEnumConstants()[counterLocation];
          arduino.lightLed((byte)counterLocation);
        }
      }
    break;
    
  case GuessTheTemperature:
      counter += increment;
      arduino.setTemperature((byte)counter);
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
      arduino.setTemperature((byte)temperatureFromAPI);
    break;
    
  case ShowSolution:
      // Show the solution
      if (counter++ > maxSolutionCounter) {
        if (tries == 1) currentState = State.PlayOutro;
        else {
          --tries;
          currentState = State.TimeSelection;
        }
        arduino.lightLed(ledOff);
        arduino.setTime(88,88);
        arduino.setTemperature((byte)minTemperature);
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
    ScreenLocation position = screenLocationMapping.get(place);
    if (place == current) fill(#3377FF, 255);
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