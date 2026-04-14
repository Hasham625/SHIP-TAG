import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/shipment_provider.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<DeviceProvider>().loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Icon(Icons.devices, size: 28, color: Colors.white),
          backgroundColor: Colors.blue,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Consumer<DeviceProvider>(
          builder: (context, deviceProvider, _) {
            if (deviceProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (deviceProvider.error != null) {
              return Center(
                child: Text(
                  'Error: ${deviceProvider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (deviceProvider.devices.isEmpty) {
              return const Center(
                child: Text('No devices registered'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deviceProvider.devices.length,
              itemBuilder: (context, index) {
                final device = deviceProvider.devices[index];
                final isSelected = deviceProvider.selectedDevice?.deviceId ==
                    device.deviceId;

                return GestureDetector(
                  onTap: () {
                    final navigator = Navigator.of(context);
                    final shipmentProvider = context.read<ShipmentProvider>();
                    final deviceProvider = context.read<DeviceProvider>();

                    // Select device in shipment provider (global state)
                    shipmentProvider.selectDevice(device.deviceId);

                    // Select device in device provider (loads sensor data)
                    deviceProvider.selectDevice(device.deviceId).then((_) {
                      if (!mounted) return;
                      navigator.pop();
                      navigator.pushNamed('/home');
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        device.packageName ?? 'Unknown Package',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Device ID: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                device.deviceId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                device.location ?? 'Unknown location',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusBadge(device.status),
                          const SizedBox(height: 8),
                          _buildBatteryIcon(device.batteryLevel),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status) {
    Color color;
    String text;

    switch (status.toString()) {
      case 'DeviceStatus.online':
        color = Colors.green;
        text = 'Online';
        break;
      case 'DeviceStatus.offline':
        color = Colors.grey;
        text = 'Offline';
        break;
      case 'DeviceStatus.alert':
        color = Colors.red;
        text = 'Alert';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBatteryIcon(int batteryLevel) {
    Color color;
    IconData icon;

    if (batteryLevel > 50) {
      color = Colors.green;
      icon = Icons.battery_full;
    } else if (batteryLevel > 20) {
      color = Colors.orange;
      icon = Icons.battery_std;
    } else {
      color = Colors.red;
      icon = Icons.battery_alert;
    }

    return Tooltip(
      message: '$batteryLevel%',
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

