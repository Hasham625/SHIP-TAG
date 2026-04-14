import '../data_repository.dart';
import '../../models/user.dart';
import '../../models/device.dart';
import '../../models/shipment.dart';
import '../../models/sensor_reading.dart';
import '../../models/alert.dart';

class DjangoDataRepository implements DataRepository {
  @override
  Future<User> getUser(String userId) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<User> updateProfile(User user) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<List<Device>> getDevices() async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<Device> getDevice(String deviceId) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<List<Shipment>> getShipments() async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<Shipment> getShipment(String shipmentId) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<List<SensorReading>> getSensorReadings(String deviceId) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<SensorReading> getLatestSensorReading(String deviceId) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<List<Alert>> getAlerts() async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<List<Alert>> getAlertsForDevice(String deviceId) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> markAlertAsRead(String alertId) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> submitFeedback(String userId, String feedback) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> syncLocalCache() async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<DateTime?> getLastCacheUpdate() async {
    throw UnimplementedError('Django backend not yet implemented');
  }
}
