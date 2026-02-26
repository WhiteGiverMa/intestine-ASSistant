// @module: deepseek_service
// @type: service
// @layer: frontend
// @depends: [http, local_db_service, models]
// @exports: [DeepSeekService]
// @features:
//   - chat: 发送消息并获取响应
//   - chatStream: 流式响应
//   - analyzeRecords: 分析排便记录
//   - checkApiStatus: 检查API配置状态
// @brief: DeepSeek API直接调用服务，用户自带API Key
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_db_service.dart';
import '../models/models.dart';

class DeepSeekService {
  static const String _defaultBaseUrl = 'https://api.deepseek.com';
  static const String _defaultModel = 'deepseek-chat';

  static const String kDefaultSystemPrompt =
      '''You are a professional gut health consultant. You can have friendly conversations with users, answer questions about gut health, and provide professional advice.

If the user shares bowel record data, please analyze and provide suggestions based on this data.

Please reply in Chinese, maintaining a professional yet friendly tone.''';

  static ChatRequestDetails? _lastRequestDetails;
  static http.Client? _httpClient;
  static StreamSubscription? _streamSubscription;

  static String _buildApiUrl(String baseUrl) {
    var url = baseUrl.trim();
    if (url.isEmpty) {
      return '$_defaultBaseUrl/v1/chat/completions';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/chat/completions')) {
      return url;
    }
    final versionPattern = RegExp(r'/v\d+$');
    if (versionPattern.hasMatch(url)) {
      return '$url/chat/completions';
    }
    return '$url/v1/chat/completions';
  }

