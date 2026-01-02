# Hướng dẫn Kết nối Hardware IoT với Flutter App qua Firebase

## Tổng quan Kiến trúc

```
Hardware IoT (ESP32/Arduino) 
    ↓ (MQTT/HTTP)
Firebase Realtime Database ← → Flutter App
    ↑
Cloud Functions (Optional)
```

---

## PHẦN 1: CẤU HÌNH FIREBASE

### 1.1. Firebase Realtime Database Structure

Cấu trúc database đã có trong code của bạn:

```json
{
  "zones": {
    "zone_id": {
      "name": "Vườn rau",
      "userId": "user_id",
      "deviceId": "device_id",
      "isActive": false
    }
  },
  "devices": {
    "device_id": {
      "id": "device_id",
      "name": "Pump - Vườn rau",
      "zoneId": "zone_id",
      "status": false,
      "currentDuration": 0,
      "lastUpdated": 1234567890
    }
  },
  "sensors": {
    "sensor_id": {
      "zoneId": "zone_id",
      "type": "soilMoisture",
      "currentValue": 45.5,
      "minThreshold": 20,
      "maxThreshold": 80,
      "lastUpdated": 1234567890
    }
  },
  "hardware_commands": {
    "device_id": {
      "command": "ON",
      "duration": 600,
      "timestamp": 1234567890,
      "executed": false
    }
  }
}
```

### 1.2. Firebase Security Rules

Thêm rules cho hardware:

```json
{
  "rules": {
    "zones": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "devices": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "sensors": {
      ".read": "auth != null",
      ".write": true
    },
    "hardware_commands": {
      ".read": true,
      ".write": "auth != null"
    },
    "sensor_readings": {
      ".read": "auth != null",
      ".write": true
    }
  }
}
```

---

## PHẦN 2: CODE HARDWARE (ESP32/ESP8266)

### 2.1. Cài đặt Thư viện Arduino

```cpp
// Libraries cần cài trong Arduino IDE:
// - ESP32/ESP8266 Board Manager
// - Firebase ESP Client by Mobizt
// - DHT sensor library (nếu dùng)
// - ArduinoJson
```

### 2.2. Code Hardware Hoàn chỉnh

