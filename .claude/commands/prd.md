# /prd

Genera un PRD (Product Requirements Document) y crea una tarjeta en Trello en la lista "Pendientes".

## Uso

```
/prd [título] [descripción de requerimientos]
```

## Ejemplos

```
/prd "Exportar jugadores a CSV" "Como entrenador quiero exportar la lista de jugadores a CSV para compartirla"

/prd "Refactor sistema de notificaciones" "Simplificar el sistema actual eliminando las notificaciones push y dejando solo email"
```

---

## Detección Automática de Tipo

Claude DEBE detectar el tipo de PRD según palabras clave:

### PRD Light (Feature nueva)
**Detectar si contiene**: "nueva", "añadir", "crear", "implementar", "feature", "funcionalidad", "como [usuario] quiero"

### PRD Técnico (Refactor/Cambio complejo)
**Detectar si contiene**: "refactor", "simplificar", "migrar", "eliminar", "cambiar", "mover", "reorganizar", "actualizar arquitectura"

### Si no está claro
Preguntar al usuario:
> "¿Es una feature nueva o un refactor/cambio de algo existente?"

---

## Template: PRD Light (Features nuevas)

```markdown
## PRD Light - [Título]

### Descripción
[1-2 párrafos explicando qué es y qué problema resuelve]

### Objetivo
[Objetivo principal en una oración]

### Usuario Objetivo
[Entrenador / Coordinador / Admin]

### Funcionalidades
- [ ] [Funcionalidad 1]
- [ ] [Funcionalidad 2]
- [ ] [Funcionalidad 3]
- [ ] [Funcionalidad 4]

### Stack Técnico (estimado)
- **Entity**: [Nueva / Existente: NombreEntity]
- **DataSource**: [Nuevo / Existente: NombreDataSource]
- **Repository**: [nombre]_repository.dart
- **BLoC**: [nombre]_bloc.dart
- **Pages**: [lista de páginas]

### Archivos Principales (estimados)
- `lib/features/[nombre]/domain/[nombre]_repository.dart`
- `lib/features/[nombre]/presentation/bloc/[nombre]_bloc.dart`
- `lib/features/[nombre]/presentation/pages/[nombre]_page.dart`

### Dependencias
- [Otras features o servicios de los que depende]

### Criterios de Aceptación
- [ ] [Criterio 1]
- [ ] [Criterio 2]
- [ ] [Criterio 3]
- [ ] [Criterio 4]

---
**Prioridad**: [Alta/Media/Baja]
**Complejidad estimada**: [Baja/Media/Alta]
*PRD generado: [fecha]*
```

---

## Template: PRD Técnico (Refactors/Cambios complejos)

```markdown
## PRD: [Título]

## 📋 Resumen Ejecutivo

[2-3 párrafos explicando el objetivo del refactor y por qué es necesario]

---

## 🎯 Objetivos

1. **[Objetivo 1]** - [Descripción breve]
2. **[Objetivo 2]** - [Descripción breve]
3. **[Objetivo 3]** - [Descripción breve]

---

## 📊 Estado Actual vs Propuesto

### Estructura ACTUAL:
```
[Estructura de archivos/datos actual]
```

### Estructura PROPUESTA:
```
[Nueva estructura de archivos/datos]
```

---

## 🗑️ Funcionalidades/Archivos a ELIMINAR

### En Datasource (`futplanner_core_datasource`):
- [ ] `[archivo].dart` - [Razón]
- [ ] `[archivo].dart` - [Razón]

### En Web App (`futplanner_web`):
- [ ] `[archivo].dart` - [Razón]
- [ ] [Lógica/UI específica a eliminar]

---

## ✅ Funcionalidades a MANTENER (simplificadas)

### [Área 1]:
- [Funcionalidad a mantener]
- [Funcionalidad a mantener]

### [Área 2]:
- [Funcionalidad a mantener]

---

## 🔄 Cambios en Código

### [Archivo/Entity principal]:

**ANTES:**
```dart
[código actual]
```

**DESPUÉS:**
```dart
[código propuesto]
```

---

## 📁 Archivos a Modificar

### Datasource (`futplanner_core_datasource`):
1. `[archivo].dart` - [Cambio a realizar]
2. `[archivo].dart` - [Cambio a realizar]

### Web App (`futplanner_web`):
1. `[archivo].dart` - [Cambio a realizar]
2. `[archivo].dart` - [Cambio a realizar]

---

## 🚀 Plan de Implementación

### Fase 1: [Nombre]
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

### Fase 2: [Nombre]
1. [Paso 1]
2. [Paso 2]

### Fase 3: Cleanup
1. Eliminar archivos no usados
2. Ejecutar `dart run build_runner build --delete-conflicting-outputs`
3. Verificar que `flutter analyze` pasa sin errores

---

## ✅ Criterios de Aceptación

- [ ] [Criterio específico 1]
- [ ] [Criterio específico 2]
- [ ] [Criterio específico 3]
- [ ] [Criterio específico 4]
- [ ] [Criterio específico 5]
- [ ] `flutter analyze` sin errores
- [ ] [Tests/validaciones necesarias]

---

## ⚠️ Notas Importantes

- [Nota sobre migración de datos si aplica]
- [Breaking changes]
- [Consideraciones especiales]

---
*PRD creado: [fecha]*
*Versión: 1.0*
```

---

## Workflow de Ejecución

### Paso 1: Detectar Tipo
Analizar el input del usuario para determinar si es:
- **PRD Light**: Feature nueva
- **PRD Técnico**: Refactor/cambio complejo

### Paso 2: Recopilar Información
Si es necesario, hacer preguntas clarificadoras:
- Para PRD Light: "¿Qué usuario principal usará esto?"
- Para PRD Técnico: "¿Puedes describir el estado actual que quieres cambiar?"

### Paso 3: Generar PRD
Usar el template correspondiente y completar con la información del usuario.

### Paso 4: Crear Tarjeta en Trello
Usar `mcp__trello__add_card_to_list`:
- `listId`: `695d4a651b772efad7e241d7` (Pendientes)
- `name`: Título del PRD
- `description`: PRD generado completo

### Paso 5: Confirmar al Usuario
```
## ✅ PRD Creado

**Tipo**: [Light / Técnico]
**Tarjeta**: [Nombre]
**Lista**: Pendientes
**Link**: [URL de Trello]

### Resumen:
- **Objetivo**: [objetivo principal]
- **Funcionalidades/Cambios**: [cantidad]
- **Criterios de aceptación**: [cantidad]

### Siguiente paso
Cuando quieras implementar, ejecuta:
/futplanner-feature [nombre-sugerido]
```

---

## Configuración Trello

- **Board**: FutPlanner (default)
- **Lista destino**: Pendientes (`695d4a651b772efad7e241d7`)

---

## Checklist de Calidad

Antes de crear la tarjeta, Claude DEBE verificar:

### PRD Light:
- [ ] Título claro (max 50 chars)
- [ ] Descripción explica el problema
- [ ] Al menos 3 funcionalidades
- [ ] Stack técnico identificado
- [ ] Al menos 3 criterios de aceptación

### PRD Técnico:
- [ ] Resumen ejecutivo claro
- [ ] Estado actual vs propuesto definido
- [ ] Lista de qué eliminar/mantener
- [ ] Al menos un ejemplo de código ANTES/DESPUÉS
- [ ] Plan de implementación por fases
- [ ] Al menos 5 criterios de aceptación específicos
- [ ] Notas sobre breaking changes si aplican
