// ============================================
// PACKAGE TRACKER - FIREBASE INTEGRATION
// ============================================

// ========== LIBRARIES ==========
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include "config.h"

// Sensor Libraries
#include <DHT.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BMP280.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>

// ========== SENSOR PINS ==========
#define DHTPIN 4
#define DHTTYPE DHT22

// I2C Pins (MPU6050 + BMP280)
#define I2C_SDA 21
#define I2C_SCL 22

// GPS Serial Pins
#define GPS_RX 16
#define GPS_TX 17

// ========== SENSOR OBJECTS ==========
DHT dht(DHTPIN, DHTTYPE);
Adafruit_MPU6050 mpu;
Adafruit_BMP280 bmp;
TinyGPSPlus gps;
HardwareSerial SerialGPS(2);

// ========== FIREBASE OBJECTS ==========
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ========== NTP CLIENT ==========
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 5 * 3600, 60000); // UTC+5 for Pakistan

// ========== VARIABLES ==========
unsigned long lastUploadTime = 0;
const unsigned long uploadInterval = 10000; // 10 seconds
String deviceID;

// ========== PACKAGE STATUS ==========
enum PackageStatus {
  STATUS_NORMAL,
  STATUS_ON_SIDE,
  STATUS_SHOCKED,
  STATUS_FREEFALL,
  STATUS_UPSIDE_DOWN,
  STATUS_TEMPERATURE_ALERT,
  STATUS_PRESSURE_ALERT
};

PackageStatus currentStatus = STATUS_NORMAL;

// ========== THRESHOLDS ==========
#define SHOCK_THRESHOLD 15.0    // m/s²
#define DROP_THRESHOLD 2.0      // m/s²
#define TILT_THRESHOLD 5.0      // m/s²
#define TEMP_HIGH_THRESHOLD 40.0 // °C
#define TEMP_LOW_THRESHOLD 5.0   // °C
#define PRESSURE_CHANGE_THRESHOLD 10.0 // hPa

// ========== SENSOR STRUCTURE ==========
struct SensorData {
  // GPS Data
  float latitude;
  float longitude;
  float altitudeGPS;
  int satellites;
  bool gpsValid;
  
  // MPU6050 Data
  float accelX;
  float accelY;
  float accelZ;
  float gyroX;
  float gyroY;
  float gyroZ;
  float temperatureMPU;
  
  // BMP280 Data
  float temperatureBMP;
  float pressure;
  float altitudeBMP;
  
  // DHT22 Data
  float temperatureDHT;
  float humidity;
  
  // System Data
  unsigned long timestamp;
  int rssi; // WiFi strength
  float batteryVoltage; // If you add battery monitoring
};

// ========== FUNCTION PROTOTYPES ==========
void initSensors();
void connectToWiFi();
void initFirebase();
SensorData readAllSensors();
void readGPSData(SensorData &data);
void readMPU6050Data(SensorData &data);
void readBMP280Data(SensorData &data);
void readDHT22Data(SensorData &data);
PackageStatus determinePackageStatus(SensorData data);
String getStatusString(PackageStatus status);
void sendToFirebase(SensorData data);
void sendAlertToFirebase(SensorData data);
void printSensorData(SensorData data);
void checkWiFiConnection();

// ========== SETUP ==========
void setup() {
  Serial.begin(115200);
  delay(3000);
  
  Serial.println("\n📦 PACKAGE TRACKER - FIREBASE INTEGRATION");
  Serial.println("========================================");
  
  // Generate unique device ID
  deviceID = "PACKAGE_" + String(ESP.getEfuseMac(), HEX);
  Serial.print("Device ID: ");
  Serial.println(deviceID);
  
  // Initialize sensors
  initSensors();
  
  // Connect to WiFi
  connectToWiFi();
  
  // Initialize NTP client
  timeClient.begin();
  
  // Initialize Firebase
  initFirebase();
  
  Serial.println("\n✅ System Ready!");
  Serial.println("Sending data to Firebase every 10 seconds...");
  Serial.println("========================================\n");
}

// ========== MAIN LOOP ==========
void loop() {
  // Update NTP time
  timeClient.update();
  
  // Read all sensors
  SensorData data = readAllSensors();
  
  // Determine package status
  currentStatus = determinePackageStatus(data);
  
  // Send to Firebase every 10 seconds
  if (millis() - lastUploadTime >= uploadInterval) {
    if (Firebase.ready()) {
      sendToFirebase(data);
      lastUploadTime = millis();
    } else {
      Serial.println("Firebase not ready, reconnecting...");
      initFirebase();
    }
  }
  
  // Also print to Serial for debugging
  printSensorData(data);
  
  delay(1000); // Main loop delay
}

