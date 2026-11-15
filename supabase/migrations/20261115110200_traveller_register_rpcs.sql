-- ============================================================================
-- Registro de viajeros (RD 933/2021) — 3/3: RPCs
-- ----------------------------------------------------------------------------
-- Públicas (authenticated; comprobación de acceso interna):
--   · save_traveller_guest(booking, guest|null, data)  → crea/edita un huésped
--   · traveller_register_issues(booking)               → qué falta y quién firma
--   · sign_traveller_entry_form(booking, guest, svg, version) → parte + firma
--   · submit_traveller_checkin(booking)                → envía el check-in si
--                                                         el registro está completo
-- Internas (sin EXECUTE para authenticated):
--   · _can_access_traveller_register, _traveller_issue,
--     _traveller_guest_issues, _traveller_guest_snapshot
--
-- Reglas legales centralizadas en _traveller_guest_issues(). Los umbrales
-- (14 años firma propia, 18 años documento/domicilio/contacto, parentesco del
-- menor) siguen el Anexo I del RD 933/2021 y están PENDIENTES DE VALIDAR CON
-- ASESORÍA antes de producción.
--
-- No se modifica ninguna RPC existente: las versiones antiguas de la app
-- siguen funcionando con insert_guest_for_booking / submit_guest_checkin.
-- Rollback: 20261115110200_traveller_register_rpcs.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) Helpers internos
-- ----------------------------------------------------------------------------
-- p_write = true exige además que la reserva admita cambios del huésped
CREATE OR REPLACE FUNCTION public._can_access_traveller_register(
  p_booking_id UUID,
  p_write BOOLEAN
)
 RETURNS BOOLEAN
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT auth.role() = 'service_role'
    OR (public.is_staff() AND EXISTS (
          SELECT 1 FROM public.bookings b
           WHERE b.id = p_booking_id
             AND (public.is_admin() OR b.property_id = public.current_property_id())))
    OR EXISTS (
          SELECT 1 FROM public.bookings b
           WHERE b.id = p_booking_id
             AND b.primary_guest_user_id = auth.uid()
             AND (NOT p_write OR b.status IN ('confirmed', 'checked_in')));
$function$;

CREATE OR REPLACE FUNCTION public._traveller_issue(p_field TEXT, p_code TEXT, p_level TEXT DEFAULT 'error')
 RETURNS JSONB
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_build_array(jsonb_build_object('field', p_field, 'code', p_code, 'level', p_level));
$function$;

-- Incidencias de un huésped dentro de una reserva.
-- level = 'error' bloquea la firma y el envío; 'warning' solo avisa.
CREATE OR REPLACE FUNCTION public._traveller_guest_issues(p_booking_id UUID, p_guest_id UUID)
 RETURNS JSONB
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  g          public.guests%ROWTYPE;
  bg         public.booking_guests%ROWTYPE;
  v_checkin  DATE;
  v_age      INTEGER;
  v_resp_age INTEGER;
  v_issues   JSONB := '[]'::jsonb;
