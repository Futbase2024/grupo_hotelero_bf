# 🗄️ DataSource Agent

> **Propósito**: Crear DataSources, Repositories y conexiones con Supabase
> **Uso**: Acceso a datos, CRUD, queries, real-time

## 📋 Contexto Mínimo
- **Proyecto**: AmbuTrack Web (Flutter 3.35.3+)
- **Backend**: Supabase 2.8.3 (PostgreSQL)
- **Modelos**: ambutrack_core_datasource (paquete local)
- **DI**: @injectable, @LazySingleton

## ❌ REGLAS CRÍTICAS

### PROHIBICIONES ABSOLUTAS
- ❌ **NUNCA usar paquete `ambutrack_core`** - Paquete DEPRECADO
- ✅ **SIEMPRE usar `ambutrack_core_datasource`** - Paquete actual y activo
- ❌ **NUNCA importar de `package:ambutrack_core/...`**
- ✅ **SIEMPRE importar de `package:ambutrack_core_datasource/...`**

## 🎯 Mi Responsabilidad
- Crear DataSources con Supabase
- Implementar Repositories
- Configurar queries y filtros
- Manejar errores y Either pattern

## ⚠️ IMPORTANTE: Ubicación de Modelos
```
// Los modelos/entidades van en el paquete local, NO aquí
packages/ambutrack_core_datasource/
└── lib/features/[feature]/
    ├── models/[nombre]_model.dart      # DTOs @JsonSerializable
    └── entities/[nombre]_entity.dart   # Entidades dominio
```

## 📁 Estructura en el Proyecto Web
```
lib/features/[feature]/
├── domain/
│   └── repositories/[nombre]_repository.dart  # Contrato
└── data/
    ├── datasources/[nombre]_datasource.dart   # Supabase
    └── repositories/[nombre]_repository_impl.dart
```

## ✅ Plantillas

### Repository Abstracto (Domain)
```dart
// domain/repositories/[nombre]_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/[nombre]_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class [Nombre]Repository {
  /// Obtiene todos los elementos
  Future<Either<Failure, List<[Nombre]Entity>>> getAll();
  
  /// Obtiene un elemento por ID
  Future<Either<Failure, [Nombre]Entity>> getById(String id);
  
  /// Crea un nuevo elemento
  Future<Either<Failure, [Nombre]Entity>> create([Nombre]Entity entity);
  
  /// Actualiza un elemento existente
  Future<Either<Failure, [Nombre]Entity>> update([Nombre]Entity entity);
  
  /// Elimina un elemento por ID
  Future<Either<Failure, void>> delete(String id);
  
  /// Busca elementos con filtro
  Future<Either<Failure, List<[Nombre]Entity>>> search(String query);
}
```

### DataSource (Supabase)
```dart
// data/datasources/[nombre]_datasource.dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambutrack_core_datasource/ambutrack_core_datasource.dart';

@injectable
class [Nombre]DataSource {
  final SupabaseClient _client;
  
  static const String _tableName = '[nombre_tabla]';
  
  [Nombre]DataSource(this._client);
  
  /// Obtiene todos los registros
  Future<List<[Nombre]Model>> getAll() async {
    debugPrint('📡 [Nombre]DataSource: Obteniendo todos...');
    
    final response = await _client
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => [Nombre]Model.fromJson(json))
        .toList();
  }
  
  /// Obtiene por ID
  Future<[Nombre]Model?> getById(String id) async {
    debugPrint('📡 [Nombre]DataSource: Obteniendo id=$id');
    
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return [Nombre]Model.fromJson(response);
  }
  
  /// Crea nuevo registro
  Future<[Nombre]Model> create([Nombre]Model model) async {
    debugPrint('📡 [Nombre]DataSource: Creando...');
    
    final response = await _client
        .from(_tableName)
        .insert(model.toJson())
        .select()
        .single();
    
    return [Nombre]Model.fromJson(response);
  }
  
  /// Actualiza registro
  Future<[Nombre]Model> update([Nombre]Model model) async {
    debugPrint('📡 [Nombre]DataSource: Actualizando id=${model.id}');
    
    final response = await _client
        .from(_tableName)
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();
    
    return [Nombre]Model.fromJson(response);
  }
  
  /// Elimina registro
  Future<void> delete(String id) async {
    debugPrint('📡 [Nombre]DataSource: Eliminando id=$id');
    
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }
  
  /// Busca con filtro
  Future<List<[Nombre]Model>> search(String query) async {
    debugPrint('📡 [Nombre]DataSource: Buscando "$query"');
    
    final response = await _client
        .from(_tableName)
        .select()
        .ilike('nombre', '%$query%')
        .order('nombre');
    
    return (response as List)
        .map((json) => [Nombre]Model.fromJson(json))
        .toList();
  }
}
```

