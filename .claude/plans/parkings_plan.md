# Plan de Implementación: Feature Parkings

## Resumen
Feature para mostrar parkings cercanos a los alojamientos de BF Stay en Jerez Centro.

## Estructura de Base de Datos

### Tabla `parkings`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| name | text | Nombre del parking |
| address_text | text | Dirección completa |
| phone | text | Teléfono (nullable) |
| provider | text | Proveedor/tipo |
| lat | float | Latitud (nullable) |
| lng | float | Longitud (nullable) |
| google_maps_url | text | URL Google Maps |
| apple_maps_url | text | URL Apple Maps |
| is_active | bool | Activo/inactivo |

### Tabla `unit_parkings`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| unit_id | uuid | FK -> units.id |
| parking_id | uuid | FK -> parkings.id |
| priority | int | Orden de recomendación (0 = más cercano) |
| notes | text | Notas adicionales |

## Arquitectura de Archivos

```
lib/features/guest/parkings/
├── domain/
│   ├── entities/
│   │   ├── parking_entity.dart
│   │   └── unit_parking_entity.dart
│   ├── repositories/
│   │   └── parkings_repository.dart
│   └── bloc/
│       └── parkings_bloc.dart
├── data/
│   └── repositories/
│       └── parkings_repository_impl.dart
└── presentation/
    ├── screens/
    │   └── parkings_screen.dart
    └── widgets/
        └── parking_card.dart
```

## Flujo de Pantalla

1. Usuario accede desde la guía de estancia o menú
2. Se cargan los parkings asociados a la unidad actual del huésped
3. Se muestran ordenados por prioridad (más cercanos primero)
4. Cada tarjeta muestra:
   - Nombre del parking
   - Dirección
   - Teléfono (si existe)
   - Botones para abrir en Google Maps / Apple Maps
   - Notas específicas para ese alojamiento

## Dependencias
- `supabase_flutter` para datos
- `flutter_bloc` para estado
- `url_launcher` para abrir maps

## Rutas
- `/guest/parkings` - Lista de parkings
- `/guest/parkings/:unitId` - Parkings para una unidad específica

## Seed Data - Parkings Jerez Centro

### Parkings principales identificados:
1. Parking Plaza del Arenal (público, cercano a todos)
2. Parking C/ Larga (público, centro histórico)
3. Parking Mercado Central (público)
4. Parking C/ Porvera (público)
5. Parking Estación de Tren (público, 10 min andando)
6. Parking Centro Comercial Área Sur (privado, más lejos)

### Unidades BF Stay:
| ID | Nombre | Dirección |
|----|--------|-----------|
| bf000000-0000-0000-0001-000000000001 | Hotel Boutique Jerez | C/ José Luis Díez, 8 |
| bf000000-0000-0000-0001-000000000002 | Jacuzzi Jerez | C/ Hijuela, 2 |
| bf000000-0000-0000-0001-000000000003 | Apartamento BF Jerez | C/ Hijuela, 2 |
| bf000000-0000-0000-0001-000000000004 | Apartamento Bandera | C/ Prieta, 4 |
| bf000000-0000-0000-0001-000000000005 | Ático Jerez | C/ Hijuela, 2 |
| bf000000-0000-0000-0001-000000000006 | BF Jacuzzi Jerez | C/ Hijuela, 2 |

## Checklist de Implementación
- [ ] Crear entidades (ParkingEntity, UnitParkingEntity)
- [ ] Crear contrato de repositorio
- [ ] Crear implementación de repositorio
- [ ] Crear BLoC con events/states
- [ ] Crear pantalla principal
- [ ] Crear widget ParkingCard
- [ ] Actualizar rutas en app_router.dart
- [ ] Actualizar supabase_tables.dart
- [ ] Generar SQL seed
- [ ] Ejecutar dart fix --apply && dart analyze