// ========== INITIALIZE SENSORS ==========
void initSensors() {
  Serial.println("Initializing sensors...");
  
  // DHT22
  dht.begin();
  Serial.println("✅ DHT22: Ready");
  
  // I2C Setup for MPU6050 & BMP280
  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(100000);
  
  // Force weak pull-ups (since no resistors yet)
  pinMode(I2C_SDA, OUTPUT);
  pinMode(I2C_SCL, OUTPUT);
  digitalWrite(I2C_SDA, HIGH);
  digitalWrite(I2C_SCL, HIGH);
  delay(500);
  
  // MPU6050
  if (mpu.begin(0x68) || mpu.begin(0x69)) {
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    Serial.println("✅ MPU6050: Ready");
  } else {
    Serial.println("❌ MPU6050: Failed (needs resistors)");
  }
  
  // BMP280
  if (bmp.begin(0x76) || bmp.begin(0x77)) {
    bmp.setSampling(Adafruit_BMP280::MODE_NORMAL,
                    Adafruit_BMP280::SAMPLING_X2,
                    Adafruit_BMP280::SAMPLING_X16,
                    Adafruit_BMP280::FILTER_X16,
                    Adafruit_BMP280::STANDBY_MS_500);
    Serial.println("✅ BMP280: Ready");
  } else {
    Serial.println("❌ BMP280: Failed (needs resistors)");
  }
  
  // GPS
  SerialGPS.begin(9600, SERIAL_8N1, GPS_RX, GPS_TX);
  Serial.println("✅ GPS: Ready (waiting for signal)");
}

// ========== READ ALL SENSORS ==========
SensorData readAllSensors() {
  SensorData data;
  
  // Timestamp
  data.timestamp = timeClient.getEpochTime();
  
  // Read GPS
  readGPSData(data);
  
  // Read MPU6050
  readMPU6050Data(data);
  
  // Read BMP280
  readBMP280Data(data);
  
  // Read DHT22
  readDHT22Data(data);
  
  // System data
  data.rssi = WiFi.RSSI();
  data.batteryVoltage = 0.0; // Add battery monitoring later
  
  return data;
}

void readGPSData(SensorData &data) {
  while (SerialGPS.available() > 0) {
    gps.encode(SerialGPS.read());
  }
  
  data.gpsValid = gps.location.isValid() && gps.location.age() < 2000;
  
  if (data.gpsValid) {
    data.latitude = gps.location.lat();
    data.longitude = gps.location.lng();
    data.altitudeGPS = gps.altitude.meters();
    data.satellites = gps.satellites.value();
  } else {
    data.latitude = 0.0;
    data.longitude = 0.0;
    data.altitudeGPS = 0.0;
    data.satellites = 0;
  }
}

void readMPU6050Data(SensorData &data) {
  if (mpu.begin()) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    data.accelX = a.acceleration.x;
    data.accelY = a.acceleration.y;
    data.accelZ = a.acceleration.z;
    data.gyroX = g.gyro.x;
    data.gyroY = g.gyro.y;
    data.gyroZ = g.gyro.z;
    data.temperatureMPU = temp.temperature;
  } else {
    // Default values if sensor not available
    data.accelX = 0.0;
    data.accelY = 0.0;
    data.accelZ = 9.81;
    data.gyroX = 0.0;
    data.gyroY = 0.0;
    data.gyroZ = 0.0;
    data.temperatureMPU = 25.0;
  }
}

void readBMP280Data(SensorData &data) {
  if (bmp.begin(0x76) || bmp.begin(0x77)) {
    data.temperatureBMP = bmp.readTemperature();
    data.pressure = bmp.readPressure() / 100.0F; // Pa to hPa
    data.altitudeBMP = bmp.readAltitude(1013.25); // Sea level pressure
  } else {
    data.temperatureBMP = 25.0;
    data.pressure = 1013.25;
    data.altitudeBMP = 0.0;
  }
}

void readDHT22Data(SensorData &data) {
  data.temperatureDHT = dht.readTemperature();
  data.humidity = dht.readHumidity();
  
  if (isnan(data.temperatureDHT) || isnan(data.humidity)) {
    data.temperatureDHT = 25.0;
    data.humidity = 50.0;
  }
}