BEGIN
  SELECT * INTO bg FROM public.booking_guests
   WHERE booking_id = p_booking_id AND guest_id = p_guest_id;
  IF NOT FOUND THEN
    RETURN public._traveller_issue('guest', 'not_in_booking');
  END IF;

  SELECT * INTO g FROM public.guests WHERE id = p_guest_id;
  SELECT checkin_date INTO v_checkin FROM public.bookings WHERE id = p_booking_id;

  IF g.register_format <> 'rd933_v1' THEN
    RETURN public._traveller_issue('register_format', 'legacy_format');
  END IF;

  v_age := public.traveller_age_on(g.birth_date, v_checkin);

  -- Identificación (todos)
  IF g.first_name  IS NULL THEN v_issues := v_issues || public._traveller_issue('first_name', 'required'); END IF;
  IF g.last_name_1 IS NULL THEN v_issues := v_issues || public._traveller_issue('last_name_1', 'required'); END IF;
  IF g.sex         IS NULL THEN v_issues := v_issues || public._traveller_issue('sex', 'required'); END IF;
  IF g.nationality IS NULL THEN v_issues := v_issues || public._traveller_issue('nationality', 'required'); END IF;

  IF g.birth_date IS NULL THEN
    v_issues := v_issues || public._traveller_issue('birth_date', 'required');
  ELSIF g.birth_date > v_checkin OR v_age > 120 THEN
    v_issues := v_issues || public._traveller_issue('birth_date', 'invalid');
  END IF;

  -- Documento: obligatorio para mayores de edad
  IF v_age >= 18 THEN
    IF g.document_type   IS NULL THEN v_issues := v_issues || public._traveller_issue('document_type', 'required'); END IF;
    IF g.document_number IS NULL THEN v_issues := v_issues || public._traveller_issue('document_number', 'required'); END IF;
  END IF;

  IF g.document_number IS NOT NULL AND g.document_type IN ('dni', 'nie') THEN
    IF NOT public.is_valid_spanish_id(g.document_type, g.document_number) THEN
      v_issues := v_issues || public._traveller_issue('document_number', 'invalid');
    END IF;

    -- Número de soporte: solo existe en DNI (IDESP) y NIE/TIE (IXESP)
    IF g.document_support_number IS NULL THEN
      IF v_age >= 18 THEN
        v_issues := v_issues || public._traveller_issue('document_support_number', 'required');
      END IF;
    ELSIF g.document_support_number !~ '^[A-Z0-9]{9}$' THEN
      v_issues := v_issues || public._traveller_issue('document_support_number', 'invalid');
    END IF;

    IF g.document_type = 'dni' AND g.last_name_2 IS NULL THEN
      v_issues := v_issues || public._traveller_issue('last_name_2', 'recommended', 'warning');
    END IF;
  END IF;

  IF g.email IS NOT NULL AND g.email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    v_issues := v_issues || public._traveller_issue('email', 'invalid');
  END IF;

  IF v_age >= 18 THEN
    -- Domicilio habitual y al menos un medio de contacto
    IF g.residence_address IS NULL THEN v_issues := v_issues || public._traveller_issue('residence_address', 'required'); END IF;
    IF g.residence_city    IS NULL THEN v_issues := v_issues || public._traveller_issue('residence_city', 'required'); END IF;
    IF g.residence_country IS NULL THEN v_issues := v_issues || public._traveller_issue('residence_country', 'required'); END IF;
    IF g.phone IS NULL AND g.landline_phone IS NULL AND g.email IS NULL THEN
      v_issues := v_issues || public._traveller_issue('contact', 'at_least_one_required');
    END IF;
  ELSIF v_age IS NOT NULL THEN
    -- Menor: adulto responsable de la reserva y parentesco. El domicilio,
    -- si no se indica, se toma del responsable (no se duplican datos).
    IF bg.responsible_guest_id IS NULL THEN
      v_issues := v_issues || public._traveller_issue('responsible_guest_id', 'required');
      IF g.residence_country IS NULL THEN
        v_issues := v_issues || public._traveller_issue('residence_country', 'required');
      END IF;
    ELSE
      SELECT public.traveller_age_on(r.birth_date, v_checkin) INTO v_resp_age
        FROM public.guests r WHERE r.id = bg.responsible_guest_id;
      IF v_resp_age IS NULL OR v_resp_age < 18 THEN
        v_issues := v_issues || public._traveller_issue('responsible_guest_id', 'responsible_not_adult');
      END IF;
    END IF;
    IF bg.relationship IS NULL THEN
      v_issues := v_issues || public._traveller_issue('relationship', 'required');
    END IF;
  END IF;

  RETURN v_issues;
END;
$function$;

