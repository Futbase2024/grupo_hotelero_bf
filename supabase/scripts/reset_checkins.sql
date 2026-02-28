-- ============================================================================
-- Script: Reset Check-ins
-- Descripción: Borra todos los check-ins, huéspedes y relaciones
-- Uso: Ejecutar este script cuando se quiera limpiar los datos de check-in
-- ============================================================================

-- Borrar check-ins
DELETE FROM checkins;

-- Borrar relaciones booking_guests
DELETE FROM booking_guests;

-- Borrar huéspedes
DELETE FROM guests;

-- Verificar que se borraron (opcional)
SELECT 'checkins' as tabla, COUNT(*) as total FROM checkins
UNION ALL
SELECT 'booking_guests', COUNT(*) FROM booking_guests
UNION ALL
SELECT 'guests', COUNT(*) FROM guests;

-- Mensaje de confirmación
SELECT 'Check-ins borrados correctamente' as resultado;
