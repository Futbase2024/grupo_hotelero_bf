-- ============================================================
-- BF STAY - Tabla de Reseñas (Reviews)
-- ============================================================
-- Ejecutar este script en el editor SQL de Supabase

-- ============================================
-- LIMPIAR TABLAS EXISTENTES (si existen)
-- ============================================

DROP TABLE IF EXISTS reviews CASCADE;
DROP VIEW IF EXISTS reviews_with_guest CASCADE;
DROP FUNCTION IF EXISTS get_property_rating_avg(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_property_rating_distribution(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- ============================================
-- 1. CREAR TABLA DE REVIEWS
-- ============================================

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL,
  unit_id UUID,
  guest_id UUID,
  booking_id UUID,

  -- Contenido de la reseña
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT NOT NULL,

  -- Metadatos
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_comment_length CHECK (char_length(comment) >= 10)
);

-- ============================================
-- 2. ÍNDICES
-- ============================================

CREATE INDEX idx_reviews_property_id ON reviews(property_id);
CREATE INDEX idx_reviews_unit_id ON reviews(unit_id);
CREATE INDEX idx_reviews_guest_id ON reviews(guest_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);
CREATE INDEX idx_reviews_is_active ON reviews(is_active);

-- ============================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reviews are viewable by everyone"
  ON reviews FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "Authenticated users can insert reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own reviews"
  ON reviews FOR UPDATE
  USING (guest_id IS NOT NULL)
  WITH CHECK (guest_id IS NOT NULL);

CREATE POLICY "Users can delete own reviews"
  ON reviews FOR DELETE
  USING (guest_id IS NOT NULL);

-- ============================================
-- 4. TRIGGER PARA UPDATED_AT
-- ============================================

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

-- ============================================
-- 5. FUNCIÓN PARA RATING PROMEDIO
-- ============================================

CREATE OR REPLACE FUNCTION get_property_rating_avg(p_property_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  avg_rating NUMERIC;
BEGIN
  SELECT ROUND(AVG(rating)::numeric, 1)
  INTO avg_rating
  FROM reviews
  WHERE property_id = p_property_id
    AND is_active = TRUE;

  RETURN COALESCE(avg_rating, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. FUNCIÓN PARA DISTRIBUCIÓN DE RATINGS
-- ============================================

CREATE OR REPLACE FUNCTION get_property_rating_distribution(p_property_id UUID)
RETURNS TABLE(rating INT, count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT r.rating, COUNT(*)::bigint as count
  FROM reviews r
  WHERE r.property_id = p_property_id
    AND r.is_active = TRUE
  GROUP BY r.rating
  ORDER BY r.rating DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. VISTA PARA REVIEWS
-- ============================================

CREATE OR REPLACE VIEW reviews_with_guest AS
SELECT
  r.id,
  r.property_id,
  r.unit_id,
  r.guest_id,
  r.booking_id,
  r.rating,
  r.title,
  r.comment,
  r.is_verified,
  r.is_active,
  r.created_at,
  r.updated_at,
  'Huésped' as guest_name,
  'Propiedad' as property_name,
  NULL::TEXT as unit_name
FROM reviews r
WHERE r.is_active = TRUE;

-- ============================================
-- 8. DATOS DE PRUEBA
-- ============================================

INSERT INTO reviews (property_id, unit_id, guest_id, rating, title, comment, is_verified, is_active, created_at) VALUES
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  NULL,
  NULL,
  5,
  'Increíble estancia',
  'El apartamento estaba impecable, con vistas espectaculares. El anfitrión muy atento en todo momento.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '2 days'
),
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  NULL,
  NULL,
  4,
  'Muy buena experiencia',
  'Todo correcto, la ubicación perfecta para explorar la zona. El apartamento limpio y con todo lo necesario.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '7 days'
),
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  'bf000000-0000-0000-0001-000000000001'::UUID,
  NULL,
  5,
  'Hotel Boutique Jerez - Excelente',
  'Estuvimos en el Hotel Boutique y todo fue genial. El apartamento espacioso, muy bien decorado.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '14 days'
),
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  'bf000000-0000-0000-0001-000000000002'::UUID,
  NULL,
  5,
  'Jacuzzi Jerez - Perfecto para parejas',
  'Celebramos nuestro aniversario aquí y fue perfecto. El jacuzzi increíble.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '21 days'
),
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  NULL,
  NULL,
  4,
  'Buena relación calidad-precio',
  'Buena relación calidad-precio. El check-in fue muy fácil con las instrucciones proporcionadas.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '30 days'
),
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  'bf000000-0000-0000-0001-000000000003'::UUID,
  NULL,
  3,
  'Correcto pero mejorable',
  'El apartamento bien en general, pero encontramos algunos detalles de limpieza.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '5 days'
),
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  'bf000000-0000-0000-0001-000000000005'::UUID,
  NULL,
  5,
  'Ático Jerez - Vistas increíbles',
  'Las vistas desde la terraza son espectaculares. El apartamento muy bien equipado.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '10 days'
),
(
  'bf000000-0000-0000-0000-000000000001'::UUID,
  'bf000000-0000-0000-0001-000000000006'::UUID,
  NULL,
  5,
  'BF Jacuzzi - Experiencia de 10',
  'Todo perfecto. El jacuzzi privado un lujo. El apartamento muy limpio.',
  TRUE,
  TRUE,
  NOW() - INTERVAL '14 days'
);

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT 'Reseñas creadas:' as info, COUNT(*)::text as total FROM reviews;
SELECT * FROM reviews ORDER BY created_at DESC LIMIT 5;
