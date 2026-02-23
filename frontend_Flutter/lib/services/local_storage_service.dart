// @module: local_storage_service
// @type: service
// @layer: frontend
// @depends: [shared_preferences, models]
// @exports: [LocalStorageService, LocalUser, LocalRecord]
// @features:
//   - createLocalUser: Create local user with UUID
//   - getLocalUser: Get local user info
//   - isOfflineMode: Check if offline mode
//   - saveRecordLocally: Save record locally
//   - getLocalRecords: Get local records
//   - syncToServer: Sync data to server
//   - migrateLocalDataToServer: Migrate local data to server
// @brief: Local storage service for offline mode support
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class LocalUser {
  final String userId;
  final String nickname;
  final String createdAt;

  LocalUser({
    required this.userId,
    required this.nickname,
    required this.createdAt,
  });

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      userId: json['user_id'],
      nickname: json['nickname'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'nickname': nickname, 'created_at': createdAt};
  }
}

class LocalRecord {
  final String localId;
  final String recordDate;
  final String? recordTime;
  final int? durationMinutes;
  final int? stoolType;
  final String? color;
  final int? smellLevel;
  final String? feeling;
  final List<String>? symptoms;
  final String? notes;
  final bool isNoBowel;
  final String createdAt;
  final bool synced;

  LocalRecord({
    required this.localId,
    required this.recordDate,
    this.recordTime,
    this.durationMinutes,
    this.stoolType,
    this.color,
    this.smellLevel,
    this.feeling,
    this.symptoms,
    this.notes,
    this.isNoBowel = false,
    required this.createdAt,
    this.synced = false,
  });

  factory LocalRecord.fromJson(Map<String, dynamic> json) {
    return LocalRecord(
      localId: json['local_id'],
      recordDate: json['record_date'],
      recordTime: json['record_time'],
      durationMinutes: json['duration_minutes'],
      stoolType: json['stool_type'],
      color: json['color'],
      smellLevel: json['smell_level'],
      feeling: json['feeling'],
      symptoms:
          json['symptoms'] != null ? List<String>.from(json['symptoms']) : null,
      notes: json['notes'],
      isNoBowel: json['is_no_bowel'] ?? false,
      createdAt: json['created_at'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'record_date': recordDate,
      'record_time': recordTime,
      'duration_minutes': durationMinutes,
      'stool_type': stoolType,
      'color': color,
      'smell_level': smellLevel,
      'feeling': feeling,
      'symptoms': symptoms,
      'notes': notes,
      'is_no_bowel': isNoBowel,
      'created_at': createdAt,
      'synced': synced,
    };
  }

  BowelRecord toBowelRecord() {
    return BowelRecord(
      recordId: localId,
      recordDate: recordDate,
      recordTime: recordTime,
      durationMinutes: durationMinutes,
      stoolType: stoolType,
      color: color,
      smellLevel: smellLevel,
      feeling: feeling,
      symptoms: symptoms != null ? jsonEncode(symptoms) : null,
      notes: notes,
      isNoBowel: isNoBowel,
      createdAt: createdAt,
    );
  }
}

class LocalStorageService {
  static const String _localUserKey = 'local_user';
  static const String _localRecordsKey = 'local_records';
  static const String _offlineModeKey = 'offline_mode';
  static const String _noBowelDatesKey = 'local_no_bowel_dates';

  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'local_$timestamp$random';
  }

