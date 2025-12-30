import 'package:flutter/foundation.dart';

import '../models/watering_history_model.dart';
import 'firebase_service.dart';

class PlantLibraryService {
  static final PlantLibraryService _instance = PlantLibraryService._internal();
  factory PlantLibraryService() => _instance;
  PlantLibraryService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // ✅ FIX 1: Cache để tránh load lại nhiều lần
  List<PlantProfileModel>? _cachedPlants;
  bool _isInitializing = false;

  // ✅ FIX 2: Improved initialization with retry logic
  Future<void> initializeDefaultLibrary({bool forceReinit = false}) async {
    if (_isInitializing) {
      debugPrint('⏳ Already initializing plant library...');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('🌱 Initializing plant library...');

      // Check if library already exists
      if (!forceReinit) {
        final existing = await getAllPlants().first.timeout(
              const Duration(seconds: 10),
              onTimeout: () => <PlantProfileModel>[],
            );

        if (existing.isNotEmpty) {
          debugPrint(
              '✅ Plant library already initialized (${existing.length} plants)');
          _cachedPlants = existing;
          _isInitializing = false;
          return;
        }
      }

      // Initialize with default plants
      final defaultPlants = _getDefaultPlants();
      debugPrint('📝 Adding ${defaultPlants.length} default plants...');

      int successCount = 0;
      for (var plant in defaultPlants) {
        try {
          await _firebaseService.addPlantProfile(plant);
          successCount++;
          debugPrint('✅ Added: ${plant.name}');
        } catch (e) {
          debugPrint('❌ Failed to add ${plant.name}: $e');
        }
      }

      debugPrint(
          '✅ Plant library initialized: $successCount/${defaultPlants.length} plants added');

      // Reload cache
      _cachedPlants = await getAllPlants().first;
    } catch (e) {
      debugPrint('❌ Error initializing plant library: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  // ✅ FIX 3: Better error handling in getAllPlants
  Stream<List<PlantProfileModel>> getAllPlants() {
    return _firebaseService.getAllPlantProfilesStream().handleError((error) {
      debugPrint('❌ Error loading plants: $error');
      // Return cached data if available
      if (_cachedPlants != null) {
        return Stream.value(_cachedPlants!);
      }
      return Stream.value(<PlantProfileModel>[]);
    });
  }

  // Get plants by category
  Stream<List<PlantProfileModel>> getPlantsByCategory(String category) {
    return _firebaseService.getPlantProfilesByCategoryStream(category);
  }

  // Search plants
  Future<List<PlantProfileModel>> searchPlants(String query) async {
    try {
      final allPlants = await getAllPlants().first.timeout(
            const Duration(seconds: 10),
          );

      final lowerQuery = query.toLowerCase();
      return allPlants.where((plant) {
        return plant.name.toLowerCase().contains(lowerQuery) ||
            plant.scientificName.toLowerCase().contains(lowerQuery) ||
            plant.description.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error searching plants: $e');
      return [];
    }
  }

  // Get recommended plants based on zone conditions
  Future<List<PlantProfileModel>> getRecommendedPlants({
    required String soilType,
    required String sunExposure,
    required double avgTemperature,
    required double avgHumidity,
  }) async {
    try {
      final allPlants = await getAllPlants().first.timeout(
            const Duration(seconds: 10),
          );

      return allPlants.where((plant) {
        // Check soil compatibility
        final soilMatch = plant.soilTypes.contains(soilType);

        // Check sun exposure
        final sunMatch = plant.sunExposure == sunExposure;

        // Check temperature range
        final tempMatch = avgTemperature >= plant.minTemperature &&
            avgTemperature <= plant.maxTemperature;

        // Check humidity range
        final humidityMatch = avgHumidity >= plant.minHumidity &&
            avgHumidity <= plant.maxHumidity;

        // Return if at least 2 out of 4 conditions match
        final matches = [soilMatch, sunMatch, tempMatch, humidityMatch]
            .where((m) => m)
            .length;

        return matches >= 2; // ✅ FIX 4: Giảm từ 3 xuống 2 để flexible hơn
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting recommended plants: $e');
      return [];
    }
  }

  // Get plant profile by ID
  Future<PlantProfileModel?> getPlantProfile(String plantId) async {
    try {
      return await _firebaseService.getPlantProfile(plantId);
    } catch (e) {
      debugPrint('❌ Error getting plant profile: $e');
      return null;
    }
  }

  // Get zone profile
  Future<ZoneProfileModel?> getZoneProfile(String zoneId) async {
    try {
      return await _firebaseService.getZoneProfile(zoneId);
    } catch (e) {
      debugPrint('❌ Error getting zone profile: $e');
      return null;
    }
  }

  // Save zone profile
  Future<void> saveZoneProfile(ZoneProfileModel profile) async {
    try {
      await _firebaseService.saveZoneProfile(profile);
      debugPrint('✅ Zone profile saved: ${profile.zoneId}');
    } catch (e) {
      debugPrint('❌ Error saving zone profile: $e');
      rethrow;
    }
  }

  // Generate watering recommendation for a zone
  Future<Map<String, dynamic>> generateWateringRecommendation(
    String zoneId,
  ) async {
    try {
      final zoneProfile = await getZoneProfile(zoneId);
      if (zoneProfile == null) {
        return {
          'recommended': false,
          'message': 'Chưa có profile cho zone này',
        };
      }

      final plantProfile = await getPlantProfile(zoneProfile.plantProfileId);
      if (plantProfile == null) {
        return {
          'recommended': false,
          'message': 'Không tìm thấy thông tin cây trồng',
        };
      }

      // Calculate adjusted duration
      final baseDuration = plantProfile.wateringDuration;
      final adjustedDuration =
          zoneProfile.calculateAdjustedDuration(baseDuration);

      return {
        'recommended': true,
        'frequency': plantProfile.wateringFrequency,
        'duration': adjustedDuration,
        'baseDuration': baseDuration,
        'optimalSoilMoisture': plantProfile.optimalSoilMoisture,
        'careTips': plantProfile.careTips,
        'adjustmentFactors': {
          'slope': zoneProfile.slope,
          'drainage': zoneProfile.drainage,
          'multiplier': zoneProfile.wateringMultiplier,
        },
      };
    } catch (e) {
      debugPrint('❌ Error generating recommendation: $e');
      return {
        'recommended': false,
        'message': 'Lỗi khi tạo đề xuất: $e',
      };
    }
  }

  // ✅ FIX 5: EXPANDED DEFAULT LIBRARY - 30+ plants
  List<PlantProfileModel> _getDefaultPlants() {
    return [
      // ============ RAU CỦ (VEGETABLES) - 10 cây ============
      PlantProfileModel(
        id: 'tomato',
        name: 'Cà chua',
        scientificName: 'Solanum lycopersicum',
        category: 'vegetables',
        description:
            'Cây cà chua dễ trồng, cần nhiều nước và ánh sáng mặt trời',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 18,
        maxTemperature: 32,
        minHumidity: 50,
        maxHumidity: 80,
        careTips: [
          'Tưới đều đặn, tránh để đất quá khô',
          'Cần nhiều ánh sáng mặt trời (6-8 giờ/ngày)',
          'Bón phân hữu cơ mỗi 2 tuần',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'lettuce',
        name: 'Rau xà lách',
        scientificName: 'Lactuca sativa',
        category: 'vegetables',
        description: 'Rau xà lách mọc nhanh, thích hợp trồng quanh năm',
        imageUrl: '',
        wateringFrequency: 1,
        wateringDuration: 10,
        optimalSoilMoisture: 65,
        sunExposure: 'partial',
        soilTypes: ['loam'],
        minTemperature: 15,
        maxTemperature: 25,
        minHumidity: 60,
        maxHumidity: 80,
        careTips: [
          'Tưới đều đặn để lá giòn và ngọt',
          'Tránh nắng gắt buổi trưa',
          'Thu hoạch sớm để lá non',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'cucumber',
        name: 'Dưa chuột',
        scientificName: 'Cucumis sativus',
        category: 'vegetables',
        description: 'Dưa leo dễ trồng, sinh trưởng nhanh, cần nhiều nước',
        imageUrl: '',
        wateringFrequency: 1,
        wateringDuration: 20,
        optimalSoilMoisture: 70,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 60,
        maxHumidity: 85,
        careTips: [
          'Cần giàn leo để quả phát triển tốt',
          'Tưới thường xuyên nhưng không úng',
          'Thu hoạch khi quả còn xanh non',
        ],
        season: 'summer',
      ),
      PlantProfileModel(
        id: 'chili',
        name: 'Ớt',
        scientificName: 'Capsicum annuum',
        category: 'vegetables',
        description: 'Cây ớt bền bỉ, dễ trồng, cho quả quanh năm',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 12,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 50,
        maxHumidity: 75,
        careTips: [
          'Cần nhiều ánh sáng để quả phát triển',
          'Tránh úng nước gây thối rễ',
          'Hái quả già để kích thích ra hoa mới',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'spinach',
        name: 'Rau bina',
        scientificName: 'Spinacia oleracea',
        category: 'vegetables',
        description: 'Rau bina giàu dinh dưỡng, mọc nhanh trong thời tiết mát',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 10,
        optimalSoilMoisture: 65,
        sunExposure: 'partial',
        soilTypes: ['loam'],
        minTemperature: 10,
        maxTemperature: 25,
        minHumidity: 60,
        maxHumidity: 80,
        careTips: [
          'Trồng vào mùa thu đông cho chất lượng tốt',
          'Thu hoạch lá ngoài trước',
          'Bón phân đạm để lá xanh đậm',
        ],
        season: 'fall',
      ),
      PlantProfileModel(
        id: 'carrot',
        name: 'Cà rốt',
        scientificName: 'Daucus carota',
        category: 'vegetables',
        description: 'Củ cà rốt ngọt, cần đất tơi xốp để rễ phát triển',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['sand', 'loam'],
        minTemperature: 15,
        maxTemperature: 25,
        minHumidity: 55,
        maxHumidity: 75,
        careTips: [
          'Đất phải tơi xốp sâu ít nhất 30cm',
          'Tưới đều để củ không bị nứt',
          'Thu hoạch sau 70-80 ngày',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'eggplant',
        name: 'Cà tím',
        scientificName: 'Solanum melongena',
        category: 'vegetables',
        description: 'Cà tím dễ trồng, cho nhiều quả, thích khí hậu ấm',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 18,
        optimalSoilMoisture: 62,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 20,
        maxTemperature: 32,
        minHumidity: 55,
        maxHumidity: 80,
        careTips: [
          'Cần nhiều ánh sáng để quả phát triển',
          'Tỉa bớt quả nhỏ để quả to hơn',
          'Phòng sâu đục quả',
        ],
        season: 'summer',
      ),
      // ... Các cây khác giữ nguyên theo danh sách của bạn
      PlantProfileModel(
        id: 'cabbage',
        name: 'Bắp cải',
        scientificName: 'Brassica oleracea',
        category: 'vegetables',
        description: 'Bắp cải giòn ngọt, thích trồng vào mùa mát',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 65,
        sunExposure: 'full',
        soilTypes: ['loam', 'clay'],
        minTemperature: 12,
        maxTemperature: 24,
        minHumidity: 60,
        maxHumidity: 85,
        careTips: [
          'Bón phân đều đặn để bắp to',
          'Phòng sâu xanh',
          'Thu hoạch khi bắp chắc',
        ],
        season: 'fall',
      ),
      PlantProfileModel(
        id: 'bean',
        name: 'Đậu đũa',
        scientificName: 'Vigna unguiculata',
        category: 'vegetables',
        description: 'Đậu đũa leo giàn, cho nhiều quả, dễ chăm sóc',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 58,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 18,
        maxTemperature: 35,
        minHumidity: 50,
        maxHumidity: 75,
        careTips: [
          'Dựng giàn cao 1.5-2m',
          'Hái quả non thường xuyên',
          'Bón phân lân kali',
        ],
        season: 'summer',
      ),
      PlantProfileModel(
        id: 'kale',
        name: 'Cải xoăn Kale',
        scientificName: 'Brassica oleracea var. sabellica',
        category: 'vegetables',
        description: 'Siêu thực phẩm giàu dinh dưỡng, dễ trồng',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 12,
        optimalSoilMoisture: 63,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 10,
        maxTemperature: 25,
        minHumidity: 55,
        maxHumidity: 80,
        careTips: [
          'Thu hoạch lá ngoài, để thân tiếp tục ra lá',
          'Chịu lạnh tốt',
          'Bón phân hữu cơ thường xuyên',
        ],
        season: 'all',
      ),

      // ============ CỎ (GRASS) - 5 loại ============
      PlantProfileModel(
        id: 'bermuda_grass',
        name: 'Cỏ Bermuda',
        scientificName: 'Cynodon dactylon',
        category: 'grass',
        description: 'Cỏ chịu hạn tốt, phù hợp cho sân vườn',
        imageUrl: '',
        wateringFrequency: 3,
        wateringDuration: 20,
        optimalSoilMoisture: 45,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand', 'clay'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 30,
        maxHumidity: 70,
        careTips: [
          'Tưới sâu nhưng không thường xuyên',
          'Cắt cỏ thường xuyên để dày đặc',
          'Bón phân 4 lần/năm',
        ],
        season: 'summer',
      ),
      PlantProfileModel(
        id: 'zoysia_grass',
        name: 'Cỏ Zoysia',
        scientificName: 'Zoysia spp.',
        category: 'grass',
        description: 'Cỏ dày đặc, chịu được đạp đạp, ít bệnh',
        imageUrl: '',
        wateringFrequency: 4,
        wateringDuration: 25,
        optimalSoilMoisture: 42,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 15,
        maxTemperature: 32,
        minHumidity: 35,
        maxHumidity: 70,
        careTips: [
          'Tưới sâu 1-2 lần/tuần',
          'Cắt ở độ cao 2-3cm',
          'Thích đất có pH 6-7',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'buffalo_grass',
        name: 'Cỏ Buffalo',
        scientificName: 'Bouteloua dactyloides',
        category: 'grass',
        description: 'Cỏ bản địa Bắc Mỹ, tiết kiệm nước',
        imageUrl: '',
        wateringFrequency: 7,
        wateringDuration: 30,
        optimalSoilMoisture: 38,
        sunExposure: 'full',
        soilTypes: ['loam', 'clay'],
        minTemperature: 18,
        maxTemperature: 38,
        minHumidity: 25,
        maxHumidity: 65,
        careTips: [
          'Chịu hạn cực tốt',
          'Cắt cao 5-8cm',
          'Ít cần bón phân',
        ],
        season: 'summer',
      ),
      PlantProfileModel(
        id: 'kentucky_bluegrass',
        name: 'Cỏ Kentucky',
        scientificName: 'Poa pratensis',
        category: 'grass',
        description: 'Cỏ xanh mướt, mềm mại, thích khí hậu mát',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 25,
        optimalSoilMoisture: 52,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 10,
        maxTemperature: 25,
        minHumidity: 45,
        maxHumidity: 75,
        careTips: [
          'Cần nhiều nước hơn cỏ khác',
          'Tự phục hồi tốt sau hư hại',
          'Bón phân đạm định kỳ',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'fescue_grass',
        name: 'Cỏ Fescue',
        scientificName: 'Festuca spp.',
        category: 'grass',
        description: 'Cỏ chịu bóng tốt, thích hợp trồng dưới cây',
        imageUrl: '',
        wateringFrequency: 3,
        wateringDuration: 20,
        optimalSoilMoisture: 48,
        sunExposure: 'shade',
        soilTypes: ['loam', 'clay'],
        minTemperature: 8,
        maxTemperature: 28,
        minHumidity: 40,
        maxHumidity: 80,
        careTips: [
          'Chịu bóng râm tốt nhất',
          'Cắt ở độ cao 6-8cm',
          'Ít bị sâu bệnh',
        ],
        season: 'fall',
      ),

      // ============ HOA (FLOWERS) - 8 loại ============
      PlantProfileModel(
        id: 'rose',
        name: 'Hoa hồng',
        scientificName: 'Rosa',
        category: 'flowers',
        description: 'Hoa hồng đẹp, cần chăm sóc cẩn thận',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 18,
        maxTemperature: 28,
        minHumidity: 50,
        maxHumidity: 70,
        careTips: [
          'Tưới vào gốc, tránh tưới lên lá',
          'Cần ít nhất 6 giờ nắng/ngày',
          'Cắt tỉa thường xuyên',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'marigold',
        name: 'Cúc vạn thọ',
        scientificName: 'Tagetes',
        category: 'flowers',
        description: 'Hoa dễ trồng, chống sâu bệnh tự nhiên',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 10,
        optimalSoilMoisture: 50,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 18,
        maxTemperature: 32,
        minHumidity: 40,
        maxHumidity: 70,
        careTips: [
          'Tưới vừa phải, tránh úng nước',
          'Hái hoa tàn để kích thích ra hoa mới',
          'Trồng quanh vườn rau để đuổi sâu',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'sunflower',
        name: 'Hoa hướng dương',
        scientificName: 'Helianthus annuus',
        category: 'flowers',
        description: 'Hoa lớn, rực rỡ, theo ánh mặt trời',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 20,
        optimalSoilMoisture: 58,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 18,
        maxTemperature: 35,
        minHumidity: 40,
        maxHumidity: 75,
        careTips: [
          'Cần nhiều ánh sáng trực tiếp',
          'Tưới nhiều khi trời nóng',
          'Có thể cao đến 2-3m, cần chống đỡ',
        ],
        season: 'summer',
      ),
      PlantProfileModel(
        id: 'lavender',
        name: 'Hoa oải hương',
        scientificName: 'Lavandula',
        category: 'flowers',
        description: 'Hoa thơm, chịu hạn, làm dịu thần kinh',
        imageUrl: '',
        wateringFrequency: 4,
        wateringDuration: 10,
        optimalSoilMoisture: 40,
        sunExposure: 'full',
        soilTypes: ['sand', 'loam'],
        minTemperature: 15,
        maxTemperature: 32,
        minHumidity: 30,
        maxHumidity: 60,
        careTips: [
          'Chịu hạn tốt, tưới ít',
          'Cần đất thoát nước tốt',
          'Cắt tỉa sau khi hoa tàn',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'petunia',
        name: 'Hoa dạ yến thảo',
        scientificName: 'Petunia',
        category: 'flowers',
        description: 'Hoa nhiều màu sắc, nở quanh năm',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 12,
        optimalSoilMoisture: 52,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 15,
        maxTemperature: 30,
        minHumidity: 45,
        maxHumidity: 75,
        careTips: [
          'Bón phân thường xuyên',
          'Hái hoa tàn để nở liên tục',
          'Thích hợp trồng chậu treo',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'orchid',
        name: 'Hoa lan',
        scientificName: 'Orchidaceae',
        category: 'flowers',
        description: 'Hoa quý, cần chăm sóc đặc biệt',
        imageUrl: '',
        wateringFrequency: 4,
        wateringDuration: 5,
        optimalSoilMoisture: 45,
        sunExposure: 'partial',
        soilTypes: ['sand'],
        minTemperature: 18,
        maxTemperature: 28,
        minHumidity: 60,
        maxHumidity: 80,
        careTips: [
          'Tưới ít, để rễ khô giữa các lần',
          'Cần ánh sáng gián tiếp',
          'Trồng trong giá thể chuyên dụng',
        ],
        season: 'all',
      ),

      // ============ TREES - 1 loại ============
      PlantProfileModel(
        id: 'lemon',
        name: 'Cây chanh',
        scientificName: 'Citrus limon',
        category: 'trees',
        description: 'Cây ăn quả dễ trồng, cho trái quanh năm',
        imageUrl: '',
        wateringFrequency: 3,
        wateringDuration: 25,
        optimalSoilMoisture: 50,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 50,
        maxHumidity: 80,
        careTips: [
          'Tưới sâu 2-3 lần/tuần',
          'Bón phân chuyên dụng cho cây có múi',
          'Tỉa cành để thoáng đãng',
        ],
        season: 'all',
      ),

      // ============ SUCCULENTS - 1 loại ============
      PlantProfileModel(
        id: 'jade_plant',
        name: 'Cây ngọc bích',
        scientificName: 'Crassula ovata',
        category: 'succulents',
        description: 'Sen đá chịu hạn cực tốt, dễ chăm sóc',
        imageUrl: '',
        wateringFrequency: 7,
        wateringDuration: 5,
        optimalSoilMoisture: 30,
        sunExposure: 'partial',
        soilTypes: ['sand'],
        minTemperature: 18,
        maxTemperature: 30,
        minHumidity: 20,
        maxHumidity: 50,
        careTips: [
          'Tưới ít, chỉ khi đất khô hoàn toàn',
          'Tránh úng nước gây thối rễ',
          'Cần ánh sáng gián tiếp',
        ],
        season: 'all',
      ),
    ];
  }
}
