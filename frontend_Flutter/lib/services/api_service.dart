// @module: api_service
// @type: service
// @layer: frontend
// @depends: [local_db_service, deepseek_service, http, shared_preferences, models]
// @exports: [ApiService, ErrorHandler, AppError, ErrorType]
// @features:
//   - 认证: register, login, logout (保留签名，返回本地用户)
//   - 记录: createRecord, getRecords, deleteRecord (重定向到本地)
//   - 统计: getStatsSummary, getStatsTrends (重定向到本地)
//   - AI: analyzeData, sendMessage, sendMessageStream (重定向到 DeepSeek)
//   - 设置: getUserSettings, updateUserSettings (重定向到本地)
// @brief: API服务层，已重构为本地优先，保留接口签名兼容性
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'local_db_service.dart';
import 'deepseek_service.dart';

enum ErrorType { auth, network, server, unknown }

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final String originalError;

  AppError({
    required this.type,
    required this.message,
    this.details,
    required this.originalError,
  });
}

class ErrorHandler {
  static AppError handleError(dynamic error, {String context = ''}) {
    String message = '操作失败';
    ErrorType type = ErrorType.unknown;

    if (error is AppError) {
      return error;
    }

    if (error is Exception) {
      final errorStr = error.toString();
      if (errorStr.contains('网络') || errorStr.contains('connection')) {
        type = ErrorType.network;
        message = '网络连接失败';
      } else if (errorStr.contains('认证') ||
          errorStr.contains('token') ||
          errorStr.contains('登录')) {
        type = ErrorType.auth;
        message = '认证失败';
      } else if (errorStr.contains('API') || errorStr.contains('Key')) {
        type = ErrorType.server;
        message = 'API调用失败';
      }
    }

    return AppError(
      type: type,
      message: message,
      details: context.isNotEmpty ? context : null,
      originalError: error.toString(),
    );
  }
}

