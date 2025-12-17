import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device_model.dart';
import '../models/schedule_model.dart';
import '../models/zone_model.dart';
import '../services/firebase_service.dart';
import '../widgets/control_button.dart';
import '../widgets/schedule_item.dart';
import 'add_schedule_page.dart';

class ZoneDetailPage extends StatefulWidget {
  final ZoneModel zone;
  final DeviceModel? device;

  const ZoneDetailPage({
    Key? key,
    required this.zone,
    this.device,
  }) : super(key: key);

  @override
  State<ZoneDetailPage> createState() => _ZoneDetailPageState();
}

class _ZoneDetailPageState extends State<ZoneDetailPage> {
  final FirebaseService _firebaseService = FirebaseService();

  DeviceModel? _device;
  List<ScheduleModel> _schedules = [];
  Timer? _countdownTimer;
  StreamSubscription? _deviceSubscription;
  StreamSubscription? _schedulesSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    _loadDeviceAndSchedules();
  }

  void _loadDeviceAndSchedules() {
    // Listen to device updates
    _deviceSubscription?.cancel();
    _deviceSubscription =
        _firebaseService.getDeviceStream(widget.zone.id).listen((device) {
      if (!mounted) return;
      setState(() {
        _device = device;
        if (device?.isWatering == true) {
          _startCountdownTimer();
        } else {
          _countdownTimer?.cancel();
        }
      });
    });

    // Listen to schedules
    _schedulesSubscription?.cancel();
    _schedulesSubscription =
        _firebaseService.getSchedulesStream(widget.zone.id).listen((schedules) {
      if (!mounted) return;
      setState(() => _schedules = schedules);
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    if (_device == null ||
        _device!.currentDuration == null ||
        _device!.currentDuration! <= 0) return;

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (_device == null ||
            _device!.currentDuration == null ||
            _device!.currentDuration! <= 0) {
          timer.cancel();
          return;
        }

        final newDuration = _device!.currentDuration! - 1;

        if (newDuration <= 0) {
          await _firebaseService.controlDevice(_device!.id, false);
          timer.cancel();

          // Log watering event
          await _firebaseService.logWateringEvent(
            zoneId: widget.zone.id,
            zoneName: widget.zone.name,
            duration: _device!.currentDuration! ~/ 60,
            source: 'manual',
          );
        } else {
          await _firebaseService.updateDeviceDuration(_device!.id, newDuration);
        }
      },
    );
  }

  Future<void> _toggleDevice(bool turnOn) async {
    if (_device == null) return;

    setState(() => _isLoading = true);

    try {
      if (turnOn) {
        final duration = await _showDurationPicker();
        if (duration == null) {
          setState(() => _isLoading = false);
          return;
        }

        await _firebaseService.controlDevice(
          _device!.id,
          true,
          duration: duration,
        );
      } else {
        await _firebaseService.controlDevice(_device!.id, false);

        // Log event if was watering
        if (_device!.isWatering && _device!.startTime != null) {
          final actualDuration =
              DateTime.now().difference(_device!.startTime!).inMinutes;
          await _firebaseService.logWateringEvent(
            zoneId: widget.zone.id,
            zoneName: widget.zone.name,
            duration: actualDuration,
            source: 'manual',
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int?> _showDurationPicker() async {
    int selectedDuration = 10;

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
                  setDialogState(() => selectedDuration = value.toInt());
                },
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
              ),
              child: const Text(
                'Bắt đầu',
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

  Future<void> _deleteZone() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Xóa khu vực?',
          style: TextStyle(fontFamily: 'SpaceGrotesk'),
        ),
        content: Text(
          'Bạn có chắc muốn xóa khu vực "${widget.zone.name}"? Tất cả lịch trình liên quan cũng sẽ bị xóa.',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Xóa',
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

    setState(() => _isLoading = true);
    final success = await _firebaseService.deleteZone(widget.zone.id);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa khu vực'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Không thể xóa khu vực');
      }
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

  @override
  Widget build(BuildContext context) {
    final isActive = _device?.status ?? false;
    final isWatering = _device?.isWatering ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.zone.name,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00C1C4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteZone,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [const Color(0xFF00C1C4), const Color(0xFF00A0A3)]
                      : [Colors.grey[400]!, Colors.grey[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isActive ? const Color(0xFF00C1C4) : Colors.grey[400]!)
                            .withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        widget.zone.getPlantIcon(),
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _device?.getStatusText() ?? 'Không có thiết bị',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isWatering &&
                                _device?.getRemainingTimeString() != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Còn lại: ${_device!.getRemainingTimeString()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'SpaceGrotesk',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_device != null)
                    ControlButton(
                      label: isActive ? 'Tắt ngay' : 'Bật tưới',
                      icon: isActive ? Icons.power_off : Icons.power,
                      isActive: isActive,
                      onPressed: () => _toggleDevice(!isActive),
                      isLoading: _isLoading,
                    ),
                ],
              ),
            ),

            // Zone Info Card
            _buildInfoCard(),

            // Last Watered
            if (widget.zone.lastWatered != null) _buildLastWateredCard(),

            // Schedules Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch trình tưới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddSchedulePage(
                            zone: widget.zone,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C1C4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Schedules List
            if (_schedules.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có lịch trình nào',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._schedules.map((schedule) {
                return ScheduleItem(
                  schedule: schedule,
                  onToggle: (enabled) async {
                    await _firebaseService.toggleSchedule(
                      schedule.id,
                      enabled,
                    );
                  },
                  onTap: () {
                    // TODO: Navigate to edit schedule
                  },
                  onDelete: () async {
                    await _firebaseService.deleteSchedule(schedule.id);
                  },
                );
              }).toList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin khu vực',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.description, 'Mô tả', widget.zone.description),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.landscape,
              'Loại đất',
              widget.zone.getSoilTypeDisplay(),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.wb_sunny,
              'Ánh sáng',
              widget.zone.getSunExposureDisplay(),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.local_florist,
              'Loại cây',
              _getPlantTypeDisplay(widget.zone.plantType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastWateredCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.water_drop,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tưới lần cuối',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(widget.zone.lastWatered!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ],
    );
  }

  String _getPlantTypeDisplay(String type) {
    switch (type) {
      case 'vegetables':
        return 'Rau củ';
      case 'grass':
        return 'Cỏ';
      case 'flowers':
        return 'Hoa';
      case 'trees':
        return 'Cây';
      default:
        return 'Khác';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _deviceSubscription?.cancel();
    _schedulesSubscription?.cancel();
    super.dispose();
  }
}