```cpp
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <DHT.h>

// ==================== CẤU HÌNH ====================
// WiFi
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase
#define FIREBASE_HOST "flutter-chat-app-3e625-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "YOUR_DATABASE_SECRET" // Lấy từ Firebase Console

// Hardware Pins
#define PUMP_PIN 2           // GPIO2 - Relay điều khiển máy bơm
#define SOIL_SENSOR_PIN 34   // GPIO34 - Analog sensor độ ẩm đất
#define DHT_PIN 4            // GPIO4 - DHT22 nhiệt độ/độ ẩm
#define FLOW_SENSOR_PIN 5    // GPIO5 - Cảm biến lưu lượng nước

// Device Info
String DEVICE_ID = "device_1234567890";  // Thay bằng device ID từ Firebase
String ZONE_ID = "zone_1234567890";      // Thay bằng zone ID từ Firebase

// ==================== KHỞI TẠO ====================
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

DHT dht(DHT_PIN, DHT22);

// Variables
bool pumpStatus = false;
unsigned long pumpStartTime = 0;
int remainingDuration = 0;
unsigned long lastSensorRead = 0;
unsigned long lastCommandCheck = 0;

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  
  // Setup pins
  pinMode(PUMP_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, LOW);
  pinMode(SOIL_SENSOR_PIN, INPUT);
  pinMode(FLOW_SENSOR_PIN, INPUT);
  
  // Khởi tạo sensors
  dht.begin();
  
  // Kết nối WiFi
  connectWiFi();
  
  // Kết nối Firebase
  connectFirebase();
  
  Serial.println("✅ Hardware initialized successfully!");
}

// ==================== MAIN LOOP ====================
void loop() {
  // 1. Kiểm tra lệnh từ app (mỗi 1 giây)
  if (millis() - lastCommandCheck > 1000) {
    checkCommands();
    lastCommandCheck = millis();
  }
  
  // 2. Đọc sensors và gửi dữ liệu (mỗi 10 giây)
  if (millis() - lastSensorRead > 10000) {
    readAndSendSensorData();
    lastSensorRead = millis();
  }
  
  // 3. Quản lý countdown pump
  if (pumpStatus && remainingDuration > 0) {
    if (millis() - pumpStartTime >= 1000) {
      remainingDuration--;
      updatePumpDuration();
      pumpStartTime = millis();
      
      if (remainingDuration <= 0) {
        turnOffPump();
      }
    }
  }
  
  delay(100);
}

// ==================== WIFI ====================
void connectWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\n✅ WiFi connected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

// ==================== FIREBASE ====================
void connectFirebase() {
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Test connection
  if (Firebase.ready()) {
    Serial.println("✅ Firebase connected!");
  } else {
    Serial.println("❌ Firebase connection failed!");
  }
}

// ==================== KIỂM TRA LỆNH ====================
void checkCommands() {
  String commandPath = "/hardware_commands/" + DEVICE_ID;
  
  if (Firebase.get(firebaseData, commandPath)) {
    if (firebaseData.dataType() == "json") {
      FirebaseJson &json = firebaseData.jsonObject();
      FirebaseJsonData jsonData;
      
      // Kiểm tra xem lệnh đã thực thi chưa
      json.get(jsonData, "executed");
      if (jsonData.boolValue == true) {
        return; // Lệnh đã thực thi
      }
      
      // Lấy command
      json.get(jsonData, "command");
      String command = jsonData.stringValue;
      
      // Lấy duration (nếu có)
      json.get(jsonData, "duration");
      int duration = jsonData.intValue;
      
      Serial.println("📬 Received command: " + command);
      
      // Thực thi lệnh
      if (command == "ON") {
        turnOnPump(duration);
      } else if (command == "OFF") {
        turnOffPump();
      }
      
      // Đánh dấu lệnh đã thực thi
      Firebase.setBool(firebaseData, commandPath + "/executed", true);
      
      // Xóa lệnh sau 5 giây (cleanup)
      delay(5000);
      Firebase.deleteNode(firebaseData, commandPath);
    }
  }
}

// ==================== ĐIỀU KHIỂN BƠM ====================
void turnOnPump(int durationSeconds) {
  pumpStatus = true;
  remainingDuration = durationSeconds;
  pumpStartTime = millis();
  
  digitalWrite(PUMP_PIN, HIGH);
  Serial.println("💧 Pump ON - Duration: " + String(durationSeconds) + "s");
  
  // Cập nhật Firebase
  String devicePath = "/devices/" + DEVICE_ID;
  Firebase.setBool(firebaseData, devicePath + "/status", true);
  Firebase.setInt(firebaseData, devicePath + "/currentDuration", durationSeconds);
  Firebase.setInt(firebaseData, devicePath + "/startTime", millis());
  Firebase.setInt(firebaseData, devicePath + "/lastUpdated", millis());
}

void turnOffPump() {
  pumpStatus = false;
  remainingDuration = 0;
  
  digitalWrite(PUMP_PIN, LOW);
  Serial.println("💧 Pump OFF");
  
  // Cập nhật Firebase
  String devicePath = "/devices/" + DEVICE_ID;
  Firebase.setBool(firebaseData, devicePath + "/status", false);
  Firebase.setInt(firebaseData, devicePath + "/currentDuration", 0);
  Firebase.setInt(firebaseData, devicePath + "/lastUpdated", millis());
}

void updatePumpDuration() {
  String devicePath = "/devices/" + DEVICE_ID;
  Firebase.setInt(firebaseData, devicePath + "/currentDuration", remainingDuration);
}

// ==================== ĐỌC SENSORS ====================
void readAndSendSensorData() {
  // 1. Đọc độ ẩm đất
  int soilRaw = analogRead(SOIL_SENSOR_PIN);
  float soilMoisture = map(soilRaw, 0, 4095, 0, 100); // Convert to %
  
  // 2. Đọc nhiệt độ và độ ẩm không khí
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  // 3. Đọc lưu lượng nước (nếu có)
  // float flowRate = readFlowSensor();
  
  Serial.println("📊 Sensor readings:");
  Serial.println("  Soil: " + String(soilMoisture) + "%");
  Serial.println("  Temp: " + String(temperature) + "°C");
  Serial.println("  Humidity: " + String(humidity) + "%");
  
  // Gửi lên Firebase
  sendSensorData("soilMoisture", soilMoisture);
  sendSensorData("temperature", temperature);
  sendSensorData("humidity", humidity);
}

void sendSensorData(String sensorType, float value) {
  // Tìm sensor ID tương ứng
  String sensorsPath = "/sensors";
  
  if (Firebase.get(firebaseData, sensorsPath)) {
    FirebaseJson &json = firebaseData.jsonObject();
    
    // Duyệt qua các sensors để tìm sensor phù hợp
    size_t len = json.iteratorBegin();
    String key, path;
    int type = 0;
    FirebaseJson *obj;
    
    for (size_t i = 0; i < len; i++) {
      json.iteratorGet(i, type, key, path);
      
      if (type == FirebaseJson::JSON_OBJECT) {
        FirebaseJsonData jsonData;
        json.get(jsonData, key + "/zoneId");
        String zoneId = jsonData.stringValue;
        
        json.get(jsonData, key + "/type");
        String type = jsonData.stringValue;
        
        // Nếu đúng zone và đúng loại sensor
        if (zoneId == ZONE_ID && type == sensorType) {
          // Cập nhật giá trị
          String updatePath = "/sensors/" + key;
          Firebase.setFloat(firebaseData, updatePath + "/currentValue", value);
          Firebase.setInt(firebaseData, updatePath + "/lastUpdated", millis());
          
          // Lưu reading history
          String readingPath = "/sensor_readings/" + key + "/" + getDateKey() + "/" + String(millis());
          Firebase.setFloat(firebaseData, readingPath + "/value", value);
          Firebase.setInt(firebaseData, readingPath + "/timestamp", millis());
          
          Serial.println("✅ Sent " + sensorType + ": " + String(value));
          break;
        }
      }
    }
    json.iteratorEnd();
  }
}

// ==================== HELPER FUNCTIONS ====================
String getDateKey() {
  // Format: YYYY-MM-DD
  // Cần thư viện NTPClient để lấy thời gian thực
  // Đơn giản hóa: dùng millis()
  unsigned long days = millis() / (1000 * 60 * 60 * 24);
  return "2025-01-" + String(days % 31 + 1);
}
```

