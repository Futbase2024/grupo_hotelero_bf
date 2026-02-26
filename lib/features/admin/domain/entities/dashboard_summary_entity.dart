import 'package:equatable/equatable.dart';

/// Entity para el resumen del dashboard de administración
class DashboardSummaryEntity extends Equatable {
  const DashboardSummaryEntity({
    required this.pendingCheckins,
    required this.upcomingCheckins,
    required this.unreadNotifications,
    required this.totalUnits,
    this.recentCheckins,
  });

  final int pendingCheckins;
  final int upcomingCheckins;
  final int unreadNotifications;
  final int totalUnits;
  final List<RecentCheckinEntity>? recentCheckins;

  /// Convierte desde un mapa JSON
  factory DashboardSummaryEntity.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryEntity(
      pendingCheckins: json['pending_checkins'] as int? ?? 0,
      upcomingCheckins: json['upcoming_checkins'] as int? ?? 0,
      unreadNotifications: json['unread_notifications'] as int? ?? 0,
      totalUnits: json['total_units'] as int? ?? 0,
      recentCheckins: (json['recent_checkins'] as List<dynamic>?)
          ?.map((e) => RecentCheckinEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        pendingCheckins,
        upcomingCheckins,
        unreadNotifications,
        totalUnits,
        recentCheckins,
      ];
}

/// Entity para check-ins recientes mostrados en el dashboard
class RecentCheckinEntity extends Equatable {
  const RecentCheckinEntity({
    required this.bookingId,
    required this.bookingCode,
    required this.guestName,
    required this.unitName,
    required this.checkinStatus,
    required this.submittedAt,
  });

  final String bookingId;
  final String bookingCode;
  final String guestName;
  final String unitName;
  final String checkinStatus;
  final DateTime submittedAt;

  /// Convierte desde un mapa JSON
  factory RecentCheckinEntity.fromJson(Map<String, dynamic> json) {
    return RecentCheckinEntity(
      bookingId: json['booking_id'] as String,
      bookingCode: json['booking_code'] as String,
      guestName: json['guest_name'] as String? ?? '',
      unitName: json['unit_name'] as String? ?? '',
      checkinStatus: json['checkin_status'] as String? ?? 'draft',
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        guestName,
        unitName,
        checkinStatus,
        submittedAt,
      ];
}
