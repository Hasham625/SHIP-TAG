import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/data_repository.dart';
import '../services/service_locator.dart';

class UserProvider extends ChangeNotifier {
  final DataRepository _dataRepository = getIt<DataRepository>();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _dataRepository.getUser(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _dataRepository.updateProfile(user);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
