// @module: auth_provider
// @type: provider
// @layer: frontend
// @depends: [local_db_service, database_service, provider, shared_preferences]
// @exports: [AuthProvider]
// @state:
//   - isInitialized: bool (Whether provider is initialized)
//   - localUser: LocalUser? (Local user info)
// @brief: Authentication state management for local-first mode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/local_db_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  LocalUser? _localUser;
  bool _initialized = false;

  LocalUser? get localUser => _localUser;
  bool get isInitialized => _initialized;
  bool get isLoggedIn => _localUser != null;

  String get displayName {
    if (_localUser != null) {
      return _localUser!.nickname;
    }
    return 'Guest';
  }

  String get userId {
    return _localUser?.userId ?? '';
  }

  Future<void> initialize() async {
    if (_initialized) return;

    await DatabaseService.database;

    _localUser = await LocalDbService.getLocalUser();

    _initialized = true;
    notifyListeners();
  }

  Future<void> ensureLocalUser() async {
    if (_localUser == null) {
      _localUser = await LocalDbService.createLocalUser();
      notifyListeners();
    }
  }

  Future<void> updateNickname(String nickname) async {
    if (_localUser != null) {
      await LocalDbService.updateLocalUserNickname(nickname);
      _localUser = await LocalDbService.getLocalUser();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _localUser = null;
    notifyListeners();
  }
}
