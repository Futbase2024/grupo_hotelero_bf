import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/admin_booking_entity.dart';
import 'checkin_list_tile.dart';

/// Lista de check-ins agrupada por día de entrada, con cabecera fija por grupo.
///
/// Antes era una lista plana: con más de mil check-ins validados no había forma
/// de situarse. Agrupando por fecha (Hoy · Ayer · Mañana · fecha larga) se
/// navega de un vistazo, y la cabecera pegajosa mantiene el contexto al hacer
/// scroll.
class CheckinsGroupedList extends StatelessWidget {
  const CheckinsGroupedList({
    super.key,
    required this.checkins,
    required this.onRefresh,
    required this.onTapCheckin,
    required this.onManualCheckin,
    required this.onMoreActions,
  });

  final List<AdminBookingEntity> checkins;
  final Future<void> Function() onRefresh;
  final void Function(AdminBookingEntity checkin) onTapCheckin;
  final void Function(AdminBookingEntity checkin) onManualCheckin;
  final void Function(AdminBookingEntity checkin) onMoreActions;

  /// Agrupa preservando el orden que ya trae la lista (el que decide el BLoC).
  List<_CheckinGroup> _groupByDay() {
    final groups = <_CheckinGroup>[];

    for (final checkin in checkins) {
      final day = DateUtils.dateOnly(checkin.checkInDate);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.items.add(checkin);
      } else {
        groups.add(_CheckinGroup(day: day, items: [checkin]));
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay();

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.getCardColor(context),
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          for (final group in groups)
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DayHeaderDelegate(
                    day: group.day,
                    count: group.items.length,
                    backgroundColor: AppColors.getSurfaceColor(context),
                    textColor: AppColors.getTextSecondaryColor(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: group.items.length,
                    itemBuilder: (context, index) {
                      final checkin = group.items[index];
                      return CheckinListTile(
                        checkin: checkin,
                        onTap: checkin.checkinId != null
                            ? () => onTapCheckin(checkin)
                            : null,
                        onManualCheckin:
                            CheckinListTile.canDoManualCheckin(checkin)
                                ? () => onManualCheckin(checkin)
                                : null,
                        onMoreActions: () => onMoreActions(checkin),
                      );
                    },
                  ),
                ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _CheckinGroup {
  _CheckinGroup({required this.day, required this.items});

  final DateTime day;
  final List<AdminBookingEntity> items;
}

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DayHeaderDelegate({
    required this.day,
    required this.count,
    required this.backgroundColor,
    required this.textColor,
  });

  final DateTime day;
  final int count;
  final Color backgroundColor;
  final Color textColor;

  static const double _height = 40;

  String get _label {
    final today = DateUtils.dateOnly(DateTime.now());
    final difference = day.difference(today).inDays;

    return switch (difference) {
      0 => 'Hoy',
      -1 => 'Ayer',
      1 => 'Mañana',
      _ => DateFormat('EEEE d MMMM yyyy', 'es').format(day),
    };
  }

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: backgroundColor,
      child: Row(
        children: [
          Text(
            _label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(fontSize: 11, color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(color: AppColors.getBorderColor(context)),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DayHeaderDelegate oldDelegate) {
    return day != oldDelegate.day ||
        count != oldDelegate.count ||
        backgroundColor != oldDelegate.backgroundColor ||
        textColor != oldDelegate.textColor;
  }
}
