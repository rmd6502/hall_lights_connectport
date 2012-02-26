const byte r_control = 3;
const byte g_control = 5;
const byte b_control = 6;

unsigned int buf = 0;
byte bufPos = 0;
unsigned int dly = 5;
unsigned int random_mode = 0;

enum _colorStates { NONE, RED, GREEN, BLUE, SPEED };
byte states = 0;
byte current[3] = {0};
byte goal[3] = {255, 200, 180};
byte pins[3] = {0};

void setup() {
  Serial.begin(9600);
  Serial.println("setup begin\n");
  analogWrite(r_control, 0);
  analogWrite(g_control, 0);
  analogWrite(b_control, 0);
  
  pinMode(r_control, OUTPUT);
  pinMode(g_control, OUTPUT);
  pinMode(b_control, OUTPUT);
  
  pins[0] = r_control;
  pins[1] = g_control;
  pins[2] = b_control;
    Serial.println("setup complete\n");
}

void loop() {
  if (Serial.available()) {
    byte b = Serial.read();
    byte handled = 0;
    while (handled == 0) {
      switch(states) {
        case RED:
          handled = handleNumber(b);
          break;
        case GREEN:
          handled = handleNumber(b);
          break;
        case BLUE:
          handled = handleNumber(b);
          break;
        case SPEED:
          handled = handleNumber(b);
          break;
        default:
          handleDefault(b);
          handled = 1;
          break;
      }
    }
  }
  uint8_t bgoal = 1;
  for (int j=0; j < 3; ++j) {
    if (goal[j] != current[j]) {
      bgoal = 0;
      int dir = goal[j] - current[j];
      dir /= abs(dir);
      //Serial.print("dir "); Serial.println((short)dir);
      current[j] += dir;
      analogWrite(pins[j], current[j]);
    }
  }
  if (random_mode && bgoal) {
    for (int j=0; j < 3; ++j) {
      goal[j] = random() & 0xff;
    }
  }
  delay(dly);
}

void handleDefault(byte d) {
  switch(d) {
    case 'r': case 'R':
      states = RED;
      return;
    case 'b': case 'B':
      states = BLUE;
      return;
    case 'g': case 'G':
      states = GREEN;
      return;
    case 's': case 'S':
      states = SPEED;
      return;
    case 'n': case 'N':
      random_mode = !random_mode;
      break;
    default:
      return;
  }
}

byte handleNumber(byte r) {
  if (!isdigit(r)) {
    setColor();
    return 0;
  }
  buf = buf * 10 + (r-'0');
  return 1;
}

void setColor() {
  switch (states) {
    case RED:
      Serial.print("setting red to "); Serial.println(buf);
      random_mode = 0;
      goal[0] = buf;
      break;
    case GREEN:
      Serial.print("setting green to "); Serial.println(buf);
      goal[1] = buf;
      random_mode = 0;
      break;
    case BLUE:
      Serial.print("setting blue to "); Serial.println(buf);
      goal[2] = buf;
      random_mode = 0;
      break;
    case SPEED:
      Serial.print("setting speed to "); Serial.println(buf);
      dly = buf;
      break;
    default:
      break;
  }
  buf = 0;
  states = NONE;
}


