# Plan: Feature de Reseñas y Comentarios

## Resumen
Crear una feature completa de reseñas y comentarios que permita:
- **Usuarios registrados**: Crear, editar y eliminar sus propias reseñas
- **Usuarios no registrados**: Solo ver las reseñas (modo lectura)

---

## Alcance

### Rol de la Feature
- `guest/reviews` - Módulo de reseñas para huéspedes

### Funcionalidades
1. **Ver reseñas** (todos los usuarios)
   - Lista de reseñas de una propiedad/unidad
   - Rating promedio
   - Filtros por rating (1-5 estrellas)

2. **Crear reseña** (solo usuarios registrados)
   - Rating con estrellas (1-5)
   - Título opcional
   - Comentario obligatorio
   - Verificación de que el usuario tiene una reserva completada

3. **Editar/Eliminar reseña** (solo el autor)
   - El autor puede editar su reseña
   - El autor puede eliminar su reseña

---

## Estructura de Archivos

```
lib/features/guest/reviews/
├── data/
│   └── repositories/
│       └── reviews_repository_impl.dart
├── domain/
│   ├── bloc/
│   │   └── reviews_bloc.dart
│   ├── entities/
│   │   └── review_entity.dart
│   └── repositories/
│       └── reviews_repository.dart
└── presentation/
    ├── screens/
    │   ├── reviews_screen.dart
    │   └── review_form_screen.dart
    └── widgets/
        ├── review_card.dart
        ├── rating_stars.dart
        ├── rating_summary_card.dart
        └── review_empty_state.dart
```

---

## Tablas Supabase

### Tabla: `reviews`

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  guest_id UUID REFERENCES guests(id) ON DELETE SET NULL,
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,

  -- Contenido de la reseña
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT NOT NULL,

  -- Metadatos
  is_verified BOOLEAN DEFAULT FALSE,  -- Si el huésped realmente se hospedó
  is_active BOOLEAN DEFAULT TRUE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_comment_length CHECK (char_length(comment) >= 10)
);

