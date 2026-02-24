# AmbuTrack Web - Orquestador Multi-Agente

> **Sistema de orquestación de agentes especializados para el desarrollo de AmbuTrack Web**

---

## ⚠️ Reglas Críticas del Proyecto

### PAQUETES - PROHIBICIONES ABSOLUTAS

| Regla | Acción |
|-------|--------|
| **`ambutrack_core`** | ❌ **PROHIBIDO** - Paquete DEPRECADO y obsoleto |
| **`ambutrack_core_datasource`** | ✅ **OBLIGATORIO** - Paquete oficial y activo |

**Imports correctos**:
```dart
// ❌ NUNCA
import 'package:ambutrack_core/...';

// ✅ SIEMPRE
import 'package:ambutrack_core_datasource/ambutrack_core_datasource.dart';
```

**Documentación**: Ver `packages/README.md` y `packages/ambutrack_core/DEPRECATION.md`

---

## Arquitectura del Proyecto

**Backend:** Supabase (PostgreSQL + Auth + Storage + Real-Time)
**UI:** Material Design 3
**State:** BLoC + Freezed + Equatable
**DI:** GetIt + Injectable
**Navigation:** GoRouter (~80+ rutas)

**Supabase Project ID:** `ycmopmnrhrpnnzkvnihr`

---

## Flujo de Decisión

```
NUEVA SOLICITUD
     │
     ▼
┌─────────────────────────────────────────┐
│ ¿Qué tipo de tarea?                     │
│                                         │
│ A) Feature E2E      → Flujo Completo    │
│ B) Entity/DataSource→ DatasourceAgent   │
│ C) Repository/BLoC  → FeatureBuilder    │
│ D) Page/Widget/UI   → UIDesignerAgent   │
│ E) Validar          → QAValidatorAgent  │
│ F) Arquitectura     → ArchitectAgent    │
│ G) Supabase/SQL/RLS → SupabaseSpecialist│
└─────────────────────────────────────────┘
```

---

## Matriz de Agentes

| Tarea | Agente | Archivo |
|-------|--------|---------|
| Validar estructura | 🔵 ArchitectAgent | `agents/AmbuTrackArchitectAgent.md` |
| Entity/DataSource | 🟣 DatasourceAgent | `agents/AmbuTrackDatasourceAgent.md` |
| Repository/BLoC | 🟠 FeatureBuilderAgent | `agents/AmbuTrackFeatureBuilderAgent.md` |
| Page/Widget/UI | 🔵 UIDesignerAgent | `agents/AmbuTrackUIDesignerAgent.md` |
| Validación/QA | 🔴 QAValidatorAgent | `agents/AmbuTrackQAValidatorAgent.md` |
| **Supabase (tablas, RLS, SQL)** | 🗄️ **SupabaseSpecialist** | `agents/supabase_specialist.md` |

---

## Cuándo usar SupabaseSpecialist

- Crear/modificar tablas en PostgreSQL
- Diseñar RLS policies
- Ejecutar migraciones SQL
- Debuggear queries
- Configurar Real-Time subscriptions
- Gestionar Storage buckets
- Edge Functions
- Consultar datos directamente con MCP Supabase

---

## Modelo Recomendado por Agente

Al lanzar `Task` tools, especificar el modelo para optimizar coste y velocidad:

| Agente | Modelo | Justificación |
|--------|--------|---------------|
| ArchitectAgent | `haiku` | Solo lectura y validación |
| DatasourceAgent | `sonnet` | Generación de código |
| FeatureBuilderAgent | `sonnet` | Generación de código |
| UIDesignerAgent | `sonnet` | Generación de código |
| QAValidatorAgent | `haiku` | Validación, no genera código |
| SupabaseSpecialist | `sonnet` | SQL generation |

---

## Flujo Feature E2E (orden obligatorio + checkpoints)

1. **ArchitectAgent** (`haiku`) → Validar estructura, verificar Entity existe
2. **DatasourceAgent** (`sonnet`) → Crear Entity si no existe → ✅ CHECKPOINT 1: `dart analyze` del paquete
3. **FeatureBuilderAgent** (`sonnet`) → Repository + BLoCs → ✅ CHECKPOINT 2: `build_runner` + `flutter analyze`
4. **UIDesignerAgent** (`sonnet`) + **Navegación** + **i18n** → 🔀 PARALELO → ✅ CHECKPOINT 3: `flutter analyze`
5. **QAValidatorAgent** (`haiku`) → Validación final exhaustiva = 0 errores

> **Checkpoints:** Si un checkpoint falla, corregir ANTES de avanzar. No acumular errores.

---

## Matriz de Responsabilidades

| Tarea | Arch | DS | Feature | UI | QA | Supabase |
|-------|:----:|:--:|:-------:|:--:|:--:|:--------:|
| Definir estructura | ✅ | | | | | |
| Crear Entity | | ✅ | | | | |
| Crear tabla SQL | | | | | | ✅ |
| Crear RLS policy | | | | | | ✅ |
| Crear Repository | | | ✅ | | | |
| Crear BLoC | | | ✅ | | | |
| Crear Page/Layout | | | | ✅ | | |
| Crear Widget | | | | ✅ | | |
| Validar código | 🔍 | | | | ✅ | |
| Debug SQL | | | | | | ✅ |

---

## Trazabilidad (OBLIGATORIO)

Al iniciar agente:
```
┌─────────────────────────────────────────┐
│ 🤖 AGENTE: [Nombre]                     │
│ 📋 TAREA: [Descripción]                 │
│ 📁 ARCHIVOS: [Lista]                    │
└─────────────────────────────────────────┘
```

Al finalizar:
```
┌─────────────────────────────────────────┐
│ ✅ COMPLETADO: [Nombre]                 │
│ 📊 [X] archivos modificados             │
│ ⏭️  SIGUIENTE: [Agente o Ninguno]       │
└─────────────────────────────────────────┘
```

---

## Comandos Disponibles

| Comando | Descripción |
|---------|-------------|
| `/feature [nombre]` | Feature E2E completo |
| `/bloc [tipo] [nombre]` | Solo BLoC |
| `/page [tipo] [nombre]` | Solo Page |
| `/repository [nombre]` | Solo Repository |
| `/validate [nombre]` | Validar feature |
| `/prd [título]` | Crear PRD en Trello |
| `/plan [card-id]` | Plan desde Trello → `docs/plans/` |

---

## Single Source of Truth

| Qué | Dónde |
|-----|-------|
| Entities | `packages/ambutrack_core_datasource/` |
| Traducciones | `lib/core/lang/` |
| AppColors | `lib/core/theme/app_colors.dart` |
| AppSizes | `lib/core/theme/app_sizes.dart` |
| Convenciones | `.claude/memory/CONVENTIONS.md` |
| Shared Widgets | `lib/core/widgets/` |
| **Planes de implementación** | `docs/plans/` (⚠️ NUNCA en `.claude/`) |

---

## Reglas Críticas de AmbuTrack

1. **Material Design 3** - NO Cupertino
2. **AppColors** - NO hardcoded colors
3. **SafeArea** - OBLIGATORIO en todas las páginas
4. **Repository pass-through** - SIN conversiones Entity↔Entity
5. **flutter analyze** - 0 warnings OBLIGATORIO
6. **Supabase** - NO Firebase
7. **Widgets como clases** - NO métodos `_buildXxx()`
8. **Diálogos profesionales** - NO SnackBar para notificaciones importantes

---

**📚 Templates de código:** `.claude/memory/CONVENTIONS.md`
**📋 Instrucciones principales:** `CLAUDE.md`
