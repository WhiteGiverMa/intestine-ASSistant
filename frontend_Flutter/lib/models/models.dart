// @module: models
// @type: model
// @layer: frontend
// @depends: []
// @exports: [User, BowelRecord, StatsSummary, AnalysisResult, ChatMessage, ChatSession, AiStatus, ConversationSummary, StreamChatChunk, ThinkingIntensity]
// @models:
//   - User: 用户信息
//   - BowelRecord: 排便记录
//   - StatsSummary: 统计摘要
//   - AnalysisResult: 分析结果
//   - ChatMessage: 聊天消息
//   - ChatSession: 聊天会话
//   - AiStatus: AI配置状态
//   - ConversationSummary: 对话摘要
//   - StreamChatChunk: 流式响应块
// @brief: 数据模型定义，包含所有DTO和实体类
class User {
  final String userId;
  final String email;
  final String? nickname;
  final String token;

  User({
    required this.userId,
    required this.email,
    this.nickname,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      email: json['email'],
      nickname: json['nickname'],
      token: json['token'],
    );
  }
}

class BowelRecord {
  final String recordId;
  final String? lid;
  final String recordDate;
  final String? recordTime;
  final int? durationMinutes;
  final int? stoolType;
  final String? color;
  final int? smellLevel;
  final String? feeling;
  final String? symptoms;
  final String? notes;
  final bool isNoBowel;
  final String createdAt;

  BowelRecord({
    required this.recordId,
    this.lid,
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
  });

  factory BowelRecord.fromJson(Map<String, dynamic> json) {
    return BowelRecord(
      recordId: json['record_id'],
      lid: json['lid'],
      recordDate: json['record_date'],
      recordTime: json['record_time'],
      durationMinutes: json['duration_minutes'],
      stoolType: json['stool_type'],
      color: json['color'],
      smellLevel: json['smell_level'],
      feeling: json['feeling'],
      symptoms: json['symptoms'],
      notes: json['notes'],
      isNoBowel: json['is_no_bowel'] ?? false,
      createdAt: json['created_at'],
    );
  }
}

class StatsSummary {
  final int totalRecords;
  final int days;
  final int recordedDays;
  final double coverageRate;
  final double avgFrequencyPerDay;
  final double avgDurationMinutes;
  final Map<String, int> stoolTypeDistribution;
  final TimeDistribution timeDistribution;
  final int healthScore;

  StatsSummary({
    required this.totalRecords,
    required this.days,
    required this.recordedDays,
    required this.coverageRate,
    required this.avgFrequencyPerDay,
    required this.avgDurationMinutes,
    required this.stoolTypeDistribution,
    required this.timeDistribution,
    required this.healthScore,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      totalRecords: json['total_records'] ?? 0,
      days: json['days'] ?? 0,
      recordedDays: json['recorded_days'] ?? 0,
      coverageRate: (json['coverage_rate'] as num?)?.toDouble() ?? 0.0,
      avgFrequencyPerDay:
          (json['avg_frequency_per_day'] as num?)?.toDouble() ?? 0.0,
      avgDurationMinutes:
          (json['avg_duration_minutes'] as num?)?.toDouble() ?? 0.0,
      stoolTypeDistribution: Map<String, int>.from(
        json['stool_type_distribution'] ?? {},
      ),
      timeDistribution: TimeDistribution.fromJson(
        json['time_distribution'] ?? {},
      ),
      healthScore: json['health_score'] ?? 0,
    );
  }
}

class TimeDistribution {
  final int morning;
  final int afternoon;
  final int evening;

  TimeDistribution({
    required this.morning,
    required this.afternoon,
    required this.evening,
  });

  factory TimeDistribution.fromJson(Map<String, dynamic> json) {
    return TimeDistribution(
      morning: json['morning'] ?? 0,
      afternoon: json['afternoon'] ?? 0,
      evening: json['evening'] ?? 0,
    );
  }
}

class AnalysisResult {
  final String? analysisId;
  final int healthScore;
  final List<Insight> insights;
  final List<Suggestion> suggestions;
  final List<Warning> warnings;

