// @module: api_service
// @type: service
// @layer: frontend
// @depends: [models, http, shared_preferences]
// @exports: [ApiService, ErrorHandler, AppError, ErrorType]
// @baseUrl: http://localhost:8001/api/v1
// @features:
//   - 认证: register, login, logout
//   - 记录: createRecord, getRecords, deleteRecord
//   - 统计: getStatsSummary, getStatsTrends
//   - AI: analyzeData, sendMessage, sendMessageStream
//   - 设置: getUserSettings, updateUserSettings
// @brief: API服务层，封装所有HTTP请求和错误处理
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
  static const List<String> _authErrorKeywords = [
    '认证',
    'token',
    '令牌',
    'authenticated',
    'unauthorized',
    '登录',
    '过期',
  ];

  static const List<String> _networkErrorKeywords = [
    'ClientFailed',
    'ClientException',
    'SocketException',
    'SocketConnection',
    'Connection refused',
    'Timeout',
    'Connection timed out',
    'Network',
    'network',
    '连接失败',
    '网络',
    '无法连接',
    'Operation not permitted',
  ];

  static bool isAuthError(String error) {
    final lowerError = error.toLowerCase();
    return _authErrorKeywords.any(
      (keyword) => lowerError.contains(keyword.toLowerCase()),
    );
  }

  static bool isNetworkError(String error) {
    final lowerError = error.toLowerCase();
    return _networkErrorKeywords.any(
      (keyword) => lowerError.contains(keyword.toLowerCase()),
    );
  }

  static String getFriendlyMessage(String error) {
    if (isAuthError(error)) {
      return '登录已过期，请重新登录';
    }
    if (isNetworkError(error)) {
      return '网络连接失败，请检查网络后重试';
    }
    if (error.contains('服务器') ||
        error.contains('500') ||
        error.contains('502') ||
        error.contains('503')) {
      return '服务器暂时不可用，请稍后重试';
    }
    return '操作失败，请稍后重试';
  }

  static AppError handleError(dynamic error) {
    final errorStr = error.toString().replaceAll('Exception: ', '');

    ErrorType type;
    if (isAuthError(errorStr)) {
      type = ErrorType.auth;
    } else if (isNetworkError(errorStr)) {
      type = ErrorType.network;
    } else if (errorStr.contains('服务器') || errorStr.contains('500')) {
      type = ErrorType.server;
    } else {
      type = ErrorType.unknown;
    }

    return AppError(
      type: type,
      message: getFriendlyMessage(errorStr),
      details: errorStr.length > 100 ? errorStr : null,
      originalError: errorStr,
    );
  }
}

class ApiService {
  static const String _defaultBaseUrl = 'http://43.156.73.168:8001/api/v1';

  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_url') ?? _defaultBaseUrl;
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

