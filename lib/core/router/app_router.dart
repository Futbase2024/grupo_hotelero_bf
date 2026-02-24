import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/public/home/presentation/screens/public_home_screen.dart';
import '../../features/public/home/presentation/screens/public_home_light_screen.dart';
import '../../features/auth/presentation/screens/booking_access_screen.dart';
import '../../features/guest/home/presentation/screens/guest_home_screen.dart';
import '../../features/guest/checkin/presentation/screens/checkin_screen.dart';
import '../../features/guest/access_box/presentation/screens/access_box_screen.dart';
import '../../features/guest/stay_guide/presentation/screens/stay_guide_screen.dart';
import '../../features/guest/chat/presentation/screens/chat_screen.dart';
import '../../features/staff/dashboard/presentation/screens/staff_dashboard_screen.dart';
import '../../features/staff/checkins/presentation/screens/staff_checkins_screen.dart';

/// Rutas de la aplicación
class AppRoutes {
  AppRoutes._();

  // Public routes
  static const String publicHome = '/';
  static const String publicHomeLight = '/home-light';

  // Auth routes
  static const String login = '/login';
  static const String bookingAccess = '/booking-access';

  // Guest routes
  static const String guestHome = '/guest';
  static const String checkin = '/guest/checkin';
  static const String accessBox = '/guest/access-box';
  static const String stayGuide = '/guest/guide';
  static const String chat = '/guest/chat';

  // Staff routes
  static const String staffDashboard = '/staff';
  static const String staffCheckins = '/staff/checkins';
}

/// Router principal de la aplicación con redirección basada en roles
class AppRouter {
  AppRouter._();

  /// Crea el router con el AuthBloc para redirecciones
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: AppRoutes.publicHome,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;
        final isAuthenticating = authState is AuthLoading;

        // Rutas públicas que no requieren autenticación
        const publicRoutes = [AppRoutes.publicHome, AppRoutes.publicHomeLight, AppRoutes.login, AppRoutes.bookingAccess];
        final isPublicRoute = publicRoutes.contains(state.matchedLocation);

        // Si está cargando, no redirigir
        if (isAuthenticating) return null;

        // Si no está autenticado y trata de acceder a ruta protegida
        if (!isAuthenticated && !isPublicRoute) {
          return AppRoutes.publicHome;
        }

        // Si está autenticado y trata de acceder a la home pública o login
        if (isAuthenticated && (state.matchedLocation == AppRoutes.publicHome || state.matchedLocation == AppRoutes.login)) {
          final user = authState.user;
          return _getHomeRouteForRole(user.role);
        }

        // Si está autenticado, verificar acceso por rol
        if (isAuthenticated) {
          final user = authState.user;
          final allowedRoute = _isRouteAllowedForRole(
            state.matchedLocation,
            user.role,
          );

          if (!allowedRoute) {
            return _getHomeRouteForRole(user.role);
          }
        }

        return null;
      },
      routes: [
        // Public Routes
        GoRoute(
          path: AppRoutes.publicHome,
          name: 'public-home',
          builder: (context, state) => const PublicHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.publicHomeLight,
          name: 'public-home-light',
          builder: (context, state) => const PublicHomeLightScreen(),
        ),
        // Auth Routes
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.bookingAccess,
          name: 'booking-access',
          builder: (context, state) => const BookingAccessScreen(),
        ),

        // Guest Routes
        GoRoute(
          path: AppRoutes.guestHome,
          name: 'guest-home',
          builder: (context, state) => const GuestHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.checkin,
          name: 'checkin',
          builder: (context, state) => const CheckinScreen(),
        ),
        GoRoute(
          path: AppRoutes.accessBox,
          name: 'access-box',
          builder: (context, state) => const AccessBoxScreen(),
        ),
        GoRoute(
          path: AppRoutes.stayGuide,
          name: 'stay-guide',
          builder: (context, state) => const StayGuideScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          name: 'chat',
          builder: (context, state) => const ChatScreen(),
        ),

        // Staff Routes
        GoRoute(
          path: AppRoutes.staffDashboard,
          name: 'staff-dashboard',
          builder: (context, state) => const StaffDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.staffCheckins,
          name: 'staff-checkins',
          builder: (context, state) => const StaffCheckinsScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Ruta no válida',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.publicHome),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Obtiene la ruta de inicio según el rol del usuario
  static String _getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.guest:
        return AppRoutes.guestHome;
      case UserRole.staff:
      case UserRole.admin:
        return AppRoutes.staffDashboard;
    }
  }

  /// Verifica si una ruta está permitida para un rol específico
  static bool _isRouteAllowedForRole(String route, UserRole role) {
    const guestRoutes = [
      AppRoutes.guestHome,
      AppRoutes.checkin,
      AppRoutes.accessBox,
      AppRoutes.stayGuide,
      AppRoutes.chat,
    ];

    const staffRoutes = [
      AppRoutes.staffDashboard,
      AppRoutes.staffCheckins,
    ];

    switch (role) {
      case UserRole.guest:
        return guestRoutes.contains(route);
      case UserRole.staff:
        return staffRoutes.contains(route);
      case UserRole.admin:
        return true; // Admin tiene acceso a todo
    }
  }
}

/// Stream listener para GoRouter que escucha cambios en AuthBloc
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
