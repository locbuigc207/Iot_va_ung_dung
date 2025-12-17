import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device_model.dart';
import '../models/zone_model.dart';

class ZoneCard extends StatelessWidget {
  final ZoneModel zone;
  final DeviceModel? device;
  final VoidCallback onTap;
  final Function(bool) onToggle;

  const ZoneCard({
    Key? key,
    required this.zone,
    this.device,
    required this.onTap,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = device?.status ?? false;
    final isWatering = device?.isWatering ?? false;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? const Color(0xFF00C1C4) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Plant Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF00C1C4).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      zone.getPlantIcon(),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Zone Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zone.description,
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

                  // Toggle Switch
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: isActive,
                      activeColor: const Color(0xFF00C1C4),
                      onChanged: onToggle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Status Row
              Row(
                children: [
                  // Status Indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    device?.getStatusText() ?? 'Không có thiết bị',
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? Colors.green[700] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const Spacer(),

                  // Remaining time if watering
                  if (isWatering && device?.getRemainingTimeString() != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C1C4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Color(0xFF00C1C4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device!.getRemainingTimeString()!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C1C4),
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Last Watered
              if (zone.lastWatered != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tưới lần cuối: ${_formatLastWatered(zone.lastWatered!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
              ],

              // Zone Details
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDetailChip(
                    Icons.landscape,
                    zone.getSoilTypeDisplay(),
                  ),
                  _buildDetailChip(
                    Icons.wb_sunny_outlined,
                    zone.getSunExposureDisplay(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastWatered(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }
}
