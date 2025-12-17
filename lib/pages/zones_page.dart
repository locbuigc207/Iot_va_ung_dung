import 'package:flutter/material.dart';

import '../models/device_model.dart';
import '../models/zone_model.dart';
import '../widgets/zone_card.dart';
import 'zone_detail_page.dart';

class ZonesPage extends StatefulWidget {
  final List<ZoneModel> zones;
  final Map<String, DeviceModel> devices;
  final Function(String, bool) onToggle;

  const ZonesPage({
    Key? key,
    required this.zones,
    required this.devices,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<ZonesPage> createState() => _ZonesPageState();
}

class _ZonesPageState extends State<ZonesPage> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, vegetables, grass, flowers, trees

  @override
  Widget build(BuildContext context) {
    final filteredZones = _getFilteredZones();

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF00C1C4).withOpacity(0.05),
          child: Column(
            children: [
              // Search Field
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khu vực...',
                  hintStyle: const TextStyle(fontFamily: 'SpaceGrotesk'),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF00C1C4)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontFamily: 'SpaceGrotesk'),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'all', Icons.apps),
                    _buildFilterChip('Rau củ', 'vegetables', Icons.eco),
                    _buildFilterChip('Cỏ', 'grass', Icons.grass),
                    _buildFilterChip('Hoa', 'flowers', Icons.local_florist),
                    _buildFilterChip('Cây', 'trees', Icons.park),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Zones List
        Expanded(
          child: filteredZones.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: filteredZones.length,
                  itemBuilder: (context, index) {
                    final zone = filteredZones[index];
                    return ZoneCard(
                      zone: zone,
                      device: widget.devices[zone.id],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ZoneDetailPage(
                              zone: zone,
                              device: widget.devices[zone.id],
                            ),
                          ),
                        );
                      },
                      onToggle: (value) => widget.onToggle(zone.id, value),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String type, IconData icon) {
    final isSelected = _filterType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterType = type);
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF00C1C4),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF00C1C4) : Colors.grey[300]!,
        ),
      ),
    );
  }

  List<ZoneModel> _getFilteredZones() {
    var zones = widget.zones;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      zones = zones.where((zone) {
        return zone.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            zone.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    if (_filterType != 'all') {
      zones = zones.where((zone) => zone.plantType == _filterType).toList();
    }

    return zones;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _filterType != 'all'
                  ? Icons.search_off
                  : Icons.grass,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterType != 'all'
                  ? 'Không tìm thấy khu vực'
                  : 'Chưa có khu vực nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterType != 'all'
                  ? 'Thử tìm kiếm hoặc lọc khác'
                  : 'Tạo khu vực đầu tiên của bạn',
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
