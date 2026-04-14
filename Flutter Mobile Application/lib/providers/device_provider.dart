import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';
import '../repositories/data_repository.dart';
import '../services/service_locator.dart';

class DeviceProvider extends ChangeNotifier {
  final DataRepository _dataRepository = getIt<DataRepository>();

  List<Device> _devices = [];
  Device? _selectedDevice;
  List<SensorReading> _sensorReadings = [];
  DateTime? _lastCacheUpdate;
  bool _isLoading = false;
  String? _error;

  List<Device> get devices => _devices;
  Device? get selectedDevice => _selectedDevice;
  List<SensorReading> get sensorReadings => _sensorReadings;
  DateTime? get lastCacheUpdate => _lastCacheUpdate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _devices = await _dataRepository.getDevices();
      _lastCacheUpdate = await _dataRepository.getLastCacheUpdate();
      if (_devices.isNotEmpty) {
        _selectedDevice = _devices.first;
        await loadSensorReadings(_selectedDevice!.deviceId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects a device by ID and immediately refreshes sensor data.
  /// This keeps DeviceProvider synchronized with ShipmentProvider's selectedDeviceId.
  Future<void> selectDevice(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedDevice = await _dataRepository.getDevice(deviceId);
      await loadSensorReadings(deviceId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSensorReadings(String deviceId) async {
    try {
      _sensorReadings = await _dataRepository.getSensorReadings(deviceId);
      _lastCacheUpdate = await _dataRepository.getLastCacheUpdate();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
