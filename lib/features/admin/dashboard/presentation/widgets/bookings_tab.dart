import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/enums/enums.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../shared/widgets/admin_widgets.dart';

/// Tab de reservas del dashboard de administración
class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        return Column(
          children: [
            // Header
            _buildHeader(context),

            // Filter chips
            _buildFilterChips(context, state),

            // Search bar
            _buildSearchBar(context, state),

            // Bookings list
            Expanded(
              child: _buildBookingsList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            'Reservas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          // El FAB está en la pantalla principal
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AdminDashboardState state) {
    final filters = [
      ('all', 'Todas'),
      ('confirmed', 'Confirmadas'),
      ('active', 'Activas'),
      ('in_house', 'En casa'),
      ('checked_out', 'Finalizadas'),
      ('cancelled', 'Canceladas'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (value, label) = filters[index];
          final isSelected = state.bookingsStatusFilter == value ||
              (state.bookingsStatusFilter == null && value == 'all') ||
              (state.bookingsStatusFilter == 'all' && value == 'all');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                context.read<AdminDashboardBloc>().add(
                      AdminDashboardBookingsFilterChanged(
                        value == 'all' ? 'all' : value,
                      ),
                    );
              },
              backgroundColor: AppColors.darkSurface,
              selectedColor: AppColors.gold,
              checkmarkColor: AppColors.black,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.black : AppColors.gray400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.gold : AppColors.darkBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AdminDashboardState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<AdminDashboardBloc>().add(
                AdminDashboardBookingsSearchChanged(
                  value.isEmpty ? null : value,
                ),
              );
        },
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por apellido o código BF...',
          hintStyle: TextStyle(color: AppColors.gray500),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.gold),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, AdminDashboardState state) {
    if (state.isLoadingBookings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final bookings = state.filteredBookings;

    if (bookings.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.calendar_today_outlined,
        title: 'Sin reservas',
        subtitle: 'Crea la primera reserva con el botón +',
        actionLabel: 'Crear reserva',
        onAction: () {
          // TODO: Open CreateBookingBottomSheet
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.darkSurface,
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(
              const AdminDashboardBookingsLoadRequested(),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingListTile(
            unitName: booking.unitName,
            numGuests: booking.numGuests,
            checkInDate: booking.checkInDate,
            checkOutDate: booking.checkOutDate,
            status: _mapStatus(booking.status),
            bookingCode: booking.bookingCode,
            guestName: booking.guestFullName,
            docsPending: booking.docsPending ?? 0,
            onTap: () {
              context.push(
                AppRoutes.adminBookingDetail.replaceFirst(':bookingId', booking.id),
              );
            },
          );
        },
      ),
    );
  }

  BookingStatus _mapStatus(String status) {
    return switch (status) {
      'created' => BookingStatus.created,
      'confirmed' => BookingStatus.confirmed,
      'active' => BookingStatus.active,
      'in_house' => BookingStatus.inHouse,
      'checked_in' => BookingStatus.active, // Legacy - mapear a active
      'checked_out' => BookingStatus.checkedOut,
      'closed' => BookingStatus.closed,
      'cancelled' => BookingStatus.cancelled,
      _ => BookingStatus.created,
    };
  }
}
