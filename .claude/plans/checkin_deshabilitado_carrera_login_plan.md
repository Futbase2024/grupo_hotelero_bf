# Plan: Botón de check-in deshabilitado tras login con código

## Problema
Algunos huéspedes entran con su código y la home les muestra "No tienes reservas"
y el botón de check-in deshabilitado (caso real: BF-P92D-TDKB, 23/09/2026).

## Causa
- `loginWithBookingCode` cambia de usuario de Supabase dos veces (anónimo → email).
- Cada cambio dispara `authStateChanges` → `AuthCheckRequested`, que el `AuthBloc`
  procesa en paralelo al login.
- Ese `getCurrentUser()` corre antes de que exista la sesión local del huésped y
  antes de reasignar la reserva, así que devuelve un huésped con `bookingId = null`.
- Si su respuesta llega después de la del login, pisa el estado bueno.
- Si el código falla (caducado, erróneo), la sesión anónima creada también acaba
  en la home sin reserva en lugar de mostrar el error.
- Deslizar para refrescar no recupera el estado: sale antes si no hay `bookingId`.

## Cambios
1. `auth_bloc.dart`: flag `_loginInProgress`; mientras hay un login en curso se
   ignoran `authStateChanges` y `AuthCheckRequested`.
2. `auth_repository_impl.dart`:
   - `getCurrentUser()`: un huésped sin reserva activa devuelve `null`.
   - `loginWithEmail`: error controlado si no hay usuario válido (antes `!`).
   - Si falla un login con código, se cierra la sesión anónima creada.
3. `guest_home_screen.dart`: el pull-to-refresh lanza siempre `AuthCheckRequested`.

## Fase 2: doble pantallazo tras el login
Causa: el login devolvía un usuario sin estado de check-in y, 1-2 s después,
los eventos de sesión (que ejecutaban `getCurrentUser()` en un `asyncMap`)
lanzaban `AuthCheckRequested` → `AuthLoading` → spinner y reconstrucción.

4. Los logins con código devuelven el usuario completo (`getCurrentUser()` al final).
5. `AuthCheckRequested` con sesión ya iniciada refresca en silencio (sin
   `AuthLoading`); un error al refrescar mantiene el estado.
6. `authStateChanges` → `sessionChanges` (`Stream<void>`): solo `signedIn` y
   `userUpdated`, sin consultas.
7. `GuestHomeScreen`: `BlocProvider` con `ValueKey(userId_bookingId)` para
   recrear el bloc si cambia la reserva.

## Verificación
- `dart fix --apply && dart analyze` sin errores ni warnings.
