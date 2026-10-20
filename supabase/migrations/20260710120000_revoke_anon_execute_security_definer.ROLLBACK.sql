-- ============================================================================
-- ROLLBACK de 20260710120000_revoke_anon_execute_security_definer.sql
-- ----------------------------------------------------------------------------
-- Restaura EXACTAMENTE los grants EXECUTE que existían ANTES de la migración
-- (backup capturado desde pg_proc.proacl el 2026-07-10).
-- NO se aplica automáticamente. Ejecutar SOLO si hay que revertir.
-- ============================================================================

BEGIN;

GRANT EXECUTE ON FUNCTION public.activate_booking(p_booking_id uuid) TO postgres, service_role, authenticated, anon, PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_staff_to_conversation() TO PUBLIC, postgres, service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.assign_primary_guest(p_booking_code text) TO postgres, anon, service_role, authenticated, PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_primary_guest_to_booking(p_booking_id uuid, p_user_id uuid) TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_booking(p_booking_id uuid, p_reason text) TO authenticated, postgres, PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_checkin(p_checkin_id uuid, p_reason text) TO postgres, service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_documents() TO postgres, PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.clear_chat_notifications() TO authenticated, service_role, anon, postgres, PUBLIC;
GRANT EXECUTE ON FUNCTION public.close_booking(p_booking_id uuid, p_notes text) TO service_role, authenticated, anon, postgres, PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_booking_with_code(p_property_id uuid, p_unit_id uuid, p_checkin_date date, p_checkout_date date, p_last_name text, p_num_adults integer, p_num_children integer, p_children_ages integer[], p_staff_notes text, p_guest_first_name text, p_guest_email text, p_guest_phone text) TO postgres, service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.create_chat_notification() TO PUBLIC, service_role, authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION public.create_guest_conversation(p_property_id uuid, p_booking_id uuid, p_guest_user_id uuid, p_guest_name text) TO service_role, PUBLIC, postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_booking(p_booking_id uuid) TO anon, postgres, PUBLIC, service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.generate_booking_code() TO anon, authenticated, service_role, PUBLIC, postgres;
GRANT EXECUTE ON FUNCTION public.generate_invoice_number() TO anon, service_role, PUBLIC, postgres, authenticated;
GRANT EXECUTE ON FUNCTION public.get_access_for_booking(p_booking_id uuid) TO service_role, anon, postgres, authenticated;
GRANT EXECUTE ON FUNCTION public.get_all_units_availability(p_from date, p_to date, p_property_id uuid) TO service_role, anon, PUBLIC, postgres, authenticated;
GRANT EXECUTE ON FUNCTION public.get_booking_full_status(p_booking_id uuid) TO anon, postgres, PUBLIC, service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.get_checkin_details(p_checkin_id uuid) TO service_role, authenticated, PUBLIC, postgres, anon;
GRANT EXECUTE ON FUNCTION public.get_documents_expiring_soon(days_before integer) TO service_role, authenticated, anon, postgres, PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_fcm_token_for_user(target_user_id uuid) TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_fcm_tokens_for_users(target_user_ids uuid[]) TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_profile_by_email(p_email text) TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_senders_info(user_ids uuid[]) TO authenticated, postgres, service_role, anon;
GRANT EXECUTE ON FUNCTION public.get_server_time() TO anon, authenticated, service_role, PUBLIC, postgres;
GRANT EXECUTE ON FUNCTION public.get_unit_occupied_ranges(p_unit_id uuid, p_from date, p_to date) TO service_role, authenticated, anon, postgres, PUBLIC;
GRANT EXECUTE ON FUNCTION public.insert_guest_for_booking(p_booking_id uuid, p_full_name text, p_email text, p_phone text, p_type text, p_age integer, p_document_type text, p_document_number text, p_nationality text, p_birth_date date, p_is_primary boolean) TO service_role, PUBLIC, postgres, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_conversation_participant(conv_id uuid) TO anon, service_role, authenticated, PUBLIC, postgres;
GRANT EXECUTE ON FUNCTION public.is_unit_available(p_unit_id uuid, p_checkin date, p_checkout date, p_exclude_booking_id uuid) TO anon, postgres, PUBLIC, service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.manual_checkin_validate(p_booking_id uuid) TO authenticated, postgres, PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.migrate_guest_conversation_participant(p_old_user_id uuid, p_new_user_id uuid) TO anon, authenticated, service_role, PUBLIC, postgres;
GRANT EXECUTE ON FUNCTION public.notify_chat_message() TO service_role, PUBLIC, postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_fcm(payload jsonb) TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.notify_new_chat_message() TO postgres, anon, authenticated, service_role, PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_fcm_queue() TO postgres, service_role, authenticated, anon, PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_notification_queue() TO postgres, PUBLIC, service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.process_notification_queue_trigger() TO PUBLIC, service_role, authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION public.regenerate_booking_code(p_booking_id uuid) TO postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.reject_checkin(p_checkin_id uuid, p_reason text, p_staff_user_id uuid) TO postgres, PUBLIC, service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.reject_checkout(p_booking_id uuid, p_reason text) TO postgres, PUBLIC, service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.request_checkout(p_booking_id uuid) TO PUBLIC, service_role, authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION public.submit_guest_checkin(p_booking_id uuid, p_signature_svg text) TO postgres, PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.test_auth_uid() TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.trg_booking_status_notify() TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.trg_checkout_status_notify() TO postgres, service_role, authenticated, anon, PUBLIC;
GRANT EXECUTE ON FUNCTION public.trigger_process_notification_queue() TO PUBLIC, service_role, authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION public.update_conversation_last_message() TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_guest_for_booking(p_guest_id uuid, p_booking_id uuid, p_full_name text, p_email text, p_phone text, p_type text, p_age integer, p_document_type text, p_document_number text, p_nationality text, p_birth_date date) TO anon, PUBLIC, service_role, authenticated, postgres;
GRANT EXECUTE ON FUNCTION public.upsert_profile(p_email text, p_user_id uuid, p_full_name text, p_phone text, p_document_type text, p_document_number text, p_nationality text, p_birth_date date) TO PUBLIC, service_role, authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION public.validate_checkin(p_checkin_id uuid, p_staff_user_id uuid) TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.validate_checkout(p_booking_id uuid, p_notes text) TO PUBLIC, postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.validate_conversation_participants() TO PUBLIC, postgres, anon, authenticated, service_role;

COMMIT;
