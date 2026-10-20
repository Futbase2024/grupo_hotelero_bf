-- ============================================================================
-- Migración: Blindar funciones SECURITY DEFINER frente al rol `anon`
-- ----------------------------------------------------------------------------
-- Advisor: anon_security_definer_function_executable (0028)
--
-- Contexto de auth de la app:
--   * Invitados  -> signInAnonymously() => rol `authenticated` (is_anonymous)
--   * Admin/staff -> login email/password => rol `authenticated`
--   * El rol `anon` puro solo hace un SELECT directo sobre `bookings` (RLS),
--     nunca invoca funciones RPC. => Revocar EXECUTE de `anon` no rompe nada.
--
-- Estrategia por categoría:
--   A) Funciones TRIGGER  -> nunca se llaman por RPC. Revocar de todos,
--      dejar solo service_role (el trigger dispara sin depender de EXECUTE).
--   B) Cola/push interno   -> solo cron/edge (service_role).
--   C) RPC de negocio      -> los llama la app ya autenticada. Revocar `anon`,
--      mantener `authenticated` + `service_role`.
--
-- Se revoca de PUBLIC además de anon porque anon/authenticated heredan de
-- PUBLIC; por eso se re-otorga authenticated explícitamente donde procede.
-- Rollback exacto en: 20260710120000_revoke_anon_execute_security_definer.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- A) Funciones TRIGGER (returns trigger) -> solo service_role
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.add_staff_to_conversation() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.add_staff_to_conversation() TO service_role;
REVOKE EXECUTE ON FUNCTION public.clear_chat_notifications() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.clear_chat_notifications() TO service_role;
REVOKE EXECUTE ON FUNCTION public.create_chat_notification() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_chat_notification() TO service_role;
REVOKE EXECUTE ON FUNCTION public.notify_chat_message() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_chat_message() TO service_role;
REVOKE EXECUTE ON FUNCTION public.notify_new_chat_message() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_new_chat_message() TO service_role;
REVOKE EXECUTE ON FUNCTION public.process_notification_queue_trigger() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_notification_queue_trigger() TO service_role;
REVOKE EXECUTE ON FUNCTION public.trg_booking_status_notify() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_booking_status_notify() TO service_role;
REVOKE EXECUTE ON FUNCTION public.trg_checkout_status_notify() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_checkout_status_notify() TO service_role;
REVOKE EXECUTE ON FUNCTION public.trigger_process_notification_queue() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_process_notification_queue() TO service_role;
REVOKE EXECUTE ON FUNCTION public.update_conversation_last_message() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_conversation_last_message() TO service_role;
REVOKE EXECUTE ON FUNCTION public.validate_conversation_participants() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.validate_conversation_participants() TO service_role;

