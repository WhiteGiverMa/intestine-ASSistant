export interface Record {
  record_id: string
  record_date: string
  record_time: string
  duration_minutes: number | null
  stool_type: number | null
  color: string | null
  smell_level: number | null
  feeling: string | null
  symptoms: string | null
  notes: string | null
  created_at: string
}

export interface User {
  user_id: string
  email: string
  nickname: string | null
  token: string
}

export interface AnalysisResult {
  analysis_id: string
  health_score: number
  insights: Insight[]
  suggestions: Suggestion[]
  warnings: Warning[]
}

export interface Insight {
  type: string
  title: string
  description: string
}

export interface Suggestion {
  category: string
  suggestion: string
}

export interface Warning {
  type: string
  message: string
}

export interface StatsSummary {
  total_records: number
  avg_frequency_per_day: number
  avg_duration_minutes: number
  stool_type_distribution: Record<string, number>
  time_distribution: {
    morning: number
    afternoon: number
    evening: number
  }
  health_score: number
}
