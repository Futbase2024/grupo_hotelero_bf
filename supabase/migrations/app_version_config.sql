-- =====================================================
-- TABLA: app_config
-- DESCRIPCIÓN: Almacena configuraciones generales de la app
-- Incluye control de versiones para actualizaciones
-- =====================================================

-- Crear tabla de configuración
CREATE TABLE IF NOT EXISTS app_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL DEFAULT '{}',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para búsquedas por key
CREATE INDEX IF NOT EXISTS idx_app_config_key ON app_config(key);

-- Habilitar RLS
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden leer configuración (necesario para que la app funcione)
CREATE POLICY "Anyone can read app_config"
    ON app_config FOR SELECT
    USING (true);

-- Política: Solo admins pueden modificar configuración
CREATE POLICY "Only admins can insert app_config"
    ON app_config FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role = 'admin'
        )
    );

CREATE POLICY "Only admins can update app_config"
    ON app_config FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role = 'admin'
        )
    );

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_app_config_updated_at
    BEFORE UPDATE ON app_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CONFIGURACIÓN INICIAL DE VERSIONES
-- =====================================================

-- Insertar configuración de versión por defecto (separada por plataforma)
INSERT INTO app_config (key, value, description) VALUES (
    'app_version',
    '{
        "ios": {
            "latest_version": "1.0.1",
            "minimum_version": "1.0.0",
            "force_update": false,
            "app_store_id": "6759832221",
            "update_message": "Hay una nueva versión disponible con mejoras y correcciones."
        },
        "android": {
            "latest_version": "1.0.0",
            "minimum_version": "1.0.0",
            "force_update": false,
            "package_name": "com.bfstay.app",
            "update_message": "Hay una nueva versión disponible con mejoras y correcciones."
        }
    }'::jsonb,
    'Configuración de versiones de la aplicación para control de actualizaciones (por plataforma)'
) ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- COMENTARIOS
-- =====================================================

COMMENT ON TABLE app_config IS 'Tabla de configuración general de la aplicación';
COMMENT ON COLUMN app_config.key IS 'Clave única de la configuración';
COMMENT ON COLUMN app_config.value IS 'Valor de la configuración en formato JSON';
COMMENT ON COLUMN app_config.description IS 'Descripción de qué hace esta configuración';

-- =====================================================
-- EJEMPLO DE USO PARA ACTUALIZAR VERSIONES
-- =====================================================

-- Para actualizar solo iOS (por ejemplo, cuando se despliega en App Store):
/*
UPDATE app_config
SET value = jsonb_set(
    jsonb_set(
        jsonb_set(
            value,
            '{ios,latest_version}',
            '"1.0.2"'
        ),
        '{ios,minimum_version}',
        '"1.0.1"'
    ),
    '{ios,force_update}',
    'true'
)
WHERE key = 'app_version';
*/

-- Para actualizar solo Android:
/*
UPDATE app_config
SET value = jsonb_set(
    jsonb_set(
        value,
        '{android,latest_version}',
        '"1.0.2"'
    ),
    '{android,force_update}',
    'false'
)
WHERE key = 'app_version';
*/

-- Para desactivar actualización forzada en iOS:
/*
UPDATE app_config
SET value = jsonb_set(value, '{ios,force_update}', 'false')
WHERE key = 'app_version';
*/

-- Actualizar completo (recomendado para cambios grandes):
/*
UPDATE app_config
SET value = '{
    "ios": {
        "latest_version": "1.0.2",
        "minimum_version": "1.0.1",
        "force_update": true,
        "app_store_id": "6759832221",
        "update_message": "Actualización importante disponible."
    },
    "android": {
        "latest_version": "1.0.1",
        "minimum_version": "1.0.0",
        "force_update": false,
        "package_name": "com.bfstay.app",
        "update_message": "Nueva versión disponible."
    }
}'::jsonb
WHERE key = 'app_version';
*/
