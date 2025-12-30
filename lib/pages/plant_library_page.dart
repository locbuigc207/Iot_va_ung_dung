import 'package:flutter/material.dart';

import '../models/watering_history_model.dart';
import '../services/plant_library_service.dart';

class PlantLibraryPage extends StatefulWidget {
  const PlantLibraryPage({Key? key}) : super(key: key);

  @override
  State<PlantLibraryPage> createState() => _PlantLibraryPageState();
}

class _PlantLibraryPageState extends State<PlantLibraryPage> {
  final PlantLibraryService _libraryService = PlantLibraryService();
  final TextEditingController _searchController = TextEditingController();

  List<PlantProfileModel> _allPlants = [];
  List<PlantProfileModel> _filteredPlants = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;

  final Map<String, String> _categories = {
    'all': 'Tất cả',
    'vegetables': 'Rau củ',
    'grass': 'Cỏ',
    'flowers': 'Hoa',
    'trees': 'Cây',
    'succulents': 'Sen đá',
  };

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    setState(() => _isLoading = true);

    try {
      // Check if library exists, if not initialize
      final plants = await _libraryService.getAllPlants().first;

      if (plants.isEmpty) {
        await _libraryService.initializeDefaultLibrary();
        final initializedPlants = await _libraryService.getAllPlants().first;

        if (mounted) {
          setState(() {
            _allPlants = initializedPlants;
            _filteredPlants = initializedPlants;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _allPlants = plants;
            _filteredPlants = plants;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading plants: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterPlants() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPlants = _allPlants.where((plant) {
        // Category filter
        final categoryMatch =
            _selectedCategory == 'all' || plant.category == _selectedCategory;

        // Search filter
        final searchMatch = query.isEmpty ||
            plant.name.toLowerCase().contains(query) ||
            plant.scientificName.toLowerCase().contains(query) ||
            plant.description.toLowerCase().contains(query);

        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  void _showPlantDetails(PlantProfileModel plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _buildPlantDetails(plant, scrollController);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thư viện cây trồng',
          style: TextStyle(
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
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => _filterPlants(),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cây trồng...',
                    hintStyle: const TextStyle(fontFamily: 'SpaceGrotesk'),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF00C1C4)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'SpaceGrotesk'),
                ),
                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.entries.map((entry) {
                      final isSelected = _selectedCategory == entry.key;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            entry.value,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = entry.key;
                              _filterPlants();
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF00C1C4),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Plants Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlants.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _filteredPlants.length,
                        itemBuilder: (context, index) {
                          return _buildPlantCard(_filteredPlants[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(PlantProfileModel plant) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showPlantDetails(plant),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Icon/Image
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF00C1C4).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  plant.getCategoryIcon(),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),

            // Plant Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SpaceGrotesk',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontFamily: 'SpaceGrotesk',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.water_drop,
                            size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${plant.wateringFrequency} ngày',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantDetails(
      PlantProfileModel plant, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C1C4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  plant.getCategoryIcon(),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C1C4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        plant.getCategoryDisplay(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF00C1C4),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            plant.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'SpaceGrotesk',
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Watering Requirements
          _buildSection(
            'Yêu cầu tưới nước',
            Icons.water_drop,
            [
              _buildInfoRow('Tần suất', 'Mỗi ${plant.wateringFrequency} ngày'),
              _buildInfoRow('Thời gian/lần', '${plant.wateringDuration} phút'),
              _buildInfoRow('Độ ẩm tối ưu',
                  '${plant.optimalSoilMoisture.toStringAsFixed(0)}%'),
            ],
          ),

          const SizedBox(height: 20),

          // Environmental Preferences
          _buildSection(
            'Điều kiện môi trường',
            Icons.wb_sunny,
            [
              _buildInfoRow(
                  'Ánh sáng', _getSunExposureDisplay(plant.sunExposure)),
              _buildInfoRow('Nhiệt độ',
                  '${plant.minTemperature.toStringAsFixed(0)}°C - ${plant.maxTemperature.toStringAsFixed(0)}°C'),
              _buildInfoRow('Độ ẩm',
                  '${plant.minHumidity.toStringAsFixed(0)}% - ${plant.maxHumidity.toStringAsFixed(0)}%'),
              _buildInfoRow(
                  'Loại đất',
                  plant.soilTypes
                      .map((s) => _getSoilTypeDisplay(s))
                      .join(', ')),
            ],
          ),

          const SizedBox(height: 20),

          // Care Tips
          if (plant.careTips.isNotEmpty)
            _buildSection(
              'Mẹo chăm sóc',
              Icons.lightbulb,
              plant.careTips.map((tip) => _buildTipItem(tip)).toList(),
            ),

          const SizedBox(height: 80),
        ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF00C1C4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontFamily: 'SpaceGrotesk',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSunExposureDisplay(String sunExposure) {
    switch (sunExposure) {
      case 'full':
        return 'Nắng toàn phần';
      case 'partial':
        return 'Nắng một phần';
      case 'shade':
        return 'Bóng râm';
      default:
        return sunExposure;
    }
  }

  String _getSoilTypeDisplay(String soilType) {
    switch (soilType) {
      case 'clay':
        return 'Đất sét';
      case 'sand':
        return 'Đất cát';
      case 'loam':
        return 'Đất pha';
      default:
        return soilType;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy cây trồng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm hoặc chọn danh mục khác',
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
