# 🌱 Pi-Vert - Smart Irrigation IoT System

**Hệ thống tưới nước tự động thông minh dựa trên IoT**

## 📖 Giới thiệu

**Pi-Vert** là một ứng dụng IoT toàn diện giúp tự động hóa việc tưới nước cho vườn cây, sử dụng ESP32, cảm biến độ ẩm đất và tích hợp dự báo thời tiết. Ứng dụng được xây dựng bằng Flutter và Firebase Realtime Database, cung cấp giao diện thân thiện để giám sát và điều khiển hệ thống tưới từ xa.

### 🎯 Mục tiêu dự án

- ♻️ **Tiết kiệm nước**: Tưới đúng lúc, đúng lượng dựa trên dữ liệu thực tế
- 🤖 **Tự động hóa**: Giảm công sức chăm sóc cây trồng
- 📊 **Giám sát thông minh**: Theo dõi độ ẩm, thời tiết, lịch sử tưới
- 🌦️ **Thích ứng thời tiết**: Tự động điều chỉnh theo dự báo thời tiết
- 🔔 **Cảnh báo kịp thời**: Thông báo về rò rỉ, độ ẩm thấp, lịch trình

---

## ✨ Tính năng

### 🏡 Quản lý khu vực (Zones)
- ✅ Tạo và quản lý nhiều khu vực tưới
- ✅ Phân loại theo loại cây (rau củ, cỏ, hoa, cây)
- ✅ Cấu hình thông số đất, ánh sáng cho từng khu vực
- ✅ Kết nối thiết bị ESP32 tự động

### 💧 Điều khiển tưới nước
- ✅ **Manual Mode**: Điều khiển thủ công với thời gian tùy chỉnh
- ✅ **Auto Mode**: Tự động tưới dựa trên độ ẩm đất
- ✅ Countdown timer hiển thị thời gian còn lại
- ✅ Tắt khẩn cấp tất cả thiết bị cùng lúc

### 📅 Lịch trình tưới (Scheduling)
- ✅ Tạo lịch tưới theo giờ và ngày trong tuần
- ✅ Tự động bỏ qua khi trời mưa
- ✅ Điều chỉnh thời gian theo mùa
- ✅ Bật/tắt lịch trình linh hoạt

### 🌡️ Cảm biến thông minh
- ✅ **Soil Moisture**: Độ ẩm đất
- ✅ **Temperature**: Nhiệt độ
- ✅ **Light**: Cường độ ánh sáng
- ✅ **Flow Rate**: Lưu lượng nước
- ✅ **Humidity**: Độ ẩm không khí
- ✅ Ngưỡng cảnh báo tùy chỉnh
- ✅ Biểu đồ theo dõi dữ liệu theo thời gian

### 🌦️ Tích hợp thời tiết
- ✅ Dự báo thời tiết 5 ngày (OpenWeatherMap API)
- ✅ Tự động điều chỉnh lịch tưới theo thời tiết
- ✅ Tính toán độ ẩm tối ưu theo mùa
- ✅ Dashboard thời tiết trực quan

### 💦 Phát hiện rò rỉ nước
- ✅ Giám sát lưu lượng nước thời gian thực
- ✅ So sánh với lưu lượng dự kiến
- ✅ Cảnh báo 3 mức: Warning, Leak, Critical
- ✅ Gợi ý xử lý khi phát hiện rò rỉ

### 📊 Báo cáo & Lịch sử
- ✅ Lịch sử tưới chi tiết
- ✅ Thống kê tiêu thụ nước
- ✅ So sánh với kỳ trước
- ✅ Biểu đồ phân tích theo nguồn (manual/auto/schedule)
- ✅ Tính toán lượng nước tiết kiệm

### 🔔 Thông báo thông minh
- ✅ Firebase Cloud Messaging (FCM)
- ✅ Local notifications
- ✅ Thông báo đẩy khi:
    - Bắt đầu/kết thúc tưới
    - Cảm biến vượt ngưỡng
    - Phát hiện rò rỉ
    - Lịch trình bị bỏ qua do thời tiết
    - Độ ẩm đất thấp

### 📚 Thư viện cây trồng
- ✅ Thông tin chăm sóc chi tiết
- ✅ Gợi ý tưới phù hợp
- ✅ Tìm kiếm và lọc theo danh mục

### 👤 Profile & Settings
- ✅ Xác thực người dùng (Email/Password)
- ✅ Quản lý tài khoản
- ✅ Cài đặt thông báo
- ✅ Dark mode support (planned)


### 🤖 ESP32 Integration

```
ESP32 Tasks:
1. Read soil moisture sensor
2. Listen to Firebase commands
3. Control relay (pump on/off)
4. Update device status
5. Countdown timer management
6. Auto mode detection
```

