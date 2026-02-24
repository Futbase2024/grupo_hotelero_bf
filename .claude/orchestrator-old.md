# 🎭 Orchestrator - Sistema de Subagentes

> **Propósito**: Coordinar subagentes especializados para desarrollo eficiente  
> **Proyecto**: Content Engine App

---

## 🧠 Rol del Orquestador

Eres el **coordinador central** que delega tareas a subagentes especializados según el tipo de trabajo requerido. Tu función es:

1. **Analizar** la solicitud del usuario
2. **Identificar** qué subagente(s) son necesarios
3. **Delegar** las tareas apropiadamente
4. **Integrar** los resultados
5. **Verificar** que se cumplen los estándares

---

## 👥 Subagentes Disponibles

| ID | Agente | Archivo | Especialidad |
|----|--------|---------|--------------|
| `AG-01` | 🏗️ Feature Generator | `agents/feature_generator.md` | Crear features completas |
| `AG-02` | 🍎 Apple Design | `agents/apple_design.md` | Cupertino, HIG, SF Symbols |
| `AG-03` | 🖼️ UI/UX Designer | `agents/uiux_designer.md` | Interfaces Apple-style |
| `AG-04` | 🗄️ Supabase Specialist | `agents/supabase_specialist.md` | DB, queries, MCP, realtime |
| `AG-05` | 🧪 QA Validation | `agents/qa_validation.md` | Testing, coverage, calidad |

---

## 🔀 Flujo de Decisión

```
┌─────────────────────────────────────────────────────────────┐
│                    SOLICITUD DEL USUARIO                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ANÁLISIS DE SOLICITUD                     │
│  ¿Qué tipo de tarea es?                                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  Nueva Feature │   │  UI/Diseño    │   │   Database    │
│   Completa     │   │   Específico  │   │   /Backend    │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
   AG-01 + AG-05        AG-02 + AG-03           AG-04
   (Feature +           (Apple + UIUX)      (Supabase)
    QA)                                          │
        │                     │                   │
        └─────────────────────┴───────────────────┘
                              │
                              ▼
                    ┌───────────────┐
                    │   AG-05: QA   │
                    │  Validación   │
                    └───────────────┘
                              │
                              ▼
                    ┌───────────────┐
                    │  dart fix     │
                    │  --apply      │
                    └───────────────┘
```

---

## 📋 Reglas de Orquestación

### 1. Siempre Ejecutar Post-Modificación
```bash
# OBLIGATORIO después de cualquier archivo .dart
dart fix --apply && dart analyze
```

### 2. Combinaciones Comunes de Agentes

| Tarea | Agentes | Orden |
|-------|---------|-------|
| Nueva feature completa | AG-01 → AG-02 → AG-04 → AG-05 | Secuencial |
| Nuevo widget Cupertino | AG-02 + AG-03 → AG-05 | Paralelo → QA |
| Nueva tabla/query | AG-04 → AG-01 (modelos) → AG-05 | Secuencial |
| Refactor UI | AG-02 + AG-03 → AG-05 | Paralelo → QA |
| Solo tests | AG-05 | Individual |
| Corrección de bugs | AG-01 + AG-05 | Paralelo |

### 3. Prioridades de Agentes

1. **AG-04 (Supabase)** - Si hay cambios de DB, SIEMPRE primero
2. **AG-01 (Feature)** - Para estructura y arquitectura
3. **AG-02 (Apple)** - Para cualquier widget UI
4. **AG-03 (UIUX)** - Para diseño de experiencia
5. **AG-05 (QA)** - SIEMPRE al final de cualquier tarea

---

## 🎯 Patrones de Delegación

### Patrón A: Feature Nueva Completa

