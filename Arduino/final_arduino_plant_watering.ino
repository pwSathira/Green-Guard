#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <math.h> // isnan(), round()
#include <stdlib.h> // randomSeed()
#include <Arduino.h>

// --- Pin Definitions (Raspberry Pi Pico GP numbers) ---
#define MOSFET_PIN 22 // GP22 → HW‑042 MOSFET SIG (pump control)
#define DHTPIN 20 // GP20 → DHT11 data
#define DHTTYPE DHT11
#define MOISTURE_SENSOR_PIN 26 // GP26/A0 → Moisture sensor

// --- Binary‑output pins for DE10‑Lite (unchanged) ---
// Humidity: 6 bits (0–63) on GP2,3,6,7,10,11 (LSB→MSB)
const int humidityPins[] = {2, 3, 6, 7, 10, 11};
const int numHumidityPins = 6;
// Moisture: 3 bits (0–7) on GP16,27,28 (LSB→MSB)
const int moisturePins[] = {16, 27, 28};
const int numMoisturePins = 3;

// --- Configuration for scaling moisture ---
const int MAX_RAW_MOISTURE = 1028; // your observed full‑wet ADC reading

DHT dht(DHTPIN, DHTTYPE);

// Prototypes
void setBinaryOutput(int value, const int pins[], int n);
String intToBinaryStringLSBFirst(int value, int n);

void setup() {
Serial.begin(115200);
while (!Serial) delay(10);
delay(500);
Serial.println("--- Pico Sensor Hub Initializing ---");

// Init humidity output pins
for (int i = 0; i < numHumidityPins; i++) {
pinMode(humidityPins[i], OUTPUT);
digitalWrite(humidityPins[i], LOW);
}
// Init moisture output pins
for (int i = 0; i < numMoisturePins; i++) {
pinMode(moisturePins[i], OUTPUT);
digitalWrite(moisturePins[i], LOW);
}
// Seed RNG
pinMode(27, INPUT);
randomSeed(analogRead(27));
// Init DHT sensor
dht.begin();
// Init MOSFET pin (pump off)
pinMode(MOSFET_PIN, OUTPUT);
digitalWrite(MOSFET_PIN, LOW);

Serial.println("--- Initialization Complete ---");
}

void loop() {
delay(2000);

// --- Read sensors ---
float h = dht.readHumidity();
float t = dht.readTemperature();
uint16_t rawM = analogRead(MOISTURE_SENSOR_PIN);

if (isnan(h) || isnan(t)) {
Serial.println("DHT read failed!");
return;
}

// --- Process humidity (0–63) ---
int h_int = constrain((int)round(h), 0, 63);
String hb = intToBinaryStringLSBFirst(h_int, numHumidityPins);

// --- Process moisture (0–7) ---
float f = (float)rawM / MAX_RAW_MOISTURE * 7.0;
int m = constrain((int)round(f), 0, 7);
String mb = intToBinaryStringLSBFirst(m, numMoisturePins);

// --- Debug prints ---
Serial.printf(
"Humidity: raw=%.1f%% → scaled=%d → bin(LSB→MSB)=%s\n",
h, h_int, hb.c_str()
);
Serial.printf(
"Moisture: raw=%u → scaled=%d → bin(LSB→MSB)=%s\n",
rawM, m, mb.c_str()
);
Serial.printf("Temperature: %.1f°C\n\n", t);

// --- Drive DE10‑Lite binary lines ---
setBinaryOutput(h_int, humidityPins, numHumidityPins);
setBinaryOutput(m, moisturePins, numMoisturePins);

// --- Pump control: ON when moisture is 6 or 7 (dry) ---
if (m >= 7) {
digitalWrite(MOSFET_PIN, HIGH);
Serial.println("Pump ON (dry soil)");
} else {
digitalWrite(MOSFET_PIN, LOW);
Serial.println("Pump OFF (moist soil)");
}
}

// Write bits 0…n−1 of value out on pins[0…n−1]
void setBinaryOutput(int value, const int pins[], int n) {
for (int i = 0; i < n; i++) {
digitalWrite(pins[i], ((value >> i) & 1) ? HIGH : LOW);
}
}

// Build a String of bits LSB→MSB for debug printing
String intToBinaryStringLSBFirst(int value, int n) {
String s;
for (int i = 0; i < n; i++) {
s += ((value >> i) & 1) ? '1' : '0';
}
return s;
}