import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'features/auth/domain/bloc/auth_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/guest/alojamientos/domain/bloc/alojamientos_bloc.dart';
import 'features/guest/alojamientos/domain/repositories/properties_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Configure dependencies
  await configureDependencies();

  runApp(const BFStayApp());
}

class BFStayApp extends StatelessWidget {
  const BFStayApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          );
        },
      ),
    );
  }
}
