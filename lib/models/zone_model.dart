class ZoneModel {
  final String id;
  final String name;
  final String description;
  final String userId;
  final String deviceId;
  final bool isActive;
  final String soilType; // clay, sand, loam
  final String sunExposure; // full, partial, shade
  final String plantType; // vegetables, grass, flowers, trees
  final DateTime createdAt;
  final DateTime? lastWatered;

  ZoneModel({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.deviceId,
    this.isActive = false,
    this.soilType = 'loam',
    this.sunExposure = 'partial',
    this.plantType = 'vegetables',
    required this.createdAt,
    this.lastWatered,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
      'deviceId': deviceId,
      'isActive': isActive,
      'soilType': soilType,
      'sunExposure': sunExposure,
      'plantType': plantType,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastWatered': lastWatered?.millisecondsSinceEpoch,
    };
  }

  // Create from Firebase Map
  factory ZoneModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ZoneModel(
      id: id,
      name: map['name'] ?? 'Unknown Zone',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      isActive: map['isActive'] ?? false,
      soilType: map['soilType'] ?? 'loam',
      sunExposure: map['sunExposure'] ?? 'partial',
      plantType: map['plantType'] ?? 'vegetables',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastWatered: map['lastWatered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastWatered'])
          : null,
    );
  }

  // Copy with method for updates
  ZoneModel copyWith({
    String? name,
    String? description,
    bool? isActive,
    String? soilType,
    String? sunExposure,
    String? plantType,
    DateTime? lastWatered,
  }) {
    return ZoneModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId,
      deviceId: deviceId,
      isActive: isActive ?? this.isActive,
      soilType: soilType ?? this.soilType,
      sunExposure: sunExposure ?? this.sunExposure,
      plantType: plantType ?? this.plantType,
      createdAt: createdAt,
      lastWatered: lastWatered ?? this.lastWatered,
    );
  }

  // Get icon based on plant type
  String getPlantIcon() {
    switch (plantType) {
      case 'vegetables':
        return '🥬';
      case 'grass':
        return '🌿';
      case 'flowers':
        return '🌺';
      case 'trees':
        return '🌳';
      default:
        return '🌱';
    }
  }

  // Get soil type display name
  String getSoilTypeDisplay() {
    switch (soilType) {
      case 'clay':
        return 'Đất sét';
      case 'sand':
        return 'Đất cát';
      case 'loam':
        return 'Đất pha';
      default:
        return 'Không xác định';
    }
  }

  // Get sun exposure display name
  String getSunExposureDisplay() {
    switch (sunExposure) {
      case 'full':
        return 'Nắng toàn phần';
      case 'partial':
        return 'Nắng một phần';
      case 'shade':
        return 'Bóng râm';
      default:
        return 'Không xác định';
    }
  }
}
