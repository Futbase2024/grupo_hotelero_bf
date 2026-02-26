-- ============================================
-- SEED SQL: ¿QUÉ VER? - LUGARES Y EXPERIENCIAS
-- Proyecto: BF Stay
-- Fecha: 2025-01-25
-- ============================================

-- Crear tipo ENUM para nivel geográfico
DO $$ BEGIN
    CREATE TYPE place_level AS ENUM ('jerez', 'alrededores', 'provincia');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Crear tipo ENUM para nivel de precio
DO $$ BEGIN
    CREATE TYPE price_level AS ENUM ('gratis', 'un_euro', 'dos_euros', 'tres_euros');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- TABLA: places (lugares/experiencias turísticas)
-- ============================================
CREATE TABLE IF NOT EXISTS places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(100) UNIQUE NOT NULL,
    level place_level NOT NULL DEFAULT 'jerez',
    title VARCHAR(255) NOT NULL,
    short_description TEXT NOT NULL,
    long_description TEXT,
    categories TEXT[] NOT NULL DEFAULT '{}',
    recommended_duration_minutes INTEGER,
    best_time_to_visit VARCHAR(100),
    price_level price_level,
    address TEXT,
    geo_lat DECIMAL(10, 8),
    geo_lng DECIMAL(11, 8),
    booking_url TEXT,
    website_url TEXT,
    tips TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    image_url TEXT,
    image_alt VARCHAR(255),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para búsquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_places_level ON places(level);
CREATE INDEX IF NOT EXISTS idx_places_categories ON places USING GIN(categories);
CREATE INDEX IF NOT EXISTS idx_places_tags ON places USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_places_is_active ON places(is_active);
CREATE INDEX IF NOT EXISTS idx_places_sort_order ON places(sort_order);

-- ============================================
-- TABLA: collections (colecciones de lugares)
-- ============================================
CREATE TABLE IF NOT EXISTS collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(100) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(20),
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLA: place_collections (relación lugares-colecciones)
-- ============================================
CREATE TABLE IF NOT EXISTS place_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    UNIQUE(place_id, collection_id)
);

-- ============================================
-- TABLA: place_photos (fotos de lugares)
-- ============================================
CREATE TABLE IF NOT EXISTS place_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_alt VARCHAR(255),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_place_photos_place_id ON place_photos(place_id);

-- ============================================
-- DATOS DE EJEMPLO: COLECCIONES
-- ============================================
INSERT INTO collections (external_id, title, description, icon, color, sort_order) VALUES
('col-bodegas', 'Ruta del Vino', 'Descubre las mejores bodegas de Jerez y disfruta de catas de vino únicas', 'wine_bar', '#7B1F3E', 1),
('col-monumentos', 'Monumentos Históricos', 'Explora el rico patrimonio histórico de Jerez de la Frontera', 'account_balance', '#5D4037', 2),
('col-flamenco', 'Flamenco', 'Vive el arte flamenco en su tierra de origen', 'music_note', '#C62828', 3),
('col-familia', 'En Familia', 'Actividades perfectas para disfrutar con niños', 'family_restroom', '#1565C0', 4),
('col-gastronomia', 'Gastronomía', 'Los mejores restaurantes y tapas de la zona', 'restaurant', '#E65100', 5),
('col-naturaleza', 'Naturaleza', 'Espacios naturales y actividades al aire libre', 'park', '#2E7D32', 6)
ON CONFLICT (external_id) DO NOTHING;

