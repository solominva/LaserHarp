//#include <ardumidi.h>

int notes [24];
int prevNote [24];
int notePins[] = {22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 45}; 
int BUTTON_PIN = 18;
int COMAND_ON = 0x90;
int COMAND_OFF = 0x80;
unsigned long lastRead;
int instrument;
int analog11;
int note_on = 0;

void setup() {
  pinMode(46, OUTPUT);
  instrument = 0;
  lastRead = 0;
  
  for (int i = 0; i < 24; i++) {
    pinMode(notePins[i], INPUT);
  }
  for (int i = 0; i < 24; i++) {
    prevNote[i] = 1;
  }
  
  analogWrite(46, 50);
  Serial.begin(38400);
  readAllInputs();
}

void loop() {
  
  if ((millis() - lastRead) > 200)  {
    analog11 = analogRead(A11);
    if (analog11 > 500) {
      instrument = instrument + 1;
      //Serial.write(0xC0);
      //Serial.write(instrument & 0x7F);
      //Serial.println(chanelNumber);
    }
    if (instrument > 64) {instrument = 0;}
    lastRead = millis();
    
  }
 
  readAllInputs();
  
  for (int i = 0; i < 24; i++) {
    if (prevNote[i] != notes[i]) {
      playNote(i, 0, 127, notes[i]);
      prevNote[i] = notes[i];
    }
  
  /*playNote(0, 0, 120, note_on);
  if (note_on) {note_on = 0;}
  else {note_on = 1;}
  delay(1000);*/
}
}

void playNote(int note, int channel, int velocity, int noteOff) {
  int cmd;
  if (noteOff) {cmd = COMAND_OFF;}
  else {cmd = COMAND_ON;}
  cmd = cmd  | (channel & 0x0F);
  
  //midi_note_on(chanel, 
  //Serial.write(0xA0+chanel);
  //Serial.write(60 + convertNote(note));
  //Serial.write(120);
  
  Serial.write(cmd);
  Serial.write(60 + convertNote(note));
  Serial.write(velocity);
  //if (noteOff) {Serial.write(velocity);}
  //else {Serial.write(0x00);}
  //delay(500);
}

void readAllInputs() {
  
  for (int i = 0; i < 24; i++) {
  notes[i] = 1;
  }
  for (int i = 0; i < 1000; i++) {
    for (int j = 0; j < 24; j++) {
      if (!digitalRead(notePins[j])) {notes[j] = 0;}
    }
  }
}

int convertNote(int note) {
  return note;
  }  

