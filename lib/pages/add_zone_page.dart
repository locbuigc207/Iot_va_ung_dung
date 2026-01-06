import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/zone_model.dart';
import '../services/firebase_service.dart';

class AddZonePage extends StatefulWidget {
  const AddZonePage({Key? key}) : super(key: key);

  @override
  State<AddZonePage> createState() => _AddZonePageState();
}

class _AddZonePageState extends State<AddZonePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedSoilType = 'loam';
  String _selectedSunExposure = 'partial';
  String _selectedPlantType = 'vegetables';
  bool _isLoading = false;

  final Map<String, String> _soilTypes = {
    'clay': 'Đất sét',
    'sand': 'Đất cát',
    'loam': 'Đất pha',
  };

  final Map<String, String> _sunExposures = {
    'full': 'Nắng toàn phần',
    'partial': 'Nắng một phần',
    'shade': 'Bóng râm',
  };

  final Map<String, Map<String, dynamic>> _plantTypes = {
    'vegetables': {'name': 'Rau củ', 'icon': '🥬'},
    'grass': {'name': 'Cỏ', 'icon': '🌿'},
    'flowers': {'name': 'Hoa', 'icon': '🌺'},
    'trees': {'name': 'Cây', 'icon': '🌳'},
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveZone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final zone = ZoneModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        userId: userId,
        deviceId: '',
        soilType: _selectedSoilType,
        sunExposure: _selectedSunExposure,
        plantType: _selectedPlantType,
        createdAt: DateTime.now(),
        autoWateringEnabled: false,
      );

      final zoneId = await _firebaseService.addZone(zone);

      if (zoneId != null && mounted) {
        _showPairingInstructions(zoneId);
      } else {
        throw Exception('Failed to create zone');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPairingInstructions(String zoneId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '✅ Khu vực đã tạo!',
          style: TextStyle(fontFamily: 'SpaceGrotesk'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bước tiếp theo:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Bật nguồn thiết bị ESP32\n'
              '2. ESP32 sẽ tự động kết nối WiFi\n'
              '3. Thiết bị sẽ tự động đăng ký với khu vực này\n'
              '4. Chờ 10-30 giây để hoàn tất',
              style: TextStyle(fontFamily: 'SpaceGrotesk'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to zones list
            },
            child: const Text(
              'Đã hiểu',
              style: TextStyle(
                color: Color(0xFF00C1C4),
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm khu vực mới',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00C1C4),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              const Text(
                'Tên khu vực *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'VD: Vườn rau nhà tôi',
                  hintStyle: const TextStyle(fontFamily: 'SpaceGrotesk'),
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontFamily: 'SpaceGrotesk'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên khu vực';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description Field
              const Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mô tả ngắn về khu vực này...',
                  hintStyle: const TextStyle(fontFamily: 'SpaceGrotesk'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontFamily: 'SpaceGrotesk'),
              ),

              const SizedBox(height: 20),

              // Plant Type Selection
              const Text(
                'Loại cây trồng *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: _plantTypes.length,
                itemBuilder: (context, index) {
                  final entry = _plantTypes.entries.elementAt(index);
                  final isSelected = _selectedPlantType == entry.key;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedPlantType = entry.key);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00C1C4).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00C1C4)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            entry.value['icon'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.value['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF00C1C4)
                                  : Colors.grey[700],
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Soil Type Dropdown
              const Text(
                'Loại đất *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSoilType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.landscape),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _soilTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontFamily: 'SpaceGrotesk'),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSoilType = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Sun Exposure Dropdown
              const Text(
                'Mức độ ánh sáng *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSunExposure,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.wb_sunny),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _sunExposures.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontFamily: 'SpaceGrotesk'),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSunExposure = value);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thông tin này sẽ giúp hệ thống đề xuất lịch trình tưới phù hợp cho khu vực của bạn.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveZone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C1C4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tạo khu vực',
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
}