// ========== DETERMINE PACKAGE STATUS ==========
PackageStatus determinePackageStatus(SensorData data) {
  // Check for shock
  float totalAccel = sqrt(data.accelX*data.accelX + 
                         data.accelY*data.accelY + 
                         data.accelZ*data.accelZ);
  
  if (totalAccel > SHOCK_THRESHOLD) {
    return STATUS_SHOCKED;
  }
  
  // Check for freefall
  if (totalAccel < DROP_THRESHOLD) {
    return STATUS_FREEFALL;
  }
  
  // Check if on side
  if (abs(data.accelZ) < TILT_THRESHOLD) {
    return STATUS_ON_SIDE;
  }
  
  // Check if upside down
  if (data.accelZ < -8.0) {
    return STATUS_UPSIDE_DOWN;
  }
  
  // Check temperature alerts
  if (data.temperatureDHT > TEMP_HIGH_THRESHOLD || 
      data.temperatureDHT < TEMP_LOW_THRESHOLD) {
    return STATUS_TEMPERATURE_ALERT;
  }
  
  // Check pressure changes (static for now, would compare with previous)
  static float lastPressure = 1013.25;
  if (abs(data.pressure - lastPressure) > PRESSURE_CHANGE_THRESHOLD) {
    lastPressure = data.pressure;
    return STATUS_PRESSURE_ALERT;
  }
  
  return STATUS_NORMAL;
}

String getStatusString(PackageStatus status) {
  switch(status) {
    case STATUS_NORMAL: return "NORMAL";
    case STATUS_ON_SIDE: return "ON_SIDE";
    case STATUS_SHOCKED: return "SHOCKED";
    case STATUS_FREEFALL: return "FREEFALL";
    case STATUS_UPSIDE_DOWN: return "UPSIDE_DOWN";
    case STATUS_TEMPERATURE_ALERT: return "TEMPERATURE_ALERT";
    case STATUS_PRESSURE_ALERT: return "PRESSURE_ALERT";
    default: return "UNKNOWN";
  }
}

// ========== WIFI CONNECTION ==========
void connectToWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi Failed!");
    Serial.println("Will retry in loop...");
  }
}

// ========== FIREBASE INITIALIZATION ==========
// In initFirebase():
void initFirebase() {
  Serial.println("Initializing Firebase with Service Account...");
  
  // Service Account Configuration
  config.service_account.data.project_id = FIREBASE_PROJECT_ID;
  config.service_account.data.client_email = FIREBASE_CLIENT_EMAIL;
  config.service_account.data.private_key = FIREBASE_PRIVATE_KEY;
  
  // Database URL
  config.database_url = FIREBASE_HOST;
  
  // Timeouts for Singapore
  config.timeout.serverResponse = 60 * 1000;
  config.timeout.sslHandshake = 60 * 1000;
  
  Firebase.reconnectWiFi(true);
  fbdo.setBSSLBufferSize(4096, 1024);
  
  Serial.print("Authenticating with Service Account");
  Firebase.begin(&config, &auth);
  
  // Wait for authentication
  for (int i = 0; i < 20; i++) {
    if (Firebase.ready()) {
      Serial.println("\n✅ Firebase Authenticated!");
      
      // Test authentication
      testFirebaseAuth();
      return;
    }
    Serial.print(".");
    delay(1000);
  }
  
  Serial.println("\n❌ Firebase authentication failed");
  Serial.print("Error: ");
  Serial.println(fbdo.errorReason().c_str());
}

void testFirebaseAuth() {
  Serial.println("Testing Firebase authentication...");
  
  // Test 1: Write data
  if (Firebase.setString(fbdo, "/auth_test", "ServiceAccount_Working")) {
    Serial.println("✅ Write test passed!");
    
    // Test 2: Read data
    delay(1000);
    if (Firebase.getString(fbdo, "/auth_test")) {
      Serial.print("✅ Read test passed: ");
      Serial.println(fbdo.stringData().c_str());
    }
  } else {
    Serial.print("❌ Authentication test failed: ");
    Serial.println(fbdo.errorReason().c_str());
    
    // Debug info
    Serial.print("Client Email: ");
    Serial.println(FIREBASE_CLIENT_EMAIL);
    Serial.print("Project ID: ");
    Serial.println(FIREBASE_PROJECT_ID);
    Serial.print("Private Key length: ");
    Serial.println(strlen(FIREBASE_PRIVATE_KEY));
  }
}

