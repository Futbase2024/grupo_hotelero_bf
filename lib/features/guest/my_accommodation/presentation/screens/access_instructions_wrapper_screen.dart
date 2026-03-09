import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_booking_entity.dart';
import 'package:bf_stay/features/admin/domain/repositories/admin_panel_repository.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/unit_entity.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/entities/property_entity.dart';
import 'package:bf_stay/features/guest/alojamientos/domain/repositories/properties_repository.dart';
import 'package:bf_stay/features/guest/my_accommodation/presentation/screens/access_instructions_screen.dart';

/// Wrapper screen que carga los datos necesarios y muestra las instrucciones de acceso
class AccessInstructionsWrapperScreen extends StatefulWidget {
  const AccessInstructionsWrapperScreen({super.key});

  @override
  State<AccessInstructionsWrapperScreen> createState() => _AccessInstructionsWrapperScreenState();
}

class _AccessInstructionsWrapperScreenState extends State<AccessInstructionsWrapperScreen> {
  AdminBookingEntity? _booking;
  UnitEntity? _unit;
  PropertyEntity? _property;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final bookingId = user?.bookingId;

    if (bookingId == null) {
      setState(() {
        _error = 'No hay reserva asociada';
        _isLoading = false;
      });
      return;
    }

    try {
      // Cargar la reserva
      final repository = getIt<AdminPanelRepository>();
      final booking = await repository.getBooking(bookingId);

      if (booking == null) {
        setState(() {
          _error = 'Reserva no encontrada';
          _isLoading = false;
        });
        return;
      }

      // Cargar la unidad
      final propertiesRepository = getIt<PropertiesRepository>();
      final unit = await propertiesRepository.getUnitById(booking.unitId);

      // Cargar la propiedad para obtener el keycode de la puerta principal
      PropertyEntity? property;
      if (unit != null) {
        property = await propertiesRepository.getById(unit.propertyId);
      }

      if (mounted) {
        setState(() {
          _booking = booking;
          _unit = unit;
          _property = property;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar los datos';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getSurfaceColor(context),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.gold),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'Cargando instrucciones...',
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Error state
    if (_error != null || _booking == null || _unit == null || _property == null) {
      return Scaffold(
        backgroundColor: AppColors.getSurfaceColor(context),
        appBar: AppBar(
          backgroundColor: AppColors.getSurfaceColor(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.getTextPrimaryColor(context),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Instrucciones de Acceso',
            style: TextStyle(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    _error ?? 'No se pudieron cargar las instrucciones',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Success: mostrar la pantalla de instrucciones
    return AccessInstructionsScreen(
      booking: _booking!,
      unit: _unit!,
      property: _property!,
    );
  }
}