class ApiService {
  static const String _defaultBaseUrl = 'http://localhost:8001/api/v1';

  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (e) {
      throw Exception('网络连接失败: ${e.toString()}');
    }
  }

  static void _handleResponseError(
    http.Response response,
    String defaultMessage,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String errorMsg = defaultMessage;
    try {
      final error = jsonDecode(response.body);
      errorMsg = error['detail'] ?? error['message'] ?? errorMsg;
    } catch (_) {}

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('认证失败: $errorMsg');
    } else if (response.statusCode >= 500) {
      throw Exception('服务器错误: $errorMsg');
    } else {
      throw Exception(errorMsg);
    }
  }

  // ==================== 认证 (本地模式) ====================

  static Future<User> register(
    String email,
    String password, {
    String? nickname,
  }) async {
    final user = await LocalDbService.createLocalUser(
      nickname: nickname ?? 'Local User',
    );
    return User(
      userId: user.userId,
      email: email,
      nickname: nickname,
      token: 'local_token_${user.userId}',
    );
  }

  static Future<User> login(String email, String password) async {
    var user = await LocalDbService.getLocalUser();
    if (user == null) {
      user = await LocalDbService.createLocalUser();
    }
    return User(
      userId: user.userId,
      email: email,
      nickname: user.nickname,
      token: 'local_token_${user.userId}',
    );
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ==================== 排便记录 (本地) ====================

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
    return await LocalDbService.createRecord(
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
    );
  }

  static Future<List<BowelRecord>> getRecords({
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    return await LocalDbService.getRecords(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  static Future<BowelRecord?> getRecordById(String recordId) async {
    return await LocalDbService.getRecordById(recordId);
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
    await LocalDbService.updateRecord(
      recordId: recordId,
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
    );
  }

  static Future<void> deleteRecord(String recordId) async {
    await LocalDbService.deleteRecord(recordId);
  }

  static Future<void> markNoBowel(String date) async {
    await LocalDbService.markNoBowel(date);
  }

  static Future<void> unmarkNoBowel(String date) async {
    await LocalDbService.unmarkNoBowel(date);
  }

  // ==================== 统计 (本地) ====================

  static Future<StatsSummary> getStatsSummary({
    String? startDate,
    String? endDate,
  }) async {
    return await LocalDbService.getStatsSummary(
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<StatsTrends> getStatsTrends({
    String metric = 'frequency',
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    return await LocalDbService.getTrends(
      metric: metric,
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<DailyCounts> getDailyCounts({
    String? startDate,
    String? endDate,
  }) async {
    return await LocalDbService.getDailyCounts(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ==================== AI 分析 (DeepSeek) ====================

  static Future<AnalysisResult> analyzeData({
    String analysisType = 'weekly',
    String? startDate,
    String? endDate,
  }) async {
    return await DeepSeekService.analyzeRecords(
      analysisType: analysisType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<ChatMessage> sendMessage({
    required String message,
    String? conversationId,
    String? recordsStartDate,
    String? recordsEndDate,
    String? systemPrompt,
    String? thinkingIntensity,
  }) async {
    ChatSession? session;
    if (conversationId != null) {
      session = await LocalDbService.getChatSession(conversationId);
    }

    final response = await DeepSeekService.chat(
      message: message,
      systemPrompt: systemPrompt,
      conversationId: conversationId,
      history: session?.messages,
    );

    if (conversationId == null) {
      final newSession = await LocalDbService.createChatSession(
        systemPrompt: systemPrompt,
        thinkingIntensity:
            thinkingIntensity != null
                ? ThinkingIntensity.fromApiValue(thinkingIntensity)
                : ThinkingIntensity.medium,
      );
      conversationId = newSession.conversationId;
    }

    await LocalDbService.saveMessage(
      conversationId: conversationId!,
      role: 'user',
      content: message,
    );

    final assistantMessage = await LocalDbService.saveMessage(
      conversationId: conversationId,
      role: 'assistant',
      content: response,
    );

    return assistantMessage;
  }

  static Stream<StreamChatChunk> sendMessageStream({
    required String message,
    String? conversationId,
    String? recordsStartDate,
    String? recordsEndDate,
    String? systemPrompt,
    String? thinkingIntensity,
  }) async* {
    ChatSession? session;
    if (conversationId != null) {
      session = await LocalDbService.getChatSession(conversationId);
    }

    final userMessage = await LocalDbService.saveMessage(
      conversationId: conversationId ?? '',
      role: 'user',
      content: message,
    );

    String actualConversationId = conversationId ?? userMessage.conversationId;

    if (conversationId == null) {
      await LocalDbService.createChatSession(
        systemPrompt: systemPrompt,
        thinkingIntensity:
            thinkingIntensity != null
                ? ThinkingIntensity.fromApiValue(thinkingIntensity)
                : ThinkingIntensity.medium,
      );
    }

    final responseStream = DeepSeekService.chatStream(
      message: message,
      systemPrompt: systemPrompt,
      history: session?.messages,
      thinkingIntensity: thinkingIntensity,
    );

    String fullContent = '';
    String? fullReasoningContent;

    await for (final chunk in responseStream) {
      if (chunk.content != null) {
        fullContent += chunk.content!;
      }
      if (chunk.reasoningContent != null) {
        fullReasoningContent =
            (fullReasoningContent ?? '') + chunk.reasoningContent!;
      }
      yield chunk;
    }

    await LocalDbService.saveMessage(
      conversationId: actualConversationId,
      role: 'assistant',
      content: fullContent,
      thinkingContent: fullReasoningContent,
    );
  }

  static Future<ChatSession> getChatHistory({String? conversationId}) async {
    if (conversationId != null) {
      final session = await LocalDbService.getChatSession(conversationId);
      if (session != null) return session;
    }
    final sessions = await LocalDbService.getChatSessions(limit: 1);
    if (sessions.isNotEmpty) {
      return await LocalDbService.getChatSession(
            sessions.first.conversationId,
          ) ??
          ChatSession(conversationId: '', createdAt: '', updatedAt: '');
    }
    return ChatSession(conversationId: '', createdAt: '', updatedAt: '');
  }

  static Future<void> clearChatHistory({String? conversationId}) async {
    if (conversationId != null) {
      await LocalDbService.deleteChatSession(conversationId);
    } else {
      final sessions = await LocalDbService.getChatSessions();
      for (final session in sessions) {
        await LocalDbService.deleteChatSession(session.conversationId);
      }
    }
  }

  static Future<AiStatus> checkAiStatus() async {
    return await DeepSeekService.checkApiStatus();
  }

  static Future<List<ConversationSummary>> getConversations() async {
    return await LocalDbService.getChatSessions();
  }

  static Future<void> renameConversation({
    required String conversationId,
    required String title,
    String? systemPrompt,
    String? thinkingIntensity,
  }) async {
    await LocalDbService.updateChatSessionTitle(conversationId, title);
  }

  static Future<void> deleteConversation({
    required String conversationId,
  }) async {
    await LocalDbService.deleteChatSession(conversationId);
  }

  // ==================== 设置 (本地) ====================

  static Future<Map<String, dynamic>> getUserSettings() async {
    final apiKey = await DeepSeekService.getApiKey();
    final apiUrl = await DeepSeekService.getApiUrl();
    final model = await DeepSeekService.getModel();
    final systemPrompt = await DeepSeekService.getSystemPrompt();

    return {
      'ai_api_key': apiKey,
      'ai_api_url': apiUrl,
      'ai_model': model,
      'default_system_prompt': systemPrompt,
      'dev_mode': false,
      'ai_auto_title': false,
    };
  }

  static Future<void> updateUserSettings({
    bool? devMode,
    String? aiApiKey,
    String? aiApiUrl,
    String? aiModel,
    bool? aiAutoTitle,
    String? defaultSystemPrompt,
  }) async {
    if (aiApiKey != null) {
      await DeepSeekService.setApiKey(aiApiKey);
    }
    if (aiApiUrl != null) {
      await DeepSeekService.setApiUrl(aiApiUrl);
    }
    if (aiModel != null) {
      await DeepSeekService.setModel(aiModel);
    }
    if (defaultSystemPrompt != null) {
      await DeepSeekService.setSystemPrompt(defaultSystemPrompt);
    }
  }

  // ==================== 批量操作 (本地) ====================

  static Future<Map<String, dynamic>> markNoBowelBatch(
    String startDate,
    String endDate,
  ) async {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    var count = 0;

    for (
      var d = start;
      d.isBefore(end) || d.isAtSameMomentAs(end);
      d = d.add(const Duration(days: 1))
    ) {
      await LocalDbService.markNoBowel(d.toIso8601String().split('T')[0]);
      count++;
    }

    return {'count': count};
  }

  static Future<Map<String, dynamic>> deleteRecordsBatch(
    String startDate,
    String endDate,
  ) async {
    final records = await LocalDbService.getRecords(
      startDate: startDate,
      endDate: endDate,
    );

    for (final record in records) {
      await LocalDbService.deleteRecord(record.recordId);
    }

    return {'count': records.length};
  }

  static Future<Map<String, dynamic>> unmarkNoBowelBatch(
    String startDate,
    String endDate,
  ) async {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    var count = 0;

    for (
      var d = start;
      d.isBefore(end) || d.isAtSameMomentAs(end);
      d = d.add(const Duration(days: 1))
    ) {
      await LocalDbService.unmarkNoBowel(d.toIso8601String().split('T')[0]);
      count++;
    }

    return {'count': count};
  }
}
