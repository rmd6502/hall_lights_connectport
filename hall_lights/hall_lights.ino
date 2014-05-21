#include <stdint.h>
#include <avr/eeprom.h>

const byte r1_control = 3;
const byte g1_control = 5;
const byte b1_control = 6;

const byte r2_control = 9;
const byte g2_control = 10;
const byte b2_control = 11;

unsigned int buf = 0;
byte bufPos = 0;
unsigned int dly = 5;
unsigned int random_mode = 0;
// F = light 1, C = seCond light, A = all lights
char mode = 'a';

#define SIGNATURE 0xcafebabe

enum _colorStates { STATE_NONE, STATE_RED, STATE_GREEN, STATE_BLUE, STATE_SPEED, SEQNO,SEQCOLR,SEQCOLG,SEQCOLB,SEQDELAY, PLAYNO };
byte states = 0;
byte current[6] = {0};
byte goal[6] = {255, 200, 180, 255, 200, 180};
byte pins[6] = {0};
byte isPlaying = 0;
uint32_t lastPlaytime = 0;

struct SequenceEntry {
  byte rgb1[3];
  byte rgb2[3];
  uint16_t duration;
  SequenceEntry *nextEntry;
  
  SequenceEntry() : duration(0), nextEntry(NULL) { memset(rgb1, 0, 3); memset(rgb2, 0, 3); }
  ~SequenceEntry();
};

struct SequenceHeader {
  byte sequenceNumber;
  SequenceEntry *entries;
  
  SequenceHeader(byte _seqNumber) : sequenceNumber(_seqNumber), entries(NULL) {}
  virtual ~SequenceHeader();
};

uint16_t numsequences = 0;
uint16_t seqIndexes[10];
uint32_t seqData[64];

SequenceHeader *currentSequence = NULL;
SequenceEntry *currentEntry = NULL;

void setup() {
  Serial.begin(19200);
  Serial.println("setup begin\n");
  analogWrite(r1_control, 0);
  analogWrite(g1_control, 0);
  analogWrite(b1_control, 0);
  
  pinMode(r1_control, OUTPUT);
  pinMode(g1_control, OUTPUT);
  pinMode(b1_control, OUTPUT);
  
  pins[0] = r1_control;
  pins[1] = g1_control;
  pins[2] = b1_control;

  analogWrite(r2_control, 0);
  analogWrite(g2_control, 0);
  analogWrite(b2_control, 0);
  
  pinMode(r2_control, OUTPUT);
  pinMode(g2_control, OUTPUT);
  pinMode(b2_control, OUTPUT);
  
  pins[3] = r2_control;
  pins[4] = g2_control;
  pins[5] = b2_control;
    Serial.println("setup complete\n");
}

void loop() {
  if (Serial.available()) {
    byte b = Serial.read();
    byte handled = 0;
    while (handled == 0) {
      switch(states) {
        case STATE_RED:
        case STATE_GREEN:
        case STATE_BLUE:
        case STATE_SPEED:
        case PLAYNO:
          handled = handleNumber(b);
          break;
        case SEQNO:
          handled = handleNumber(b);
          if (!handled) {
            states = SEQCOLR;
            handled = 1;
          }
          break;
        case SEQCOLR:
          handled = handleNumber(b);
          if (!handled) {
            if (b == ',') {
              states = SEQCOLG;
            }
            handled = 1;
          }
          break;
        case SEQCOLG:
          handled = handleNumber(b);
          if (!handled) {
            if (b == ',') {
              states = SEQCOLB;
            }
            handled = 1;
          }
          break;
        case SEQCOLB:
          handled = handleNumber(b);
          if (!handled) {
            if (b == ',') {
              states = SEQDELAY;
            }
            handled = 1;
          }
          break;
        case SEQDELAY:
          handled = handleNumber(b);
          if (!handled) {
            if (b == ',') {
              states = SEQCOLR;
              handled = 1;
            } else {
              commitSequence();
              states = STATE_NONE;
            }
          }
          break;
        default:
          handleDefault(b);
          handled = 1;
          break;
      }
    }
  }
  uint8_t bgoal = 1;
  for (int j=0; j < 6; ++j) {
    if (goal[j] != current[j]) {
      bgoal = 0;
      int dir = goal[j] - current[j];
      dir /= abs(dir);
      //Serial.print("dir "); Serial.println((short)dir);
      current[j] += dir;
      analogWrite(pins[j], current[j]);
    }
  }
  if (isPlaying && bgoal && currentEntry) {
    if (millis() - lastPlaytime >= currentEntry->duration) {
      if (lastPlaytime > 0) {
        currentEntry = currentEntry->nextEntry;
        if (!currentEntry) {
          currentEntry = currentSequence->entries;
        }
      }
      for(int j=0; j < 3; ++j) {
        goal[j] = currentEntry->rgb1[j];
        goal[j+3] = currentEntry->rgb2[j];
      }
      lastPlaytime = millis();
    }
  }
  if (random_mode && bgoal) {
    for (int j=0; j < 6; ++j) {
      goal[j] = random() & 0xff;
    }
  }
  delay(dly);
}