-- Datos de un huésped tal como quedan congelados en el parte
CREATE OR REPLACE FUNCTION public._traveller_guest_snapshot(p_booking_id UUID, p_guest_id UUID)
 RETURNS JSONB
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_build_object(
    'guest_id', g.id,
    'first_name', g.first_name,
    'last_name_1', g.last_name_1,
    'last_name_2', g.last_name_2,
    'sex', g.sex,
    'birth_date', g.birth_date,
    'age_on_checkin', public.traveller_age_on(g.birth_date, b.checkin_date),
    'nationality', g.nationality,
    'document_type', g.document_type,
    'document_number', g.document_number,
    'document_support_number', g.document_support_number,
    'residence_address', COALESCE(g.residence_address, r.residence_address),
    'residence_city', COALESCE(g.residence_city, r.residence_city),
    'residence_postal_code', COALESCE(g.residence_postal_code, r.residence_postal_code),
    'residence_country', COALESCE(g.residence_country, r.residence_country),
    'residence_inherited', g.residence_country IS NULL AND r.id IS NOT NULL,
    'mobile', g.phone,
    'landline_phone', g.landline_phone,
    'email', g.email,
    'is_primary', bg.is_primary,
    'responsible_guest_id', bg.responsible_guest_id,
    'relationship', bg.relationship
  )
  FROM public.booking_guests bg
  JOIN public.guests g   ON g.id = bg.guest_id
  JOIN public.bookings b ON b.id = bg.booking_id
  LEFT JOIN public.guests r ON r.id = bg.responsible_guest_id
  WHERE bg.booking_id = p_booking_id AND bg.guest_id = p_guest_id;
$function$;

REVOKE EXECUTE ON FUNCTION public._can_access_traveller_register(UUID, BOOLEAN) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._traveller_issue(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._traveller_guest_issues(UUID, UUID) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._traveller_guest_snapshot(UUID, UUID) FROM PUBLIC, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2) Estado del registro de una reserva
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.traveller_register_issues(p_booking_id UUID)
 RETURNS JSONB
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_checkin  DATE;
  v_row      RECORD;
  v_age      INTEGER;
  v_issues   JSONB;
  v_signed   BOOLEAN;
  v_covered  BOOLEAN;
  v_guests   JSONB := '[]'::jsonb;
  v_complete BOOLEAN := true;
  v_count    INTEGER := 0;
BEGIN
  IF NOT public._can_access_traveller_register(p_booking_id, false) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  SELECT checkin_date INTO v_checkin FROM bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: reserva no encontrada' USING ERRCODE = 'P0002';
  END IF;

  FOR v_row IN
    SELECT bg.guest_id, bg.is_primary, bg.responsible_guest_id, g.birth_date, g.register_format
      FROM booking_guests bg
      JOIN guests g ON g.id = bg.guest_id
     WHERE bg.booking_id = p_booking_id
     ORDER BY bg.is_primary DESC, bg.created_at
  LOOP
    v_count  := v_count + 1;
    v_age    := traveller_age_on(v_row.birth_date, v_checkin);
    v_issues := _traveller_guest_issues(p_booking_id, v_row.guest_id);

    v_signed := EXISTS (
      SELECT 1 FROM traveller_entry_forms f
       WHERE f.booking_id = p_booking_id
         AND f.guest_id = v_row.guest_id
         AND f.superseded_at IS NULL);

    -- Menor de 14: lo cubre el parte vigente de su responsable
    v_covered := v_age IS NOT NULL AND v_age < 14 AND EXISTS (
      SELECT 1 FROM traveller_entry_forms f
       WHERE f.booking_id = p_booking_id
         AND f.guest_id = v_row.responsible_guest_id
         AND f.superseded_at IS NULL
         AND f.snapshot -> 'minors' @> jsonb_build_array(jsonb_build_object('guest_id', v_row.guest_id)));

    IF jsonb_path_exists(v_issues, '$[*] ? (@.level == "error")')
       OR v_age IS NULL
       OR (v_age >= 14 AND NOT v_signed)
       OR (v_age < 14 AND NOT v_covered) THEN
      v_complete := false;
    END IF;

    v_guests := v_guests || jsonb_build_array(jsonb_build_object(
      'guest_id', v_row.guest_id,
      'is_primary', v_row.is_primary,
      'register_format', v_row.register_format,
      'age_on_checkin', v_age,
      'needs_own_signature', v_age >= 14,
      'signed', v_signed,
      'covered_by_responsible', v_covered,
      'issues', v_issues
    ));
  END LOOP;

  RETURN jsonb_build_object(
    'booking_id', p_booking_id,
    'checkin_date', v_checkin,
    'complete', v_complete AND v_count > 0,
    'guests', v_guests
  );