### Repository Implementation
```dart
// data/repositories/[nombre]_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/[nombre]_entity.dart';
import '../../domain/repositories/[nombre]_repository.dart';
import '../datasources/[nombre]_datasource.dart';
import '../../../../core/errors/failures.dart';

@LazySingleton(as: [Nombre]Repository)
class [Nombre]RepositoryImpl implements [Nombre]Repository {
  final [Nombre]DataSource _dataSource;
  
  [Nombre]RepositoryImpl(this._dataSource);
  
  @override
  Future<Either<Failure, List<[Nombre]Entity>>> getAll() async {
    try {
      final models = await _dataSource.getAll();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e, stackTrace) {
      debugPrint('❌ [Nombre]Repository.getAll: $e');
      debugPrint('$stackTrace');
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, [Nombre]Entity>> getById(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure(message: 'Elemento no encontrado'));
      }
      return Right(model.toEntity());
    } catch (e) {
      debugPrint('❌ [Nombre]Repository.getById: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, [Nombre]Entity>> create([Nombre]Entity entity) async {
    try {
      final model = [Nombre]Model.fromEntity(entity);
      final created = await _dataSource.create(model);
      return Right(created.toEntity());
    } catch (e) {
      debugPrint('❌ [Nombre]Repository.create: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, [Nombre]Entity>> update([Nombre]Entity entity) async {
    try {
      final model = [Nombre]Model.fromEntity(entity);
      final updated = await _dataSource.update(model);
      return Right(updated.toEntity());
    } catch (e) {
      debugPrint('❌ [Nombre]Repository.update: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [Nombre]Repository.delete: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<[Nombre]Entity>>> search(String query) async {
    try {
      final models = await _dataSource.search(query);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      debugPrint('❌ [Nombre]Repository.search: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
```

## 🔧 Queries Supabase Comunes

### Filtros
```dart
// Igual
.eq('campo', valor)

// No igual
.neq('campo', valor)

// Mayor/menor
.gt('campo', valor)  // >
.gte('campo', valor) // >=
.lt('campo', valor)  // <
.lte('campo', valor) // <=

// Like (case insensitive)
.ilike('campo', '%texto%')

// In array
.inFilter('campo', ['valor1', 'valor2'])

// Is null
.isFilter('campo', null)

// Between (rango)
.gte('fecha', fechaInicio).lte('fecha', fechaFin)
```

### Ordenamiento
```dart
.order('campo', ascending: true)
.order('campo', ascending: false)
```

### Paginación
```dart
.range(0, 9)  // Primeros 10
.limit(10)
```

### Relaciones (Join)
```dart
// Obtener con relación
.select('''
  *,
  categoria:categorias(id, nombre),
  usuario:usuarios(id, nombre, email)
''')
```

### Real-time
```dart
// Subscription a cambios
_client
    .from(_tableName)
    .stream(primaryKey: ['id'])
    .listen((data) {
      debugPrint('📡 Real-time update: $data');
    });
```

## ⚠️ Reglas que DEBO seguir

1. **Supabase SIEMPRE**: Nunca Firebase
2. **Either pattern**: Para manejo de errores
3. **debugPrint**: Para logging, nunca print()
4. **@injectable/@LazySingleton**: Para DI
5. **Modelos en core_datasource**: No en proyecto web
6. **Try-catch**: En todas las operaciones

## 🔧 Comandos Post-Creación
```bash
# Generar código (injectable)
flutter pub run build_runner build --delete-conflicting-outputs

# Verificar (OBLIGATORIO)
flutter analyze
```

## 💬 Cómo Usarme
```
Usuario: Crea el datasource y repository para la tabla "servicios"

Yo:
1. Creo domain/repositories/servicio_repository.dart
2. Creo data/datasources/servicio_datasource.dart (Supabase)
3. Creo data/repositories/servicio_repository_impl.dart
4. Implemento CRUD + search
5. Ejecuto build_runner
6. Verifico flutter analyze
```