void handleDefault(byte d) {
  switch(d) {
    case 'r': case 'R':
      states = STATE_RED;
      return;
    case 'b': case 'B':
      states = STATE_BLUE;
      return;
    case 'g': case 'G':
      states = STATE_GREEN;
      return;
    case 's': case 'S':
      states = STATE_SPEED;
      return;
    case 'n': case 'N':
      random_mode = !random_mode;
      isPlaying = 0;
      break;
    case 'f': case 'F':  // color settings apply to first light only
    case 'c': case 'C':  // color settings apply to second light only
    case 'a': case 'A':  // color settings apply to both lights
      mode = tolower(d);
      break;
    case 'q': case 'Q': {
      Serial.print("Qr");
      Serial.print(goal[0]);
      Serial.print("g");
      Serial.print(goal[1]);
      Serial.print("b");
      Serial.print(goal[2]);
      Serial.print("s");
      Serial.println(dly);
      Serial.print("2r");
      Serial.print(goal[3]);
      Serial.print("g");
      Serial.print(goal[4]);
      Serial.print("b");
      Serial.println(goal[5]);
      break;
    }
    case 'm': case 'M':
      states = SEQNO;
      break;
    case 'p': case 'P':
      states = PLAYNO;
      break;
    case 'h': case 'H':
      Serial.println("\nHELP");
      Serial.println("----");
      Serial.println("All commands are case-insensitive");
      Serial.println("rxxx - set red to xxx, xxx ranges from 0 to 255");
      Serial.println("gxxx - set green to xxx");      
      Serial.println("bxxx - set blue to xxx");
      Serial.println("sxxx - set change speed to xxx");
      Serial.println("q - Query");
      Serial.println("n - raNdom (party) mode");
      Serial.println("f=first, c=seCond,a=all lights");
      Serial.println("m1,ar,ag,ab,bbbb,cr,cg,cb,dddd,... - define sequence x as color aaa, delay bbbb ms, color ccc, delay dddd ms, ...");
      Serial.println("p1 - play sequence x.  X ranges from 0 to 9");
      Serial.println("p0 - stop playing sequence");
      break;
    default:
      return;
  }
}

byte handleNumber(byte r) {
  if (!isdigit(r)) {
    switch (states) {
      case STATE_RED: case STATE_GREEN: case STATE_BLUE: case STATE_SPEED:
        isPlaying = 0;
        setColor();
        break;
      case SEQNO:
        isPlaying = 0;
        currentEntry = NULL;
        startSequence();
        break;
      case SEQCOLR: {
        SequenceEntry *newEntry = new SequenceEntry;
        if (!currentEntry) {
          currentSequence->entries = newEntry;
        } else {
          currentEntry->nextEntry = newEntry;
        }
        currentEntry = newEntry;
        currentEntry->rgb1[0] = buf;
      }
        break;
      case SEQCOLG:
        if (currentEntry) {
          currentEntry->rgb1[1] = buf;
        }
        break;
      case SEQCOLB:
        if (currentEntry) {
          currentEntry->rgb1[2] = buf;
        }
        break;
      case SEQDELAY:
        if (currentEntry) {
          currentEntry->duration = buf;
        }
        break;
      case PLAYNO:
        if (buf > 0) {
          if (!currentSequence) {
            readSequence();
          }
          currentEntry = currentSequence->entries;
          Serial.println("Playing sequence");
          isPlaying = 1;
        } else {
          Serial.println("Stopping sequence");
          isPlaying = 0;
        }
        states = STATE_NONE;
        break;
    }
    buf = 0;
    return 0;
  }
  buf = buf * 10 + (r-'0');
  return 1;
}

