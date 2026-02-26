# Plan: Feature "¿Qué ver?" - BF Stay

> **Fecha**: 2026-02-25
> **Feature**: Guía turística premium de Jerez y alrededores
> **Estado**: Planificación

---

## 1. Resumen

Feature de guía turística para huéspedes con:
- **40 lugares/experiencias** curados (16 Jerez + 12 Alrededores + 12 Provincia)
- **11 categorías**: cultura, monumentos, gastronomía, enoturismo, flamenco, naturaleza, familias, compras, experiencias, playa, pueblos_blancos
- **3 colecciones**: "Imprescindibles en 1 día", "Plan romántico", "Gastronomía y vino"
- **Filtrado** por categoría y nivel geográfico
- **Detalle** de cada lugar con imágenes, tips, horarios, precios

---

## 2. Estructura de Archivos

```
lib/features/guest/que_ver/
├── domain/
│   ├── entities/
│   │   ├── place_entity.dart           # Lugar/experiencia
│   │   └── collection_entity.dart      # Colección curada
│   ├── repositories/
│   │   └── places_repository.dart      # Contrato
│   └── bloc/
│       └── que_ver_bloc.dart           # Events + States + BLoC
├── data/
│   └── repositories/
│       └── places_repository_impl.dart # Implementación Supabase
├── presentation/
│   ├── screens/
│   │   ├── que_ver_screen.dart         # Lista principal
│   │   ├── place_detail_screen.dart    # Detalle de lugar
│   │   └── collection_screen.dart      # Vista de colección
│   └── widgets/
│       ├── place_card.dart             # Tarjeta de lugar
│       ├── category_filter_chip.dart   # Chip de categoría
│       ├── level_filter_chip.dart      # Chip de nivel (jerez/alrededores/provincia)
│       └── collection_card.dart        # Tarjeta de colección
└── routes/
    └── que_ver_routes.dart             # Definición de rutas
```

---

## 3. Modelo de Datos

### 3.1 Tabla Supabase: `places`

```sql
CREATE TABLE places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id VARCHAR(100) UNIQUE NOT NULL,  -- "jerez-alcazar"
  level VARCHAR(20) NOT NULL,                 -- 'jerez' | 'alrededores' | 'provincia'
  title VARCHAR(200) NOT NULL,
  short_description TEXT NOT NULL,
  long_description TEXT NOT NULL,
  categories TEXT[] NOT NULL,                 -- ['cultura', 'monumentos']
  recommended_duration_minutes INTEGER,
  best_time_to_visit VARCHAR(100),
  price_level VARCHAR(20),                    -- 'gratis' | '€' | '€€' | '€€€'
  address TEXT,
  geo_lat DECIMAL(10, 8),
  geo_lng DECIMAL(11, 8),
  booking_url TEXT,
  website_url TEXT,
  tips TEXT[] NOT NULL,
  tags TEXT[] NOT NULL,
  image_url TEXT,                             -- URL imagen principal
  image_alt TEXT,
  image_search_queries TEXT[],
  image_generation_prompts TEXT[],
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices
CREATE INDEX idx_places_level ON places(level);
CREATE INDEX idx_places_categories ON places USING GIN(categories);
CREATE INDEX idx_places_active ON places(is_active);
```

### 3.2 Tabla Supabase: `collections`

```sql
CREATE TABLE collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id VARCHAR(100) UNIQUE NOT NULL,  -- "imprescindibles-1-dia"
  title VARCHAR(200) NOT NULL,
  description TEXT,
  level VARCHAR(20),                          -- Nivel predominante
  place_ids UUID[] NOT NULL,                  -- Array de IDs de places
  image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices
CREATE INDEX idx_collections_active ON collections(is_active);
```

### 3.3 Entity: PlaceEntity

```dart
class PlaceEntity extends Equatable {
  final String id;
  final String externalId;
  final PlaceLevel level;
  final String title;
  final String shortDescription;
  final String longDescription;
  final List<String> categories;
  final int? recommendedDurationMinutes;
  final String? bestTimeToVisit;
  final PriceLevel? priceLevel;
  final String? address;
  final double? geoLat;
  final double? geoLng;
  final String? bookingUrl;
  final String? websiteUrl;
  final List<String> tips;
  final List<String> tags;
  final String? imageUrl;
  final String? imageAlt;
  final int sortOrder;
  final bool isActive;
}

enum PlaceLevel { jerez, alrededores, provincia }
enum PriceLevel { gratis, unEuro, dosEuros, tresEuros }
```

### 3.4 Entity: CollectionEntity

```dart
class CollectionEntity extends Equatable {
  final String id;
  final String externalId;
  final String title;
  final String? description;
  final PlaceLevel? level;
  final List<String> placeIds;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
}
```

---

## 4. BLoC: QueVerBloc

### Events
- `QueVerStarted` - Inicializar
- `QueVerLoadRequested` - Cargar datos
- `QueVerCategoryFilterChanged` - Cambiar filtro categoría
- `QueVerLevelFilterChanged` - Cambiar filtro nivel
- `QueVerSearchChanged` - Búsqueda por texto
- `QueVerRefreshRequested` - Refrescar

