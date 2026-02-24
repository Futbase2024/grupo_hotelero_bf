# Análisis y Plan de Preparación - AmbuTrack Web

> Fecha: 2025-02-09
> Estado: En progreso

## 📋 Resumen Ejecutivo

Este documento analiza el estado actual de la configuración de `.claude/` en el proyecto **AmbuTrack Web** y propone un plan para preparar el proyecto según las instrucciones correctas.

## 🔍 Análisis Actual

### Identidad del Proyecto

**AmbuTrack Web** - Sistema de gestión integral de servicios de ambulancias:
- Flota de ambulancias y vehículos médicos
- Personal sanitario (turnos, formación, certificaciones)
- Planificación y seguimiento de servicios médicos
- Tracking GPS en tiempo real
- Mantenimiento de vehículos (ITV, revisiones)
- Tablas maestras (20+ catálogos)
- Informes y analytics

**Stack Tecnológico:**
- **Framework:** Flutter 3.35.3+ | Dart 3.9.2+
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Real-Time)
- **UI Framework:** Material Design 3
- **State Management:** BLoC + Freezed + Equatable
- **DI:** GetIt + Injectable
- **Navigation:** GoRouter (~80+ rutas)
- **Supabase Project ID:** `ycmopmnrhrpnnzkvnihr`

### Problema Detectado

El archivo `CLAUDE.md` actual es una **plantilla de Content Engine App** (otro proyecto) que no corresponde a AmbuTrack. Esto causa confusión en:

1. **UI Framework:** CLAUDE.md dice "Cupertino" pero AmbuTrack usa **Material Design 3**
2. **Arquitectura:** Referencias a `content_engine_app/` en lugar de `ambutrack_web/`
3. **Stack:** Referencias a n8n que no se usan en AmbuTrack

## 📁 Estado de Archivos .claude

### ✅ Archivos Correctos (Mantener)

| Archivo | Estado | Notas |
|---------|--------|-------|
| `agents/_AGENT_COMMON.md` | ✅ Correcto | Reglas comunes (actualizar para AmbuTrack) |
| `agents/supabase_specialist.md` | ✅ Correcto | Especialista Supabase |
| `agents/ambutrack_page_pattern.md` | ✅ Correcto | Patrón de páginas AmbuTrack |
| `agents/DataSourceAgent.md` | ✅ Correcto | Agente DataSource genérico |
| `agents/datasource.md` | ✅ Correcto | Otro datasource |
| `agents/feature-creator.md` | ✅ Correcto | Creador de features |
| `agents/reviewer.md` | ✅ Correcto | Revisor |
| `agents/bug-fixer.md` | ✅ Correcto | Fix de bugs |
| `agents/refactor.md` | ✅ Correcto | Refactorización |
| `agents/bloc-state.md` | ✅ Correcto | BLoC + State |
| `agents/qa_validation.md` | ✅ Correcto | Validación QA |
| `agents/ui-widget.md` | ✅ Correcto | Widgets UI |
| `agents/UITableStandardAgent.md` | ✅ Correcto | Tablas estándar |
| `hooks/hooks.md` | ✅ Correcto | Hooks obligatorios |
| `memory/CONVENTIONS.md` | ⚠️ Actualizar | Convenciones (viene de FutPlanner) |
| `commands/new-feature.md` | ✅ Correcto | Nuevo feature |
| `commands/lint.md` | ✅ Correcto | Lint |
| `commands/review.md` | ✅ Correcto | Review |
| `commands/test.md` | ✅ Correcto | Test |
| `commands/bloc.md` | ✅ Correcto | BLoC |
| `commands/page.md` | ✅ Correcto | Page |
| `commands/repository.md` | ✅ Correcto | Repository |
| `commands/validate.md` | ✅ Correcto | Validate |
| `commands/design-to-code.md` | ✅ Correcto | Design to code |
| `skills/bloc_freezed.md` | ✅ Correcto | BLoC Freezed |
| `skills/dart_mcp_debug.md` | ✅ Correcto | Dart MCP debug |
| `skills/datasource_integration.md` | ✅ Correcto | DataSource integration |
| `skills/gorouter_navigation.md` | ✅ Correcto | GoRouter navigation |
| `skills/injectable_di.md` | ✅ Correcto | Injectable DI |
| `design/COMPONENT_LIBRARY.md` | ⚠️ Revisar | Librería de componentes |
| `ORCHESTRATOR.md` | ⚠️ Actualizar | Orquestador (viene de FutPlanner) |

### ❌ Archivos Obsoletos (Eliminar o Reemplazar)