  static void _handleResponseError(http.Response response, String defaultMsg) {
    if (response.statusCode != 200) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? defaultMsg);
      } catch (e) {
        if (e is Exception && !e.toString().contains('网络连接失败')) {
          rethrow;
        }
        throw Exception('$defaultMsg (状态码: ${response.statusCode})');
      }
    }
  }

  static Future<User> register(
    String email,
    String password, {
    String? nickname,
  }) async {
    final baseUrl = await _getBaseUrl();
    final body = <String, dynamic>{'email': email, 'password': password};
    if (nickname != null) body['nickname'] = nickname;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '注册失败');
    }

    final data = jsonDecode(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(data));

    return User.fromJson(data);
  }

  static Future<User> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final baseUrl = await _getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'remember_me': rememberMe,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '登录失败');
    }

    final data = jsonDecode(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(data));

    return User.fromJson(data);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/auth/password'),
      headers: headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '修改密码失败');
    }
  }

  static Future<String> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/auth/email'),
      headers: headers,
      body: jsonEncode({'new_email': newEmail, 'password': password}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '修改邮箱失败');
    }

    final data = jsonDecode(response.body);
    final newEmailResult = data['data']['email'] as String;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      userData['email'] = newEmailResult;
      await prefs.setString('user', jsonEncode(userData));
    }

    return newEmailResult;
  }

  static Future<void> deleteAccount() async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/account'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '注销账号失败');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<BowelRecord> createRecord({
    required String recordDate,
    required String recordTime,
    int? durationMinutes,
    int? stoolType,
    String? color,
    int? smellLevel,
    String? feeling,
    List<String>? symptoms,
    String? notes,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final body = <String, dynamic>{
      'record_date': recordDate,
      'record_time': recordTime,
    };
    if (durationMinutes != null) body['duration_minutes'] = durationMinutes;
    if (stoolType != null) body['stool_type'] = stoolType;
    if (color != null) body['color'] = color;
    if (smellLevel != null) body['smell_level'] = smellLevel;
    if (feeling != null) body['feeling'] = feeling;
    if (symptoms != null) body['symptoms'] = symptoms;
    if (notes != null) body['notes'] = notes;

    final response = await http.post(
      Uri.parse('$baseUrl/records'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '创建记录失败');
    }

    final data = jsonDecode(response.body);
    return BowelRecord.fromJson(data['data']);
  }

  static Future<List<BowelRecord>> getRecords({
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await _safeRequest(
      () => http.get(
        Uri.parse('$baseUrl/records').replace(queryParameters: params),
        headers: headers,
      ),
    );

    _handleResponseError(response, '获取记录失败');

    final data = jsonDecode(response.body);
    return (data['data']['records'] as List)
        .map((e) => BowelRecord.fromJson(e))
        .toList();
  }

  static Future<void> deleteRecord(String recordId) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/records/$recordId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '删除记录失败');
    }
  }

  static Future<StatsSummary> getStatsSummary({
    String period = 'week',
    String? startDate,
    String? endDate,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (startDate != null && endDate != null) {
      params['start_date'] = startDate;
      params['end_date'] = endDate;
    } else {
      params['period'] = period;
    }

    final response = await _safeRequest(
      () => http.get(
        Uri.parse('$baseUrl/stats/summary').replace(queryParameters: params),
        headers: headers,
      ),
    );

    _handleResponseError(response, '获取统计失败');

    final data = jsonDecode(response.body);
    return StatsSummary.fromJson(data['data']);
  }

  static Future<StatsTrends> getStatsTrends({
    String metric = 'frequency',
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final params = <String, String>{};
    params['metric'] = metric;
    if (startDate != null && endDate != null) {
      params['start_date'] = startDate;
      params['end_date'] = endDate;
    } else {
      params['period'] = period;
    }

    final response = await _safeRequest(
      () => http.get(
        Uri.parse('$baseUrl/stats/trends').replace(queryParameters: params),
        headers: headers,
      ),
    );

    _handleResponseError(response, '获取趋势失败');

    final data = jsonDecode(response.body);
    return StatsTrends.fromJson(data['data']);
  }

  static Future<AnalysisResult> analyzeData({
    String analysisType = 'weekly',
    String? startDate,
    String? endDate,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final body = <String, dynamic>{'analysis_type': analysisType};
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;

    final response = await http
        .post(
          Uri.parse('$baseUrl/ai/analyze'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('分析请求超时，请稍后重试');
          },
        );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '分析失败');
    }

    final data = jsonDecode(response.body);
    return AnalysisResult.fromJson(data['data']);
  }

  static Future<List<AnalysisResult>> getAnalyses() async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/ai/analyses'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '获取分析历史失败');
    }

    final data = jsonDecode(response.body);
    return (data['data'] as List)
        .map((e) => AnalysisResult.fromJson(e))
        .toList();
  }

  static Future<Map<String, dynamic>> getUserSettings() async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/settings'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '获取设置失败');
    }

    final data = jsonDecode(response.body);
    return data['data'];
  }

  static Future<void> updateUserSettings({
    bool? devMode,
    String? aiApiKey,
    String? aiApiUrl,
    String? aiModel,
    bool? aiAutoTitle,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (devMode != null) body['dev_mode'] = devMode;
    if (aiApiKey != null) body['ai_api_key'] = aiApiKey;
    if (aiApiUrl != null) body['ai_api_url'] = aiApiUrl;
    if (aiModel != null) body['ai_model'] = aiModel;
    if (aiAutoTitle != null) body['ai_auto_title'] = aiAutoTitle;

    final response = await http.put(
      Uri.parse('$baseUrl/auth/settings'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '更新设置失败');
    }
  }

  static Future<void> markNoBowel(String date) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/records/no-bowel'),
        headers: headers,
        body: jsonEncode({'date': date}),
      );
    } catch (e) {
      throw Exception('网络连接失败: ${e.toString()}');
    }

    if (response.statusCode != 200) {
      String errorMsg = '标注失败';
      try {
        final error = jsonDecode(response.body);
        errorMsg = error['detail'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  static Future<void> unmarkNoBowel(String date) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    http.Response response;
    try {
      response = await http.delete(
        Uri.parse('$baseUrl/records/no-bowel/$date'),
        headers: headers,
      );
    } catch (e) {
      throw Exception('网络连接失败: ${e.toString()}');
    }

    if (response.statusCode != 200) {
      String errorMsg = '取消标注失败';
      try {
        final error = jsonDecode(response.body);
        errorMsg = error['detail'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  static Future<Map<String, dynamic>> markNoBowelBatch(
    String startDate,
    String endDate,
  ) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/records/no-bowel/batch'),
        headers: headers,
        body: jsonEncode({'start_date': startDate, 'end_date': endDate}),
      );
    } catch (e) {
      throw Exception('网络连接失败: ${e.toString()}');
    }

    if (response.statusCode != 200) {
      String errorMsg = '批量标注失败';
      try {
        final error = jsonDecode(response.body);
        errorMsg = error['detail'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body);
    return data['data'];
  }

  static Future<Map<String, dynamic>> deleteRecordsBatch(
    String startDate,
    String endDate,
  ) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    http.Response response;
    try {
      response = await http.delete(
        Uri.parse('$baseUrl/records/batch'),
        headers: headers,
        body: jsonEncode({'start_date': startDate, 'end_date': endDate}),
      );
    } catch (e) {
      throw Exception('网络连接失败: ${e.toString()}');
    }

    if (response.statusCode != 200) {
      String errorMsg = '批量删除失败';
      try {
        final error = jsonDecode(response.body);
        errorMsg = error['detail'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body);
    return data['data'];
  }

  static Future<Map<String, dynamic>> unmarkNoBowelBatch(
    String startDate,
    String endDate,
  ) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    http.Response response;
    try {
      response = await http.delete(
        Uri.parse('$baseUrl/records/no-bowel/batch'),
        headers: headers,
        body: jsonEncode({'start_date': startDate, 'end_date': endDate}),
      );
    } catch (e) {
      throw Exception('网络连接失败: ${e.toString()}');
    }

    if (response.statusCode != 200) {
      String errorMsg = '批量取消标注失败';
      try {
        final error = jsonDecode(response.body);
        errorMsg = error['detail'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body);
    return data['data'];
  }

  static Future<DailyCounts> getDailyCounts({
    String? startDate,
    String? endDate,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await http.get(
      Uri.parse(
        '$baseUrl/records/daily-counts',
      ).replace(queryParameters: params),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '获取每日统计失败');
    }

    final data = jsonDecode(response.body);
    return DailyCounts.fromJson(data['data']);
  }

  static Future<ChatMessage> sendMessage({
    required String message,
    String? conversationId,
    String? recordsStartDate,
    String? recordsEndDate,
    String? systemPrompt,
    String? thinkingIntensity,
  }) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final body = <String, dynamic>{'message': message};
    if (conversationId != null) body['conversation_id'] = conversationId;
    if (recordsStartDate != null) body['records_start_date'] = recordsStartDate;
    if (recordsEndDate != null) body['records_end_date'] = recordsEndDate;
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (thinkingIntensity != null) {
      body['thinking_intensity'] = thinkingIntensity;
    }

    final response = await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );

    _handleResponseError(response, '发送消息失败');

    final data = jsonDecode(response.body);
    return ChatMessage.fromJson(data['data']);
  }

  static Stream<StreamChatChunk> sendMessageStream({
    required String message,
    String? conversationId,
    String? recordsStartDate,
    String? recordsEndDate,
    String? systemPrompt,
    String? thinkingIntensity,
  }) async* {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final body = <String, dynamic>{'message': message};
    if (conversationId != null) body['conversation_id'] = conversationId;
    if (recordsStartDate != null) body['records_start_date'] = recordsStartDate;
    if (recordsEndDate != null) body['records_end_date'] = recordsEndDate;
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (thinkingIntensity != null) {
      body['thinking_intensity'] = thinkingIntensity;
    }

    final request = http.Request('POST', Uri.parse('$baseUrl/ai/chat/stream'));
    request.headers.addAll(headers);
    request.body = jsonEncode(body);

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      final response = await http.Response.fromStream(streamedResponse);
      String errorMsg = '发送消息失败';
      try {
        final error = jsonDecode(response.body);
        errorMsg = error['detail'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    await for (final line in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6);
        if (jsonStr.trim().isEmpty) continue;

        try {
          final json = jsonDecode(jsonStr);
          yield StreamChatChunk.fromJson(json);
        } catch (e) {
          throw Exception('解析流式响应失败: ${e.toString()}');
        }
      }
    }
  }

  static Future<ChatSession> getChatHistory({String? conversationId}) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (conversationId != null) params['conversation_id'] = conversationId;

    final response = await _safeRequest(
      () => http.get(
        Uri.parse('$baseUrl/ai/chat/history').replace(queryParameters: params),
        headers: headers,
      ),
    );

    _handleResponseError(response, '获取对话历史失败');

    final data = jsonDecode(response.body);
    return ChatSession.fromJson(data['data']);
  }

  static Future<void> clearChatHistory({String? conversationId}) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (conversationId != null) params['conversation_id'] = conversationId;

    final response = await http.delete(
      Uri.parse('$baseUrl/ai/chat').replace(queryParameters: params),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '清除对话历史失败');
    }
  }

  static Future<AiStatus> checkAiStatus() async {
    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final response = await _safeRequest(
      () => http.get(Uri.parse('$baseUrl/ai/status'), headers: headers),
    );

    _handleResponseError(response, '获取AI状态失败');

    final data = jsonDecode(response.body);
    return AiStatus.fromJson(data['data']);
  }

  static Future<List<ConversationSummary>> getConversations() async {
    final baseUrl = await _getBaseUrl();
    final token = await _getToken();
    if (token == null) throw Exception('未登录');

    final response = await _safeRequest(
      () => http.get(
        Uri.parse('$baseUrl/ai/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List conversations = data['data']['conversations'];
      return conversations.map((e) => ConversationSummary.fromJson(e)).toList();
    } else {
      throw Exception('获取对话列表失败');
    }
  }

  static Future<void> renameConversation({
    required String conversationId,
    required String title,
    String? systemPrompt,
    String? thinkingIntensity,
  }) async {
    final baseUrl = await _getBaseUrl();
    final token = await _getToken();
    if (token == null) throw Exception('未登录');

    final body = <String, dynamic>{'title': title};
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (thinkingIntensity != null) {
      body['thinking_intensity'] = thinkingIntensity;
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/ai/conversations/$conversationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('重命名对话失败');
    }
  }

  static Future<void> deleteConversation({
    required String conversationId,
  }) async {
    final baseUrl = await _getBaseUrl();
    final token = await _getToken();
    if (token == null) throw Exception('未登录');

    final response = await http.delete(
      Uri.parse('$baseUrl/ai/conversations/$conversationId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('删除对话失败');
    }
  }
}
