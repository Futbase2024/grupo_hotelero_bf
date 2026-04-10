import '../../domain/entities/occupancy_stats_entity.dart';

class OccupancyState {
  const OccupancyState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.selectedPeriod = OccupancyPeriod.today,
    this.todayStats,
    this.weekStats,
    this.monthStats,
    this.yearStats,
  });

  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final OccupancyPeriod selectedPeriod;
  final OccupancyPeriodStats? todayStats;
  final OccupancyPeriodStats? weekStats;
  final OccupancyPeriodStats? monthStats;
  final OccupancyPeriodStats? yearStats;

  OccupancyPeriodStats? get currentStats {
    switch (selectedPeriod) {
      case OccupancyPeriod.today:
        return todayStats;
      case OccupancyPeriod.week:
        return weekStats;
      case OccupancyPeriod.month:
        return monthStats;
      case OccupancyPeriod.year:
        return yearStats;
    }
  }

  bool get hasData =>
      todayStats != null ||
      weekStats != null ||
      monthStats != null ||
      yearStats != null;

  OccupancyState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    OccupancyPeriod? selectedPeriod,
    OccupancyPeriodStats? todayStats,
    OccupancyPeriodStats? weekStats,
    OccupancyPeriodStats? monthStats,
    OccupancyPeriodStats? yearStats,
    bool clearError = false,
  }) {
    return OccupancyState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      todayStats: todayStats ?? this.todayStats,
      weekStats: weekStats ?? this.weekStats,
      monthStats: monthStats ?? this.monthStats,
      yearStats: yearStats ?? this.yearStats,
    );
  }
}
