import 'dart:async';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/supabase_config.dart';
import 'core/config/url_strategy.dart'
    if (dart.library.html) 'core/config/url_strategy_web.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/app_update_service.dart';
import 'core/services/fcm_service/fcm_service_factory.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'features/auth/domain/bloc/auth_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/guest/alojamientos/domain/bloc/alojamientos_bloc.dart';
import 'features/guest/alojamientos/domain/repositories/properties_repository.dart';
import 'firebase_options.dart';
import 'shared/widgets/splash_screen.dart';
import 'shared/widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar URL strategy para web (hash URLs)
  configureUrlStrategy();

  // Inicializar Firebase primero
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar Crashlytics
  // Capturar errores de Flutter
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Capturar errores asíncronos no manejados
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Ejecutar la app dentro de una zona protegida para capturar errores
  runZonedGuarded<Future<void>>(
    () async {
      runApp(const BFStayApp());
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

/// App principal con splash screen integrado
class BFStayApp extends StatefulWidget {
  const BFStayApp({super.key});

  @override
  State<BFStayApp> createState() => _BFStayAppState();
}

class _BFStayAppState extends State<BFStayApp> {
  /// Indica si la inicialización está completa
  bool _isInitialized = false;

  /// Inicializa todos los servicios de la aplicación
  Future<void> _initializeApp() async {
    final crashlytics = FirebaseCrashlytics.instance;

    // Load environment variables (with fallback for web production)
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // En web production, el archivo .env no existe
      // Las variables se obtienen de compile-time constants en AppConfig
      debugPrint('dotenv not available, using compile-time variables');
      // No reportar esto como error, es esperado en producción web
    }

    // Firebase ya fue inicializado en main()
    debugPrint('✅ Firebase already initialized');

    // Initialize Supabase
    try {
      await SupabaseConfig.initialize();
      debugPrint('✅ Supabase initialized');
    } catch (e, s) {
      debugPrint('❌ Error initializing Supabase: $e');
      crashlytics.recordError(e, s, reason: 'Supabase initialization failed');
      rethrow;
    }

    // Configure dependencies
    try {
      await configureDependencies();
      debugPrint('✅ Dependencies configured');
    } catch (e, s) {
      debugPrint('❌ Error configuring dependencies: $e');
      crashlytics.recordError(e, s, reason: 'DI configuration failed');
      rethrow;
    }

    // Initialize FCM Service
    try {
      await fcmService.initialize();
      debugPrint('✅ FCM Service initialized');
    } catch (e, s) {
      debugPrint('❌ Error initializing FCM: $e');
      crashlytics.recordError(e, s, reason: 'FCM initialization failed');
      // No rethrow - FCM no es crítico para la app
    }

    // Initialize App Update Service
    try {
      await AppUpdateService.instance.initialize();
      debugPrint('✅ App Update Service initialized');
    } catch (e, s) {
      debugPrint('❌ Error initializing App Update Service: $e');
      crashlytics.recordError(e, s, reason: 'App Update Service initialization failed');
      // No rethrow - no es crítico
    }

    // Marcar como inicializado
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar splash screen mientras se inicializa
    if (!_isInitialized) {
      return MaterialApp(
        title: 'BF Stay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: SplashScreen(
          onInitComplete: _initializeApp,
        ),
      );
    }

    // Mostrar la app principal después de la inicialización
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: getIt<AuthRepository>(),
          )..add(const AuthCheckRequested()),
        ),
        BlocProvider<AlojamientosBloc>(
          create: (context) => AlojamientosBloc(
            propertiesRepository: getIt<PropertiesRepository>(),
          )..add(const AlojamientosStarted()),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final router = AppRouter.createRouter(authBloc);
          final themeMode = context.watch<ThemeCubit>().state;

          return MaterialApp.router(
            title: 'BF Stay',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: router,
            builder: (context, child) {
              return UpdateChecker(
                checkOnStart: true,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
