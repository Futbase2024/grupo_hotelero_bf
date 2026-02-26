-- ============================================
-- BF Stay - Seed Data para Parkings
-- Parkings cercanos a alojamientos en Jerez Centro
-- ============================================

-- Limpiar datos existentes (opcional, descomentar si es necesario)
-- DELETE FROM public.unit_parkings;
-- DELETE FROM public.parkings;

-- ============================================
-- 1. INSERTAR PARKINGS
-- ============================================

INSERT INTO public.parkings (id, name, address_text, phone, provider, lat, lng, google_maps_url, apple_maps_url, is_active) VALUES

-- Parking Plaza del Arenal (más céntrico)
('pk000000-0000-0000-0001-000000000001',
 'Parking Plaza del Arenal',
 'Plaza del Arenal, 11403 Jerez de la Frontera, Cádiz',
 NULL,
 'Público',
 36.6847,
 -6.1361,
 'https://www.google.com/maps?q=36.6847,-6.1361',
 'https://maps.apple.com/?ll=36.6847,-6.1361',
 true),

-- Parking C/ Larga
('pk000000-0000-0000-0001-000000000002',
 'Parking Calle Larga',
 'C/ Larga, 11403 Jerez de la Frontera, Cádiz',
 NULL,
 'Público',
 36.6855,
 -6.1372,
 'https://www.google.com/maps?q=36.6855,-6.1372',
 'https://maps.apple.com/?ll=36.6855,-6.1372',
 true),

-- Parking Mercado Central
('pk000000-0000-0000-0001-000000000003',
 'Parking Mercado Central',
 'Plaza del Mercado, 11403 Jerez de la Frontera, Cádiz',
 NULL,
 'Público',
 36.6861,
 -6.1358,
 'https://www.google.com/maps?q=36.6861,-6.1358',
 'https://maps.apple.com/?ll=36.6861,-6.1358',
 true),

-- Parking C/ Porvera
('pk000000-0000-0000-0001-000000000004',
 'Parking Calle Porvera',
 'C/ Porvera, 11403 Jerez de la Frontera, Cádiz',
 NULL,
 'Público',
 36.6839,
 -6.1338,
 'https://www.google.com/maps?q=36.6839,-6.1338',
 'https://maps.apple.com/?ll=36.6839,-6.1338',
 true),

-- Parking Estación de Tren
('pk000000-0000-0000-0001-000000000005',
 'Parking Estación de Tren Jerez',
 'Estación de Jerez de la Frontera, Plaza de la Estación, 11403 Jerez de la Frontera, Cádiz',
 '+34 956 33 05 00',
 'Público',
 36.6792,
 -6.1297,
 'https://www.google.com/maps?q=36.6792,-6.1297',
 'https://maps.apple.com/?ll=36.6792,-6.1297',
 true),

-- Parking Centro Comercial Área Sur
('pk000000-0000-0000-0001-000000000006',
 'Parking Centro Comercial Área Sur',
 'Ctra. N-IV, Km. 640, 11405 Jerez de la Frontera, Cádiz',
 '+34 956 18 58 00',
 'Privado',
 36.6698,
 -6.1211,
 'https://www.google.com/maps?q=36.6698,-6.1211',
 'https://maps.apple.com/?ll=36.6698,-6.1211',
 true),

-- Parking C/ Manuel María González
('pk000000-0000-0000-0001-000000000007',
 'Parking Calle Manuel María González',
 'C/ Manuel María González, 11403 Jerez de la Frontera, Cádiz',
 NULL,
 'Público',
 36.6842,
 -6.1345,
 'https://www.google.com/maps?q=36.6842,-6.1345',
 'https://maps.apple.com/?ll=36.6842,-6.1345',
 true),

-- Parking Plaza del Banco
('pk000000-0000-0000-0001-000000000008',
 'Parking Plaza del Banco',
 'Plaza del Banco, 11403 Jerez de la Frontera, Cádiz',
 NULL,
 'Público',
 36.6858,
 -6.1365,
 'https://www.google.com/maps?q=36.6858,-6.1365',
 'https://maps.apple.com/?ll=36.6858,-6.1365',
 true);

-- ============================================
-- 2. INSERTAR RELACIONES UNIDADES-PARKINGS
-- ============================================

