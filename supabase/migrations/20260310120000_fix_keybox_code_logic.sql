-- 20260310120000_fix_keybox_code_logic.sql
-- Modifica el trigger set_keybox_code_on_insert para usar el box_code de la unidad en lugar de código aleatorio
-- Con excepción especial para "Apartamento Bandera" que usa el main_door_keycode de la propiedad
-- También elimina la restricción de unicidad para permitir códigos duplicados

-- ═══════════════════════════════════════════════════════════════════
-- 1. Eliminar el trigger existente
-- ═══════════════════════════════════════════════════════════════════

DROP TRIGGER IF EXISTS trigger_set_keybox_code ON public.bookings;

-- ═══════════════════════════════════════════════════════════════════
-- 2. Eliminar la restricción de unicidad del keybox_code
-- ═══════════════════════════════════════════════════════════════════

DROP INDEX IF EXISTS public.bookings_keybox_code_unique_idx;

-- ═══════════════════════════════════════════════════════════════════
-- 3. Eliminar la función existente
-- ═══════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.set_keybox_code_on_insert;

-- ═══════════════════════════════════════════════════════════════════
-- 4. Crear nueva función con la lógica actualizada
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.set_keybox_code_on_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_box_code text;
    v_property_name text;
    v_main_door_keycode text;
    v_is_bandera boolean := false;
BEGIN
    -- Obtener la unidad y propiedad asociadas a la reserva
    SELECT u.box_code,
           p.name AS property_name,
           p.main_door_keycode
    INTO v_box_code, v_property_name, v_main_door_keycode
    FROM public.units u
    JOIN public.properties p ON u.property_id = p.id
    WHERE u.id = NEW.unit_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la unidad para la reserva';
    END IF;

    -- Verificar si es "Apartamento Bandera" (por nombre de propiedad)
    v_is_bandera := (v_property_name ILIKE '%bandera%');

    -- Determinar el código a usar
    IF v_is_bandera THEN
        -- Para Apartamento Bandera: usar el código de la puerta principal de la propiedad
        v_box_code := v_main_door_keycode;
    ELSE
        -- Para el resto de unidades: usar el código de la caja de la unidad
        v_box_code := v_box_code;
    END IF;

    -- Si no hay código disponible, generar uno aleatorio (fallback)
    IF v_box_code IS NULL OR v_box_code = '' THEN
        v_box_code := public.generate_unique_keybox_code();
    END IF;

    -- Establecer el código en la reserva
    NEW.keybox_code := v_box_code;

    RETURN NEW;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════
-- 5. Crear el trigger
-- ═══════════════════════════════════════════════════════════════════

CREATE TRIGGER set_keybox_code_on_insert
    BEFORE INSERT ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_keybox_code_on_insert();

-- ═══════════════════════════════════════════════════════════════════
-- 6. Actualizar reservas existentes con los códigos correctos
-- ═══════════════════════════════════════════════════════════════════

UPDATE public.bookings b
SET keybox_code = CASE
    WHEN p.name ILIKE '%bandera%' THEN p.main_door_keycode
    ELSE u.box_code
END
FROM public.units u
JOIN public.properties p ON u.property_id = p.id
WHERE b.unit_id = u.id;

-- ═══════════════════════════════════════════════════════════════════
-- 7. Comentario documental
-- ═══════════════════════════════════════════════════════════════════

COMMENT ON FUNCTION public.set_keybox_code_on_insert IS
'Asigna automáticamente el código keybox_code a la reserva basándose en:
1. Para "Apartamento Bandera" (propiedad con "Bandera" en el nombre)
   - Código de la puerta principal (properties.main_door_keycode)
2. Para el resto de unidades
   - Código de la caja de llaves (units.box_code)
3. Si no hay código configurado
   - Genera código aleatorio de 4 dígitos (fallback)

NOTA: Se eliminó la restricción de unicidad bookings_keybox_code_unique_idx
para permitir que múltiples reservas de la misma unidad tengan el mismo código.';
