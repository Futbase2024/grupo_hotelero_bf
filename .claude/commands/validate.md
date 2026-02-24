# /futplanner-validate

Ejecuta validación completa de una feature.

## Uso

```
/futplanner-validate [feature]
```

## Ejemplo

```
/futplanner-validate players
```

---

## 🎯 Validación con MCP Dart (Preferido)

### Paso 1: Fixes Automáticos
```
dart_fix
```

### Paso 2: Análisis Estático
```
analyze_files path: lib/features/[feature]/
```

**DEBE retornar 0 errores**

### Paso 3: Formateo
```
dart_format
```

### Paso 4: Tests
```
run_tests
```

### Paso 5: Validación Runtime (si app corriendo)
```
get_runtime_errors
get_widget_tree
```

---

## Validaciones Bash (Fallback)

Solo usar si MCP no está disponible.

### 1. Flutter Analyze

```bash
flutter analyze lib/features/[feature]/
```

**DEBE retornar 0 errores**

---

### 2. Arquitectura

```bash
# ❌ Buscar carpeta data/ prohibida
ls lib/features/[feature]/data/ 2>/dev/null && echo "ERROR: carpeta data/"

# ❌ Buscar entities duplicadas
ls lib/features/[feature]/domain/entities/ 2>/dev/null && echo "ERROR: entities duplicadas"

# ✅ Verificar Repository existe
ls lib/features/[feature]/domain/*_repository.dart

# ✅ Verificar @LazySingleton
grep "@LazySingleton" lib/features/[feature]/domain/*_repository.dart
```

---

### 3. Repository

```bash
# ✅ Verificar import datasource
grep "import.*futplanner_core_datasource" lib/features/[feature]/domain/*_repository.dart

# ❌ Buscar imports prohibidos
grep "import.*data/datasources" lib/features/[feature]/domain/*_repository.dart && echo "ERROR: import prohibido"

# ❌ Buscar Firebase directo
grep "FirebaseFirestore\|FirebaseAuth" lib/features/[feature]/domain/*_repository.dart && echo "ERROR: Firebase directo"
```

---

### 4. BLoC

```bash
# ✅ Verificar @injectable
grep "@injectable" lib/features/[feature]/presentation/bloc/*_bloc.dart

# ✅ Verificar @freezed en events
grep "@freezed" lib/features/[feature]/presentation/bloc/*_event.dart

# ✅ Verificar @freezed en state
grep "@freezed" lib/features/[feature]/presentation/bloc/*_state.dart

# ⚠️ CRÍTICO: Verificar State.loading con message
grep -A3 "factory.*State.loading" lib/features/[feature]/presentation/bloc/*_state.dart
```

**Esperado:**
```dart
const factory [Feature]State.loading({
  @Default('...') String message,
}) = _Loading;
```

---

### 5. LoadingOverlay

```bash
# ✅ Verificar LoadingOverlay
grep -r "LoadingOverlay" lib/features/[feature]/presentation/

# ❌ Buscar StatefulWidget con _isLoading
grep -r "_isLoading" lib/features/[feature]/presentation/ && echo "ERROR: _isLoading manual"
```

---

### 6. Traducciones

```bash
# ❌ Buscar strings hardcodeados
grep -r "Text('" lib/features/[feature]/presentation/ | grep -v "context.lang" && echo "ERROR: strings hardcodeados"

# ❌ Buscar label hardcodeado
grep -r "label: '" lib/features/[feature]/presentation/ && echo "ERROR: label hardcodeado"

# ✅ Verificar uso de context.lang
grep -r "context.lang" lib/features/[feature]/presentation/
```

---

### 7. Material 3 UI

```bash
# ✅ Verificar widgets Material 3
grep -r "Scaffold(" lib/features/[feature]/presentation/
grep -r "AppBar(" lib/features/[feature]/presentation/
grep -r "FilledButton\|TextButton" lib/features/[feature]/presentation/

# ❌ Buscar widgets Cupertino prohibidos
grep -r "CupertinoButton(" lib/features/[feature]/presentation/ && echo "ERROR: CupertinoButton"
grep -r "CupertinoTextField(" lib/features/[feature]/presentation/ && echo "ERROR: CupertinoTextField"
grep -r "CupertinoPageScaffold(" lib/features/[feature]/presentation/ && echo "ERROR: CupertinoPageScaffold"
```

