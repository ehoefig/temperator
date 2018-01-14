 /*
 struct CmdMessage {
  byte command[3];
  byte value[3];
};

CMD:
tmp  zahl (-30..+60)
led  zahl (0..9) 100 is off
clk  4byte (hb, hl, mb, ml)
  
  
  To DO
  get temperature from API
  
 */
 
 class ArduinoController {
   
   private Serial port;
   
   public ArduinoController (Serial port) {
     this.port = port;
   }
   
   public void lightLed(byte ledNum) {
      port.write("led");
      port.write(String.format("%4d", ledNum));
   }
  
   public void setTemperature(byte t) {
      temperature = t;
      // Talk to Arduino
      port.write("tmp");
      port.write(String.format("%4d",t));
      delay(delayForServoMS);
   }

   public void setTime(int hours, int minutes) {
      hb = (byte)(hours / 10);
      hl = (byte)(hours % 10);
      mb = (byte)(minutes / 10);
      ml = (byte)(minutes % 10);
        
      // Talk to Arduino
      port.write("clk");
      port.write(String.format("%2d", hours));
      port.write(String.format("%2d", minutes));
   }
   
   public void showIntro() {
      port.write("dointro");
   }
   
   public void showSuccess() {
      port.write("win0000");
   }
   
   public void showFail() {
      port.write("fail000");
   }
   
   public void showOutro() {
      port.write("dooutro");
   }
   
   
 }