-- ============================================
-- DATOS DE EJEMPLO: LUGARES EN JEREZ
-- ============================================
INSERT INTO places (
    external_id, level, title, short_description, long_description,
    categories, recommended_duration_minutes, best_time_to_visit, price_level,
    address, geo_lat, geo_lng, booking_url, website_url,
    tips, tags, image_url, sort_order
) VALUES
-- BODEGAS
(
    'place-gonzalez-byass',
    'jerez',
    'Bodegas González Byass',
    'Una de las bodegas más emblemáticas de Jerez, famosa por su Tío Pepe',
    'Fundada en 1835, González Byass es una de las bodegas más prestigiosas de Jerez. Ofrece visitas guiadas que incluyen los viñedos, las bodegas históricas donde se añeja el vino, y una cata de sus mejores productos. Destaca la colección de barriles firmados por personalidades como Churchill o Spielberg.',
    ARRAY['bodega', 'vino', 'cata', 'cultura'],
    120,
    'Mañana o tarde',
    'dos_euros',
    'Calle Manuel María González, 12, 11403 Jerez de la Frontera',
    36.6825,
    -6.1369,
    'https://www.gonzalezbyass.com/visitas/',
    'https://www.gonzalezbyass.com',
    ARRAY['Reserva con antelación', 'Visita recomendada de 2 horas', 'Tienda de vinos disponible'],
    ARRAY['tío pepe', 'sherry', 'jerez', 'brandy'],
    NULL,
    1
),
(
    'place-haro',
    'jerez',
    'Bodegas Lustau - Haro',
    'Bodega centenaria especializada en vinos de Jerez de alta calidad',
    'Situada en el corazón del marco de Jerez, Bodegas Lustau ofrece una experiencia enológica única. Sus vinos han sido reconocidos internacionalmente y las visitas incluyen una explicación detallada del proceso de elaboración del vino de Jerez.',
    ARRAY['bodega', 'vino', 'cata'],
    90,
    'Mañana',
    'dos_euros',
    'Calle Arcos, 53, 11402 Jerez de la Frontera',
    36.6850,
    -6.1380,
    NULL,
    'https://www.lustau.es',
    ARRAY['Catas premium disponibles', 'Grupo reducido recomendado'],
    ARRAY['sherry', 'manzanilla', 'amontillado'],
    NULL,
    2
),
(
    'place-domecq',
    'jerez',
    'Bodegas Domecq',
    'Bodega histórica con más de 300 años de tradición vinícola',
    'Una de las bodegas más antiguas de Jerez, Domecq representa la esencia del vino jerezano. Su arquitectura tradicional y sus cavas centenarias hacen de esta visita una experiencia inolvidable.',
    ARRAY['bodega', 'vino', 'historia'],
    90,
    'Cualquier hora',
    'dos_euros',
    'Calle Cordobeses, 3, 11403 Jerez de la Frontera',
    36.6810,
    -6.1350,
    NULL,
    NULL,
    ARRAY['Fundada en 1730', 'Arquitectura del siglo XVIII'],
    ARRAY['fundador', 'rioja', 'tradicional'],
    NULL,
    3
),

-- MONUMENTOS
(
    'place-alcazar',
    'jerez',
    'Alcázar de Jerez',
    'Fortaleza del siglo XI con jardines árabes y cámara oscura',
    'El Alcázar de Jerez es una fortaleza de origen almohade que data del siglo XI. Incluye la mezquita más antigua de la ciudad, los baños árabes, los jardines y la cámara oscura desde donde se pueden ver vistas panorámicas de Jerez.',
    ARRAY['monumento', 'historia', 'arquitectura', 'jardín'],
    90,
    'Mañana o tarde',
    'un_euro',
    'Alameda Vieja, s/n, 11403 Jerez de la Frontera',
    36.6833,
    -6.1389,
    NULL,
    NULL,
    ARRAY['No te pierdas la cámara oscura', 'Jardines muy bonitos', 'Vistas panorámicas'],
    ARRAY['almohade', 'árabe', 'medieval', 'fortaleza'],
    NULL,
    4
),
(
    'place-catedral',
    'jerez',
    'Catedral de Jerez',
    'Impresionante catedral del siglo XVII con estilo barroco',
    'La Catedral de San Salvador es un edificio religioso del siglo XVII que combina elementos góticos, barrocos y neoclásicos. Destacan su retablo mayor, la sillería del coro y la impresionante cúpula.',
    ARRAY['monumento', 'religioso', 'historia'],
    60,
    'Mañana',
    'gratis',
    'Plaza de la Encarnación, 11402 Jerez de la Frontera',
    36.6847,
    -6.1375,
    NULL,
    NULL,
    ARRAY['Horario de misas', 'Entrada gratuita'],
    ARRAY['barroco', 'gótico', 'patrimonio'],
    NULL,
    5
),

