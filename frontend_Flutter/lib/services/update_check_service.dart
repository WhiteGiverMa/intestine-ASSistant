import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? errorMessage;

  UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.errorMessage,
  });

  factory UpdateCheckResult.noUpdate() {
    return UpdateCheckResult(hasUpdate: false);
  }

  factory UpdateCheckResult.withUpdate({
    required String latestVersion,
    String? downloadUrl,
    String? releaseNotes,
  }) {
    return UpdateCheckResult(
      hasUpdate: true,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes,
    );
  }

  factory UpdateCheckResult.error(String message) {
    return UpdateCheckResult(
      hasUpdate: false,
      errorMessage: message,
    );
  }
}

class UpdateCheckService {
  static final UpdateCheckService _instance = UpdateCheckService._internal();
  factory UpdateCheckService() => _instance;
  UpdateCheckService._internal();

  static const String _githubApiUrl =
      'https://api.github.com/repos/WhiteGiverMa/intestine-ASSistant/releases/latest';
  static const String _githubReleaseUrl =
      'https://github.com/WhiteGiverMa/intestine-ASSistant/releases/latest';

  UpdateCheckResult? _cachedResult;
  DateTime? _lastCheckTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  Future<UpdateCheckResult> checkForUpdate({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedResult != null &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _cacheDuration) {
      return _cachedResult!;
    }

    try {
      final currentVersion = await _getCurrentVersion();
      final response = await http
          .get(
            Uri.parse(_githubApiUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = _extractVersion(data['tag_name'] as String?);
        final releaseNotes = data['body'] as String?;
        final assets = data['assets'] as List<dynamic>?;

        String? downloadUrl;
        if (assets != null && assets.isNotEmpty) {
          final apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.apk'),
            orElse: () => assets.first,
          );
          downloadUrl = apkAsset['browser_download_url'] as String?;
        }

        final hasUpdate = _compareVersions(currentVersion, latestVersion) < 0;

        final result = hasUpdate
            ? UpdateCheckResult.withUpdate(
                latestVersion: latestVersion,
                downloadUrl: downloadUrl ?? _githubReleaseUrl,
                releaseNotes: releaseNotes,
              )
            : UpdateCheckResult.noUpdate();

        _cachedResult = result;
        _lastCheckTime = DateTime.now();
        return result;
      } else if (response.statusCode == 404) {
        return UpdateCheckResult.error('未找到发布版本');
      } else {
        return UpdateCheckResult.error('检查更新失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return UpdateCheckResult.error('检查更新失败: $e');
    }
  }

  Future<String> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.3.1';
    }
  }

  String _extractVersion(String? tagName) {
    if (tagName == null || tagName.isEmpty) {
      return '0.0.0';
    }
    return tagName.replaceFirst(RegExp(r'^v'), '');
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final p2 = i < parts2.length ? (parts2[i] ?? 0) : 0;
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    return 0;
  }

  void clearCache() {
    _cachedResult = null;
    _lastCheckTime = null;
  }
}
