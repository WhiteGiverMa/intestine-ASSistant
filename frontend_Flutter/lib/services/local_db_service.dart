// @module: local_db_service
// @type: service
// @layer: frontend
// @depends: [database_service, models]
// @exports: [LocalDbService, LocalUser]
// @features:
//   - 用户管理: createLocalUser, getLocalUser
//   - 记录CRUD: createRecord, getRecords, updateRecord, deleteRecord
//   - 统计计算: getStatsSummary, getDailyCounts, getTrends
//   - 聊天管理: createChatSession, getChatSessions, saveMessage, getMessages
//   - 设置管理: getSetting, setSetting
// @brief: 本地数据库服务，封装所有数据访问操作
import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/models.dart';

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
      userId: json['id'] ?? json['user_id'],
      nickname: json['nickname'] ?? 'Local User',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'nickname': nickname, 'created_at': createdAt};
  }
}

class LocalDbService {
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${timestamp}_$random';
  }

  static String _getNowIso() {
    return DateTime.now().toIso8601String();
  }

  // ==================== 用户管理 ====================

  static Future<LocalUser> createLocalUser({String? nickname}) async {
    final db = await DatabaseService.database;
    final user = LocalUser(
      userId: _generateId(),
      nickname: nickname ?? 'Local User',
      createdAt: _getNowIso(),
    );

    await db.insert('local_users', {
      'id': user.userId,
      'nickname': user.nickname,
      'created_at': user.createdAt,
    });

    return user;
  }

  static Future<LocalUser?> getLocalUser() async {
    final db = await DatabaseService.database;
    final results = await db.query('local_users', limit: 1);
    if (results.isEmpty) return null;
    return LocalUser.fromJson(results.first);
  }

  static Future<void> updateLocalUserNickname(String nickname) async {
    final db = await DatabaseService.database;
    await db.update(
      'local_users',
      {'nickname': nickname},
    );
  }

  // ==================== 排便记录 CRUD ====================

  static Future<BowelRecord> createRecord({
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
    final db = await DatabaseService.database;
    final now = _getNowIso();
    final id = _generateId();

    await db.insert('bowel_records', {
      'id': id,
      'record_date': recordDate,
      'record_time': recordTime,
      'duration_minutes': durationMinutes,
      'stool_type': stoolType,
      'color': color,
      'smell_level': smellLevel,
      'feeling': feeling,
      'symptoms': symptoms != null ? jsonEncode(symptoms) : null,
      'notes': notes,
      'is_no_bowel': isNoBowel ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });

    return BowelRecord(
      recordId: id,
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
      createdAt: now,
    );
  }

  static Future<List<BowelRecord>> getRecords({
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await DatabaseService.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('record_date >= ?');
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      whereClauses.add('record_date <= ?');
      whereArgs.add(endDate);
    }

    final results = await db.query(
      'bowel_records',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'record_date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((row) => BowelRecord.fromJson(_mapRowToRecordJson(row))).toList();
  }

  static Future<BowelRecord?> getRecordById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'bowel_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return BowelRecord.fromJson(_mapRowToRecordJson(results.first));
  }

  static Future<void> updateRecord({
    required String recordId,
    String? recordDate,
    String? recordTime,
    int? durationMinutes,
    int? stoolType,
    String? color,
    int? smellLevel,
    String? feeling,
    List<String>? symptoms,
    String? notes,
    bool? isNoBowel,
  }) async {
    final db = await DatabaseService.database;
    final updates = <String, dynamic>{
      'updated_at': _getNowIso(),
    };

    if (recordDate != null) updates['record_date'] = recordDate;
    if (recordTime != null) updates['record_time'] = recordTime;
    if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
    if (stoolType != null) updates['stool_type'] = stoolType;
    if (color != null) updates['color'] = color;
    if (smellLevel != null) updates['smell_level'] = smellLevel;
    if (feeling != null) updates['feeling'] = feeling;
    if (symptoms != null) updates['symptoms'] = jsonEncode(symptoms);
    if (notes != null) updates['notes'] = notes;
    if (isNoBowel != null) updates['is_no_bowel'] = isNoBowel ? 1 : 0;

    await db.update(
      'bowel_records',
      updates,
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  static Future<void> deleteRecord(String recordId) async {
    final db = await DatabaseService.database;
    await db.delete(
      'bowel_records',
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  static Future<void> markNoBowel(String date) async {
    await createRecord(recordDate: date, isNoBowel: true);
  }

  static Future<void> unmarkNoBowel(String date) async {
    final db = await DatabaseService.database;
    await db.delete(
      'bowel_records',
      where: 'record_date = ? AND is_no_bowel = 1',
      whereArgs: [date],
    );
  }

  static Future<List<String>> getNoBowelDates({
    String? startDate,
    String? endDate,
  }) async {
    final db = await DatabaseService.database;
    final whereClauses = <String>['is_no_bowel = 1'];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('record_date >= ?');
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      whereClauses.add('record_date <= ?');
      whereArgs.add(endDate);
    }

    final results = await db.query(
      'bowel_records',
      columns: ['record_date'],
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );

    return results.map((row) => row['record_date'] as String).toList();
  }

  static Map<String, dynamic> _mapRowToRecordJson(Map<String, dynamic> row) {
    return {
      'record_id': row['id'],
      'record_date': row['record_date'],
      'record_time': row['record_time'],
      'duration_minutes': row['duration_minutes'],
      'stool_type': row['stool_type'],
      'color': row['color'],
      'smell_level': row['smell_level'],
      'feeling': row['feeling'],
      'symptoms': row['symptoms'],
      'notes': row['notes'],
      'is_no_bowel': row['is_no_bowel'] == 1,
      'created_at': row['created_at'],
    };
  }

  // ==================== 统计计算 ====================

  static Future<StatsSummary> getStatsSummary({
    String? startDate,
    String? endDate,
  }) async {
    final records = await getRecords(startDate: startDate, endDate: endDate);
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
        timeDistribution: TimeDistribution(morning: 0, afternoon: 0, evening: 0),
        healthScore: 0,
      );
    }

    final uniqueDates = nonNoBowelRecords.map((r) => r.recordDate).toSet();
    final totalRecords = nonNoBowelRecords.length;
    final recordedDays = uniqueDates.length;
    final avgFrequencyPerDay = totalRecords / recordedDays;

    final durations = nonNoBowelRecords
        .where((r) => r.durationMinutes != null)
        .map((r) => r.durationMinutes!)
        .toList();
    final avgDurationMinutes = durations.isNotEmpty
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

    if (stoolTypeDistribution.isNotEmpty) {
      final avgStoolType = stoolTypeDistribution.entries
              .map((e) => int.parse(e.key) * e.value)
              .reduce((a, b) => a + b) /
          stoolTypeDistribution.values.reduce((a, b) => a + b);
      if (avgStoolType >= 3 && avgStoolType <= 5) {
        healthScore += 10;
      } else if (avgStoolType < 2 || avgStoolType > 6) {
        healthScore -= 10;
      }
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

  static Future<DailyCounts> getDailyCounts({
    String? startDate,
    String? endDate,
  }) async {
    final db = await DatabaseService.database;
    final whereClauses = <String>['is_no_bowel = 0'];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('record_date >= ?');
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      whereClauses.add('record_date <= ?');
      whereArgs.add(endDate);
    }

    final results = await db.query(
      'bowel_records',
      columns: ['record_date', 'COUNT(*) as count'],
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      groupBy: 'record_date',
    );

    final dailyCounts = <String, int>{};
    for (final row in results) {
      dailyCounts[row['record_date'] as String] = row['count'] as int;
    }

    final noBowelDates = await getNoBowelDates(startDate: startDate, endDate: endDate);

    return DailyCounts(dailyCounts: dailyCounts, noBowelDates: noBowelDates);
  }

  static Future<StatsTrends> getTrends({
    String metric = 'frequency',
    String? startDate,
    String? endDate,
    String period = 'month',
  }) async {
    final db = await DatabaseService.database;

    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (startDate != null && endDate != null) {
      start = DateTime.parse(startDate);
      end = DateTime.parse(endDate);
    } else {
      switch (period) {
        case 'week':
          start = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          start = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          start = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          start = DateTime(now.year, now.month - 1, now.day);
      }
    }

    final results = await db.query(
      'bowel_records',
      columns: ['record_date', 'COUNT(*) as count'],
      where: 'record_date >= ? AND record_date <= ? AND is_no_bowel = 0',
      whereArgs: [start.toIso8601String().split('T')[0], end.toIso8601String().split('T')[0]],
      groupBy: 'record_date',
      orderBy: 'record_date ASC',
    );

    final Map<String, int> countsByDate = {};
    for (final row in results) {
      countsByDate[row['record_date'] as String] = row['count'] as int;
    }

    final trends = <TrendPoint>[];
    for (var d = start; d.isBefore(end) || d.isAtSameMomentAs(end); d = d.add(const Duration(days: 1))) {
      final dateStr = d.toIso8601String().split('T')[0];
      trends.add(TrendPoint(
        date: dateStr,
        value: countsByDate[dateStr] ?? 0,
        isRecorded: countsByDate.containsKey(dateStr),
      ));
    }

    return StatsTrends(metric: metric, trends: trends);
  }

  // ==================== 聊天会话管理 ====================

  static Future<ChatSession> createChatSession({
    String? title,
    String? systemPrompt,
    ThinkingIntensity thinkingIntensity = ThinkingIntensity.medium,
  }) async {
    final db = await DatabaseService.database;
    final now = _getNowIso();
    final id = _generateId();

    await db.insert('chat_sessions', {
      'id': id,
      'title': title,
      'system_prompt': systemPrompt,
      'thinking_intensity': thinkingIntensity.toApiValue(),
      'created_at': now,
      'updated_at': now,
    });

    return ChatSession(
      conversationId: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  static Future<List<ConversationSummary>> getChatSessions({
    int? limit,
    int? offset,
  }) async {
    final db = await DatabaseService.database;

    final sessions = await db.query(
      'chat_sessions',
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    final summaries = <ConversationSummary>[];
    for (final session in sessions) {
      final messageCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM chat_messages WHERE conversation_id = ?',
          [session['id']],
        ),
      ) ?? 0;

      summaries.add(ConversationSummary(
        conversationId: session['id'] as String,
        title: session['title'] as String?,
        createdAt: session['created_at'] as String,
        updatedAt: session['updated_at'] as String,
        messageCount: messageCount,
      ));
    }

    return summaries;
  }

  static Future<ChatSession?> getChatSession(String conversationId) async {
    final db = await DatabaseService.database;

    final sessions = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (sessions.isEmpty) return null;

    final session = sessions.first;
    final messages = await getMessages(conversationId);

    return ChatSession(
      conversationId: session['id'] as String,
      title: session['title'] as String?,
      createdAt: session['created_at'] as String,
      updatedAt: session['updated_at'] as String,
      messages: messages,
    );
  }

  static Future<void> updateChatSessionTitle(String conversationId, String title) async {
    final db = await DatabaseService.database;
    await db.update(
      'chat_sessions',
      {'title': title, 'updated_at': _getNowIso()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  static Future<void> deleteChatSession(String conversationId) async {
    final db = await DatabaseService.database;
    await db.delete('chat_messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [conversationId]);
  }

  // ==================== 聊天消息管理 ====================

  static Future<ChatMessage> saveMessage({
    required String conversationId,
    required String role,
    required String content,
    String? thinkingContent,
  }) async {
    final db = await DatabaseService.database;
    final now = _getNowIso();
    final id = _generateId();

    await db.insert('chat_messages', {
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'thinking_content': thinkingContent,
      'created_at': now,
    });

    await db.update(
      'chat_sessions',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return ChatMessage(
      messageId: id,
      conversationId: conversationId,
      role: role,
      content: content,
      thinkingContent: thinkingContent,
      createdAt: now,
    );
  }

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final db = await DatabaseService.database;

    final results = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return results.map((row) => ChatMessage(
      messageId: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      role: row['role'] as String,
      content: row['content'] as String,
      thinkingContent: row['thinking_content'] as String?,
      createdAt: row['created_at'] as String,
    )).toList();
  }

  // ==================== 设置管理 ====================

  static Future<String?> getSetting(String key) async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  static Future<void> setSetting(String key, String? value) async {
    final db = await DatabaseService.database;
    if (value == null) {
      await db.delete('settings', where: 'key = ?', whereArgs: [key]);
    } else {
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> deleteSetting(String key) async {
    final db = await DatabaseService.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  // ==================== 数据导出导入 ====================

  static Future<Map<String, dynamic>> exportAllData() async {
    final db = await DatabaseService.database;

    final users = await db.query('local_users');
    final records = await db.query('bowel_records');
    final sessions = await db.query('chat_sessions');
    final messages = await db.query('chat_messages');
    final settings = await db.query('settings');

    return {
      'version': 1,
      'exported_at': _getNowIso(),
      'users': users,
      'bowel_records': records,
      'chat_sessions': sessions,
      'chat_messages': messages,
      'settings': settings,
    };
  }

  static Future<void> importAllData(Map<String, dynamic> data, {bool overwrite = false}) async {
    final db = await DatabaseService.database;

    if (overwrite) {
      await DatabaseService.resetDatabase();
    }

    if (data['users'] != null) {
      for (final user in data['users'] as List) {
        await db.insert('local_users', Map<String, dynamic>.from(user),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    if (data['bowel_records'] != null) {
      for (final record in data['bowel_records'] as List) {
        await db.insert('bowel_records', Map<String, dynamic>.from(record),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    if (data['chat_sessions'] != null) {
      for (final session in data['chat_sessions'] as List) {
        await db.insert('chat_sessions', Map<String, dynamic>.from(session),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    if (data['chat_messages'] != null) {
      for (final message in data['chat_messages'] as List) {
        await db.insert('chat_messages', Map<String, dynamic>.from(message),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    if (data['settings'] != null) {
      for (final setting in data['settings'] as List) {
        await db.insert('settings', Map<String, dynamic>.from(setting),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }
}