### States
- `QueVerInitial`
- `QueVerLoading`
- `QueVerLoaded` - Con places, collections, filtros activos
- `QueVerError`

---

## 5. Pantallas

### 5.1 QueVerScreen (Lista principal)

**Elementos**:
- AppBar con título "¿Qué ver?"
- Sección de colecciones destacadas (horizontal scroll)
- Chips de filtros (categorías + niveles)
- Grid de tarjetas de lugares
- Pull to refresh

**Filtros**:
- Categorías: Todos | Cultura | Monumentos | Gastronomía | Enoturismo | Flamenco | Naturaleza | Familias | Compras | Experiencias | Playa | Pueblos Blancos
- Niveles: Jerez | Alrededores | Provincia

### 5.2 PlaceDetailScreen (Detalle)

**Elementos**:
- Hero image con transición
- Título y descripción corta
- Badges: nivel, categoría(s), precio
- Descripción larga
- Información práctica (duración, mejor momento, dirección)
- Mapa con ubicación (si tiene coordenadas)
- Tips (lista con iconos)
- Botones: Reservar | Web oficial
- Tags

### 5.3 CollectionScreen (Colección)

**Elementos**:
- Header con título y descripción
- Lista de places de la colección
- Navegación a detalle de cada place

---

## 6. Rutas

```dart
class QueVerRoutes {
  static const String queVer = '/guest/que-ver';
  static const String placeDetail = '/guest/que-ver/:id';
  static const String collection = '/guest/que-ver/collection/:id';
}
```

---

## 7. Seed Data

Generar JSON con 40 lugares según el prompt:
- 16 de Jerez (Alcázar, Catedral, Bodegas Tío Pepe, Museo Flamenco, etc.)
- 12 de Alrededores (Arcos de la Frontera, Sanlúcar, El Puerto, etc.)
- 12 de Provincia (Cádiz capital, Tarifa, Vejer, etc.)

Y 3 colecciones:
- "Imprescindibles en 1 día"
- "Plan romántico"
- "Gastronomía y vino"

---

## 8. Orden de Implementación

1. **Fase 1: Infraestructura**
   - [ ] Crear tablas en Supabase
   - [ ] Crear entities
   - [ ] Crear repository contract
   - [ ] Crear repository implementation
   - [ ] Registrar en DI

2. **Fase 2: BLoC**
   - [ ] Crear events
   - [ ] Crear states
   - [ ] Crear QueVerBloc

3. **Fase 3: UI**
   - [ ] Crear widgets (PlaceCard, FilterChips, etc.)
   - [ ] Crear QueVerScreen
   - [ ] Crear PlaceDetailScreen
   - [ ] Crear CollectionScreen

4. **Fase 4: Routing**
   - [ ] Definir rutas
   - [ ] Integrar en app_router.dart

5. **Fase 5: Seed Data**
   - [ ] Generar JSON de lugares
   - [ ] Generar JSON de colecciones
   - [ ] Insertar en Supabase

---

## 9. Consideraciones Técnicas

### Colores (AppColors)
- Primario: `AppColors.gold` (#C6A75E)
- Fondo cards: `AppColors.cardBackground`
- Texto: `AppColors.textPrimary`, `textSecondary`
- Badges: según categoría (cultura=azul, gastronomía=naranja, etc.)

### Responsive
- Grid 2 columnas en móvil, 3 en tablet
- Usar `context.responsive()` para adaptar UI

### Imágenes
- Usar `cached_network_image` para imágenes remotas
- Placeholder con shimmer mientras carga
- Hero animation en transición a detalle

### Sin personas en imágenes
- Solo arquitectura, paisajes, platos, detalles
- Alt text descriptivo para accesibilidad

---

## 10. Archivos a Crear/Modificar

### Nuevos (14 archivos)
1. `lib/features/guest/que_ver/domain/entities/place_entity.dart`
2. `lib/features/guest/que_ver/domain/entities/collection_entity.dart`
3. `lib/features/guest/que_ver/domain/repositories/places_repository.dart`
4. `lib/features/guest/que_ver/domain/bloc/que_ver_bloc.dart`
5. `lib/features/guest/que_ver/data/repositories/places_repository_impl.dart`
6. `lib/features/guest/que_ver/presentation/screens/que_ver_screen.dart`
7. `lib/features/guest/que_ver/presentation/screens/place_detail_screen.dart`
8. `lib/features/guest/que_ver/presentation/screens/collection_screen.dart`
9. `lib/features/guest/que_ver/presentation/widgets/place_card.dart`
10. `lib/features/guest/que_ver/presentation/widgets/category_filter_chip.dart`
11. `lib/features/guest/que_ver/presentation/widgets/level_filter_chip.dart`
12. `lib/features/guest/que_ver/presentation/widgets/collection_card.dart`
13. `lib/features/guest/que_ver/routes/que_ver_routes.dart`
14. `supabase_seed_que_ver.sql` (migraciones + seed)

### Modificar (3 archivos)
1. `lib/core/di/injection.dart` - Registrar repositorio
2. `lib/core/router/app_router.dart` - Añadir rutas
3. `lib/core/config/supabase_config.dart` - Añadir constantes de tablas
