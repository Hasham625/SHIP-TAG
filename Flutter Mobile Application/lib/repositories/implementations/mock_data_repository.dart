import '../data_repository.dart';
import '../../models/user.dart';
import '../../models/device.dart';
import '../../models/shipment.dart';
import '../../models/sensor_reading.dart';
import '../../models/alert.dart';
import '../../services/database_service.dart';
import '../../services/service_locator.dart';

class MockDataRepository implements DataRepository {
  late final DatabaseService _databaseService;

  MockDataRepository() {
    _databaseService = getIt<DatabaseService>();
  }

  @override
  Future<User> getUser(String userId) async {
    return User(
      id: userId,
      mobileNumber: '+1234567890',
      email: 'user@example.com',
      name: 'John Doe',
      profileImage: null,
    );
  }

  @override
  Future<User> updateProfile(User user) async {
    return user;
  }

  @override
  Future<List<Device>> getDevices() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final devices = [
      Device(
        deviceId: 'DEV001',
        batteryLevel: 85,
        status: DeviceStatus.online,
        packageName: 'Package Alpha',
        location: 'New York, NY',
      ),
      Device(
        deviceId: 'DEV002',
        batteryLevel: 45,
        status: DeviceStatus.online,
        packageName: 'Package Beta',
        location: 'Los Angeles, CA',
      ),
      Device(
        deviceId: 'DEV003',
        batteryLevel: 15,
        status: DeviceStatus.alert,
        packageName: 'Package Gamma',
        location: 'Chicago, IL',
      ),
    ];

    // Cache devices in background
    _databaseService.insertDevices(devices);

