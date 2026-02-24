# Hooks Obligatorios - FutPlanner Web

## 🎯 MCP Dart Disponible

El proyecto tiene configurado el **MCP de Dart/Flutter** que proporciona herramientas nativas. Usar MCP cuando sea posible para mejor integración.

### Herramientas MCP Dart

| Herramienta MCP | Equivalente Bash | Cuándo Usar |
|-----------------|------------------|-------------|
| `dart_fix` | `dart fix --apply` | Aplicar fixes automáticos |
| `analyze_files` | `dart analyze` | Análisis estático (output estructurado) |
| `dart_format` | `dart format .` | Formatear código |
| `run_tests` | `flutter test` | Ejecutar tests |
| `pub` | `dart pub get` | Gestión de dependencias |
| `hot_reload` | - | Recargar app en ejecución |
| `get_runtime_errors` | - | Errores de app en ejecución |
| `get_widget_tree` | - | Inspeccionar árbol de widgets |

---

## Post-File Hook - EJECUTAR SIEMPRE

**Después de crear o modificar archivos `.dart`:**

```
# Opción 1: MCP Dart (preferido)
dart_fix → analyze_files

# Opción 2: Bash (fallback)
dart fix --apply && dart analyze
```

**Flujo optimizado (batch de archivos):**
```
Editar archivo 1 → Editar archivo 2 → ... → dart_fix → analyze_files → Continuar
```

> ⚡ **Tip**: No ejecutar después de CADA archivo. Agrupar ediciones y ejecutar al final del batch.

---

## Pre-Commit Hook

Antes de considerar CUALQUIER tarea completada:

```
# MCP Dart
dart_fix → analyze_files → run_tests

# Bash (fallback)
dart fix --apply && dart analyze && flutter test
```

---

## Post-Build-Runner Hook

Después de ejecutar `build_runner`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Luego:
```
dart_fix → analyze_files
```

---

## Post-Gen-L10n Hook

Después de generar traducciones:

```bash
flutter gen-l10n
```

Luego:
```
dart_fix → analyze_files
```

---

## 🔍 Debugging con MCP Dart (NUEVO)

Cuando la app está corriendo en modo debug:

| Situación | Herramienta MCP |
|-----------|-----------------|
| Ver errores en runtime | `get_runtime_errors` |
| Inspeccionar UI | `get_widget_tree` |
| Ver widget específico | `get_selected_widget` |
| Aplicar cambios rápido | `hot_reload` |
| Reiniciar app | `hot_restart` |

**Flujo de debug:**
```
launch_app → hacer cambios → hot_reload → get_runtime_errors → verificar
```

---

## Resumen de Comandos

| Hook | MCP Dart | Bash (fallback) |
|------|----------|-----------------|
| Post-File (batch) | `dart_fix` → `analyze_files` | `dart fix --apply && dart analyze` |
| Pre-Commit | `dart_fix` → `analyze_files` → `run_tests` | `dart fix --apply && dart analyze && flutter test` |
| Post-Build-Runner | `dart_fix` | `dart fix --apply` |
| Post-Gen-L10n | `dart_fix` → `analyze_files` | `dart fix --apply && dart analyze` |

---

## ⚠️ Notas Importantes

1. **MCP vs Bash**: Preferir MCP Dart porque da output estructurado y mejor integración
2. **Batch edits**: Agrupar ediciones antes de ejecutar fixes/analyze
3. **Runtime debugging**: Solo disponible si la app está corriendo (`flutter run`)
4. **No automatizar hooks**: El overhead de ejecutar en cada Write/Edit es excesivo
