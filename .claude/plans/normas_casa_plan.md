# Plan: Feature Normas de la Casa (Guest)

## Resumen
Feature para que los huéspedes puedan ver las normas de la casa de la propiedad donde se hospedan.

## Alcance
- **Rol**: Guest (huésped)
- **Funcionalidades**: Listado de normas (solo lectura)
- **Nivel**: Por propiedad (property_id)

## Estructura de Archivos

```
lib/features/guest/house_rules/
├── data/
│   └── repositories/
│       └── house_rules_repository_impl.dart
├── domain/
│   ├── bloc/
│   │   └── house_rules_bloc.dart
│   ├── entities/
│   │   └── house_rule_entity.dart
│   └── repositories/
│       └── house_rules_repository.dart
├── presentation/
│   ├── screens/
│   │   └── house_rules_screen.dart
│   └── widgets/
│       └── house_rule_card.dart
└── routes/
    └── house_rules_route.dart
```

## Tabla Supabase (NUEVA)

### house_rules
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| property_id | uuid | FK → properties |
| title | text | Título de la norma |
| description | text | Descripción detallada |
| icon | text | Nombre del icono (ej: 'no_smoking', 'quiet_hours') |
| category | text | Categoría (ruido, limpieza, seguridad, general) |
| sort_order | int | Orden de visualización |
| is_active | bool | Si la norma está activa |
| created_at | timestamptz | Fecha creación |
| updated_at | timestamptz | Fecha actualización |

### SQL para crear la tabla
```sql
CREATE TABLE house_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'info',
    category TEXT DEFAULT 'general',
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_house_rules_property_id ON house_rules(property_id);
CREATE INDEX idx_house_rules_category ON house_rules(category);
CREATE INDEX idx_house_rules_sort_order ON house_rules(sort_order);

-- RLS (Row Level Security)
ALTER TABLE house_rules ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden leer normas activas
CREATE POLICY "Anyone can read active house rules"
ON house_rules FOR SELECT
USING (is_active = true);
```

## Entidad

### HouseRuleEntity
```dart
class HouseRuleEntity extends Equatable {
  final String id;
  final String propertyId;
  final String title;
  final String? description;
  final String icon;
  final String category;
  final int sortOrder;
  final bool isActive;

  // Getters
  bool get hasDescription => description != null && description!.isNotEmpty;
  String get categoryName => _getCategoryDisplayName(category);

  // Métodos
  static String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'noise': return 'Silencio';
      case 'cleanliness': return 'Limpieza';
      case 'safety': return 'Seguridad';
      case 'general': return 'General';
      default: return 'Otro';
    }
  }
}
```

### Categorías predefinidas
| Valor | Display | Icono sugerido |
|-------|---------|----------------|
| noise | Silencio | `Icons.volume_off` |
| cleanliness | Limpieza | `Icons.cleaning_services` |
| safety | Seguridad | `Icons.security` |
| general | General | `Icons.info` |

### Iconos predefinidos
| Valor | Descripción | Icono Flutter |
|-------|-------------|---------------|
| no_smoking | Prohibido fumar | `Icons.smoke_free` |
| no_pets | No mascotas | `Icons.pets_off` |
| no_parties | No fiestas | `Icons.music_off` |
| quiet_hours | Horas de silencio | `Icons.bedtime` |
| no_visitors | No visitantes | `Icons.person_off` |
| no_shoes | Sin zapatos | `Icons.no_shoes` |
| wifi_password | WiFi | `Icons.wifi` |
| checkout_time | Hora de salida | `Icons.schedule` |
| garbage | Basura | `Icons.delete` |
| air_conditioning | Aire acondicionado | `Icons.ac_unit` |
| heating | Calefacción | `Icons.thermostat` |
| pool | Piscina | `Icons.pool` |
| keys | Llaves | `Icons.key` |
| info | Información | `Icons.info` |

## BLoC

### Events
- `HouseRulesStarted` - Inicialización con propertyId
- `HouseRulesLoadRequested` - Cargar normas
- `HouseRulesRefreshRequested` - Refrescar lista

### States
- `HouseRulesInitial` - Estado inicial
- `HouseRulesLoading` - Cargando
- `HouseRulesLoaded` - Datos cargados (con lista de normas y agrupadas por categoría)
- `HouseRulesError` - Error

## Pantalla

### HouseRulesScreen
- AppBar con título "Normas de la Casa"
- Lista agrupada por categoría
- Cada norma en una tarjeta con icono, título y descripción
- Pull to refresh
- Estado vacío si no hay normas
- Animación de entrada para las tarjetas

### Diseño de tarjeta (HouseRuleCard)
```
┌─────────────────────────────────────┐
│  [Icono]   │  Título de la norma    │
│            │  Descripción opcional  │
└─────────────────────────────────────┘
```

## Rutas
- `/guest/house-rules` - Listado de normas
- `/guest/house-rules/:propertyId` - Normas de una propiedad específica

## Orden de Implementación
1. Crear tabla en Supabase (ejecutar SQL)
2. Añadir constante en `SupabaseTables`
3. Crear entidad `HouseRuleEntity`
4. Crear contrato del repositorio `HouseRulesRepository`
5. Crear implementación `HouseRulesRepositoryImpl`
6. Crear BLoC (`HouseRulesBloc` con events y states)
7. Crear widget `HouseRuleCard`
8. Crear pantalla `HouseRulesScreen`
9. Registrar repositorio en `injection.dart`
10. Añadir ruta en `app_router.dart`
11. Ejecutar `dart fix --apply && dart analyze`

## Consideraciones
- Los huéspedes solo pueden ver normas activas
- Ordenar por `sort_order` y luego por `created_at`
- Usar `AppColors` para colores
- Responsive para móvil y tablet
- Iconos con color según categoría
- Animaciones sutiles para mejorar UX

## Dependencias
- `flutter_bloc` - State management
- `equatable` - Comparación de entidades
- `supabase_flutter` - Backend
- `go_router` - Navegación
- `google_fonts` - Tipografía (Poppins)
