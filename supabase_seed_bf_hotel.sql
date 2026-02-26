-- Seed data para Grupo Hotelero BF
-- Ejecutar después del schema principal (supabase_schema.sql)

-- Eliminar datos de demo anteriores
DELETE FROM public.units WHERE property_id = '11111111-1111-1111-1111-111111111111';
DELETE FROM public.properties WHERE id = '11111111-1111-1111-1111-111111111111';
DELETE FROM public.guide_items WHERE property_id = '11111111-1111-1111-1111-111111111111';

-- Crear propiedad principal: Grupo Hotelero BF
INSERT INTO public.properties (id, name, address, city, country, timezone, lat, lng)
VALUES (
  'bf000000-0000-0000-0000-000000000001',
  'Grupo Hotelero BF',
  'Jerez de la Frontera',
  'Cádiz',
  'ES',
  'Europe/Madrid',
  36.6850,
  -6.1260
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  city = EXCLUDED.city;

-- ============================================
-- UNIDADES DEL GRUPO HOTELERO BF
-- ============================================

-- 1. Hotel Boutique Jerez (Blanco + Negro)
INSERT INTO public.units (id, property_id, name, unit_type, box_location_text, box_code, access_instructions)
VALUES (
  'bf000000-0000-0000-0001-000000000001',
  'bf000000-0000-0000-0000-000000000001',
  'Hotel Boutique Jerez',
  'apartment',
  'Recepción principal del hotel',
  '0000',
  'Acceso por recepción. Presentar documento de identidad.'
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  box_location_text = EXCLUDED.box_location_text,
  access_instructions = EXCLUDED.access_instructions;

-- 2. Jacuzzi Jerez (Oro + Negro)
INSERT INTO public.units (id, property_id, name, unit_type, box_location_text, box_code, access_instructions)
VALUES (
  'bf000000-0000-0000-0001-000000000002',
  'bf000000-0000-0000-0000-000000000001',
  'Jacuzzi Jerez',
  'apartment',
  'Caja de seguridad junto a la puerta principal',
  '2024',
  'Introducir código, girar el pomo hacia la derecha y retirar la llave. Vuelva a guardar la llave al salir.'
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  box_location_text = EXCLUDED.box_location_text,
  box_code = EXCLUDED.box_code,
  access_instructions = EXCLUDED.access_instructions;

-- 3. Apartamento BF Jerez (Verde elegante + Blanco)
INSERT INTO public.units (id, property_id, name, unit_type, box_location_text, box_code, access_instructions)
VALUES (
  'bf000000-0000-0000-0001-000000000003',
  'bf000000-0000-0000-0000-000000000001',
  'Apartamento BF Jerez',
  'apartment',
  'Buzón electrónico en el portal',
  '1985',
  'El código está en el buzón. Portal con ascensor, tercera planta.'
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  box_location_text = EXCLUDED.box_location_text,
  box_code = EXCLUDED.box_code,
  access_instructions = EXCLUDED.access_instructions;

-- 4. Apartamento Bandera (Gris claro + Negro)
INSERT INTO public.units (id, property_id, name, unit_type, box_location_text, box_code, access_instructions)
VALUES (
  'bf000000-0000-0000-0001-000000000004',
  'bf000000-0000-0000-0000-000000000001',
  'Apartamento Bandera',
  'apartment',
  'Caja negra en la pared junto al portal',
  '1472',
  'Portal con escalera, segunda planta a la izquierda.'
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  box_location_text = EXCLUDED.box_location_text,
  box_code = EXCLUDED.box_code,
  access_instructions = EXCLUDED.access_instructions;

-- 5. Atico Jerez (Azul profundo + Blanco)
INSERT INTO public.units (id, property_id, name, unit_type, box_location_text, box_code, access_instructions)
VALUES (
  'bf000000-0000-0000-0001-000000000005',
  'bf000000-0000-0000-0000-000000000001',
  'Ático Jerez',
  'apartment',
  'Caja de llaves en la entrada del edificio',
  '3690',
  'Última planta con terraza. Ascensor disponible.'
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  box_location_text = EXCLUDED.box_location_text,
  box_code = EXCLUDED.box_code,
  access_instructions = EXCLUDED.access_instructions;

-- 6. BF Jacuzzi Jerez (Azul claro + Negro)
INSERT INTO public.units (id, property_id, name, unit_type, box_location_text, box_code, access_instructions)
VALUES (
  'bf000000-0000-0000-0001-000000000006',
  'bf000000-0000-0000-0000-000000000001',
  'BF Jacuzzi Jerez',
  'apartment',
  'Caja de seguridad en el porche',
  '7531',
  'Apartamento con jacuzzi privado. Acceso por patio interior.'
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  box_location_text = EXCLUDED.box_location_text,
  box_code = EXCLUDED.box_code,
  access_instructions = EXCLUDED.access_instructions;

-- ============================================
-- GUÍA DE ESTANCIA PARA EL GRUPO
-- ============================================

-- Items de guía generales (property_id sin unit_id específico)
INSERT INTO public.guide_items (property_id, unit_id, category, title, body, sort_order, is_published)
VALUES
  -- WiFi General
  (
    'bf000000-0000-0000-0000-000000000001',
    NULL,
    'wifi',
    'WiFi del Grupo Hotelero BF',
    'SSID: BF_Huespedes
Contraseña: BienvenidoBF2024!

Para problemas de conexión, contacte con recepción.',
    1,
    true
  ),
  -- Normas
  (
    'bf000000-0000-0000-0000-000000000001',
    NULL,
    'rules',
    'Normas de la Casa',
    '• Check-in: a partir de las 15:00h
• Check-out: antes de las 11:00h
• No fumar en el interior
• Respeta el descanso de los vecinos (22:00 - 08:00)
• No se permiten fiestas ni eventos
• Mascotas bajo consulta previa',
    2,
    true
  ),
  -- Emergencias
  (
    'bf000000-0000-0000-0000-000000000001',
    NULL,
    'emergency',
    'Contactos de Emergencia',
    'Emergencias: 112
Recepción Grupo BF: +34 XXX XXX XXX
WhatsApp: +34 XXX XXX XXX

Hospital de Jerez: +34 XXX XXX XXX',
    3,
    true
  ),
  -- Información de Jerez
  (
    'bf000000-0000-0000-0000-000000000001',
    NULL,
    'local',
    'Información de Jerez',
    'Centro histórico: 10 min andando
Estación de tren: 5 min en taxi
Aeropuerto Jerez: 15 min en taxi
Playa de Cádiz: 35 min en coche

Bodegas recomendadas:
• Bodega Tío Pepe
• Bodega González Byass
• Bodega Lustau',
    4,
    true
  )
ON CONFLICT DO NOTHING;

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Mostrar los datos insertados
SELECT 'Propiedades:' as tipo;
SELECT id, name, address, city FROM public.properties;

SELECT 'Unidades:' as tipo;
SELECT u.id, u.name, u.unit_type, u.box_location_text
FROM public.units u
ORDER BY u.name;

SELECT 'Guía de estancia:' as tipo;
SELECT id, category, title FROM public.guide_items
WHERE property_id = 'bf000000-0000-0000-0000-000000000001';
