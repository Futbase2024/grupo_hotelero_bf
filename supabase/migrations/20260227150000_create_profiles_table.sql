-- Tabla de perfiles de usuario para almacenar datos persistentes
-- como documento de identidad, nacionalidad, etc.

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone TEXT,
    document_type TEXT CHECK (document_type IN ('dni', 'nie', 'passport', 'other')),
    document_number TEXT,
    nationality TEXT,
    birth_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Un perfil por email (unique)
    CONSTRAINT profiles_email_unique UNIQUE (email),

    -- Un perfil por usuario (si tiene user_id)
    CONSTRAINT profiles_user_id_unique UNIQUE (user_id)
);

-- Índices para búsquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_document_number ON profiles(document_number);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Los usuarios pueden ver su propio perfil
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT
    USING (auth.uid() = user_id OR email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Los usuarios pueden insertar su propio perfil
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = user_id OR email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Función para crear o actualizar perfil (upsert)
CREATE OR REPLACE FUNCTION upsert_profile(
    p_email TEXT,
    p_user_id UUID DEFAULT NULL,
    p_full_name TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_document_type TEXT DEFAULT NULL,
    p_document_number TEXT DEFAULT NULL,
    p_nationality TEXT DEFAULT NULL,
    p_birth_date DATE DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_profile_id UUID;
BEGIN
    -- Intentar actualizar si existe
    UPDATE profiles SET
        user_id = COALESCE(p_user_id, user_id),
        full_name = COALESCE(p_full_name, full_name),
        phone = COALESCE(p_phone, phone),
        document_type = COALESCE(p_document_type, document_type),
        document_number = COALESCE(p_document_number, document_number),
        nationality = COALESCE(p_nationality, nationality),
        birth_date = COALESCE(p_birth_date, birth_date),
        updated_at = NOW()
    WHERE email = p_email
    RETURNING id INTO v_profile_id;

    -- Si no existe, insertar
    IF v_profile_id IS NULL THEN
        INSERT INTO profiles (
            email, user_id, full_name, phone,
            document_type, document_number, nationality, birth_date
        ) VALUES (
            p_email, p_user_id, p_full_name, p_phone,
            p_document_type, p_document_number, p_nationality, p_birth_date
        )
        RETURNING id INTO v_profile_id;
    END IF;

    RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para buscar perfil por email
CREATE OR REPLACE FUNCTION get_profile_by_email(p_email TEXT)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    email TEXT,
    full_name TEXT,
    phone TEXT,
    document_type TEXT,
    document_number TEXT,
    nationality TEXT,
    birth_date DATE,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM profiles
    WHERE email ILIKE p_email
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentario descriptivo
COMMENT ON TABLE profiles IS 'Perfiles de usuario con datos persistentes como documento de identidad';
