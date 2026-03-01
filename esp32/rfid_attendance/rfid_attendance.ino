/*
 * ═══════════════════════════════════════════════════════════════
 *  WIWC Smart Classroom — ESP32 + RFID (MFRC522) Attendance
 *  Writes student attendance to Firebase Realtime Database
 * ═══════════════════════════════════════════════════════════════
 *
 *  Wiring (Arduino Nano ESP32 → MFRC522):
 *    3.3V  → VCC
 *    GND   → GND
 *    D13   → SCK
 *    D11   → MOSI
 *    D12   → MISO
 *    D10   → SDA (SS)
 *    D9    → RST
 *    D2    → LED (built-in on most boards)
 *
 *  Libraries needed (install via Arduino Library Manager):
 *    1. MFRC522 by GithubCommunity
 *    2. Firebase Arduino Client Library for ESP8266 and ESP32 (by mobizt)
 *    3. WiFi (built-in for ESP32)
 *
 *  How it works:
 *    - ESP32 reads RFID card UIDs
 *    - Each unique card UID = one student
 *    - First tap = CHECK IN  (studentsPresent++)
 *    - Second tap = CHECK OUT (studentsPresent--)
 *    - Writes to Firebase RTDB:
 *        classroom/sensors/studentsPresent = <count>
 *        classroom/attendance/<cardUID> = { checkedIn: true/false, lastScan:
 * ... }
 */

#include <Firebase_ESP_Client.h>
#include <MFRC522.h>
#include <SPI.h>
#include <WiFi.h>
#include <addons/RTDBHelper.h>
#include <addons/TokenHelper.h>


// ═══════════════════════════════════════════
//  🔧 CONFIGURATION — EDIT THESE 2 VALUES
// ═══════════════════════════════════════════

// WiFi credentials — CHANGE THESE TO YOUR NETWORK
#define WIFI_SSID "UH2CGUEST"
#define WIFI_PASSWORD "uh2c@2021"

// Firebase — already configured for your project (no auth needed)
#define FIREBASE_API_KEY "AIzaSyCiXjjBLZnMCyKhzYQUv8Tz2fYSHbpwepo"
#define FIREBASE_DATABASE_URL                                                  \
  "https://wiwc-smartclass-default-rtdb.firebaseio.com/"

// RFID Pins (Specific to Arduino Nano ESP32)
#define SS_PIN 10 // D10
#define RST_PIN 9 // D9

// LED pin (built-in LED on Nano ESP32 is D13, but let's use D2 for external led
// or pin D2)
#define LED_PIN 2 // D2

// ═══════════════════════════════════════════
//  Internal state
// ═══════════════════════════════════════════

MFRC522 rfid(SS_PIN, RST_PIN);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

int studentsPresent = 0;

// Track which cards are currently checked in (max 40 students)
#define MAX_STUDENTS 40
String checkedInCards[MAX_STUDENTS];
int checkedInCount = 0;

// ═══════════════════════════════════════════
//  Setup
// ═══════════════════════════════════════════

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n═══════════════════════════════════════");
  Serial.println("  WIWC Smart Classroom — ESP32 RFID");
  Serial.println("═══════════════════════════════════════\n");

  // LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // Initialize SPI and RFID
  SPI.begin();
  rfid.PCD_Init();
  rfid.PCD_DumpVersionToSerial();
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

  // Configure Firebase (anonymous — no auth needed since rules are open)
  config.api_key = FIREBASE_API_KEY;
  config.database_url = FIREBASE_DATABASE_URL;

  // Sign in anonymously (no email/password needed)
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
  } else {
    Serial.println("\n❌ Firebase connection failed!");
    return;
  }

  // Reset student count to 0 on startup
  studentsPresent = 0;
  writeStudentCount();

  // Blink LED to show ready
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(200);
    digitalWrite(LED_PIN, LOW);
    delay(200);
  }

  Serial.println("\n🎯 Ready! Tap an RFID card to check in/out...\n");
}

// ═══════════════════════════════════════════
//  Main Loop
// ═══════════════════════════════════════════

void loop() {
  // Reconnect WiFi if needed
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️ WiFi disconnected, reconnecting...");
    WiFi.reconnect();
    delay(5000);
    return;
  }

  // Check for new RFID card
  if (!rfid.PICC_IsNewCardPresent()) {
    return;
  }
  if (!rfid.PICC_ReadCardSerial()) {
    return;
  }

  // Turn on LED
  digitalWrite(LED_PIN, HIGH);

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
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();

  // Turn off LED
  delay(800);
  digitalWrite(LED_PIN, LOW);

  delay(500); // Debounce — prevents double-read
}

// ═══════════════════════════════════════════
//  Card Management
// ═══════════════════════════════════════════

String getCardUID() {
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10)
      uid += "0";
    uid += String(rfid.uid.uidByte[i], HEX);
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