### 🌐 Data Flow

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  Flutter    │◄───────►│   Firebase   │◄───────►│    ESP32    │
│     App     │         │   Realtime   │         │   Device    │
└─────────────┘         │   Database   │         └─────────────┘
      │                 └──────────────┘               │
      │                        │                       │
      ▼                        ▼                       ▼
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  Weather    │         │   Firebase   │         │   Sensors   │
│     API     │         │     Auth     │         │  (Moisture) │
└─────────────┘         └──────────────┘         └─────────────┘
```

---

## 🚀 Cài đặt

### Yêu cầu hệ thống

- **Flutter SDK**: >= 3.0.0
- **Dart SDK**: >= 3.0.0
- **Android Studio** / **VS Code**
- **Firebase Project**
- **ESP32 Device** (optional for full functionality)

### Bước 1: Clone repository

```bash
git clone https://github.com/your-username/pi-vert.git
cd pi-vert
```

### Bước 2: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 3: Cấu hình Firebase

1. Tạo Firebase project tại [Firebase Console](https://console.firebase.google.com/)
2. Thêm Android app vào project
3. Download `google-services.json` và đặt vào `android/app/`
4. Enable **Realtime Database**, **Authentication**, **Cloud Messaging**
5. Cấu hình Security Rules

### Bước 4: Cấu hình Weather API

1. Đăng ký tài khoản tại [OpenWeatherMap](https://openweathermap.org/api)
2. Lấy API key
3. Cập nhật trong `lib/services/weather_service.dart`:

```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

### Bước 5: Chạy ứng dụng

```bash
flutter run
```

---

## 📱 Sử dụng

### Đăng ký tài khoản

1. Mở ứng dụng
2. Chọn "Sign Up"
3. Nhập email và password
4. Xác thực email (optional)

### Tạo khu vực tưới

1. Vào trang "Khu vực" (Zones)
2. Nhấn nút **+** (Floating Action Button)
3. Điền thông tin:
    - Tên khu vực
    - Loại cây trồng
    - Loại đất
    - Mức độ ánh sáng
4. Nhấn "Tạo khu vực"

### Kết nối ESP32

1. Bật nguồn ESP32
2. ESP32 tự động kết nối WiFi và đăng ký với zone
3. Kiểm tra trong app, thiết bị sẽ xuất hiện sau 10-30s

### Tưới thủ công

1. Chọn một zone
2. Nhấn "Bật tưới"
3. Chọn thời gian (1-60 phút)
4. Nhấn "Bắt đầu tưới"

### Tạo lịch trình

1. Vào zone detail
2. Nhấn "Thêm lịch trình"
3. Cấu hình:
    - Giờ bắt đầu
    - Thời gian tưới
    - Ngày trong tuần
    - Bỏ qua khi trời mưa (optional)
4. Nhấn "Tạo lịch trình"

### Bật tưới tự động

1. Vào zone detail
2. Bật "Tưới tự động theo độ ẩm"
3. Hệ thống sẽ tự động tưới khi độ ẩm đất < ngưỡng

---

## 🛠️ Tech Stack

### Frontend (Mobile)
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: StreamBuilder + Callbacks
- **UI Library**: Material Design 3

### Backend & Database
- **BaaS**: Firebase
    - Realtime Database (NoSQL)
    - Authentication
    - Cloud Messaging
- **API**: OpenWeatherMap REST API

### Hardware (IoT)
- **Microcontroller**: ESP32
- **Sensors**:
    - Capacitive Soil Moisture Sensor
    - DHT22 (Temperature & Humidity)
    - YF-S201 (Water Flow Sensor)
- **Actuator**: Relay Module + Water Pump

### Key Libraries

```yaml
dependencies:
  flutter: 
  sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  firebase_database: ^10.4.0
  firebase_messaging: ^14.7.0
  
  # UI & Charts
  fl_chart: ^0.66.0
  syncfusion_flutter_charts: ^24.1.41
  
  # Notifications
  flutter_local_notifications: ^16.3.0
  
  # Utilities
  intl: ^0.18.1
  http: ^1.1.2
```

## 🔧 Configuration

### Environment Variables

Create `.env` file:

```env
WEATHER_API_KEY=your_openweathermap_api_key
FIREBASE_PROJECT_ID=your_firebase_project_id
```

### Firebase Config

Edit `android/app/google-services.json` with your Firebase credentials.

### Android Permissions

Required in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

---

## 🧪 Testing

### Run tests

```bash
flutter test
```

### Run integration tests

```bash
flutter drive --target=test_driver/app.dart
```

### Test Firebase connection

```bash
flutter run --debug
# Check Firebase Console for realtime updates
```

---

## 📈 Performance

### Optimization Techniques Used

- ✅ **Stream Subscriptions**: Cancel when not needed
- ✅ **Const Constructors**: Reduce widget rebuilds
- ✅ **Lazy Loading**: Load data on demand
- ✅ **Image Caching**: Cache weather icons
- ✅ **Database Indexes**: Optimize queries
- ✅ **Throttling**: Limit API calls

### Benchmarks

- **App Size**: ~25 MB (release build)
- **Cold Start**: ~2.5s
- **Warm Start**: ~0.8s
- **Memory Usage**: ~80-120 MB
- **Firebase Latency**: <100ms (realtime updates)

---

## 🐛 Known Issues

- [ ] Dark mode chưa hoàn thiện
- [ ] iOS version chưa được test đầy đủ
- [ ] Cần thêm unit tests
- [ ] Multi-language support (chỉ có tiếng Việt)

---

---

## 🤝 Đóng góp

Chúng tôi rất hoan nghênh mọi đóng góp!

### Cách đóng góp

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

### Coding Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Sử dụng `flutter format` trước khi commit
- Viết comment cho các hàm phức tạp
- Tạo unit tests cho business logic

### Bug Reports

Mở issue với template:
- **Mô tả lỗi**
- **Các bước tái hiện**
- **Expected behavior**
- **Screenshots** (nếu có)
- **Device info** (OS, Flutter version)