// ========== SEND DATA TO FIREBASE ==========
void sendToFirebase(SensorData data) {
  String timestampPath = "/packages/" + deviceID + "/" + String(data.timestamp);
  String latestPath = "/packages/" + deviceID + "/latest";
  
  // Create JSON document
  FirebaseJson json;
  
  // Basic info
  json.set("device_id", deviceID);
  json.set("timestamp", data.timestamp);
  json.set("status", getStatusString(currentStatus));
  
  // Location
  FirebaseJson location;
  location.set("latitude", data.latitude);
  location.set("longitude", data.longitude);
  location.set("altitude_gps", data.altitudeGPS);
  location.set("altitude_bmp", data.altitudeBMP);
  location.set("satellites", data.satellites);
  location.set("valid", data.gpsValid);
  json.set("location", location);
  
  // Motion
  FirebaseJson motion;
  motion.set("accel_x", data.accelX);
  motion.set("accel_y", data.accelY);
  motion.set("accel_z", data.accelZ);
  motion.set("gyro_x", data.gyroX);
  motion.set("gyro_y", data.gyroY);
  motion.set("gyro_z", data.gyroZ);
  motion.set("total_accel", sqrt(data.accelX*data.accelX + 
                                data.accelY*data.accelY + 
                                data.accelZ*data.accelZ));
  json.set("motion", motion);
  
  // Environment
  FirebaseJson environment;
  environment.set("temperature_dht", data.temperatureDHT);
  environment.set("temperature_bmp", data.temperatureBMP);
  environment.set("temperature_mpu", data.temperatureMPU);
  environment.set("humidity", data.humidity);
  environment.set("pressure", data.pressure);
  json.set("environment", environment);
  
  // System
  FirebaseJson system;
  system.set("wifi_rssi", data.rssi);
  system.set("battery", data.batteryVoltage);
  system.set("free_heap", ESP.getFreeHeap());
  json.set("system", system);
  
  // Send to Firebase
  Serial.println("📤 Sending to Firebase...");
  
  // Store historical data
  if (Firebase.setJSON(fbdo, timestampPath, json)) {
    Serial.print("✅ Historical data sent: ");
    Serial.println(fbdo.dataPath());
  } else {
    Serial.print("❌ Historical data failed: ");
    Serial.println(fbdo.errorReason());
  }
  
  // Update latest data
  if (Firebase.setJSON(fbdo, latestPath, json)) {
    Serial.println("✅ Latest data updated");
  } else {
    Serial.print("❌ Latest data failed: ");
    Serial.println(fbdo.errorReason());
  }
  
  // Also send alerts if status is not normal
  if (currentStatus != STATUS_NORMAL) {
    sendAlertToFirebase(data);
  }
}

// ========== SEND ALERTS ==========
void sendAlertToFirebase(SensorData data) {
  String alertPath = "/alerts/" + deviceID + "/" + String(data.timestamp);
  
  FirebaseJson alert;
  alert.set("device_id", deviceID);
  alert.set("timestamp", data.timestamp);
  alert.set("status", getStatusString(currentStatus));
  alert.set("location/latitude", data.latitude);
  alert.set("location/longitude", data.longitude);
  alert.set("acknowledged", false);
  
  // Add alert-specific details
  switch(currentStatus) {
    case STATUS_SHOCKED:
      alert.set("message", "Package experienced sudden shock!");
      alert.set("severity", "HIGH");
      break;
    case STATUS_FREEFALL:
      alert.set("message", "Package may have been dropped!");
      alert.set("severity", "CRITICAL");
      break;
    case STATUS_TEMPERATURE_ALERT:
      alert.set("message", "Temperature out of safe range!");
      alert.set("severity", "MEDIUM");
      alert.set("temperature", data.temperatureDHT);
      break;
    default:
      alert.set("message", "Package status changed");
      alert.set("severity", "LOW");
  }
  
  if (Firebase.setJSON(fbdo, alertPath, alert)) {
    Serial.println("🚨 Alert sent to Firebase!");
  }
}

// ========== PRINT SENSOR DATA (DEBUG) ==========
void printSensorData(SensorData data) {
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 5000) { // Print every 5 seconds
    lastPrint = millis();
    
    Serial.println("\n=== SENSOR READINGS ===");
    Serial.print("Status: ");
    Serial.println(getStatusString(currentStatus));
    
    if (data.gpsValid) {
      Serial.print("GPS: ");
      Serial.print(data.latitude, 6);
      Serial.print(", ");
      Serial.print(data.longitude, 6);
      Serial.print(" | Sats: ");
      Serial.println(data.satellites);
    } else {
      Serial.println("GPS: No signal");
    }
    
    Serial.print("Motion: X:");
    Serial.print(data.accelX, 1);
    Serial.print(" Y:");
    Serial.print(data.accelY, 1);
    Serial.print(" Z:");
    Serial.print(data.accelZ, 1);
    Serial.println(" m/s²");
    
    Serial.print("Environment: ");
    Serial.print(data.temperatureDHT, 1);
    Serial.print("°C, ");
    Serial.print(data.humidity, 0);
    Serial.print("%, ");
    Serial.print(data.pressure, 0);
    Serial.println(" hPa");
    
    Serial.print("WiFi: ");
    Serial.print(data.rssi);
    Serial.println(" dBm");
    Serial.println("=====================\n");
  }
}

// ========== HANDLE WIFI DISCONNECT ==========
void checkWiFiConnection() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected, reconnecting...");
    connectToWiFi();
    
    // Reinitialize Firebase after WiFi reconnect
    if (WiFi.status() == WL_CONNECTED) {
      initFirebase();
    }
  }
}