END;
$function$;

-- ----------------------------------------------------------------------------
-- 3) Crear / editar un huésped con el formulario nuevo
-- ----------------------------------------------------------------------------
-- p_data (todas las claves opcionales salvo first_name al crear):
--   first_name, last_name_1, last_name_2, sex (M|F|other), birth_date (YYYY-MM-DD),
--   nationality (ISO alfa-3), document_type (dni|nie|passport|other),
--   document_number, document_support_number, residence_address,
--   residence_city, residence_postal_code, residence_country (ISO alfa-3),
--   mobile, landline_phone, email, is_primary, responsible_guest_id, relationship
-- Los formatos inválidos se rechazan; los campos que faltan los informa
-- traveller_register_issues(). Si cambian datos ya firmados, los partes
-- afectados se marcan como sustituidos y hay que volver a firmar.
CREATE OR REPLACE FUNCTION public.save_traveller_guest(
  p_booking_id UUID,
  p_guest_id UUID,
  p_data JSONB
)
 RETURNS UUID
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_checkin_date   DATE;
  v_checkin_status TEXT;
  v_guest_id       UUID := p_guest_id;
  v_created        BOOLEAN := false;
  v_before         JSONB;
  v_after          JSONB;
  v_old_resp       UUID;
  v_age            INTEGER;

  v_first     TEXT := NULLIF(upper(btrim(p_data->>'first_name')), '');
  v_last1     TEXT := NULLIF(upper(btrim(p_data->>'last_name_1')), '');
  v_last2     TEXT := NULLIF(upper(btrim(p_data->>'last_name_2')), '');
  v_sex       TEXT := NULLIF(btrim(p_data->>'sex'), '');
  v_birth     DATE;
  v_nat       TEXT := NULLIF(upper(btrim(p_data->>'nationality')), '');
  v_doc_type  TEXT := NULLIF(lower(btrim(p_data->>'document_type')), '');
  v_doc_num   TEXT := public.traveller_normalize_doc(p_data->>'document_number');
  v_support   TEXT := public.traveller_normalize_doc(p_data->>'document_support_number');
  v_address   TEXT := NULLIF(upper(btrim(p_data->>'residence_address')), '');
  v_city      TEXT := NULLIF(upper(btrim(p_data->>'residence_city')), '');
  v_postal    TEXT := NULLIF(upper(btrim(p_data->>'residence_postal_code')), '');
  v_res_ctry  TEXT := NULLIF(upper(btrim(p_data->>'residence_country')), '');
  v_mobile    TEXT := NULLIF(regexp_replace(COALESCE(p_data->>'mobile', ''), '[\s\-\.\(\)]', '', 'g'), '');
  v_landline  TEXT := NULLIF(regexp_replace(COALESCE(p_data->>'landline_phone', ''), '[\s\-\.\(\)]', '', 'g'), '');
  v_email     TEXT := NULLIF(lower(btrim(p_data->>'email')), '');
  v_primary   BOOLEAN := COALESCE((p_data->>'is_primary')::boolean, false);
  v_resp      UUID := NULLIF(p_data->>'responsible_guest_id', '')::uuid;
  v_relation  TEXT := NULLIF(btrim(p_data->>'relationship'), '');