  static Future<LocalUser> createLocalUser({String? nickname}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = LocalUser(
      userId: _generateId(),
      nickname: nickname ?? 'Local User',
      createdAt: DateTime.now().toIso8601String(),
    );
    await prefs.setString(_localUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(_offlineModeKey, true);
    return user;
  }

  static Future<LocalUser?> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_localUserKey);
    if (userJson == null) return null;
    return LocalUser.fromJson(jsonDecode(userJson));
  }

  static Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }

  static Future<void> setOfflineMode(bool offline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, offline);
  }

  static Future<void> enableOfflineMode() async {
    final user = await getLocalUser();
    if (user == null) {
      await createLocalUser();
    }
    await setOfflineMode(true);
  }

  static Future<void> disableOfflineMode() async {
    await setOfflineMode(false);
  }

  static Future<LocalRecord> saveRecordLocally({
    required String recordDate,
    String? recordTime,
    int? durationMinutes,
    int? stoolType,
    String? color,
    int? smellLevel,
    String? feeling,
    List<String>? symptoms,
    String? notes,
    bool isNoBowel = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_localRecordsKey);
    final List<dynamic> records =
        recordsJson != null ? jsonDecode(recordsJson) : [];

    final record = LocalRecord(
      localId: _generateId(),
      recordDate: recordDate,
      recordTime: recordTime,
      durationMinutes: durationMinutes,
      stoolType: stoolType,
      color: color,
      smellLevel: smellLevel,
      feeling: feeling,
      symptoms: symptoms,
      notes: notes,
      isNoBowel: isNoBowel,
      createdAt: DateTime.now().toIso8601String(),
      synced: false,
    );

    records.add(record.toJson());
    await prefs.setString(_localRecordsKey, jsonEncode(records));
    return record;
  }

  static Future<List<LocalRecord>> getLocalRecords({
    String? startDate,
    String? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_localRecordsKey);
    if (recordsJson == null) return [];

    final List<dynamic> records = jsonDecode(recordsJson);
    var localRecords = records.map((e) => LocalRecord.fromJson(e)).toList();

    if (startDate != null) {
      localRecords =
          localRecords
              .where((r) => r.recordDate.compareTo(startDate) >= 0)
              .toList();
    }
    if (endDate != null) {
      localRecords =
          localRecords
              .where((r) => r.recordDate.compareTo(endDate) <= 0)
              .toList();
    }

    localRecords.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    return localRecords;
  }

  static Future<void> deleteLocalRecord(String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_localRecordsKey);
    if (recordsJson == null) return;

    final List<dynamic> records = jsonDecode(recordsJson);
    records.removeWhere((r) => r['local_id'] == localId);
    await prefs.setString(_localRecordsKey, jsonEncode(records));
  }

  static Future<void> markNoBowelLocally(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final datesJson = prefs.getString(_noBowelDatesKey);
    final List<dynamic> dates = datesJson != null ? jsonDecode(datesJson) : [];

    if (!dates.contains(date)) {
      dates.add(date);
      await prefs.setString(_noBowelDatesKey, jsonEncode(dates));
    }

    await saveRecordLocally(recordDate: date, isNoBowel: true);
  }

  static Future<void> unmarkNoBowelLocally(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final datesJson = prefs.getString(_noBowelDatesKey);
    if (datesJson == null) return;

    final List<dynamic> dates = jsonDecode(datesJson);
    dates.remove(date);
    await prefs.setString(_noBowelDatesKey, jsonEncode(dates));

    final records = await getLocalRecords(startDate: date, endDate: date);
    for (final record in records) {
      if (record.isNoBowel) {
        await deleteLocalRecord(record.localId);
      }
    }
  }

  static Future<List<String>> getNoBowelDates() async {
    final prefs = await SharedPreferences.getInstance();
    final datesJson = prefs.getString(_noBowelDatesKey);
    if (datesJson == null) return [];
    return List<String>.from(jsonDecode(datesJson));
  }

  static Future<Map<String, dynamic>> migrateLocalDataToServer({
    bool preferLocal = true,
    Function(String)? onProgress,
  }) async {
    final localRecords = await getLocalRecords();
    final unsyncedRecords = localRecords.where((r) => !r.synced).toList();

    final result = {
      'total': unsyncedRecords.length,
      'success': 0,
      'failed': 0,
      'errors': <String>[],
    };

    for (final record in unsyncedRecords) {
      try {
        onProgress?.call('Syncing record ${record.recordDate}...');

        if (record.isNoBowel) {
          await ApiService.markNoBowel(record.recordDate);
        } else {
          if (record.recordTime == null) {
            throw Exception('Missing record time');
          }
          await ApiService.createRecord(
            recordDate: record.recordDate,
            recordTime: record.recordTime!,
            durationMinutes: record.durationMinutes,
            stoolType: record.stoolType,
            color: record.color,
            smellLevel: record.smellLevel,
            feeling: record.feeling,
            symptoms: record.symptoms,
            notes: record.notes,
          );
        }

        await _markRecordSynced(record.localId);
        result['success'] = (result['success'] as int) + 1;
      } catch (e) {
        result['failed'] = (result['failed'] as int) + 1;
        (result['errors'] as List<String>).add(
          'Record ${record.recordDate}: ${e.toString()}',
        );
      }
    }

    return result;
  }

  static Future<void> _markRecordSynced(String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_localRecordsKey);
    if (recordsJson == null) return;

    final List<dynamic> records = jsonDecode(recordsJson);
    for (int i = 0; i < records.length; i++) {
      if (records[i]['local_id'] == localId) {
        records[i]['synced'] = true;
        break;
      }
    }
    await prefs.setString(_localRecordsKey, jsonEncode(records));
  }

  static Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localRecordsKey);
    await prefs.remove(_noBowelDatesKey);
  }

  static Future<void> clearAllLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localUserKey);
    await prefs.remove(_localRecordsKey);
    await prefs.remove(_offlineModeKey);
    await prefs.remove(_noBowelDatesKey);
  }

  static Future<int> getUnsyncedCount() async {
    final records = await getLocalRecords();
    return records.where((r) => !r.synced).length;
  }

  static Future<DailyCounts> getLocalDailyCounts({
    String? startDate,
    String? endDate,
  }) async {
    final records = await getLocalRecords(
      startDate: startDate,
      endDate: endDate,
    );
    final noBowelDates = await getNoBowelDates();

    final Map<String, int> dailyCounts = {};
    for (final record in records) {
      if (!record.isNoBowel) {
        dailyCounts[record.recordDate] =
            (dailyCounts[record.recordDate] ?? 0) + 1;
      }
    }

    return DailyCounts(dailyCounts: dailyCounts, noBowelDates: noBowelDates);
  }

  static Future<StatsSummary> getLocalStatsSummary({
    String? startDate,
    String? endDate,
  }) async {
    final records = await getLocalRecords(
      startDate: startDate,
      endDate: endDate,
    );
    final nonNoBowelRecords = records.where((r) => !r.isNoBowel).toList();

    if (nonNoBowelRecords.isEmpty) {
      return StatsSummary(
        totalRecords: 0,
        days: 0,
        recordedDays: 0,
        coverageRate: 0,
        avgFrequencyPerDay: 0,
        avgDurationMinutes: 0,
        stoolTypeDistribution: {},
        timeDistribution: TimeDistribution(
          morning: 0,
          afternoon: 0,
          evening: 0,
        ),
        healthScore: 0,
      );
    }

    final uniqueDates = nonNoBowelRecords.map((r) => r.recordDate).toSet();
    final totalRecords = nonNoBowelRecords.length;
    final recordedDays = uniqueDates.length;

    final avgFrequencyPerDay = totalRecords / recordedDays;

    final durations =
        nonNoBowelRecords
            .where((r) => r.durationMinutes != null)
            .map((r) => r.durationMinutes!)
            .toList();
    final avgDurationMinutes =
        durations.isNotEmpty
            ? durations.reduce((a, b) => a + b) / durations.length
            : 0.0;

    final Map<String, int> stoolTypeDistribution = {};
    for (final record in nonNoBowelRecords) {
      if (record.stoolType != null) {
        final key = record.stoolType.toString();
        stoolTypeDistribution[key] = (stoolTypeDistribution[key] ?? 0) + 1;
      }
    }

    int morning = 0, afternoon = 0, evening = 0;
    for (final record in nonNoBowelRecords) {
      if (record.recordTime != null) {
        try {
          final hour = int.parse(record.recordTime!.split(':')[0]);
          if (hour >= 6 && hour < 12) {
            morning++;
          } else if (hour >= 12 && hour < 18) {
            afternoon++;
          } else {
            evening++;
          }
        } catch (_) {}
      }
    }

    int healthScore = 70;
    if (avgFrequencyPerDay >= 1 && avgFrequencyPerDay <= 2) {
      healthScore += 10;
    } else if (avgFrequencyPerDay > 3) {
      healthScore -= 10;
    }

    final avgStoolType =
        stoolTypeDistribution.entries.isEmpty
            ? 0.0
            : stoolTypeDistribution.entries
                    .map((e) => int.parse(e.key) * e.value)
                    .reduce((a, b) => a + b) /
                stoolTypeDistribution.values.reduce((a, b) => a + b);
    if (avgStoolType >= 3 && avgStoolType <= 5) {
      healthScore += 10;
    } else if (avgStoolType < 2 || avgStoolType > 6) {
      healthScore -= 10;
    }

    healthScore = healthScore.clamp(0, 100);

    return StatsSummary(
      totalRecords: totalRecords,
      days: recordedDays,
      recordedDays: recordedDays,
      coverageRate: 1.0,
      avgFrequencyPerDay: avgFrequencyPerDay,
      avgDurationMinutes: avgDurationMinutes,
      stoolTypeDistribution: stoolTypeDistribution,
      timeDistribution: TimeDistribution(
        morning: morning,
        afternoon: afternoon,
        evening: evening,
      ),
      healthScore: healthScore,
    );
  }
}
