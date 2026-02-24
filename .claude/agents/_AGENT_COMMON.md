# Reglas Comunes de Agentes

## 🎯 MCP Dart/Flutter Disponible

El proyecto tiene configurado el **MCP de Dart/Flutter**. Usar estas herramientas nativas cuando sea posible:

| Herramienta | Uso | Cuándo |
|-------------|-----|--------|
| `dart_fix` | Aplicar fixes automáticos | Después de editar archivos .dart |
| `analyze_files` | Análisis estático estructurado | Validación de código |
| `dart_format` | Formatear código | Antes de commit |
| `run_tests` | Ejecutar tests | Validación final |
| `pub` | Gestión de dependencias | Añadir/actualizar paquetes |
| `pub_dev_search` | Buscar paquetes | Encontrar dependencias |
| `get_runtime_errors` | Errores en runtime | Debug con app corriendo |
| `get_widget_tree` | Inspeccionar widgets | Verificar UI |
| `hot_reload` | Recargar cambios | Iteración rápida |

> **Preferir MCP sobre Bash** para `dart fix`, `dart analyze`, `flutter test`

---

## Reglas Globales (aplican a TODOS los agentes)

### Backend
- ✅ **Supabase** (PostgreSQL + Auth + Storage + Real-Time)
- ❌ **Firebase PROHIBIDO** - El proyecto ha migrado completamente a Supabase
- ✅ DataSources via `getIt<XxxDataSource>()` (DatasourceModule)
- ❌ NO usar factories de Firebase

### Arquitectura
- ❌ NO `data/` en features (excepto app_config, legal)
- ❌ NO `domain/entities/` (usar futplanner_core_datasource)
- ✅ Repository: clase concreta con `@LazySingleton`
- ✅ BLoC: `@injectable` + Freezed

### UI Material Design 3
- ✅ Usar widgets Material 3: `Scaffold`, `AppBar`, `FilledButton`, etc.
- ✅ Colores con `Theme.of(context).colorScheme`
- ✅ `LoadingOverlay` obligatorio
- ✅ `AppLayoutBuilder` con 3 layouts
- ✅ **`CELoading` OBLIGATORIO** - Ver `.claude/agents/ce_loading.md`
- ❌ **NUNCA usar `CircularProgressIndicator`**

### Código
- ✅ `context.lang` para textos
- ✅ Widgets como clases, NO métodos `_buildXxx()`
- ✅ `State.loading` con `message` y `@Default`

### Git
- ❌ NO ejecutar `git add/commit/push`
- ✅ Solo PROPONER comandos git

### Documentación
- ✅ Planes de implementación en `doc/plans/`
- ❌ NUNCA crear planes en `.claude/plans/`

---

## Flujo de Validación con MCP Dart

```
Editar archivos → dart_fix → analyze_files → (si hay errores) → corregir → repetir
```

Para validación completa:
```
dart_fix → analyze_files → run_tests
```

---

## Templates de Código

Ver: `.claude/memory/CONVENTIONS.md`

## Trazabilidad

Mostrar al iniciar y finalizar cada tarea (ver ORCHESTRATOR.md)

## Patrón de Acceso a Datos

```dart
// ✅ CORRECTO - Via DI
final playersDS = getIt<PlayersDataSource>();
final activities = await getIt<ActivitiesDataSource>().getAll();

// ❌ PROHIBIDO - Acceso directo a Supabase
final client = Supabase.instance.client; // NO en features
```
