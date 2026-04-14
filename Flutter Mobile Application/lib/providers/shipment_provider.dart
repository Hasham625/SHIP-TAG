import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../repositories/data_repository.dart';
import '../services/service_locator.dart';

class ShipmentProvider extends ChangeNotifier {
  final DataRepository _dataRepository = getIt<DataRepository>();

  List<Shipment> _shipments = [];
  Shipment? _selectedShipment;
  String? _selectedDeviceId; // Global selected device ID
  bool _isLoading = false;
  String? _error;

  List<Shipment> get shipments => _shipments;
  Shipment? get selectedShipment => _selectedShipment;
  String? get selectedDeviceId => _selectedDeviceId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadShipments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _shipments = await _dataRepository.getShipments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectShipment(String shipmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedShipment = await _dataRepository.getShipment(shipmentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the global selected device ID. This is the single source of truth
  /// for device selection across all screens (Dashboard, Detail, etc.)
  void selectDevice(String deviceId) {
    _selectedDeviceId = deviceId;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
