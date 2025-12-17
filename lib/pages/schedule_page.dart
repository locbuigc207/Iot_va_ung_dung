import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../services/firebase_service.dart';
import '../widgets/schedule_item.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<ScheduleModel> _allSchedules = [];
  String _filterStatus = 'all'; // all, enabled, disabled

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    _firebaseService.getAllSchedulesStream().listen((schedules) {
      if (!mounted) return;
      setState(() => _allSchedules = schedules);
    });
  }

  List<ScheduleModel> _getFilteredSchedules() {
    switch (_filterStatus) {
      case 'enabled':
        return _allSchedules.where((s) => s.enabled).toList();
      case 'disabled':
        return _allSchedules.where((s) => !s.enabled).toList();
      default:
        return _allSchedules;
    }
  }

  int _getEnabledCount() => _allSchedules.where((s) => s.enabled).length;

  int _getTodayCount() =>
      _allSchedules.where((s) => s.enabled && s.shouldRunToday()).length;

  @override
  Widget build(BuildContext context) {
    final filteredSchedules = _getFilteredSchedules();
    final enabledCount = _getEnabledCount();
    final todayCount = _getTodayCount();

    return Column(
      children: [
        // Stats Card
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
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Lịch trình tưới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatItem(
                    '${_allSchedules.length}',
                    'Tổng số',
                    Icons.list,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    '$enabledCount',
                    'Đang bật',
                    Icons.power,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    '$todayCount',
                    'Hôm nay',
                    Icons.today,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('Tất cả', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Đang bật', 'enabled'),
              const SizedBox(width: 8),
              _buildFilterChip('Đã tắt', 'disabled'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Schedules List
        Expanded(
          child: filteredSchedules.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = filteredSchedules[index];
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
                        final success = await _firebaseService.deleteSchedule(
                          schedule.id,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa lịch trình'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
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

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;

    return Expanded(
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = status);
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF00C1C4),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF00C1C4) : Colors.grey[300]!,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String submessage;

    switch (_filterStatus) {
      case 'enabled':
        message = 'Không có lịch trình nào đang bật';
        submessage = 'Bật lịch trình để bắt đầu tưới tự động';
        break;
      case 'disabled':
        message = 'Không có lịch trình nào bị tắt';
        submessage = 'Tất cả lịch trình đang hoạt động';
        break;
      default:
        message = 'Chưa có lịch trình nào';
        submessage = 'Tạo lịch trình từ trang chi tiết khu vực';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              submessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
