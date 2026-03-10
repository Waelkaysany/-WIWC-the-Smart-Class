/*
 * ═══════════════════════════════════════════════════════════════
 *  WIWC Smart Classroom — ESP32 + RFID (MFRC522) Attendance + LEDs
 *  Writes student attendance to Firebase Realtime Database
 *  Reads LED state from Firebase to control lights
 * ═══════════════════════════════════════════════════════════════
 *
 *  Wiring (ESP32 → MFRC522):
 *    3.3V  → VCC
 *    GND   → GND
 *    D18   → SCK
 *    D23   → MOSI
 *    D19   → MISO
 *    D5    → SDA (SS)
 *    D22   → RST
 *
 *  LED Wiring (ESP32):
 *    D12   → LED1
 *    D13   → LED2
 *    D14   → LED3
 *
 *  Libraries needed (install via Arduino Library Manager):
 *    1. MFRC522 by GithubCommunity
 *    2. Firebase Arduino Client Library for ESP8266 and ESP32 (by mobizt)
 *    3. WiFi (built-in for ESP32)
 */

#include <Firebase_ESP_Client.h>
#include <MFRC522.h>
#include <SPI.h>
#include <WiFi.h>
#include <addons/RTDBHelper.h>
#include <addons/TokenHelper.h>

// ═══════════════════════════════════════════
//  🔧 CONFIGURATION — EDIT THESE
// ═══════════════════════════════════════════

// WiFi credentials — CHANGE THESE TO YOUR NETWORK
#define WIFI_SSID "YOUR_WIFI_NAME"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase — already configured for your project
#define FIREBASE_API_KEY "AIzaSyCiXjjBLZnMCyKhzYQUv8Tz2fYSHbpwepo"
#define FIREBASE_DATABASE_URL                                                  \
  "https://wiwc-smartclass-default-rtdb.firebaseio.com/"

// RFID Pins
#define SS_PIN 5
#define RST_PIN 22

// LED Pins (from your code)
#define LED1 12
#define LED2 13
#define LED3 14

// ═══════════════════════════════════════════
//  Internal state
// ═══════════════════════════════════════════

MFRC522 mfrc522(SS_PIN, RST_PIN);
FirebaseData fbdo;
FirebaseData streamDo; // Dedicated to streaming LED changes
FirebaseAuth auth;
FirebaseConfig config;

int studentsPresent = 0;

// Track which cards are currently checked in (max 40 students)
#define MAX_STUDENTS 40
String checkedInCards[MAX_STUDENTS];
int checkedInCount = 0;

// LED State
bool ledState = false;

// ═══════════════════════════════════════════
//  Setup
// ═══════════════════════════════════════════

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n═══════════════════════════════════════");
  Serial.println("  WIWC Smart Classroom — ESP32 + RFID");
  Serial.println("═══════════════════════════════════════\n");

  // LEDs
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  digitalWrite(LED1, LOW);
  digitalWrite(LED2, LOW);
  digitalWrite(LED3, LOW);

  // Initialize SPI and RFID
  SPI.begin();
  mfrc522.PCD_Init();
  Serial.println("✅ RFID reader initialized");

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("📶 Connecting to WiFi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("✅ Connected! IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi connection failed! Check SSID and password.");
    return;
  }

  // Configure Firebase
  config.api_key = FIREBASE_API_KEY;
  config.database_url = FIREBASE_DATABASE_URL;

  // Sign in anonymously
  Firebase.signUp(&config, &auth, "", "");
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Wait for Firebase to be ready
  Serial.print("🔑 Connecting to Firebase");
  int fbAttempts = 0;
  while (!Firebase.ready() && fbAttempts < 20) {
    delay(500);
    Serial.print(".");
    fbAttempts++;
  }

  if (Firebase.ready()) {
    Serial.println("\n✅ Firebase connected!");

    // Start listening for LED changes from Firebase App
    if (Firebase.RTDB.beginStream(&streamDo,
                                  "/classroom/devices/esp_leds/isOn")) {
      Serial.println("✅ Started streaming ESP LEDs state from app");
    } else {
      Serial.println("❌ Failed to begin stream for ESP LEDs");
    }

  } else {
    Serial.println("\n❌ Firebase connection failed!");
    return;
  }

  // Sync initial students count
  if (Firebase.RTDB.getInt(&fbdo, "classroom/sensors/studentsPresent")) {
    studentsPresent = fbdo.intData();
    Serial.print("Initial students present from DB: ");
    Serial.println(studentsPresent);
  } else {
    studentsPresent = 0;
  }

  // Blink LED to show ready
  digitalWrite(LED1, HIGH);
  digitalWrite(LED2, HIGH);
  digitalWrite(LED3, HIGH);
  delay(500);
  digitalWrite(LED1, LOW);
  digitalWrite(LED2, LOW);
  digitalWrite(LED3, LOW);

  Serial.println("\n🎯 Ready! Tap an RFID card to check in/out...\n");
}

