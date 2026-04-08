import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bf_stay/l10n/app_localizations.dart';

import '../../features/auth/domain/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/public/home/presentation/screens/public_home_screen.dart';
import '../../features/public/home/presentation/screens/public_home_light_screen.dart';
import '../../features/auth/presentation/screens/booking_access_screen.dart';
import '../../features/guest/home/presentation/screens/guest_home_screen.dart';
import '../../features/guest/home/domain/bloc/guest_home_bloc.dart';
import '../../features/guest/home/domain/bloc/guest_home_event.dart';
import '../../features/guest/notifications/presentation/screens/guest_notifications_screen.dart';
import '../../features/guest/checkin/presentation/screens/checkin_screen.dart';
import '../../features/guest/checkout/presentation/screens/checkout_screen.dart';
import '../../features/guest/checkin/presentation/bloc/checkin_bloc.dart';
import '../../features/guest/checkin/domain/repositories/checkin_repository.dart';
import '../../features/guest/checkout/presentation/bloc/checkout_bloc.dart';
import '../../features/guest/checkout/domain/repositories/checkout_repository.dart';
import '../../features/guest/access_box/presentation/screens/access_box_screen.dart';
import '../../features/guest/stay_guide/presentation/screens/stay_guide_screen.dart';
import '../../features/guest/chat/presentation/screens/chat_screen.dart';
import '../../features/guest/alojamientos/presentation/screens/alojamientos_screen.dart';
import '../../features/guest/alojamientos/presentation/screens/alojamiento_detail_screen.dart';
import '../../features/guest/alojamientos/presentation/screens/unit_detail_screen.dart';
import '../../features/guest/alojamientos/presentation/screens/hotel_rooms_screen.dart';
import '../../features/guest/alojamientos/presentation/screens/hotel_common_areas_screen.dart';
import '../../features/guest/alojamientos/domain/bloc/alojamientos_bloc.dart';
import '../../features/guest/alojamientos/domain/repositories/properties_repository.dart';
import '../../features/guest/house_rules/presentation/screens/house_rules_screen.dart';
import '../../features/guest/normas/presentation/screens/normas_screen.dart';
import '../../features/guest/que_ver/presentation/screens/que_ver_screen.dart';
import '../../features/guest/que_ver/presentation/screens/place_detail_screen.dart';
import '../../features/guest/que_ver/domain/entities/place_entity.dart';
import '../../features/guest/parkings/presentation/screens/parkings_screen.dart';
import '../../features/guest/my_accommodation/presentation/screens/my_accommodation_screen.dart';
import '../../features/guest/my_accommodation/presentation/screens/access_instructions_wrapper_screen.dart';
import '../../features/guest/extras/presentation/screens/romantic_pack_screen.dart';
import '../../features/guest/extras/presentation/screens/jacuzzi_rules_screen.dart';
import '../../features/guest/extras/presentation/screens/physical_registration_screen.dart';
import '../../features/guest/reviews/domain/bloc/reviews_bloc.dart';
import '../../features/guest/reviews/domain/entities/review_entity.dart';
import '../../features/guest/reviews/domain/repositories/reviews_repository.dart';
import '../../features/guest/reviews/presentation/screens/reviews_screen.dart';
import '../../features/guest/reviews/presentation/screens/review_form_screen.dart';
import '../../features/guest/settings/presentation/screens/settings_screen.dart';
import '../../features/staff/dashboard/presentation/screens/staff_dashboard_screen.dart';
import '../../features/staff/checkins/presentation/screens/staff_checkins_screen.dart';
import '../../features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/chat/presentation/screens/conversations_screen.dart';
import '../../features/admin/chat/presentation/screens/admin_chat_screen.dart';
import '../../features/admin/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/admin/domain/repositories/admin_panel_repository.dart';
import '../di/injection.dart';

