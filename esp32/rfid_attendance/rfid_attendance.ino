/*
 * ═══════════════════════════════════════════════════════════════
 *  WIWC Smart Classroom — ESP32 HTTP REST API (FULL VERSION)
 *
 *  Auto-Discovery: broadcasts "WIWC_ESP32:{ip}" on UDP port 4210
 *  every 3 seconds so the phone app connects automatically.
 *
 *  Devices:
 *    DHT11  → Temperature & Humidity   (pin 4)
 *    LDR    → Light level              (pin 34)
 *    Flame  → Fire sensor              (pin 14)
 *    RFID   → Attendance               (SPI: SS=5, RST=22)
 *    LED 1  → Main ceiling light       (pin 26)   ← PWM
 *    LED 2  → Window-side light        (pin 27)   ← PWM
 *    Servo  → Window open/close        (pin 13)
 *    Buzzer → Alerts                   (pin 32)
 *
 *  HTTP Endpoints:
 *    GET /data                                   → all sensor+device JSON
 *    GET /control?device=X&state=on|off          → control a device
 *      devices: light_1, light_2, window_left, window_right, door
 *    Optional: &brightness=0.00-1.00  (for lights)
 * ═══════════════════════════════════════════════════════════════
 */

// ── Library Includes
// ──────────────────────────────────────────────────────────
#include <DHT.h>
#include <ESP32Servo.h> // Install: Sketch → Library → "ESP32Servo"
#include <HTTPClient.h>
#include <LiquidCrystal_I2C.h>
#include <MFRC522.h>
#include <SPI.h>
#include <WebServer.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <WiFiUdp.h> // For UDP auto-discovery broadcast
#include <Wire.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

// ── Configuration
// ─────────────────────────────────────────────────────────────

const char *WIFI_SSID = "http";          // Your phone hotspot / home WiFi
const char *WIFI_PASSWORD = "wail00000"; // WiFi password

// Optional Google Sheets attendance logging
const char *GOOGLE_SHEET_URL = "https://script.google.com/macros/s/"
                               "AKfycbx2FdKwwW4OTZRI23TWjEEpn8gpwaTsD3ziWDeZGvt"
                               "Q5kcgArIhQz7IXGrJs4mKY1Gx/exec";

// Firebase RTDB
// The database rules are open (.read/.write = true), so no auth needed.
const char *FIREBASE_DB_URL =
    "https://wiwc-smartclass-default-rtdb.firebaseio.com";
const char *CLASSROOM_ID = "a8";

// ── Pin Definitions
// ───────────────────────────────────────────────────────────
#define SS_PIN 5   // RFID SDA/SS
#define RST_PIN 27 // RFID Reset
#define DHTPIN 4   // DHT11 data pin
#define DHTTYPE DHT11
#define FLAME_SENSOR_PIN 14 // KY-026 flame sensor (HIGH = fire detected)
#define LDR_PIN 34          // Analog LDR (light level)
#define BUZZER_PIN 32       // Passive buzzer
#define SERVO_PIN 13        // Servo motor for window control
#define LED1_PIN 25         // Used as Green/Ceiling light
#define LED2_PIN 26         // Used as Red/Window light
#define LIGHT_LED_PIN 33    // Extra light LED

// ── Auto-Discovery Settings
// ───────────────────────────────────────────────────
#define DISCOVERY_UDP_PORT 4210 // Flutter listens on this port
#define DISCOVERY_INTERVAL 3000 // Send broadcast every 3 seconds (ms)
const char *DISCOVERY_PREFIX = "WIWC_ESP32:";

// ── Hardware Objects
// ──────────────────────────────────────────────────────────
MFRC522 rfid(SS_PIN, RST_PIN);
DHT dht(DHTPIN, DHTTYPE);
Servo windowServo;
WebServer server(80);
WiFiUDP udp;

// ── Global Sensor State
// ───────────────────────────────────────────────────────
float currentTemp = 0.0;
float currentHum = 0.0;
int currentLight = 0;
bool isFlameDetected = false;
int studentsPresent = 0;
String lastScannedUser = "None";
String lastScannedUID = "None";

// ── Device States
// ─────────────────────────────────────────────────────────────
bool light1On = false;
float light1Brightness = 1.0;
bool light2On = false;
float light2Brightness = 1.0;
bool doorOpened = false;
bool windowOpen = false; // false = closed (0°), true = open (90°)

// ── Timers
// ────────────────────────────────────────────────────────────────────
unsigned long prevSensor = 0;
unsigned long prevDiscovery = 0;
unsigned long prevAlarm = 0; // For fire-alarm LED blink timing
bool alarmLedState = false;  // Tracks blink state of fire LED

// =============================================================================
//  Helper: Apply LED brightness via PWM
// =============================================================================
void applyLight1() {
  int duty = light1On ? (int)(light1Brightness * 255) : 0;
  ledcWrite(LED1_PIN, duty);
}

