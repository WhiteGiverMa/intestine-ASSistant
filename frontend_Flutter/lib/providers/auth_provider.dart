// @module: auth_provider
// @type: provider
// @layer: frontend
// @depends: [local_storage_service, api_service, provider, shared_preferences]
// @exports: [AuthProvider]
// @state:
//   - isLoggedIn: bool (Whether user is logged in)
//   - isOfflineMode: bool (Whether in offline mode)
//   - user: User? (Current logged in user)
//   - localUser: LocalUser? (Local user for offline mode)
//   - unsyncedCount: int (Number of unsynced records)
// @brief: Authentication state management, supports online/offline mode switching
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isOfflineMode = false;
  User? _user;
  LocalUser? _localUser;
  int _unsyncedCount = 0;
  bool _initialized = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isOfflineMode => _isOfflineMode;
  User? get user => _user;
  LocalUser? get localUser => _localUser;
  int get unsyncedCount => _unsyncedCount;
  bool get isInitialized => _initialized;

  String get displayName {
    if (_isLoggedIn && _user != null) {
      return _user!.nickname ?? _user!.email;
    }
    if (_isOfflineMode && _localUser != null) {
      return _localUser!.nickname;
    }
    return 'Guest';
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      try {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _user = User.fromJson(userData);
        _isLoggedIn = true;
      } catch (e) {
        debugPrint('Failed to parse user data: $e');
      }
    }

    _isOfflineMode = await LocalStorageService.isOfflineMode();
    _localUser = await LocalStorageService.getLocalUser();
    _unsyncedCount = await LocalStorageService.getUnsyncedCount();

    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final user = await ApiService.login(email, password);
    _user = user;
    _isLoggedIn = true;
    _isOfflineMode = false;
    await LocalStorageService.disableOfflineMode();
    notifyListeners();
  }

  Future<void> register(String email, String password, {String? nickname}) async {
    final user = await ApiService.register(email, password, nickname: nickname);
    _user = user;
    _isLoggedIn = true;
    _isOfflineMode = false;
    await LocalStorageService.disableOfflineMode();
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> enableOfflineMode() async {
    await LocalStorageService.enableOfflineMode();
    _isOfflineMode = true;
    _localUser = await LocalStorageService.getLocalUser();
    notifyListeners();
  }

  Future<void> disableOfflineMode() async {
    await LocalStorageService.disableOfflineMode();
    _isOfflineMode = false;
    notifyListeners();
  }

  Future<void> switchToOnlineMode() async {
    if (!_isLoggedIn) {
      throw Exception('Please login first');
    }
    await disableOfflineMode();
  }

  Future<void> switchToOfflineMode() async {
    await enableOfflineMode();
  }

  Future<Map<String, dynamic>> syncLocalData({
    Function(String)? onProgress,
  }) async {
    if (!_isLoggedIn) {
      throw Exception('Please login first');
    }

    final result = await LocalStorageService.migrateLocalDataToServer(
      onProgress: onProgress,
    );

    _unsyncedCount = await LocalStorageService.getUnsyncedCount();
    notifyListeners();

    return result;
  }

  Future<void> refreshUnsyncedCount() async {
    _unsyncedCount = await LocalStorageService.getUnsyncedCount();
    notifyListeners();
  }

  Future<void> ensureLocalUser() async {
    _localUser = await LocalStorageService.getLocalUser();
    if (_localUser == null) {
      _localUser = await LocalStorageService.createLocalUser();
    }
    notifyListeners();
  }
}
