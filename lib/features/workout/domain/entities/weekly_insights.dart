import 'package:equatable/equatable.dart';

class WeeklyInsights extends Equatable {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int plannedDays;
  final int completedDays;
  final int completedSessions;
  final double adherenceRate;
  final double totalVolume;
  final double previousWeekVolume;
  final double volumeTrendPercent;
  final int personalRecords;

  const WeeklyInsights({
    required this.weekStart,
    required this.weekEnd,
    required this.plannedDays,
    required this.completedDays,
    required this.completedSessions,
    required this.adherenceRate,
    required this.totalVolume,
    required this.previousWeekVolume,
    required this.volumeTrendPercent,
    required this.personalRecords,
  });

  factory WeeklyInsights.fromJson(Map<String, dynamic> json) {
    final rawWeekStart = json['week_start']?.toString();
    final rawWeekEnd = json['week_end']?.toString();
    return WeeklyInsights(
      weekStart: DateTime.tryParse(rawWeekStart ?? '') ?? DateTime.now(),
      weekEnd: DateTime.tryParse(rawWeekEnd ?? '') ?? DateTime.now(),
      plannedDays: (json['planned_days'] as num?)?.toInt() ?? 0,
      completedDays: (json['completed_days'] as num?)?.toInt() ?? 0,
      completedSessions: (json['completed_sessions'] as num?)?.toInt() ?? 0,
      adherenceRate: (json['adherence_rate'] as num?)?.toDouble() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
      previousWeekVolume: (json['previous_week_volume'] as num?)?.toDouble() ?? 0,
      volumeTrendPercent: (json['volume_trend_percent'] as num?)?.toDouble() ?? 0,
      personalRecords: (json['personal_records'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    weekStart,
    weekEnd,
    plannedDays,
    completedDays,
    completedSessions,
    adherenceRate,
    totalVolume,
    previousWeekVolume,
    volumeTrendPercent,
    personalRecords,
  ];
}