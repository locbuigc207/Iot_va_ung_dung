import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_model.dart';

class ScheduleItem extends StatelessWidget {
  final ScheduleModel schedule;
  final Function(bool) onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ScheduleItem({
    Key? key,
    required this.schedule,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nextRun = schedule.getNextRunTime();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: schedule.enabled
              ? const Color(0xFF00C1C4).withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Time Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: schedule.enabled
                          ? const Color(0xFF00C1C4).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: schedule.enabled
                              ? const Color(0xFF00C1C4)
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          schedule.time,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: schedule.enabled
                                ? const Color(0xFF00C1C4)
                                : Colors.grey[600],
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Schedule Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.zoneName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule.getDurationString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Toggle Switch
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: schedule.enabled,
                      activeColor: const Color(0xFF00C1C4),
                      onChanged: onToggle,
                    ),
                  ),

                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    iconSize: 22,
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Days and Next Run
              Row(
                children: [
                  // Active Days
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _buildDayChips(),
                    ),
                  ),

                  // Next Run
                  if (schedule.enabled && nextRun != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatNextRun(nextRun),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Weather Skip Badge
              if (schedule.weatherSkip) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        size: 12,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tự động bỏ qua khi trời mưa',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDayChips() {
    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return List.generate(7, (index) {
      final dayNumber = index + 1;
      final isActive = schedule.activeDays.contains(dayNumber);

      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C1C4) : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            dayNames[index],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey[600],
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ),
      );
    });
  }

  String _formatNextRun(DateTime nextRun) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextRunDay = DateTime(nextRun.year, nextRun.month, nextRun.day);
    final difference = nextRunDay.difference(today).inDays;

    if (difference == 0) {
      return 'Hôm nay ${schedule.time}';
    } else if (difference == 1) {
      return 'Mai ${schedule.time}';
    } else {
      return DateFormat('dd/MM').format(nextRun);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Xóa lịch trình?',
          style: TextStyle(fontFamily: 'SpaceGrotesk'),
        ),
        content: Text(
          'Bạn có chắc muốn xóa lịch trình tưới lúc ${schedule.time}?',
          style: const TextStyle(fontFamily: 'SpaceGrotesk'),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