void setColor() {
  switch (states) {
    case STATE_RED:
      Serial.print("setting red to "); Serial.println(buf);
      random_mode = 0;
      if (mode == 'f' || mode == 'a') {
        goal[0] = buf;
      }
      if (mode == 'c' || mode == 'a') {
        goal[3] = buf;
      }
      break;
    case STATE_GREEN:
      Serial.print("setting green to "); Serial.println(buf);
      if (mode == 'f' || mode == 'a') {
        goal[1] = buf;
      }
      if (mode == 'c' || mode == 'a') {
        goal[4] = buf;
      }
      random_mode = 0;
      break;
    case STATE_BLUE:
      Serial.print("setting blue to "); Serial.println(buf);
      if (mode == 'f' || mode == 'a') {
        goal[2] = buf;
      }
      if (mode == 'c' || mode == 'a') {
        goal[5] = buf;
      }
      random_mode = 0;
      break;
    case STATE_SPEED:
      Serial.print("setting speed to "); Serial.println(buf);
      dly = buf;
      break;
    default:
      break;
  }
  buf = 0;
  states = STATE_NONE;
}

void startSequence()
{
  if (currentSequence) {
    delete currentSequence;
  }
  currentSequence = new SequenceHeader(buf);
}

void commitSequence()
{
  if (!currentSequence) {
    return;
  }
  Serial.println("saving");
  byte *addr = (byte *)0;
  eeprom_busy_wait();
  eeprom_write_dword((uint32_t *)addr, SIGNATURE);
  addr += 4;
  eeprom_busy_wait();
  eeprom_write_block(currentSequence, addr, sizeof(SequenceHeader));
  addr += sizeof(SequenceHeader);
  for (SequenceEntry *entry = currentSequence->entries; entry; entry = entry->nextEntry) {
    eeprom_busy_wait();
    eeprom_write_block(entry, addr, sizeof(SequenceEntry));
    addr += sizeof(SequenceEntry);
  }
  Serial.println("Saved");
}

void readSequence()
{
  delete currentSequence;
  currentSequence = NULL;
  byte *addr = (byte *)0;
  eeprom_busy_wait();
  if (eeprom_read_dword((uint32_t *)addr) != SIGNATURE) {
    Serial.println("bad sig");
    return;
  }
  addr += 4;
  currentSequence = new SequenceHeader(0);
  eeprom_busy_wait();
  eeprom_read_block(currentSequence, addr, sizeof(SequenceHeader));
  addr += sizeof(SequenceHeader);
  bool first = true;
  for (currentEntry = currentSequence->entries; currentEntry; ) {
    SequenceEntry *newEntry = new SequenceEntry;
    eeprom_busy_wait();
    eeprom_read_block(newEntry, addr, sizeof(SequenceEntry));
    addr += sizeof(SequenceEntry);
    if (first) {
      currentSequence->entries = newEntry;
      first = false;
    } else {
      currentEntry->nextEntry = newEntry;
    }
    currentEntry = newEntry;
    if (currentEntry->nextEntry == NULL) {
      break;
    }
  }
  Serial.println("read sequence");
}

SequenceHeader::~SequenceHeader()
{
  delete entries;
}
  
SequenceEntry::~SequenceEntry()
{
  if (this->nextEntry) {
    delete this->nextEntry;
  }
}

