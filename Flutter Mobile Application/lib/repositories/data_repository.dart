import '../models/user.dart';
import '../models/device.dart';
import '../models/shipment.dart';
import '../models/sensor_reading.dart';
import '../models/alert.dart';

abstract class DataRepository {
  // User operations
  Future<User> getUser(String userId);
  Future<User> updateProfile(User user);

  // Device operations
  Future<List<Device>> getDevices();
  Future<Device> getDevice(String deviceId);

  // Shipment operations
  Future<List<Shipment>> getShipments();
  Future<Shipment> getShipment(String shipmentId);

  // Sensor operations
  Future<List<SensorReading>> getSensorReadings(String deviceId);
  Future<SensorReading> getLatestSensorReading(String deviceId);

  // Alert operations
  Future<List<Alert>> getAlerts();
  Future<List<Alert>> getAlertsForDevice(String deviceId);
  Future<void> markAlertAsRead(String alertId);

  // Support operations
  Future<void> submitFeedback(String userId, String feedback);

  // Cache operations
  Future<void> syncLocalCache();
  Future<DateTime?> getLastCacheUpdate();
}

