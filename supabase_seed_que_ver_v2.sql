-- ============================================
-- SEED SQL: ¿QUÉ VER? - LUGARES Y EXPERIENCIAS v2
-- Proyecto: BF Stay
-- Fecha: 2026-02-25
-- Bucket: poi/jerez, poi/alrededores, poi/provincia
-- ============================================

-- Limpiar datos existentes (opcional, descomentar si necesario)
-- DELETE FROM place_collections;
-- DELETE FROM place_photos;
-- DELETE FROM places;
-- DELETE FROM collections WHERE external_id LIKE 'col-v2-%';

-- ============================================
-- COLECCIONES
-- ============================================
INSERT INTO collections (external_id, title, description, icon, color, sort_order) VALUES
('col-v2-imprescindibles', 'Imprescindibles en 1 día', 'Lo mejor de Jerez para disfrutar en un día: monumentos, bodegas y flamenco', 'star', '#D4AF37', 1),
('col-v2-romantico', 'Plan romántico', 'Experiencias perfectas para parejas: ecuestre, vino, atardeceres', 'favorite', '#C62828', 2),
('col-v2-gastronomia', 'Gastronomía y vino', 'La mejor gastronomía gaditana: bodegas, tapas y pescado fresco', 'restaurant', '#E65100', 3)
ON CONFLICT (external_id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon,
  color = EXCLUDED.color,
  sort_order = EXCLUDED.sort_order;

-- ============================================
-- LUGARES - JEREZ (ordenados por importancia)
-- ============================================
INSERT INTO places (
    external_id, level, title, short_description, long_description,
    categories, recommended_duration_minutes, best_time_to_visit, price_level,
    address, geo_lat, geo_lng, booking_url, website_url,
    tips, tags, image_url, sort_order
) VALUES

-- 1. ALCÁZAR DE JEREZ
(
    'place-v2-alcazar-jerez',
    'jerez',
    'Alcázar de Jerez',
    'Fortaleza almohade del siglo XI con cámara oscura y los mejores jardines árabes de la ciudad.',
    'El Alcázar de Jerez es una fortaleza de origen almohade que data del siglo XI. Conserva la mezquita más antigua de la ciudad, baños árabes perfectamente restaurados y la única cámara oscura de Andalucía. Desde sus torres se obtienen las mejores vistas panorámicas de Jerez. Los jardines son un remanso de paz con fuentes y naranjos.',
    ARRAY['monumentos', 'cultura'],
    90,
    'Mañana',
    'un_euro',
    'Alameda Vieja, s/n, 11403 Jerez de la Frontera',
    36.6833,
    -6.1389,
    NULL,
    NULL,
    ARRAY['La cámara oscura tiene sesiones cada 30 minutos', 'Visita los baños árabes primero', 'Jardines ideales al atardecer', 'Parking gratuito en Alameda Vieja'],
    ARRAY['almohade', 'cámara oscura', 'jardines', 'vistas', 'historia', 'árabe', 'medieval'],
    'poi/jerez/alcazar_jerez/alcazar_jerez_1.jpg',
    1
),

-- 2. CATEDRAL DE JEREZ
(
    'place-v2-catedral-jerez',
    'jerez',
    'Catedral de San Salvador',
    'Impresionante catedral barroca del siglo XVII en el corazón del casco histórico.',
    'La Catedral de Jerez combina elementos góticos, barrocos y neoclásicos en una construcción que tardó más de un siglo en completarse. Destacan su retablo mayor dorado, la sillería del coro tallada en madera y la imponente cúpula visible desde muchos puntos de la ciudad. Se conserva la imagen de Nuestra Señora del Rosario, patrona de Jerez.',
    ARRAY['monumentos', 'cultura'],
    45,
    'Mañana',
    'gratis',
    'Plaza de la Encarnación, 11402 Jerez de la Frontera',
    36.6847,
    -6.1375,
    NULL,
    NULL,
    ARRAY['Entrada gratuita fuera de horario de misa', 'Sube a la torre para vistas únicas', 'Visita guiada los domingos a las 12:00'],
    ARRAY['barroco', 'patrimonio', 'religioso', 'cúpula', 'gótico', 'neoclásico'],
    'poi/jerez/catedral_jerez/catedral_jerez_1.jpg',
    2
),

-- 3. REAL ESCUELA ECUUESTRE
(
    'place-v2-escuela-ecuestre',
    'jerez',
    'Real Escuela Andaluza del Arte Ecuestre',
    'Espectáculo único de doma clásica y vaquera con caballos cartujanos.',
    'La Real Escuela es el referente mundial del arte ecuestre andaluz. Los espectáculos "Cómo bailan los caballos andaluces" se celebran en un picadero del siglo XIX. El recorrido incluye las cuadras, el museo del enganche y los jardines. Los caballos cartujanos, raza autóctona en peligro de extinción, son los auténticos protagonistas.',
    ARRAY['experiencias', 'cultura'],
    120,
    'Martes y jueves (espectáculo)',
    'dos_euros',
    'Avda. Duque de Abrantes, 11407 Jerez de la Frontera',
    36.6911,
    -6.1219,
    'https://www.realescuela.org/es/entradas',
    'https://www.realescuela.org',
    ARRAY['Reserva con antelación, se agota rápido', 'Espectáculo oficial: martes y jueves a las 12:00', 'Llega 30 min antes para ver cuadras', 'Visita el museo del enganche incluido'],
    ARRAY['caballos', 'cartujano', 'doma', 'espectáculo', 'tradicional', 'andaluz'],
    'poi/jerez/real_escuela_ecuestre/real_escuela_ecuestre_1.jpg',
    3
),

-- 4. BODEGAS TÍO PEPE
(
    'place-v2-bodegas-tio-pepe',
    'jerez',
    'Bodegas González Byass - Tío Pepe',
    'La bodega más emblemática de Jerez, famosa mundialmente por sus finos y brandies.',
    'Fundada en 1835, González Byass es parada obligatoria para entender el vino de Jerez. La visita incluye los viñedos, las bodegas centenarias donde reposan los vinos en soleras, y la icónica botella gigante de Tío Pepe. Destacan los barriles firmados por visitantes ilustres como Churchill, Orson Welles o Spielberg. La cata final permite descubrir finos, manzanillas y olorosos.',
    ARRAY['enoturismo', 'gastronomia'],
    120,
    'Mañana o tarde',
    'dos_euros',
    'Calle Manuel María González, 12, 11403 Jerez de la Frontera',
    36.6825,
    -6.1369,
    'https://www.gonzalezbyass.com/visitas/',
    'https://www.gonzalezbyass.com',
    ARRAY['Reserva online para elegir horario', 'Cata premium disponible con maridaje', 'Tienda con edición limitada', 'Visita nocturna en verano'],
    ARRAY['tío pepe', 'sherry', 'fino', 'brandy', 'cata', 'jerez', 'solera'],
    'poi/jerez/bodegas_tio_pepe/bodegas_tio_pepe_1.jpg',
    4
),

-- 5. TABLAO FLAMENCO
(
    'place-v2-tablao-flamenco',
    'jerez',
    'Tablao Flamenco Pemarte',
    'El mejor flamenco en vivo de Jerez, cuna del arte jondo.',
    'Situado en un edificio del siglo XIX en pleno centro histórico, el Tablao Pemarte ofrece la experiencia flamenca más auténtica de Jerez. Los espectáculos cuentan con bailaores, cantaores y guitarristas de renombre local. El ambiente íntimo permite sentir la pasión del cante jondo, el baile y el toque en primera fila. Opción de cena con show completo.',
    ARRAY['flamenco', 'experiencias'],
    90,
    'Noche (21:00)',
    'dos_euros',
    'Calle Larga, 15, 11402 Jerez de la Frontera',
    36.6855,
    -6.1395,
    'https://www.tablaopemarte.com/reservas',
    'https://www.tablaopemarte.com',
    ARRAY['Reserva obligatoria', 'Opción cena + show muy recomendable', 'Llega 20 min antes para buena mesa', 'Show de viernes y domingo más íntimo'],
    ARRAY['bailaor', 'cantaor', 'toque', 'jondo', 'jerezano', 'arte'],
    'poi/jerez/tablao_flamenco/tablao_flamenco_1.jpg',
    5
)

ON CONFLICT (external_id) DO UPDATE SET
  title = EXCLUDED.title,
  short_description = EXCLUDED.short_description,
  long_description = EXCLUDED.long_description,
  categories = EXCLUDED.categories,
  recommended_duration_minutes = EXCLUDED.recommended_duration_minutes,
  best_time_to_visit = EXCLUDED.best_time_to_visit,
  price_level = EXCLUDED.price_level,
  address = EXCLUDED.address,
  geo_lat = EXCLUDED.geo_lat,
  geo_lng = EXCLUDED.geo_lng,
  booking_url = EXCLUDED.booking_url,
  website_url = EXCLUDED.website_url,
  tips = EXCLUDED.tips,
  tags = EXCLUDED.tags,
  image_url = EXCLUDED.image_url,
  sort_order = EXCLUDED.sort_order;

-- ============================================
-- LUGARES - ALREDEDORES
-- ============================================
INSERT INTO places (
    external_id, level, title, short_description, long_description,
    categories, recommended_duration_minutes, best_time_to_visit, price_level,
    address, geo_lat, geo_lng, booking_url, website_url,
    tips, tags, image_url, sort_order
) VALUES

-- 1. CÁDIZ CAPITAL
(
    'place-v2-cadiz-capital',
    'alrededores',
    'Cádiz Capital',
    'Una de las ciudades más antiguas de Europa, con playas urbanas y carnaval legendario.',
    'Cádiz tiene más de 3.000 años de historia y se siente en cada rincón. El casco antiguo es un laberinto de plazas y callejuelas que desembocan en la playa de La Caleta. Imprescindibles: la Catedral nueva con vistas al océano, la Torre Tavira (cámara oscura) y el mercado central. El Carnaval de Cádiz, declarado de Interés Turístico Internacional, transforma la ciudad cada febrero.',
    ARRAY['cultura', 'playa', 'monumentos'],
    360,
    'Todo el día',
    'gratis',
    'Cádiz',
    36.5297,
    -6.2927,
    NULL,
    'https://www.cadizturismo.com',
    ARRAY['Catamarán desde El Puerto (30 min)', 'Torre Tavira mejor a primera hora', 'Carnaval: reserva con meses de antelación', 'Mercado Central para tapear'],
    ARRAY['la caleta', 'carnaval', 'fenicios', 'torre tavira', 'atlántico', 'gaditano'],
    'poi/alrededores/cadiz_capital/cadiz_capital_1.jpg',
    10
),

-- 2. EL PUERTO DE SANTA MARÍA
(
    'place-v2-el-puerto',
    'alrededores',
    'El Puerto de Santa María',
    'Ciudad costera con playas vírgenes, bodegas de fino y la mejor gastronomía marinera.',
    'El Puerto es famosa por sus playas vírgenes de La Puntilla, aguas cristalinas y chiringuitos de pescado frito. Las bodegas de fino y amontillado como Osborne o 501 ofrecen catas únicas. Fue puerto de partida de Colón hacia América. El centro histórico conserva mansiones señoriales y la Plaza de Toros más antigua de España en uso.',
    ARRAY['playa', 'enoturismo', 'gastronomia'],
    240,
    'Todo el día',
    'gratis',
    'El Puerto de Santa María, Cádiz',
    36.5944,
    -6.2261,
    NULL,
    NULL,
    ARRAY['Playa La Puntilla a primera hora', 'Bodega Osborne con reserva previa', 'Catamarán a Cádiz cada hora', 'Romijo para pescado frito'],
    ARRAY['fino', 'osborne', 'la puntilla', 'colón', 'pescado frito', 'marinero'],
    'poi/alrededores/el_puerto_santa_maria/el_puerto_santa_maria_1.jpg',
    11
),

-- 3. SANLÚCAR DE BARRAMEDA
(
    'place-v2-sanlucar',
    'alrededores',
    'Sanlúcar de Barrameda',
    'Pueblo pesquero famoso por sus langostinos, manzanilla y las carreras de caballos en la playa.',
    'Sanlúcar es el secreto mejor guardado de la costa gaditana. Sus langostinos de Sanlúcar son únicos por la desembocadura del Guadalquivir. Las bodegas de manzanilla como Barbadillo ofrecen visitas completas. En agosto, las carreras de caballos en la playa son un espectáculo inolvidable. Desde el puerto salen excursiones al Parque de Doñana.',
    ARRAY['playa', 'gastronomia', 'experiencias'],
    240,
    'Todo el día (agosto para carreras)',
    'gratis',
    'Sanlúcar de Barrameda, Cádiz',
    36.7786,
    -6.3525,
    NULL,
    NULL,
    ARRAY['Carreras de caballos: dos fines de semana de agosto', 'Casa Bigote para langostinos', 'Excursión a Doñana desde el puerto', 'Bodega Barbadillo imprescindible'],
    ARRAY['langostinos', 'manzanilla', 'caballos', 'doñana', 'guadalquivir', 'barbadillo'],
    'poi/alrededores/sanlucar_barrameda/sanlucar_barrameda_1.jpg',
    12
),

-- 4. ROTA
(
    'place-v2-rota',
    'alrededores',
    'Rota - Costa de la Luz',
    'Costa con playas infinitas de arena dorada y el encanto de un pueblo pesquero auténtico.',
    'Rota combina kilómetros de playas vírgenes con un casco histórico de casas encaladas. La Playa de la Costilla es la más emblemática, con chiringuitos tradicionales. El Castillo de Luna y la Ermita de la Luz son visitas obligadas. La gastronomía roteña destaca por el urta a la roteña y los pescaítos fritos. Base naval americana que aporta un toque cosmopolita.',
    ARRAY['playa', 'gastronomia'],
    180,
    'Mañana o tarde',
    'gratis',
    'Rota, Cádiz',
    36.6256,
    -6.3625,
    NULL,
    NULL,
    ARRAY['Playa de la Costilla con todos los servicios', 'Chiringuito Antonio para urta', 'Paseo marítimo ideal al atardecer', 'Ferry directo desde Cádiz en verano'],
    ARRAY['costilla', 'urta', 'pescaito frito', 'costa de la luz', 'roteño'],
    'poi/alrededores/rota_playa/rota_playa_1.jpg',
    13
)

ON CONFLICT (external_id) DO UPDATE SET
  title = EXCLUDED.title,
  short_description = EXCLUDED.short_description,
  long_description = EXCLUDED.long_description,
  categories = EXCLUDED.categories,
  recommended_duration_minutes = EXCLUDED.recommended_duration_minutes,
  best_time_to_visit = EXCLUDED.best_time_to_visit,
  price_level = EXCLUDED.price_level,
  address = EXCLUDED.address,
  geo_lat = EXCLUDED.geo_lat,
  geo_lng = EXCLUDED.geo_lng,
  booking_url = EXCLUDED.booking_url,
  website_url = EXCLUDED.website_url,
  tips = EXCLUDED.tips,
  tags = EXCLUDED.tags,
  image_url = EXCLUDED.image_url,
  sort_order = EXCLUDED.sort_order;

-- ============================================
-- LUGARES - PROVINCIA
-- ============================================
INSERT INTO places (
    external_id, level, title, short_description, long_description,
    categories, recommended_duration_minutes, best_time_to_visit, price_level,
    address, geo_lat, geo_lng, booking_url, website_url,
    tips, tags, image_url, sort_order
) VALUES

-- 1. ARCOS DE LA FRONTERA
(
    'place-v2-arcos',
    'provincia',
    'Arcos de la Frontera',
    'El más espectacular de los pueblos blancos, encaramado sobre un peñón con vistas infinitas.',
    'Arcos es la puerta de los Pueblos Blancos y uno de los más impresionantes. Situado sobre un peñón a orillas del embalse, su casco histórico está declarado Conjunto Monumental. La Plaza del Cabildo ofrece vistas vertiginosas, la Iglesia de Santa María es gótico-mudéjar, y el Parador ocupa el antiguo castillo. Calles empedradas, balcones floridos y la luz de Cádiz lo hacen inolvidable.',
    ARRAY['pueblos_blancos', 'monumentos'],
    180,
    'Mañana o tarde',
    'gratis',
    'Arcos de la Frontera, Cádiz',
    36.7494,
    -5.8119,
    NULL,
    NULL,
    ARRAY['Parking en la entrada, luego a pie', 'Mirador de la Ciudad al atardecer', 'Parador para café con vistas', 'Restaurante El Convento'],
    ARRAY['mirador', 'parador', 'embalse', 'mudéjar', 'conjunto monumental', 'pueblo blanco'],
    'poi/provincia/arcos_frontera/arcos_frontera_1.jpg',
    20
),

-- 2. VEJER DE LA FRONTERA
(
    'place-v2-vejer',
    'provincia',
    'Vejer de la Frontera',
    'Pueblo blanco considerado uno de los más bonitos de España, con vistas al Atlántico.',
    'Vejer es un laberinto de calles empedradas, arcos medievales y casas encaladas que parecen suspenderse en el aire. Desde sus miradores se divisa el Atlántico y África en días claros. La plaza de España con su fuente cerámica, la Iglesia del Divino Salvador y el Convento de las Monjas son paradas obligatorias. A 10 km, la Playa de El Palmar es un paraíso surfista.',
    ARRAY['pueblos_blancos', 'playa'],
    180,
    'Mañana o tarde',
    'gratis',
    'Vejer de la Frontera, Cádiz',
    36.2536,
    -5.9669,
    NULL,
    NULL,
    ARRAY['Parking en la entrada del pueblo', 'Restaurante El Jerez (reserva previa)', 'Playa El Palmar a 10 km para atardecer', 'Hotel La Casa del Califa para alojamiento'],
    ARRAY['atlántico', 'el palmar', 'surf', 'mirador', 'medieval', 'africa'],
    'poi/provincia/vejer_frontera/vejer_frontera_1.jpg',
    21
),

-- 3. GRAZALEMA
(
    'place-v2-grazalema',
    'provincia',
    'Parque Natural de Grazalema',
    'El pueblo más lluvioso de España en un parque natural con la Garganta Verde y senderismo único.',
    'Grazalema es el corazón del Parque Natural de la Sierra de Cádiz. El pueblo es famoso por sus mantas de lana artesanales y por ser el más lluvioso de España. La Garganta Verde es una ruta de senderismo espectacular que desciende entre paredes rocosas hasta un salto de agua. Los pinsapos, abetos prehistóricos, son únicos en Europa. Rutas para todos los niveles.',
    ARRAY['naturaleza', 'pueblos_blancos'],
    360,
    'Primavera u otoño',
    'gratis',
    'Grazalema, Cádiz',
    36.7461,
    -5.3642,
    NULL,
    'https://www.grazalema.es',
    ARRAY['Garganta Verde requiere permiso (reserva previa)', 'Calzado de montaña obligatorio', 'Comprar manta de Grazalema de recuerdo', 'Mejor de abril a junio'],
    ARRAY['garganta verde', 'pinsapo', 'senderismo', 'sierra', 'mantas', 'naturaleza'],
    'poi/provincia/grazalema/grazalema_1.jpg',
    22
),

-- 4. TARIFA Y BOLONIA
(
    'place-v2-tarifa-bolonia',
    'provincia',
    'Tarifa y Bolonia',
    'El punto más meridional de Europa: kitesurf, ballenas y playas vírgenes junto a ruinas romanas.',
    'Tarifa es donde se unen el Atlántico y el Mediterráneo. Es la capital europea del kitesurf y windsurf, con vientos constantes todo el año. Las excursiones de avistamiento de cetáceos (orcas, pilot whales, delfines) salen diariamente. La Playa de Bolonia, a 20 min, es una de las últimas playas vírgenes del sur con ruinas romanas de Baelo Claudia. Ferry a Tánger en 35 minutos.',
    ARRAY['playa', 'naturaleza', 'experiencias'],
    480,
    'Todo el día',
    'gratis',
    'Tarifa, Cádiz',
    36.0128,
    -5.6028,
    NULL,
    NULL,
    ARRAY['Avistamiento de cetáceos: reserva en temporada alta', 'Bolonia mejor por la mañana (menos viento)', 'Ferry a Tánger con pasaporte', 'Chiringuito El Faro para atún rojo'],
    ARRAY['kitesurf', 'ballenas', 'estrecho', 'bolonia', 'baelo claudia', 'marruecos', 'tánger'],
    'poi/provincia/tarifa_bolonia/tarifa_bolonia_1.jpg',
    23
)

ON CONFLICT (external_id) DO UPDATE SET
  title = EXCLUDED.title,
  short_description = EXCLUDED.short_description,
  long_description = EXCLUDED.long_description,
  categories = EXCLUDED.categories,
  recommended_duration_minutes = EXCLUDED.recommended_duration_minutes,
  best_time_to_visit = EXCLUDED.best_time_to_visit,
  price_level = EXCLUDED.price_level,
  address = EXCLUDED.address,
  geo_lat = EXCLUDED.geo_lat,
  geo_lng = EXCLUDED.geo_lng,
  booking_url = EXCLUDED.booking_url,
  website_url = EXCLUDED.website_url,
  tips = EXCLUDED.tips,
  tags = EXCLUDED.tags,
  image_url = EXCLUDED.image_url,
  sort_order = EXCLUDED.sort_order;

-- ============================================
-- RELACIONES LUGARES-COLECCIONES
-- ============================================

-- Colección: Imprescindibles en 1 día
INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-v2-alcazar-jerez' AND c.external_id = 'col-v2-imprescindibles'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 2
FROM places p, collections c
WHERE p.external_id = 'place-v2-catedral-jerez' AND c.external_id = 'col-v2-imprescindibles'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 3
FROM places p, collections c
WHERE p.external_id = 'place-v2-bodegas-tio-pepe' AND c.external_id = 'col-v2-imprescindibles'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 4
FROM places p, collections c
WHERE p.external_id = 'place-v2-tablao-flamenco' AND c.external_id = 'col-v2-imprescindibles'
ON CONFLICT DO NOTHING;

-- Colección: Plan romántico
INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-v2-escuela-ecuestre' AND c.external_id = 'col-v2-romantico'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 2
FROM places p, collections c
WHERE p.external_id = 'place-v2-bodegas-tio-pepe' AND c.external_id = 'col-v2-romantico'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 3
FROM places p, collections c
WHERE p.external_id = 'place-v2-vejer' AND c.external_id = 'col-v2-romantico'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 4
FROM places p, collections c
WHERE p.external_id = 'place-v2-sanlucar' AND c.external_id = 'col-v2-romantico'
ON CONFLICT DO NOTHING;

-- Colección: Gastronomía y vino
INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-v2-bodegas-tio-pepe' AND c.external_id = 'col-v2-gastronomia'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 2
FROM places p, collections c
WHERE p.external_id = 'place-v2-el-puerto' AND c.external_id = 'col-v2-gastronomia'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 3
FROM places p, collections c
WHERE p.external_id = 'place-v2-sanlucar' AND c.external_id = 'col-v2-gastronomia'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 4
FROM places p, collections c
WHERE p.external_id = 'place-v2-cadiz-capital' AND c.external_id = 'col-v2-gastronomia'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 5
FROM places p, collections c
WHERE p.external_id = 'place-v2-rota' AND c.external_id = 'col-v2-gastronomia'
ON CONFLICT DO NOTHING;

-- ============================================
-- FOTOS ADICIONALES (3 por lugar)
-- ============================================

-- ALCÁZAR DE JEREZ
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/alcazar_jerez/alcazar_jerez_1.jpg', 'Fachada del Alcázar de Jerez', 1
FROM places WHERE external_id = 'place-v2-alcazar-jerez';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/alcazar_jerez/alcazar_jerez_2.jpg', 'Jardines árabes del Alcázar', 2
FROM places WHERE external_id = 'place-v2-alcazar-jerez';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/alcazar_jerez/alcazar_jerez_3.jpg', 'Vistas desde la torre', 3
FROM places WHERE external_id = 'place-v2-alcazar-jerez';

-- CATEDRAL DE JEREZ
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/catedral_jerez/catedral_jerez_1.jpg', 'Fachada de la Catedral', 1
FROM places WHERE external_id = 'place-v2-catedral-jerez';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/catedral_jerez/catedral_jerez_2.jpg', 'Cúpula de la Catedral', 2
FROM places WHERE external_id = 'place-v2-catedral-jerez';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/catedral_jerez/catedral_jerez_3.jpg', 'Retablo mayor', 3
FROM places WHERE external_id = 'place-v2-catedral-jerez';

-- REAL ESCUELA ECUUESTRE
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/real_escuela_ecuestre/real_escuela_ecuestre_1.jpg', 'Picadero del espectáculo', 1
FROM places WHERE external_id = 'place-v2-escuela-ecuestre';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/real_escuela_ecuestre/real_escuela_ecuestre_2.jpg', 'Caballo cartujano', 2
FROM places WHERE external_id = 'place-v2-escuela-ecuestre';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/real_escuela_ecuestre/real_escuela_ecuestre_3.jpg', 'Cuadras de la Real Escuela', 3
FROM places WHERE external_id = 'place-v2-escuela-ecuestre';

-- BODEGAS TÍO PEPE
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/bodegas_tio_pepe/bodegas_tio_pepe_1.jpg', 'Botella gigante Tío Pepe', 1
FROM places WHERE external_id = 'place-v2-bodegas-tio-pepe';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/bodegas_tio_pepe/bodegas_tio_pepe_2.jpg', 'Bodegas centenarias', 2
FROM places WHERE external_id = 'place-v2-bodegas-tio-pepe';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/bodegas_tio_pepe/bodegas_tio_pepe_3.jpg', 'Cata de vinos', 3
FROM places WHERE external_id = 'place-v2-bodegas-tio-pepe';

-- TABLAO FLAMENCO
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/tablao_flamenco/tablao_flamenco_1.jpg', 'Espectáculo flamenco en vivo', 1
FROM places WHERE external_id = 'place-v2-tablao-flamenco';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/tablao_flamenco/tablao_flamenco_2.jpg', 'Bailaora en el tablao', 2
FROM places WHERE external_id = 'place-v2-tablao-flamenco';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/jerez/tablao_flamenco/tablao_flamenco_3.jpg', 'Ambiente del Tablao Pemarte', 3
FROM places WHERE external_id = 'place-v2-tablao-flamenco';

-- CÁDIZ CAPITAL
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/cadiz_capital/cadiz_capital_1.jpg', 'Playa de La Caleta', 1
FROM places WHERE external_id = 'place-v2-cadiz-capital';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/cadiz_capital/cadiz_capital_2.jpg', 'Catedral de Cádiz', 2
FROM places WHERE external_id = 'place-v2-cadiz-capital';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/cadiz_capital/cadiz_capital_3.jpg', 'Torre Tavira', 3
FROM places WHERE external_id = 'place-v2-cadiz-capital';

-- EL PUERTO DE SANTA MARÍA
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/el_puerto_santa_maria/el_puerto_santa_maria_1.jpg', 'Playa de La Puntilla', 1
FROM places WHERE external_id = 'place-v2-el-puerto';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/el_puerto_santa_maria/el_puerto_santa_maria_2.jpg', 'Bodegas Osborne', 2
FROM places WHERE external_id = 'place-v2-el-puerto';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/el_puerto_santa_maria/el_puerto_santa_maria_3.jpg', 'Casco histórico', 3
FROM places WHERE external_id = 'place-v2-el-puerto';

-- SANLÚCAR DE BARRAMEDA
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/sanlucar_barrameda/sanlucar_barrameda_1.jpg', 'Carreras de caballos en la playa', 1
FROM places WHERE external_id = 'place-v2-sanlucar';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/sanlucar_barrameda/sanlucar_barrameda_2.jpg', 'Langostinos de Sanlúcar', 2
FROM places WHERE external_id = 'place-v2-sanlucar';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/sanlucar_barrameda/sanlucar_barrameda_3.jpg', 'Bodegas Barbadillo', 3
FROM places WHERE external_id = 'place-v2-sanlucar';

-- ROTA
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/rota_playa/rota_playa_1.jpg', 'Playa de la Costilla', 1
FROM places WHERE external_id = 'place-v2-rota';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/rota_playa/rota_playa_2.jpg', 'Castillo de Luna', 2
FROM places WHERE external_id = 'place-v2-rota';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/alrededores/rota_playa/rota_playa_3.jpg', 'Paseo marítimo', 3
FROM places WHERE external_id = 'place-v2-rota';

-- ARCOS DE LA FRONTERA
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/arcos_frontera/arcos_frontera_1.jpg', 'Vista de Arcos desde el embalse', 1
FROM places WHERE external_id = 'place-v2-arcos';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/arcos_frontera/arcos_frontera_2.jpg', 'Plaza del Cabildo', 2
FROM places WHERE external_id = 'place-v2-arcos';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/arcos_frontera/arcos_frontera_3.jpg', 'Callejas del casco histórico', 3
FROM places WHERE external_id = 'place-v2-arcos';

-- VEJER DE LA FRONTERA
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/vejer_frontera/vejer_frontera_1.jpg', 'Vista de Vejer', 1
FROM places WHERE external_id = 'place-v2-vejer';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/vejer_frontera/vejer_frontera_2.jpg', 'Plaza de España', 2
FROM places WHERE external_id = 'place-v2-vejer';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/vejer_frontera/vejer_frontera_3.jpg', 'Playa de El Palmar', 3
FROM places WHERE external_id = 'place-v2-vejer';

-- GRAZALEMA
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/grazalema/grazalema_1.jpg', 'Pueblo de Grazalema', 1
FROM places WHERE external_id = 'place-v2-grazalema';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/grazalema/grazalema_2.jpg', 'Garganta Verde', 2
FROM places WHERE external_id = 'place-v2-grazalema';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/grazalema/grazalema_3.jpg', 'Pinsapos en la sierra', 3
FROM places WHERE external_id = 'place-v2-grazalema';

-- TARIFA Y BOLONIA
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/tarifa_bolonia/tarifa_bolonia_1.jpg', 'Playa de Tarifa', 1
FROM places WHERE external_id = 'place-v2-tarifa-bolonia';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/tarifa_bolonia/tarifa_bolonia_2.jpg', 'Ruinas de Baelo Claudia', 2
FROM places WHERE external_id = 'place-v2-tarifa-bolonia';
INSERT INTO place_photos (place_id, image_url, image_alt, sort_order)
SELECT id, 'poi/provincia/tarifa_bolonia/tarifa_bolonia_3.jpg', 'Kitesurf en Tarifa', 3
FROM places WHERE external_id = 'place-v2-tarifa-bolonia';

-- ============================================
-- RESUMEN FINAL
-- ============================================
SELECT '✅ Seed ¿Qué Ver? v2 completado' as status;
SELECT
    level,
    COUNT(*) as total
FROM places
WHERE external_id LIKE 'place-v2-%'
GROUP BY level
ORDER BY level;
SELECT
    c.title as coleccion,
    COUNT(pc.id) as lugares
FROM collections c
LEFT JOIN place_collections pc ON c.id = pc.collection_id
WHERE c.external_id LIKE 'col-v2-%'
GROUP BY c.id, c.title
ORDER BY c.sort_order;