-- Unidades BF Stay:
-- bf000000-0000-0000-0001-000000000001 = Hotel Boutique Jerez (C/ José Luis Díez, 8)
-- bf000000-0000-0000-0001-000000000002 = Jacuzzi Jerez (C/ Hijuela, 2)
-- bf000000-0000-0000-0001-000000000003 = Apartamento BF Jerez (C/ Hijuela, 2)
-- bf000000-0000-0000-0001-000000000004 = Apartamento Bandera (C/ Prieta, 4)
-- bf000000-0000-0000-0001-000000000005 = Ático Jerez (C/ Hijuela, 2)
-- bf000000-0000-0000-0001-000000000006 = BF Jacuzzi Jerez (C/ Hijuela, 2)

-- Hotel Boutique Jerez (C/ José Luis Díez, 8) - Zona centro
INSERT INTO public.unit_parkings (id, unit_id, parking_id, priority, notes) VALUES
('up000000-0000-0000-0001-000000000001', 'bf000000-0000-0000-0001-000000000001', 'pk000000-0000-0000-0001-000000000004', 0, 'Opción más cercana, a 2 min andando'),
('up000000-0000-0000-0001-000000000002', 'bf000000-0000-0000-0001-000000000001', 'pk000000-0000-0000-0001-000000000007', 1, 'Muy cercano, a 3 min andando'),
('up000000-0000-0000-0001-000000000003', 'bf000000-0000-0000-0001-000000000001', 'pk000000-0000-0000-0001-000000000001', 2, 'Plaza del Arenal, a 5 min andando'),
('up000000-0000-0000-0001-000000000004', 'bf000000-0000-0000-0001-000000000001', 'pk000000-0000-0000-0001-000000000008', 3, 'Plaza del Banco, a 5 min andando'),
('up000000-0000-0000-0001-000000000005', 'bf000000-0000-0000-0001-000000000001', 'pk000000-0000-0000-0001-000000000002', 4, 'Calle Larga, a 6 min andando');

-- Jacuzzi Jerez (C/ Hijuela, 2) - Zona centro histórico
INSERT INTO public.unit_parkings (id, unit_id, parking_id, priority, notes) VALUES
('up000000-0000-0000-0001-000000000006', 'bf000000-0000-0000-0001-000000000002', 'pk000000-0000-0000-0001-000000000007', 0, 'Opción más cercana, a 2 min andando'),
('up000000-0000-0000-0001-000000000007', 'bf000000-0000-0000-0001-000000000002', 'pk000000-0000-0000-0001-000000000004', 1, 'Muy cercano, a 3 min andando'),
('up000000-0000-0000-0001-000000000008', 'bf000000-0000-0000-0001-000000000002', 'pk000000-0000-0000-0001-000000000003', 2, 'Mercado Central, a 4 min andando'),
('up000000-0000-0000-0001-000000000009', 'bf000000-0000-0000-0001-000000000002', 'pk000000-0000-0000-0001-000000000001', 3, 'Plaza del Arenal, a 5 min andando'),
('up000000-0000-0000-0001-000000000010', 'bf000000-0000-0000-0001-000000000002', 'pk000000-0000-0000-0001-000000000005', 4, 'Estación de tren, a 8 min andando');

-- Apartamento BF Jerez (C/ Hijuela, 2) - Mismo edificio que Jacuzzi Jerez
INSERT INTO public.unit_parkings (id, unit_id, parking_id, priority, notes) VALUES
('up000000-0000-0000-0001-000000000011', 'bf000000-0000-0000-0001-000000000003', 'pk000000-0000-0000-0001-000000000007', 0, 'Opción más cercana, a 2 min andando'),
('up000000-0000-0000-0001-000000000012', 'bf000000-0000-0000-0001-000000000003', 'pk000000-0000-0000-0001-000000000004', 1, 'Muy cercano, a 3 min andando'),
('up000000-0000-0000-0001-000000000013', 'bf000000-0000-0000-0001-000000000003', 'pk000000-0000-0000-0001-000000000003', 2, 'Mercado Central, a 4 min andando'),
('up000000-0000-0000-0001-000000000014', 'bf000000-0000-0000-0001-000000000003', 'pk000000-0000-0000-0001-000000000001', 3, 'Plaza del Arenal, a 5 min andando'),
('up000000-0000-0000-0001-000000000015', 'bf000000-0000-0000-0001-000000000003', 'pk000000-0000-0000-0001-000000000005', 4, 'Estación de tren, a 8 min andando');

