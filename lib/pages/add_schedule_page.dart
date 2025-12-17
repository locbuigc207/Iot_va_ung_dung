import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../models/zone_model.dart';
import '../services/firebase_service.dart';

class AddSchedulePage extends StatefulWidget {
  final ZoneModel zone;

  const AddSchedulePage({
    Key? key,
    required this.zone,
  }) : super(key: key);

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final FirebaseService _firebaseService = FirebaseService();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 6, minute: 0);
  int _selectedDuration = 10; // minutes
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri
  bool _weatherSkip = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _daysOfWeek = [
    {'number': 1, 'short': 'T2', 'full': 'Thứ 2'},
    {'number': 2, 'short': 'T3', 'full': 'Thứ 3'},
    {'number': 3, 'short': 'T4', 'full': 'Thứ 4'},
    {'number': 4, 'short': 'T5', 'full': 'Thứ 5'},
    {'number': 5, 'short': 'T6', 'full': 'Thứ 6'},
    {'number': 6, 'short': 'T7', 'full': 'Thứ 7'},
    {'number': 7, 'short': 'CN', 'full': 'Chủ nhật'},
  ];

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00C1C4),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
  }

  void _selectAllDays() {
    setState(() {
      if (_selectedDays.length == 7) {
        _selectedDays.clear();
      } else {
        _selectedDays = [1, 2, 3, 4, 5, 6, 7];
      }
    });
  }

  void _selectWeekdays() {
    setState(() {
      _selectedDays = [1, 2, 3, 4, 5];
    });
  }

  void _selectWeekend() {
    setState(() {
      _selectedDays = [6, 7];
    });
  }

  Future<void> _saveSchedule() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ngày'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final schedule = ScheduleModel(
        id: '', // Will be set by Firebase
        zoneId: widget.zone.id,
        zoneName: widget.zone.name,
        time: timeString,
        duration: _selectedDuration,
        activeDays: _selectedDays,
        enabled: true,
        weatherSkip: _weatherSkip,
        createdAt: DateTime.now(),
      );

      final scheduleId = await _firebaseService.addSchedule(schedule);

      if (scheduleId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo lịch trình thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to create schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo lịch trình',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00C1C4),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      widget.zone.getPlantIcon(),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.zone.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.zone.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontFamily: 'SpaceGrotesk',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Time Selection
            const Text(
              'Thời gian tưới',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C1C4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00C1C4).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF00C1C4),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giờ bắt đầu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C1C4),
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_right,
                      color: Color(0xFF00C1C4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Duration Selection
            const Text(
              'Thời gian tưới',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    '$_selectedDuration phút',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C1C4),
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _selectedDuration.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    activeColor: const Color(0xFF00C1C4),
                    label: '$_selectedDuration phút',
                    onChanged: (value) {
                      setState(() => _selectedDuration = value.toInt());
                    },
                  ),
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
            ),

            const SizedBox(height: 24),

            // Days Selection
            const Text(
              'Ngày trong tuần',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 12),

            // Quick Select Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectWeekdays,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00C1C4)),
                    ),
                    child: const Text(
                      'T2-T6',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: Color(0xFF00C1C4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectWeekend,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00C1C4)),
                    ),
                    child: const Text(
                      'T7-CN',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: Color(0xFF00C1C4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectAllDays,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00C1C4)),
                    ),
                    child: Text(
                      _selectedDays.length == 7 ? 'Bỏ chọn' : 'Tất cả',
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: Color(0xFF00C1C4),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Day Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day['number']);
                return InkWell(
                  onTap: () => _toggleDay(day['number']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 72) / 7,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00C1C4)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00C1C4)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day['short'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Weather Skip Option
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                value: _weatherSkip,
                onChanged: (value) => setState(() => _weatherSkip = value),
                activeColor: const Color(0xFF00C1C4),
                title: const Text(
                  'Tự động bỏ qua khi trời mưa',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                subtitle: Text(
                  'Hệ thống sẽ kiểm tra dự báo thời tiết và hủy lịch tưới nếu trời mưa',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cloud_outlined,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C1C4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tạo lịch trình',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
