import 'package:flutter/material.dart';

import '../models/watering_history_model.dart';
import '../models/zone_model.dart';
import '../services/plant_library_service.dart';

class ZoneProfilePage extends StatefulWidget {
  final ZoneModel zone;

  const ZoneProfilePage({
    Key? key,
    required this.zone,
  }) : super(key: key);

  @override
  State<ZoneProfilePage> createState() => _ZoneProfilePageState();
}

class _ZoneProfilePageState extends State<ZoneProfilePage> {
  final PlantLibraryService _libraryService = PlantLibraryService();
  final _formKey = GlobalKey<FormState>();

  ZoneProfileModel? _currentProfile;
  PlantProfileModel? _selectedPlant;
  List<PlantProfileModel> _recommendedPlants = [];

  // Form controllers
  double _slope = 0;
  String _drainage = 'moderate';
  double _sunHoursPerDay = 6;
  bool _hasWindProtection = false;
  double _waterPressure = 30;
  int _numberOfEmitters = 1;
  double _emitterFlowRate = 4;
  double _wateringMultiplier = 1.0;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRecommendedPlants();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _libraryService.getZoneProfile(widget.zone.id);

      if (profile != null && mounted) {
        final plant =
            await _libraryService.getPlantProfile(profile.plantProfileId);

        setState(() {
          _currentProfile = profile;
          _selectedPlant = plant;
          _slope = profile.slope;
          _drainage = profile.drainage;
          _sunHoursPerDay = profile.sunHoursPerDay;
          _hasWindProtection = profile.hasWindProtection;
          _waterPressure = profile.waterPressure;
          _numberOfEmitters = profile.numberOfEmitters;
          _emitterFlowRate = profile.emitterFlowRate;
          _wateringMultiplier = profile.wateringMultiplier;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecommendedPlants() async {
    try {
      final plants = await _libraryService.getRecommendedPlants(
        soilType: widget.zone.soilType,
        sunExposure: widget.zone.sunExposure,
        avgTemperature: 25, // Default
        avgHumidity: 60, // Default
      );

      if (mounted) {
        setState(() => _recommendedPlants = plants);
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlant == null) {
      _showError('Vui lòng chọn loại cây trồng');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = ZoneProfileModel(
        zoneId: widget.zone.id,
        plantProfileId: _selectedPlant!.id,
        plantName: _selectedPlant!.name,
        slope: _slope,
        drainage: _drainage,
        sunHoursPerDay: _sunHoursPerDay,
        hasWindProtection: _hasWindProtection,
        waterPressure: _waterPressure,
        numberOfEmitters: _numberOfEmitters,
        emitterFlowRate: _emitterFlowRate,
        wateringMultiplier: _wateringMultiplier,
        customSettings: {},
        createdAt: _currentProfile?.createdAt ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _libraryService.saveZoneProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu profile thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi khi lưu profile: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectPlant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _buildPlantSelector(scrollController);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile - ${widget.zone.name}',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone Info Card
                    _buildZoneInfoCard(),

                    const SizedBox(height: 24),

                    // Plant Selection
                    _buildSection(
                      'Loại cây trồng',
                      Icons.local_florist,
                      [_buildPlantSelection()],
                    ),

                    const SizedBox(height: 20),

                    // Terrain Characteristics
                    _buildSection(
                      'Đặc điểm địa hình',
                      Icons.terrain,
                      [
                        _buildSlider(
                          'Độ dốc',
                          _slope,
                          0,
                          45,
                          '°',
                          (value) => setState(() => _slope = value),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          'Thoát nước',
                          _drainage,
                          {
                            'poor': 'Kém',
                            'moderate': 'Trung bình',
                            'good': 'Tốt',
                            'excellent': 'Xuất sắc',
                          },
                          (value) => setState(() => _drainage = value!),
                        ),
                        const SizedBox(height: 16),
                        _buildSlider(
                          'Giờ nắng/ngày',
                          _sunHoursPerDay,
                          0,
                          12,
                          'h',
                          (value) => setState(() => _sunHoursPerDay = value),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            'Có chắn gió',
                            style: TextStyle(fontFamily: 'SpaceGrotesk'),
                          ),
                          value: _hasWindProtection,
                          activeColor: const Color(0xFF00C1C4),
                          onChanged: (value) {
                            setState(() => _hasWindProtection = value);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Irrigation Settings
                    _buildSection(
                      'Hệ thống tưới',
                      Icons.water_drop,
                      [
                        _buildSlider(
                          'Áp suất nước',
                          _waterPressure,
                          10,
                          60,
                          'PSI',
                          (value) => setState(() => _waterPressure = value),
                        ),
                        const SizedBox(height: 16),
                        _buildIntSlider(
                          'Số vòi phun',
                          _numberOfEmitters,
                          1,
                          10,
                          '',
                          (value) => setState(() => _numberOfEmitters = value),
                        ),
                        const SizedBox(height: 16),
                        _buildSlider(
                          'Lưu lượng/vòi',
                          _emitterFlowRate,
                          1,
                          10,
                          'L/h',
                          (value) => setState(() => _emitterFlowRate = value),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Custom Adjustments
                    _buildSection(
                      'Điều chỉnh tùy chỉnh',
                      Icons.tune,
                      [
                        _buildSlider(
                          'Hệ số tưới',
                          _wateringMultiplier,
                          0.5,
                          2.0,
                          'x',
                          (value) =>
                              setState(() => _wateringMultiplier = value),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hệ số < 1: giảm nước, > 1: tăng nước',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                    fontFamily: 'SpaceGrotesk',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Recommendation Preview
                    if (_selectedPlant != null) _buildRecommendationPreview(),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C1C4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Lưu Profile',
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
            ),
    );
  }

  Widget _buildZoneInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              widget.zone.getPlantIcon(),
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.zone.name,
                    style: const TextStyle(
                      fontSize: 18,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00C1C4), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantSelection() {
    return InkWell(
      onTap: _selectPlant,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (_selectedPlant != null) ...[
              Text(
                _selectedPlant!.getCategoryIcon(),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPlant!.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    Text(
                      _selectedPlant!.scientificName,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Icon(Icons.add_circle_outline, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Text(
                'Chọn loại cây',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    String unit,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00C1C4),
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFF00C1C4),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIntSlider(
    String label,
    int value,
    int min,
    int max,
    String unit,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            Text(
              '$value$unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00C1C4),
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: const Color(0xFF00C1C4),
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    Map<String, String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(fontFamily: 'SpaceGrotesk'),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRecommendationPreview() {
    // Calculate adjusted duration based on profile
    final baseDuration = _selectedPlant!.wateringDuration;
    final profile = ZoneProfileModel(
      zoneId: widget.zone.id,
      plantProfileId: _selectedPlant!.id,
      plantName: _selectedPlant!.name,
      slope: _slope,
      drainage: _drainage,
      sunHoursPerDay: _sunHoursPerDay,
      hasWindProtection: _hasWindProtection,
      waterPressure: _waterPressure,
      numberOfEmitters: _numberOfEmitters,
      emitterFlowRate: _emitterFlowRate,
      wateringMultiplier: _wateringMultiplier,
      customSettings: {},
      createdAt: DateTime.now(),
    );

    final adjustedDuration = profile.calculateAdjustedDuration(baseDuration);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Gợi ý tưới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecommendationItem(
              'Tần suất',
              'Mỗi ${_selectedPlant!.wateringFrequency} ngày',
            ),
            _buildRecommendationItem(
              'Thời gian gốc',
              '$baseDuration phút',
            ),
            _buildRecommendationItem(
              'Sau điều chỉnh',
              '$adjustedDuration phút',
            ),
            _buildRecommendationItem(
              'Độ ẩm đất tối ưu',
              '${_selectedPlant!.optimalSoilMoisture.toStringAsFixed(0)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSelector(ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn loại cây',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          if (_recommendedPlants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Được đề xuất cho khu vực này',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<PlantProfileModel>>(
              future: _libraryService.getAllPlants().first,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final plants = snapshot.data!;

                return ListView.builder(
                  controller: scrollController,
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    final isRecommended =
                        _recommendedPlants.any((p) => p.id == plant.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isRecommended ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isRecommended
                              ? Colors.green[400]!
                              : Colors.grey[200]!,
                          width: isRecommended ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() => _selectedPlant = plant);
                          Navigator.pop(context);
                        },
                        leading: Text(
                          plant.getCategoryIcon(),
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(
                          plant.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        subtitle: Text(
                          plant.scientificName,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        trailing: isRecommended
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Đề xuất',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SpaceGrotesk',
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
