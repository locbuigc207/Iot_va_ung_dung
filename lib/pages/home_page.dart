import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/device_model.dart';
import '../models/zone_model.dart';
import '../services/firebase_service.dart';
import '../widgets/control_button.dart';
import '../widgets/zone_card.dart';
import 'add_zone_page.dart';
import 'schedule_page.dart';
import 'zone_detail_page.dart';
import 'zones_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _currentIndex = 0;
  List<ZoneModel> _zones = [];
  Map<String, DeviceModel> _devices = {};
  Map<String, StreamSubscription> _deviceSubscriptions = {};
  Map<String, Timer> _countdownTimers = {};

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  void _loadZones() {
    _firebaseService.getZonesStream().listen((zones) {
      if (!mounted) return;
      setState(() {
        _zones = zones;
      });

      // Load devices for each zone
      for (var zone in zones) {
        _loadDeviceForZone(zone.id);
      }

      // Clean up subscriptions for removed zones
      final zoneIds = zones.map((z) => z.id).toSet();
      _deviceSubscriptions.keys.toList().forEach((id) {
        if (!zoneIds.contains(id)) {
          _deviceSubscriptions[id]?.cancel();
          _deviceSubscriptions.remove(id);
          _countdownTimers[id]?.cancel();
          _countdownTimers.remove(id);
        }
      });
    });
  }

  void _loadDeviceForZone(String zoneId) {
    _deviceSubscriptions[zoneId]?.cancel();
    _deviceSubscriptions[zoneId] =
        _firebaseService.getDeviceStream(zoneId).listen((device) {
      if (!mounted) return;
      setState(() {
        if (device != null) {
          _devices[zoneId] = device;

          // Start countdown timer if watering
          if (device.isWatering) {
            _startCountdownTimer(zoneId, device);
          } else {
            _countdownTimers[zoneId]?.cancel();
            _countdownTimers.remove(zoneId);
          }
        }
      });
    });
  }

  void _startCountdownTimer(String zoneId, DeviceModel device) {
    _countdownTimers[zoneId]?.cancel();

    if (device.currentDuration == null || device.currentDuration! <= 0) return;

    _countdownTimers[zoneId] = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        final currentDevice = _devices[zoneId];
        if (currentDevice == null ||
            currentDevice.currentDuration == null ||
            currentDevice.currentDuration! <= 0) {
          timer.cancel();
          _countdownTimers.remove(zoneId);
          return;
        }

        final newDuration = currentDevice.currentDuration! - 1;

        if (newDuration <= 0) {
          // Time's up - turn off device
          await _firebaseService.controlDevice(currentDevice.id, false);
          timer.cancel();
          _countdownTimers.remove(zoneId);

          // Log watering event
          final zone = _zones.firstWhere((z) => z.id == zoneId);
          await _firebaseService.logWateringEvent(
            zoneId: zoneId,
            zoneName: zone.name,
            duration: device.currentDuration! ~/ 60,
            source: 'manual',
          );
        } else {
          // Update duration
          await _firebaseService.updateDeviceDuration(
            currentDevice.id,
            newDuration,
          );
        }
      },
    );
  }

  Future<void> _toggleDevice(String zoneId, bool turnOn) async {
    final device = _devices[zoneId];
    if (device == null) return;

    if (turnOn) {
      // Show duration picker
      final duration = await _showDurationPicker();
      if (duration == null) return;

      final success = await _firebaseService.controlDevice(
        device.id,
        true,
        duration: duration,
      );

      if (!success && mounted) {
        _showErrorSnackBar('Không thể bật thiết bị');
      }
    } else {
      // Turn off immediately
      final success = await _firebaseService.controlDevice(device.id, false);

      if (success) {
        // Log watering event if was running
        if (device.isWatering && device.startTime != null) {
          final zone = _zones.firstWhere((z) => z.id == zoneId);
          final actualDuration =
              DateTime.now().difference(device.startTime!).inMinutes;
          await _firebaseService.logWateringEvent(
            zoneId: zoneId,
            zoneName: zone.name,
            duration: actualDuration,
            source: 'manual',
          );
        }
      } else if (mounted) {
        _showErrorSnackBar('Không thể tắt thiết bị');
      }
    }
  }

  Future<int?> _showDurationPicker() async {
    int selectedDuration = 10; // Default 10 minutes

    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Chọn thời gian tưới',
            style: TextStyle(fontFamily: 'SpaceGrotesk'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedDuration phút',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C1C4),
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: selectedDuration.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                activeColor: const Color(0xFF00C1C4),
                label: '$selectedDuration phút',
                onChanged: (value) {
                  setDialogState(() {
                    selectedDuration = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 phút',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  Text(
                    '60 phút',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedDuration),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C1C4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Bắt đầu tưới',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _turnAllOff() async {
    final activeDevices =
        _devices.values.where((device) => device.status).toList();

    if (activeDevices.isEmpty) {
      _showInfoSnackBar('Không có thiết bị nào đang hoạt động');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Tắt tất cả?',
          style: TextStyle(fontFamily: 'SpaceGrotesk'),
        ),
        content: Text(
          'Tắt ${activeDevices.length} thiết bị đang hoạt động?',
          style: const TextStyle(fontFamily: 'SpaceGrotesk'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tắt tất cả',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (var device in activeDevices) {
      await _firebaseService.controlDevice(device.id, false);
    }

    if (mounted) {
      _showSuccessSnackBar('Đã tắt tất cả thiết bị');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pi-Vert',
          style: TextStyle(
            fontFamily: 'VeronaSerial',
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00C1C4),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF00C1C4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Khu vực',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Lịch trình',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddZonePage(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF00C1C4),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return ZonesPage(
          zones: _zones,
          devices: _devices,
          onToggle: _toggleDevice,
        );
      case 2:
        return const SchedulePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final activeCount = _devices.values.where((d) => d.status).length;
    final wateringCount = _devices.values.where((d) => d.isWatering).length;

    return RefreshIndicator(
      onRefresh: () async {
        _loadZones();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C1C4), Color(0xFF00A0A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C1C4).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${_auth.currentUser?.displayName ?? "User"}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Hãy chăm sóc cây của bạn hôm nay',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatCard(
                        '${_zones.length}',
                        'Khu vực',
                        Icons.location_on,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        '$activeCount',
                        'Đang bật',
                        Icons.power,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        '$wateringCount',
                        'Đang tưới',
                        Icons.water_drop,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Điều khiển nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: QuickControlButton(
                      label: 'Tắt tất cả',
                      sublabel: 'Dừng mọi tưới',
                      icon: Icons.power_settings_new,
                      color: Colors.red,
                      onPressed: _turnAllOff,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickControlButton(
                      label: 'Thêm khu vực',
                      sublabel: 'Tạo zone mới',
                      icon: Icons.add_location_alt,
                      color: const Color(0xFF00C1C4),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddZonePage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Zones List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Khu vực của bạn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: Color(0xFF00C1C4),
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_zones.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.grass,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có khu vực nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddZonePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo khu vực đầu tiên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C1C4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._zones.take(3).map((zone) {
                return ZoneCard(
                  zone: zone,
                  device: _devices[zone.id],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZoneDetailPage(
                          zone: zone,
                          device: _devices[zone.id],
                        ),
                      ),
                    );
                  },
                  onToggle: (value) => _toggleDevice(zone.id, value),
                );
              }).toList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deviceSubscriptions.values.forEach((sub) => sub.cancel());
    _countdownTimers.values.forEach((timer) => timer.cancel());
    super.dispose();
  }
}