BEGIN
  IF auth.uid() IS NULL AND auth.role() <> 'service_role' THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  IF NOT public._can_access_traveller_register(p_booking_id, true) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  SELECT b.checkin_date, c.status INTO v_checkin_date, v_checkin_status
    FROM bookings b LEFT JOIN checkins c ON c.booking_id = b.id
   WHERE b.id = p_booking_id;

  IF NOT public.is_staff() AND v_checkin_status IN ('submitted', 'validated') THEN
    RAISE EXCEPTION 'checkin_locked: el check-in ya se ha enviado' USING ERRCODE = 'P0001';
  END IF;

  -- Formatos ------------------------------------------------------------------
  BEGIN
    v_birth := NULLIF(p_data->>'birth_date', '')::date;
  EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'invalid_birth_date' USING ERRCODE = '22023';
  END;

  IF v_sex IS NOT NULL AND v_sex NOT IN ('M', 'F', 'other') THEN
    RAISE EXCEPTION 'invalid_sex' USING ERRCODE = '22023';
  END IF;
  IF v_doc_type IS NOT NULL AND v_doc_type NOT IN ('dni', 'nie', 'passport', 'other') THEN
    RAISE EXCEPTION 'invalid_document_type' USING ERRCODE = '22023';
  END IF;
  IF v_doc_type IN ('dni', 'nie') AND v_doc_num IS NOT NULL
     AND NOT public.is_valid_spanish_id(v_doc_type, v_doc_num) THEN
    RAISE EXCEPTION 'invalid_document_number' USING ERRCODE = '22023';
  END IF;
  IF v_doc_type IN ('passport', 'other') AND v_doc_num IS NOT NULL
     AND v_doc_num !~ '^[A-Z0-9]{3,20}$' THEN
    RAISE EXCEPTION 'invalid_document_number' USING ERRCODE = '22023';
  END IF;
  -- El soporte solo existe en DNI y NIE/TIE: en otros documentos se descarta
  IF v_doc_type IS NULL OR v_doc_type NOT IN ('dni', 'nie') THEN
    v_support := NULL;
  ELSIF v_support IS NOT NULL AND v_support !~ '^[A-Z0-9]{9}$' THEN
    RAISE EXCEPTION 'invalid_document_support_number' USING ERRCODE = '22023';
  END IF;
  IF v_nat IS NOT NULL AND v_nat !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'invalid_nationality' USING ERRCODE = '22023';
  END IF;
  IF v_res_ctry IS NOT NULL AND v_res_ctry !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'invalid_residence_country' USING ERRCODE = '22023';
  END IF;
  IF v_email IS NOT NULL AND v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    RAISE EXCEPTION 'invalid_email' USING ERRCODE = '22023';
  END IF;
  IF v_mobile IS NOT NULL AND v_mobile !~ '^\+?[0-9]{6,15}$' THEN
    RAISE EXCEPTION 'invalid_mobile' USING ERRCODE = '22023';
  END IF;
  IF v_landline IS NOT NULL AND v_landline !~ '^\+?[0-9]{6,15}$' THEN
    RAISE EXCEPTION 'invalid_landline_phone' USING ERRCODE = '22023';
  END IF;
  IF v_relation IS NOT NULL AND v_relation NOT IN (
       'parent', 'grandparent', 'sibling', 'uncle_aunt', 'cousin', 'legal_guardian', 'other') THEN
    RAISE EXCEPTION 'invalid_relationship' USING ERRCODE = '22023';
  END IF;
  IF length(COALESCE(v_first, '')) > 100 OR length(COALESCE(v_last1, '')) > 100
     OR length(COALESCE(v_last2, '')) > 100 OR length(COALESCE(v_address, '')) > 250
     OR length(COALESCE(v_city, '')) > 120 THEN
    RAISE EXCEPTION 'value_too_long' USING ERRCODE = '22001';
  END IF;

  v_age := public.traveller_age_on(v_birth, v_checkin_date);
  IF v_age IS NULL OR v_age >= 18 THEN
    v_resp := NULL;
    v_relation := NULL;
  END IF;

  -- Alta o edición -------------------------------------------------------------
  IF v_guest_id IS NULL THEN
    IF v_first IS NULL THEN
      RAISE EXCEPTION 'first_name_required' USING ERRCODE = '22023';
    END IF;

    INSERT INTO guests (
      full_name, first_name, last_name_1, last_name_2, sex, birth_date,
      nationality, document_type, document_number, document_support_number,
      residence_address, residence_city, residence_postal_code, residence_country,
      phone, landline_phone, email, type, age, register_format
    ) VALUES (
      v_first, v_first, v_last1, v_last2, v_sex, v_birth,
      v_nat, v_doc_type, v_doc_num, v_support,
      v_address, v_city, v_postal, v_res_ctry,
      v_mobile, v_landline, v_email,
      CASE WHEN v_age < 18 THEN 'child' ELSE 'adult' END, v_age, 'rd933_v1'
    ) RETURNING id INTO v_guest_id;

    INSERT INTO booking_guests (booking_id, guest_id, is_primary, age_at_checkin)
    VALUES (p_booking_id, v_guest_id, v_primary, v_age);

    v_created := true;
  ELSE
    SELECT to_jsonb(g) - 'updated_at' - 'full_name' - 'age' - 'type'
           || jsonb_build_object('responsible_guest_id', bg.responsible_guest_id,
                                 'relationship', bg.relationship),
           bg.responsible_guest_id
      INTO v_before, v_old_resp
      FROM booking_guests bg JOIN guests g ON g.id = bg.guest_id
     WHERE bg.booking_id = p_booking_id AND bg.guest_id = v_guest_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'not_found: el huésped no pertenece a esta reserva' USING ERRCODE = 'P0002';
    END IF;

    -- El formulario envía el huésped completo: se reemplazan todos los campos
    UPDATE guests SET
      first_name = COALESCE(v_first, first_name),
      last_name_1 = v_last1,
      last_name_2 = v_last2,
      sex = v_sex,
      birth_date = v_birth,
      nationality = v_nat,
      document_type = v_doc_type,
      document_number = v_doc_num,
      document_support_number = v_support,
      residence_address = v_address,
      residence_city = v_city,
      residence_postal_code = v_postal,
      residence_country = v_res_ctry,
      phone = v_mobile,
      landline_phone = v_landline,
      email = v_email,
      type = CASE WHEN v_age < 18 THEN 'child' ELSE 'adult' END,
      age = v_age,
      register_format = 'rd933_v1'
    WHERE id = v_guest_id;

    UPDATE booking_guests SET age_at_checkin = v_age
     WHERE booking_id = p_booking_id AND guest_id = v_guest_id;
  END IF;

  -- La FK compuesta garantiza que el responsable es de la misma reserva
  UPDATE booking_guests
     SET responsible_guest_id = v_resp,
         relationship = v_relation
   WHERE booking_id = p_booking_id AND guest_id = v_guest_id;

  -- Si cambian datos ya firmados, los partes afectados dejan de valer
  IF NOT v_created THEN
    SELECT to_jsonb(g) - 'updated_at' - 'full_name' - 'age' - 'type'
           || jsonb_build_object('responsible_guest_id', bg.responsible_guest_id,
                                 'relationship', bg.relationship)
      INTO v_after
      FROM booking_guests bg JOIN guests g ON g.id = bg.guest_id
     WHERE bg.booking_id = p_booking_id AND bg.guest_id = v_guest_id;

    IF v_after IS DISTINCT FROM v_before THEN
      UPDATE traveller_entry_forms
         SET superseded_at = now()
       WHERE booking_id = p_booking_id
         AND superseded_at IS NULL
         AND (guest_id = v_guest_id
              OR guest_id = v_old_resp
              OR guest_id = v_resp
              OR snapshot -> 'minors' @> jsonb_build_array(jsonb_build_object('guest_id', v_guest_id))
              -- un adulto cuyo domicilio heredan sus menores
              OR guest_id IN (SELECT bg2.guest_id FROM booking_guests bg2
                               WHERE bg2.booking_id = p_booking_id
                                 AND bg2.responsible_guest_id = v_guest_id));
    END IF;
  END IF;

  -- Trazabilidad sin datos personales
  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('traveller_guest_saved', 'guests', v_guest_id, auth.uid(),
          jsonb_build_object('booking_id', p_booking_id,
                             'created', v_created,
                             'by_staff', public.is_staff()));

  RETURN v_guest_id;