// ═══════════════════════════════════════════
//  Main Loop
// ═══════════════════════════════════════════

void loop() {
  // 1. Reconnect WiFi if needed
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️ WiFi disconnected, reconnecting...");
    WiFi.reconnect();
    delay(5000);
    return;
  }

  // 2. Listen for Firebase Stream events (App -> ESP32)
  if (Firebase.ready()) {
    if (Firebase.RTDB.readStream(&streamDo)) {
      if (streamDo.streamTimeout()) {
        Serial.println("Stream timeout, resuming...");
      }

      if (streamDo.streamAvailable()) {
        // App toggled the LEDs switch!
        if (streamDo.dataType() == "boolean") {
          ledState = streamDo.boolData();
          Serial.print("📱 App updated LED State: ");
          Serial.println(ledState ? "ON" : "OFF");

          digitalWrite(LED1, ledState ? HIGH : LOW);
          digitalWrite(LED2, ledState ? HIGH : LOW);
          digitalWrite(LED3, ledState ? HIGH : LOW);
        }
      }
    }
  }

  // 3. Check for new RFID card (ESP32 -> App)
  if (!mfrc522.PICC_IsNewCardPresent()) {
    return;
  }
  if (!mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  // Blink indicator for card read
  digitalWrite(LED1, !ledState); // Toggle briefly based on current state
  delay(100);
  digitalWrite(LED1, ledState);

  // Read card UID
  String cardUID = getCardUID();
  Serial.print("📇 Card detected: ");
  Serial.println(cardUID);

  // Toggle check-in/check-out
  bool wasCheckedIn = isCardCheckedIn(cardUID);

  if (wasCheckedIn) {
    // ── CHECK OUT ──
    removeCard(cardUID);
    studentsPresent = max(0, studentsPresent - 1);
    Serial.print("🔴 CHECK OUT → Students present: ");
    Serial.println(studentsPresent);
  } else {
    // ── CHECK IN ──
    addCard(cardUID);
    studentsPresent++;
    Serial.print("🟢 CHECK IN  → Students present: ");
    Serial.println(studentsPresent);
  }

  // Write to Firebase RTDB
  writeStudentCount();
  writeAttendanceRecord(cardUID, !wasCheckedIn);

  // Halt card to prevent repeated reads
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();

  delay(1000); // Debounce — prevents double-read
}

// ═══════════════════════════════════════════
//  Card Management
// ═══════════════════════════════════════════

String getCardUID() {
  String uid = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10)
      uid += "0";
    uid += String(mfrc522.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  return uid;
}

bool isCardCheckedIn(String uid) {
  for (int i = 0; i < checkedInCount; i++) {
    if (checkedInCards[i] == uid)
      return true;
  }
  return false;
}

void addCard(String uid) {
  if (checkedInCount < MAX_STUDENTS) {
    checkedInCards[checkedInCount] = uid;
    checkedInCount++;
  }
}

void removeCard(String uid) {
  for (int i = 0; i < checkedInCount; i++) {
    if (checkedInCards[i] == uid) {
      for (int j = i; j < checkedInCount - 1; j++) {
        checkedInCards[j] = checkedInCards[j + 1];
      }
      checkedInCount--;
      break;
    }
  }
}

// ═══════════════════════════════════════════
//  Firebase Operations
// ═══════════════════════════════════════════

void writeStudentCount() {
  if (!Firebase.ready()) {
    Serial.println("  ⚠️ Firebase not ready");
    return;
  }

  // This is the value your Flutter app reads
  if (Firebase.RTDB.setInt(&fbdo, "classroom/sensors/studentsPresent",
                           studentsPresent)) {
    Serial.print("  ✅ Firebase updated: studentsPresent = ");
    Serial.println(studentsPresent);
  } else {
    Serial.print("  ❌ Firebase error: ");
    Serial.println(fbdo.errorReason());
  }
}

void writeAttendanceRecord(String cardUID, bool checkedIn) {
  if (!Firebase.ready())
    return;

  String path = "classroom/attendance/" + cardUID;

  FirebaseJson json;
  json.set("checkedIn", checkedIn);
  json.set("timestamp", (int)(millis() / 1000));

  if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {
    Serial.println("  ✅ Attendance record saved");
  } else {
    Serial.print("  ❌ Attendance error: ");
    Serial.println(fbdo.errorReason());
  }
}