    return devices;
  }

  @override
  Future<Device> getDevice(String deviceId) async {
    final device = Device(
      deviceId: deviceId,
      batteryLevel: 80,
      status: DeviceStatus.online,
      packageName: 'Sample Package',
      location: 'Current Location',
    );

    _databaseService.insertDevice(device);

    return device;
  }

  @override
  Future<List<Shipment>> getShipments() async {
    return [
      Shipment(
        shipmentId: 'SHIP001',
        trackingNumber: 'TRK001',
        origin: 'New York',
        destination: 'Boston',
        currentLocation: Location(latitude: 40.7128, longitude: -74.0060),
        assignedDevice: Device(
          deviceId: 'DEV001',
          batteryLevel: 85,
          status: DeviceStatus.online,
          packageName: 'Package Alpha',
        ),
      ),
      Shipment(
        shipmentId: 'SHIP002',
        trackingNumber: 'TRK002',
        origin: 'Los Angeles',
        destination: 'San Diego',
        currentLocation: Location(latitude: 34.0522, longitude: -118.2437),
        assignedDevice: Device(
          deviceId: 'DEV002',
          batteryLevel: 45,
          status: DeviceStatus.online,
          packageName: 'Package Beta',
        ),
      ),
    ];
  }

  @override
  Future<Shipment> getShipment(String shipmentId) async {
    return Shipment(
      shipmentId: shipmentId,
      trackingNumber: 'TRK_$shipmentId',
      origin: 'Origin City',
      destination: 'Destination City',
      currentLocation: Location(latitude: 40.7128, longitude: -74.0060),
      assignedDevice: Device(
        deviceId: 'DEV001',
        batteryLevel: 80,
        status: DeviceStatus.online,
      ),
    );
  }

  @override
  Future<List<SensorReading>> getSensorReadings(String deviceId) async {
    // Cache-Aside Pattern:
    // 1. Return cached data immediately
    final cached = await _databaseService.getSensorReadings(deviceId);

    // 2. If cache is empty or we have data, still trigger a background refresh
    _refreshSensorReadings(deviceId);

    // Return cached data immediately (or empty list if no cache)
    if (cached.isNotEmpty) {
      return cached;
    }

    // If cache is empty, generate and return mock data
    return _generateMockSensorData(deviceId);
  }

  Future<void> _refreshSensorReadings(String deviceId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Get new mock data
    final newData = _generateMockSensorData(deviceId);

    // Update cache
    await _databaseService.insertSensorReadings(newData);

    // Clean old records (older than 7 days)
    await _databaseService.clearOldReadings(days: 7);
  }

  List<SensorReading> _generateMockSensorData(String deviceId) {
    return [
      SensorReading(
        temperature: 21.5,
        humidity: 60,
        tiltAngle: 2.1,
        shockDetected: false,
        tamperDetected: false,
        batteryLevel: 95,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      SensorReading(
        temperature: 22.1,
        humidity: 62,
        tiltAngle: 3.8,
        shockDetected: false,
        tamperDetected: false,
        batteryLevel: 92,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      ),
      SensorReading(
        temperature: 23.0,
        humidity: 65,
        tiltAngle: 5.0,
        shockDetected: true,
        tamperDetected: false,
        batteryLevel: 88,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SensorReading(
        temperature: 23.4,
        humidity: 67,
        tiltAngle: 4.2,
        shockDetected: false,
        tamperDetected: false,
        batteryLevel: 85,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      ),
      SensorReading(
        temperature: 24.1,
        humidity: 70,
        tiltAngle: 6.1,
        shockDetected: true,
        tamperDetected: false,
        batteryLevel: 82,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      SensorReading(
        temperature: 23.8,
        humidity: 69,
        tiltAngle: 5.5,
        shockDetected: false,
        tamperDetected: false,
        batteryLevel: 80,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      SensorReading(
        temperature: 23.5,
        humidity: 68,
        tiltAngle: 4.8,
        shockDetected: false,
        tamperDetected: false,
        batteryLevel: 78,
        timestamp: DateTime.now(),
      ),
    ];
  }

  @override
  Future<SensorReading> getLatestSensorReading(String deviceId) async {
    return SensorReading(
      temperature: 23.8,
      humidity: 70,
      tiltAngle: 5.5,
      shockDetected: false,
      tamperDetected: false,
      batteryLevel: 80,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<Alert>> getAlerts() async {
    return [
      Alert(
        alertId: 'ALR001',
        type: AlertType.temperature,
        severity: AlertSeverity.high,
        message: 'Temperature exceeded 25°C',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        deviceId: 'DEV001',
        isRead: false,
      ),
      Alert(
        alertId: 'ALR002',
        type: AlertType.battery,
        severity: AlertSeverity.medium,
        message: 'Battery level below 20%',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        deviceId: 'DEV003',
        isRead: false,
      ),
      Alert(
        alertId: 'ALR003',
        type: AlertType.shock,
        severity: AlertSeverity.high,
        message: 'Impact/Shock detected',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        deviceId: 'DEV002',
        isRead: true,
      ),
    ];
  }

  @override
  Future<List<Alert>> getAlertsForDevice(String deviceId) async {
    return [
      Alert(
        alertId: 'ALR001',
        type: AlertType.temperature,
        severity: AlertSeverity.high,
        message: 'Temperature exceeded 25°C',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        deviceId: deviceId,
        isRead: false,
      ),
    ];
  }

  @override
  Future<void> markAlertAsRead(String alertId) async {
    // Alert marked as read
  }

  @override
  Future<void> submitFeedback(String userId, String feedback) async {
    // Mock implementation - just simulate success
    if (feedback.isEmpty) {
      throw Exception('Feedback cannot be empty');
    }
  }

  @override
  Future<void> syncLocalCache() async {
    // Populate cache with mock data on first launch
    final devices = await getDevices();
    for (final device in devices) {
      await _databaseService.insertDevice(device);

      // Also cache sensor readings for each device
      final readings = _generateMockSensorData(device.deviceId);
      await _databaseService.insertSensorReadings(readings);
    }
  }

  @override
  Future<DateTime?> getLastCacheUpdate() async {
    return await _databaseService.getLastCacheUpdate();
  }
}


