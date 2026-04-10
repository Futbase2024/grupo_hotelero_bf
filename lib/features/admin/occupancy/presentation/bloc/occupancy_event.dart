import '../../domain/entities/occupancy_stats_entity.dart';

abstract class OccupancyEvent {
  const OccupancyEvent();
}

class OccupancyLoadRequested extends OccupancyEvent {
  const OccupancyLoadRequested();
}

class OccupancyRefreshRequested extends OccupancyEvent {
  const OccupancyRefreshRequested();
}

class OccupancyPeriodChanged extends OccupancyEvent {
  const OccupancyPeriodChanged(this.period);
  final OccupancyPeriod period;
}