/// GlobalKey para acceder al Navigator desde cualquier lugar
/// Necesario para mostrar diálogos desde fuera del árbol de navegación (ej: UpdateChecker)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
  static const String guestNotifications = '/guest/notifications';
  static const String checkin = '/guest/checkin/:bookingId';
  static const String checkout = '/guest/checkout/:bookingId';
  static const String accessBox = '/guest/access-box';
  static const String myAccommodation = '/guest/my-accommodation';
  static const String accessInstructions = '/guest/access-instructions';
  static const String stayGuide = '/guest/guide';
  static const String chat = '/guest/chat';
  static const String alojamientos = '/guest/alojamientos';
  static const String alojamientoDetail = '/guest/alojamientos/:id';
  static const String hotelRooms = '/guest/alojamientos/hotel/:propertyId';
  static const String hotelCommonAreas = '/guest/alojamientos/hotel/:propertyId/common-areas';
  static const String unitDetail = '/guest/alojamientos/unit/:unitId';
  static const String houseRulesGeneral = '/guest/house-rules';
  static const String houseRules = '/guest/house-rules/:propertyId';
  static const String normas = '/guest/normas/:bookingId';
  static const String queVer = '/guest/que-ver';
  static const String placeDetail = '/guest/que-ver/:id';
  static const String collection = '/guest/que-ver/collection/:id';
  static const String parkings = '/guest/parkings';
  static const String parkingsByUnit = '/guest/parkings/:unitId';
  static const String romanticPack = '/guest/romantic-pack';
  static const String jacuzziRules = '/guest/jacuzzi-rules';
  static const String physicalRegistration = '/guest/physical-registration';
  static const String settings = '/guest/settings';

  // Reviews routes
  static const String reviews = '/guest/reviews/:propertyId';
  static const String reviewCreate = '/guest/reviews/:propertyId/new';
  static const String reviewEdit = '/guest/reviews/:reviewId/edit';

  // Staff routes
  static const String staffDashboard = '/staff';
  static const String staffCheckins = '/staff/checkins';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminChat = '/admin/chat';
  static const String adminChatConversation = '/admin/chat/:conversationId';
  static const String adminBookingDetail = '/admin/booking/:bookingId';
}

/// Router principal de la aplicación con redirección basada en roles
class AppRouter {
  AppRouter._();

  /// Crea el router con el AuthBloc para redirecciones
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.publicHome,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;
        final isAuthenticating = authState is AuthLoading;