-- FLAMENCO
(
    'place-tablao-flamenco',
    'jerez',
    'Tablao Flamenco Pemarte',
    'El tablao más emblemático de Jerez para disfrutar del flamenco auténtico',
    'Situado en el centro de Jerez, el Tablao Flamenco Pemarte ofrece espectáculos de flamenco en vivo con artistas locales de renombre. El ambiente íntimo permite apreciar la pasión y el arte del flamenco jerezano.',
    ARRAY['flamenco', 'espectáculo', 'cultura', 'noche'],
    90,
    'Noche (21:00 - 23:00)',
    'tres_euros',
    'Calle Larga, 15, 11402 Jerez de la Frontera',
    36.6855,
    -6.1395,
    'https://www.tablaopemarte.com',
    'https://www.tablaopemarte.com',
    ARRAY['Reserva obligatoria', 'Cena disponible', 'Espectáculo de 1 hora'],
    ARRAY['bailaor', 'cantaor', 'guitarra', 'jerezano'],
    NULL,
    6
),

-- FAMILIA
(
    'place-zoobotanico',
    'jerez',
    'Zoobotánico de Jerez',
    'Zoológico y jardín botánico con más de 200 especies animales',
    'El Zoobotánico de Jerez combina un zoológico moderno con un jardín botánico. Cuenta con más de 200 especies de animales en entornos naturalizados y una extensa colección de plantas. Ideal para visitar en familia.',
    ARRAY['familia', 'animales', 'naturaleza', 'botánico'],
    180,
    'Mañana (10:00 - 14:00)',
    'dos_euros',
    'Calle Madre de Dios, s/n, 11407 Jerez de la Frontera',
    36.6950,
    -6.1250,
    NULL,
    'https://www.zoobotanicojerez.com',
    ARRAY['Lleva calzado cómodo', 'Fuente de agua disponible', 'Picnic permitido'],
    ARRAY['niños', 'leones', 'jirafas', 'plantas'],
    NULL,
    7
),

-- GASTRONOMÍA
(
    'place-mercado-central',
    'jerez',
    'Mercado Central de Abastos',
    'El mercado más tradicional de Jerez con productos frescos locales',
    'El Mercado Central de Jerez es el lugar perfecto para descubrir los productos locales: pescado fresco de la costa gaditana, verduras de la huerta jerezana, y por supuesto, los mejores ibéricos. Ideal para tapear.',
    ARRAY['gastronomía', 'mercado', 'tapas', 'local'],
    60,
    'Mañana (8:00 - 14:00)',
    'gratis',
    'Plaza del Mercado, 11402 Jerez de la Frontera',
    36.6860,
    -6.1370,
    NULL,
    NULL,
    ARRAY['Mejor hora: 10:00 - 12:00', 'Cierra por las tardes', 'Prueba las tapas dentro'],
    ARRAY['pescado', 'ibérico', 'verdura', 'tradicional'],
    NULL,
    8
)

ON CONFLICT (external_id) DO NOTHING;

-- ============================================
-- DATOS DE EJEMPLO: LUGARES EN ALREDEDORES
-- ============================================
INSERT INTO places (
    external_id, level, title, short_description, long_description,
    categories, recommended_duration_minutes, best_time_to_visit, price_level,
    address, geo_lat, geo_lng, booking_url, website_url,
    tips, tags, image_url, sort_order
) VALUES
(
    'place-sanlucar',
    'alrededores',
    'Sanlúcar de Barrameda',
    'Pueblo costero famoso por sus langostinos y las carreras de caballos en la playa',
    'Sanlúcar de Barrameda es un encantador pueblo pesquero situado en la desembocadura del Guadalquivir. Famoso por sus langostinos, el manzanilla y las carreras de caballos que se celebran en la playa durante el verano.',
    ARRAY['playa', 'gastronomía', 'pueblo', 'caballos'],
    240,
    'Todo el día',
    'gratis',
    'Sanlúcar de Barrameda, Cádiz',
    36.7786,
    -6.3525,
    NULL,
    NULL,
    ARRAY['Carreras de caballos en agosto', 'Prueba los langostinos', 'Visita las bodegas de manzanilla'],
    ARRAY['langostinos', 'manzanilla', 'guadalquivir', 'doñana'],
    NULL,
    10
),
(
    'place-arcos',
    'alrededores',
    'Arcos de la Frontera',
    'Pueblo blanco con impresionantes vistas al embalse y rica historia',
    'Arcos de la Frontera es uno de los pueblos blancos más bonitos de Cádiz. Situado sobre un peñón, ofrece vistas espectaculares del embalse y la campiña. Su casco histórico está declarado Conjunto Monumental.',
    ARRAY['pueblo blanco', 'historia', 'vistas', 'monumento'],
    180,
    'Mañana o tarde',
    'gratis',
    'Arcos de la Frontera, Cádiz',
    36.7494,
    -5.8119,
    NULL,
    NULL,
    ARRAY['Parking limitado en el centro', 'Mejor visitar a pie', 'Mirador de la ciudad es imprescindible'],
    ARRAY['pueblos blancos', 'mirador', 'iglesia', 'parador'],
    NULL,
    11
),
(
    'place-puerto-santa-maria',
    'alrededores',
    'El Puerto de Santa María',
    'Ciudad costera con playas vírgenes y excelente gastronomía',
    'El Puerto de Santa María es conocida por sus playas vírgenes de La Puntilla, sus bodegas de fino y su rica gastronomía. Fue el puerto desde donde Colón partió hacia América.',
    ARRAY['playa', 'bodega', 'gastronomía', 'historia'],
    240,
    'Todo el día',
    'gratis',
    'El Puerto de Santa María, Cádiz',
    36.5944,
    -6.2261,
    NULL,
    NULL,
    ARRAY['Playa de La Puntilla', 'Catamarán a Cádiz', 'Bodegas Osborne'],
    ARRAY['fino', 'colón', 'playas vírgenes', 'pescado frito'],
    NULL,
    12
)