void applyLight2() {
  int duty = light2On ? (int)(light2Brightness * 255) : 0;
  ledcWrite(LED2_PIN, duty);
}

// =============================================================================
//  Helper: Move the servo (window)
// =============================================================================
void applyWindowServo() { windowServo.write(windowOpen ? 90 : 0); }

// =============================================================================
//  Helper: Add CORS headers so the phone can talk to this server
// =============================================================================
void addCors() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

// =============================================================================
//  HTTP Handler: GET /
// =============================================================================
void handleRoot() {
  addCors();
  String ip = WiFi.localIP().toString();
  String msg = "<h2>WIWC IoT Unit Online</h2><p>IP: " + ip +
               "</p>"
               "<p>Use <a href='/data'>/data</a> to read sensors.</p>";
  server.send(200, "text/html; charset=utf-8", msg);
}

// =============================================================================
//  HTTP Handler: GET /data
//  Returns full sensor + device state in JSON
// =============================================================================
void handleData() {
  addCors();
  String json = "{";
  json += "\"temp\":" + String(currentTemp, 1) + ",";
  json += "\"hum\":" + String(currentHum, 1) + ",";
  json += "\"light\":" + String(currentLight) + ",";
  json += "\"fire\":" + String(isFlameDetected ? 1 : 0) + ",";
  json += "\"studentsPresent\":" + String(studentsPresent) + ",";
  json += "\"lastUser\":\"" + lastScannedUser + "\",";
  json += "\"lastUID\":\"" + lastScannedUID + "\",";
  json += "\"devices\":{";
  json += "\"light_1\":{\"isOn\":" + String(light1On ? "true" : "false") +
          ",\"brightness\":" + String(light1Brightness, 2) + "},";
  json += "\"light_2\":{\"isOn\":" + String(light2On ? "true" : "false") +
          ",\"brightness\":" + String(light2Brightness, 2) + "},";
  json += "\"window_left\":{\"isOn\":" + String(windowOpen ? "true" : "false") +
          "},";
  json +=
      "\"window_right\":{\"isOn\":" + String(windowOpen ? "true" : "false") +
      "},";
  json += "\"door\":{\"isOn\":" + String(doorOpened ? "true" : "false") + "}";
  json += "}}";
  server.send(200, "application/json", json);
}

// =============================================================================
//  HTTP Handler: GET /control?device=X&state=on|off[&brightness=0.00-1.00]
// =============================================================================
void handleControl() {
  addCors();

  if (!server.hasArg("device")) {
    server.send(400, "application/json", "{\"error\":\"Missing device arg\"}");
    return;
  }

  String device = server.arg("device");
  String st = server.hasArg("state") ? server.arg("state") : "";
  bool turnOn = (st == "on");

  if (device == "light_1") {
    if (st != "")
      light1On = turnOn;
    if (server.hasArg("brightness"))
      light1Brightness = server.arg("brightness").toFloat();
    applyLight1();
  } else if (device == "light_2") {
    if (st != "")
      light2On = turnOn;
    if (server.hasArg("brightness"))
      light2Brightness = server.arg("brightness").toFloat();
    applyLight2();
  } else if (device == "window_left" || device == "window_right") {
    if (st != "")
      windowOpen = turnOn;
    applyWindowServo();
  } else if (device == "door") {
    if (st != "")
      doorOpened = turnOn;
    // Add door solenoid/relay logic here if needed
    Serial.println("Door → " + String(doorOpened ? "UNLOCKED" : "LOCKED"));
  } else {
    server.send(400, "application/json",
                "{\"error\":\"Unknown device: " + device + "\"}");
    return;
  }

  server.send(200, "application/json",
              "{\"ok\":true,\"device\":\"" + device + "\",\"state\":\"" + st +
                  "\"}");
}

// =============================================================================
//  Helper: Write scanned UID directly to Firebase RTDB
//  This removes the Flutter polling-based bridge entirely — Flutter just
//  watches  classrooms/{id}/last_scanned_id  and reacts in real time.
// =============================================================================
void sendToFirebase(String uid) {
  if (WiFi.status() != WL_CONNECTED)
    return;

  WiFiClientSecure client;
  client.setInsecure(); // Required for HTTPS without providing root certs

  HTTPClient http;
  // PUT "\"UID_VALUE\"" to .../last_scanned_id.json
  String url = String(FIREBASE_DB_URL) + "/classrooms/" + String(CLASSROOM_ID) +
               "/last_scanned_id.json";
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  String payload = "\"" + uid + "\"";
  int code = http.PUT(payload);
  Serial.println("Firebase PUT → " + String(code) + " (" + uid + ")");
  http.end();
}

void sendToGoogleSheet(String name, String uid) {
  if (WiFi.status() != WL_CONNECTED)
    return;
  HTTPClient http;
  http.begin(GOOGLE_SHEET_URL);
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  int code = http.POST("name=" + name + "&uid=" + uid);
  Serial.println("Sheets → " + String(code));
  http.end();
}

