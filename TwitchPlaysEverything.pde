import java.awt.*;
import java.awt.event.*;
import java.awt.event.KeyEvent;

//See the Bot class for login settings

//the robot automating input
Robot robot;

//the chat bot interfacing with Twitch, see Bot class
Bot bot;

//mouse area
int MIN_X = 40;
int MIN_Y = 80;
int MAX_X = MIN_X+900;
int MAX_Y = MIN_Y+710;

ArrayList<KeyPress> keys;

//timing vars in millis
int lastTime = 0;
int deltaTime = 0;

//if receiving a key press already down
//should it add the time (true) or ignore the command (false)
boolean KEY_CUMULATIVE = false;

//generic timer for application restart
//in this example if somebody calls "restart" and nobody says anything
//for 3 seconds the application restarts
//it's a simple "voting" system
int restartTimer = -1;
int RESTART_TIME = 5000;

//typing shouldn't be zero or it will skipp characters
int TYPE_DELAY = 60;

//runtime to open or close external applications
Runtime runtime; 
Process process;

//if you need to restart an application through a command
//you need the path of the application 
//on mac you drag and drop the app on a terminal window to find it
//mind that .app files may not be understood as executables, you have to "show package contents" and find the actual launcher

//on windows right click property, don't forget to add double slashes "C:\\Users\\paolo\\Desktop\\ 

String applicationPath = ""; // "/Applications/pokemon.app/Contents/MacOS/"
String applicationName = ""; // eg pokemon.exe

//twitch users rarely scroll down the channel page to read the instructions
//it's a good idea to have an overlay summarizing the commands
//just a simple scrolling text, leave it blank to disable it
String ticker = "Your instructions here";
float tickerX = 0;
float tickerW = 0;
PFont tickerFont;

void setup() {
  size(1024, 40);

  //create the robot automation
  try { 
    robot = new Robot();
    robot.setAutoDelay(0);
  } 
  catch (Exception e) {
    e.printStackTrace();
  }

  //start the chatbot that listens to commands
  bot = new Bot();

  //initialize all the possible keypresses
  //KeyEvent are just int codes https://docs.oracle.com/javase/6/docs/api/java/awt/event/KeyEvent.html
  keys = new ArrayList<KeyPress>();

  // you can specify one command associated to a keypress eg:
  //keys.add(new KeyPress( "start", KeyEvent.VK_SPACE));

  //...or multiple alias for the same event
  String[] ids = {"left", "l"};
  keys.add(new KeyPress( ids, KeyEvent.VK_LEFT));

  String[] ids1 = {"right", "r"}; 
  keys.add(new KeyPress( ids1, KeyEvent.VK_RIGHT));

  String[] ids2 = {"up", "u"};
  keys.add(new KeyPress( ids2, KeyEvent.VK_UP));

  String[] ids3 = {"down", "d"};
  keys.add(new KeyPress(ids3, KeyEvent.VK_DOWN));

  String[] ids4 = {"enter", "return", "start"};
  keys.add(new KeyPress(ids4, KeyEvent.VK_ENTER, 0, 1));

  //check parse commands for more commands
  runtime = Runtime.getRuntime();

  /*
  This part is experimental and may not work in some cases
   allows java to open and close the application and let users restart it.
   It can be used when the game doesn't have a clean restart system
   */
  if (applicationPath != "" && applicationName != "" && process == null) {
    startGame();
  }

  //center mouse
  robot.mouseMove(int(MIN_X+(MAX_X-MIN_X)/2), int(MIN_Y+(MAX_Y-MIN_Y)/2));

  //initialize scrolling text
  if (ticker!="") {
    textSize(28);
    tickerW = textWidth(ticker);
    tickerX = width;
  }
}

//main loop
void draw() {

  deltaTime = millis() - lastTime;
  lastTime = millis();

  //update all the keypresses
  for (int i = 0; i < keys.size(); i++) {
    KeyPress kp = keys.get(i);
    kp.update();
  }

  //restart in progress
  if (restartTimer > 0) {
    restartTimer -= deltaTime;

    //nobody opposed
    if (restartTimer<=0) {
      bot.sendMessage(bot.channel, "Restart in progress...");

      if (applicationPath != "" && applicationName != "")
      {
        if (process != null) 
          process.destroy();

        delay(5000);
        startGame();
      }
    }
  }


  //scrolling text
  if (ticker !="") {
    background(0);
    textAlign(LEFT, TOP);
    fill(255);
    text(ticker, tickerX, 5);
    tickerX--;
    if (tickerX<-tickerW)
      tickerX = width;
  }
}


