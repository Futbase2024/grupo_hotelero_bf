# Skill: GoRouter Navigation

Conocimiento técnico sobre navegación con GoRouter en FutPlanner.

---

## Configuración Base

```dart
// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../../features/app_config/presentation/widgets/app_config_wrapper.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,  // Solo en desarrollo
  routes: <RouteBase>[
    // Rutas aquí
  ],
  errorBuilder: (context, state) => ErrorPage(error: state.error),
  redirect: (context, state) {
    // Lógica de redirección (auth, etc.)
    return null;
  },
);
```

---

## Patrón de Rutas por Feature

### Lista + Detalle + Formulario

```dart
GoRoute(
  path: '/players',
  name: 'playersList',
  builder: (context, state) => AppConfigWrapper(
    child: BlocProvider(
      create: (context) => getIt<PlayersListBloc>()
        ..add(PlayersListEvent.load(teamId: _getTeamId(context))),
      child: const PlayersListPage(),
    ),
  ),
  routes: [
    // Crear nuevo
    GoRoute(
      path: 'new',
      name: 'playersNew',
      builder: (context, state) => AppConfigWrapper(
        child: BlocProvider(
          create: (context) => getIt<PlayerFormBloc>()
            ..add(const PlayerFormEvent.initialize()),
          child: const PlayerFormPage(),
        ),
      ),
    ),
    // Detalle
    GoRoute(
      path: ':id',
      name: 'playersDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AppConfigWrapper(
          child: BlocProvider(
            create: (context) => getIt<PlayerDetailBloc>()
              ..add(PlayerDetailEvent.load(id: id)),
            child: const PlayerDetailPage(),
          ),
        );
      },
      routes: [
        // Editar
        GoRoute(
          path: 'edit',
          name: 'playersEdit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return AppConfigWrapper(
              child: BlocProvider(
                create: (context) => getIt<PlayerFormBloc>()
                  ..add(PlayerFormEvent.initialize(id: id)),
                child: const PlayerFormPage(),
              ),
            );
          },
        ),
      ],
    ),
  ],
),
```

---

## Métodos de Navegación

### context.go() - Reemplazar toda la pila

```dart
// Ir a home (limpia la pila)
context.go('/');

// Ir a lista de jugadores
context.go('/players');
```

### context.push() - Agregar a la pila

```dart
// Ir a detalle (se puede volver con back)
context.push('/players/$playerId');

// Ir a formulario nuevo
context.push('/players/new');

// Ir a editar
context.push('/players/$playerId/edit');
```

### context.pop() - Volver atrás

```dart
// Volver a la pantalla anterior
context.pop();

// Volver con resultado
context.pop(result);
```

### context.pushReplacement() - Reemplazar actual

```dart
// Reemplazar pantalla actual
context.pushReplacement('/players/$newPlayerId');
```

### context.goNamed() - Por nombre de ruta

```dart
// Usando nombre de ruta
context.goNamed(
  'playersDetail',
  pathParameters: {'id': playerId},
);

// Con query parameters
context.goNamed(
  'playersList',
  queryParameters: {'filter': 'active'},
);
```

---

## Path Parameters

### Definición

```dart
GoRoute(
  path: '/players/:id',  // :id es el parámetro
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    // ...
  },
),
```

### Uso

```dart
// Navegar
context.push('/players/abc123');

// Obtener en destino
final id = GoRouterState.of(context).pathParameters['id'];
```

---

## Query Parameters

### Definición

```dart
GoRoute(
  path: '/players',
  builder: (context, state) {
    final filter = state.uri.queryParameters['filter'];
    final sort = state.uri.queryParameters['sort'];
    // ...
  },
),
```

### Uso

```dart
// Navegar con query params
context.push('/players?filter=active&sort=name');

// O con goNamed
context.goNamed(
  'playersList',
  queryParameters: {
    'filter': 'active',
    'sort': 'name',
  },
);
```

---

## Shell Routes (Navegación con Layout Compartido)

