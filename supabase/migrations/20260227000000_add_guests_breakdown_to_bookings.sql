-- Añadir campos de desglose de huéspedes a bookings
-- Esto permite saber cuántos adultos y niños (con sus edades) hay en cada reserva

-- Añadir columnas
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS num_adults int NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS num_children int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS children_ages int[] DEFAULT '{}';

-- Crear índice para búsquedas por número de huéspedes
CREATE INDEX IF NOT EXISTS bookings_num_guests_idx
  ON public.bookings(num_adults, num_children);

-- Comentario descriptivo
COMMENT ON COLUMN public.bookings.num_adults IS 'Número de adultos en la reserva';
COMMENT ON COLUMN public.bookings.num_children IS 'Número de niños (menores de edad) en la reserva';
COMMENT ON COLUMN public.bookings.children_ages IS 'Array con las edades de cada niño';
