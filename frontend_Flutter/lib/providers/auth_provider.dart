// @module: auth_provider
// @type: provider
// @layer: frontend
// @depends: [local_db_service, database_service, provider]
// @exports: [AuthProvider]
// @state:
//   - isInitialized: bool (Whether provider is initialized)
//   - localUser: LocalUser? (Local user info)
// @brief: Local user state management for local-first mode
import 'package:flutter/material.dart';
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

    _localUser ??= await LocalDbService.createLocalUser();

    _initialized = true;
    notifyListeners();
  }

  Future<void> updateNickname(String nickname) async {
    if (_localUser != null) {
      await LocalDbService.updateLocalUserNickname(nickname);
      _localUser = await LocalDbService.getLocalUser();
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    _localUser = await LocalDbService.getLocalUser();
    notifyListeners();
  }
}
