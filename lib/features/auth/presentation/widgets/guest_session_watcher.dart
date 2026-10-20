import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bf_stay/core/services/notification_refresh_bus.dart';
import 'package:bf_stay/features/auth/domain/bloc/auth_bloc.dart';

/// Revalida la sesión del huésped mientras la app está abierta.
///
/// La sesión solo se comprobaba al arrancar la app en frío, así que un huésped
/// con la app abierta (o en segundo plano) seguía dentro aunque su estancia
/// hubiera terminado y el servidor ya le negara la reserva. Este widget lanza
/// [AuthCheckRequested] —que devuelve [AuthUnauthenticated] si la reserva ya no
/// está activa— en estos casos:
///
///  1. Al volver la app a primer plano.
///  2. Al llegar un push de cierre o check-out de la reserva.
///  3. Periódicamente, por si no llega ningún push.
///
/// Solo actúa con huéspedes autenticados: el staff no tiene estancia que caduque.
class GuestSessionWatcher extends StatefulWidget {
  const GuestSessionWatcher({super.key, required this.child});

  final Widget child;

  /// Cada cuánto se revalida la sesión con la app en primer plano.
  static const Duration periodicCheckInterval = Duration(minutes: 5);

  /// Tipos de push que pueden terminar la estancia.
  static const Set<String> sessionEndingPushTypes = {
    'booking_status',
    'checkout_status',
  };

  @override
  State<GuestSessionWatcher> createState() => _GuestSessionWatcherState();
}

class _GuestSessionWatcherState extends State<GuestSessionWatcher>
    with WidgetsBindingObserver {
  Timer? _periodicTimer;
  StreamSubscription<String>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pushSubscription = NotificationRefreshBus.instance.stream.listen((type) {
      if (GuestSessionWatcher.sessionEndingPushTypes.contains(type)) {
        _revalidateGuestSession();
      }
    });
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushSubscription?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revalidateGuestSession();
      _startPeriodicCheck();
    } else if (state == AppLifecycleState.paused) {
      // En segundo plano no se consulta: al volver se revalida igualmente.
      _periodicTimer?.cancel();
    }
  }

  void _startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      GuestSessionWatcher.periodicCheckInterval,
      (_) => _revalidateGuestSession(),
    );
  }

  void _revalidateGuestSession() {
    if (!mounted) return;

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    if (authState is AuthAuthenticated && authState.user.isGuest) {
      authBloc.add(const AuthCheckRequested());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