---

### 8. Layouts Responsive

```bash
# ✅ Verificar AppLayoutBuilder
grep -r "AppLayoutBuilder" lib/features/[feature]/presentation/pages/

# ✅ Verificar layouts existen
ls lib/features/[feature]/presentation/layouts/*_mobile_layout.dart
ls lib/features/[feature]/presentation/layouts/*_tablet_layout.dart
ls lib/features/[feature]/presentation/layouts/*_desktop_layout.dart
```

---

### 9. Widgets

```bash
# ❌ Buscar métodos Widget _build
grep -r "Widget _build" lib/features/[feature]/presentation/ && echo "ERROR: método Widget _build"

# ✅ Verificar widgets extraídos
ls lib/features/[feature]/presentation/widgets/
```

---

### 10. Navegación

```bash
# ✅ Verificar ruta en router
grep -r "/[feature]" lib/core/router/

# ✅ Verificar AppConfigWrapper
grep -A5 "path: '/[feature]'" lib/core/router/ | grep "AppConfigWrapper"

# ✅ Verificar BlocProvider con getIt
grep -A5 "path: '/[feature]'" lib/core/router/ | grep "getIt"
```

---

## 🔍 Validación Runtime con MCP Dart

Si la app está corriendo, usar estas herramientas adicionales:

### Detectar Errores en Caliente
```
get_runtime_errors
```

Detecta:
- Excepciones no manejadas
- Errores de renderizado (overflow, etc.)
- Null pointer exceptions

### Inspeccionar Widgets
```
get_widget_tree
```

Verificar:
- Jerarquía Material 3 correcta
- No hay widgets Cupertino donde no deberían

---

## Template: Reporte

```markdown
# Reporte de Validación: [feature]

## Resumen
- **Estado**: ✅ APROBADO / ❌ RECHAZADO
- **Fecha**: YYYY-MM-DD
- **Método**: MCP Dart / Bash

## Resultados

| Área | Estado | Notas |
|------|--------|-------|
| analyze_files / flutter analyze | ✅/❌ | X errores |
| dart_fix | ✅/❌ | X fixes aplicados |
| Arquitectura | ✅/❌ | |
| Repository | ✅/❌ | |
| BLoC | ✅/❌ | |
| LoadingOverlay | ✅/❌ | |
| Traducciones | ✅/❌ | |
| Material 3 UI | ✅/❌ | |
| Layouts | ✅/❌ | |
| Widgets | ✅/❌ | |
| Navegación | ✅/❌ | |
| 📱💻 Paridad Mobile-Desktop | ✅/❌ | |
| Runtime Errors (si app corriendo) | ✅/❌ | |

## Errores Encontrados

1. [Descripción del error]
   - Archivo: `path/to/file.dart:123`
   - Solución: [Cómo arreglarlo]

## Acciones Requeridas

- [ ] Acción 1
- [ ] Acción 2
```

---

## Checklist Manual

Si prefieres validar manualmente:

- [ ] `analyze_files` o `flutter analyze` = 0 errores
- [ ] `dart_fix` aplicado
- [ ] NO carpeta `data/` en feature
- [ ] NO `domain/entities/`
- [ ] Repository con `@LazySingleton`
- [ ] BLoC con `@injectable`
- [ ] State.loading tiene `message` con `@Default`
- [ ] LoadingOverlay usado
- [ ] Traducciones con `context.lang`
- [ ] UI Material 3 (NO Cupertino)
- [ ] 3 layouts en `layouts/`
- [ ] Widgets extraídos (NO métodos `_buildXxx`)
- [ ] Ruta en GoRouter con AppConfigWrapper
- [ ] 📱💻 Paridad Mobile-Desktop verificada
