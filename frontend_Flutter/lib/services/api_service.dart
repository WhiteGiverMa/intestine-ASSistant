// @module: api_service
// @type: service
// @layer: frontend
// @depends: [local_db_service, deepseek_service, http, models]
// @exports: [ApiService, ErrorHandler, AppError, ErrorType]
// @features:
//   - 记录: createRecord, getRecords, deleteRecord (重定向到本地)
//   - 统计: getStatsSummary, getStatsTrends (重定向到本地)
//   - AI: analyzeData, sendMessage, sendMessageStream (重定向到 DeepSeek)
//   - 设置: getUserSettings, updateUserSettings (重定向到本地)
// @brief: API服务层，已重构为本地优先
import 'dart:async';
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
  static const int _maxRecordsChars = 10000;
  static const int _maxRecordsCount = 150;

  static String _buildRecordsText(List<BowelRecord> records) {
    final buffer = StringBuffer();
    for (final record in records) {
      buffer.writeln(
        '- ${record.recordDate} ${record.recordTime ?? ""}: '
        '类型${record.stoolType ?? "?"}, '
        '时长${record.durationMinutes ?? "?"}分钟, '
        '感受${record.feeling ?? "?"}',
      );
    }
    return buffer.toString();
  }

  static Future<({String? message, String? actualStartDate})>
  _buildRecordsMessage({
    String? recordsStartDate,
    String? recordsEndDate,
  }) async {
    if (recordsStartDate == null || recordsEndDate == null) {
      return (message: null, actualStartDate: null);
    }

    final records = await LocalDbService.getRecords(
      startDate: recordsStartDate,
      endDate: recordsEndDate,
    );

    if (records.isEmpty) {
      return (message: null, actualStartDate: null);
    }

    records.sort((a, b) => b.recordDate.compareTo(a.recordDate));

    final String recordsText = _buildRecordsText(records);

    if (recordsText.length <= _maxRecordsChars &&
        records.length <= _maxRecordsCount) {
      return (
        message: '以下是用户的排便记录：\n$recordsText',
        actualStartDate: recordsStartDate,
      );
    }

    final List<BowelRecord> trimmedRecords = List.from(records);
    while (trimmedRecords.isNotEmpty &&
        (trimmedRecords.length > _maxRecordsCount ||
            _buildRecordsText(trimmedRecords).length > _maxRecordsChars)) {
      trimmedRecords.removeLast();
    }

    if (trimmedRecords.isEmpty) {
      return (message: null, actualStartDate: null);
    }

    final actualStartDate = trimmedRecords.last.recordDate;
    final trimmedText = _buildRecordsText(trimmedRecords);

    return (
      message: '以下是用户的排便记录：\n$trimmedText',
      actualStartDate: actualStartDate,
    );
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
    return LocalDbService.createRecord(
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
    return LocalDbService.getRecords(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  static Future<BowelRecord?> getRecordById(String recordId) async {
    return LocalDbService.getRecordById(recordId);
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
    return LocalDbService.getStatsSummary(
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
    return LocalDbService.getTrends(
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
    return LocalDbService.getDailyCounts(
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
    return DeepSeekService.analyzeRecords(
      analysisType: analysisType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<({ChatMessage message, String? actualStartDate})> sendMessage({
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

    final recordsResult = await _buildRecordsMessage(
      recordsStartDate: recordsStartDate,
      recordsEndDate: recordsEndDate,
    );

    final response = await DeepSeekService.chat(
      message: message,
      systemPrompt: systemPrompt,
      conversationId: conversationId,
      history: session?.messages,
      thinkingIntensity: thinkingIntensity,
      extraUserMessage: recordsResult.message,
    );

    if (conversationId == null) {
      final newSession = await LocalDbService.createChatSession(
        systemPrompt: systemPrompt,
        thinkingIntensity:
            thinkingIntensity != null
                ? ThinkingIntensity.fromApiValue(thinkingIntensity)
                : ThinkingIntensity.none,
      );
      conversationId = newSession.conversationId;
    }

    await LocalDbService.saveMessage(
      conversationId: conversationId,
      role: 'user',
      content: message,
    );

    if (recordsResult.message != null) {
      await LocalDbService.saveMessage(
        conversationId: conversationId,
        role: 'user',
        content: recordsResult.message!,
      );
    }

    final assistantMessage = await LocalDbService.saveMessage(
      conversationId: conversationId,
      role: 'assistant',
      content: response,
    );

    return (
      message: assistantMessage,
      actualStartDate: recordsResult.actualStartDate,
    );
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
    String actualConversationId;

    if (conversationId != null) {
      session = await LocalDbService.getChatSession(conversationId);
      actualConversationId = conversationId;
    } else {
      final newSession = await LocalDbService.createChatSession(
        systemPrompt: systemPrompt,
        thinkingIntensity:
            thinkingIntensity != null
                ? ThinkingIntensity.fromApiValue(thinkingIntensity)
                : ThinkingIntensity.none,
      );
      actualConversationId = newSession.conversationId;
    }

    final recordsResult = await _buildRecordsMessage(
      recordsStartDate: recordsStartDate,
      recordsEndDate: recordsEndDate,
    );

    await LocalDbService.saveMessage(
      conversationId: actualConversationId,
      role: 'user',
      content: message,
    );

    if (recordsResult.message != null) {
      await LocalDbService.saveMessage(
        conversationId: actualConversationId,
        role: 'user',
        content: recordsResult.message!,
      );
    }

    yield StreamChatChunk(
      conversationId: actualConversationId,
      done: false,
      actualStartDate: recordsResult.actualStartDate,
    );

    final responseStream = DeepSeekService.chatStream(
      message: message,
      systemPrompt: systemPrompt,
      history: session?.messages,
      thinkingIntensity: thinkingIntensity,
      extraUserMessage: recordsResult.message,
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
    return DeepSeekService.checkApiStatus();
  }

  static ChatRequestDetails? getLastChatRequestDetails() {
    return DeepSeekService.getLastRequestDetails();
  }

  static void clearLastChatRequestDetails() {
    DeepSeekService.clearLastRequestDetails();
  }

  static void cancelCurrentRequest() {
    DeepSeekService.cancelRequest();
  }

  static Future<List<ConversationSummary>> getConversations() async {
    return LocalDbService.getChatSessions();
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
