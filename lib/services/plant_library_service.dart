import '../models/watering_history_model.dart';
import 'firebase_service.dart';

class PlantLibraryService {
  static final PlantLibraryService _instance = PlantLibraryService._internal();
  factory PlantLibraryService() => _instance;
  PlantLibraryService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Get all plant profiles
  Stream<List<PlantProfileModel>> getAllPlants() {
    return _firebaseService.getAllPlantProfilesStream();
  }

  // Get plants by category
  Stream<List<PlantProfileModel>> getPlantsByCategory(String category) {
    return _firebaseService.getPlantProfilesByCategoryStream(category);
  }

  // Search plants
  Future<List<PlantProfileModel>> searchPlants(String query) async {
    final allPlants = await getAllPlants().first;

    final lowerQuery = query.toLowerCase();
    return allPlants.where((plant) {
      return plant.name.toLowerCase().contains(lowerQuery) ||
          plant.scientificName.toLowerCase().contains(lowerQuery) ||
          plant.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get recommended plants based on zone conditions
  Future<List<PlantProfileModel>> getRecommendedPlants({
    required String soilType,
    required String sunExposure,
    required double avgTemperature,
    required double avgHumidity,
  }) async {
    final allPlants = await getAllPlants().first;

    return allPlants.where((plant) {
      // Check soil compatibility
      final soilMatch = plant.soilTypes.contains(soilType);

      // Check sun exposure
      final sunMatch = plant.sunExposure == sunExposure;

      // Check temperature range
      final tempMatch = avgTemperature >= plant.minTemperature &&
          avgTemperature <= plant.maxTemperature;

      // Check humidity range
      final humidityMatch =
          avgHumidity >= plant.minHumidity && avgHumidity <= plant.maxHumidity;

      // Return if at least 3 out of 4 conditions match
      final matches = [soilMatch, sunMatch, tempMatch, humidityMatch]
          .where((m) => m)
          .length;

      return matches >= 3;
    }).toList();
  }

  // Get plant profile by ID
  Future<PlantProfileModel?> getPlantProfile(String plantId) async {
    return _firebaseService.getPlantProfile(plantId);
  }

  // Initialize default plant library
  Future<void> initializeDefaultLibrary() async {
    final defaultPlants = _getDefaultPlants();

    for (var plant in defaultPlants) {
      await _firebaseService.addPlantProfile(plant);
    }
  }

  // Get zone profile
  Future<ZoneProfileModel?> getZoneProfile(String zoneId) async {
    return _firebaseService.getZoneProfile(zoneId);
  }

  // Save zone profile
  Future<void> saveZoneProfile(ZoneProfileModel profile) async {
    await _firebaseService.saveZoneProfile(profile);
  }

  // Generate watering recommendation for a zone
  Future<Map<String, dynamic>> generateWateringRecommendation(
    String zoneId,
  ) async {
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
  }

  // Default plant library data
  List<PlantProfileModel> _getDefaultPlants() {
    return [
      // Vegetables
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

      // Grass
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

      // Flowers
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

      // Trees
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

      // Succulents
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
