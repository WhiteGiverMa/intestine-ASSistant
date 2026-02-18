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
      avgFrequencyPerDay: (json['avg_frequency_per_day'] as num?)?.toDouble() ?? 0.0,
      avgDurationMinutes: (json['avg_duration_minutes'] as num?)?.toDouble() ?? 0.0,
      stoolTypeDistribution: Map<String, int>.from(json['stool_type_distribution'] ?? {}),
      timeDistribution: TimeDistribution.fromJson(json['time_distribution'] ?? {}),
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
      warnings: (json['warnings'] as List?)
          ?.map((e) => Warning.fromJson(e))
          .toList() ?? [],
    );
  }
}

class Insight {
  final String type;
  final String title;
  final String description;

  Insight({
    required this.type,
    required this.title,
    required this.description,
  });

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

  Suggestion({
    required this.category,
    required this.suggestion,
  });

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

  Warning({
    required this.type,
    required this.message,
  });

  factory Warning.fromJson(Map<String, dynamic> json) {
    return Warning(
      type: json['type'],
      message: json['message'],
    );
  }
}

class DailyCounts {
  final Map<String, int> dailyCounts;
  final List<String> noBowelDates;

  DailyCounts({
    required this.dailyCounts,
    required this.noBowelDates,
  });

  factory DailyCounts.fromJson(Map<String, dynamic> json) {
    return DailyCounts(
      dailyCounts: Map<String, int>.from(json['daily_counts'] ?? {}),
      noBowelDates: List<String>.from(json['no_bowel_dates'] ?? []),
    );
  }
}