END;
$function$;

-- ----------------------------------------------------------------------------
-- 4) Generar el parte de entrada y firmarlo (atómico)
-- ----------------------------------------------------------------------------
-- El snapshot lo construye el servidor con los datos guardados: la app no
-- puede enviar un parte distinto de lo que hay en la base de datos.
CREATE OR REPLACE FUNCTION public.sign_traveller_entry_form(
  p_booking_id UUID,
  p_guest_id UUID,
  p_signature_svg TEXT,
  p_form_version TEXT
)
 RETURNS UUID
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_booking        RECORD;
  v_checkin_status TEXT;
  v_age            INTEGER;
  v_snapshot       JSONB;
  v_sha            TEXT;
  v_form_id        UUID;
  v_minor          RECORD;
BEGIN
  IF NOT public._can_access_traveller_register(p_booking_id, true) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  IF p_form_version IS NULL OR p_form_version !~ '^rd933-v[0-9]+$' THEN
    RAISE EXCEPTION 'invalid_form_version' USING ERRCODE = '22023';
  END IF;

  IF p_signature_svg IS NULL
     OR length(p_signature_svg) NOT BETWEEN 20 AND 500000
     OR position('<svg' IN lower(p_signature_svg)) = 0
     OR p_signature_svg ~* '<script|javascript:|on[a-z]+\s*=' THEN
    RAISE EXCEPTION 'invalid_signature' USING ERRCODE = '22023';
  END IF;

  SELECT b.id, b.booking_code, b.checkin_date, b.checkout_date, b.num_guests,
         b.property_id, b.unit_id, p.name AS property_name, p.address AS property_address,
         p.city AS property_city, u.name AS unit_name
    INTO v_booking
    FROM bookings b
    JOIN private.properties p ON p.id = b.property_id
    LEFT JOIN private.units u ON u.id = b.unit_id
   WHERE b.id = p_booking_id;

  SELECT status INTO v_checkin_status FROM checkins WHERE booking_id = p_booking_id;
  IF NOT public.is_staff() AND v_checkin_status IN ('submitted', 'validated') THEN
    RAISE EXCEPTION 'checkin_locked: el check-in ya se ha enviado' USING ERRCODE = 'P0001';
  END IF;

  SELECT traveller_age_on(g.birth_date, v_booking.checkin_date) INTO v_age
    FROM booking_guests bg JOIN guests g ON g.id = bg.guest_id
   WHERE bg.booking_id = p_booking_id AND bg.guest_id = p_guest_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: el huésped no pertenece a esta reserva' USING ERRCODE = 'P0002';
  END IF;
  IF v_age IS NULL OR v_age < 14 THEN
    RAISE EXCEPTION 'signature_not_allowed_under_14: lo firma el adulto responsable'
      USING ERRCODE = 'P0001';
  END IF;

  IF jsonb_path_exists(_traveller_guest_issues(p_booking_id, p_guest_id), '$[*] ? (@.level == "error")') THEN
    RAISE EXCEPTION 'register_incomplete: faltan datos del huésped' USING ERRCODE = 'P0001';
  END IF;

  -- Los menores de 14 a su cargo deben estar completos: van en este parte
  FOR v_minor IN
    SELECT bg.guest_id FROM booking_guests bg JOIN guests g ON g.id = bg.guest_id
     WHERE bg.booking_id = p_booking_id
       AND bg.responsible_guest_id = p_guest_id
       AND traveller_age_on(g.birth_date, v_booking.checkin_date) < 14
  LOOP
    IF jsonb_path_exists(_traveller_guest_issues(p_booking_id, v_minor.guest_id), '$[*] ? (@.level == "error")') THEN
      RAISE EXCEPTION 'register_incomplete: faltan datos de un menor a su cargo' USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  v_snapshot := jsonb_build_object(
    'form_version', p_form_version,
    'generated_at', now(),
    'booking', jsonb_build_object(
      'id', v_booking.id,
      'code', v_booking.booking_code,
      'checkin_date', v_booking.checkin_date,
      'checkout_date', v_booking.checkout_date,
      'num_guests', v_booking.num_guests),
    'establishment', jsonb_build_object(
      'property_id', v_booking.property_id,
      'name', v_booking.property_name,
      'address', v_booking.property_address,
      'city', v_booking.property_city,
      'unit', v_booking.unit_name),
    'guest', _traveller_guest_snapshot(p_booking_id, p_guest_id),
    'minors', COALESCE((
      SELECT jsonb_agg(_traveller_guest_snapshot(p_booking_id, bg.guest_id) ORDER BY g.birth_date)
        FROM booking_guests bg JOIN guests g ON g.id = bg.guest_id
       WHERE bg.booking_id = p_booking_id
         AND bg.responsible_guest_id = p_guest_id
         AND traveller_age_on(g.birth_date, v_booking.checkin_date) < 14
    ), '[]'::jsonb)
  );

  v_sha := encode(extensions.digest(convert_to(v_snapshot::text, 'UTF8'), 'sha256'), 'hex');

  UPDATE traveller_entry_forms
     SET superseded_at = now()
   WHERE booking_id = p_booking_id AND guest_id = p_guest_id AND superseded_at IS NULL;

  INSERT INTO traveller_entry_forms (
    booking_id, guest_id, property_id, form_version, snapshot, snapshot_sha256, created_by
  ) VALUES (
    p_booking_id, p_guest_id, v_booking.property_id, p_form_version, v_snapshot, v_sha, auth.uid()
  ) RETURNING id INTO v_form_id;

  INSERT INTO guest_signatures (
    entry_form_id, booking_id, guest_id, signature_version, signature_svg,
    signature_sha256, signed_by_user_id, signed_via
  ) VALUES (
    v_form_id, p_booking_id, p_guest_id, p_form_version, p_signature_svg,
    encode(extensions.digest(convert_to(p_signature_svg, 'UTF8'), 'sha256'), 'hex'),
    auth.uid(),
    CASE WHEN public.is_staff() THEN 'staff_device' ELSE 'guest_app' END
  );

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('traveller_entry_form_signed', 'traveller_entry_forms', v_form_id, auth.uid(),
          jsonb_build_object('booking_id', p_booking_id,
                             'guest_id', p_guest_id,
                             'form_version', p_form_version,
                             'snapshot_sha256', v_sha));

  RETURN v_form_id;