ON CONFLICT (external_id) DO NOTHING;

-- ============================================
-- DATOS DE EJEMPLO: LUGARES EN LA PROVINCIA
-- ============================================
INSERT INTO places (
    external_id, level, title, short_description, long_description,
    categories, recommended_duration_minutes, best_time_to_visit, price_level,
    address, geo_lat, geo_lng, booking_url, website_url,
    tips, tags, image_url, sort_order
) VALUES
(
    'place-cadiz',
    'provincia',
    'Cádiz Capital',
    'Una de las ciudades más antiguas de Europa occidental con playas urbanas',
    'Cádiz es una de las ciudades más antiguas de Europa, con más de 3.000 años de historia. Su casco antiguo, las playas urbanas como La Caleta, y el Carnaval la hacen un destino imprescindible.',
    ARRAY['ciudad', 'playa', 'historia', 'carnaval'],
    480,
    'Todo el día',
    'gratis',
    'Cádiz',
    36.5297,
    -6.2927,
    NULL,
    NULL,
    ARRAY['Torre Tavira imprescindible', 'Carnaval en febrero', 'Catamarán desde El Puerto'],
    ARRAY['la caleta', 'carnaval', 'fenicios', 'atlántico'],
    NULL,
    20
),
(
    'place-vejer',
    'provincia',
    'Vejer de la Frontera',
    'Pueblo blanco considerado uno de los más bonitos de España',
    'Vejer de la Frontera es un pueblo blanco espectacular situado sobre una colina. Su laberinto de calles empedradas, casas encaladas y vistas al Atlántico lo convierten en una visita obligada.',
    ARRAY['pueblo blanco', 'vistas', 'arquitectura'],
    180,
    'Mañana o tarde',
    'gratis',
    'Vejer de la Frontera, Cádiz',
    36.2536,
    -5.9669,
    NULL,
    NULL,
    ARRAY['Restaurante El Jerez', 'Playa de El Palmar a 10 km', 'Parking en la entrada'],
    ARRAY['atlántico', 'casco antiguo', 'encalado'],
    NULL,
    21
),
(
    'place-tarifa',
    'provincia',
    'Tarifa',
    'El punto más meridional de Europa, paraíso del kitesurf y avistamiento de cetáceos',
    'Tarifa es el punto más al sur de Europa continental, donde se unen el Atlántico y el Mediterráneo. Es el paraíso europeo del kitesurf y punto de partida para avistamiento de ballenas en el Estrecho.',
    ARRAY['playa', 'deportes', 'naturaleza', 'avistamiento'],
    480,
    'Todo el día',
    'gratis',
    'Tarifa, Cádiz',
    36.0128,
    -5.6028,
    NULL,
    NULL,
    ARRAY['Avistamiento de cetáceos', 'Viento constante', 'Ferry a Marruecos'],
    ARRAY['kitesurf', 'ballenas', 'estrecho', 'marruecos'],
    NULL,
    22
),
(
    'place-grazalema',
    'provincia',
    'Parque Natural de Grazalema',
    'Parque natural con el pueblo más lluvioso de España y rutas de senderismo',
    'El Parque Natural de Grazalema es uno de los espacios naturales más importantes de Andalucía. Incluye el pueblo de Grazalema, famoso por ser el más lluvioso de España, y la Garganta Verde.',
    ARRAY['naturaleza', 'senderismo', 'pueblo blanco'],
    360,
    'Primavera u otoño',
    'gratis',
    'Grazalema, Cádiz',
    36.7461,
    -5.3642,
    NULL,
    'https://www.grazalema.es',
    ARRAY['Reserva necesaria para la Garganta Verde', 'Calzado de montaña', 'Mantas de Grazalema'],
    ARRAY['sierra', 'garganta verde', 'pinsapo', 'lluvia'],
    NULL,
    23
)

