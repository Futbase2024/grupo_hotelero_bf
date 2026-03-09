import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_booking_entity.dart';

/// Diálogo para seleccionar una reserva con búsqueda
class BookingSelectorDialog extends StatefulWidget {
  const BookingSelectorDialog({
    super.key,
    required this.bookings,
    required this.onSelected,
  });

  final List<AdminBookingEntity> bookings;
  final void Function(AdminBookingEntity booking) onSelected;

  @override
  State<BookingSelectorDialog> createState() => _BookingSelectorDialogState();
}

class _BookingSelectorDialogState extends State<BookingSelectorDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<AdminBookingEntity> get _filteredBookings {
    if (_searchQuery.isEmpty) return widget.bookings;

    final query = _searchQuery.toLowerCase();
    return widget.bookings.where((b) {
      return b.guestFullName.toLowerCase().contains(query) ||
          b.bookingCode.toLowerCase().contains(query) ||
          b.unitName.toLowerCase().contains(query) ||
          b.guestEmail.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.darkSurface,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: AppColors.darkBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.hotel_outlined,
                          color: AppColors.gold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seleccionar Reserva',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Busca por nombre, código o unidad',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.gray400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search field
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar reserva...',
                      hintStyle: const TextStyle(color: AppColors.gray500),
                      prefixIcon: const Icon(Icons.search, color: AppColors.gray500),
                      filled: true,
                      fillColor: AppColors.darkBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Results count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${_filteredBookings.length} reservas',
                    style: const TextStyle(
                      color: AppColors.gray400,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ordenadas por fecha de check-in',
                    style: TextStyle(
                      color: AppColors.gray500.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Bookings list
            Flexible(
              child: _filteredBookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = _filteredBookings[index];
                        return _BookingCard(
                          booking: booking,
                          onTap: () {
                            widget.onSelected(booking);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),

            // Bottom padding
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.gray500.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No hay reservas disponibles'
                  : 'No se encontraron reservas',
              style: const TextStyle(
                color: AppColors.gray400,
                fontSize: 15,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Intenta con otro término de búsqueda',
                style: TextStyle(
                  color: AppColors.gray500.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta individual de reserva
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
  });

  final AdminBookingEntity booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: código y fechas
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.bookingCode,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildDateChip(),
                  ],
                ),
                const SizedBox(height: 10),

                // Guest name
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.guestFullName.isNotEmpty
                            ? booking.guestFullName
                            : 'Sin nombre',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Unit
                Row(
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booking.unitName,
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Email
                if (booking.guestEmail.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.guestEmail,
                          style: const TextStyle(
                            color: AppColors.gray400,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                // Phone
                if (booking.guestPhone != null && booking.guestPhone!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking.guestPhone!,
                        style: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],

                // Guests info
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 18,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booking.guestsDescription,
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.gold.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip() {
    final checkIn = _formatDate(booking.checkInDate);
    final checkOut = _formatDate(booking.checkOutDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 12, color: AppColors.gray500),
          const SizedBox(width: 6),
          Text(
            '$checkIn → $checkOut',
            style: const TextStyle(
              color: AppColors.gray400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

/// Función helper para mostrar el diálogo
Future<AdminBookingEntity?> showBookingSelectorDialog(
  BuildContext context, {
  required List<AdminBookingEntity> bookings,
}) async {
  AdminBookingEntity? selectedBooking;

  await showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => BookingSelectorDialog(
      bookings: bookings,
      onSelected: (booking) => selectedBooking = booking,
    ),
  );

  return selectedBooking;
}
