import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class DevicePairingPage extends StatefulWidget {
  final String zoneId;
  final String zoneName;

  const DevicePairingPage({
    required this.zoneId,
    required this.zoneName,
    Key? key,
  }) : super(key: key);

  @override
  State<DevicePairingPage> createState() => _DevicePairingPageState();
}

class _DevicePairingPageState extends State<DevicePairingPage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSearching = true;
  String? _foundDeviceId;

  @override
  void initState() {
    super.initState();
    _searchForDevice();
  }

  Future<void> _searchForDevice() async {
    // Listen for new devices registered to this zone
    final subscription =
        _firebaseService.getDeviceStream(widget.zoneId).listen((device) {
      if (device != null &&
          device.uniqueId != null &&
          device.uniqueId!.startsWith('ESP32_')) {
        setState(() {
          _isSearching = false;
          _foundDeviceId = device.id;
        });
      }
    });

    // Timeout after 60 seconds
    Future.delayed(const Duration(seconds: 60), () {
      if (_isSearching) {
        setState(() => _isSearching = false);
      }
      subscription.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết nối thiết bị'),
        backgroundColor: const Color(0xFF00C1C4),
      ),
      body: Center(
        child: _isSearching
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Đang tìm kiếm ESP32...',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đảm bảo ESP32 đã được bật nguồn\nvà kết nối WiFi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : _foundDeviceId != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Đã kết nối thành công!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hoàn tất'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Không tìm thấy thiết bị',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isSearching = true);
                          _searchForDevice();
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