  AnalysisResult({
    this.analysisId,
    required this.healthScore,
    required this.insights,
    required this.suggestions,
    required this.warnings,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      analysisId: json['analysis_id'],
      healthScore: json['health_score'],
      insights: (json['insights'] as List)
          .map((e) => Insight.fromJson(e))
          .toList(),
      suggestions: (json['suggestions'] as List)
          .map((e) => Suggestion.fromJson(e))
          .toList(),
      warnings:
          (json['warnings'] as List?)
              ?.map((e) => Warning.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Insight {
  final String type;
  final String title;
  final String description;

  Insight({required this.type, required this.title, required this.description});

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json['type'],
      title: json['title'],
      description: json['description'],
    );
  }
}

class Suggestion {
  final String category;
  final String suggestion;

  Suggestion({required this.category, required this.suggestion});

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      category: json['category'],
      suggestion: json['suggestion'],
    );
  }
}

class Warning {
  final String type;
  final String message;

  Warning({required this.type, required this.message});

  factory Warning.fromJson(Map<String, dynamic> json) {
    return Warning(type: json['type'], message: json['message']);
  }
}

class DailyCounts {
  final Map<String, int> dailyCounts;
  final List<String> noBowelDates;

  DailyCounts({required this.dailyCounts, required this.noBowelDates});

  factory DailyCounts.fromJson(Map<String, dynamic> json) {
    return DailyCounts(
      dailyCounts: Map<String, int>.from(json['daily_counts'] ?? {}),
      noBowelDates: List<String>.from(json['no_bowel_dates'] ?? []),
    );
  }
}

class TrendPoint {
  final String date;
  final int value;
  final bool isRecorded;

  TrendPoint({required this.date, required this.value, this.isRecorded = true});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'],
      value: json['value'] ?? 0,
      isRecorded: json['is_recorded'] ?? true,
    );
  }
}

class StatsTrends {
  final String metric;
  final List<TrendPoint> trends;

  StatsTrends({required this.metric, required this.trends});

  factory StatsTrends.fromJson(Map<String, dynamic> json) {
    return StatsTrends(
      metric: json['metric'] ?? 'frequency',
      trends:
          (json['trends'] as List?)
              ?.map((e) => TrendPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ChatMessage {
  final String messageId;
  final String conversationId;
  final String role;
  final String content;
  final String? thinkingContent;
  final String createdAt;

  ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.role,
    required this.content,
    this.thinkingContent,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'],
      conversationId: json['conversation_id'],
      role: json['role'],
      content: json['content'],
      thinkingContent: json['thinking_content'],
      createdAt: json['created_at'],
    );
  }
}

class ChatSession {
  final String conversationId;
  final String? title;
  final String createdAt;
  final String updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.conversationId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      conversationId: json['conversation_id'],
      title: json['title'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      messages:
          (json['messages'] as List?)
              ?.map((e) => ChatMessage.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AiStatus {
  final bool hasApiKey;
  final bool hasApiUrl;
  final bool hasModel;
  final bool isConfigured;

  AiStatus({
    required this.hasApiKey,
    required this.hasApiUrl,
    required this.hasModel,
    required this.isConfigured,
  });

  factory AiStatus.fromJson(Map<String, dynamic> json) {
    return AiStatus(
      hasApiKey: json['has_api_key'] ?? false,
      hasApiUrl: json['has_api_url'] ?? false,
      hasModel: json['has_model'] ?? false,
      isConfigured: json['is_configured'] ?? false,
    );
  }
}

class ConversationSummary {
  final String conversationId;
  final String? title;
  final String createdAt;
  final String updatedAt;
  final int messageCount;

  ConversationSummary({
    required this.conversationId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      conversationId: json['conversation_id'],
      title: json['title'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      messageCount: json['message_count'] ?? 0,
    );
  }
}

enum ThinkingIntensity {
  low,
  medium,
  high;

  String toApiValue() {
    switch (this) {
      case ThinkingIntensity.low:
        return 'low';
      case ThinkingIntensity.medium:
        return 'medium';
      case ThinkingIntensity.high:
        return 'high';
    }
  }

  static ThinkingIntensity fromApiValue(String value) {
    switch (value) {
      case 'low':
        return ThinkingIntensity.low;
      case 'high':
        return ThinkingIntensity.high;
      default:
        return ThinkingIntensity.medium;
    }
  }
}

class StreamChatChunk {
  final String? content;
  final String? reasoningContent;
  final bool done;
  final String? messageId;
  final String? conversationId;

  StreamChatChunk({
    this.content,
    this.reasoningContent,
    required this.done,
    this.messageId,
    this.conversationId,
  });

  factory StreamChatChunk.fromJson(Map<String, dynamic> json) {
    return StreamChatChunk(
      content: json['content'],
      reasoningContent: json['reasoning_content'],
      done: json['done'] ?? false,
      messageId: json['message_id'],
      conversationId: json['conversation_id'],
    );
  }
}
