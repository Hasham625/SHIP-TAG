import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../repositories/data_repository.dart';
import '../services/service_locator.dart';

class AlertProvider extends ChangeNotifier {
  final DataRepository _dataRepository = getIt<DataRepository>();

  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;
  bool _hasUnreadAlerts = false; // Persistent state for navigation badge

  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnreadAlerts => _hasUnreadAlerts;

  int get unreadCount => _alerts.where((alert) => !alert.isRead).length;

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _dataRepository.getAlerts();
      // Update persistent unread status
      _hasUnreadAlerts = _alerts.any((alert) => !alert.isRead);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _dataRepository.markAlertAsRead(alertId);
      final index = _alerts.indexWhere((alert) => alert.alertId == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
        // Update persistent unread status after reading an alert
        _hasUnreadAlerts = _alerts.any((alert) => !alert.isRead);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAlertsAsRead() async {
    try {
      for (final alert in _alerts.where((a) => !a.isRead).toList()) {
        await _dataRepository.markAlertAsRead(alert.alertId);
        final index = _alerts.indexWhere((a) => a.alertId == alert.alertId);
        if (index != -1) {
          _alerts[index] = _alerts[index].copyWith(isRead: true);
        }
      }
      // Update persistent state when all alerts are read
      _hasUnreadAlerts = false;
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
