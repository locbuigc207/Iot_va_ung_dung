import 'package:flutter/material.dart';

import '../models/sensor_model.dart';
import '../models/zone_model.dart';
import '../services/firebase_service.dart';

class AddSensorPage extends StatefulWidget {
  final ZoneModel zone;

  const AddSensorPage({
    Key? key,
    required this.zone,
  }) : super(key: key);

  @override
  State<AddSensorPage> createState() => _AddSensorPageState();
}

class _AddSensorPageState extends State<AddSensorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  SensorType _selectedType = SensorType.soilMoisture;
  double _minThreshold = 20.0;
  double _maxThreshold = 80.0;
  bool _alertEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateThresholds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateThresholds() {
    setState(() {
      _minThreshold = _selectedType.defaultMin;
      _maxThreshold = _selectedType.defaultMax;
    });
  }

  Future<void> _saveSensor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sensor = SensorModel(
        id: '',
        zoneId: widget.zone.id,
        zoneName: widget.zone.name,
        name: _nameController.text.trim(),
        type: _selectedType,
        unit: _selectedType.defaultUnit,
        currentValue: _minThreshold,
        minThreshold: _minThreshold,
        maxThreshold: _maxThreshold,
        lastUpdated: DateTime.now(),
        alertEnabled: _alertEnabled,
      );

      final sensorId = await _firebaseService.addSensor(sensor);

      if (sensorId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm cảm biến thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to create sensor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm cảm biến',
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
              // Zone Info
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        widget.zone.getPlantIcon(),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.zone.name,
                              style: const TextStyle(
                                fontSize: 16,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sensor Name
              const Text(
                'Tên cảm biến *',
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
                  hintText: 'VD: Cảm biến độ ẩm đất 1',
                  hintStyle: const TextStyle(fontFamily: 'SpaceGrotesk'),
                  prefixIcon: const Icon(Icons.sensors),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontFamily: 'SpaceGrotesk'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên cảm biến';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Sensor Type
              const Text(
                'Loại cảm biến *',
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
                  childAspectRatio: 1.5,
                ),
                itemCount: SensorType.values.length,
                itemBuilder: (context, index) {
                  final type = SensorType.values[index];
                  final isSelected = _selectedType == type;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                        _updateThresholds();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getTypeIcon(type),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF00C1C4)
                                  : Colors.grey[700],
                              fontFamily: 'SpaceGrotesk',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Thresholds
              const Text(
                'Ngưỡng cảnh báo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 16),

              // Min Threshold
              Text(
                'Ngưỡng thấp: ${_minThreshold.toStringAsFixed(1)} ${_selectedType.defaultUnit}',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              Slider(
                value: _minThreshold,
                min: 0,
                max: _maxThreshold - 5,
                divisions: 100,
                activeColor: const Color(0xFF00C1C4),
                onChanged: (value) {
                  setState(() => _minThreshold = value);
                },
              ),

              const SizedBox(height: 16),

              // Max Threshold
              Text(
                'Ngưỡng cao: ${_maxThreshold.toStringAsFixed(1)} ${_selectedType.defaultUnit}',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              Slider(
                value: _maxThreshold,
                min: _minThreshold + 5,
                max: 100,
                divisions: 100,
                activeColor: const Color(0xFF00C1C4),
                onChanged: (value) {
                  setState(() => _maxThreshold = value);
                },
              ),

              const SizedBox(height: 24),

              // Alert Toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  value: _alertEnabled,
                  onChanged: (value) => setState(() => _alertEnabled = value),
                  activeColor: const Color(0xFF00C1C4),
                  title: const Text(
                    'Bật cảnh báo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  subtitle: Text(
                    'Nhận thông báo khi giá trị vượt ngưỡng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
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
                        'Cảm biến sẽ gửi cảnh báo khi giá trị vượt quá ngưỡng bạn đã đặt.',
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
                  onPressed: _isLoading ? null : _saveSensor,
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
                          'Thêm cảm biến',
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

  String _getTypeIcon(SensorType type) {
    switch (type) {
      case SensorType.soilMoisture:
        return '💧';
      case SensorType.temperature:
        return '🌡️';
      case SensorType.light:
        return '☀️';
      case SensorType.flow:
        return '💦';
      case SensorType.humidity:
        return '💨';
    }
  }
}