// =============================================================================
//  SETUP
// =============================================================================
void setup() {
  Serial.begin(115200);
  delay(200);

  // Init sensors & peripherals
  SPI.begin();
  rfid.PCD_Init();
  dht.begin();

  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connecting");

  pinMode(FLAME_SENSOR_PIN, INPUT);
  pinMode(LDR_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LIGHT_LED_PIN, OUTPUT);

  // LED PWM init  (ESP-IDF ledcAttach)
  ledcAttach(LED1_PIN, 5000, 8);
  ledcAttach(LED2_PIN, 5000, 8);
  applyLight1(); // Start OFF
  applyLight2();

  // Servo init
  windowServo.attach(SERVO_PIN, 500, 2400);
  applyWindowServo(); // Start closed

  // ── Connect to WiFi ──
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 40) {
    delay(500);
    Serial.print(".");
    tries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    String ip = WiFi.localIP().toString();
    Serial.println("\n✅ WiFi Connected!");
    Serial.println("📍 IP Address: " + ip);

    // Open UDP socket for broadcasting
    udp.begin(DISCOVERY_UDP_PORT);
    Serial.println("📡 UDP broadcast enabled on port " +
                   String(DISCOVERY_UDP_PORT));
  } else {
    Serial.println("\n❌ WiFi Failed! Running without network.");
  }

  // ── HTTP Server Routes ──
  server.on("/", handleRoot);
  server.on("/data", handleData);
  server.on("/control", handleControl);
  server.begin();
  Serial.println("🎯 HTTP Server started on port 80.");
}

// =============================================================================
//  LOOP
// =============================================================================
void loop() {
  // Handle HTTP requests
  server.handleClient();

  unsigned long now = millis();

  // ── 1. Read sensors every 2 seconds ──────────────────────────────────────
  if (now - prevSensor >= 2000) {
    prevSensor = now;

    float h = dht.readHumidity();
    float t = dht.readTemperature();
    if (!isnan(h) && !isnan(t)) {
      currentHum = h;
      currentTemp = t;
    }

    int ldrRaw = analogRead(LDR_PIN);
    currentLight = map(ldrRaw, 0, 4095, 0, 100);

    isFlameDetected = (digitalRead(FLAME_SENSOR_PIN) == HIGH);

    Serial.printf("📡 Temp=%.1f°C  Hum=%.1f%%  Light=%d%%  Fire=%s\n",
                  currentTemp, currentHum, currentLight,
                  isFlameDetected ? "YES" : "no");

    // If no fire, make sure alarm LED is off
    if (!isFlameDetected) {
      digitalWrite(LIGHT_LED_PIN, LOW);
      alarmLedState = false;
    }
  }

  // ── 2. RFID Scan ──────────────────────────────────────────────────────────
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    // Build uppercase hex UID correctly
    String uid = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      if (rfid.uid.uidByte[i] < 0x10)
        uid += "0";
      uid += String(rfid.uid.uidByte[i], HEX);
    }
    uid.toUpperCase(); // Arduino String mutates in-place

    lastScannedUID = uid;
    lastScannedUser = "Card: " + uid;

    Serial.println("🪪 RFID: " + uid);
    tone(BUZZER_PIN, 1800, 150);

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Card Scanned!");
    lcd.setCursor(0, 1);
    lcd.print(uid);

    // Push UID to Firebase so Flutter reacts instantly (no poll needed)
    sendToFirebase(uid);
    sendToGoogleSheet(lastScannedUser, uid);

    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();

    // Short delay so the same card is not double-scanned in the next loop tick.
    delay(500);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Scan your card");
  }

  // ── 3. Fire Alarm: blink Light 3 + wail buzzer ─────────────────────────────
  // Runs every 150ms — fast blink and high-pitch continuous alarm
  if (isFlameDetected && now - prevAlarm >= 150) {
    prevAlarm = now;
    alarmLedState = !alarmLedState;
    digitalWrite(LIGHT_LED_PIN, alarmLedState ? HIGH : LOW);
    tone(BUZZER_PIN, alarmLedState ? 2000 : 2500,
         140); // alternating high tones
  }

  // ── 4. UDP Auto-Discovery Broadcast ──────────────────────────────────────
  // Sends "WIWC_ESP32:{ip}" every 3 seconds so the phone finds us automatically
  if (WiFi.status() == WL_CONNECTED &&
      now - prevDiscovery >= DISCOVERY_INTERVAL) {
    prevDiscovery = now;

    String message = String(DISCOVERY_PREFIX) + WiFi.localIP().toString();

    // Broadcast to 255.255.255.255 on the discovery port
    udp.beginPacket(IPAddress(255, 255, 255, 255), DISCOVERY_UDP_PORT);
    udp.print(message);
    udp.endPacket();
  }
}