        // Rutas públicas que no requieren autenticación
        const publicRoutes = [
          AppRoutes.publicHome,
          AppRoutes.publicHomeLight,
          AppRoutes.login,
          AppRoutes.bookingAccess,
          AppRoutes.houseRulesGeneral,
        ];
        // Rutas que empiezan con estos prefijos también son públicas
        const publicRoutePrefixes = ['/guest/alojamientos', '/guest/house-rules/', '/guest/que-ver', '/guest/parkings', '/guest/reviews', '/guest/alojamientos/hotel/'];
        final isPublicRoute = publicRoutes.contains(state.matchedLocation) ||
            publicRoutePrefixes.any((prefix) => state.matchedLocation.startsWith(prefix));

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
          builder: (context, state) => BlocProvider(
            create: (context) => AlojamientosBloc(
              propertiesRepository: getIt<PropertiesRepository>(),
            )..add(const AlojamientosStarted()),
            child: const PublicHomeScreen(),
          ),
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
          path: AppRoutes.guestNotifications,
          name: 'guest-notifications',
          builder: (context, state) {
            final authState = context.read<AuthBloc>().state;
            final user = authState is AuthAuthenticated ? authState.user : null;

            return BlocProvider(
              create: (context) => GuestHomeBloc(
                repository: getIt<AdminPanelRepository>(),
              )..add(GuestHomeLoadNotifications(user?.id ?? '')),
              child: const GuestNotificationsScreen(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.checkin,
          name: 'checkin',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return BlocProvider(
              create: (context) => CheckinBloc(
                repository: getIt<CheckinRepository>(),
              ),
              child: CheckinScreen(bookingId: bookingId),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.checkout,
          name: 'checkout',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return BlocProvider(
              create: (context) => CheckoutBloc(
                repository: getIt<CheckoutRepository>(),
              ),
              child: CheckoutScreen(bookingId: bookingId),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.accessBox,
          name: 'access-box',
          builder: (context, state) => const AccessBoxScreen(),
        ),
        GoRoute(
          path: AppRoutes.myAccommodation,
          name: 'my-accommodation',
          builder: (context, state) => const MyAccommodationScreen(),
        ),
        GoRoute(
          path: AppRoutes.accessInstructions,
          name: 'access-instructions',
          builder: (context, state) => const AccessInstructionsWrapperScreen(),
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
        GoRoute(
          path: AppRoutes.alojamientos,
          name: 'alojamientos',
          builder: (context, state) => BlocProvider(
            create: (context) => AlojamientosBloc(
              propertiesRepository: getIt<PropertiesRepository>(),
            )..add(const AlojamientosStarted()),
            child: const AlojamientosScreen(),
          ),
        ),
        GoRoute(
          path: '/guest/alojamientos/:id',
          name: 'alojamiento-detail',
          builder: (context, state) {
            final propertyId = state.pathParameters['id']!;
            return AlojamientoDetailScreen(propertyId: propertyId);
          },
        ),
        GoRoute(
          path: AppRoutes.hotelRooms,
          name: 'hotel-rooms',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return BlocProvider(
              create: (context) => AlojamientosBloc(
                propertiesRepository: getIt<PropertiesRepository>(),
              )..add(const AlojamientosStarted()),
              child: HotelRoomsScreen(propertyId: propertyId),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.hotelCommonAreas,
          name: 'hotel-common-areas',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return HotelCommonAreasScreen(propertyId: propertyId);
          },
        ),
        GoRoute(
          path: AppRoutes.unitDetail,
          name: 'unit-detail',
          builder: (context, state) {
            final unitId = state.pathParameters['unitId']!;
            return BlocProvider(
              create: (context) => AlojamientosBloc(
                propertiesRepository: getIt<PropertiesRepository>(),
              )..add(UnitDetailRequested(unitId: unitId)),
              child: UnitDetailScreen(unitId: unitId),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.houseRulesGeneral,
          name: 'house-rules-general',
          builder: (context, state) => const HouseRulesScreen(),
        ),
        GoRoute(
          path: AppRoutes.houseRules,
          name: 'house-rules',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return HouseRulesScreen(propertyId: propertyId);
          },
        ),
        GoRoute(
          path: AppRoutes.normas,
          name: 'normas',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return NormasScreen(bookingId: bookingId);
          },
        ),
        GoRoute(
          path: AppRoutes.queVer,
          name: 'que-ver',
          builder: (context, state) => const QueVerScreen(),
        ),
        GoRoute(
          path: AppRoutes.placeDetail,
          name: 'place-detail',
          builder: (context, state) {
            final placeId = state.pathParameters['id']!;
            final extra = state.extra as Map<String, dynamic>?;
            return PlaceDetailScreen(
              placeId: placeId,
              place: extra?['place'] as PlaceEntity?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.parkings,
          name: 'parkings',
          builder: (context, state) => const ParkingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.parkingsByUnit,
          name: 'parkings-by-unit',
          builder: (context, state) {
            final unitId = state.pathParameters['unitId']!;
            return ParkingsScreen(unitId: unitId);
          },
        ),
        GoRoute(
          path: AppRoutes.romanticPack,
          name: 'romantic-pack',
          builder: (context, state) => const RomanticPackScreen(),
        ),
        GoRoute(
          path: AppRoutes.jacuzziRules,
          name: 'jacuzzi-rules',
          builder: (context, state) => const JacuzziRulesScreen(),
        ),
        GoRoute(
          path: AppRoutes.physicalRegistration,
          name: 'physical-registration',
          builder: (context, state) => const PhysicalRegistrationScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // Reviews Routes
        GoRoute(
          path: AppRoutes.reviews,
          name: 'reviews',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return BlocProvider(
              create: (context) => ReviewsBloc(
                reviewsRepository: getIt<ReviewsRepository>(),
              )..add(ReviewsStarted(propertyId: propertyId)),
              child: ReviewsScreen(
                propertyId: propertyId,
                propertyName: extra?['propertyName'] as String?,
                guestId: extra?['guestId'] as String?,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.reviewCreate,
          name: 'review-create',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return BlocProvider(
              create: (context) => ReviewsBloc(
                reviewsRepository: getIt<ReviewsRepository>(),
              ),
              child: ReviewFormScreen(
                propertyId: propertyId,
                guestId: extra?['guestId'] as String?,
                propertyName: extra?['propertyName'] as String?,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.reviewEdit,
          name: 'review-edit',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final existingReview = extra?['review'] as ReviewEntity?;
            return BlocProvider(
              create: (context) => ReviewsBloc(
                reviewsRepository: getIt<ReviewsRepository>(),
              ),
              child: ReviewFormScreen(
                propertyId: existingReview?.propertyId ?? '',
                existingReview: existingReview,
                propertyName: extra?['propertyName'] as String?,
              ),
            );
          },
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

        // Admin Routes
        GoRoute(
          path: AppRoutes.adminDashboard,
          name: 'admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminChat,
          name: 'admin-chat',
          builder: (context, state) => const ConversationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminChatConversation,
          name: 'admin-chat-conversation',
          builder: (context, state) {
            final conversationId = state.pathParameters['conversationId']!;
            return AdminChatScreen(conversationId: conversationId);
          },
        ),
        GoRoute(
          path: AppRoutes.adminBookingDetail,
          name: 'admin-booking-detail',
          builder: (context, state) {
            final bookingId = state.pathParameters['bookingId']!;
            return BookingDetailScreen(
              bookingId: bookingId,
              repository: getIt<AdminPanelRepository>(),
            );
          },
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
                S.of(context).common_page_not_found,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? S.of(context).common_invalid_route,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.publicHome),
                child: Text(S.of(context).common_back_to_home),
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
        return AppRoutes.staffDashboard;
      case UserRole.admin:
        return AppRoutes.adminDashboard;
    }
  }

  /// Verifica si una ruta está permitida para un rol específico
  static bool _isRouteAllowedForRole(String route, UserRole role) {
    const guestRoutes = [
      AppRoutes.guestHome,
      AppRoutes.guestNotifications,
      AppRoutes.checkin,
      AppRoutes.checkout,
      AppRoutes.accessBox,
      AppRoutes.myAccommodation,
      AppRoutes.accessInstructions,
      AppRoutes.stayGuide,
      AppRoutes.chat,
      AppRoutes.alojamientos,
      AppRoutes.queVer,
      AppRoutes.parkings,
      AppRoutes.romanticPack,
      AppRoutes.jacuzziRules,
      AppRoutes.physicalRegistration,
      AppRoutes.settings,
    ];

    // Rutas que empiezan por cierto patrón también son permitidas
    const guestRoutePrefixes = [
      '/guest/checkin/',
      '/guest/checkout/',
      '/guest/alojamientos/',
      '/guest/house-rules/',
      '/guest/normas/',
      '/guest/que-ver/',
      '/guest/parkings/',
    ];

    const staffRoutes = [
      AppRoutes.staffDashboard,
      AppRoutes.staffCheckins,
    ];

    switch (role) {
      case UserRole.guest:
        // Verificar si la ruta está en la lista o empieza con algún prefijo permitido
        if (guestRoutes.contains(route)) return true;
        return guestRoutePrefixes.any((prefix) => route.startsWith(prefix));
      case UserRole.staff:
        return staffRoutes.contains(route);
      case UserRole.admin:
        // Admin tiene acceso a todo (rutas admin + staff + guest)
        return true;
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