```dart
ShellRoute(
  builder: (context, state, child) {
    return MainLayout(
      child: child,
    );
  },
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/players',
      builder: (context, state) => const PlayersListPage(),
    ),
    GoRoute(
      path: '/trainings',
      builder: (context, state) => const TrainingsListPage(),
    ),
  ],
),
```

---

## Guards y Redirecciones

### Redirect Global

```dart
final GoRouter appRouter = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    // Si no está logueado y no está en login, redirigir
    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }

    // Si está logueado y está en login, redirigir a home
    if (isLoggedIn && isLoginRoute) {
      return '/';
    }

    return null;  // No redirigir
  },
);
```

### Redirect en Ruta Específica

```dart
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    final isAdmin = context.read<UserBloc>().state.isAdmin;
    if (!isAdmin) {
      return '/unauthorized';
    }
    return null;
  },
  builder: (context, state) => const AdminPage(),
),
```

---

## AppConfigWrapper Obligatorio

**TODAS las rutas deben usar AppConfigWrapper:**

```dart
GoRoute(
  path: '/players',
  builder: (context, state) => AppConfigWrapper(  // ✅ OBLIGATORIO
    child: BlocProvider(
      create: (context) => getIt<PlayersListBloc>(),
      child: const PlayersListPage(),
    ),
  ),
),
```

**Razón:** AppConfigWrapper asegura que la página reaccione a cambios de idioma y tema.

---

## BlocProvider en Rutas

### Patrón Correcto

```dart
GoRoute(
  path: '/players',
  builder: (context, state) => AppConfigWrapper(
    child: BlocProvider(
      create: (context) => getIt<PlayersListBloc>()  // ✅ getIt
        ..add(PlayersListEvent.load(teamId: teamId)),  // ✅ Evento inicial
      child: const PlayersListPage(),
    ),
  ),
),
```

### ❌ PROHIBIDO

```dart
// NO crear BLoC manualmente
BlocProvider(
  create: (context) => PlayersListBloc(repository),  // ❌
  child: const PlayersListPage(),
),
```

---

## Navegación desde BLoC

Si necesitas navegar desde un BLoC, usa un callback o listener:

```dart
// En la Page
BlocListener<PlayerFormBloc, PlayerFormState>(
  listener: (context, state) {
    state.maybeWhen(
      saved: (player) {
        // Navegar después de guardar
        context.pop(player);
        // O ir a detalle
        context.pushReplacement('/players/${player.id}');
      },
      orElse: () {},
    );
  },
  child: const PlayerFormView(),
)
```

---

## Rutas Anidadas

```dart
// URL resultante: /teams/team1/players/player1

GoRoute(
  path: '/teams/:teamId',
  builder: (context, state) => const TeamDetailPage(),
  routes: [
    GoRoute(
      path: 'players',
      builder: (context, state) => const TeamPlayersPage(),
      routes: [
        GoRoute(
          path: ':playerId',
          builder: (context, state) {
            final teamId = state.pathParameters['teamId']!;
            final playerId = state.pathParameters['playerId']!;
            return PlayerInTeamPage(
              teamId: teamId,
              playerId: playerId,
            );
          },
        ),
      ],
    ),
  ],
),
```

---

## Deep Linking

GoRouter soporta deep links automáticamente:

```dart
// Android: AndroidManifest.xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="futplanner" android:host="app" />
</intent-filter>

// iOS: Info.plist
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>futplanner</string>
    </array>
  </dict>
</array>
```

**URL:** `futplanner://app/players/abc123`

---

## Checklist de Rutas

- [ ] Ruta definida en `app_router.dart`
- [ ] `AppConfigWrapper` envolviendo
- [ ] `BlocProvider` con `getIt`
- [ ] Evento inicial disparado si es necesario
- [ ] Path parameters extraídos correctamente
- [ ] Query parameters manejados si aplica
- [ ] Redirect configurado si es necesario
- [ ] Deep link funcionando (si aplica)