-- Apartamento Bandera (C/ Prieta, 4) - Zona centro
INSERT INTO public.unit_parkings (id, unit_id, parking_id, priority, notes) VALUES
('up000000-0000-0000-0001-000000000016', 'bf000000-0000-0000-0001-000000000004', 'pk000000-0000-0000-0001-000000000001', 0, 'Plaza del Arenal, la opción más cercana'),
('up000000-0000-0000-0001-000000000017', 'bf000000-0000-0000-0001-000000000004', 'pk000000-0000-0000-0001-000000000008', 1, 'Plaza del Banco, a 3 min andando'),
('up000000-0000-0000-0001-000000000018', 'bf000000-0000-0000-0001-000000000004', 'pk000000-0000-0000-0001-000000000002', 2, 'Calle Larga, a 4 min andando'),
('up000000-0000-0000-0001-000000000019', 'bf000000-0000-0000-0001-000000000004', 'pk000000-0000-0000-0001-000000000007', 3, 'Calle Manuel María González, a 5 min'),
('up000000-0000-0000-0001-000000000020', 'bf000000-0000-0000-0001-000000000004', 'pk000000-0000-0000-0001-000000000003', 4, 'Mercado Central, a 6 min andando');

-- Ático Jerez (C/ Hijuela, 2) - Mismo edificio que Jacuzzi Jerez
INSERT INTO public.unit_parkings (id, unit_id, parking_id, priority, notes) VALUES
('up000000-0000-0000-0001-000000000021', 'bf000000-0000-0000-0001-000000000005', 'pk000000-0000-0000-0001-000000000007', 0, 'Opción más cercana, a 2 min andando'),
('up000000-0000-0000-0001-000000000022', 'bf000000-0000-0000-0001-000000000005', 'pk000000-0000-0000-0001-000000000004', 1, 'Muy cercano, a 3 min andando'),
('up000000-0000-0000-0001-000000000023', 'bf000000-0000-0000-0001-000000000005', 'pk000000-0000-0000-0001-000000000003', 2, 'Mercado Central, a 4 min andando'),
('up000000-0000-0000-0001-000000000024', 'bf000000-0000-0000-0001-000000000005', 'pk000000-0000-0000-0001-000000000001', 3, 'Plaza del Arenal, a 5 min andando'),
('up000000-0000-0000-0001-000000000025', 'bf000000-0000-0000-0001-000000000005', 'pk000000-0000-0000-0001-000000000005', 4, 'Estación de tren, a 8 min andando');

-- BF Jacuzzi Jerez (C/ Hijuela, 2) - Mismo edificio
INSERT INTO public.unit_parkings (id, unit_id, parking_id, priority, notes) VALUES
('up000000-0000-0000-0001-000000000026', 'bf000000-0000-0000-0001-000000000006', 'pk000000-0000-0000-0001-000000000007', 0, 'Opción más cercana, a 2 min andando'),
('up000000-0000-0000-0001-000000000027', 'bf000000-0000-0000-0001-000000000006', 'pk000000-0000-0000-0001-000000000004', 1, 'Muy cercano, a 3 min andando'),
('up000000-0000-0000-0001-000000000028', 'bf000000-0000-0000-0001-000000000006', 'pk000000-0000-0000-0001-000000000003', 2, 'Mercado Central, a 4 min andando'),
('up000000-0000-0000-0001-000000000029', 'bf000000-0000-0000-0001-000000000006', 'pk000000-0000-0000-0001-000000000001', 3, 'Plaza del Arenal, a 5 min andando'),
('up000000-0000-0000-0001-000000000030', 'bf000000-0000-0000-0001-000000000006', 'pk000000-0000-0000-0001-000000000005', 4, 'Estación de tren, a 8 min andando');

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Verificar parkings insertados
SELECT id, name, address_text, is_active FROM public.parkings ORDER BY name;

-- Verificar relaciones insertadas
SELECT
  up.id,
  up.unit_id,
  p.name as parking_name,
  up.priority,
  up.notes
FROM public.unit_parkings up
JOIN public.parkings p ON up.parking_id = p.id
ORDER BY up.unit_id, up.priority;