//every chat string passes through this
void parseCommand(String command) {

  String[] c = split(command, ' ');
  boolean keyFound = false;

  //cancel restart if in progress
  restartTimer = -1;

  if (c.length>0) {

    //check all the keypresses first
    for (int i = 0; i < keys.size(); i++) {

      KeyPress kp = keys.get(i);
      boolean found = false;
      String id = c[0].toLowerCase(); 

      //check the command against all the ids, there may be aliases
      for (int j = 0; j<kp.id.length; j++)
      {
        if (id.equals(kp.id[j]))
          found = true;
      }

      //command matches
      if (found) {
        //default duration if not specified
        float duration = 0.5;

        //a parameter is passed
        if (c.length >= 2) {
          duration = float(c[1]);
        }

        if (kp.timer > 0 && KEY_CUMULATIVE) {
          kp.timer += duration;
        }
        if (kp.timer > 0 && !KEY_CUMULATIVE)
        {
          //just ignore
        } else { 
          //normal 
          kp.press(duration);
        }

        keyFound = true;
      }
    }//key loop


    //check other keywords if keys are not found
    if (!keyFound) {
      switch(c[0].toLowerCase()) {
      case "click":
        robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
        robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
        break;

        //mouse x y - instant move
      case "mouse":
        if (c.length >=3) {
          int x = int(c[1]);
          int y = int(c[2]);
          x = constrain(x, MIN_X, MAX_X);
          y = constrain(y, MIN_Y, MAX_Y);
          robot.mouseMove(x, y);
        }
        break;

        //mouse% x y - instant move in percent of area
      case "mouse%":
        if (c.length >=3) {
          int x = int(c[1]);
          int y = int(c[2]);
          x = constrain(x, 0, 100);
          y = constrain(y, 0, 100);
          int xp = int(map(x, 0, 100, MIN_X, MAX_X));
          int yp = int(map(y, 0, 100, MIN_Y, MAX_Y));
          robot.mouseMove(xp, yp);
        }
        break;

        //mouse increment
      case "x":
        if (c.length >=2) {
          int dx = int(c[1]);

          PointerInfo pi = MouseInfo.getPointerInfo(); 
          // get the location of mouse 
          Point p = pi.getLocation(); 

          int x = p.x + dx;
          x = constrain(x, MIN_X, MAX_X);
          robot.mouseMove(x, p.y);
        }
        break;

        //mouse increment
      case "y":
        if (c.length >=2) {
          int dy = int(c[1]);

          PointerInfo pi = MouseInfo.getPointerInfo(); 
          // get the location of mouse 
          Point p = pi.getLocation(); 

          int y = p.y + dy;
          y = constrain(y, MIN_Y, MAX_Y);
          robot.mouseMove(p.x, y);
        }
        break;

        //types a whole string and presses enter
      case "type":

        //there must be another member
        if (c.length >= 2) {
          //slice from the first space

          String s = command.substring(command.indexOf(" "));

          for (int i = 0; i < s.length(); i++) {

            char ch = s.charAt(i);

            //special chars, they don't have a key associated
            //this is keyboard-layout dependent
            if (ch == '!') {
              robot.keyPress(KeyEvent.VK_SHIFT);
              robot.keyPress(KeyEvent.VK_1);
              robot.keyRelease(KeyEvent.VK_1);
              robot.keyRelease(KeyEvent.VK_SHIFT);
            } else if (ch == '?') {
              robot.keyPress(KeyEvent.VK_SHIFT);
              robot.keyPress(KeyEvent.VK_SLASH);
              robot.keyRelease(KeyEvent.VK_SLASH);
              robot.keyRelease(KeyEvent.VK_SHIFT);
            } else if (ch == '\'' || ch =='`') {
              robot.keyPress(KeyEvent.VK_QUOTE);
            } else if (ch == '"' || ch=='“' || ch=='”') {
              /*
              robot.keyPress(KeyEvent.VK_SHIFT);
               robot.keyPress(KeyEvent.VK_QUOTE);
               robot.keyRelease(KeyEvent.VK_QUOTE);
               robot.keyRelease(KeyEvent.VK_SHIFT);
               */
              //doesn't seem to work with the first quote?
            } else {
              //normal letters
              if (Character.isUpperCase(ch)) {
                robot.keyPress(KeyEvent.VK_SHIFT);
              }
              robot.keyPress(Character.toUpperCase(ch));

              robot.keyRelease(Character.toUpperCase(ch));

              if (Character.isUpperCase(ch)) {
                robot.keyRelease(KeyEvent.VK_SHIFT);
              }
            }

            delay(TYPE_DELAY);
          }

          robot.keyPress(KeyEvent.VK_ENTER);
          robot.keyRelease(KeyEvent.VK_ENTER);
        }

        break;

        //calls a restart poll
      case "restart":
        if (applicationPath !="" && applicationName !="") {
          restartTimer = RESTART_TIME;
          bot.sendMessage(bot.channel, "RESTART CALLED! Effective in 5 seconds. If you don't want to restart speak now or forever hold your peace.");
        }
        break;
      }//end case
    }//end keyfound
  }//end cmd not empty
}

void startGame() {

  try
  {
    process = null;
    ProcessBuilder pb = new ProcessBuilder(applicationPath+applicationName);
    pb.directory(new File(applicationPath));
    process = pb.start();
  }
  catch (IOException e)
  {
    e.printStackTrace();
  }
}

//simple class that holds the key down for x seconds
//new times 
class KeyPress {
  String[] id;
  int k;
  float timer = 0;

  //Default min and max time allowed in SECONDS
  float MAX = 2;
  float MIN = 0;

  //initialize
  KeyPress(String _id, int _k) {
    this.id = new String[1];
    this.id[0] = _id;
    this.k = _k;
  }

  //initialize
  KeyPress(String[] _id, int _k) {
    this.id = _id;    
    this.k = _k;
  }

  //alt initialize with min and max values
  KeyPress(String _id, int _k, int _MIN, int _MAX) {
    this.id = new String[1];
    this.id[0] = _id;
    this.k = _k;
    this.MIN = _MIN;
    this.MAX = _MAX;
  }

  KeyPress(String[] _id, int _k, int _MIN, int _MAX) {
    this.id = _id;
    this.k = _k;
    this.MIN = _MIN;
    this.MAX = _MAX;
  }

  //time is passed in seconds and converted to millis
  void press(float _time) {
    this.timer = _time;
    this.timer = constrain(this.timer, MIN, MAX) * 1000; //convert to millis
    robot.keyPress(this.k);
  }

  //countdown and release
  void update() {
    if (this.timer>0) {
      this.timer -= deltaTime;

      if (this.timer<=0) {
        robot.keyRelease(this.k);
        this.timer = 0;
      }
    }
  }
}//end KeyPress class


//utility delay, stops execution
void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
