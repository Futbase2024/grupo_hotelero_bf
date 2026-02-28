import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bf_stay/core/di/injection.dart';
import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';
import 'package:bf_stay/features/guest/access_box/domain/entities/access_box_entity.dart';
import 'package:bf_stay/features/guest/access_box/domain/repositories/access_box_repository.dart';

/// Pantalla de Access Box - Códigos de acceso a la propiedad
class AccessBoxScreen extends StatefulWidget {
  const AccessBoxScreen({super.key});

  @override
  State<AccessBoxScreen> createState() => _AccessBoxScreenState();
}

class _AccessBoxScreenState extends State<AccessBoxScreen> {
  AccessBoxEntity? _accessBox;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccessBox();
  }

  Future<void> _loadAccessBox() async {
    final authState = context.read<AuthBloc>().state;
    final bookingId = authState is AuthAuthenticated ? authState.user.bookingId : null;

    if (bookingId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No hay reserva asociada';
      });
      return;
    }

    try {
      final repository = getIt<AccessBoxRepository>();
      final accessBox = await repository.getAccessBox(bookingId);

      if (mounted) {
        setState(() {
          _accessBox = accessBox;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar los códigos de acceso';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimaryColor(context),
          ),
          onPressed: () => context.go('/guest'),
        ),
        title: Text(
          'Access Box',
          style: TextStyle(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(context, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
          strokeWidth: 3,
        ),
      );
    }

    if (_error != null || _accessBox == null) {
      return _AccessBoxErrorView(
        error: _error ?? 'No hay códigos de acceso disponibles',
        onRetry: _loadAccessBox,
      );
    }

    return _AccessBoxContent(accessBox: _accessBox!);
  }
}

/// Vista de error cuando no hay datos
class _AccessBoxErrorView extends StatelessWidget {
  const _AccessBoxErrorView({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            Text(
              error,
              style: TextStyle(
                color: AppColors.getTextSecondaryColor(context),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenido principal de Access Box
class _AccessBoxContent extends StatelessWidget {
  const _AccessBoxContent({required this.accessBox});

  final AccessBoxEntity accessBox;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _AccessBoxHeader(),
          const SizedBox(height: AppTheme.spacing24),

          // Main access code
          _MainAccessCodeCard(accessBox: accessBox),
          const SizedBox(height: AppTheme.spacing24),

          // WiFi Card
          if (accessBox.wifiNetwork != null && accessBox.wifiPassword != null)
            _WiFiCard(
              network: accessBox.wifiNetwork!,
              password: accessBox.wifiPassword!,
            ),

          // Additional codes
          if (accessBox.additionalCodes.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing16),
            _AdditionalCodesSection(codes: accessBox.additionalCodes),
          ],

          // Instructions
          if (accessBox.accessInstructions != null &&
              accessBox.accessInstructions!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing24),
            _InstructionsCard(instructions: accessBox.accessInstructions!),
          ],

          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }
}

/// Header de la pantalla
class _AccessBoxHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Códigos de Acceso',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimaryColor(context),
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Utiliza estos códigos para acceder a la propiedad',
          style: TextStyle(
            color: AppColors.getTextSecondaryColor(context),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta del código principal de acceso
class _MainAccessCodeCard extends StatelessWidget {
  const _MainAccessCodeCard({required this.accessBox});

  final AccessBoxEntity accessBox;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM');
    final validFromStr = dateFormat.format(accessBox.validFrom);
    final validUntilStr = dateFormat.format(accessBox.validUntil);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldWithAlpha30,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con icono y ubicación
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.blackWithAlpha20,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.lock_open_outlined,
                  color: AppColors.black,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código Principal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      accessBox.boxLocation ?? 'Puerta principal',
                      style: const TextStyle(
                        color: AppColors.blackWithAlpha80,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Código de acceso
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing32,
              vertical: AppTheme.spacing20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildCodeDigits(accessBox.mainCode),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Validez
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: AppColors.blackWithAlpha20,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  'Válido del $validFromStr al $validUntilStr',
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCodeDigits(String code) {
    final digits = code.split('');
    return digits.asMap().entries.map((entry) {
      final index = entry.key;
      final digit = entry.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            digit,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
              letterSpacing: 6,
            ),
          ),
          if (index < digits.length - 1) const SizedBox(width: 12),
        ],
      );
    }).toList();
  }
}

/// Tarjeta de WiFi
class _WiFiCard extends StatelessWidget {
  const _WiFiCard({
    required this.network,
    required this.password,
  });

  final String network;
  final String password;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.wifi_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Text(
                'Red WiFi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimaryColor(context),
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),

          // Network name
          _InfoRow(
            label: 'Red',
            value: network,
            icon: Icons.network_cell_outlined,
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Password with copy button
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  label: 'Contraseña',
                  value: password,
                  icon: Icons.vpn_key_outlined,
                  isPassword: true,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              _CopyButton(text: password),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila de información
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isPassword = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.getTextSecondaryColor(context),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getTextSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: isPassword ? 1.5 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botón de copiar
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Contraseña copiada',
                style: TextStyle(
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              backgroundColor: AppColors.getCardColor(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          child: Icon(
            Icons.copy_rounded,
            size: 20,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

/// Sección de códigos adicionales
class _AdditionalCodesSection extends StatelessWidget {
  const _AdditionalCodesSection({required this.codes});

  final List<AdditionalCode> codes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Otros Accesos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimaryColor(context),
                ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        ...codes.map((code) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
              child: _AdditionalCodeCard(code: code),
            )),
      ],
    );
  }
}

/// Tarjeta de código adicional
class _AdditionalCodeCard extends StatelessWidget {
  const _AdditionalCodeCard({required this.code});

  final AdditionalCode code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              _getIconForName(code.icon),
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  code.subtitle,
                  style: TextStyle(
                    color: AppColors.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              code.code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.gold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'wifi':
        return Icons.wifi_outlined;
      case 'room':
      case 'meeting_room':
        return Icons.meeting_room_outlined;
      case 'fitness':
      case 'gym':
        return Icons.fitness_center_outlined;
      case 'pool':
        return Icons.pool_outlined;
      case 'parking':
        return Icons.local_parking_outlined;
      default:
        return Icons.vpn_key_outlined;
    }
  }
}

/// Tarjeta de instrucciones mejorada
class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.instructions});

  final String instructions;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceWithAlpha50
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.getGoldWithAlpha(context, alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.getGoldWithAlpha(context, alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'Instrucciones de Acceso',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.goldWithAlpha30,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Instructions content
          Text(
            instructions,
            style: TextStyle(
              color: AppColors.getTextPrimaryColor(context),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