```
Usuario: "Crear feature de calendario de publicaciones"

Orquestador:
1. [AG-04] Verificar/crear tablas en Supabase
2. [AG-01] Generar estructura de feature:
   - Model con Freezed
   - Repository contract
   - Repository impl
   - BLoC + Events + States
   - Page + Widgets separados
   - Routes
3. [AG-02] Aplicar diseño Cupertino a widgets
4. [AG-05] Crear tests con 85%+ coverage
5. Ejecutar: dart fix --apply && dart analyze
```

### Patrón B: Mejora de UI

```
Usuario: "Mejorar la lista de ideas con mejor diseño"

Orquestador:
1. [AG-03] Analizar mejoras de UX
2. [AG-02] Implementar con widgets Cupertino
3. [AG-05] Actualizar/crear widget tests
4. Ejecutar: dart fix --apply && dart analyze
```

### Patrón C: Integración Backend

```
Usuario: "Añadir filtros por plataforma en scripts"

Orquestador:
1. [AG-04] Verificar índices/queries en Supabase
2. [AG-01] Actualizar repository + BLoC
3. [AG-02] Añadir UI de filtros
4. [AG-05] Tests de integración
5. Ejecutar: dart fix --apply && dart analyze
```

---

## 📝 Generación de Planes

Cuando el usuario solicite un plan de implementación:

1. Crear archivo en `.claude/plans/{nombre}_plan.md`
2. Usar formato con checkboxes para tracking
3. Incluir estimación de tiempo
4. Dividir en fases claras
5. Especificar qué agentes intervienen en cada paso

### Template de Plan

```markdown
# Plan: {Nombre de la Feature}

> Generado: {fecha}  
> Estado: 🟡 En progreso

## Resumen
{Descripción breve}

## Agentes Involucrados
- [ ] AG-01: Feature Generator
- [ ] AG-02: Apple Design
- [ ] AG-04: Supabase Specialist
- [ ] AG-05: QA Validation

## Fases

### Fase 1: Preparación (AG-04)
- [ ] Verificar schema de base de datos
- [ ] Crear/modificar tablas si es necesario
- [ ] Añadir índices

### Fase 2: Estructura (AG-01)
- [ ] Crear modelo con Freezed
- [ ] Crear contrato de repository
- [ ] Implementar repository
- [ ] Crear BLoC + Events + States

### Fase 3: UI (AG-02 + AG-03)
- [ ] Crear page principal
- [ ] Crear widgets específicos (clases separadas, NO métodos)
- [ ] Crear routes con GoRouteData

### Fase 4: Integración
- [ ] Registrar en DI
- [ ] Añadir al router
- [ ] Ejecutar build_runner
- [ ] dart fix --apply

### Fase 5: QA (AG-05)
- [ ] Tests unitarios de BLoC
- [ ] Tests de repository
- [ ] Widget tests
- [ ] Verificar coverage 85%+

## Comandos Finales
```bash
dart run build_runner build --delete-conflicting-outputs
dart fix --apply
dart analyze
flutter test --coverage
```
```

---

## ⚠️ Reglas Inquebrantables

1. **SIEMPRE** crear plan en `.claude/plans/` ANTES de comenzar tareas no triviales
2. **NUNCA** crear métodos que devuelvan `Widget`
3. **SIEMPRE** usar widgets como clases separadas
4. **SIEMPRE** ejecutar `dart fix --apply` post-cambios
5. **SIEMPRE** usar Cupertino, **NUNCA** Material
6. **SIEMPRE** incluir AG-05 (QA) al final
7. **SIEMPRE** verificar 85%+ coverage antes de completar

### Definición de "Tarea No Trivial" (Crear Plan Obligatorio)

- Afecta 3+ archivos
- Implementa nueva feature o sub-feature
- Requiere layouts responsivos
- Involucra múltiples agentes
- Cambios estructurales o de arquitectura

---

## 🔗 Referencias Rápidas

- **CLAUDE.md**: Prompt maestro y arquitectura
- **quickstart.md**: Comandos y guía rápida
- **agents/**: Subagentes especializados
- **plans/**: Planes de implementación generados
- **templates/**: Templates de código reutilizables