---

## PHẦN 3: TÍCH HỢP VÀO FLUTTER APP

### 3.1. Cập nhật Firebase Service

Thêm vào `lib/services/firebase_service.dart`:

```dart
// ==================== HARDWARE COMMANDS ====================

Future<bool> sendCommandToHardware({
  required String deviceId,
  required String command,
  int? duration,
}) async {
  try {
    final commandRef = _db.child('hardware_commands/$deviceId');
    
    await commandRef.set({
      'command': command,
      'duration': duration,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'executed': false,
    });
    
    debugPrint('✅ Command sent to hardware: $command');
    return true;
  } catch (e) {
    debugPrint('❌ Error sending command: $e');
    return false;
  }
}

// Override controlDevice để gửi lệnh đến hardware
@override
Future<bool> controlDevice(String deviceId, bool turnOn, {int? duration}) async {
  try {
    // 1. Cập nhật Firebase (như cũ)
    final updates = <String, dynamic>{
      'status': turnOn,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };

    if (turnOn) {
      updates['startTime'] = DateTime.now().millisecondsSinceEpoch;
      if (duration != null) {
        updates['currentDuration'] = duration * 60;
      }
    } else {
      updates['currentDuration'] = 0;
      updates['startTime'] = null;
    }

    await _db.child('devices/$deviceId').update(updates);
    
    // 2. Gửi lệnh đến hardware
    await sendCommandToHardware(
      deviceId: deviceId,
      command: turnOn ? 'ON' : 'OFF',
      duration: duration != null ? duration * 60 : null,
    );
    
    return true;
  } catch (e) {
    debugPrint('Error controlling device: $e');
    return false;
  }
}
```

---

## PHẦN 4: THIẾT LẬP FIREBASE

### 4.1. Lấy Database Secret (Legacy Token)

1. Vào Firebase Console → Project Settings
2. Chọn tab "Service accounts"
3. Click "Database secrets"
4. Copy secret key → Dùng trong code Arduino

### 4.2. Hoặc dùng REST API (Khuyến nghị)

Nếu không muốn dùng legacy token, dùng REST API:

```cpp
#include <HTTPClient.h>

void sendDataViaHTTP(String path, String jsonData) {
  HTTPClient http;
  String url = "https://flutter-chat-app-3e625-default-rtdb.firebaseio.com" + path + ".json";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.PUT(jsonData); // PUT để update
  
  if (httpCode > 0) {
    Serial.println("✅ HTTP Response: " + String(httpCode));
  } else {
    Serial.println("❌ HTTP Error");
  }
  
  http.end();
}
```

---

## PHẦN 5: TESTING & DEBUGGING

### 5.1. Test Flow

```
1. Hardware → Firebase:
   - Gửi sensor data
   - Cập nhật device status
   
2. App → Firebase → Hardware:
   - App gửi command
   - Hardware nhận và thực thi
   
3. Hardware → Firebase → App:
   - Hardware cập nhật trạng thái
   - App hiển thị real-time
```

### 5.2. Debug Commands

```cpp
// Thêm Serial debug trong Arduino
Serial.println("🔍 Checking commands...");
Serial.println("📊 Sensor value: " + String(value));
Serial.println("💧 Pump status: " + String(pumpStatus));
```

---

## PHẦN 6: PRODUCTION CHECKLIST

- [ ] Đổi WiFi credentials trong code
- [ ] Cập nhật DEVICE_ID và ZONE_ID
- [ ] Bật Firebase Rules cho production
- [ ] Test kết nối WiFi ổn định
- [ ] Test sensor readings
- [ ] Test pump control
- [ ] Test với app thật
- [ ] Setup auto-reconnect WiFi
- [ ] Setup watchdog timer
- [ ] Log errors về Firebase

---

## LƯU Ý QUAN TRỌNG

1. **Bảo mật**: Không commit WiFi password và Firebase secrets lên GitHub
2. **Power**: Đảm bảo nguồn ổn định cho ESP32
3. **Network**: WiFi phải ổn định, setup auto-reconnect
4. **Delay**: Không dùng `delay()` quá lâu, dùng `millis()` thay thế
5. **Memory**: ESP32 có RAM hạn chế, cẩn thận với String

Bạn có cần hướng dẫn chi tiết phần nào không?