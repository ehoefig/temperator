
import java.util.Properties;
import java.io.ByteArrayInputStream;

class WeatherApiClient {
  
  private static final String NO_ID = "no client_id configured. please configure a temperator.properties file.";
  private static final String NO_SECRET = "no client_id configured. please configure a temperator.properties file.";
  
  private String client_id = NO_ID;
  private String client_secret = NO_SECRET;
  
  public void setup() {
    Properties p = new Properties();
    try {
      byte[] b = loadBytes("temperator.properties"); 
      p.load(new ByteArrayInputStream(b));
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
    this.client_id = p.getProperty("weatherapi.client_id", NO_ID );
    this.client_secret = p.getProperty("weatherapi.client_secret", NO_SECRET); //<>//
  }
   
  public float getYesterdaysTemperature(Place place, int hour, int minute) throws IOException {
    ZonedDateTime yesterday = ZonedDateTime.now().minus(1, ChronoUnit.DAYS);
    ZonedDateTime targetTime = yesterday.with(ChronoField.HOUR_OF_DAY, hour)
        .with(ChronoField.MINUTE_OF_HOUR, minute)
        .with(ChronoField.SECOND_OF_MINUTE, 0)
        .with(ChronoField.MILLI_OF_SECOND, 0)
        .withZoneSameLocal(timezoneMapping.get(place));
    String observedFrom = URLEncoder.encode(DateTimeFormatter.ISO_OFFSET_DATE_TIME.format(targetTime.minus(1, ChronoUnit.HOURS)), "UTF-8");
    String observedUntil = URLEncoder.encode(DateTimeFormatter.ISO_OFFSET_DATE_TIME.format(targetTime), "UTF-8");
    String urlString = String.format(Locale.US, "https://point-observation.weather.mg/search?fields=airTemperatureInCelsius&locatedAt=%f,%f&observedPeriod=PT0S&observedFrom=%s&observedUntil=%s",
        geoLocationMapping.get(place).longitude,
        geoLocationMapping.get(place).latitude,
        observedFrom,
        observedUntil);
    return Float.parseFloat(get(urlString));
  }

   private String get(String urlStr) throws IOException {
    URL url = new URL(urlStr);
    HttpURLConnection con = (HttpURLConnection) url.openConnection();
    con.setRequestMethod("GET");
    con.setRequestProperty("Authorization", "Bearer " + getAccessToken());
    InputStream is = con.getInputStream();
    try {
      byte[] data = new byte[4096];
      is.read(data);
      return extractAirTemperature(new String(data));
    } finally {
      is.close();
    }
  }

  private String getAccessToken() throws IOException {
    URL url = new URL("https://auth.weather.mg/oauth/token");
    String urlParameters = "grant_type=client_credentials";
    byte[] postData = urlParameters.getBytes(Charset.forName("UTF-8"));
    int postDataLength = postData.length;
    HttpURLConnection con = (HttpURLConnection) url.openConnection();
    con.setRequestMethod("POST");
    con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
    String secret = new String(java.util.Base64.getEncoder().encode((client_id + ":" + client_secret).getBytes()));
    con.setRequestProperty("Authorization", "Basic " + secret);
    con.setRequestProperty("Content-Length", Integer.toString(postDataLength));
    con.setDoInput(true);
    con.setDoOutput(true);
    OutputStream os = con.getOutputStream();
    try {
      os.write(postData);
    } finally {
      os.close();
    }
    InputStream is = con.getInputStream();
    try {
      byte[] responseBuf = new byte[4096];
      is.read(responseBuf);
      String response = new String(responseBuf);
      return extractAccessToken(response);
    } finally {
      is.close();
    }
  }

  private String extractAccessToken(String response) {
    Pattern pattern = Pattern.compile("access_token\":\"([^\"]+)");
    Matcher matcher = pattern.matcher(response);
    if (!matcher.find()) {
      throw new IllegalStateException("No access token found in response: " + response);
    }
    return matcher.group(1);
  }

  private String extractAirTemperature(String response) {
    Pattern pattern = Pattern.compile("airTemperatureInCelsius\":(\\d+.\\d+)");
    Matcher matcher = pattern.matcher(response);
    if (!matcher.find()) {
      throw new IllegalStateException("No airTemperatureInCelsius found in response: " + response);
    }
    return matcher.group(1);
  }
  
}