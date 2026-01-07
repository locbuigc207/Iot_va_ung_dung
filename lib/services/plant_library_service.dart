import 'package:flutter/foundation.dart';

import '../models/watering_history_model.dart';
import 'firebase_service.dart';

class PlantLibraryService {
  static final PlantLibraryService _instance = PlantLibraryService._internal();
  factory PlantLibraryService() => _instance;
  PlantLibraryService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Cache và Completer để handle concurrent requests
  List<PlantProfileModel>? _cachedPlants;
  bool _isInitializing = false;
  Future<void>? _initializationFuture;

  // Improved initialization with Completer pattern
  Future<void> initializeDefaultLibrary({bool forceReinit = false}) async {
    // Nếu đang init, đợi nó xong thay vì return
    if (_isInitializing && _initializationFuture != null) {
      debugPrint('⏳ Waiting for ongoing initialization...');
      await _initializationFuture;
      return;
    }

    _isInitializing = true;
    _initializationFuture = _performInitialization(forceReinit);

    try {
      await _initializationFuture;
    } finally {
      _isInitializing = false;
      _initializationFuture = null;
    }
  }

  Future<void> _performInitialization(bool forceReinit) async {
    try {
      debugPrint('🌱 Initializing plant library...');

      // Check if library already exists
      if (!forceReinit) {
        try {
          final existing = await getAllPlants().first.timeout(
                const Duration(seconds: 5),
                onTimeout: () => <PlantProfileModel>[],
              );

          if (existing.isNotEmpty) {
            debugPrint(
                '✅ Plant library already exists (${existing.length} plants)');
            _cachedPlants = existing;
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Error checking existing plants: $e');
          // Continue to initialize
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
          if (successCount <= 5) {
            debugPrint('✅ Added: ${plant.name}');
          }
        } catch (e) {
          debugPrint('❌ Failed to add ${plant.name}: $e');
        }
      }

      debugPrint(
          '✅ Plant library initialized: $successCount/${defaultPlants.length} plants');

      // Reload cache
      try {
        _cachedPlants = await getAllPlants().first.timeout(
              const Duration(seconds: 5),
            );
      } catch (e) {
        debugPrint('⚠️ Error reloading cache: $e');
      }
    } catch (e) {
      debugPrint('❌ Error initializing plant library: $e');
      // Don't rethrow - app should still work without plant library
    }
  }

  // Better error handling và fallback
  Stream<List<PlantProfileModel>> getAllPlants() {
    return _firebaseService.getAllPlantProfilesStream().handleError((error) {
      debugPrint('❌ Error loading plants: $error');
      // Return cached data if available
      if (_cachedPlants != null) {
        return Stream.value(_cachedPlants!);
      }
      return Stream.value(<PlantProfileModel>[]);
    }).map((plants) {
      if (plants.isNotEmpty) {
        _cachedPlants = plants; // Update cache
      }
      return plants;
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
            const Duration(seconds: 5),
            onTimeout: () => _cachedPlants ?? [],
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
            const Duration(seconds: 5),
            onTimeout: () => _cachedPlants ?? [],
          );

      return allPlants.where((plant) {
        final soilMatch = plant.soilTypes.contains(soilType);
        final sunMatch = plant.sunExposure == sunExposure;
        final tempMatch = avgTemperature >= plant.minTemperature &&
            avgTemperature <= plant.maxTemperature;
        final humidityMatch = avgHumidity >= plant.minHumidity &&
            avgHumidity <= plant.maxHumidity;

        final matches = [soilMatch, sunMatch, tempMatch, humidityMatch]
            .where((m) => m)
            .length;

        return matches >= 2;
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

  // Full default plants library - 30+ plants
  List<PlantProfileModel> _getDefaultPlants() {
    return [
      // VEGETABLES
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
        description: 'Rau xà lách phát triển nhanh, thích hợp trồng quanh năm',
        imageUrl: '',
        wateringFrequency: 1,
        wateringDuration: 10,
        optimalSoilMoisture: 70,
        sunExposure: 'partial',
        soilTypes: ['loam', 'clay'],
        minTemperature: 10,
        maxTemperature: 25,
        minHumidity: 60,
        maxHumidity: 85,
        careTips: [
          'Tưới thường xuyên để lá giòn và ngọt',
          'Trồng ở nơi bóng râm nhẹ',
          'Thu hoạch sớm để tránh đắng',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'cucumber',
        name: 'Dưa chuột',
        scientificName: 'Cucumis sativus',
        category: 'vegetables',
        description: 'Dưa chuột cần nhiều nước, phát triển mạnh trong mùa hè',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 20,
        optimalSoilMoisture: 65,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 55,
        maxHumidity: 85,
        careTips: [
          'Tưới nhiều nước, đặc biệt khi đang ra quả',
          'Dựng giàn cho cây leo',
          'Bón phân NPK 2 tuần/lần',
        ],
        season: 'summer',
      ),
      PlantProfileModel(
        id: 'pepper',
        name: 'Ớt',
        scientificName: 'Capsicum annuum',
        category: 'vegetables',
        description: 'Cây ớt dễ trồng, chịu hạn tốt',
        imageUrl: '',
        wateringFrequency: 3,
        wateringDuration: 12,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 18,
        maxTemperature: 35,
        minHumidity: 45,
        maxHumidity: 75,
        careTips: [
          'Không tưới quá nhiều nước',
          'Cần nhiều ánh sáng để quả cay',
          'Bón phân lân kali khi ra hoa',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'carrot',
        name: 'Cà rốt',
        scientificName: 'Daucus carota',
        category: 'vegetables',
        description: 'Cà rốt cần đất tơi xốp, thoát nước tốt',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['sand', 'loam'],
        minTemperature: 15,
        maxTemperature: 25,
        minHumidity: 50,
        maxHumidity: 75,
        careTips: [
          'Làm đất sâu và tơi xốp',
          'Tưới đều, tránh đất bị khô nứt',
          'Tỉa thưa khi cây cao 5cm',
        ],
        season: 'autumn',
      ),

      // HERBS
      PlantProfileModel(
        id: 'basil',
        name: 'Húng quế',
        scientificName: 'Ocimum basilicum',
        category: 'herbs',
        description: 'Húng quế thơm, dễ trồng trong chậu',
        imageUrl: '',
        wateringFrequency: 1,
        wateringDuration: 8,
        optimalSoilMoisture: 65,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 50,
        maxHumidity: 80,
        careTips: [
          'Tưới vào buổi sáng',
          'Hái ngọn thường xuyên để cây ra nhiều nhánh',
          'Cắt bỏ hoa để lá ngon hơn',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'mint',
        name: 'Bạc hà',
        scientificName: 'Mentha',
        category: 'herbs',
        description: 'Bạc hà phát triển nhanh, dễ chăm sóc',
        imageUrl: '',
        wateringFrequency: 1,
        wateringDuration: 10,
        optimalSoilMoisture: 70,
        sunExposure: 'partial',
        soilTypes: ['loam', 'clay'],
        minTemperature: 15,
        maxTemperature: 30,
        minHumidity: 60,
        maxHumidity: 85,
        careTips: [
          'Giữ đất ẩm đều',
          'Trồng riêng vì lan nhanh',
          'Hái lá thường xuyên',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'coriander',
        name: 'Rau mùi (Ngò)',
        scientificName: 'Coriandrum sativum',
        category: 'herbs',
        description: 'Rau mùi thơm, dễ trồng quanh năm',
        imageUrl: '',
        wateringFrequency: 1,
        wateringDuration: 8,
        optimalSoilMoisture: 65,
        sunExposure: 'partial',
        soilTypes: ['loam'],
        minTemperature: 18,
        maxTemperature: 28,
        minHumidity: 55,
        maxHumidity: 80,
        careTips: [
          'Trồng ở nơi thoáng mát',
          'Tưới nhẹ mỗi ngày',
          'Gieo hạt mới 3-4 tuần/lần',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'lemongrass',
        name: 'Sả',
        scientificName: 'Cymbopogon',
        category: 'herbs',
        description: 'Cây sả dễ trồng, chịu hạn tốt',
        imageUrl: '',
        wateringFrequency: 3,
        wateringDuration: 15,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 38,
        minHumidity: 45,
        maxHumidity: 75,
        careTips: [
          'Chịu hạn tốt, không cần tưới nhiều',
          'Trồng nơi nhiều nắng',
          'Tách khóm khi cây đông',
        ],
        season: 'all',
      ),

      // FLOWERS
      PlantProfileModel(
        id: 'rose',
        name: 'Hoa hồng',
        scientificName: 'Rosa',
        category: 'flowers',
        description: 'Hoa hồng đẹp, cần chăm sóc cẩn thận',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 15,
        maxTemperature: 30,
        minHumidity: 50,
        maxHumidity: 80,
        careTips: [
          'Tưới gốc, tránh làm ướt lá',
          'Bón phân định kỳ',
          'Cắt tỉa hoa héo',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'marigold',
        name: 'Cúc vạn thọ',
        scientificName: 'Tagetes',
        category: 'flowers',
        description: 'Hoa cúc vạn thọ dễ trồng, chống sâu bệnh tốt',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 10,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 18,
        maxTemperature: 35,
        minHumidity: 45,
        maxHumidity: 75,
        careTips: [
          'Chịu hạn và nóng tốt',
          'Tỉa hoa héo để ra hoa liên tục',
          'Trồng xen canh để đuổi sâu',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'sunflower',
        name: 'Hoa hướng dương',
        scientificName: 'Helianthus annuus',
        category: 'flowers',
        description: 'Hoa hướng dương cao lớn, cần nhiều ánh sáng',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 20,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 45,
        maxHumidity: 75,
        careTips: [
          'Cần rất nhiều ánh sáng mặt trời',
          'Tưới nhiều nước khi đang phát triển',
          'Dựng cọc chống đổ',
        ],
        season: 'summer',
      ),
      PlantProfileModel(
        id: 'orchid',
        name: 'Lan hồ điệp',
        scientificName: 'Phalaenopsis',
        category: 'flowers',
        description: 'Lan hồ điệp đẹp, cần độ ẩm cao',
        imageUrl: '',
        wateringFrequency: 5,
        wateringDuration: 5,
        optimalSoilMoisture: 50,
        sunExposure: 'shade',
        soilTypes: ['special'],
        minTemperature: 18,
        maxTemperature: 28,
        minHumidity: 60,
        maxHumidity: 85,
        careTips: [
          'Tưới ít, phun sương nhiều',
          'Trồng giá thể chuyên dụng',
          'Đặt nơi thoáng mát',
        ],
        season: 'all',
      ),

      // FRUITS
      PlantProfileModel(
        id: 'strawberry',
        name: 'Dâu tây',
        scientificName: 'Fragaria × ananassa',
        category: 'fruits',
        description: 'Dâu tây ngọt, thích hợp trồng chậu',
        imageUrl: '',
        wateringFrequency: 1,
        wateringDuration: 12,
        optimalSoilMoisture: 65,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 15,
        maxTemperature: 25,
        minHumidity: 55,
        maxHumidity: 80,
        careTips: [
          'Giữ đất ẩm đều',
          'Phủ rơm để quả sạch',
          'Bón phân khi ra hoa',
        ],
        season: 'autumn',
      ),
      PlantProfileModel(
        id: 'lemon',
        name: 'Chanh',
        scientificName: 'Citrus limon',
        category: 'fruits',
        description: 'Cây chanh dễ trồng, chịu nóng tốt',
        imageUrl: '',
        wateringFrequency: 3,
        wateringDuration: 20,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 15,
        maxTemperature: 35,
        minHumidity: 50,
        maxHumidity: 80,
        careTips: [
          'Tưới đều, tránh ngập úng',
          'Bón phân hữu cơ định kỳ',
          'Cắt tỉa cành khô',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'papaya',
        name: 'Đu đủ',
        scientificName: 'Carica papaya',
        category: 'fruits',
        description: 'Đu đủ phát triển nhanh, cho quả sớm',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 25,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 22,
        maxTemperature: 38,
        minHumidity: 55,
        maxHumidity: 85,
        careTips: [
          'Cần nhiều nước và nắng',
          'Thoát nước tốt',
          'Bón phân NPK thường xuyên',
        ],
        season: 'all',
      ),

      // SUCCULENTS
      PlantProfileModel(
        id: 'aloe_vera',
        name: 'Nha đam',
        scientificName: 'Aloe vera',
        category: 'succulents',
        description: 'Nha đam chịu hạn, dễ chăm sóc',
        imageUrl: '',
        wateringFrequency: 7,
        wateringDuration: 10,
        optimalSoilMoisture: 40,
        sunExposure: 'full',
        soilTypes: ['sand', 'loam'],
        minTemperature: 15,
        maxTemperature: 40,
        minHumidity: 30,
        maxHumidity: 65,
        careTips: [
          'Tưới rất ít nước',
          'Đất phải thoát nước tốt',
          'Chịu nắng và hạn tốt',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'cactus',
        name: 'Xương rồng',
        scientificName: 'Cactaceae',
        category: 'succulents',
        description: 'Xương rồng chịu hạn cực tốt',
        imageUrl: '',
        wateringFrequency: 14,
        wateringDuration: 5,
        optimalSoilMoisture: 35,
        sunExposure: 'full',
        soilTypes: ['sand'],
        minTemperature: 10,
        maxTemperature: 45,
        minHumidity: 20,
        maxHumidity: 60,
        careTips: [
          'Tưới rất ít, tránh úng nước',
          'Cần đất cát, thoát nước cực tốt',
          'Đặt nơi nhiều nắng',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'jade_plant',
        name: 'Cây ngọc',
        scientificName: 'Crassula ovata',
        category: 'succulents',
        description: 'Cây ngọc may mắn, dễ trồng trong nhà',
        imageUrl: '',
        wateringFrequency: 7,
        wateringDuration: 8,
        optimalSoilMoisture: 45,
        sunExposure: 'partial',
        soilTypes: ['sand', 'loam'],
        minTemperature: 15,
        maxTemperature: 30,
        minHumidity: 35,
        maxHumidity: 65,
        careTips: [
          'Tưới khi đất khô hoàn toàn',
          'Ánh sáng gián tiếp',
          'Chăm sóc tối thiểu',
        ],
        season: 'all',
      ),

      // INDOOR PLANTS
      PlantProfileModel(
        id: 'pothos',
        name: 'Trầu bà',
        scientificName: 'Epipremnum aureum',
        category: 'indoor',
        description: 'Trầu bà dễ sống, thanh lọc không khí tốt',
        imageUrl: '',
        wateringFrequency: 5,
        wateringDuration: 10,
        optimalSoilMoisture: 55,
        sunExposure: 'shade',
        soilTypes: ['loam'],
        minTemperature: 18,
        maxTemperature: 30,
        minHumidity: 50,
        maxHumidity: 80,
        careTips: [
          'Sống tốt trong bóng râm',
          'Tưới khi đất khô 2-3cm',
          'Cắt tỉa để cây đẹp hơn',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'snake_plant',
        name: 'Lưỡi hổ',
        scientificName: 'Sansevieria trifasciata',
        category: 'indoor',
        description: 'Lưỡi hổ cực kỳ dễ chăm, thanh lọc không khí',
        imageUrl: '',
        wateringFrequency: 14,
        wateringDuration: 8,
        optimalSoilMoisture: 40,
        sunExposure: 'partial',
        soilTypes: ['sand', 'loam'],
        minTemperature: 15,
        maxTemperature: 35,
        minHumidity: 30,
        maxHumidity: 70,
        careTips: [
          'Chịu hạn cực tốt',
          'Sống được cả trong bóng tối',
          'Tưới rất ít nước',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'peace_lily',
        name: 'Lan ý',
        scientificName: 'Spathiphyllum',
        category: 'indoor',
        description: 'Lan ý hoa trắng đẹp, thanh lọc không khí',
        imageUrl: '',
        wateringFrequency: 5,
        wateringDuration: 12,
        optimalSoilMoisture: 60,
        sunExposure: 'shade',
        soilTypes: ['loam'],
        minTemperature: 18,
        maxTemperature: 28,
        minHumidity: 55,
        maxHumidity: 85,
        careTips: [
          'Thích ẩm và bóng râm',
          'Lá héo = cần nước',
          'Phun sương lên lá',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'spider_plant',
        name: 'Cây nhện',
        scientificName: 'Chlorophytum comosum',
        category: 'indoor',
        description: 'Cây nhện dễ trồng, sinh sản nhanh',
        imageUrl: '',
        wateringFrequency: 4,
        wateringDuration: 10,
        optimalSoilMoisture: 55,
        sunExposure: 'partial',
        soilTypes: ['loam'],
        minTemperature: 15,
        maxTemperature: 30,
        minHumidity: 45,
        maxHumidity: 75,
        careTips: [
          'Ánh sáng gián tiếp',
          'Tưới đều đặn',
          'Sinh sản bằng cây con',
        ],
        season: 'all',
      ),

      // TREES
      PlantProfileModel(
        id: 'mango',
        name: 'Xoài',
        scientificName: 'Mangifera indica',
        category: 'trees',
        description: 'Cây xoài cho trái ngọt, chịu hạn tốt',
        imageUrl: '',
        wateringFrequency: 7,
        wateringDuration: 30,
        optimalSoilMoisture: 50,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 40,
        minHumidity: 50,
        maxHumidity: 80,
        careTips: [
          'Cây trưởng thành chịu hạn tốt',
          'Cây con cần tưới thường xuyên',
          'Bón phân khi ra hoa và đậu quả',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'guava',
        name: 'Ổi',
        scientificName: 'Psidium guajava',
        category: 'trees',
        description: 'Cây ổi dễ trồng, cho trái nhiều',
        imageUrl: '',
        wateringFrequency: 4,
        wateringDuration: 25,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam', 'clay'],
        minTemperature: 18,
        maxTemperature: 38,
        minHumidity: 50,
        maxHumidity: 85,
        careTips: [
          'Tưới đều, tránh khô hạn',
          'Cắt tỉa tạo tán',
          'Bón phân hữu cơ định kỳ',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'moringa',
        name: 'Chùm ngây',
        scientificName: 'Moringa oleifera',
        category: 'trees',
        description: 'Chùm ngây giàu dinh dưỡng, chịu hạn cực tốt',
        imageUrl: '',
        wateringFrequency: 7,
        wateringDuration: 20,
        optimalSoilMoisture: 45,
        sunExposure: 'full',
        soilTypes: ['sand', 'loam'],
        minTemperature: 20,
        maxTemperature: 42,
        minHumidity: 40,
        maxHumidity: 75,
        careTips: [
          'Chịu hạn và nóng cực tốt',
          'Cắt tỉa thường xuyên để thu hoạch lá',
          'Tưới ít, tránh úng nước',
        ],
        season: 'all',
      ),

      // VINES
      PlantProfileModel(
        id: 'grape',
        name: 'Nho',
        scientificName: 'Vitis vinifera',
        category: 'vines',
        description: 'Nho leo giàn, cần chăm sóc cẩn thận',
        imageUrl: '',
        wateringFrequency: 3,
        wateringDuration: 20,
        optimalSoilMoisture: 55,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 15,
        maxTemperature: 32,
        minHumidity: 50,
        maxHumidity: 75,
        careTips: [
          'Dựng giàn cho cây leo',
          'Tưới đều, không được úng',
          'Cắt tỉa sau thu hoạch',
        ],
        season: 'spring',
      ),
      PlantProfileModel(
        id: 'passion_fruit',
        name: 'Chanh dây',
        scientificName: 'Passiflora edulis',
        category: 'vines',
        description: 'Chanh dây leo nhanh, cho quả nhiều',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 18,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['loam', 'sand'],
        minTemperature: 20,
        maxTemperature: 35,
        minHumidity: 55,
        maxHumidity: 85,
        careTips: [
          'Dựng giàn chắc chắn',
          'Tưới nhiều nước khi ra hoa và quả',
          'Bón phân lân kali',
        ],
        season: 'all',
      ),
      PlantProfileModel(
        id: 'bitter_melon',
        name: 'Khổ qua',
        scientificName: 'Momordica charantia',
        category: 'vines',
        description: 'Khổ qua tốt cho sức khỏe, dễ trồng',
        imageUrl: '',
        wateringFrequency: 2,
        wateringDuration: 15,
        optimalSoilMoisture: 60,
        sunExposure: 'full',
        soilTypes: ['loam'],
        minTemperature: 22,
        maxTemperature: 35,
        minHumidity: 55,
        maxHumidity: 80,
        careTips: [
          'Dựng giàn hoặc lưới',
          'Tưới đều đặn',
          'Bón phân khi ra hoa',
        ],
        season: 'summer',
      ),
    ];
  }
}