ON CONFLICT (external_id) DO NOTHING;

-- ============================================
-- RELACIONES LUGARES-COLECCIONES
-- ============================================
INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-gonzalez-byass' AND c.external_id = 'col-bodegas'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 2
FROM places p, collections c
WHERE p.external_id = 'place-haro' AND c.external_id = 'col-bodegas'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 3
FROM places p, collections c
WHERE p.external_id = 'place-domecq' AND c.external_id = 'col-bodegas'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-alcazar' AND c.external_id = 'col-monumentos'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 2
FROM places p, collections c
WHERE p.external_id = 'place-catedral' AND c.external_id = 'col-monumentos'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-tablao-flamenco' AND c.external_id = 'col-flamenco'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-zoobotanico' AND c.external_id = 'col-familia'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-mercado-central' AND c.external_id = 'col-gastronomia'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-sanlucar' AND c.external_id = 'col-gastronomia'
ON CONFLICT DO NOTHING;

INSERT INTO place_collections (place_id, collection_id, sort_order)
SELECT p.id, c.id, 1
FROM places p, collections c
WHERE p.external_id = 'place-grazalema' AND c.external_id = 'col-naturaleza'
ON CONFLICT DO NOTHING;

-- ============================================
-- FUNCIONES ÚTILES
-- ============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para actualizar updated_at
DROP TRIGGER IF EXISTS update_places_updated_at ON places;
CREATE TRIGGER update_places_updated_at
    BEFORE UPDATE ON places
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_collections_updated_at ON collections;
CREATE TRIGGER update_collections_updated_at
    BEFORE UPDATE ON collections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista de lugares con sus colecciones
CREATE OR REPLACE VIEW v_places_with_collections AS
SELECT
    p.*,
    COALESCE(
        ARRAY_AGG(DISTINCT c.title) FILTER (WHERE c.id IS NOT NULL),
        '{}'
    ) as collection_titles
FROM places p
LEFT JOIN place_collections pc ON p.id = pc.place_id
LEFT JOIN collections c ON pc.collection_id = c.id
GROUP BY p.id;

-- ============================================
-- COMENTARIOS
-- ============================================
COMMENT ON TABLE places IS 'Lugares y experiencias turísticas para recomendar a los huéspedes';
COMMENT ON TABLE collections IS 'Colecciones temáticas de lugares (ej: Ruta del Vino, En Familia)';
COMMENT ON TABLE place_collections IS 'Relación many-to-many entre lugares y colecciones';
COMMENT ON TABLE place_photos IS 'Fotos adicionales de cada lugar';

COMMENT ON COLUMN places.level IS 'Nivel geográfico: jerez, alrededores, provincia';
COMMENT ON COLUMN places.price_level IS 'Nivel de precio: gratis, un_euro, dos_euros, tres_euros';
COMMENT ON COLUMN places.categories IS 'Array de categorías para filtrado';
COMMENT ON COLUMN places.tags IS 'Tags para búsqueda';
COMMENT ON COLUMN places.tips IS 'Consejos útiles para el visitante';

-- ============================================
-- FINALIZACIÓN
-- ============================================
SELECT 'Seed ¿Qué Ver? completado correctamente' as status;
SELECT COUNT(*) as total_places FROM places;
SELECT COUNT(*) as total_collections FROM collections;