  static void cancelRequest() {
    _httpClient?.close();
    _httpClient = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  static ChatRequestDetails? getLastRequestDetails() => _lastRequestDetails;

  static void clearLastRequestDetails() {
    _lastRequestDetails = null;
  }

  static Future<String?> getApiKey() async {
    return LocalDbService.getSetting('deepseek_api_key');
  }

  static Future<void> setApiKey(String? apiKey) async {
    await LocalDbService.setSetting('deepseek_api_key', apiKey);
  }

  static Future<String?> getApiUrl() async {
    return await LocalDbService.getSetting('deepseek_api_url') ??
        _defaultBaseUrl;
  }

  static Future<void> setApiUrl(String? apiUrl) async {
    await LocalDbService.setSetting('deepseek_api_url', apiUrl);
  }

  static Future<String?> getModel() async {
    final model = await LocalDbService.getSetting('deepseek_model');
    return model ?? _defaultModel;
  }

  static Future<void> setModel(String? model) async {
    await LocalDbService.setSetting('deepseek_model', model);
  }

  static Future<String?> getSystemPrompt() async {
    final saved = await LocalDbService.getSetting('default_system_prompt');
    if (saved == null || saved.isEmpty) {
      return kDefaultSystemPrompt;
    }
    return saved;
  }

  static Future<void> setSystemPrompt(String? prompt) async {
    if (prompt == null || prompt.isEmpty || prompt == kDefaultSystemPrompt) {
      await LocalDbService.setSetting('default_system_prompt', null);
    } else {
      await LocalDbService.setSetting('default_system_prompt', prompt);
    }
  }

  static Future<AiStatus> checkApiStatus() async {
    final apiKey = await getApiKey();
    final apiUrl = await getApiUrl();
    final model = await getModel();

    return AiStatus(
      hasApiKey: apiKey != null && apiKey.isNotEmpty,
      hasApiUrl: apiUrl != null && apiUrl.isNotEmpty,
      hasModel: model != null && model.isNotEmpty,
      isConfigured: apiKey != null && apiKey.isNotEmpty,
    );
  }

  static Future<bool> testConnection({
    String? apiKey,
    String? apiUrl,
    String? model,
  }) async {
    final keyToUse = apiKey ?? await getApiKey();
    if (keyToUse == null || keyToUse.isEmpty) {
      throw Exception('请先配置 API Key');
    }

    final urlToUse = apiUrl ?? await getApiUrl() ?? _defaultBaseUrl;
    final modelToUse = model ?? await getModel() ?? _defaultModel;

    final response = await http
        .post(
          Uri.parse(_buildApiUrl(urlToUse)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $keyToUse',
          },
          body: jsonEncode({
            'model': modelToUse,
            'messages': [
              {'role': 'user', 'content': 'Hi'},
            ],
            'max_tokens': 5,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return true;
    }

    final error = jsonDecode(response.body);
    final errorMsg =
        error['error']?['message'] ?? '连接失败 (${response.statusCode})';
    throw Exception(errorMsg);
  }

  static Future<String> chat({
    required String message,
    String? systemPrompt,
    String? conversationId,
    List<ChatMessage>? history,
    String? thinkingIntensity,
    String? extraUserMessage,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先配置 DeepSeek API Key');
    }

    final apiUrl = await getApiUrl() ?? _defaultBaseUrl;
    final model = await getModel() ?? _defaultModel;

    final messages = <Map<String, String>>[];

    final system = systemPrompt ?? await getSystemPrompt();
    if (system != null && system.isNotEmpty) {
      messages.add({'role': 'system', 'content': system});
    }

    if (history != null) {
      for (final msg in history) {
        messages.add({'role': msg.role, 'content': msg.content});
      }
    }

    messages.add({'role': 'user', 'content': message});

    if (extraUserMessage != null && extraUserMessage.isNotEmpty) {
      messages.add({'role': 'user', 'content': extraUserMessage});
    }

    final requestBody = <String, dynamic>{
      'model': model,
      'messages': messages,
      'stream': false,
    };

    if (thinkingIntensity != null && thinkingIntensity != 'none') {
      requestBody['thinking_intensity'] = thinkingIntensity;
    }

    final url = _buildApiUrl(apiUrl);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final startTime = DateTime.now();

    try {
      _httpClient = http.Client();
      final response = await _httpClient!
          .post(Uri.parse(url), headers: headers, body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 60));

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error']?['message'] ?? 'API调用失败';
        _lastRequestDetails = ChatRequestDetails(
          url: url,
          headers: headers,
          body: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          errorMessage: errorMsg,
          duration: duration,
        );
        throw Exception(errorMsg);
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;

      _lastRequestDetails = ChatRequestDetails(
        url: url,
        headers: headers,
        body: requestBody,
        statusCode: response.statusCode,
        responseBody: response.body,
        duration: duration,
      );

      return content;
    } catch (e) {
      if (e is! Exception ||
          e.toString() != 'Exception: 请先配置 DeepSeek API Key') {
        final duration = DateTime.now().difference(startTime);
        _lastRequestDetails = ChatRequestDetails(
          url: url,
          headers: headers,
          body: requestBody,
          errorMessage: e.toString(),
          duration: duration,
        );
      }
      rethrow;
    }
  }

  static Stream<StreamChatChunk> chatStream({
    required String message,
    String? systemPrompt,
    List<ChatMessage>? history,
    String? thinkingIntensity,
    String? extraUserMessage,
  }) async* {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先配置 DeepSeek API Key');
    }

    final apiUrl = await getApiUrl() ?? _defaultBaseUrl;
    final model = await getModel() ?? _defaultModel;

    final messages = <Map<String, String>>[];

    final system = systemPrompt ?? await getSystemPrompt();
    if (system != null && system.isNotEmpty) {
      messages.add({'role': 'system', 'content': system});
    }

    if (history != null) {
      for (final msg in history) {
        messages.add({'role': msg.role, 'content': msg.content});
      }
    }

    messages.add({'role': 'user', 'content': message});

    if (extraUserMessage != null && extraUserMessage.isNotEmpty) {
      messages.add({'role': 'user', 'content': extraUserMessage});
    }

    final requestBody = <String, dynamic>{
      'model': model,
      'messages': messages,
      'stream': true,
    };

    if (thinkingIntensity != null && thinkingIntensity != 'none') {
      requestBody['thinking_intensity'] = thinkingIntensity;
    }

    final url = _buildApiUrl(apiUrl);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll(headers);
    request.body = jsonEncode(requestBody);

    final startTime = DateTime.now();
    int? statusCode;

    try {
      _httpClient = http.Client();
      final streamedResponse = await _httpClient!
          .send(request)
          .timeout(const Duration(seconds: 120));

      statusCode = streamedResponse.statusCode;

      if (streamedResponse.statusCode != 200) {
        final response = await http.Response.fromStream(streamedResponse);
        String errorMsg = 'API调用失败';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['error']?['message'] ?? errorMsg;
        } catch (_) {}
        final duration = DateTime.now().difference(startTime);
        _lastRequestDetails = ChatRequestDetails(
          url: url,
          headers: headers,
          body: requestBody,
          statusCode: streamedResponse.statusCode,
          responseBody: response.body,
          errorMessage: errorMsg,
          duration: duration,
        );
        throw Exception(errorMsg);
      }

      final buffer = StringBuffer();
      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr.trim() == '[DONE]') {
            yield StreamChatChunk(done: true);
            break;
          }
          if (jsonStr.trim().isEmpty) continue;

          try {
            final json = jsonDecode(jsonStr);
            final delta = json['choices']?[0]?['delta'];
            if (delta != null) {
              final content = delta['content'] as String?;
              final reasoningContent = delta['reasoning_content'] as String?;
              if (content != null) {
                buffer.write(content);
              }
              yield StreamChatChunk(
                content: content,
                reasoningContent: reasoningContent,
                done: false,
              );
            }

            final finishReason = json['choices']?[0]?['finish_reason'];
            if (finishReason != null) {
              yield StreamChatChunk(done: true);
              break;
            }
          } catch (e) {
            // Skip malformed JSON
          }
        }
      }

      final duration = DateTime.now().difference(startTime);
      _lastRequestDetails = ChatRequestDetails(
        url: url,
        headers: headers,
        body: requestBody,
        statusCode: statusCode,
        responseBody:
            '{"choices":[{"message":{"content":"${buffer.length > 500 ? '${buffer.toString().substring(0, 500)}... (${buffer.length} chars)' : buffer.toString()}"}}]}',
        duration: duration,
      );
    } catch (e) {
      if (e is! Exception ||
          e.toString() != 'Exception: 请先配置 DeepSeek API Key') {
        final duration = DateTime.now().difference(startTime);
        _lastRequestDetails = ChatRequestDetails(
          url: url,
          headers: headers,
          body: requestBody,
          statusCode: statusCode,
          errorMessage: e.toString(),
          duration: duration,
        );
      }
      rethrow;
    }
    yield StreamChatChunk(done: true);
  }

  static Future<AnalysisResult> analyzeRecords({
    required String analysisType,
    String? startDate,
    String? endDate,
  }) async {
    final records = await LocalDbService.getRecords(
      startDate: startDate,
      endDate: endDate,
    );
    final stats = await LocalDbService.getStatsSummary(
      startDate: startDate,
      endDate: endDate,
    );

    if (records.isEmpty) {
      return AnalysisResult(
        healthScore: 0,
        insights: [],
        suggestions: [],
        warnings: [Warning(type: 'no_data', message: '没有记录数据可供分析')],
      );
    }

    final prompt = _buildAnalysisPrompt(records, stats, analysisType);

    final response = await chat(
      message: prompt,
      systemPrompt: _getAnalysisSystemPrompt(),
    );

    return _parseAnalysisResponse(response);
  }

  static String _buildAnalysisPrompt(
    List<BowelRecord> records,
    StatsSummary stats,
    String analysisType,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('请分析以下排便健康数据，分析类型: $analysisType');
    buffer.writeln();
    buffer.writeln('## 统计摘要');
    buffer.writeln('- 总记录数: ${stats.totalRecords}');
    buffer.writeln('- 记录天数: ${stats.recordedDays}');
    buffer.writeln('- 平均每日频率: ${stats.avgFrequencyPerDay.toStringAsFixed(2)}');
    buffer.writeln('- 平均时长: ${stats.avgDurationMinutes.toStringAsFixed(1)} 分钟');
    buffer.writeln('- 健康评分: ${stats.healthScore}');
    buffer.writeln(
      '- 时间分布: 上午 ${stats.timeDistribution.morning}, 下午 ${stats.timeDistribution.afternoon}, 晚上 ${stats.timeDistribution.evening}',
    );
    buffer.writeln('- 大便类型分布: ${stats.stoolTypeDistribution}');
    buffer.writeln();
    buffer.writeln('## 最近记录');
    for (final record in records.take(10)) {
      buffer.writeln(
        '- ${record.recordDate} ${record.recordTime ?? ""}: 类型${record.stoolType ?? "?"}, 时长${record.durationMinutes ?? "?"}分钟, 感受${record.feeling ?? "?"}',
      );
    }

    return buffer.toString();
  }

  static String _getAnalysisSystemPrompt() {
    return '''你是一个专业的肠胃健康分析助手。请根据用户提供的排便记录数据进行分析。

请以JSON格式返回分析结果，格式如下：
{
  "health_score": 0-100的整数,
  "insights": [
    {"type": "类型", "title": "标题", "description": "描述"}
  ],
  "suggestions": [
    {"category": "类别", "suggestion": "建议内容"}
  ],
  "warnings": [
    {"type": "类型", "message": "警告信息"}
  ]
}

分析要点：
1. 评估排便频率是否正常（正常为每天1-3次）
2. 评估大便类型（布里斯托分类法，类型3-5为正常）
3. 评估排便时长和感受
4. 给出个性化的饮食和生活建议
5. 如有异常情况，提出警告和建议就医''';
  }

  static AnalysisResult _parseAnalysisResponse(String response) {
    try {
      // Try to extract JSON from response
      String jsonStr = response;
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }

      final json = jsonDecode(jsonStr);
      return AnalysisResult(
        healthScore: json['health_score'] ?? 70,
        insights:
            (json['insights'] as List?)
                ?.map((e) => Insight.fromJson(e))
                .toList() ??
            [],
        suggestions:
            (json['suggestions'] as List?)
                ?.map((e) => Suggestion.fromJson(e))
                .toList() ??
            [],
        warnings:
            (json['warnings'] as List?)
                ?.map((e) => Warning.fromJson(e))
                .toList() ??
            [],
      );
    } catch (e) {
      // Fallback: return basic analysis
      return AnalysisResult(
        healthScore: 70,
        insights: [
          Insight(type: 'general', title: '分析完成', description: response),
        ],
        suggestions: [],
        warnings: [],
      );
    }
  }

  static Future<String> generateTitle(String firstMessage) async {
    try {
      final response = await chat(
        message: '请为以下对话生成一个简短的标题（不超过10个字），只返回标题本身：\n\n$firstMessage',
        systemPrompt: '你是一个标题生成助手，请生成简短准确的标题。',
      );
      return response.trim().replaceAll(RegExp(r'["\n]'), '');
    } catch (e) {
      return '新对话';
    }
  }
}
