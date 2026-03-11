import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../../../auth/domain/bloc/auth_bloc.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../domain/repositories/invoices_repository.dart';
import '../../../bookings/presentation/sheets/create_booking_bottom_sheet.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../invoices/presentation/bloc/invoices_bloc.dart';
import '../../../invoices/presentation/widgets/invoices_tab.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/bookings_tab.dart';
import '../widgets/checkins_tab.dart';
import '../widgets/properties_tab.dart';
import '../../../marketing/presentation/widgets/marketing_tab.dart';

// ignore: avoid_classes_with_only_static_members
class _Debug {
  static void log(String message) {
    debugPrint('🔵 [AdminDashboard] $message');
  }

  static void error(String message, [Object? error]) {
    debugPrint('🔴 [AdminDashboard] $message');
    if (error != null) {
      debugPrint('🔴 [AdminDashboard] Error: $error');
    }
  }
}

/// Pantalla principal del panel de administración.
/// Shell con BottomNavigationBar y 5 tabs.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardBloc _bloc;
  late final InvoicesBloc _invoicesBloc;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _Debug.log('initState - Iniciando AdminDashboardScreen');
    _bloc = AdminDashboardBloc(
      repository: getIt<AdminPanelRepository>(),
    );
    _invoicesBloc = InvoicesBloc(
      repository: getIt<InvoicesRepository>(),
      adminRepository: getIt<AdminPanelRepository>(),
    );
    _authBloc = context.read<AuthBloc>();
    _Debug.log('initState - AuthBloc obtenido: ${_authBloc.state}');
    _bloc.add(const AdminDashboardLoadRequested());
    _Debug.log('initState - AdminDashboardLoadRequested enviado');
  }

  @override
  void dispose() {
    _Debug.log('dispose - Cerrando AdminDashboardScreen');
    _bloc.close();
    _invoicesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _Debug.log('build - Construyendo widget');
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider.value(value: _invoicesBloc),
      ],
      child: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        buildWhen: (prev, curr) => prev.currentTabIndex != curr.currentTabIndex,
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.darkBackground,
            appBar: _buildAppBar(context, state),
            body: _buildBody(state),
            bottomNavigationBar: _buildBottomNav(state),
            floatingActionButton: _buildFAB(state),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AdminDashboardState state) {
    final authState = _authBloc.state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final propertyName = isAdmin
        ? 'BF-Stay Admin'
        : (authState is AuthAuthenticated ? (authState.user.propertyId ?? '') : '');

    return AppBar(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha20,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'BF',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        propertyName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
      actions: [
        // Notification bell
        BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
          buildWhen: (prev, curr) =>
              prev.unreadNotificationsCount != curr.unreadNotificationsCount,
          builder: (context, state) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: _bloc,
                          child: const NotificationsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                if (state.unreadNotificationsCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        state.unreadNotificationsCount > 9
                            ? '9+'
                            : state.unreadNotificationsCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Logout button
        IconButton(
          icon: Icon(
            Icons.logout_rounded,
            color: AppColors.whiteWithAlpha70,
            size: 22,
          ),
          onPressed: () => _showLogoutDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(AdminDashboardState state) {
    final authState = _authBloc.state;
    final isAuthenticated = authState is AuthAuthenticated;
    final isAdmin = isAuthenticated && authState.user.isAdmin;
    final user = isAuthenticated ? authState.user : null;

    // Construir lista de tabs según permisos
    // Orden: Resumen (0), Reservas (1), Check-ins (2), Facturas (3), Marketing (4), Alojamientos (5)
    final tabs = <Widget>[
      const DashboardTab(),
      const BookingsTab(),
      const CheckinsTab(),
    ];

    // Tab de facturas solo visible para admin
    if (isAdmin) {
      tabs.add(const InvoicesTab());
    }

    // Tab de marketing solo visible para admin
    if (isAdmin && user != null) {
      tabs.add(MarketingTab(
        propertyId: user.propertyId ?? '',
        userId: user.id,
      ));
    }

    // Tab de alojamientos solo visible para admin
    if (isAdmin) {
      tabs.add(const PropertiesTab());
    }

    // Asegurar que el índice está dentro del rango
    final validIndex = state.currentTabIndex.clamp(0, tabs.length - 1);

    return IndexedStack(
      index: validIndex,
      children: tabs,
    );
  }

  Widget _buildBottomNav(AdminDashboardState state) {
    final authState = _authBloc.state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    final tabNames = ['Resumen', 'Reservas', 'Check-ins', 'Facturas', 'Marketing', 'Alojamientos'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: state.currentTabIndex,
        onTap: (index) {
          // Si no es admin y trata de acceder a tabs de admin (3, 4 o 5), ignorar
          if (!isAdmin && (index == 3 || index == 4 || index == 5)) return;
          _Debug.log('Tab pulsado: $index (${tabNames[index]})');
          _bloc.add(AdminDashboardTabChanged(index));
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.gray500,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Reservas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg_outlined),
            activeIcon: Icon(Icons.how_to_reg),
            label: 'Check-ins',
          ),
          // Tab de facturas solo visible para admin
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Facturas',
            ),
          // Tab de marketing solo visible para admin
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Marketing',
            ),
          // Tab de alojamientos solo visible para admin
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.apartment_outlined),
              activeIcon: Icon(Icons.apartment),
              label: 'Alojamientos',
            ),
        ],
      ),
    );
  }

  Widget? _buildFAB(AdminDashboardState state) {
    // Solo mostrar FAB en el tab de reservas
    if (state.currentTabIndex != 1) return null;

    return FloatingActionButton(
      heroTag: 'admin_dashboard_fab',
      onPressed: () {
        _Debug.log('FAB presionado - Abriendo CreateBookingBottomSheet');
        try {
          CreateBookingBottomSheet.show(
            context,
            repository: getIt<AdminPanelRepository>(),
            dashboardBloc: _bloc,
          );
          _Debug.log('FAB - CreateBookingBottomSheet.show() llamado correctamente');
        } catch (e, stackTrace) {
          _Debug.error('FAB - Error al abrir CreateBookingBottomSheet', e);
          debugPrint('🔴 StackTrace: $stackTrace');
        }
      },
      backgroundColor: AppColors.gold,
      child: const Icon(
        Icons.add,
        color: AppColors.black,
        size: 28,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.blackWithAlpha80,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.getCardColor(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono decorativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.goldWithAlpha20,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 48,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                '¿Estás seguro de que quieres cerrar sesión?\n\nPodrás volver a acceder con tu código de reserva cuando lo necesites.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextSecondaryColor(dialogContext),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimaryColor(dialogContext),
                        side: BorderSide(color: AppColors.getBorderColor(dialogContext)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _authBloc.add(const AuthLogoutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
