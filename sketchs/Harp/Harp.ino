int notes [24];
int prevNote [24];
int notePins[] = {22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 45}; 
int instruments[] = {46, 0, 24, 40, 56, 65, 73, 33, 14, 19, 30};
int BUTTON_PIN = 18;
int COMAND_ON = 0x90;
int COMAND_OFF = 0x80;
int lastInstrument = 0;
volatile int instrNumber = 0;
volatile unsigned long lastRead;
boolean playFirst;
unsigned long lastPlayTime = 0;

void setup() {
  pinMode(46, OUTPUT);
  instrNumber = 0;
  lastRead = 0;
  
  for (int i = 0; i < 24; i++) {
    pinMode(notePins[i], INPUT);
  }
  for (int i = 0; i < 24; i++) {
    prevNote[i] = 0;
  }
  
  analogWrite(46, 50);
  Serial.begin(38400);
  attachInterrupt(5, onButtonPressed, CHANGE); 
  playFirst = true;
}

void loop() {
  
  for (int i = 0; i < 24; i++) {
    notes[i] = 0;
  }
  
  for (int i = 0; i < 100; i++) {
    for (int j = 0; j < 24; j++) {
      if (digitalRead(notePins[j])) {notes[j] = 1;}
    }
  }
  
  if (lastInstrument != instrNumber) {
  for (int i = 0; i < 24; i++) {
    if (prevNote[i] = 0) {
      playNote(i, 0, 127, 1);
      prevNote[i] = 1;
    }
  }
    Serial.write(0xC0);
    Serial.write(instruments[instrNumber] & 0x7F);
    lastInstrument = instrNumber;
  }

  for (int i = 0; i < 24; i++) {
    if (prevNote[i] != notes[i]) {
      playNote(i, 0, 127, notes[i]);
      prevNote[i] = notes[i];
    }
  }

  if ((millis() - lastPlayTime) > 60000) {
    Serial.write(0xC0);
    Serial.write(instruments[0] & 0x7F); 
  }
}

void onButtonPressed() {
  if (((millis() - lastRead) > 200) && digitalRead(BUTTON_PIN))  {
    instrNumber = instrNumber + 1;
    if (instrNumber > 10) {instrNumber = 0;}
  }
  lastRead = millis();
}

void playNote(int note, int channel, int velocity, int noteOff) {
  int cmd;
  if (noteOff) {cmd = COMAND_OFF;}
  else {cmd = COMAND_ON;}
  cmd = cmd  | (channel & 0x0F);
  if (playFirst) {
    Serial.write(0xC0);
    Serial.write(instruments[0] & 0x7F);  
    playFirst = false;
  }
  Serial.write(cmd);
  Serial.write(48 + note);
  Serial.write(velocity);
  lastPlayTime = millis();
}
