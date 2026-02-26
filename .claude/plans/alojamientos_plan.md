# Plan: Feature Alojamientos (Guest)

## Resumen
Feature para que los huéspedes puedan ver el listado de alojamientos disponibles y acceder al detalle de cada uno.

## Alcance
- **Rol**: Guest (huésped)
- **Funcionalidades**: Listado y detalle (solo lectura)

## Estructura de Archivos

```
lib/features/guest/alojamientos/
├── data/
│   └── repositories/
│       └── properties_repository_impl.dart
├── domain/
│   ├── bloc/
│   │   └── alojamientos_bloc.dart
│   ├── entities/
│   │   ├── property_entity.dart
│   │   └── unit_entity.dart
│   └── repositories/
│       └── properties_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── alojamientos_screen.dart
│   │   └── alojamiento_detail_screen.dart
│   └── widgets/
│       ├── property_card.dart
│       └── unit_card.dart
└── routes/
    └── alojamientos_route.dart
```

## Tablas Supabase

### properties
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| name | text | Nombre de la propiedad |
| address | text | Dirección |
| city | text | Ciudad |
| country | text | País (default: ES) |
| timezone | text | Zona horaria |
| lat | double precision | Latitud |
| lng | double precision | Longitud |
| created_at | timestamptz | Fecha creación |

### units
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| property_id | uuid | FK → properties |
| name | text | Nombre (ej: "Apto 2B") |
| unit_type | text | apartment/room |
| box_location_text | text | Ubicación caja llaves |
| box_code | text | Código de acceso |
| access_instructions | text | Instrucciones |
| created_at | timestamptz | Fecha creación |

## Entidades

### PropertyEntity
```dart
class PropertyEntity extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String country;
  final String timezone;
  final double? lat;
  final double? lng;
  final List<UnitEntity> units;
}
```

### UnitEntity
```dart
class UnitEntity extends Equatable {
  final String id;
  final String propertyId;
  final String name;
  final String unitType;
  final String? boxLocationText;
  final String? boxCode;
  final String? accessInstructions;
}
```

## BLoC

### Events
- `AlojamientosStarted` - Inicialización
- `AlojamientosLoadRequested` - Cargar alojamientos
- `AlojamientosRefreshRequested` - Refrescar lista
- `AlojamientosSearchChanged` - Filtrar por búsqueda

### States
- `AlojamientosInitial` - Estado inicial
- `AlojamientosLoading` - Cargando
- `AlojamientosLoaded` - Datos cargados
- `AlojamientosError` - Error

## Pantallas

### AlojamientosScreen
- AppBar con título "Alojamientos"
- Campo de búsqueda
- Lista de propiedades con sus unidades
- Pull to refresh

### AlojamientoDetailScreen
- Información de la propiedad
- Lista de unidades disponibles
- Ubicación en mapa (si tiene coordenadas)
- Información de contacto

## Rutas
- `/guest/alojamientos` - Listado
- `/guest/alojamientos/:id` - Detalle

## Orden de Implementación
1. Entidades (PropertyEntity, UnitEntity)
2. Contrato del repositorio
3. Implementación del repositorio
4. BLoC (events, states, bloc)
5. Widgets (PropertyCard, UnitCard)
6. Pantallas (AlojamientosScreen, AlojamientoDetailScreen)
7. Rutas
8. Registro en DI
9. Integración en AppRouter

## Consideraciones
- Los huéspedes solo pueden ver propiedades publicadas
- No mostrar box_code en listado (solo en detalle con permisos)
- Diseño consistente con el resto de la app (Material Design)
- Usar AppColors para colores
- Responsive para móvil y tablet