| Archivo | Procedencia | Acción |
|---------|-------------|--------|
| `CLAUDE.md` | Content Engine App | 🔄 Reemplazar con AmbuTrack |
| `orchestrator.md` | FutPlanner | 🔄 Actualizar para AmbuTrack |
| `agents/FutPlannerArchitectAgent.md` | FutPlanner | ❌ Eliminar (renombrar a AmbuTrack) |
| `agents/FutPlannerDatasourceAgent.md` | FutPlanner | ❌ Eliminar (renombrar a AmbuTrack) |
| `agents/FutPlannerDesignSystemAgent.md` | FutPlanner | ❌ Eliminar (renombrar a AmbuTrack) |
| `agents/FutPlannerFeatureBuilderAgent.md` | FutPlanner | ❌ Eliminar (renombrar a AmbuTrack) |
| `agents/FutPlannerQAValidatorAgent.md` | FutPlanner | ❌ Eliminar (renombrar a AmbuTrack) |
| `agents/FutPlannerUIDesignerAgent.md` | FutPlanner | ❌ Eliminar (renombrar a AmbuTrack) |
| `design/PROJECT_CONTEXT.md` | FutPlanner | 🔄 Reemplazar con AmbuTrack |
| `design/DESIGN_SYSTEM.md` | FutPlanner | 🔄 Reemplazar con AmbuTrack |
| `agents/apple_design.md` | Otro proyecto | ❌ Eliminar (AmbuTrack usa Material) |
| `agents/uiux_designer.md` | Otro proyecto | ⚠️ Revisar |
| `agents/dSAgent.md` | Otro proyecto | ⚠️ Revisar |
| `agents/iaut_design_system_agent.md` | Otro proyecto | ⚠️ Revisar |
| `commands/feature.md` | FutPlanner | 🔄 Actualizar para AmbuTrack |
| `commands/plan.md` | FutPlanner | 🔄 Actualizar para AmbuTrack |
| `commands/prd.md` | FutPlanner | 🔄 Actualizar para AmbuTrack |
| `ui-adapter.md` | Otro proyecto | ⚠️ Revisar |
| `quickstart.md` | FutPlanner | 🔄 Actualizar para AmbuTrack |

### ⚠️ Archivos en Ubicación Incorrecta

| Archivo | Ubicación Actual | Ubicación Correcta |
|---------|------------------|-------------------|
| `plans/*.md` (18 archivos) | `.claude/plans/` | `docs/plans/` |

## 🎯 Plan de Acción

### Fase 1: Limpieza de Archivos Obsoletos

1. **Eliminar agentes de FutPlanner:**
   - `FutPlannerArchitectAgent.md`
   - `FutPlannerDatasourceAgent.md`
   - `FutPlannerDesignSystemAgent.md`
   - `FutPlannerFeatureBuilderAgent.md`
   - `FutPlannerQAValidatorAgent.md`
   - `FutPlannerUIDesignerAgent.md`
   - `apple_design.md` (AmbuTrack usa Material Design)

2. **Mover planes a ubicación correcta:**
   - Mover todos los archivos de `.claude/plans/` a `docs/plans/`

### Fase 2: Actualización de CLAUDE.md

Crear un nuevo `CLAUDE.md` específico para AmbuTrack con:

1. **Identidad del Proyecto:**
   - Nombre: AmbuTrack Web
   - Descripción: Gestión integral de servicios de ambulancias
   - Stack: Flutter + Supabase + Material Design 3

2. **Stack Tecnológico:**
   - Framework: Flutter 3.35.3+ | Dart 3.9.2+
   - Backend: Supabase (PostgreSQL + Auth + Storage + Real-Time)
   - UI: Material Design 3
   - State: BLoC + Freezed + Equatable
   - DI: GetIt + Injectable
   - Navigation: GoRouter

3. **Reglas Críticas:**
   - AppColors para colores
   - SafeArea obligatorio
   - Sin datos MOCK (usar Supabase)
   - Material Design 3 (NO Cupertino)
   - Pass-through en repositorios
   - Badges ajustados al texto
   - Diálogos profesionales
   - `flutter analyze` obligatorio → 0 warnings

4. **Arquitectura Clean:**
   - Entities en `packages/ambutrack_core_datasource/`
   - Repository pass-through
   - BLoC con Freezed
   - Pages con SafeArea
   - GoRouter para navegación

5. **Sistema Multi-Agente:**
   - AmbuTrackArchitectAgent
   - AmbuTrackDatasourceAgent
   - AmbuTrackFeatureBuilderAgent
   - AmbuTrackUIDesignerAgent
   - AmbuTrackQAValidatorAgent
   - SupabaseSpecialist

### Fase 3: Actualización de Orchestador

Crear `ORCHESTRATOR.md` específico para AmbuTrack con:

1. **Matriz de Agentes:**
   - ArchitectAgent → Validar estructura
   - DatasourceAgent → Entity/DataSource
   - FeatureBuilderAgent → Repository/BLoC
   - UIDesignerAgent → Page/Widget/UI
   - QAValidatorAgent → Validación
   - SupabaseSpecialist → Tablas/RLS/SQL

