# /futplanner-repository

Genera un Repository para una feature existente.

## Uso

```
/futplanner-repository [feature]
```

## Ejemplo

```
/futplanner-repository players
```

---

## Pre-requisitos

1. La feature debe existir en `lib/features/[feature]/`
2. El Entity debe existir en `futplanner_core_datasource`
3. El DataSource debe existir en `futplanner_core_datasource`

```bash
# Verificar Entity
ls packages/futplanner_core_datasource/lib/src/entities/[feature]_entity.dart

# Verificar DataSource
ls packages/futplanner_core_datasource/lib/src/datasources/[feature]_datasource.dart
```

---

## Template

Crear `lib/features/[feature]/domain/[feature]_repository.dart`:

```dart
import 'package:futplanner_core_datasource/futplanner_core_datasource.dart';
import 'package:injectable/injectable.dart';

/// Repository para gestión de [Feature]
///
/// Delega operaciones al DataSource del paquete.
/// Puede inyectar múltiples DataSources si necesita
/// enriquecer datos de diferentes fuentes.
@LazySingleton()
class [Feature]Repository {
  [Feature]Repository(this._dataSource);

  final [Feature]DataSource _dataSource;

  /// Obtener todos los [feature] de un equipo
  Future<List<[Feature]Entity>> getAll({
    required String userId,
    required String teamId,
  }) async {
    return _dataSource.getByTeamId(userId, teamId);
  }

  /// Obtener [feature] por ID
  Future<[Feature]Entity?> getById({
    required String userId,
    required String teamId,
    required String id,
  }) async {
    return _dataSource.getById(userId, teamId, id);
  }

  /// Stream de [feature] (tiempo real)
  Stream<List<[Feature]Entity>> watch({
    required String userId,
    required String teamId,
  }) {
    return _dataSource.watchByTeamId(userId, teamId);
  }

  /// Crear nuevo [feature]
  Future<String> create({
    required String userId,
    required String teamId,
    required [Feature]Entity entity,
  }) async {
    return _dataSource.create(userId, teamId, entity);
  }

  /// Actualizar [feature]
  Future<void> update({
    required String userId,
    required String teamId,
    required [Feature]Entity entity,
  }) async {
    await _dataSource.update(userId, teamId, entity);
  }

  /// Eliminar [feature]
  Future<void> delete({
    required String userId,
    required String teamId,
    required String id,
  }) async {
    await _dataSource.delete(userId, teamId, id);
  }
}
```

---

## Reglas Críticas

### ✅ OBLIGATORIO

1. **@LazySingleton()** en la clase
2. **Importar desde** `futplanner_core_datasource`
3. **Inyectar DataSource(s)** del paquete
4. **Delegar 100%** al DataSource
5. **Parámetros userId/teamId** cuando aplique

### ❌ PROHIBIDO

1. NO importar desde `data/datasources/`
2. NO usar Firebase directamente
3. NO ser clase abstracta/interface
4. NO tener lógica de UI
5. NO tener dependencias de Flutter widgets

---

## Repository con Múltiples DataSources

Cuando necesitas enriquecer datos de múltiples fuentes:

```dart
@LazySingleton()
class PlayersRepository {
  PlayersRepository(
    this._playersDataSource,
    this._teamsDataSource,
    this._attendanceDataSource,
  );

  final PlayersDataSource _playersDataSource;
  final TeamsDataSource _teamsDataSource;
  final AttendanceDataSource _attendanceDataSource;

  /// Obtener jugadores con estadísticas de asistencia
  Future<List<PlayerWithStats>> getPlayersWithStats({
    required String userId,
    required String teamId,
  }) async {
    final players = await _playersDataSource.getByTeamId(userId, teamId);
    final attendance = await _attendanceDataSource.getByTeamId(userId, teamId);

    return players.map((player) {
      final playerAttendance = attendance
          .where((a) => a.playerId == player.id)
          .toList();

      return PlayerWithStats(
        player: player,
        totalSessions: playerAttendance.length,
        attendedSessions: playerAttendance.where((a) => a.present).length,
      );
    }).toList();
  }
}
```

---

## Checklist

- [ ] Archivo en `domain/[feature]_repository.dart`
- [ ] `@LazySingleton()` presente
- [ ] Import de `futplanner_core_datasource`
- [ ] DataSource inyectado
- [ ] Métodos CRUD implementados
- [ ] Stream method para tiempo real
- [ ] Documentación de clase
- [ ] `flutter analyze` sin errores

---

## Post-creación

```bash
# Regenerar inyección de dependencias
dart run build_runner build --delete-conflicting-outputs

# Verificar
flutter analyze
```
