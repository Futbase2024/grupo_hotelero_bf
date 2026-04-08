// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class SIt extends S {
  SIt([String locale = 'it']) : super(locale);

  @override
  String get common_app_name => 'BF Stay';

  @override
  String get common_cancel => 'Annulla';

  @override
  String get common_exit => 'Esci';

  @override
  String get common_save => 'Salva';

  @override
  String get common_delete => 'Elimina';

  @override
  String get common_close => 'Chiudi';

  @override
  String get common_loading => 'Caricamento...';

  @override
  String get common_retry => 'Riprova';

  @override
  String get common_accept => 'Accetta';

  @override
  String get common_continue => 'Continua';

  @override
  String get common_back => 'Indietro';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error => 'Errore';

  @override
  String get common_success => 'Successo';

  @override
  String get common_no_data => 'Nessun dato';

  @override
  String get common_yes => 'Sì';

  @override
  String get common_no => 'No';

  @override
  String get common_send => 'Invia';

  @override
  String get common_edit => 'Modifica';

  @override
  String get common_search => 'Cerca';

  @override
  String get common_later => 'Più tardi';

  @override
  String get common_update => 'Aggiorna';

  @override
  String get common_understood => 'Capito';

  @override
  String get common_exit_app_title => 'Uscire da BF Stay';

  @override
  String get common_exit_app_message =>
      'Sei sicuro di voler uscire dall\'app?\n\nLa tua sessione rimarrà attiva quando tornerai.';

  @override
  String get common_logout_title => 'Disconnetti';

  @override
  String get common_logout_message =>
      'Sei sicuro di voler disconnetterti?\n\nPuoi accedere di nuovo con il tuo codice prenotazione quando vuoi.';

  @override
  String get common_logout_button => 'Disconnetti';

  @override
  String get common_splash_ready => 'Pronto';

  @override
  String get common_splash_loading => 'Caricamento...';

  @override
  String get common_update_force_title => 'Aggiornamento richiesto';

  @override
  String get common_update_available_title => 'Nuova versione disponibile';

  @override
  String get common_update_force_message =>
      'Devi aggiornare l\'app per continuare a utilizzarla. Questa versione include importanti miglioramenti e correzioni di sicurezza.';

  @override
  String get common_update_available_message =>
      'È disponibile una nuova versione con miglioramenti e correzioni. Vuoi aggiornare adesso?';

  @override
  String common_update_version(String version) {
    return 'Versione $version';
  }

  @override
  String get common_page_not_found => 'Pagina non trovata';

  @override
  String get common_invalid_route => 'Percorso non valido';

  @override
  String get common_back_to_home => 'Torna alla home';

  @override
  String get common_theme_light => 'Chiaro';

  @override
  String get common_theme_dark => 'Scuro';

  @override
  String get common_theme_mode_light => 'Modalità chiara';

  @override
  String get common_theme_mode_dark => 'Modalità scura';

  @override
  String get common_theme_system => 'Sistema';

  @override
  String get common_theme_app_label => 'Tema dell\'app';

  @override
  String common_copied_to_clipboard(String type) {
    return '$type copiato negli appunti';
  }

  @override
  String get common_phone_type => 'Telefono';

  @override
  String get common_email_type => 'Email';

  @override
  String get enum_booking_status_created => 'Creata';

  @override
  String get enum_booking_status_confirmed => 'Confermata';

  @override
  String get enum_booking_status_active => 'Attiva';

  @override
  String get enum_booking_status_in_house => 'In struttura';

  @override
  String get enum_booking_status_checked_out => 'Check-out effettuato';

  @override
  String get enum_booking_status_closed => 'Chiusa';

  @override
  String get enum_booking_status_cancelled => 'Annullata';

  @override
  String get enum_booking_status_created_desc =>
      'Prenotazione creata, in attesa di conferma';

  @override
  String get enum_booking_status_confirmed_desc =>
      'Prenotazione confermata, in attesa di check-in';

  @override
  String get enum_booking_status_active_desc =>
      'Check-in validato, pannello completo accessibile';

  @override
  String get enum_booking_status_in_house_desc =>
      'Ospite fisicamente nella struttura';

  @override
  String get enum_booking_status_checked_in_legacy_desc =>
      'Check-in validato (legacy)';

  @override
  String get enum_booking_status_checked_out_desc =>
      'Check-out completato, l\'ospite è partito';

  @override
  String get enum_booking_status_closed_desc =>
      'Prenotazione terminata e chiusa';

  @override
  String get enum_booking_status_cancelled_desc => 'Prenotazione annullata';

  @override
  String get enum_checkin_status_not_started => 'In attesa';

  @override
  String get enum_checkin_status_in_progress => 'In corso';

  @override
  String get enum_checkin_status_submitted => 'Inviato';

  @override
  String get enum_checkin_status_validated => 'Validato';

  @override
  String get enum_checkin_status_rejected => 'Rifiutato';

  @override
  String get enum_checkin_status_cancelled => 'Annullato';

  @override
  String get enum_checkin_status_not_started_desc =>
      'L\'ospite non ha ancora iniziato il check-in';

  @override
  String get enum_checkin_status_in_progress_desc =>
      'L\'ospite sta compilando i propri dati';

  @override
  String get enum_checkin_status_submitted_desc =>
      'In attesa di revisione da parte dell\'amministratore';

  @override
  String get enum_checkin_status_validated_desc =>
      'Check-in validato, soggiorno autorizzato';

  @override
  String get enum_checkin_status_rejected_desc =>
      'Richiede correzione da parte dell\'ospite';

  @override
  String get enum_checkin_status_cancelled_desc =>
      'Prenotazione annullata, si prega di contattare la reception';

  @override
  String get enum_checkout_status_not_started => 'Non iniziato';

  @override
  String get enum_checkout_status_requested => 'Richiesto';

  @override
  String get enum_checkout_status_validated => 'Validato';

  @override
  String get enum_checkout_status_rejected => 'Rifiutato';

  @override
  String get enum_checkout_status_not_started_desc =>
      'Il soggiorno è ancora in corso';

  @override
  String get enum_checkout_status_requested_desc =>
      'L\'ospite ha richiesto il check-out';

  @override
  String get enum_checkout_status_validated_desc =>
      'Check-out validato, prenotazione pronta per la chiusura';

  @override
  String get enum_checkout_status_rejected_desc =>
      'Ci sono problemi da risolvere';

  @override
  String get public_badge_exclusivity => 'ESCLUSIVITÀ GARANTITA';

  @override
  String get public_hero_title_prefix => 'Il tuo soggiorno, ';

  @override
  String get public_hero_title_suffix => 'Elevato';

  @override
  String get public_cta_access_booking => 'Accedi alla mia prenotazione';

  @override
  String get public_services_section_title => 'I Nostri Servizi';

  @override
  String get public_footer_brand_name => 'BF STAY';

  @override
  String public_footer_copyright(int year) {
    return '© $year BF Stay • Tutti i diritti riservati';
  }

  @override
  String get public_footer_privacy_policy => 'Privacy Policy';

  @override
  String get public_service_checkin_title => 'Check-in digitale';

  @override
  String get public_service_checkin_desc => 'Registrazione senza attesa.';

  @override
  String get public_service_checkout_title => 'Check-out digitale';

  @override
  String get public_service_checkout_desc => 'Partenza rapida.';

  @override
  String get public_service_house_rules_title => 'Regole della casa';

  @override
  String get public_service_house_rules_desc => 'Regole e raccomandazioni.';

  @override
  String get public_service_what_to_see_title => 'Cosa visitare?';

  @override
  String get public_service_what_to_see_desc =>
      'Punti di interesse nelle vicinanze.';

  @override
  String get public_service_parking_title => 'Parcheggi';

  @override
  String get public_service_parking_desc => 'Opzioni di parcheggio.';

  @override
  String get public_service_chat_title => 'Chat';

  @override
  String get public_service_chat_desc => 'Concierge virtuale 24/7.';

  @override
  String get public_service_accommodations_title => 'Alloggi';

  @override
  String get public_service_accommodations_desc => 'Altre proprietà.';

  @override
  String get public_service_reviews_title => 'Recensioni';

  @override
  String get public_service_reviews_desc => 'Recensioni degli ospiti.';

  @override
  String get public_service_parking_title_light => 'Parcheggi nelle vicinanze';

  @override
  String get public_service_accommodations_title_light => 'I nostri alloggi';

  @override
  String get public_service_accommodations_desc_light =>
      'Altre proprietà disponibili.';

  @override
  String get public_service_reviews_title_light => 'Recensioni e commenti';

  @override
  String get public_hero_subtitle =>
      'Gestione intelligente per alloggi esclusivi.';

  @override
  String get auth_login_brand_name => 'BF Stay';

  @override
  String get auth_login_subtitle => 'Pannello di controllo';

  @override
  String get auth_feature_bookings => 'Gestione prenotazioni';

  @override
  String get auth_feature_checkin => 'Check-in digitale';

  @override
  String get auth_feature_chat => 'Chat con gli ospiti';

  @override
  String get auth_feature_keyless => 'Accesso senza chiave';

  @override
  String get auth_field_email => 'Email';

  @override
  String get auth_field_password => 'Password';

  @override
  String get auth_validation_email_required => 'Inserisci la tua email';

  @override
  String get auth_validation_email_invalid => 'Inserisci un\'email valida';

  @override
  String get auth_validation_password_required => 'Inserisci la tua password';

  @override
  String get auth_validation_password_min_length =>
      'La password deve essere di almeno 6 caratteri';

  @override
  String get auth_forgot_password => 'Password dimenticata?';

  @override
  String get auth_login_button => 'Accedi';

  @override
  String get auth_divider_or => 'o';

  @override
  String get auth_guest_access_button => 'Accedi con codice prenotazione';

  @override
  String get auth_login_footer => 'BF Stay © 2026';

  @override
  String get auth_recover_password_title => 'Recupera password';

  @override
  String get auth_recover_password_body =>
      'Inserisci la tua email e ti invieremo le istruzioni per reimpostare la password.';

  @override
  String get auth_recover_password_sent => 'Email di recupero inviata';

  @override
  String get auth_button_send => 'Invia';

  @override
  String get auth_booking_access_title => 'Accesso ospiti';

  @override
  String get auth_booking_benefit_code => 'Codice prenotazione';

  @override
  String get auth_booking_benefit_personal => 'Accesso personalizzato';

  @override
  String get auth_booking_benefit_instant => 'Accesso immediato';

  @override
  String get auth_booking_benefit_secure_checkin => 'Check-in sicuro';

  @override
  String get auth_booking_code_info_short =>
      'Hai ricevuto il tuo codice prenotazione nell\'email di conferma.';

  @override
  String get auth_booking_code_info_full =>
      'Hai ricevuto il tuo codice prenotazione nell\'email di conferma della prenotazione.';

  @override
  String get auth_booking_desktop_subtitle =>
      'Goditi il tuo soggiorno con accesso digitale';

  @override
  String get auth_booking_form_subtitle =>
      'Inserisci il tuo codice prenotazione per accedere al tuo alloggio';

  @override
  String get auth_booking_field_code => 'Codice prenotazione';

  @override
  String get auth_booking_code_hint => 'XX-XXXX-XXXX';

  @override
  String get auth_booking_validation_code_required =>
      'Inserisci il tuo codice prenotazione';

  @override
  String get auth_booking_validation_code_invalid =>
      'Il formato del codice non è valido';

  @override
  String get auth_booking_access_button => 'Accedi';

  @override
  String get auth_booking_help_title => 'Dove trovo il mio codice?';

  @override
  String get auth_booking_help_body =>
      'Hai ricevuto il tuo codice prenotazione nell\'email di conferma. Ha il formato BF-XXXXX.';

  @override
  String get auth_booking_footer => 'BF Stay © 2026';

  @override
  String get auth_booking_error_title => 'Errore di accesso';

  @override
  String get auth_booking_error_code_not_found =>
      'Il codice prenotazione non esiste. Verifica di averlo inserito correttamente.';

  @override
  String get auth_booking_error_code_expired =>
      'Questo codice prenotazione è scaduto. Contatta la reception per ottenerne uno nuovo.';

  @override
  String get auth_booking_error_email_mismatch =>
      'L\'email non corrisponde alla prenotazione. Assicurati di usare la stessa email con cui hai prenotato.';

  @override
  String get auth_booking_error_generic =>
      'Impossibile verificare il codice prenotazione. Riprova.';

  @override
  String get auth_booking_error_dismiss => 'Capito';

  @override
  String get auth_sheet_title => 'Accedi alla tua prenotazione';

  @override
  String get auth_sheet_subtitle =>
      'Inserisci la tua email e il codice ricevuto';

  @override
  String get auth_sheet_label_email => 'EMAIL';

  @override
  String get auth_sheet_hint_email => 'tu@email.com';

  @override
  String get auth_sheet_label_code => 'CODICE PRENOTAZIONE';

  @override
  String get auth_sheet_hint_code => 'BF-XXXX-XXXX';

  @override
  String get auth_sheet_submit_button => 'Accedi alla mia prenotazione';

  @override
  String get auth_sheet_help_text =>
      'Non hai il codice? Contatta il tuo alloggio';

  @override
  String get auth_admin_sheet_title => 'Accesso privato';

  @override
  String get auth_admin_sheet_subtitle => 'Solo personale autorizzato BF-Stay';

  @override
  String get auth_admin_label_email => 'EMAIL';

  @override
  String get auth_admin_hint_email => 'admin@bfstay.com';

  @override
  String get auth_admin_label_password => 'PASSWORD';

  @override
  String get auth_admin_hint_password => '••••••••';

  @override
  String get auth_admin_error_unauthorized =>
      'Non hai accesso a questo pannello';

  @override
  String get auth_admin_submit_button => 'Accedi al pannello';

  @override
  String get guest_settings_title => 'Impostazioni';

  @override
  String get guest_settings_section_language => 'Lingua';

  @override
  String get guest_settings_language_title => 'Lingua dell\'app';

  @override
  String get guest_settings_language_subtitle =>
      'Seleziona la lingua dell\'interfaccia';

  @override
  String get guest_settings_section_legal => 'Legale';

  @override
  String get guest_settings_privacy_policy_title => 'Privacy Policy';

  @override
  String get guest_settings_privacy_policy_subtitle =>
      'Visualizza la nostra informativa sulla privacy';

  @override
  String get guest_settings_privacy_open_error =>
      'Impossibile aprire l\'informativa sulla privacy';

  @override
  String get notification_channel_name => 'Notifiche BF Stay';

  @override
  String get notification_channel_description => 'Canale di notifiche BF Stay';

  @override
  String get notification_checkin_validated_title => '✅ Check-in validato';

  @override
  String get notification_checkin_validated_body =>
      'Il tuo check-in è stato validato con successo. Benvenuto!';

  @override
  String get notification_checkin_rejected_title => '❌ Check-in rifiutato';

  @override
  String get notification_checkin_rejected_body =>
      'Il tuo check-in è stato rifiutato. Verifica la tua documentazione.';

  @override
  String notification_checkin_rejected_body_with_reason(String reason) {
    return 'Il tuo check-in è stato rifiutato: $reason';
  }

  @override
  String get notification_booking_cancelled_title =>
      '🚫 Prenotazione annullata';

  @override
  String get notification_booking_cancelled_body =>
      'La tua prenotazione è stata annullata. Contatta la reception.';

  @override
  String notification_booking_cancelled_body_with_reason(String reason) {
    return 'La tua prenotazione è stata annullata: $reason';
  }

  @override
  String get notification_checkin_status_update_title =>
      '📋 Aggiornamento check-in';

  @override
  String notification_checkin_status_update_body(String status) {
    return 'Il tuo stato di check-in è cambiato a: $status';
  }

  @override
  String get notification_admin_checkin_submitted_title =>
      '📝 Nuovo check-in in attesa';

  @override
  String notification_admin_checkin_submitted_body(
    String guestName,
    String unitName,
  ) {
    return '$guestName ha inviato il check-in per $unitName. In attesa di revisione.';
  }

  @override
  String get guest_parking_title => 'Parcheggio';

  @override
  String get guest_parking_available_singular => 'parcheggio disponibile';

  @override
  String get guest_parking_available_plural => 'parcheggi disponibili';

  @override
  String get guest_parking_error_loading => 'Errore di caricamento';

  @override
  String get guest_parking_empty_title => 'Nessun parcheggio';

  @override
  String get guest_parking_empty_subtitle =>
      'Presto aggiungeremo informazioni sui parcheggi vicini';

  @override
  String guest_parking_for_unit(String unitName) {
    return 'Parcheggio per $unitName';
  }

  @override
  String guest_parking_gps_label(String label) {
    return 'GPS: $label';
  }

  @override
  String get guest_parking_info_zones_title => 'INFORMAZIONI ZONE PARCHEGGIO';

  @override
  String get guest_parking_plaza_arenal_title => 'PARCHEGGIO PLAZA ARENAL';

  @override
  String get guest_parking_plaza_arenal_subtitle => 'A circa 5 minuti a piedi';

  @override
  String get guest_parking_plaza_arenal_content =>
      '• Pagamento tramite app El Parking: 6,95€/24h\n• Prenotazione tramite il loro sito web: 8€/24h (minimo 24h)\n• Pagamento biglietto alla cassa: 16€/24h';

  @override
  String get guest_parking_centro_title => 'PARCHEGGIO CENTRO CITTÀ';

  @override
  String get guest_parking_centro_subtitle => 'ZONA BLU O.R.A';

  @override
  String get guest_parking_centro_content =>
      '• Dal lunedì al venerdì: 9:00 - 13:30 e 17:00 - 20:00\n• Sabato: 9:00 - 14:00\n• Luglio e agosto: 9:00 - 14:00';

  @override
  String get guest_parking_free_zone_title => 'ZONA PARCHEGGIO GRATUITO';

  @override
  String get guest_parking_free_zone_subtitle => 'A circa 10 minuti a piedi';

  @override
  String get guest_parking_free_zone_content =>
      'Area di parcheggio rotante gratuita.';

  @override
  String get guest_checkin_camera_not_available =>
      'Nessuna fotocamera disponibile';

  @override
  String guest_checkin_camera_init_error(String error) {
    return 'Errore di inizializzazione fotocamera: $error';
  }

  @override
  String guest_checkin_camera_capture_error(String error) {
    return 'Errore di acquisizione: $error';
  }

  @override
  String get guest_checkin_camera_scan_title => 'Scansiona documento';

  @override
  String get guest_checkin_camera_starting => 'Avvio fotocamera...';

  @override
  String get guest_checkin_camera_frame_hint =>
      'Inquadra il documento all\'interno del riquadro';

  @override
  String get guest_checkin_camera_document_label => 'Documento d\'identità';

  @override
  String get admin_chat_messages => 'Messaggi';

  @override
  String get admin_chat_conversation_deleted => 'Conversazione eliminata';

  @override
  String get admin_chat_empty_title => 'Nessuna conversazione';

  @override
  String get admin_chat_empty_subtitle =>
      'Le conversazioni con gli ospiti\nappariranno qui';

  @override
  String get guest_chat_input_hint => 'Scrivi un messaggio...';

  @override
  String get admin_booking_detail_title => 'Dettaglio prenotazione';

  @override
  String get admin_booking_not_found => 'Prenotazione non trovata';

  @override
  String admin_booking_error(String error) {
    return 'Errore: $error';
  }

  @override
  String admin_booking_error_validating(String error) {
    return 'Errore nella validazione: $error';
  }

  @override
  String admin_booking_error_rejecting(String error) {
    return 'Errore nel rifiuto: $error';
  }

  @override
  String admin_booking_error_validating_checkout(String error) {
    return 'Errore nella validazione del check-out: $error';
  }

  @override
  String admin_booking_error_rejecting_checkout(String error) {
    return 'Errore nel rifiuto del check-out: $error';
  }

  @override
  String admin_booking_error_closing(String error) {
    return 'Errore nella chiusura della prenotazione: $error';
  }

  @override
  String admin_booking_error_cancelling(String error) {
    return 'Errore nell\'annullamento della prenotazione: $error';
  }

  @override
  String admin_booking_error_deleting(String error) {
    return 'Errore nell\'eliminazione della prenotazione: $error';
  }

  @override
  String admin_booking_error_updating(String error) {
    return 'Errore nell\'aggiornamento: $error';
  }

  @override
  String get admin_booking_resend_error => 'Impossibile reinviare il codice';

  @override
  String get admin_booking_notification_sent =>
      'Notifica inviata correttamente';

  @override
  String get admin_booking_notification_error =>
      'Errore nell\'invio della notifica';

  @override
  String get admin_booking_code_resent => 'Codice reinviato correttamente';

  @override
  String get admin_booking_checkin_validated =>
      'Check-in validato correttamente';

  @override
  String get admin_booking_checkin_rejected => 'Check-in rifiutato';

  @override
  String get admin_booking_checkout_validated =>
      'Check-out validato correttamente';

  @override
  String get admin_booking_checkout_rejected => 'Check-out rifiutato';

  @override
  String get admin_booking_incidents_detected => 'Incidenze rilevate';

  @override
  String get admin_booking_closed_successfully =>
      'Prenotazione chiusa correttamente';

  @override
  String get admin_booking_cancelled_successfully =>
      'Prenotazione annullata correttamente';

  @override
  String get admin_booking_deleted_successfully =>
      'Prenotazione eliminata correttamente';

  @override
  String get admin_booking_keybox_updated => 'Codice keybox aggiornato';

  @override
  String get admin_booking_already_closed_title => 'Prenotazione già chiusa';

  @override
  String get admin_booking_already_closed_message =>
      'Questa prenotazione è già chiusa.';

  @override
  String get admin_booking_already_cancelled_title =>
      'Prenotazione già annullata';

  @override
  String get admin_booking_already_cancelled_message =>
      'Questa prenotazione è già annullata.';

  @override
  String get admin_booking_cannot_delete_title => 'Impossibile eliminare';

  @override
  String admin_booking_cannot_delete_message(String status) {
    return 'Impossibile eliminare una prenotazione nello stato $status.';
  }

  @override
  String get admin_booking_cancel_booking => 'Annulla prenotazione';

  @override
  String get admin_booking_cancel_booking_confirm =>
      'Sei sicuro di voler annullare questa prenotazione? Questa azione non può essere annullata.';

  @override
  String get admin_booking_no_keep => 'No, mantieni';

  @override
  String get admin_booking_yes_cancel => 'Sì, annulla';

  @override
  String get admin_booking_delete_booking => 'Elimina prenotazione';

  @override
  String get admin_booking_delete_confirm =>
      'Sei sicuro di voler eliminare completamente questa prenotazione e tutti i dati associati? Questa azione è irreversibile.';

  @override
  String get admin_booking_close_booking => 'Chiudi prenotazione';

  @override
  String get admin_booking_close_confirm =>
      'Vuoi chiudere manualmente questa prenotazione? Verrà registrata la data di chiusura.';

  @override
  String get admin_booking_close_notes_hint => 'Note di chiusura (opzionale)';

  @override
  String get admin_booking_reject_checkout => 'Rifiuta check-out';

  @override
  String get admin_booking_reject_checkout_desc =>
      'Indica le incidenze rilevate per rifiutare il check-out.';

  @override
  String get admin_booking_incidents_hint =>
      'Descrivi le incidenze rilevate...';

  @override
  String get admin_booking_reject => 'Rifiuta';

  @override
  String get admin_booking_reject_checkin => 'Rifiuta check-in';

  @override
  String get admin_booking_reject_checkin_desc =>
      'Indica il motivo del rifiuto del check-in.';

  @override
  String get admin_booking_reject_reason_hint =>
      'Motivo del rifiuto (opzionale)...';

  @override
  String admin_booking_share_code_message(String code) {
    return 'Il tuo codice di accesso è: $code';
  }

  @override
  String admin_booking_share_keybox_code(String code) {
    return 'Codice keybox: $code';
  }

  @override
  String admin_booking_share_dates(String checkIn, String checkOut) {
    return 'Check-in: $checkIn | Check-out: $checkOut';
  }

  @override
  String get admin_booking_share_download_app => 'Scarica l\'app: BF Stay';

  @override
  String get admin_booking_edit_keybox_title => 'Codice Keybox';

  @override
  String get admin_booking_edit_keybox_desc =>
      'Inserisci il codice della cassetta delle chiavi';

  @override
  String get admin_booking_checkin_done => 'Check-in effettuato';

  @override
  String get admin_booking_checkout_done => 'Check-out effettuato';

  @override
  String get admin_booking_units_label => 'camere';

  @override
  String get admin_booking_email_sent => 'Email inviata';

  @override
  String get admin_booking_email_pending => 'Email in attesa';

  @override
  String get admin_booking_code_used => 'Codice utilizzato';

  @override
  String get admin_booking_code_unused => 'Codice non utilizzato';

  @override
  String get admin_booking_checkin_ok => 'Check-in OK';

  @override
  String get admin_booking_checkin_pending => 'Validazione in attesa';

  @override
  String get admin_booking_checkin_in_progress => 'In corso';

  @override
  String get admin_booking_no_checkin => 'Nessun check-in';

  @override
  String get admin_booking_guest_section => 'OSPITE';

  @override
  String get admin_booking_no_name => 'Nessun nome';

  @override
  String get admin_booking_reservation_section => 'PRENOTAZIONE';

  @override
  String get admin_booking_checkin_label => 'Check-in';

  @override
  String get admin_booking_checkout_label => 'Check-out';

  @override
  String get admin_booking_night_singular => 'notte';

  @override
  String get admin_booking_night_plural => 'notti';

  @override
  String get admin_booking_years_label => 'anni';

  @override
  String get admin_booking_rooms_section => 'Camere';

  @override
  String get admin_booking_wifi_label => 'WiFi';

  @override
  String get admin_booking_wifi_network_label => 'Rete:';

  @override
  String get admin_booking_wifi_password_label => 'Password:';

  @override
  String get admin_booking_wifi_password_clipboard => 'Password WiFi';

  @override
  String get admin_booking_access_code_label => 'Codice di accesso';

  @override
  String get admin_booking_access_code_clipboard => 'Codice di accesso';

  @override
  String get admin_booking_access_instructions_label => 'Istruzioni di accesso';

  @override
  String get admin_booking_access_codes_section => 'CODICI DI ACCESSO';

  @override
  String get admin_booking_reservation_code_label => 'Codice prenotazione';

  @override
  String get admin_booking_share_button => 'Condividi';

  @override
  String get admin_booking_keybox_not_set => 'Non configurato';

  @override
  String get admin_booking_keybox_code_label => 'Codice Keybox';

  @override
  String get admin_booking_keybox_code_clipboard => 'Codice Keybox';

  @override
  String get admin_booking_checkin_not_started => 'Check-in non iniziato';

  @override
  String get admin_booking_checkin_validated_status => 'Check-in validato';

  @override
  String get admin_booking_checkin_rejected_status => 'Check-in rifiutato';

  @override
  String get admin_booking_checkin_pending_validation =>
      'In attesa di validazione';

  @override
  String get admin_booking_checkin_in_progress_status => 'Check-in in corso';

  @override
  String get admin_booking_checkin_section => 'CHECK-IN';

  @override
  String get admin_booking_docs_pending => 'documenti in attesa';

  @override
  String get admin_booking_validate_button => 'Valida';

  @override
  String get admin_booking_reject_button => 'Rifiuta';

  @override
  String get admin_booking_internal_notes_section => 'NOTE INTERNE';

  @override
  String get admin_booking_closed_status => 'Prenotazione chiusa';

  @override
  String get admin_booking_checkout_validated_status => 'Check-out validato';

  @override
  String get admin_booking_checkout_incidents_status =>
      'Check-out con incidenze';

  @override
  String get admin_booking_checkout_requested_status => 'Check-out richiesto';

  @override
  String get admin_booking_checkout_pending_status => 'Check-out in attesa';

  @override
  String get admin_booking_checkout_section => 'CHECK-OUT';

  @override
  String get admin_booking_requested_label => 'Richiesto:';

  @override
  String get admin_booking_notes_label => 'Note:';

  @override
  String get admin_booking_incidents_button => 'Incidenze';

  @override
  String get admin_booking_close_booking_button => 'Chiudi prenotazione';

  @override
  String get admin_booking_close_booking_description =>
      'L\'ospite non ha richiesto il check-out. Puoi chiudere la prenotazione manualmente.';

  @override
  String get admin_booking_signature_section => 'FIRMA DEL TITOLARE';

  @override
  String get admin_booking_signature_unavailable => 'Firma non disponibile';

  @override
  String get admin_booking_actions_section => 'AZIONI';

  @override
  String get admin_booking_resend_code_title => 'Reinvia codice via email';

  @override
  String get admin_booking_last_sent_label => 'Ultimo invio:';

  @override
  String get admin_booking_na => 'N/D';

  @override
  String get admin_booking_not_sent_yet => 'Non ancora inviato';

  @override
  String get admin_booking_room_ready_title => 'Camera disponibile';

  @override
  String get admin_booking_room_ready_subtitle =>
      'Notifica all\'ospite che la camera è pronta e può accedere';

  @override
  String get admin_booking_cancel_booking_title => 'Annulla prenotazione';

  @override
  String get admin_booking_cancel_booking_subtitle =>
      'Segna la prenotazione come annullata';

  @override
  String get admin_booking_delete_booking_title => 'Elimina prenotazione';

  @override
  String get admin_booking_delete_booking_subtitle =>
      'Elimina completamente la prenotazione e i suoi dati (solo se non è finalizzata)';

  @override
  String get admin_dashboard_admin_title => 'BF-Stay Admin';

  @override
  String get admin_dashboard_tab_summary => 'Riepilogo';

  @override
  String get admin_dashboard_tab_bookings => 'Prenotazioni';

  @override
  String get admin_dashboard_tab_checkins => 'Check-in';

  @override
  String get admin_dashboard_tab_invoices => 'Fatture';

  @override
  String get admin_dashboard_tab_marketing => 'Marketing';

  @override
  String get admin_dashboard_tab_properties => 'Alloggi';

  @override
  String get guest_reviews_title => 'Recensioni';

  @override
  String get guest_reviews_write_review => 'Scrivi recensione';

  @override
  String get guest_reviews_published => 'Recensione pubblicata correttamente';

  @override
  String get guest_reviews_publishing => 'Pubblicazione recensione...';

  @override
  String get guest_reviews_updating => 'Aggiornamento recensione...';

  @override
  String get guest_reviews_deleting => 'Eliminazione recensione...';

  @override
  String get guest_reviews_loading => 'Caricamento recensioni...';

  @override
  String get guest_reviews_delete_review => 'Elimina recensione';

  @override
  String get guest_reviews_delete_confirm =>
      'Sei sicuro di voler eliminare la tua recensione? Questa azione non può essere annullata.';

  @override
  String get guest_reviews_filter_all => 'Tutte';

  @override
  String get guest_reviews_edit_review => 'Modifica recensione';

  @override
  String get guest_reviews_new_review => 'Nuova recensione';

  @override
  String get guest_reviews_updated => 'Recensione aggiornata';

  @override
  String get guest_reviews_info_public =>
      'La tua recensione sarà pubblica e aiuterà altri ospiti a prendere decisioni.';

  @override
  String get guest_reviews_your_rating => 'La tua valutazione';

  @override
  String get guest_reviews_tap_stars => 'Tocca le stelle per valutare';

  @override
  String get guest_reviews_rating_1 => 'Molto scarso';

  @override
  String get guest_reviews_rating_2 => 'Scarso';

  @override
  String get guest_reviews_rating_3 => 'Nella media';

  @override
  String get guest_reviews_rating_4 => 'Buono';

  @override
  String get guest_reviews_rating_5 => 'Eccellente';

  @override
  String get guest_reviews_title_label => 'Titolo (opzionale)';

  @override
  String get guest_reviews_title_hint =>
      'Riassumi la tua esperienza in una frase';

  @override
  String get guest_reviews_comment_required => 'Per favore, scrivi un commento';

  @override
  String get guest_reviews_comment_min_length =>
      'Il commento deve avere almeno 10 caratteri';

  @override
  String get guest_reviews_comment_label => 'Il tuo commento *';

  @override
  String get guest_reviews_comment_hint => 'Raccontaci la tua esperienza...';

  @override
  String get guest_reviews_save_changes => 'Salva modifiche';

  @override
  String get guest_reviews_publish_review => 'Pubblica recensione';

  @override
  String get guest_reviews_select_rating =>
      'Per favore, seleziona una valutazione';

  @override
  String get guest_reviews_saving => 'Salvataggio...';

  @override
  String get guest_alojamientos_title => 'I nostri alloggi';

  @override
  String get guest_alojamientos_error_title => 'Errore di caricamento';

  @override
  String get guest_alojamientos_empty_title => 'Nessun alloggio';

  @override
  String get guest_alojamientos_empty_subtitle =>
      'Nessun alloggio disponibile al momento';

  @override
  String guest_alojamientos_room_count(int count) {
    return '$count camere';
  }

  @override
  String get guest_alojamiento_detail_title => 'Dettagli';

  @override
  String get guest_alojamiento_units_available => 'Unità disponibili';

  @override
  String get guest_alojamiento_no_units => 'Nessuna unità disponibile';

  @override
  String get guest_alojamiento_location => 'Posizione';

  @override
  String get guest_alojamiento_common_areas => 'Aree comuni';

  @override
  String get guest_alojamiento_shared_spaces => 'Spazi condivisi';

  @override
  String get guest_alojamiento_common_areas_subtitle =>
      'Goditi le aree comuni dell\'hotel';

  @override
  String get guest_alojamiento_no_photos => 'Nessuna foto';

  @override
  String get guest_alojamiento_no_photos_subtitle =>
      'Nessuna foto delle aree comuni trovata';

  @override
  String guest_alojamiento_photos_count(int count) {
    return '$count foto';
  }

  @override
  String get guest_alojamiento_hotel_rooms_title => 'Hotel Boutique Jerez';

  @override
  String get guest_alojamiento_no_rooms => 'Nessuna camera';

  @override
  String get guest_alojamiento_no_rooms_subtitle =>
      'Nessuna camera disponibile al momento';

  @override
  String get guest_alojamiento_rooms => 'Camere';

  @override
  String get guest_alojamiento_features => 'Caratteristiche';

  @override
  String get guest_alojamiento_feature_flexible_checkin =>
      'Check-in flessibile';

  @override
  String get guest_alojamiento_feature_wifi => 'WiFi gratuito';

  @override
  String get guest_alojamiento_feature_ac => 'Aria condizionata';

  @override
  String get guest_alojamiento_description => 'Descrizione';

  @override
  String guest_alojamiento_description_text(String unitType) {
    return 'Scopri questo $unitType completamente attrezzato per rendere il tuo soggiorno il più confortevole possibile. Ha tutto il necessario per goderti Jerez al tuo ritmo.';
  }

  @override
  String get guest_alojamiento_services => 'Servizi inclusi';

  @override
  String get guest_alojamiento_service_kitchen => 'Cucina attrezzata';

  @override
  String get guest_alojamiento_service_washer => 'Lavatrice';

  @override
  String get guest_alojamiento_service_tv => 'Smart TV';

  @override
  String get guest_alojamiento_service_bedding => 'Biancheria da letto';

  @override
  String get guest_alojamiento_service_towels => 'Asciugamani';

  @override
  String get guest_alojamiento_service_coffee => 'Macchina del caffè';

  @override
  String get guest_alojamiento_access_info => 'Informazioni di accesso';

  @override
  String get guest_alojamiento_box_location => 'Posizione cassaforte';

  @override
  String get guest_alojamiento_access_instructions => 'Istruzioni di accesso';

  @override
  String get guest_house_rules_title => 'Regole della casa';

  @override
  String get guest_house_rules_subtitle =>
      'Consulta le regole e le raccomandazioni';

  @override
  String get guest_house_rules_empty_title => 'Nessuna regola';

  @override
  String get guest_house_rules_empty_subtitle =>
      'Questo alloggio non ha regole registrate';

  @override
  String get guest_normas_title => 'Regole';

  @override
  String get guest_normas_hotel_title => 'Regole dell\'hotel';

  @override
  String get guest_normas_apartment_title => 'Regole dell\'appartamento';

  @override
  String get guest_normas_not_available => 'Nessuna regola disponibile';

  @override
  String get guest_normas_image_error => 'Impossibile caricare l\'immagine';

  @override
  String get guest_normas_generic_error => 'Si è verificato un errore';

  @override
  String get guest_que_ver_title => 'Cosa vedere?';

  @override
  String get guest_que_ver_clear_filters => 'Cancella';

  @override
  String guest_que_ver_places_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count luoghi',
      one: '1 luogo',
    );
    return '$_temp0';
  }

  @override
  String get guest_que_ver_no_results => 'Nessun risultato';

  @override
  String get guest_que_ver_no_places => 'Nessun luogo';

  @override
  String get guest_que_ver_try_filters =>
      'Prova a cambiare i filtri di ricerca';

  @override
  String get guest_que_ver_coming_soon => 'Presto aggiungeremo nuovi luoghi';

  @override
  String get guest_que_ver_error_loading => 'Errore nel caricamento del luogo';

  @override
  String get guest_que_ver_place_not_found => 'Luogo non trovato';

  @override
  String get guest_que_ver_about_place => 'Su questo luogo';

  @override
  String get guest_que_ver_address => 'Indirizzo';

  @override
  String get guest_que_ver_best_time => 'Orario migliore per visitare';

  @override
  String get guest_que_ver_location => 'Posizione';

  @override
  String get guest_que_ver_practical_info => 'Informazioni pratiche';

  @override
  String get guest_que_ver_tips => 'Consigli';

  @override
  String get guest_que_ver_free_entry => 'Ingresso gratuito';

  @override
  String get guest_que_ver_how_to_get => 'Come arrivarci';

  @override
  String get guest_que_ver_copy_link => 'Copia link';

  @override
  String get guest_que_ver_official_web => 'Sito web ufficiale';

  @override
  String get guest_que_ver_link_copied => 'Link copiato negli appunti';

  @override
  String get guest_reviews_verified => 'Verificato';

  @override
  String get guest_reviews_show_less => 'Mostra meno';

  @override
  String get guest_reviews_show_more => 'Mostra di più';

  @override
  String get guest_reviews_empty_title => 'Nessuna recensione ancora';

  @override
  String get guest_reviews_empty_subtitle =>
      'Sii il primo a condividere la tua esperienza';

  @override
  String get guest_reviews_write_first => 'Scrivi recensione';

  @override
  String guest_reviews_filter_empty_title(String filter) {
    return 'Nessun risultato per $filter';
  }

  @override
  String get guest_reviews_filter_empty_subtitle =>
      'Prova a selezionare un altro filtro';

  @override
  String get guest_reviews_clear_filter => 'Cancella filtro';

  @override
  String guest_reviews_count_label(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recensioni',
      one: '1 recensione',
    );
    return '$_temp0';
  }

  @override
  String get guest_reviews_no_reviews_title => 'Nessuna recensione ancora';

  @override
  String get guest_reviews_be_first => 'Sii il primo';

  @override
  String get guest_access_no_booking => 'Prenotazione non trovata';

  @override
  String get guest_access_error_loading =>
      'Errore nel caricamento dei dati di accesso';

  @override
  String get guest_access_title => 'Accesso';

  @override
  String get guest_access_no_codes => 'Nessun codice di accesso disponibile';

  @override
  String get guest_access_codes_title => 'Codici di accesso';

  @override
  String get guest_access_codes_subtitle =>
      'Usa questi codici per accedere al tuo alloggio';

  @override
  String get guest_access_main_code => 'Codice principale';

  @override
  String get guest_access_main_door => 'Porta principale';

  @override
  String guest_access_valid_period(String from, String until) {
    return 'Valido da $from a $until';
  }

  @override
  String get guest_access_wifi_title => 'WiFi';

  @override
  String get guest_access_wifi_network => 'Rete:';

  @override
  String get guest_access_wifi_password => 'Password:';

  @override
  String get guest_access_password_copied => 'Password copiata negli appunti';

  @override
  String get guest_access_other_accesses => 'Altri accessi';

  @override
  String get guest_access_instructions => 'Istruzioni di accesso';

  @override
  String get guest_guide_title => 'Guida al soggiorno';

  @override
  String get guest_guide_subtitle => 'Tutte le informazioni sul tuo soggiorno';

  @override
  String get guest_guide_contact => 'Contatto';

  @override
  String get guest_guide_phone_1 => 'Telefono 1';

  @override
  String get guest_guide_phone_2 => 'Telefono 2';

  @override
  String get guest_guide_your_data => 'I tuoi dati';

  @override
  String get guest_guide_accommodation => 'Alloggio';

  @override
  String get guest_guide_property => 'Struttura';

  @override
  String get guest_guide_checkin => 'Check-in';

  @override
  String get guest_guide_checkout => 'Check-out';

  @override
  String get guest_guide_guests => 'Ospiti';

  @override
  String get guest_guide_services => 'Servizi';

  @override
  String get guest_guide_wifi => 'WiFi';

  @override
  String get guest_guide_laundry => 'Lavanderia';

  @override
  String get guest_guide_laundry_desc => 'Servizio lavanderia disponibile';

  @override
  String get guest_guide_jacuzzi => 'Jacuzzi';

  @override
  String get guest_guide_ac => 'Aria condizionata';

  @override
  String get guest_guide_ac_title => 'Aria condizionata';

  @override
  String get guest_guide_ac_desc => 'Clima controllato nel tuo alloggio';

  @override
  String get guest_guide_tv => 'TV';

  @override
  String get guest_guide_tv_title => 'Televisione';

  @override
  String get guest_guide_tv_desc => 'Smart TV con canali e app';

  @override
  String get guest_guide_not_available => 'Non disponibile';

  @override
  String get guest_guide_wifi_desc => 'Connessione WiFi inclusa';

  @override
  String get guest_guide_house_rules => 'Regole della casa';

  @override
  String get guest_guide_rule_checkin => 'Check-in dalle 16:00';

  @override
  String guest_guide_rule_checkout(String time) {
    return 'Check-out entro le $time';
  }

  @override
  String get guest_guide_rule_no_smoking => 'Vietato fumare';

  @override
  String get guest_guide_rule_no_parties => 'Niente feste consentite';

  @override
  String get guest_guide_rule_no_pets => 'Animali non ammessi';

  @override
  String get guest_notifications_title => 'Notifiche';

  @override
  String get guest_notifications_delete_all => 'Elimina tutte';

  @override
  String get guest_notifications_delete_all_title =>
      'Elimina tutte le notifiche';

  @override
  String get guest_notifications_delete_all_confirm =>
      'Sei sicuro di voler eliminare tutte le notifiche? Questa azione non può essere annullata.';

  @override
  String guest_notifications_unread_count(int count) {
    return '$count non lette';
  }

  @override
  String get guest_notifications_mark_all => 'Segna tutte come lette';

  @override
  String get guest_notifications_empty_title => 'Nessuna notifica';

  @override
  String get guest_notifications_empty_subtitle =>
      'Le notifiche sul tuo soggiorno appariranno qui';

  @override
  String get guest_notifications_read => 'Letto';

  @override
  String get guest_romantic_title => 'Pacchetto romantico';

  @override
  String get guest_romantic_surprise => 'Sorprendi il tuo partner';

  @override
  String get guest_romantic_unforgettable => 'Crea un momento indimenticabile';

  @override
  String get guest_romantic_includes => 'Cosa è incluso?';

  @override
  String get guest_romantic_decoration_title => 'Decorazione romantica';

  @override
  String get guest_romantic_decoration_desc =>
      'Petali di rosa, candele e decorazione speciale della camera';

  @override
  String get guest_romantic_choose_title => 'Scegli il tuo dettaglio';

  @override
  String get guest_romantic_choose_desc =>
      'Bottiglia di cava o cioccolato artigianale per accompagnare la serata';

  @override
  String get guest_romantic_basic_pack => 'Pacchetto romantico base';

  @override
  String get guest_romantic_price => '€49,90';

  @override
  String get guest_romantic_book_now => 'Prenota ora';

  @override
  String get guest_romantic_customize =>
      'O personalizza con extra al momento della prenotazione';

  @override
  String get guest_romantic_redirect =>
      'Sarai reindirizzato al sito web per completare la prenotazione del Pacchetto Romantico. Continuare?';

  @override
  String get guest_romantic_how_to => 'Come prenotare?';

  @override
  String get guest_romantic_step_1 => 'Seleziona il Pacchetto Romantico';

  @override
  String get guest_romantic_step_2 => 'Personalizza i dettagli';

  @override
  String get guest_romantic_step_3 => 'Completa la prenotazione online';

  @override
  String get guest_romantic_step_4 => 'Goditi la sorpresa';

  @override
  String get guest_romantic_note =>
      'La decorazione viene preparata durante la tua assenza così sarà una sorpresa completa.';

  @override
  String get guest_jacuzzi_title => 'Jacuzzi';

  @override
  String get guest_jacuzzi_rules_title => 'Regole d\'uso';

  @override
  String get guest_jacuzzi_subtitle => 'Rilassati e goditi';

  @override
  String get guest_jacuzzi_power => 'Accensione';

  @override
  String get guest_jacuzzi_power_step_1 =>
      'Premi il tasto POWER per accendere il jacuzzi';

  @override
  String get guest_jacuzzi_power_step_2 =>
      'Attendi che il pannello si illumini';

  @override
  String get guest_jacuzzi_power_step_3 =>
      'Seleziona la temperatura desiderata con i tasti + e -';

  @override
  String get guest_jacuzzi_lock => 'Blocco pannello';

  @override
  String get guest_jacuzzi_lock_step_1 =>
      'Per evitare attivazioni accidentali, puoi bloccare il pannello di controllo';

  @override
  String get guest_jacuzzi_lock_unlock => 'Sblocca';

  @override
  String get guest_jacuzzi_lock_unlock_step =>
      'Tieni premuto il tasto LOCK per 3 secondi';

  @override
  String get guest_jacuzzi_lock_manual => 'Blocco manuale';

  @override
  String get guest_jacuzzi_lock_manual_step =>
      'Tieni premuto il tasto LOCK per 3 secondi per attivare';

  @override
  String get guest_jacuzzi_ozone => 'Funzione ozono';

  @override
  String get guest_jacuzzi_ozone_intro =>
      'Il sistema a ozono aiuta a mantenere l\'acqua pulita e disinfettata automaticamente.';

  @override
  String get guest_jacuzzi_ozone_step_1 => 'Premi il tasto OZONE sul pannello';

  @override
  String get guest_jacuzzi_ozone_step_2 => 'Si attiverà la spia luminosa';

  @override
  String get guest_jacuzzi_ozone_step_3 =>
      'Il sistema funzionerà per 30 minuti';

  @override
  String get guest_jacuzzi_ozone_step_4 =>
      'Si disattiverà automaticamente al termine';

  @override
  String guest_jacuzzi_ozone_note(String note) {
    return 'Nota: $note';
  }

  @override
  String get guest_jacuzzi_massage => 'Funzioni massaggio';

  @override
  String get guest_jacuzzi_air_jets => 'Getti d\'aria';

  @override
  String get guest_jacuzzi_air_step_1 =>
      'Premi il tasto AIR per attivare i getti d\'aria';

  @override
  String get guest_jacuzzi_air_step_2 =>
      'Regola l\'intensità con i tasti + e -';

  @override
  String get guest_jacuzzi_air_step_3 =>
      'I getti creeranno bolle delicate nell\'acqua';

  @override
  String get guest_jacuzzi_air_step_4 => 'Premi di nuovo per disattivare';

  @override
  String get guest_jacuzzi_water_jets => 'Getti d\'acqua';

  @override
  String get guest_jacuzzi_water_step_1 =>
      'Premi il tasto JET per attivare i getti d\'acqua';

  @override
  String get guest_jacuzzi_water_step_2 =>
      'I getti d\'acqua offrono un massaggio più intenso';

  @override
  String get guest_jacuzzi_water_step_3 =>
      'Dirigi i getti verso le zone di tensione muscolare';

  @override
  String get guest_jacuzzi_water_step_4 => 'Premi di nuovo per disattivare';

  @override
  String get guest_jacuzzi_important => 'Importante';

  @override
  String get guest_jacuzzi_water_level_info =>
      'Il livello dell\'acqua deve essere sempre sopra i getti per un corretto funzionamento.';

  @override
  String get guest_jacuzzi_low_water_title => 'Se il livello è basso:';

  @override
  String get guest_jacuzzi_low_water_stop => 'Ferma immediatamente il jacuzzi';

  @override
  String get guest_jacuzzi_low_water_icon =>
      'Controlla l\'icona di avvertimento sul pannello';

  @override
  String get guest_jacuzzi_low_water_resume =>
      'Riempi con acqua fino a coprire i getti prima di riprendere.';

  @override
  String get guest_jacuzzi_water_responsibility =>
      'Uso responsabile dell\'acqua';

  @override
  String get guest_jacuzzi_water_refill_info =>
      'Il jacuzzi ha una notevole capacità d\'acqua. Ti preghiamo di usarla responsabilmente.';

  @override
  String get guest_jacuzzi_capacity => 'Capacità:';

  @override
  String get guest_jacuzzi_capacity_liters => '800 litri';

  @override
  String get guest_jacuzzi_water_regulation =>
      'Il riempimento e lo svuotamento del jacuzzi è regolato dalle normative locali sull\'uso dell\'acqua.';

  @override
  String get guest_jacuzzi_thanks =>
      'Grazie per la tua collaborazione nell\'uso responsabile dell\'acqua.';

  @override
  String get guest_physical_registration_title => 'Registrazione fisica';

  @override
  String get guest_physical_registration_header =>
      'Registrazione alla reception';

  @override
  String get guest_physical_registration_subtitle =>
      'Completa la tua registrazione di persona';

  @override
  String get guest_physical_registration_instructions => 'Istruzioni';

  @override
  String get guest_physical_registration_step_1_title => 'Vai alla reception';

  @override
  String get guest_physical_registration_step_1_desc =>
      'Recati alla reception dell\'hotel durante l\'orario di attenzione';

  @override
  String get guest_physical_registration_step_2_title =>
      'Presenta il tuo documento';

  @override
  String get guest_physical_registration_step_2_desc =>
      'Mostra il tuo documento d\'identità originale (DNI, passaporto o patente di guida)';

  @override
  String get guest_physical_registration_step_3_title => 'Firma il registro';

  @override
  String get guest_physical_registration_step_3_desc =>
      'Firma il documento di registrazione all\'arrivo';

  @override
  String get guest_physical_registration_step_4_title => 'Ricevi la tua chiave';

  @override
  String get guest_physical_registration_step_4_desc =>
      'Ti consegneremo la chiave della tua camera';

  @override
  String get guest_physical_registration_schedule => 'Orari reception';

  @override
  String get guest_physical_registration_schedule_hours => 'Orario lavorativo';

  @override
  String get guest_physical_registration_schedule_days =>
      'Dal lunedì al venerdì';

  @override
  String get guest_physical_registration_documents => 'Documenti accettati';

  @override
  String get guest_physical_registration_doc_dni => 'DNI';

  @override
  String get guest_physical_registration_doc_passport => 'Passaporto';

  @override
  String get guest_physical_registration_doc_license => 'Patente di guida';

  @override
  String get guest_checkin_child_no_data =>
      'Sotto i 14 anni, nessun dato richiesto';

  @override
  String get guest_checkin_holder => 'Principale';

  @override
  String get guest_checkin_full_name => 'Nome completo';

  @override
  String get guest_checkin_email => 'Email';

  @override
  String get guest_checkin_phone => 'Telefono';

  @override
  String guest_checkin_young(int age) {
    return 'Minore ($age anni)';
  }

  @override
  String guest_checkin_adult(int number) {
    return 'Adulto $number';
  }

  @override
  String guest_checkin_guest(int number) {
    return 'Ospite $number';
  }

  @override
  String get guest_checkin_document_id => 'Documento d\'identità';

  @override
  String get guest_checkin_upload_document => 'Carica documento';

  @override
  String get guest_checkin_document => 'Documento';

  @override
  String get guest_checkin_missing_photo => 'Foto del documento mancante';

  @override
  String get guest_checkin_upload_document_title => 'Carica documento';

  @override
  String get guest_checkin_document_type => 'Tipo di documento';

  @override
  String get guest_checkin_document_number => 'Numero documento';

  @override
  String get guest_checkin_document_photo => 'Foto del documento';

  @override
  String get guest_checkin_image_captured => 'Immagine acquisita';

  @override
  String get guest_checkin_tap_to_capture => 'Tocca per acquisire il documento';

  @override
  String get guest_checkin_camera_or_gallery => 'Fotocamera o galleria';

  @override
  String get guest_checkin_select_source => 'Seleziona origine';

  @override
  String get guest_checkin_camera => 'Fotocamera';

  @override
  String get guest_checkin_gallery => 'Galleria';

  @override
  String get guest_checkin_photo_required => 'Foto richiesta';

  @override
  String get guest_checkin_confirm => 'Conferma';

  @override
  String guest_checkin_capture_error(String error) {
    return 'Errore nell\'acquisizione dell\'immagine: $error';
  }

  @override
  String get admin_chat_title => 'Chat';

  @override
  String get admin_chat_online => 'Online';

  @override
  String get admin_chat_delete_conversation => 'Elimina conversazione';

  @override
  String get admin_chat_delete_confirm_body =>
      'Sei sicuro di voler eliminare questa conversazione?';

  @override
  String get admin_chat_deleted_success =>
      'Conversazione eliminata con successo';

  @override
  String admin_chat_error_deleting(String error) {
    return 'Errore nell\'eliminazione della conversazione: $error';
  }

  @override
  String get admin_checkin_detail_title => 'Dettaglio check-in';

  @override
  String get admin_checkin_validate => 'Valida';

  @override
  String get admin_checkin_reject => 'Rifiuta';

  @override
  String get admin_checkin_cancel_booking => 'Annulla prenotazione';

  @override
  String get admin_checkin_error_loading => 'Errore di caricamento';

  @override
  String get admin_checkin_not_found => 'Check-in non trovato';

  @override
  String get admin_checkin_status_pending => 'In attesa';

  @override
  String get admin_checkin_status_validated => 'Validato';

  @override
  String get admin_checkin_status_rejected => 'Rifiutato';

  @override
  String get admin_checkin_status_cancelled => 'Annullato';

  @override
  String get admin_checkin_status_draft => 'Bozza';

  @override
  String get admin_checkin_submitted_label => 'Inviato:';

  @override
  String get admin_checkin_validated_label => 'Validato:';

  @override
  String get admin_checkin_rejected_label => 'Rifiutato:';

  @override
  String get admin_checkin_cancelled_label => 'Annullato:';

  @override
  String get admin_checkin_booking_info => 'Info prenotazione';

  @override
  String get admin_checkin_property_label => 'Struttura:';

  @override
  String get admin_checkin_units_label => 'camere';

  @override
  String get admin_checkin_unit_label => 'camera';

  @override
  String get admin_checkin_code_label => 'Codice:';

  @override
  String get admin_checkin_checkin_date_label => 'Check-in:';

  @override
  String get admin_checkin_checkout_date_label => 'Check-out:';

  @override
  String get admin_checkin_guests_section => 'OSPITI';

  @override
  String get admin_checkin_primary_badge => 'Principale';

  @override
  String get admin_checkin_na => 'N/D';

  @override
  String get admin_checkin_documents_section => 'DOCUMENTI';

  @override
  String get admin_checkin_unknown_guest => 'Ospite sconosciuto';

  @override
  String get admin_checkin_signature_section => 'FIRMA';

  @override
  String get admin_checkin_doc_type_dni => 'DNI';

  @override
  String get admin_checkin_doc_type_nie => 'NIE';

  @override
  String get admin_checkin_doc_type_passport => 'Passaporto';

  @override
  String get admin_checkin_image_load_error =>
      'Errore nel caricamento dell\'immagine';

  @override
  String get admin_checkin_validate_title => 'Valida check-in';

  @override
  String get admin_checkin_validate_message =>
      'Sei sicuro di voler validare questo check-in?';

  @override
  String get admin_checkin_validated_success =>
      'Check-in validato con successo';

  @override
  String admin_checkin_error(String error) {
    return 'Errore: $error';
  }

  @override
  String get admin_checkin_reject_title => 'Rifiuta check-in';

  @override
  String get admin_checkin_reject_message =>
      'Sei sicuro di voler rifiutare questo check-in?';

  @override
  String get admin_checkin_reject_hint => 'Motivo del rifiuto (opzionale)...';

  @override
  String get admin_checkin_no_reason => 'Nessun motivo';

  @override
  String get admin_checkin_rejected_success =>
      'Check-in rifiutato con successo';

  @override
  String get admin_checkin_cancel_message =>
      'Sei sicuro di voler annullare questa prenotazione?';

  @override
  String get admin_checkin_cancel_warning =>
      'Questa azione non può essere annullata.';

  @override
  String get admin_checkin_cancel_reason_label => 'Motivo dell\'annullamento';

  @override
  String get admin_checkin_cancel_reason_hint =>
      'Descrivi il motivo dell\'annullamento...';

  @override
  String get admin_checkin_cancelled_success =>
      'Prenotazione annullata con successo';

  @override
  String get admin_invoice_generate_pdf => 'Genera PDF';

  @override
  String get admin_invoice_share => 'Condividi';

  @override
  String get admin_invoice_download => 'Scarica';

  @override
  String get admin_invoice_share_title => 'Condividi fattura';

  @override
  String get admin_invoice_copy_link => 'Copia link';

  @override
  String admin_invoice_pdf_saved(String path) {
    return 'PDF salvato in: $path';
  }

  @override
  String get admin_invoice_issue => 'Emetti';

  @override
  String get admin_invoice_mark_paid => 'Segna come pagata';

  @override
  String admin_invoice_paid_on(String date) {
    return 'Pagata il $date';
  }

  @override
  String admin_invoice_cancelled(String reason) {
    return 'Annullata: $reason';
  }

  @override
  String get admin_invoice_issue_confirm_title => 'Emetti fattura';

  @override
  String admin_invoice_issue_confirm_message(String invoiceNumber) {
    return 'Sei sicuro di voler emettere la fattura $invoiceNumber?';
  }

  @override
  String get admin_invoice_mark_paid_confirm_title => 'Segna come pagata';

  @override
  String admin_invoice_mark_paid_confirm_message(String total) {
    return 'Confermi di aver ricevuto il pagamento di $total?';
  }

  @override
  String get admin_invoice_confirm_payment => 'Conferma pagamento';

  @override
  String get admin_invoice_cancel_confirm_title => 'Annulla fattura';

  @override
  String get admin_invoice_cancel_reason_label => 'Motivo dell\'annullamento';

  @override
  String get admin_invoice_cancel_reason_hint =>
      'Descrivi il motivo dell\'annullamento...';

  @override
  String get admin_invoice_dont_cancel => 'Non annullare';

  @override
  String get admin_invoice_cancel_invoice => 'Annulla fattura';

  @override
  String admin_invoice_error_generate_pdf(String error) {
    return 'Errore nella generazione del PDF: $error';
  }

  @override
  String admin_invoice_error_share(String error) {
    return 'Errore nella condivisione: $error';
  }

  @override
  String admin_invoice_error_download(String error) {
    return 'Errore nel download: $error';
  }

  @override
  String get admin_invoice_nif_label => 'NIF/CIF:';

  @override
  String get admin_invoice_label => 'Fattura';

  @override
  String get admin_invoice_bill_to => 'Intestata a';

  @override
  String get admin_invoice_issue_date_label => 'Data emissione:';

  @override
  String get admin_invoice_due_date_label => 'Data scadenza:';

  @override
  String get admin_invoice_period_label => 'Periodo';

  @override
  String get admin_invoice_booking_label => 'Prenotazione';

  @override
  String get admin_invoice_no_line_items => 'Nessuna voce';

  @override
  String get admin_invoice_col_description => 'Descrizione';

  @override
  String get admin_invoice_col_qty => 'Qtà';

  @override
  String get admin_invoice_col_price => 'Prezzo';

  @override
  String get admin_invoice_col_total => 'Totale';

  @override
  String get admin_invoice_tax_base => 'Imponibile';

  @override
  String get admin_invoice_tax_label => 'IVA';

  @override
  String get admin_invoice_total_label => 'Totale';

  @override
  String get admin_invoice_notes_label => 'Note';

  @override
  String get admin_notifications_title => 'Notifiche';

  @override
  String get admin_notifications_empty_title => 'Nessuna notifica';

  @override
  String get admin_notifications_empty_subtitle =>
      'Le notifiche appariranno qui';

  @override
  String get admin_notifications_mark_all_read => 'Segna tutte come lette';

  @override
  String get admin_notifications_mark_read => 'Segna come letta';

  @override
  String get admin_notifications_delete_all => 'Elimina tutte';

  @override
  String get admin_notifications_delete_all_title =>
      'Elimina tutte le notifiche';

  @override
  String get admin_notifications_delete_all_confirm =>
      'Sei sicuro di voler eliminare tutte le notifiche?';

  @override
  String admin_notifications_unread_count(int count) {
    return '$count non lette';
  }

  @override
  String get guest_access_checkin => 'Check-in';

  @override
  String get guest_access_checkout => 'Check-out';

  @override
  String get guest_access_checkout_label => 'Check-out';

  @override
  String guest_access_checkout_until(String time) {
    return 'Fino alle $time';
  }

  @override
  String get guest_access_checkout_deadline => 'Scadenza check-out';

  @override
  String get guest_access_checkout_instructions =>
      'Istruzioni per il check-out';

  @override
  String get guest_access_code_label => 'Codice';

  @override
  String guest_access_code_available_at(String date, String time) {
    return 'Disponibile il $date alle $time';
  }

  @override
  String get guest_access_code_provided_by_staff => 'Fornito dal personale';

  @override
  String get guest_access_locker_code => 'Codice armadietto';

  @override
  String get guest_access_locker_code_label => 'Codice armadietto';

  @override
  String guest_access_locker_available_at(String date) {
    return 'Disponibile il $date';
  }

  @override
  String get guest_access_key_locker => 'Cassetta delle chiavi';

  @override
  String get guest_access_door_code => 'Codice porta';

  @override
  String get guest_access_building_access => 'Accesso all\'edificio';

  @override
  String get guest_access_building_instructions =>
      'Istruzioni per l\'accesso all\'edificio';

  @override
  String get guest_access_apartment_access => 'Accesso all\'appartamento';

  @override
  String get guest_access_apartment_instructions =>
      'Istruzioni per l\'accesso all\'appartamento';

  @override
  String get guest_access_location => 'Posizione';

  @override
  String get guest_access_contact => 'Contatto';

  @override
  String get guest_access_contact_description =>
      'Contattaci se hai bisogno di aiuto';

  @override
  String guest_access_copied(String label) {
    return '$label copiato negli appunti';
  }

  @override
  String get guest_access_open_maps => 'Apri in Maps';

  @override
  String get guest_access_network => 'Rete';

  @override
  String get guest_access_network_name => 'Nome rete';

  @override
  String get guest_access_password => 'Password';

  @override
  String get guest_access_company_name => 'BF Stay';

  @override
  String get guest_access_house_rules => 'Regole della casa';

  @override
  String get guest_access_rules_warning =>
      'Ti preghiamo di leggere le regole della casa prima del tuo arrivo';

  @override
  String get guest_access_your_accommodation => 'Il tuo alloggio';

  @override
  String get guest_access_your_codes => 'I tuoi codici';

  @override
  String get guest_access_guest => 'Ospite';

  @override
  String guest_access_welcome_message(String unitName) {
    return 'Benvenuto a $unitName';
  }

  @override
  String guest_access_hello(String name) {
    return 'Ciao $name';
  }

  @override
  String guest_access_codes_available_datetime(String date, String time) {
    return 'Disponibile il $date alle $time';
  }

  @override
  String guest_access_codes_available_message(String time) {
    return 'Il tuo codice sarà disponibile dalle $time';
  }

  @override
  String get guest_access_loading_instructions => 'Caricamento istruzioni...';

  @override
  String get guest_access_cannot_load_instructions =>
      'Impossibile caricare le istruzioni';

  @override
  String get guest_access_rule_no_parties_title => 'Niente feste';

  @override
  String get guest_access_rule_no_parties_description =>
      'Non sono consentite feste o eventi';

  @override
  String get guest_access_rule_no_smoking_title => 'Vietato fumare';

  @override
  String get guest_access_rule_smoke_free_description =>
      'Questa è una struttura non fumatori';

  @override
  String get guest_access_rule_registered_only_title => 'Solo registrati';

  @override
  String get guest_access_rule_registered_only_description =>
      'Solo gli ospiti registrati possono accedere';

  @override
  String get guest_accommodation_title => 'Alloggio';

  @override
  String get guest_accommodation_error_loading => 'Errore di caricamento';

  @override
  String get guest_accommodation_error_occurred => 'Si è verificato un errore';

  @override
  String get guest_accommodation_no_booking => 'Prenotazione non trovata';

  @override
  String get guest_accommodation_booking_not_found =>
      'Prenotazione non trovata';

  @override
  String get guest_accommodation_no_unit_info =>
      'Nessuna informazione sull\'unità disponibile';

  @override
  String get guest_accommodation_address => 'Indirizzo';

  @override
  String get guest_accommodation_address_unavailable =>
      'Indirizzo non disponibile';

  @override
  String get guest_accommodation_box_location => 'Posizione cassaforte';

  @override
  String get guest_accommodation_access_codes => 'Codici di accesso';

  @override
  String get guest_accommodation_access_instructions => 'Istruzioni di accesso';

  @override
  String get guest_accommodation_main_door => 'Porta principale';

  @override
  String get guest_accommodation_door_code => 'Codice porta';

  @override
  String get guest_accommodation_portal_code => 'Codice portone';

  @override
  String get guest_accommodation_key_box_code => 'Codice cassetta chiavi';

  @override
  String get guest_accommodation_keybox_description =>
      'Codice per la cassetta delle chiavi';

  @override
  String get guest_accommodation_wifi_password => 'Password WiFi';

  @override
  String guest_accommodation_rooms_count(int count) {
    return '$count camere';
  }

  @override
  String get guest_accommodation_hotel_rules => 'Regole dell\'hotel';

  @override
  String get guest_accommodation_apartment_rules => 'Regole dell\'appartamento';

  @override
  String get guest_accommodation_rules_description =>
      'Consulta le regole del tuo alloggio';

  @override
  String guest_accommodation_rules_load_error(String error) {
    return 'Errore nel caricamento delle regole: $error';
  }

  @override
  String guest_accommodation_codes_available_datetime(
    String date,
    String time,
  ) {
    return 'Disponibile il $date alle $time';
  }

  @override
  String guest_accommodation_codes_available_message(String time) {
    return 'I tuoi codici saranno disponibili quando inizia il tuo soggiorno ($time)';
  }

  @override
  String guest_accommodation_file_not_found(String message) {
    return 'File non trovato: $message';
  }

  @override
  String get guest_accommodation_cannot_open_document =>
      'Impossibile aprire il documento';

  @override
  String get guest_accommodation_tap_for_access_info =>
      'Tocca per le informazioni di accesso';

  @override
  String get guest_chat_default_title => 'Chat';

  @override
  String get guest_chat_online => 'Online';

  @override
  String get guest_chat_start_conversation => 'Inizia conversazione';

  @override
  String get guest_chat_welcome_message => 'Ciao! Come possiamo aiutarti?';

  @override
  String get guest_checkin_label => 'Check-in';

  @override
  String get guest_checkin_back => 'Indietro';

  @override
  String get guest_checkin_continue => 'Continua';

  @override
  String get guest_checkin_complete => 'Completa';

  @override
  String get guest_checkin_loading_booking =>
      'Caricamento dati prenotazione...';

  @override
  String get guest_checkin_error_loading => 'Errore di caricamento';

  @override
  String get guest_checkin_booking => 'Prenotazione';

  @override
  String get guest_checkin_code => 'Codice';

  @override
  String get guest_checkin_guests_label => 'Ospiti';

  @override
  String guest_checkin_guests_count(int count) {
    return '$count ospiti';
  }

  @override
  String guest_checkin_guests_registered(int count) {
    return '$count registrati';
  }

  @override
  String guest_checkin_guests_summary(int count) {
    return '$count ospiti';
  }

  @override
  String get guest_checkin_guest_data => 'Dati ospite';

  @override
  String get guest_checkin_guest_data_description =>
      'Compila i dati di tutti gli ospiti';

  @override
  String get guest_checkin_holder_badge => 'PRINCIPALE';

  @override
  String get guest_checkin_holder_signature => 'Firma dell\'ospite principale';

  @override
  String get guest_checkin_no_name => 'Nessun nome';

  @override
  String get guest_checkin_guest_no_name => 'Ospite senza nome';

  @override
  String guest_checkin_adults_children(int adults, int children) {
    return '$adults adulti e $children minori';
  }

  @override
  String get guest_checkin_minor_badge => 'MINORE';

  @override
  String guest_checkin_young_document_required(int age) {
    return 'Sotto i $age anni, documento richiesto';
  }

  @override
  String get guest_checkin_document_required => 'Documento richiesto';

  @override
  String get guest_checkin_upload => 'Carica';

  @override
  String guest_checkin_documents_uploaded(int completed, int total) {
    return '$completed di $total documenti caricati';
  }

  @override
  String get guest_checkin_all_documents_uploaded =>
      'Tutti i documenti caricati';

  @override
  String get guest_checkin_upload_documents_description =>
      'Carica le foto dei documenti d\'identità di tutti gli ospiti';

  @override
  String get guest_checkin_uploaded_documents => 'Documenti caricati';

  @override
  String get guest_checkin_pending_documents => 'Documenti in attesa';

  @override
  String get guest_checkin_identity_documents => 'Documenti d\'identità';

  @override
  String get guest_checkin_signature_description =>
      'Firma dell\'ospite principale della prenotazione';

  @override
  String get guest_checkin_signature_pending => 'Firma in attesa';

  @override
  String get guest_checkin_signature_captured => 'Firma acquisita';

  @override
  String get guest_checkin_signature_captured_short => 'Firma';

  @override
  String get guest_checkin_clear_signature => 'Cancella firma';

  @override
  String get guest_checkin_step_guests => 'Ospiti';

  @override
  String get guest_checkin_step_documents => 'Documenti';

  @override
  String get guest_checkin_step_signature => 'Firma';

  @override
  String get guest_checkin_step_confirm => 'Conferma';

  @override
  String get guest_checkin_online => 'Online';

  @override
  String get guest_checkin_pending => 'In attesa';

  @override
  String get guest_checkin_validated => 'Validato';

  @override
  String get guest_checkin_waiting_validation => 'In attesa di validazione';

  @override
  String get guest_checkin_completed => 'Completato';

  @override
  String get guest_checkin_completed_success =>
      'Check-in completato con successo';

  @override
  String get guest_checkin_sending => 'Invio in corso...';

  @override
  String get guest_checkin_progress => 'Avanzamento check-in';

  @override
  String get guest_checkin_confirmation => 'Conferma check-in';

  @override
  String get guest_checkin_confirmation_description =>
      'Il tuo check-in è stato inviato. Ora devi aspettare che l\'alloggio lo validi.';

  @override
  String get guest_checkin_legal_notice => 'Avviso legale';

  @override
  String get guest_checkout_title => 'Check-out';

  @override
  String get guest_checkout_label => 'Check-out';

  @override
  String get guest_checkout_checkin_label => 'Check-in';

  @override
  String get guest_checkout_checkout_label => 'Check-out';

  @override
  String guest_checkout_nights_count(int count) {
    return '$count notti';
  }

  @override
  String guest_checkout_guests_count(int count) {
    return '$count ospiti';
  }

  @override
  String get guest_checkout_stay_summary => 'Riepilogo soggiorno';

  @override
  String get guest_checkout_confirm => 'Conferma';

  @override
  String get guest_checkout_confirm_button => 'Conferma check-out';

  @override
  String get guest_checkout_confirm_dialog_title => 'Confermare il check-out?';

  @override
  String get guest_checkout_confirm_dialog_message =>
      'Stai per confermare il tuo check-out. Vuoi continuare?';

  @override
  String get guest_checkout_confirm_info => 'Conferma check-out in corso...';

  @override
  String get guest_checkout_processing => 'Elaborazione in corso...';

  @override
  String get guest_checkout_completed => 'Check-out completato';

  @override
  String get guest_checkout_thank_you => 'Grazie per il tuo soggiorno!';

  @override
  String get guest_checkout_feedback_title => 'La tua opinione è importante';

  @override
  String get guest_checkout_feedback_hint => 'Raccontaci la tua esperienza...';

  @override
  String get guest_checkout_rating_title => 'Valuta il tuo soggiorno';

  @override
  String get guest_checkout_review_description =>
      'La tua opinione aiuta altri viaggiatori';

  @override
  String get guest_checkout_loading => 'Caricamento...';

  @override
  String get guest_checkout_error_loading => 'Errore di caricamento';

  @override
  String get guest_checkout_already_done => 'Check-out già effettuato';

  @override
  String get guest_checkout_already_done_message =>
      'Hai già effettuato il check-out. Grazie!';

  @override
  String get guest_home_welcome => 'Benvenuto';

  @override
  String get guest_home_welcome_stay => 'Benvenuto nel tuo soggiorno';

  @override
  String guest_home_hello_name(String name) {
    return 'Ciao, $name';
  }

  @override
  String get guest_home_your_stay => 'Il tuo soggiorno';

  @override
  String get guest_home_no_booking => 'Nessuna prenotazione';

  @override
  String get guest_home_not_authenticated => 'Non autenticato';

  @override
  String get guest_home_stay_active_enjoy =>
      'Il tuo soggiorno è attivo. Buon divertimento!';

  @override
  String get guest_home_quick_actions => 'Azioni rapide';

  @override
  String get guest_home_checkin => 'Check-in';

  @override
  String get guest_home_checkout => 'Check-out';

  @override
  String get guest_home_chat => 'Chat';

  @override
  String get guest_home_guide => 'Guida';

  @override
  String get guest_home_rules => 'Regole';

  @override
  String get guest_home_parkings => 'Parcheggio';

  @override
  String get guest_home_accommodations => 'Alloggi';

  @override
  String get guest_home_accommodation => 'Alloggio';

  @override
  String guest_home_rooms_count(int count) {
    return '$count camere';
  }

  @override
  String get guest_home_guests => 'Ospiti';

  @override
  String guest_home_nights(int count) {
    return '$count notti';
  }

  @override
  String get guest_home_what_to_see => 'Cosa vedere';

  @override
  String get guest_home_instructions => 'Istruzioni';

  @override
  String get guest_home_my_accommodation => 'Il mio alloggio';

  @override
  String get guest_home_booking_cancelled => 'Prenotazione annullata';

  @override
  String get guest_home_booking_cancelled_message =>
      'La tua prenotazione è stata annullata. Contatta la reception.';

  @override
  String get guest_home_cancellation_reason => 'Motivo dell\'annullamento';

  @override
  String get guest_home_checkin_pending => 'Check-in in attesa';

  @override
  String get guest_home_checkin_sent_waiting =>
      'Check-in inviato, in attesa di validazione';

  @override
  String get guest_home_checkin_rejected => 'Check-in rifiutato';

  @override
  String get guest_home_rejection_reason => 'Motivo del rifiuto';

  @override
  String get guest_home_pending_validation => 'In attesa di validazione';

  @override
  String get guest_home_complete_checkin_access =>
      'Completa il check-in per accedere';

  @override
  String get guest_home_contact_reception => 'Contatta la reception';

  @override
  String get guest_home_correct_errors_resend =>
      'Correggi gli errori e reinvia';

  @override
  String get guest_home_physical_registration => 'Registrazione di persona';

  @override
  String get guest_home_romantic_pack => 'Pacchetto romantico';

  @override
  String guest_jacuzzi_note(String note) {
    return 'Nota: $note';
  }

  @override
  String get public_services_title => 'I nostri servizi';

  @override
  String get public_service_rules_title => 'Regole della casa';

  @override
  String get public_service_rules_desc => 'Regole e raccomandazioni.';

  @override
  String public_copyright(int year) {
    return '© $year BF Stay • Tutti i diritti riservati';
  }

  @override
  String get public_access_booking => 'Accedi alla mia prenotazione';

  @override
  String staff_dashboard_greeting(String name) {
    return 'Ciao $name';
  }

  @override
  String get staff_dashboard_control_panel => 'Pannello di controllo';

  @override
  String get staff_dashboard_daily_summary => 'Riepilogo giornaliero';

  @override
  String get staff_dashboard_occupancy => 'Occupazione';

  @override
  String get staff_dashboard_pending => 'In attesa';

  @override
  String get staff_dashboard_pending_checkin => 'Check-in in attesa';

  @override
  String get staff_dashboard_pending_checkout => 'Check-out in attesa';

  @override
  String get staff_dashboard_pending_tasks => 'Attività in attesa';

  @override
  String get staff_dashboard_checkins_today => 'Check-in di oggi';

  @override
  String get staff_dashboard_checkouts_today => 'Check-out di oggi';

  @override
  String get staff_dashboard_quick_actions => 'Azioni rapide';

  @override
  String get staff_dashboard_manage_checkins => 'Gestisci check-in';

  @override
  String get staff_dashboard_view_guests => 'Visualizza ospiti';

  @override
  String staff_dashboard_room_extras(String room) {
    return 'Camera $room - Extra';
  }

  @override
  String get staff_dashboard_cleaning_request => 'Richiesta di pulizia';

  @override
  String staff_dashboard_room_guest(String room, String guest) {
    return 'Camera $room - $guest';
  }

  @override
  String get staff_dashboard_generate_report => 'Genera report';

  @override
  String get staff_checkins_title => 'Check-in';

  @override
  String get staff_checkins_tab_pending => 'In attesa';

  @override
  String get staff_checkins_tab_in_progress => 'In corso';

  @override
  String get staff_checkins_tab_completed => 'Completati';

  @override
  String get staff_checkins_status_pending => 'In attesa';

  @override
  String get staff_checkins_status_in_progress => 'In corso';

  @override
  String get staff_checkins_status_completed => 'Completato';

  @override
  String get staff_checkins_start => 'Inizia';

  @override
  String get staff_checkins_new_checkin => 'Nuovo check-in';

  @override
  String get staff_checkins_complete => 'Completa';

  @override
  String get staff_checkins_view_details => 'Visualizza dettagli';

  @override
  String get guest_access_wifi_password_label => 'Password WiFi';

  @override
  String get guest_access_locker_provided_by_staff => 'Fornito dal personale';

  @override
  String get guest_access_rule_smoke_free_title => 'Vietato fumare';

  @override
  String get guest_accommodation_view_rules_pdf => 'Visualizza regole come PDF';

  @override
  String get public_hero_title_line1 => 'Il tuo soggiorno,';

  @override
  String get public_hero_title_line2 => 'Elevato';
}