2. **Flujo Feature E2E:**
   - Paso 1: ArchitectAgent (validar)
   - Paso 2: DatasourceAgent (Entity si no existe)
   - Paso 3: FeatureBuilderAgent (Repository + BLoC)
   - Paso 4: UIDesignerAgent (Pages + Widgets)
   - Paso 5: QAValidatorAgent (validación final)

3. **Modelos Recomendados:**
   - ArchitectAgent: `haiku`
   - DatasourceAgent: `sonnet`
   - FeatureBuilderAgent: `sonnet`
   - UIDesignerAgent: `sonnet`
   - QAValidatorAgent: `haiku`
   - SupabaseSpecialist: `sonnet`

### Fase 4: Actualización de Convenciones

Actualizar `memory/CONVENTIONS.md` con:

1. **Arquitectura AmbuTrack:**
   - Material Design 3 (NO Cupertino)
   - AppColors para colores
   - SafeArea obligatorio
   - Widgets como clases (NO métodos _buildXxx)

2. **Colores:**
   - AppColors.primary (Azul médico #1E40AF)
   - AppColors.secondary (Verde médico #059669)
   - AppColors.success, warning, error, info
   - AppColors.emergency (Rojo #DC2626)

3. **Repository Pass-Through:**
   - UN solo import del core
   - Sin conversiones Entity ↔ Entity
   - Logging con debugPrint

4. **UI Material 3:**
   - FilledButton, TextButton, OutlinedButton
   - TextField, Card, CircularProgressIndicator
   - Scaffold, AppBar, NavigationBar
   - Theme.of(context).colorScheme

### Fase 5: Actualización de Sistema de Diseño

Crear `design/DESIGN_SYSTEM.md` específico para AmbuTrack con:

1. **Brand Identity:**
   - Personalidad: Profesional, confiable, eficiente
   - Valores: Seguridad, eficiencia, compasión
   - Tagline: "Gestión integral de servicios médicos de emergencia"

2. **Color Palette:**
   - Primary: Azul médico #1E40AF
   - Secondary: Verde médico #059669
   - Success: #10B981
   - Warning: #F59E0B
   - Error: #EF4444
   - Emergency: #DC2626

3. **Typography:**
   - Font: Google Fonts (Inter)
   - Scale: display, h1, h2, h3, body, caption

4. **Componentes:**
   - Buttons, Inputs, Cards, Tables
   - Badges, Status, Dialogs

### Fase 6: Actualización de Contexto del Proyecto

Crear `design/PROJECT_CONTEXT.md` específico para AmbuTrack con:

1. **Project Overview:**
   - Descripción de AmbuTrack
   - Misión y Visión
   - Target Users

2. **Features:**
   - Flota de ambulancias
   - Personal sanitario
   - Servicios médicos
   - Tracking GPS
   - Mantenimiento
   - Tablas maestras

3. **Technical Stack:**
   - Flutter + Supabase
   - Material Design 3
   - BLoC pattern

### Fase 7: Actualización de Comandos

Actualizar comandos específicos para AmbuTrack:

1. `/feature [nombre]` → Feature E2E completo
2. `/bloc [tipo] [nombre]` → Solo BLoC
3. `/page [tipo] [nombre]` → Solo Page
4. `/repository [nombre]` → Solo Repository
5. `/validate [nombre]` → Validar feature
6. `/prd [título]` → Crear PRD en Trello
7. `/plan [card-id]` → Plan desde Trello → `docs/plans/`

### Fase 8: Verificación Final

1. ✅ Verificar que todos los agentes tienen instrucciones correctas
2. ✅ Verificar que los comandos funcionan correctamente
3. ✅ Verificar que los hooks están configurados
4. ✅ Verificar que MCP Supabase está disponible
5. ✅ Ejecutar `flutter analyze` → 0 warnings
6. ✅ Verificar que la documentación está actualizada

## 📊 Checklist de Preparación

- [ ] Fase 1: Limpieza de archivos obsoletos
- [ ] Fase 2: Actualización de CLAUDE.md
- [ ] Fase 3: Actualización de Orchestador
- [ ] Fase 4: Actualización de Convenciones
- [ ] Fase 5: Actualización de Sistema de Diseño
- [ ] Fase 6: Actualización de Contexto del Proyecto
- [ ] Fase 7: Actualización de Comandos
- [ ] Fase 8: Verificación Final

## 🎯 Resultado Esperado

Al finalizar este plan, el proyecto estará:

1. ✅ **Libre de archivos obsoletos** de otros proyectos
2. ✅ **Configurado con instrucciones correctas** para AmbuTrack
3. ✅ **Con agentes especializados** para AmbuTrack
4. ✅ **Con comandos funcionales** específicos para AmbuTrack
5. ✅ **Con documentación actualizada** y coherente
6. ✅ **Listo para desarrollo eficiente** con Claude Code

---

**Estado:** 🟡 En progreso
**Siguiente paso:** Ejecutar Fase 1 - Limpieza de archivos obsoletos
