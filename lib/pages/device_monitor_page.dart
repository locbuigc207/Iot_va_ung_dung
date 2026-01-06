import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class DeviceMonitorPage extends StatefulWidget {
  const DeviceMonitorPage({Key? key}) : super(key: key);

  @override
  State<DeviceMonitorPage> createState() => _DeviceMonitorPageState();
}

class _DeviceMonitorPageState extends State<DeviceMonitorPage> {
  final DatabaseReference _devicesRef =
      FirebaseDatabase.instance.ref('devices');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Monitor'),
        backgroundColor: const Color(0xFF00C1C4),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _devicesRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No devices registered yet'),
            );
          }

          final devices = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final entry = devices.entries.elementAt(index);
              final deviceId = entry.key;
              final deviceData = Map<dynamic, dynamic>.from(entry.value);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    deviceData['name'] ?? 'Unknown Device',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ID: $deviceId'),
                  leading: Icon(
                    deviceData['status'] == true
                        ? Icons.power
                        : Icons.power_off,
                    color: deviceData['status'] == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Zone ID', deviceData['zoneId']),
                          _buildDetailRow('Type', deviceData['type']),
                          _buildDetailRow('Status', '${deviceData['status']}'),
                          _buildDetailRow('Current Duration',
                              '${deviceData['currentDuration'] ?? 0}s'),
                          _buildDetailRow('Flow Rate',
                              '${deviceData['flowRate'] ?? 0} L/min'),
                          _buildDetailRow(
                              'Device MAC', deviceData['deviceMAC'] ?? 'N/A'),
                          _buildDetailRow(
                              'Unique ID', deviceData['uniqueId'] ?? 'N/A'),
                          _buildDetailRow('Last Updated',
                              _formatTimestamp(deviceData['lastUpdated'])),

                          const Divider(height: 24),

                          // Test Controls
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _testDevice(deviceId, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Test ON (2min)'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _testDevice(deviceId, false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Test OFF'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month} ${date.hour}:${date.minute}:${date.second}';
    } catch (e) {
      return 'Invalid';
    }
  }

  Future<void> _testDevice(String deviceId, bool turnOn) async {
    try {
      await FirebaseService().controlDevice(
        deviceId,
        turnOn,
        duration: turnOn ? 2 : null, // 2 minutes
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Command sent: ${turnOn ? "ON" : "OFF"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