-- ----------------------------------------------------------------------------
-- B) Cola / push interno -> solo service_role (cron/edge functions)
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.notify_fcm(payload jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_fcm(payload jsonb) TO service_role;
REVOKE EXECUTE ON FUNCTION public.process_fcm_queue() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_fcm_queue() TO service_role;
REVOKE EXECUTE ON FUNCTION public.process_notification_queue() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_notification_queue() TO service_role;

-- ----------------------------------------------------------------------------
-- C) RPC de negocio -> revocar anon, mantener authenticated + service_role
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.activate_booking(p_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.activate_booking(p_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.assign_primary_guest(p_booking_code text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assign_primary_guest(p_booking_code text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.assign_primary_guest_to_booking(p_booking_id uuid, p_user_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assign_primary_guest_to_booking(p_booking_id uuid, p_user_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.cancel_booking(p_booking_id uuid, p_reason text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_booking(p_booking_id uuid, p_reason text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.cancel_checkin(p_checkin_id uuid, p_reason text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_checkin(p_checkin_id uuid, p_reason text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.cleanup_expired_documents() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_documents() TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.close_booking(p_booking_id uuid, p_notes text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.close_booking(p_booking_id uuid, p_notes text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.create_booking_with_code(p_property_id uuid, p_unit_id uuid, p_checkin_date date, p_checkout_date date, p_last_name text, p_num_adults integer, p_num_children integer, p_children_ages integer[], p_staff_notes text, p_guest_first_name text, p_guest_email text, p_guest_phone text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_with_code(p_property_id uuid, p_unit_id uuid, p_checkin_date date, p_checkout_date date, p_last_name text, p_num_adults integer, p_num_children integer, p_children_ages integer[], p_staff_notes text, p_guest_first_name text, p_guest_email text, p_guest_phone text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.create_guest_conversation(p_property_id uuid, p_booking_id uuid, p_guest_user_id uuid, p_guest_name text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_guest_conversation(p_property_id uuid, p_booking_id uuid, p_guest_user_id uuid, p_guest_name text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.delete_booking(p_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_booking(p_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.generate_booking_code() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.generate_booking_code() TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.generate_invoice_number() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.generate_invoice_number() TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_access_for_booking(p_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_access_for_booking(p_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_all_units_availability(p_from date, p_to date, p_property_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_all_units_availability(p_from date, p_to date, p_property_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_booking_full_status(p_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_booking_full_status(p_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_checkin_details(p_checkin_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_checkin_details(p_checkin_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_documents_expiring_soon(days_before integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_documents_expiring_soon(days_before integer) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_fcm_token_for_user(target_user_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_fcm_token_for_user(target_user_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_fcm_tokens_for_users(target_user_ids uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_fcm_tokens_for_users(target_user_ids uuid[]) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_profile_by_email(p_email text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_profile_by_email(p_email text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_senders_info(user_ids uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_senders_info(user_ids uuid[]) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_server_time() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_server_time() TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.get_unit_occupied_ranges(p_unit_id uuid, p_from date, p_to date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_unit_occupied_ranges(p_unit_id uuid, p_from date, p_to date) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.insert_guest_for_booking(p_booking_id uuid, p_full_name text, p_email text, p_phone text, p_type text, p_age integer, p_document_type text, p_document_number text, p_nationality text, p_birth_date date, p_is_primary boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.insert_guest_for_booking(p_booking_id uuid, p_full_name text, p_email text, p_phone text, p_type text, p_age integer, p_document_type text, p_document_number text, p_nationality text, p_birth_date date, p_is_primary boolean) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.is_conversation_participant(conv_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_conversation_participant(conv_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.is_unit_available(p_unit_id uuid, p_checkin date, p_checkout date, p_exclude_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_unit_available(p_unit_id uuid, p_checkin date, p_checkout date, p_exclude_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.manual_checkin_validate(p_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.manual_checkin_validate(p_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.migrate_guest_conversation_participant(p_old_user_id uuid, p_new_user_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.migrate_guest_conversation_participant(p_old_user_id uuid, p_new_user_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.regenerate_booking_code(p_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.regenerate_booking_code(p_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.reject_checkin(p_checkin_id uuid, p_reason text, p_staff_user_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_checkin(p_checkin_id uuid, p_reason text, p_staff_user_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.reject_checkout(p_booking_id uuid, p_reason text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_checkout(p_booking_id uuid, p_reason text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.request_checkout(p_booking_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_checkout(p_booking_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.submit_guest_checkin(p_booking_id uuid, p_signature_svg text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_guest_checkin(p_booking_id uuid, p_signature_svg text) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.test_auth_uid() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.test_auth_uid() TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.update_guest_for_booking(p_guest_id uuid, p_booking_id uuid, p_full_name text, p_email text, p_phone text, p_type text, p_age integer, p_document_type text, p_document_number text, p_nationality text, p_birth_date date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_guest_for_booking(p_guest_id uuid, p_booking_id uuid, p_full_name text, p_email text, p_phone text, p_type text, p_age integer, p_document_type text, p_document_number text, p_nationality text, p_birth_date date) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.upsert_profile(p_email text, p_user_id uuid, p_full_name text, p_phone text, p_document_type text, p_document_number text, p_nationality text, p_birth_date date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_profile(p_email text, p_user_id uuid, p_full_name text, p_phone text, p_document_type text, p_document_number text, p_nationality text, p_birth_date date) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.validate_checkin(p_checkin_id uuid, p_staff_user_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_checkin(p_checkin_id uuid, p_staff_user_id uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.validate_checkout(p_booking_id uuid, p_notes text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_checkout(p_booking_id uuid, p_notes text) TO authenticated, service_role;

COMMIT;
