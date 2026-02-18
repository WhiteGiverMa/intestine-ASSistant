import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8001/api/v1';

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

  static Future<User> register(String email, String password, {String? nickname}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': ?nickname,
      }),
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

  static Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
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
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/records'),
      headers: headers,
      body: jsonEncode({
        'record_date': recordDate,
        'record_time': recordTime,
        'duration_minutes': ?durationMinutes,
        'stool_type': ?stoolType,
        'color': ?color,
        'smell_level': ?smellLevel,
        'feeling': ?feeling,
        'symptoms': ?symptoms,
        'notes': ?notes,
      }),
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
    final headers = await _getHeaders();
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'start_date': ?startDate,
      'end_date': ?endDate,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/records').replace(queryParameters: params),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '获取记录失败');
    }

    final data = jsonDecode(response.body);
    return (data['data']['records'] as List)
        .map((e) => BowelRecord.fromJson(e))
        .toList();
  }

  static Future<void> deleteRecord(String recordId) async {
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

  static Future<StatsSummary> getStatsSummary({String period = 'week'}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/stats/summary?period=$period'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '获取统计失败');
    }

    final data = jsonDecode(response.body);
    return StatsSummary.fromJson(data['data']);
  }

  static Future<AnalysisResult> analyzeData({
    String analysisType = 'weekly',
    String? startDate,
    String? endDate,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/analyze'),
      headers: headers,
      body: jsonEncode({
        'analysis_type': analysisType,
        'start_date': ?startDate,
        'end_date': ?endDate,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '分析失败');
    }

    final data = jsonDecode(response.body);
    return AnalysisResult.fromJson(data['data']);
  }

  static Future<List<AnalysisResult>> getAnalyses() async {
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
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (devMode != null) body['dev_mode'] = devMode;
    if (aiApiKey != null) body['ai_api_key'] = aiApiKey;
    if (aiApiUrl != null) body['ai_api_url'] = aiApiUrl;
    if (aiModel != null) body['ai_model'] = aiModel;

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
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/records/no-bowel'),
        headers: headers,
        body: jsonEncode({'date': date}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? '标注失败');
      }
    } catch (e) {
      if (e.toString().contains('ClientException') || e.toString().contains('Failed to fetch')) {
        throw Exception('网络连接失败，请检查后端服务是否运行');
      }
      rethrow;
    }
  }

  static Future<void> unmarkNoBowel(String date) async {
    final headers = await _getHeaders();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/records/no-bowel/$date'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? '取消标注失败');
      }
    } catch (e) {
      if (e.toString().contains('ClientException') || e.toString().contains('Failed to fetch')) {
        throw Exception('网络连接失败，请检查后端服务是否运行');
      }
      rethrow;
    }
  }

  static Future<DailyCounts> getDailyCounts({
    String? startDate,
    String? endDate,
  }) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await http.get(
      Uri.parse('$baseUrl/records/daily-counts').replace(queryParameters: params),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? '获取每日统计失败');
    }

    final data = jsonDecode(response.body);
    return DailyCounts.fromJson(data['data']);
  }
}