-- Índices
CREATE INDEX idx_reviews_property_id ON reviews(property_id);
CREATE INDEX idx_reviews_unit_id ON reviews(unit_id);
CREATE INDEX idx_reviews_guest_id ON reviews(guest_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- RLS (Row Level Security)
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden ver reseñas activas
CREATE POLICY "Reviews are viewable by everyone"
  ON reviews FOR SELECT
  USING (is_active = TRUE);

-- Política: Solo usuarios autenticados pueden insertar
CREATE POLICY "Authenticated users can insert reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Política: Solo el autor puede actualizar
CREATE POLICY "Users can update own reviews"
  ON reviews FOR UPDATE
  USING (auth.uid()::text = guest_id::text);

-- Política: Solo el autor puede eliminar
CREATE POLICY "Users can delete own reviews"
  ON reviews FOR DELETE
  USING (auth.uid()::text = guest_id::text);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_reviews_updated_at
  BEFORE UPDATE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## Entidades

### ReviewEntity

```dart
class ReviewEntity extends Equatable {
  const ReviewEntity({
    required this.id,
    required this.propertyId,
    this.unitId,
    this.guestId,
    this.bookingId,
    required this.rating,
    this.title,
    required this.comment,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    // Campos joined
    this.guestName,
    this.propertyName,
    this.unitName,
  });

  final String id;
  final String propertyId;
  final String? unitId;
  final String? guestId;
  final String? bookingId;
  final int rating;
  final String? title;
  final String comment;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Campos de relaciones (populados desde joins)
  final String? guestName;
  final String? propertyName;
  final String? unitName;

  // Getters
  bool get hasTitle => title != null && title!.isNotEmpty;
  bool get isRecent => DateTime.now().difference(createdAt).inDays <= 30;
  String get ratingStars => '★' * rating + '☆' * (5 - rating);
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${diff.inDays ~/ 7} semanas';
    if (diff.inDays < 365) return 'Hace ${diff.inDays ~/ 30} meses';
    return 'Hace más de un año';
  }
}
```

---

## BLoC

### Events

```dart
abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();
}

// Carga inicial
class ReviewsStarted extends ReviewsEvent { ... }

// Cargar reseñas de una propiedad
class ReviewsLoadByProperty extends ReviewsEvent {
  final String propertyId;
}

// Cargar reseñas de una unidad
class ReviewsLoadByUnit extends ReviewsEvent {
  final String unitId;
}

// Crear reseña
class ReviewsCreate extends ReviewsEvent {
  final ReviewEntity review;
}

// Actualizar reseña
class ReviewsUpdate extends ReviewsEvent {
  final ReviewEntity review;
}

// Eliminar reseña
class ReviewsDelete extends ReviewsEvent {
  final String reviewId;
}

// Filtrar por rating
class ReviewsFilterByRating extends ReviewsEvent {
  final int? minRating;
}

// Refrescar
class ReviewsRefresh extends ReviewsEvent { ... }
```

### States

```dart
abstract class ReviewsState extends Equatable {
  const ReviewsState();
}

class ReviewsInitial extends ReviewsState { ... }
class ReviewsLoading extends ReviewsState { ... }
class ReviewsLoaded extends ReviewsState {
  final List<ReviewEntity> reviews;
  final double averageRating;
  final Map<int, int> ratingDistribution; // {5: 10, 4: 5, ...}
  final int? filterMinRating;
  final bool isRefreshing;
}
class ReviewsError extends ReviewsState {
  final String message;
}
class ReviewCreating extends ReviewsState { ... }
class ReviewCreated extends ReviewsState { ... }
class ReviewUpdating extends ReviewsState { ... }
class ReviewDeleting extends ReviewsState { ... }
```

---

## Pantallas

### 1. ReviewsScreen
- Muestra lista de reseñas de una propiedad/unidad
- Cabecera con rating promedio y distribución
- Filtros por rating
- Botón flotante para añadir reseña (solo usuarios registrados)
- Pull-to-refresh

### 2. ReviewFormScreen
- Formulario para crear/editar reseña
- Rating con estrellas interactivas
- Campo de título (opcional)
- Campo de comentario (obligatorio, mínimo 10 caracteres)
- Validación antes de guardar

---

## Widgets

### ReviewCard
- Avatar del huésped (inicial)
- Nombre del huésped
- Rating con estrellas
- Fecha relativa ("Hace 2 días")
- Badge "Verificado" si isVerified
- Título (si existe)
- Comentario truncado con "Ver más"
- Botones editar/eliminar (solo para el autor)

### RatingStars
- Widget reutilizable para mostrar rating
- Modo display (solo lectura)
- Modo input (interactivo para seleccionar)

### RatingSummaryCard
- Rating promedio grande
- Barras de distribución de ratings
- Total de reseñas

### ReviewEmptyState
- Mensaje cuando no hay reseñas
- CTA para ser el primero en reseñar

---

## Rutas

```dart
class AppRoutes {
  // ... existentes
  static const String reviews = '/guest/reviews/:propertyId';
  static const String reviewCreate = '/guest/reviews/:propertyId/new';
  static const String reviewEdit = '/guest/reviews/:reviewId/edit';
}
```

---

## Orden de Implementación

1. ✅ Crear plan
2. ⬜ Crear script SQL para tablas
3. ⬜ Actualizar `SupabaseTables` con constantes
4. ⬜ Crear `ReviewEntity`
5. ⬜ Crear contrato `ReviewsRepository`
6. ⬜ Crear implementación `ReviewsRepositoryImpl`
7. ⬜ Crear `ReviewsBloc`
8. ⬜ Crear widgets (`RatingStars`, `ReviewCard`, `RatingSummaryCard`)
9. ⬜ Crear `ReviewsScreen`
10. ⬜ Crear `ReviewFormScreen`
11. ⬜ Configurar rutas en `AppRouter`
12. ⬜ Registrar en DI (`injection.dart`)
13. ⬜ Crear seed de datos de prueba
14. ⬜ Probar flujo completo

---

## Consideraciones

### Seguridad
- RLS habilitado en Supabase
- Solo usuarios autenticados pueden crear reseñas
- Solo el autor puede editar/eliminar sus reseñas
- Validación de longitud mínima de comentario

### UX
- Indicador de carga mientras se guardan reseñas
- Confirmación antes de eliminar
- Animación suave en las estrellas
- Pull-to-refresh en la lista
- Empty state atractivo

### Performance
- Índices en columnas frecuentemente consultadas
- Paginación si hay muchas reseñas (futuro)
- Cache de rating promedio (futuro)

---

## Datos de Prueba (Seed)

```sql
-- Insertar reseñas de ejemplo
INSERT INTO reviews (property_id, guest_id, rating, title, comment, is_verified)
VALUES
  ('{property_id_1}', '{guest_id_1}', 5, 'Increíble estancia', 'El apartamento estaba impecable, con vistas espectaculares. El anfitrión muy atento en todo momento.', TRUE),
  ('{property_id_1}', '{guest_id_2}', 4, 'Muy buena experiencia', 'Todo correcto, la ubicación perfecta. Único pero: el WiFi un poco lento.', TRUE),
  ('{property_id_1}', '{guest_id_3}', 5, NULL, 'Volveremos sin duda. Todo perfecto desde la llegada hasta la salida.', TRUE);
```
