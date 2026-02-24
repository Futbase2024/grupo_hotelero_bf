# /plan Command

Genera un plan técnico completo para una feature/tarea, incluyendo prompt de diseño para Stitch.

---

## Proceso

### 1. Análisis del PRD
- Lee el PRD de Trello o la descripción proporcionada
- Identifica requisitos funcionales y no funcionales
- Extrae user stories y criterios de aceptación

### 2. Arquitectura Técnica
Siguiendo Clean Architecture de FutPlanner:
```
lib/features/{feature_name}/
├── domain/
│   └── {feature}_repository.dart    # Clase concreta con @LazySingleton
└── presentation/
    ├── bloc/
    │   ├── {feature}_bloc.dart      # @injectable
    │   ├── {feature}_event.dart     # @freezed
    │   └── {feature}_state.dart     # @freezed
    ├── pages/
    │   └── {feature}_page.dart
    ├── layouts/
    │   ├── {feature}_mobile_layout.dart
    │   ├── {feature}_tablet_layout.dart
    │   └── {feature}_desktop_layout.dart
    └── widgets/
        └── {feature}_card.dart
```

**⚠️ PROHIBIDO:**
- ❌ `data/` en features (excepto app_config, legal)
- ❌ `domain/entities/` (usar `futplanner_core_datasource`)
- ❌ `domain/usecases/` (lógica va en Repository o BLoC)

### 3. Definición de Entidades
- Entities con Freezed en `packages/futplanner_core_datasource/`
- NO crear entities dentro de la feature
- Si la Entity no existe → DatasourceAgent la crea en el paquete externo

### 4. Repository Pattern
- Clase concreta con `@LazySingleton()` en `domain/`
- Inyecta DataSource via constructor (DI con getIt)
- DataSources en `futplanner_core_datasource` (Supabase)
- Para datos externos: usar `CacheDataSource` (cache-first, llama a api.futplanner.com)

### 5. BLoC State Management
- Events (`@freezed`)
- States (`@freezed`) — **CRÍTICO:** `State.loading` DEBE tener `message` con `@Default`
- BLoC con `@injectable` y manejo de errores
- LoadingOverlay obligatorio en UI

### 6. UI Components (Material Design 3)
- Pages con `AppLayoutBuilder` (3 layouts obligatorios: mobile, tablet, desktop)
- Widgets extraídos como clases (❌ NO métodos `_buildXxx()`)
- Material 3: `Scaffold`, `AppBar`, `FilledButton`, `Card`, etc.
- Colores via `Theme.of(context).colorScheme` (❌ NO hardcoded)
- Textos via `context.lang` (❌ NO strings hardcoded)
- Paridad funcional mobile-desktop obligatoria
- Widgets M3 propios: `FMCard`, `FMChip`, `FMEmptyState` de `lib/core/ui/widgets/`

### 7. Testing Strategy
- Unit tests para Repository y BLoC
- Widget tests para componentes clave
- Mocks para datasources externos

### 8. Fases de Implementación
Dividir en fases incrementales con verificación

---

## 9. Generación de Diseños en Google Stitch (AUTOMÁTICO via MCP)

> Los diseños se generan automáticamente usando el MCP de Stitch.
> Consultar protocolo completo en `~/.claude/commands/plan.md` → Paso 6.

### Cuándo Generar Diseño

| Situación | ¿Generar en Stitch? |
|-----------|:-------------------:|
| Feature con pantallas nuevas | Si |
| Feature solo backend/lógica | No (saltar este paso) |
| Modificación menor de UI existente | No |
| Nuevo flujo o experiencia de usuario | Si |

### Configuración Stitch para FutPlanner

```json
{
  "stitch": {
    "projectId": "10448117637612065749",
    "deviceType": "DESKTOP",
    "modelId": "GEMINI_3_PRO"
  }
}
```

### Proceso

1. **Leer Design System** (OBLIGATORIO antes de generar prompts):
   - `.claude/design/DESIGN_SYSTEM.md` → Tokens, colores, tipografía
   - `.claude/design/COMPONENT_LIBRARY.md` → Componentes existentes
   - `.claude/design/PROJECT_CONTEXT.md` → Contexto del proyecto

2. **Identificar pantallas a generar** del análisis del PRD

3. **Construir prompt por pantalla** con Design System de FutPlanner:

```
Design a [screen description] for FutPlanner.

Design System:
- Theme: Light Mode (OBLIGATORIO)
- Background: #F5F5F5 (page), #FFFFFF (cards), #FAFAFA (sections)
- Primary: #5DB075 (green), Secondary: #3D7A4A (dark green)
- Text: #1F2937 (primary), #6B7280 (secondary), #9CA3AF (muted)
- Borders: #E5E7EB, radius 12px (cards), 8px (inputs)
- Font: Manrope (headings bold/extrabold, body normal/medium)
- Shadows: shadow-sm (cards), shadow-xl (modals only)
- Icons: Material Symbols

Screen: [Nombre]

[Descripción detallada]

Components:
- [Lista del análisis UI]

Existing components to reference:
- [Componentes de COMPONENT_LIBRARY.md que aplican]

States: loaded, empty (illustration + CTA), loading (skeleton)

Layout: Desktop (1280px wide), Bento Box grid
```

4. **Ejecutar generación via MCP** (una pantalla a la vez):

```
mcp__stitch__generate_screen_from_text(
  projectId: "10448117637612065749",
  prompt: "[prompt]",
  deviceType: "DESKTOP",
  modelId: "GEMINI_3_PRO"
)
```

5. **Guardar resultados**:
   - HTML en `doc/design/{feature}/{screen_name}.html`
   - Prompts en `doc/design/{feature}/{feature}_stitch_prompts.md`

6. **Preguntar antes de cada pantalla adicional**

### Notas FutPlanner

- **NO repetir** Design System completo en cada prompt — referenciar
- Referenciar componentes de COMPONENT_LIBRARY.md antes de diseñar nuevos
- Mantener prompts concisos (~50-100 líneas máximo)
- Crear carpeta `doc/design/{feature}/` automáticamente
- Actualizar `COMPONENT_LIBRARY.md` después de implementar nuevos componentes

---

## Output del Comando /plan

### Archivos Generados

| Archivo | Ubicación | Contenido |
|---------|-----------|-----------|
| Plan Técnico | `doc/plans/PLAN_{feature_name}.md` | Arquitectura, entidades, fases |
| Diseños HTML | `doc/design/{feature_name}/*.html` | HTML generados por Stitch |
| Prompts Stitch | `doc/design/{feature_name}/{feature_name}_stitch_prompts.md` | Prompts usados (trazabilidad) |

### Flujo Completo Post-Plan
```
/plan {feature}
    │
    ├──► doc/plans/PLAN_{feature}.md
    │
    ├──► Stitch MCP genera pantallas automáticamente
    │       ↓
    ├──► doc/design/{feature}/*.html (HTMLs guardados)
    │
    └──► doc/design/{feature}/{feature}_stitch_prompts.md
              │
              ▼
         /design-to-code {feature}
              │
              ▼
         Implementación en código Flutter
              │
              ▼
         Actualizar COMPONENT_LIBRARY.md
```