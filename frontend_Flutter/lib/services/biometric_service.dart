// @module: biometric_service
// @type: service
// @layer: frontend
// @depends: [local_auth, flutter_secure_storage, api_service]
// @exports: [BiometricService]
// @features:
//   - isBiometricAvailable: 检查设备是否支持生物识别
//   - isBiometricEnabled: 检查是否已启用生物识别
//   - enableBiometric: 启用生物识别并存储凭证
//   - disableBiometric: 禁用生物识别
//   - authenticate: 生物识别验证
//   - getStoredCredentials: 获取存储的凭证
// @brief: 生物识别登录服务，使用指纹/面容识别进行快速登录
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyStoredEmail = 'biometric_email';
  static const String _keyStoredPassword = 'biometric_password';

  static Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _keyBiometricEnabled);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  static Future<void> enableBiometric(String email, String password) async {
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
    await _storage.write(key: _keyStoredEmail, value: email);
    await _storage.write(key: _keyStoredPassword, value: password);
  }

  static Future<void> disableBiometric() async {
    await _storage.delete(key: _keyBiometricEnabled);
    await _storage.delete(key: _keyStoredEmail);
    await _storage.delete(key: _keyStoredPassword);
  }

  static Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: '请使用生物识别验证以快速登录',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  static Future<Map<String, String>?> getStoredCredentials() async {
    try {
      final enabled = await isBiometricEnabled();
      if (!enabled) {
        return null;
      }

      final email = await _storage.read(key: _keyStoredEmail);
      final password = await _storage.read(key: _keyStoredPassword);

      if (email == null || password == null) {
        return null;
      }

      return {'email': email, 'password': password};
    } catch (e) {
      return null;
    }
  }

  static Future<bool> loginWithBiometric() async {
    try {
      final authenticated = await authenticate();
      if (!authenticated) {
        return false;
      }

      final credentials = await getStoredCredentials();
      if (credentials == null) {
        return false;
      }

      await ApiService.login(credentials['email']!, credentials['password']!);

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }
}
