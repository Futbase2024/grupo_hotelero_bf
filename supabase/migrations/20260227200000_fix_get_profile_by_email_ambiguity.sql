-- Corregir ambigüedad en la función get_profile_by_email
-- El error "column reference "email" is ambiguous" ocurría porque
-- la columna "email" podía referirse tanto a la variable de salida
-- del RETURNS TABLE como a la columna de la tabla profiles.

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
    SELECT
        profiles.id,
        profiles.user_id,
        profiles.email,
        profiles.full_name,
        profiles.phone,
        profiles.document_type,
        profiles.document_number,
        profiles.nationality,
        profiles.birth_date,
        profiles.created_at,
        profiles.updated_at
    FROM profiles
    WHERE profiles.email ILIKE p_email
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_profile_by_email(TEXT) IS 'Busca un perfil por email (case-insensitive). Corregido para evitar ambigüedad de columnas.';
