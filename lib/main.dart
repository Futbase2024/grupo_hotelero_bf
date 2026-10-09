import 'dart:async';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';

import 'core/config/supabase_config.dart';
import 'core/config/url_strategy.dart'
    if (dart.library.html) 'core/config/url_strategy_web.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/app_update_service.dart';
import 'core/services/fcm_service/fcm_service_factory.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'core/locale/cubit/locale_cubit.dart';
import 'features/auth/domain/bloc/auth_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/widgets/guest_session_watcher.dart';
import 'features/guest/alojamientos/domain/bloc/alojamientos_bloc.dart';
import 'features/guest/alojamientos/domain/repositories/properties_repository.dart';
import 'firebase_options.dart';
import 'shared/widgets/splash_screen.dart';
import 'shared/widgets/update_dialog.dart';

void main() async {
  // Ejecutar todo dentro de la misma zona para evitar Zone mismatch
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Edge-to-edge: el contenido se dibuja bajo las barras de sistema.
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Estilo inicial de las barras durante el splash, que siempre es oscuro.
      // A partir de ahí lo gobierna el AnnotatedRegion de BFStayApp, que sigue al tema activo.
      SystemChrome.setSystemUIOverlayStyle(_overlayStyleFor(Brightness.dark));

      // Configurar URL strategy para web (hash URLs)
      configureUrlStrategy();

      // Inicializar Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configurar Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      runApp(const BFStayApp());
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

/// Estilo de las barras de sistema derivado del brillo del fondo sobre el que se dibujan.
///
/// En edge-to-edge las barras son transparentes, así que lo único que hay que decidir es el
/// contraste de sus iconos: fondo oscuro → iconos claros, y al revés. No se fijan
/// `statusBarColor` ni `systemNavigationBarColor` a propósito: son no-op desde Android 15 y
/// Play los reporta como APIs obsoletas para edge-to-edge.
SystemUiOverlayStyle _overlayStyleFor(Brightness backgroundBrightness) {
  final isDark = backgroundBrightness == Brightness.dark;
  return SystemUiOverlayStyle(
    // statusBarBrightness describe el fondo (solo iOS); las otras dos, los iconos (Android).
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,
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

    // Marcar como inicializado: ya está todo lo imprescindible para pintar
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }

    // ⚡ Servicios NO críticos para la primera pantalla: se inicializan en
    // segundo plano para no bloquear el arranque.
    _initializeBackgroundServices(crashlytics);
  }

  /// Inicializa los servicios que no hacen falta para pintar la primera
  /// pantalla. No se espera su resultado.
  void _initializeBackgroundServices(FirebaseCrashlytics crashlytics) {
    // FCM: pide permisos al sistema y obtiene el token (puede tardar segundos
    // en instalación limpia). Se muestra sobre la app ya pintada.
    unawaited(
      fcmService.initialize().then((_) {
        debugPrint('✅ FCM Service initialized');
      }).catchError((Object e, StackTrace s) {
        debugPrint('❌ Error initializing FCM: $e');
        crashlytics.recordError(e, s, reason: 'FCM initialization failed');
      }),
    );

    // App Update: UpdateChecker espera internamente a esta inicialización
    // antes de comparar versiones, así que el update forzado sigue funcionando.
    unawaited(
      AppUpdateService.instance.initialize().then((_) {
        debugPrint('✅ App Update Service initialized');
      }).catchError((Object e, StackTrace s) {
        debugPrint('❌ Error initializing App Update Service: $e');
        crashlytics.recordError(
          e,
          s,
          reason: 'App Update Service initialization failed',
        );
      }),
    );
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
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value: _overlayStyleFor(Brightness.dark),
          child: SplashScreen(onInitComplete: _initializeApp),
        ),
      );
    }

    // Mostrar la app principal después de la inicialización
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
        BlocProvider<LocaleCubit>(create: (context) => LocaleCubit()),
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(authRepository: getIt<AuthRepository>())
                ..add(const AuthCheckRequested()),
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
          final locale = context.watch<LocaleCubit>().state;

          return MaterialApp.router(
            title: 'BF Stay',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            locale: locale,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            routerConfig: router,
            builder: (context, child) {
              // El brillo se lee del Theme ya resuelto por MaterialApp, así que respeta
              // ThemeMode.system además de la elección explícita del usuario.
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: _overlayStyleFor(Theme.of(context).brightness),
                child: UpdateChecker(
                  checkOnStart: true,
                  child: GuestSessionWatcher(child: child!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