END;
$function$;

-- ----------------------------------------------------------------------------
-- 5) Enviar el check-in con el registro completo
-- ----------------------------------------------------------------------------
-- Reutiliza submit_guest_checkin() (estado, auto-validación, notificaciones).
-- En checkins.signature_svg se copia la firma del titular para que el panel
-- y el flujo actual sigan mostrando una firma.
CREATE OR REPLACE FUNCTION public.submit_traveller_checkin(p_booking_id UUID)
 RETURNS VOID
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_register JSONB;
  v_svg      TEXT;
BEGIN
  IF NOT public._can_access_traveller_register(p_booking_id, true) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  v_register := public.traveller_register_issues(p_booking_id);
  IF NOT COALESCE((v_register->>'complete')::boolean, false) THEN
    RAISE EXCEPTION 'register_incomplete: faltan datos o firmas en el registro de viajeros'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT s.signature_svg INTO v_svg
    FROM guest_signatures s
    JOIN traveller_entry_forms f ON f.id = s.entry_form_id
    JOIN booking_guests bg ON bg.booking_id = f.booking_id AND bg.guest_id = f.guest_id
   WHERE f.booking_id = p_booking_id AND f.superseded_at IS NULL
   ORDER BY bg.is_primary DESC, s.signed_at
   LIMIT 1;

  PERFORM public.submit_guest_checkin(p_booking_id, v_svg);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.traveller_register_issues(UUID) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.save_traveller_guest(UUID, UUID, JSONB) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.sign_traveller_entry_form(UUID, UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.submit_traveller_checkin(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.traveller_register_issues(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.save_traveller_guest(UUID, UUID, JSONB) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.sign_traveller_entry_form(UUID, UUID, TEXT, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.submit_traveller_checkin(UUID) TO authenticated, service_role;

COMMIT;
