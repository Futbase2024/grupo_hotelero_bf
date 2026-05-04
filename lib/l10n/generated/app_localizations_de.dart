// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SDe extends S {
  SDe([String locale = 'de']) : super(locale);

  @override
  String get common_app_name => 'BF Stay';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_exit => 'Beenden';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_loading => 'Laden...';

  @override
  String get common_retry => 'Erneut versuchen';

  @override
  String get common_accept => 'Akzeptieren';

  @override
  String get common_continue => 'Weiter';

  @override
  String get common_back => 'Zurück';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error => 'Fehler';

  @override
  String get common_success => 'Erfolg';

  @override
  String get common_no_data => 'Keine Daten';

  @override
  String get common_yes => 'Ja';

  @override
  String get common_no => 'Nein';

  @override
  String get common_send => 'Senden';

  @override
  String get common_edit => 'Bearbeiten';

  @override
  String get common_search => 'Suchen';

  @override
  String get common_later => 'Später';

  @override
  String get common_update => 'Aktualisieren';

  @override
  String get common_understood => 'Verstanden';

  @override
  String get common_exit_app_title => 'BF Stay beenden';

  @override
  String get common_exit_app_message =>
      'Möchten Sie die App wirklich beenden?\n\nIhre Sitzung bleibt aktiv, wenn Sie zurückkehren.';

  @override
  String get common_logout_title => 'Abmelden';

  @override
  String get common_logout_message =>
      'Möchten Sie sich wirklich abmelden?\n\nSie können sich jederzeit mit Ihrem Buchungscode wieder anmelden.';

  @override
  String get common_logout_button => 'Abmelden';

  @override
  String get common_splash_ready => 'Bereit';

  @override
  String get common_splash_loading => 'Wird geladen...';

  @override
  String get common_update_force_title => 'Update erforderlich';

  @override
  String get common_update_available_title => 'Neue Version verfügbar';

  @override
  String get common_update_force_message =>
      'Sie müssen die App aktualisieren, um sie weiter nutzen zu können. Diese Version enthält wichtige Verbesserungen und Sicherheitsupdates.';

  @override
  String get common_update_available_message =>
      'Eine neue Version mit Verbesserungen und Fehlerbehebungen ist verfügbar. Möchten Sie jetzt aktualisieren?';

  @override
  String common_update_version(String version) {
    return 'Version $version';
  }

  @override
  String get common_page_not_found => 'Seite nicht gefunden';

  @override
  String get common_invalid_route => 'Ungültige Route';

  @override
  String get common_back_to_home => 'Zurück zur Startseite';

  @override
  String get common_theme_light => 'Hell';

  @override
  String get common_theme_dark => 'Dunkel';

  @override
  String get common_theme_mode_light => 'Heller Modus';

  @override
  String get common_theme_mode_dark => 'Dunkler Modus';

  @override
  String get common_theme_system => 'System';

  @override
  String get common_theme_app_label => 'App-Design';

  @override
  String common_copied_to_clipboard(String type) {
    return '$type in die Zwischenablage kopiert';
  }

  @override
  String get common_phone_type => 'Telefon';

  @override
  String get common_email_type => 'E-Mail';

  @override
  String get enum_booking_status_created => 'Erstellt';

  @override
  String get enum_booking_status_confirmed => 'Bestätigt';

  @override
  String get enum_booking_status_active => 'Aktiv';

  @override
  String get enum_booking_status_in_house => 'Im Haus';

  @override
  String get enum_booking_status_checked_out => 'Ausgecheckt';

  @override
  String get enum_booking_status_closed => 'Geschlossen';

  @override
  String get enum_booking_status_cancelled => 'Storniert';

  @override
  String get enum_booking_status_created_desc =>
      'Buchung erstellt, Bestätigung ausstehend';

  @override
  String get enum_booking_status_confirmed_desc =>
      'Buchung bestätigt, Check-in ausstehend';

  @override
  String get enum_booking_status_active_desc =>
      'Check-in validiert, vollständiges Panel zugänglich';

  @override
  String get enum_booking_status_in_house_desc =>
      'Gast befindet sich in der Unterkunft';

  @override
  String get enum_booking_status_checked_in_legacy_desc =>
      'Check-in validiert (veraltet)';

  @override
  String get enum_booking_status_checked_out_desc =>
      'Check-out abgeschlossen, Gast hat die Unterkunft verlassen';

  @override
  String get enum_booking_status_closed_desc =>
      'Buchung abgeschlossen und geschlossen';

  @override
  String get enum_booking_status_cancelled_desc => 'Buchung storniert';

  @override
  String get enum_checkin_status_not_started => 'Ausstehend';

  @override
  String get enum_checkin_status_in_progress => 'In Bearbeitung';

  @override
  String get enum_checkin_status_submitted => 'Eingereicht';

  @override
  String get enum_checkin_status_validated => 'Validiert';

  @override
  String get enum_checkin_status_rejected => 'Abgelehnt';

  @override
  String get enum_checkin_status_cancelled => 'Storniert';

  @override
  String get enum_checkin_status_not_started_desc =>
      'Der Gast hat den Check-in noch nicht begonnen';

  @override
  String get enum_checkin_status_in_progress_desc =>
      'Der Gast füllt seine Daten aus';

  @override
  String get enum_checkin_status_submitted_desc =>
      'Überprüfung durch den Administrator ausstehend';

  @override
  String get enum_checkin_status_validated_desc =>
      'Check-in validiert, Aufenthalt genehmigt';

  @override
  String get enum_checkin_status_rejected_desc =>
      'Korrektur durch den Gast erforderlich';

  @override
  String get enum_checkin_status_cancelled_desc =>
      'Buchung storniert, bitte kontaktieren Sie die Rezeption';

  @override
  String get enum_checkout_status_not_started => 'Nicht begonnen';

  @override
  String get enum_checkout_status_requested => 'Angefordert';

  @override
  String get enum_checkout_status_validated => 'Validiert';

  @override
  String get enum_checkout_status_rejected => 'Abgelehnt';

  @override
  String get enum_checkout_status_not_started_desc =>
      'Der Aufenthalt läuft noch';

  @override
  String get enum_checkout_status_requested_desc =>
      'Der Gast hat den Check-out angefordert';

  @override
  String get enum_checkout_status_validated_desc =>
      'Check-out validiert, Buchung kann geschlossen werden';

  @override
  String get enum_checkout_status_rejected_desc =>
      'Es gibt noch zu lösende Probleme';

  @override
  String get public_badge_exclusivity => 'EXKLUSIVITÄT GARANTIERT';

  @override
  String get public_hero_title_prefix => 'Dein Aufenthalt, ';

  @override
  String get public_hero_title_suffix => 'Erhöht';

  @override
  String get public_cta_access_booking => 'Auf meine Buchung zugreifen';

  @override
  String get public_services_section_title => 'Unsere Dienstleistungen';

  @override
  String get public_footer_brand_name => 'BF STAY';

  @override
  String public_footer_copyright(int year) {
    return '© $year BF Stay • Alle Rechte vorbehalten';
  }

  @override
  String get public_footer_privacy_policy => 'Datenschutzrichtlinie';

  @override
  String get public_service_checkin_title => 'Digitaler Check-in';

  @override
  String get public_service_checkin_desc => 'Einchecken ohne Wartezeit.';

  @override
  String get public_service_checkout_title => 'Digitaler Check-out';

  @override
  String get public_service_checkout_desc => 'Schnelles Auschecken.';

  @override
  String get public_service_house_rules_title => 'Hausordnung';

  @override
  String get public_service_house_rules_desc => 'Regeln und Empfehlungen.';

  @override
  String get public_service_what_to_see_title => 'Was besichtigen?';

  @override
  String get public_service_what_to_see_desc =>
      'Nahe gelegene Sehenswürdigkeiten.';

  @override
  String get public_service_parking_title => 'Parkplätze';

  @override
  String get public_service_parking_desc => 'Parkmöglichkeiten.';

  @override
  String get public_service_chat_title => 'Chat';

  @override
  String get public_service_chat_desc =>
      'Virtueller Concierge rund um die Uhr.';

  @override
  String get public_service_accommodations_title => 'Unterkünfte';

  @override
  String get public_service_accommodations_desc => 'Weitere Unterkünfte.';

  @override
  String get public_service_reviews_title => 'Bewertungen';

  @override
  String get public_service_reviews_desc => 'Gästebewertungen.';

  @override
  String get public_service_parking_title_light => 'Parkplätze in der Nähe';

  @override
  String get public_service_accommodations_title_light => 'Unsere Unterkünfte';

  @override
  String get public_service_accommodations_desc_light =>
      'Weitere verfügbare Unterkünfte.';

  @override
  String get public_service_reviews_title_light => 'Bewertungen und Kommentare';

  @override
  String get public_hero_subtitle =>
      'Intelligente Verwaltung für exklusive Unterkünfte.';

  @override
  String get auth_login_brand_name => 'BF Stay';

  @override
  String get auth_login_subtitle => 'Kontrollpanel';

  @override
  String get auth_feature_bookings => 'Buchungsverwaltung';

  @override
  String get auth_feature_checkin => 'Digitaler Check-in';

  @override
  String get auth_feature_chat => 'Gäste-Chat';

  @override
  String get auth_feature_keyless => 'Schlüsselloser Zugang';

  @override
  String get auth_field_email => 'E-Mail';

  @override
  String get auth_field_password => 'Passwort';

  @override
  String get auth_validation_email_required =>
      'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get auth_validation_email_invalid =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get auth_validation_password_required =>
      'Bitte geben Sie Ihr Passwort ein';

  @override
  String get auth_validation_password_min_length =>
      'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get auth_forgot_password => 'Passwort vergessen?';

  @override
  String get auth_login_button => 'Anmelden';

  @override
  String get auth_divider_or => 'oder';

  @override
  String get auth_guest_access_button => 'Mit Buchungscode zugreifen';

  @override
  String get auth_login_footer => 'BF Stay © 2026';

  @override
  String get auth_recover_password_title => 'Passwort wiederherstellen';

  @override
  String get auth_recover_password_body =>
      'Geben Sie Ihre E-Mail-Adresse ein und wir senden Ihnen Anweisungen zum Zurücksetzen Ihres Passworts.';

  @override
  String get auth_recover_password_sent => 'Wiederherstellungs-E-Mail gesendet';

  @override
  String get auth_button_send => 'Senden';

  @override
  String get auth_booking_access_title => 'Gästezugang';

  @override
  String get auth_booking_benefit_code => 'Buchungscode';

  @override
  String get auth_booking_benefit_personal => 'Personalisierter Zugang';

  @override
  String get auth_booking_benefit_instant => 'Sofortiger Zugang';

  @override
  String get auth_booking_benefit_secure_checkin => 'Sicherer Check-in';

  @override
  String get auth_booking_code_info_short =>
      'Sie haben Ihren Buchungscode in der Bestätigungs-E-Mail erhalten.';

  @override
  String get auth_booking_code_info_full =>
      'Sie haben Ihren Buchungscode in der Buchungsbestätigungs-E-Mail erhalten.';

  @override
  String get auth_booking_desktop_subtitle =>
      'Genießen Sie Ihren Aufenthalt mit digitalem Zugang';

  @override
  String get auth_booking_form_subtitle =>
      'Geben Sie Ihren Buchungscode ein, um auf Ihre Unterkunft zuzugreifen';

  @override
  String get auth_booking_field_code => 'Buchungscode';

  @override
  String get auth_booking_code_hint => 'XX-XXXX-XXXX';

  @override
  String get auth_booking_validation_code_required =>
      'Bitte geben Sie Ihren Buchungscode ein';

  @override
  String get auth_booking_validation_code_invalid =>
      'Das Codeformat ist ungültig';

  @override
  String get auth_booking_access_button => 'Zugriff';

  @override
  String get auth_booking_help_title => 'Wo finde ich meinen Code?';

  @override
  String get auth_booking_help_body =>
      'Sie haben Ihren Buchungscode in der Buchungsbestätigungs-E-Mail erhalten. Er hat das Format BF-XXXXX.';

  @override
  String get auth_booking_footer => 'BF Stay © 2026';

  @override
  String get auth_booking_error_title => 'Zugriffsfehler';

  @override
  String get auth_booking_error_code_not_found =>
      'Der Buchungscode existiert nicht. Bitte überprüfen Sie, ob Sie ihn korrekt eingegeben haben.';

  @override
  String get auth_booking_error_code_expired =>
      'Dieser Buchungscode ist abgelaufen. Kontaktieren Sie die Rezeption, um einen neuen zu erhalten.';

  @override
  String get auth_booking_error_email_mismatch =>
      'Die E-Mail-Adresse stimmt nicht mit der Buchung überein. Bitte stellen Sie sicher, dass es dieselbe E-Mail-Adresse ist, die Sie bei der Buchung verwendet haben.';

  @override
  String get auth_booking_error_generic =>
      'Der Buchungscode konnte nicht verifiziert werden. Bitte versuchen Sie es erneut.';

  @override
  String get auth_booking_error_dismiss => 'Verstanden';

  @override
  String get auth_sheet_title => 'Auf Ihre Buchung zugreifen';

  @override
  String get auth_sheet_subtitle =>
      'Geben Sie Ihre E-Mail und den erhaltenen Code ein';

  @override
  String get auth_sheet_label_email => 'E-MAIL';

  @override
  String get auth_sheet_hint_email => 'sie@email.com';

  @override
  String get auth_sheet_label_code => 'BUCHUNGSCODE';

  @override
  String get auth_sheet_hint_code => 'BF-XXXX-XXXX';

  @override
  String get auth_sheet_submit_button => 'Auf meine Buchung zugreifen';

  @override
  String get auth_sheet_help_text =>
      'Haben Sie keinen Code? Kontaktieren Sie Ihre Unterkunft';

  @override
  String get auth_admin_sheet_title => 'Privater Zugang';

  @override
  String get auth_admin_sheet_subtitle =>
      'Nur für autorisiertes BF-Stay Personal';

  @override
  String get auth_admin_label_email => 'E-MAIL';

  @override
  String get auth_admin_hint_email => 'admin@bfstay.com';

  @override
  String get auth_admin_label_password => 'PASSWORT';

  @override
  String get auth_admin_hint_password => '••••••••';

  @override
  String get auth_admin_error_unauthorized =>
      'Sie haben keinen Zugang zu diesem Panel';

  @override
  String get auth_admin_submit_button => 'Panel aufrufen';

  @override
  String get guest_settings_title => 'Einstellungen';

  @override
  String get guest_settings_section_language => 'Sprache';

  @override
  String get guest_settings_language_title => 'App-Sprache';

  @override
  String get guest_settings_language_subtitle =>
      'Wählen Sie die Sprache der Benutzeroberfläche';

  @override
  String get guest_settings_section_legal => 'Rechtliches';

  @override
  String get guest_settings_privacy_policy_title => 'Datenschutzrichtlinie';

  @override
  String get guest_settings_privacy_policy_subtitle =>
      'Unsere Datenschutzrichtlinie anzeigen';

  @override
  String get guest_settings_privacy_open_error =>
      'Die Datenschutzrichtlinie konnte nicht geöffnet werden';

  @override
  String get notification_channel_name => 'BF Stay Benachrichtigungen';

  @override
  String get notification_channel_description =>
      'BF Stay Benachrichtigungskanal';

  @override
  String get notification_checkin_validated_title => '✅ Check-in validiert';

  @override
  String get notification_checkin_validated_body =>
      'Ihr Check-in wurde erfolgreich validiert. Willkommen!';

  @override
  String get notification_checkin_rejected_title => '❌ Check-in abgelehnt';

  @override
  String get notification_checkin_rejected_body =>
      'Ihr Check-in wurde abgelehnt. Bitte überprüfen Sie Ihre Unterlagen.';

  @override
  String notification_checkin_rejected_body_with_reason(String reason) {
    return 'Ihr Check-in wurde abgelehnt: $reason';
  }

  @override
  String get notification_booking_cancelled_title => '🚫 Buchung storniert';

  @override
  String get notification_booking_cancelled_body =>
      'Ihre Buchung wurde storniert. Bitte kontaktieren Sie die Rezeption.';

  @override
  String notification_booking_cancelled_body_with_reason(String reason) {
    return 'Ihre Buchung wurde storniert: $reason';
  }

  @override
  String get notification_checkin_status_update_title =>
      '📋 Check-in Aktualisierung';

  @override
  String notification_checkin_status_update_body(String status) {
    return 'Ihr Check-in-Status hat sich geändert zu: $status';
  }

  @override
  String get notification_admin_checkin_submitted_title =>
      '📝 Neuer ausstehender Check-in';

  @override
  String notification_admin_checkin_submitted_body(
    String guestName,
    String unitName,
  ) {
    return '$guestName hat seinen Check-in für $unitName eingereicht. Überprüfung ausstehend.';
  }

  @override
  String get guest_parking_title => 'Parkplatz';

  @override
  String get guest_parking_available_singular => 'Parkplatz verfügbar';

  @override
  String get guest_parking_available_plural => 'Parkplätze verfügbar';

  @override
  String get guest_parking_error_loading => 'Fehler beim Laden';

  @override
  String get guest_parking_empty_title => 'Keine Parkplätze';

  @override
  String get guest_parking_empty_subtitle =>
      'Wir werden bald Informationen zu nahegelegenen Parkplätzen hinzufügen';

  @override
  String guest_parking_for_unit(String unitName) {
    return 'Parkplatz für $unitName';
  }

  @override
  String guest_parking_gps_label(String label) {
    return 'GPS: $label';
  }

  @override
  String get guest_parking_info_zones_title => 'INFORMATIONEN ZU PARKZONEN';

  @override
  String get guest_parking_plaza_arenal_title => 'PARKPLATZ PLAZA ARENAL';

  @override
  String get guest_parking_plaza_arenal_subtitle =>
      'Ungefähr 5 Gehminuten entfernt';

  @override
  String get guest_parking_plaza_arenal_content =>
      '• Zahlung über die El Parking App: 6,95€/24h\n• Buchung über ihre Webseite: 8€/24h (mindestens 24h)\n• Zahlung am Automaten: 16€/24h';

  @override
  String get guest_parking_centro_title => 'PARKPLATZ STADTZENTRUM';

  @override
  String get guest_parking_centro_subtitle => 'O.R.A BLAUE ZONE';

  @override
  String get guest_parking_centro_content =>
      '• Montag bis Freitag: 9:00 - 13:30 und 17:00 - 20:00\n• Samstag: 9:00 - 14:00\n• Juli und August: 9:00 - 14:00';

  @override
  String get guest_parking_free_zone_title => 'KOSTENLOSE PARKZONE';

  @override
  String get guest_parking_free_zone_subtitle =>
      'Ungefähr 10 Gehminuten entfernt';

  @override
  String get guest_parking_free_zone_content =>
      'Kostenloser Wechselparkbereich.';

  @override
  String get guest_checkin_camera_not_available => 'Keine Kameras verfügbar';

  @override
  String guest_checkin_camera_init_error(String error) {
    return 'Fehler beim Initialisieren der Kamera: $error';
  }

  @override
  String guest_checkin_camera_capture_error(String error) {
    return 'Aufnahmefehler: $error';
  }

  @override
  String get guest_checkin_camera_scan_title => 'Dokument scannen';

  @override
  String get guest_checkin_camera_starting => 'Kamera wird gestartet...';

  @override
  String get guest_checkin_camera_frame_hint =>
      'Halten Sie das Dokument im Rahmen';

  @override
  String get guest_checkin_camera_document_label => 'Ausweisdokument';

  @override
  String get admin_chat_messages => 'Nachrichten';

  @override
  String get admin_chat_conversation_deleted => 'Konversation gelöscht';

  @override
  String get admin_chat_empty_title => 'Keine Konversationen';

  @override
  String get admin_chat_empty_subtitle =>
      'Konversationen mit Gästen\nwerden hier angezeigt';

  @override
  String get guest_chat_input_hint => 'Nachricht eingeben...';

  @override
  String get admin_booking_detail_title => 'Buchungsdetails';

  @override
  String get admin_booking_not_found => 'Buchung nicht gefunden';

  @override
  String admin_booking_error(String error) {
    return 'Fehler: $error';
  }

  @override
  String admin_booking_error_validating(String error) {
    return 'Fehler bei der Validierung: $error';
  }

  @override
  String admin_booking_error_rejecting(String error) {
    return 'Fehler bei der Ablehnung: $error';
  }

  @override
  String admin_booking_error_validating_checkout(String error) {
    return 'Fehler bei der Check-out-Validierung: $error';
  }

  @override
  String admin_booking_error_rejecting_checkout(String error) {
    return 'Fehler bei der Check-out-Ablehnung: $error';
  }

  @override
  String admin_booking_error_closing(String error) {
    return 'Fehler beim Schließen der Buchung: $error';
  }

  @override
  String admin_booking_error_cancelling(String error) {
    return 'Fehler beim Stornieren der Buchung: $error';
  }

  @override
  String admin_booking_error_deleting(String error) {
    return 'Fehler beim Löschen der Buchung: $error';
  }

  @override
  String admin_booking_error_updating(String error) {
    return 'Fehler beim Aktualisieren: $error';
  }

  @override
  String get admin_booking_resend_error =>
      'Code konnte nicht erneut gesendet werden';

  @override
  String get admin_booking_notification_sent =>
      'Benachrichtigung erfolgreich gesendet';

  @override
  String get admin_booking_notification_error =>
      'Fehler beim Senden der Benachrichtigung';

  @override
  String get admin_booking_code_resent => 'Code erfolgreich erneut gesendet';

  @override
  String get admin_booking_checkin_validated =>
      'Check-in erfolgreich validiert';

  @override
  String get admin_booking_checkin_rejected => 'Check-in abgelehnt';

  @override
  String get admin_booking_checkout_validated =>
      'Check-out erfolgreich validiert';

  @override
  String get admin_booking_checkout_rejected => 'Check-out abgelehnt';

  @override
  String get admin_booking_incidents_detected => 'Vorfälle festgestellt';

  @override
  String get admin_booking_closed_successfully =>
      'Buchung erfolgreich geschlossen';

  @override
  String get admin_booking_cancelled_successfully =>
      'Buchung erfolgreich storniert';

  @override
  String get admin_booking_deleted_successfully =>
      'Buchung erfolgreich gelöscht';

  @override
  String get admin_booking_keybox_updated => 'Keybox-Code aktualisiert';

  @override
  String get admin_booking_already_closed_title =>
      'Buchung bereits geschlossen';

  @override
  String get admin_booking_already_closed_message =>
      'Diese Buchung ist bereits geschlossen.';

  @override
  String get admin_booking_already_cancelled_title =>
      'Buchung bereits storniert';

  @override
  String get admin_booking_already_cancelled_message =>
      'Diese Buchung ist bereits storniert.';

  @override
  String get admin_booking_cannot_delete_title => 'Löschen nicht möglich';

  @override
  String admin_booking_cannot_delete_message(String status) {
    return 'Eine Buchung mit dem Status $status kann nicht gelöscht werden.';
  }

  @override
  String get admin_booking_cancel_booking => 'Buchung stornieren';

  @override
  String get admin_booking_cancel_booking_confirm =>
      'Möchten Sie diese Buchung wirklich stornieren? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get admin_booking_no_keep => 'Nein, behalten';

  @override
  String get admin_booking_yes_cancel => 'Ja, stornieren';

  @override
  String get admin_booking_delete_booking => 'Buchung löschen';

  @override
  String get admin_booking_delete_confirm =>
      'Möchten Sie diese Buchung und alle zugehörigen Daten wirklich vollständig löschen? Diese Aktion ist unwiderruflich.';

  @override
  String get admin_booking_close_booking => 'Buchung schließen';

  @override
  String get admin_booking_close_confirm =>
      'Möchten Sie diese Buchung manuell schließen? Das Schlussdatum wird registriert.';

  @override
  String get admin_booking_close_notes_hint => 'Abschlussnotizen (optional)';

  @override
  String get admin_booking_reject_checkout => 'Check-out ablehnen';

  @override
  String get admin_booking_reject_checkout_desc =>
      'Geben Sie die festgestellten Vorfälle an, um den Check-out abzulehnen.';

  @override
  String get admin_booking_incidents_hint =>
      'Beschreiben Sie die festgestellten Vorfälle...';

  @override
  String get admin_booking_reject => 'Ablehnen';

  @override
  String get admin_booking_reject_checkin => 'Check-in ablehnen';

  @override
  String get admin_booking_reject_checkin_desc =>
      'Geben Sie den Ablehnungsgrund für den Check-in an.';

  @override
  String get admin_booking_reject_reason_hint =>
      'Ablehnungsgrund (optional)...';

  @override
  String admin_booking_share_code_message(String code) {
    return 'Ihr Zugangscode lautet: $code';
  }

  @override
  String admin_booking_share_keybox_code(String code) {
    return 'Keybox-Code: $code';
  }

  @override
  String admin_booking_share_dates(String checkIn, String checkOut) {
    return 'Check-in: $checkIn | Check-out: $checkOut';
  }

  @override
  String get admin_booking_share_download_app => 'App herunterladen: BF Stay';

  @override
  String get admin_booking_edit_keybox_title => 'Keybox-Code';

  @override
  String get admin_booking_edit_keybox_desc =>
      'Geben Sie den Code des Schlüsselschranks ein';

  @override
  String get admin_booking_checkin_done => 'Check-in durchgeführt';

  @override
  String get admin_booking_checkout_done => 'Check-out durchgeführt';

  @override
  String get admin_booking_units_label => 'Zimmer';

  @override
  String get admin_booking_email_sent => 'E-Mail gesendet';

  @override
  String get admin_booking_email_pending => 'E-Mail ausstehend';

  @override
  String get admin_booking_code_used => 'Code verwendet';

  @override
  String get admin_booking_code_unused => 'Code nicht verwendet';

  @override
  String get admin_booking_checkin_ok => 'Check-in OK';

  @override
  String get admin_booking_checkin_pending => 'Validierung ausstehend';

  @override
  String get admin_booking_checkin_in_progress => 'In Bearbeitung';

  @override
  String get admin_booking_no_checkin => 'Kein Check-in';

  @override
  String get admin_booking_guest_section => 'GAST';

  @override
  String get admin_booking_no_name => 'Kein Name';

  @override
  String get admin_booking_reservation_section => 'BUCHUNG';

  @override
  String get admin_booking_checkin_label => 'Check-in';

  @override
  String get admin_booking_checkout_label => 'Check-out';

  @override
  String get admin_booking_night_singular => 'Nacht';

  @override
  String get admin_booking_night_plural => 'Nächte';

  @override
  String get admin_booking_years_label => 'Jahre';

  @override
  String get admin_booking_rooms_section => 'Zimmer';

  @override
  String get admin_booking_wifi_label => 'WiFi';

  @override
  String get admin_booking_wifi_network_label => 'Netzwerk:';

  @override
  String get admin_booking_wifi_password_label => 'Passwort:';

  @override
  String get admin_booking_wifi_password_clipboard => 'WiFi-Passwort';

  @override
  String get admin_booking_access_code_label => 'Zugangscode';

  @override
  String get admin_booking_access_code_clipboard => 'Zugangscode';

  @override
  String get admin_booking_access_instructions_label => 'Zugangsanweisungen';

  @override
  String get admin_booking_access_codes_section => 'ZUGANGSCODES';

  @override
  String get admin_booking_reservation_code_label => 'Buchungscode';

  @override
  String get admin_booking_share_button => 'Teilen';

  @override
  String get admin_booking_keybox_not_set => 'Nicht konfiguriert';

  @override
  String get admin_booking_keybox_code_label => 'Keybox-Code';

  @override
  String get admin_booking_keybox_code_clipboard => 'Keybox-Code';

  @override
  String get admin_booking_checkin_not_started =>
      'Check-in noch nicht begonnen';

  @override
  String get admin_booking_checkin_validated_status => 'Check-in validiert';

  @override
  String get admin_booking_checkin_rejected_status => 'Check-in abgelehnt';

  @override
  String get admin_booking_checkin_pending_validation =>
      'Validierung ausstehend';

  @override
  String get admin_booking_checkin_in_progress_status =>
      'Check-in in Bearbeitung';

  @override
  String get admin_booking_checkin_section => 'CHECK-IN';

  @override
  String get admin_booking_docs_pending => 'Dokumente ausstehend';

  @override
  String get admin_booking_validate_button => 'Validieren';

  @override
  String get admin_booking_reject_button => 'Ablehnen';

  @override
  String get admin_booking_internal_notes_section => 'INTERNE NOTIZEN';

  @override
  String get admin_booking_closed_status => 'Buchung geschlossen';

  @override
  String get admin_booking_checkout_validated_status => 'Check-out validiert';

  @override
  String get admin_booking_checkout_incidents_status =>
      'Check-out mit Vorfällen';

  @override
  String get admin_booking_checkout_requested_status => 'Check-out angefordert';

  @override
  String get admin_booking_checkout_pending_status => 'Check-out ausstehend';

  @override
  String get admin_booking_checkout_section => 'CHECK-OUT';

  @override
  String get admin_booking_requested_label => 'Angefordert:';

  @override
  String get admin_booking_notes_label => 'Notizen:';

  @override
  String get admin_booking_incidents_button => 'Vorfälle';

  @override
  String get admin_booking_close_booking_button => 'Buchung schließen';

  @override
  String get admin_booking_close_booking_description =>
      'Der Gast hat keinen Check-out angefordert. Sie können die Buchung manuell schließen.';

  @override
  String get admin_booking_signature_section => 'UNTERSCHRIFT DES INHABERS';

  @override
  String get admin_booking_signature_unavailable =>
      'Unterschrift nicht verfügbar';

  @override
  String get admin_booking_actions_section => 'AKTIONEN';

  @override
  String get admin_booking_resend_code_title => 'Code per E-Mail erneut senden';

  @override
  String get admin_booking_last_sent_label => 'Zuletzt gesendet:';

  @override
  String get admin_booking_na => 'N/A';

  @override
  String get admin_booking_not_sent_yet => 'Noch nicht gesendet';

  @override
  String get admin_booking_room_ready_title => 'Zimmer verfügbar';

  @override
  String get admin_booking_room_ready_subtitle =>
      'Den Gast benachrichtigen, dass das Zimmer bereit ist und zugegriffen werden kann';

  @override
  String get admin_booking_cancel_booking_title => 'Buchung stornieren';

  @override
  String get admin_booking_cancel_booking_subtitle =>
      'Buchung als storniert markieren';

  @override
  String get admin_booking_delete_booking_title => 'Buchung löschen';

  @override
  String get admin_booking_delete_booking_subtitle =>
      'Buchung und zugehörige Daten vollständig löschen (nur wenn noch nicht abgeschlossen)';

  @override
  String get admin_dashboard_admin_title => 'BF-Stay Admin';

  @override
  String get admin_dashboard_tab_summary => 'Übersicht';

  @override
  String get admin_dashboard_tab_bookings => 'Buchungen';

  @override
  String get admin_dashboard_tab_checkins => 'Check-ins';

  @override
  String get admin_dashboard_tab_invoices => 'Rechnungen';

  @override
  String get admin_dashboard_tab_marketing => 'Marketing';

  @override
  String get admin_dashboard_tab_properties => 'Unterkünfte';

  @override
  String get guest_reviews_title => 'Bewertungen';

  @override
  String get guest_reviews_write_review => 'Bewertung schreiben';

  @override
  String get guest_reviews_published => 'Bewertung erfolgreich veröffentlicht';

  @override
  String get guest_reviews_publishing => 'Bewertung wird veröffentlicht...';

  @override
  String get guest_reviews_updating => 'Bewertung wird aktualisiert...';

  @override
  String get guest_reviews_deleting => 'Bewertung wird gelöscht...';

  @override
  String get guest_reviews_loading => 'Bewertungen werden geladen...';

  @override
  String get guest_reviews_delete_review => 'Bewertung löschen';

  @override
  String get guest_reviews_delete_confirm =>
      'Möchten Sie Ihre Bewertung wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get guest_reviews_filter_all => 'Alle';

  @override
  String get guest_reviews_edit_review => 'Bewertung bearbeiten';

  @override
  String get guest_reviews_new_review => 'Neue Bewertung';

  @override
  String get guest_reviews_updated => 'Bewertung aktualisiert';

  @override
  String get guest_reviews_info_public =>
      'Ihre Bewertung wird öffentlich sein und anderen Gästen bei ihrer Entscheidung helfen.';

  @override
  String get guest_reviews_your_rating => 'Ihre Bewertung';

  @override
  String get guest_reviews_tap_stars =>
      'Tippen Sie auf die Sterne, um zu bewerten';

  @override
  String get guest_reviews_rating_1 => 'Sehr schlecht';

  @override
  String get guest_reviews_rating_2 => 'Schlecht';

  @override
  String get guest_reviews_rating_3 => 'Durchschnittlich';

  @override
  String get guest_reviews_rating_4 => 'Gut';

  @override
  String get guest_reviews_rating_5 => 'Ausgezeichnet';

  @override
  String get guest_reviews_title_label => 'Titel (optional)';

  @override
  String get guest_reviews_title_hint =>
      'Fassen Sie Ihre Erfahrung in einem Satz zusammen';

  @override
  String get guest_reviews_comment_required =>
      'Bitte schreiben Sie einen Kommentar';

  @override
  String get guest_reviews_comment_min_length =>
      'Der Kommentar muss mindestens 10 Zeichen lang sein';

  @override
  String get guest_reviews_comment_label => 'Ihr Kommentar *';

  @override
  String get guest_reviews_comment_hint =>
      'Erzählen Sie uns von Ihrer Erfahrung...';

  @override
  String get guest_reviews_save_changes => 'Änderungen speichern';

  @override
  String get guest_reviews_publish_review => 'Bewertung veröffentlichen';

  @override
  String get guest_reviews_select_rating =>
      'Bitte wählen Sie eine Bewertung aus';

  @override
  String get guest_reviews_saving => 'Wird gespeichert...';

  @override
  String get guest_alojamientos_title => 'Unsere Unterkünfte';

  @override
  String get guest_alojamientos_error_title => 'Fehler beim Laden';

  @override
  String get guest_alojamientos_empty_title => 'Keine Unterkünfte';

  @override
  String get guest_alojamientos_empty_subtitle =>
      'Derzeit keine Unterkünfte verfügbar';

  @override
  String guest_alojamientos_room_count(int count) {
    return '$count Zimmer';
  }

  @override
  String get guest_alojamiento_detail_title => 'Details';

  @override
  String get guest_alojamiento_units_available => 'Verfügbare Einheiten';

  @override
  String get guest_alojamiento_no_units => 'Keine Einheiten verfügbar';

  @override
  String get guest_alojamiento_location => 'Lage';

  @override
  String get guest_alojamiento_common_areas => 'Gemeinschaftsbereiche';

  @override
  String get guest_alojamiento_shared_spaces => 'Gemeinschaftsräume';

  @override
  String get guest_alojamiento_common_areas_subtitle =>
      'Genießen Sie die Gemeinschaftsbereiche des Hotels';

  @override
  String get guest_alojamiento_no_photos => 'Keine Fotos';

  @override
  String get guest_alojamiento_no_photos_subtitle =>
      'Keine Fotos der Gemeinschaftsbereiche gefunden';

  @override
  String guest_alojamiento_photos_count(int count) {
    return '$count Fotos';
  }

  @override
  String get guest_alojamiento_hotel_rooms_title => 'Hotel Boutique Jerez';

  @override
  String get guest_alojamiento_no_rooms => 'Keine Zimmer';

  @override
  String get guest_alojamiento_no_rooms_subtitle =>
      'Derzeit keine Zimmer verfügbar';

  @override
  String get guest_alojamiento_rooms => 'Zimmer';

  @override
  String get guest_alojamiento_features => 'Ausstattung';

  @override
  String get guest_alojamiento_feature_flexible_checkin => 'Flexibler Check-in';

  @override
  String get guest_alojamiento_feature_wifi => 'Kostenloses WiFi';

  @override
  String get guest_alojamiento_feature_ac => 'Klimaanlage';

  @override
  String get guest_alojamiento_description => 'Beschreibung';

  @override
  String guest_alojamiento_description_text(String unitType) {
    return 'Entdecken Sie dieses vollständig ausgestattete $unitType, damit Ihr Aufenthalt so komfortabel wie möglich ist. Es hat alles, was Sie brauchen, um Jerez in Ihrem eigenen Tempo zu genießen.';
  }

  @override
  String get guest_alojamiento_services => 'Enthaltene Leistungen';

  @override
  String get guest_alojamiento_service_kitchen => 'Ausgestattete Küche';

  @override
  String get guest_alojamiento_service_washer => 'Waschmaschine';

  @override
  String get guest_alojamiento_service_tv => 'Smart TV';

  @override
  String get guest_alojamiento_service_bedding => 'Bettwäsche';

  @override
  String get guest_alojamiento_service_towels => 'Handtücher';

  @override
  String get guest_alojamiento_service_coffee => 'Kaffeemaschine';

  @override
  String get guest_alojamiento_access_info => 'Zugangsinformationen';

  @override
  String get guest_alojamiento_box_location => 'Standort der Box';

  @override
  String get guest_alojamiento_access_instructions => 'Zugangsanweisungen';

  @override
  String get guest_house_rules_title => 'Hausordnung';

  @override
  String get guest_house_rules_subtitle => 'Regeln und Empfehlungen einsehen';

  @override
  String get guest_house_rules_empty_title => 'Keine Regeln';

  @override
  String get guest_house_rules_empty_subtitle =>
      'Diese Unterkunft hat keine registrierten Regeln';

  @override
  String get guest_normas_title => 'Regeln';

  @override
  String get guest_normas_hotel_title => 'Hotelregeln';

  @override
  String get guest_normas_apartment_title => 'Wohnungsregeln';

  @override
  String get guest_normas_not_available => 'Keine Regeln verfügbar';

  @override
  String get guest_normas_image_error => 'Bild konnte nicht geladen werden';

  @override
  String get guest_normas_generic_error => 'Ein Fehler ist aufgetreten';

  @override
  String get guest_que_ver_title => 'Was besichtigen?';

  @override
  String get guest_que_ver_clear_filters => 'Löschen';

  @override
  String guest_que_ver_places_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Orte',
      one: '1 Ort',
    );
    return '$_temp0';
  }

  @override
  String get guest_que_ver_no_results => 'Keine Ergebnisse';

  @override
  String get guest_que_ver_no_places => 'Keine Orte';

  @override
  String get guest_que_ver_try_filters =>
      'Versuchen Sie, die Suchfilter zu ändern';

  @override
  String get guest_que_ver_coming_soon =>
      'Wir werden bald neue Orte hinzufügen';

  @override
  String get guest_que_ver_error_loading => 'Fehler beim Laden des Ortes';

  @override
  String get guest_que_ver_place_not_found => 'Ort nicht gefunden';

  @override
  String get guest_que_ver_about_place => 'Über diesen Ort';

  @override
  String get guest_que_ver_address => 'Adresse';

  @override
  String get guest_que_ver_best_time => 'Beste Besuchszeit';

  @override
  String get guest_que_ver_location => 'Lage';

  @override
  String get guest_que_ver_practical_info => 'Praktische Informationen';

  @override
  String get guest_que_ver_tips => 'Tipps';

  @override
  String get guest_que_ver_free_entry => 'Kostenloser Eintritt';

  @override
  String get guest_que_ver_how_to_get => 'Anreise';

  @override
  String get guest_que_ver_copy_link => 'Link kopieren';

  @override
  String get guest_que_ver_official_web => 'Offizielle Website';

  @override
  String get guest_que_ver_link_copied => 'Link in die Zwischenablage kopiert';

  @override
  String get guest_reviews_verified => 'Verifiziert';

  @override
  String get guest_reviews_show_less => 'Weniger anzeigen';

  @override
  String get guest_reviews_show_more => 'Mehr anzeigen';

  @override
  String get guest_reviews_empty_title => 'Noch keine Bewertungen';

  @override
  String get guest_reviews_empty_subtitle =>
      'Seien Sie der Erste, der seine Erfahrung teilt';

  @override
  String get guest_reviews_write_first => 'Bewertung schreiben';

  @override
  String guest_reviews_filter_empty_title(String filter) {
    return 'Keine Ergebnisse für $filter';
  }

  @override
  String get guest_reviews_filter_empty_subtitle =>
      'Versuchen Sie, einen anderen Filter auszuwählen';

  @override
  String get guest_reviews_clear_filter => 'Filter löschen';

  @override
  String guest_reviews_count_label(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bewertungen',
      one: '1 Bewertung',
    );
    return '$_temp0';
  }

  @override
  String get guest_reviews_no_reviews_title => 'Noch keine Bewertungen';

  @override
  String get guest_reviews_be_first => 'Seien Sie der Erste';

  @override
  String get guest_access_no_booking => 'Buchung nicht gefunden';

  @override
  String get guest_access_error_loading => 'Fehler beim Laden der Zugangsdaten';

  @override
  String get guest_access_title => 'Zugang';

  @override
  String get guest_access_no_codes => 'Keine Zugangscodes verfügbar';

  @override
  String get guest_access_codes_title => 'Zugangscodes';

  @override
  String get guest_access_codes_subtitle =>
      'Verwenden Sie diese Codes, um auf Ihre Unterkunft zuzugreifen';

  @override
  String get guest_access_main_code => 'Hauptcode';

  @override
  String get guest_access_main_door => 'Haupteingang';

  @override
  String guest_access_valid_period(String from, String until) {
    return 'Gültig von $from bis $until';
  }

  @override
  String get guest_access_wifi_title => 'WiFi';

  @override
  String get guest_access_wifi_network => 'Netzwerk:';

  @override
  String get guest_access_wifi_password => 'Passwort:';

  @override
  String get guest_access_password_copied =>
      'Passwort in die Zwischenablage kopiert';

  @override
  String get guest_access_other_accesses => 'Weitere Zugänge';

  @override
  String get guest_access_instructions => 'Zugangsanweisungen';

  @override
  String get guest_guide_title => 'Aufenthaltsführer';

  @override
  String get guest_guide_subtitle => 'Alle Informationen zu Ihrem Aufenthalt';

  @override
  String get guest_guide_contact => 'Kontakt';

  @override
  String get guest_guide_phone_1 => 'Telefon 1';

  @override
  String get guest_guide_phone_2 => 'Telefon 2';

  @override
  String get guest_guide_your_data => 'Ihre Daten';

  @override
  String get guest_guide_accommodation => 'Unterkunft';

  @override
  String get guest_guide_property => 'Objekt';

  @override
  String get guest_guide_checkin => 'Check-in';

  @override
  String get guest_guide_checkout => 'Check-out';

  @override
  String get guest_guide_guests => 'Gäste';

  @override
  String get guest_guide_services => 'Leistungen';

  @override
  String get guest_guide_wifi => 'WiFi';

  @override
  String get guest_guide_laundry => 'Wäsche';

  @override
  String get guest_guide_laundry_desc => 'Wäscheservice verfügbar';

  @override
  String get guest_guide_jacuzzi => 'Jacuzzi';

  @override
  String get guest_guide_ac => 'Klimaanlage';

  @override
  String get guest_guide_ac_title => 'Klimaanlage';

  @override
  String get guest_guide_ac_desc => 'Klimaregelung in Ihrer Unterkunft';

  @override
  String get guest_guide_tv => 'TV';

  @override
  String get guest_guide_tv_title => 'Fernsehen';

  @override
  String get guest_guide_tv_desc => 'Smart TV mit Kanälen und Apps';

  @override
  String get guest_guide_not_available => 'Nicht verfügbar';

  @override
  String get guest_guide_wifi_desc => 'WiFi-Verbindung inklusive';

  @override
  String get guest_guide_house_rules => 'Hausordnung';

  @override
  String get guest_guide_rule_checkin => 'Check-in ab 16:00 Uhr';

  @override
  String guest_guide_rule_checkout(String time) {
    return 'Check-out vor $time';
  }

  @override
  String get guest_guide_rule_no_smoking => 'Rauchverbot';

  @override
  String get guest_guide_rule_no_parties => 'Partys nicht erlaubt';

  @override
  String get guest_guide_rule_no_pets => 'Haustiere nicht erlaubt';

  @override
  String get guest_notifications_title => 'Benachrichtigungen';

  @override
  String get guest_notifications_delete_all => 'Alle löschen';

  @override
  String get guest_notifications_delete_all_title =>
      'Alle Benachrichtigungen löschen';

  @override
  String get guest_notifications_delete_all_confirm =>
      'Möchten Sie wirklich alle Benachrichtigungen löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String guest_notifications_unread_count(int count) {
    return '$count ungelesen';
  }

  @override
  String get guest_notifications_mark_all => 'Alle als gelesen markieren';

  @override
  String get guest_notifications_empty_title => 'Keine Benachrichtigungen';

  @override
  String get guest_notifications_empty_subtitle =>
      'Benachrichtigungen über Ihren Aufenthalt werden hier angezeigt';

  @override
  String get guest_notifications_read => 'Gelesen';

  @override
  String get guest_romantic_title => 'Romantikpaket';

  @override
  String get guest_romantic_surprise => 'Überraschen Sie Ihren Partner';

  @override
  String get guest_romantic_unforgettable =>
      'Schaffen Sie einen unvergesslichen Moment';

  @override
  String get guest_romantic_includes => 'Was ist enthalten?';

  @override
  String get guest_romantic_decoration_title => 'Romantische Dekoration';

  @override
  String get guest_romantic_decoration_desc =>
      'Rosenblätter, Kerzen und besondere Zimmerdekoration';

  @override
  String get guest_romantic_choose_title => 'Wählen Sie Ihr Detail';

  @override
  String get guest_romantic_choose_desc =>
      'Eine Flasche Cava oder handgemachte Schokolade für den Abend';

  @override
  String get guest_romantic_basic_pack => 'Basis-Romantikpaket';

  @override
  String get guest_romantic_price => '20,00€';

  @override
  String get guest_romantic_book_now => 'Jetzt buchen';

  @override
  String get guest_romantic_customize =>
      'Oder mit Extras bei der Buchung anpassen';

  @override
  String get guest_romantic_redirect =>
      'Sie werden auf die Website weitergeleitet, um die Buchung des Romantikpakets abzuschließen. Fortfahren?';

  @override
  String get guest_romantic_how_to => 'Wie buche ich?';

  @override
  String get guest_romantic_step_1 => 'Romantikpaket auswählen';

  @override
  String get guest_romantic_step_2 => 'Details anpassen';

  @override
  String get guest_romantic_step_3 => 'Buchung online abschließen';

  @override
  String get guest_romantic_step_4 => 'Die Überraschung genießen';

  @override
  String get guest_romantic_note =>
      'Die Dekoration wird während Ihrer Abwesenheit vorbereitet, damit sie eine vollständige Überraschung ist.';

  @override
  String get guest_jacuzzi_title => 'Jacuzzi';

  @override
  String get guest_jacuzzi_rules_title => 'Nutzungsregeln';

  @override
  String get guest_jacuzzi_subtitle => 'Entspannen Sie sich und genießen Sie';

  @override
  String get guest_jacuzzi_power => 'Ein/Aus';

  @override
  String get guest_jacuzzi_power_step_1 =>
      'Drücken Sie die POWER-Taste, um den Jacuzzi einzuschalten';

  @override
  String get guest_jacuzzi_power_step_2 =>
      'Warten Sie, bis das Panel aufleuchtet';

  @override
  String get guest_jacuzzi_power_step_3 =>
      'Wählen Sie die gewünschte Temperatur mit den Tasten + und -';

  @override
  String get guest_jacuzzi_lock => 'Panel-Sperre';

  @override
  String get guest_jacuzzi_lock_step_1 =>
      'Um versehentliche Aktivierungen zu vermeiden, können Sie das Bedienfeld sperren';

  @override
  String get guest_jacuzzi_lock_unlock => 'Entsperren';

  @override
  String get guest_jacuzzi_lock_unlock_step =>
      'Halten Sie die LOCK-Taste 3 Sekunden lang gedrückt';

  @override
  String get guest_jacuzzi_lock_manual => 'Manuelle Sperre';

  @override
  String get guest_jacuzzi_lock_manual_step =>
      'Halten Sie die LOCK-Taste 3 Sekunden lang gedrückt, um sie zu aktivieren';

  @override
  String get guest_jacuzzi_ozone => 'Ozon-Funktion';

  @override
  String get guest_jacuzzi_ozone_intro =>
      'Das Ozonsystem hilft dabei, das Wasser automatisch sauber und desinfiziert zu halten.';

  @override
  String get guest_jacuzzi_ozone_step_1 =>
      'Drücken Sie die OZONE-Taste auf dem Panel';

  @override
  String get guest_jacuzzi_ozone_step_2 => 'Die Kontrollleuchte wird aktiviert';

  @override
  String get guest_jacuzzi_ozone_step_3 => 'Das System läuft 30 Minuten lang';

  @override
  String get guest_jacuzzi_ozone_step_4 =>
      'Es schaltet sich am Ende automatisch ab';

  @override
  String guest_jacuzzi_ozone_note(String note) {
    return 'Hinweis: $note';
  }

  @override
  String get guest_jacuzzi_massage => 'Massagefunktionen';

  @override
  String get guest_jacuzzi_air_jets => 'Luftdüsen';

  @override
  String get guest_jacuzzi_air_step_1 =>
      'Drücken Sie die AIR-Taste, um die Luftdüsen zu aktivieren';

  @override
  String get guest_jacuzzi_air_step_2 =>
      'Stellen Sie die Intensität mit den Tasten + und - ein';

  @override
  String get guest_jacuzzi_air_step_3 =>
      'Die Düsen erzeugen sanfte Blasen im Wasser';

  @override
  String get guest_jacuzzi_air_step_4 => 'Erneut drücken, um zu deaktivieren';

  @override
  String get guest_jacuzzi_water_jets => 'Wasserdüsen';

  @override
  String get guest_jacuzzi_water_step_1 =>
      'Drücken Sie die JET-Taste, um die Wasserdüsen zu aktivieren';

  @override
  String get guest_jacuzzi_water_step_2 =>
      'Die Wasserdüsen bieten eine intensivere Massage';

  @override
  String get guest_jacuzzi_water_step_3 =>
      'Richten Sie die Düsen auf verspannte Muskelzonen';

  @override
  String get guest_jacuzzi_water_step_4 => 'Erneut drücken, um zu deaktivieren';

  @override
  String get guest_jacuzzi_important => 'Wichtig';

  @override
  String get guest_jacuzzi_water_level_info =>
      'Der Wasserstand muss immer über den Düsen liegen, damit das Gerät ordnungsgemäß funktioniert.';

  @override
  String get guest_jacuzzi_low_water_title => 'Wenn der Stand zu niedrig ist:';

  @override
  String get guest_jacuzzi_low_water_stop => 'Jacuzzi sofort stoppen';

  @override
  String get guest_jacuzzi_low_water_icon =>
      'Überprüfen Sie das Warnsymbol auf dem Panel';

  @override
  String get guest_jacuzzi_low_water_resume =>
      'Füllen Sie Wasser nach, bis die Düsen bedeckt sind, bevor Sie fortfahren.';

  @override
  String get guest_jacuzzi_water_responsibility =>
      'Verantwortungsvoller Wasserverbrauch';

  @override
  String get guest_jacuzzi_water_refill_info =>
      'Der Jacuzzi hat ein erhebliches Fassungsvermögen. Bitte nutzen Sie ihn verantwortungsvoll.';

  @override
  String get guest_jacuzzi_capacity => 'Fassungsvermögen:';

  @override
  String get guest_jacuzzi_capacity_liters => '800 Liter';

  @override
  String get guest_jacuzzi_water_regulation =>
      'Das Befüllen und Entleeren des Jacuzzis unterliegt den lokalen Wassernutzungsvorschriften.';

  @override
  String get guest_jacuzzi_thanks =>
      'Vielen Dank für Ihre Mitarbeit beim verantwortungsvollen Wasserverbrauch.';

  @override
  String get guest_physical_registration_title => 'Persönliche Anmeldung';

  @override
  String get guest_physical_registration_header => 'Anmeldung an der Rezeption';

  @override
  String get guest_physical_registration_subtitle =>
      'Schließen Sie Ihre Anmeldung persönlich ab';

  @override
  String get guest_physical_registration_instructions => 'Anweisungen';

  @override
  String get guest_physical_registration_step_1_title => 'Zur Rezeption gehen';

  @override
  String get guest_physical_registration_step_1_desc =>
      'Begeben Sie sich während der Öffnungszeiten zur Rezeption des Hotels';

  @override
  String get guest_physical_registration_step_2_title => 'Dokument vorlegen';

  @override
  String get guest_physical_registration_step_2_desc =>
      'Zeigen Sie Ihr Originalausweis (DNI, Reisepass oder Führerschein)';

  @override
  String get guest_physical_registration_step_3_title =>
      'Anmeldung unterzeichnen';

  @override
  String get guest_physical_registration_step_3_desc =>
      'Unterzeichnen Sie das Eincheckdokument';

  @override
  String get guest_physical_registration_step_4_title => 'Schlüssel erhalten';

  @override
  String get guest_physical_registration_step_4_desc =>
      'Wir übergeben Ihnen den Schlüssel zu Ihrem Zimmer';

  @override
  String get guest_physical_registration_schedule => 'Rezeptionszeiten';

  @override
  String get guest_physical_registration_schedule_hours => 'Öffnungszeiten';

  @override
  String get guest_physical_registration_schedule_days => 'Montag bis Freitag';

  @override
  String get guest_physical_registration_documents => 'Akzeptierte Dokumente';

  @override
  String get guest_physical_registration_doc_dni => 'DNI';

  @override
  String get guest_physical_registration_doc_passport => 'Reisepass';

  @override
  String get guest_physical_registration_doc_license => 'Führerschein';

  @override
  String get guest_checkin_child_no_data =>
      'Unter 14, keine Daten erforderlich';

  @override
  String get guest_checkin_holder => 'Hauptgast';

  @override
  String get guest_checkin_full_name => 'Vollständiger Name';

  @override
  String get guest_checkin_email => 'E-Mail';

  @override
  String get guest_checkin_phone => 'Telefon';

  @override
  String guest_checkin_young(int age) {
    return 'Minderjähriger ($age Jahre alt)';
  }

  @override
  String guest_checkin_adult(int number) {
    return 'Erwachsener $number';
  }

  @override
  String guest_checkin_guest(int number) {
    return 'Gast $number';
  }

  @override
  String get guest_checkin_document_id => 'Ausweisdokument';

  @override
  String get guest_checkin_upload_document => 'Dokument hochladen';

  @override
  String get guest_checkin_document => 'Dokument';

  @override
  String get guest_checkin_missing_photo => 'Dokumentfoto fehlt';

  @override
  String get guest_checkin_upload_document_title => 'Dokument hochladen';

  @override
  String get guest_checkin_document_type => 'Dokumenttyp';

  @override
  String get guest_checkin_document_number => 'Dokumentnummer';

  @override
  String get guest_checkin_document_photo => 'Dokumentfoto';

  @override
  String get guest_checkin_image_captured => 'Bild aufgenommen';

  @override
  String get guest_checkin_tap_to_capture => 'Tippen, um Dokument aufzunehmen';

  @override
  String get guest_checkin_camera_or_gallery => 'Kamera oder Galerie';

  @override
  String get guest_checkin_select_source => 'Quelle auswählen';

  @override
  String get guest_checkin_camera => 'Kamera';

  @override
  String get guest_checkin_gallery => 'Galerie';

  @override
  String get guest_checkin_photo_required => 'Foto erforderlich';

  @override
  String get guest_checkin_confirm => 'Bestätigen';

  @override
  String guest_checkin_capture_error(String error) {
    return 'Fehler beim Aufnehmen des Bildes: $error';
  }

  @override
  String get admin_chat_title => 'Chat';

  @override
  String get admin_chat_online => 'Online';

  @override
  String get admin_chat_delete_conversation => 'Konversation löschen';

  @override
  String get admin_chat_delete_confirm_body =>
      'Möchten Sie diese Konversation wirklich löschen?';

  @override
  String get admin_chat_deleted_success => 'Konversation erfolgreich gelöscht';

  @override
  String admin_chat_error_deleting(String error) {
    return 'Fehler beim Löschen der Konversation: $error';
  }

  @override
  String get admin_checkin_detail_title => 'Check-in Detail';

  @override
  String get admin_checkin_validate => 'Validieren';

  @override
  String get admin_checkin_reject => 'Ablehnen';

  @override
  String get admin_checkin_cancel_booking => 'Buchung stornieren';

  @override
  String get admin_checkin_error_loading => 'Fehler beim Laden';

  @override
  String get admin_checkin_not_found => 'Check-in nicht gefunden';

  @override
  String get admin_checkin_status_pending => 'Ausstehend';

  @override
  String get admin_checkin_status_validated => 'Validiert';

  @override
  String get admin_checkin_status_rejected => 'Abgelehnt';

  @override
  String get admin_checkin_status_cancelled => 'Storniert';

  @override
  String get admin_checkin_status_draft => 'Entwurf';

  @override
  String get admin_checkin_submitted_label => 'Eingereicht:';

  @override
  String get admin_checkin_validated_label => 'Validiert:';

  @override
  String get admin_checkin_rejected_label => 'Abgelehnt:';

  @override
  String get admin_checkin_cancelled_label => 'Storniert:';

  @override
  String get admin_checkin_booking_info => 'Buchungsinformationen';

  @override
  String get admin_checkin_property_label => 'Unterkunft:';

  @override
  String get admin_checkin_units_label => 'Zimmer';

  @override
  String get admin_checkin_unit_label => 'Zimmer';

  @override
  String get admin_checkin_code_label => 'Code:';

  @override
  String get admin_checkin_checkin_date_label => 'Check-in:';

  @override
  String get admin_checkin_checkout_date_label => 'Check-out:';

  @override
  String get admin_checkin_guests_section => 'GÄSTE';

  @override
  String get admin_checkin_primary_badge => 'Hauptgast';

  @override
  String get admin_checkin_na => 'N/A';

  @override
  String get admin_checkin_documents_section => 'DOKUMENTE';

  @override
  String get admin_checkin_unknown_guest => 'Unbekannter Gast';

  @override
  String get admin_checkin_signature_section => 'UNTERSCHRIFT';

  @override
  String get admin_checkin_doc_type_dni => 'DNI';

  @override
  String get admin_checkin_doc_type_nie => 'NIE';

  @override
  String get admin_checkin_doc_type_passport => 'Reisepass';

  @override
  String get admin_checkin_image_load_error => 'Fehler beim Laden des Bildes';

  @override
  String get admin_checkin_validate_title => 'Check-in validieren';

  @override
  String get admin_checkin_validate_message =>
      'Möchten Sie diesen Check-in wirklich validieren?';

  @override
  String get admin_checkin_validated_success =>
      'Check-in erfolgreich validiert';

  @override
  String admin_checkin_error(String error) {
    return 'Fehler: $error';
  }

  @override
  String get admin_checkin_reject_title => 'Check-in ablehnen';

  @override
  String get admin_checkin_reject_message =>
      'Möchten Sie diesen Check-in wirklich ablehnen?';

  @override
  String get admin_checkin_reject_hint => 'Ablehnungsgrund (optional)...';

  @override
  String get admin_checkin_no_reason => 'Kein Grund';

  @override
  String get admin_checkin_rejected_success => 'Check-in erfolgreich abgelehnt';

  @override
  String get admin_checkin_cancel_message =>
      'Möchten Sie diese Buchung wirklich stornieren?';

  @override
  String get admin_checkin_cancel_warning =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get admin_checkin_cancel_reason_label => 'Stornogrund';

  @override
  String get admin_checkin_cancel_reason_hint =>
      'Beschreiben Sie den Stornogrund...';

  @override
  String get admin_checkin_cancelled_success => 'Buchung erfolgreich storniert';

  @override
  String get admin_invoice_generate_pdf => 'PDF erstellen';

  @override
  String get admin_invoice_share => 'Teilen';

  @override
  String get admin_invoice_download => 'Herunterladen';

  @override
  String get admin_invoice_share_title => 'Rechnung teilen';

  @override
  String get admin_invoice_copy_link => 'Link kopieren';

  @override
  String admin_invoice_pdf_saved(String path) {
    return 'PDF gespeichert unter: $path';
  }

  @override
  String get admin_invoice_issue => 'Ausstellen';

  @override
  String get admin_invoice_mark_paid => 'Als bezahlt markieren';

  @override
  String admin_invoice_paid_on(String date) {
    return 'Bezahlt am $date';
  }

  @override
  String admin_invoice_cancelled(String reason) {
    return 'Storniert: $reason';
  }

  @override
  String get admin_invoice_issue_confirm_title => 'Rechnung ausstellen';

  @override
  String admin_invoice_issue_confirm_message(String invoiceNumber) {
    return 'Möchten Sie Rechnung $invoiceNumber wirklich ausstellen?';
  }

  @override
  String get admin_invoice_mark_paid_confirm_title => 'Als bezahlt markieren';

  @override
  String admin_invoice_mark_paid_confirm_message(String total) {
    return 'Bestätigen Sie den Eingang der Zahlung von $total?';
  }

  @override
  String get admin_invoice_confirm_payment => 'Zahlung bestätigen';

  @override
  String get admin_invoice_cancel_confirm_title => 'Rechnung stornieren';

  @override
  String get admin_invoice_cancel_reason_label => 'Stornogrund';

  @override
  String get admin_invoice_cancel_reason_hint =>
      'Beschreiben Sie den Stornogrund...';

  @override
  String get admin_invoice_dont_cancel => 'Nicht stornieren';

  @override
  String get admin_invoice_cancel_invoice => 'Rechnung stornieren';

  @override
  String admin_invoice_error_generate_pdf(String error) {
    return 'Fehler beim Erstellen des PDFs: $error';
  }

  @override
  String admin_invoice_error_share(String error) {
    return 'Fehler beim Teilen: $error';
  }

  @override
  String admin_invoice_error_download(String error) {
    return 'Fehler beim Herunterladen: $error';
  }

  @override
  String get admin_invoice_nif_label => 'NIF/CIF:';

  @override
  String get admin_invoice_label => 'Rechnung';

  @override
  String get admin_invoice_bill_to => 'Rechnungsempfänger';

  @override
  String get admin_invoice_issue_date_label => 'Ausstellungsdatum:';

  @override
  String get admin_invoice_due_date_label => 'Fälligkeitsdatum:';

  @override
  String get admin_invoice_period_label => 'Zeitraum';

  @override
  String get admin_invoice_booking_label => 'Buchung';

  @override
  String get admin_invoice_no_line_items => 'Keine Posten';

  @override
  String get admin_invoice_col_description => 'Beschreibung';

  @override
  String get admin_invoice_col_qty => 'Mge.';

  @override
  String get admin_invoice_col_price => 'Preis';

  @override
  String get admin_invoice_col_total => 'Gesamt';

  @override
  String get admin_invoice_tax_base => 'Steuerbasis';

  @override
  String get admin_invoice_tax_label => 'MwSt.';

  @override
  String get admin_invoice_total_label => 'Gesamt';

  @override
  String get admin_invoice_notes_label => 'Hinweise';

  @override
  String get admin_notifications_title => 'Benachrichtigungen';

  @override
  String get admin_notifications_empty_title => 'Keine Benachrichtigungen';

  @override
  String get admin_notifications_empty_subtitle =>
      'Benachrichtigungen werden hier angezeigt';

  @override
  String get admin_notifications_mark_all_read => 'Alle als gelesen markieren';

  @override
  String get admin_notifications_mark_read => 'Als gelesen markieren';

  @override
  String get admin_notifications_delete_all => 'Alle löschen';

  @override
  String get admin_notifications_delete_all_title =>
      'Alle Benachrichtigungen löschen';

  @override
  String get admin_notifications_delete_all_confirm =>
      'Möchten Sie wirklich alle Benachrichtigungen löschen?';

  @override
  String admin_notifications_unread_count(int count) {
    return '$count ungelesen';
  }

  @override
  String get guest_access_checkin => 'Check-in';

  @override
  String get guest_access_checkout => 'Check-out';

  @override
  String get guest_access_checkout_label => 'Check-out';

  @override
  String guest_access_checkout_until(String time) {
    return 'Bis $time';
  }

  @override
  String get guest_access_checkout_deadline => 'Check-out Frist';

  @override
  String get guest_access_checkout_instructions => 'Check-out Anweisungen';

  @override
  String get guest_access_code_label => 'Code';

  @override
  String guest_access_code_available_at(String date, String time) {
    return 'Verfügbar am $date um $time';
  }

  @override
  String get guest_access_code_provided_by_staff =>
      'Vom Personal bereitgestellt';

  @override
  String get guest_access_locker_code => 'Schließfachcode';

  @override
  String get guest_access_locker_code_label => 'Schließfachcode';

  @override
  String guest_access_locker_available_at(String date) {
    return 'Verfügbar am $date';
  }

  @override
  String get guest_access_key_locker => 'Schlüsselschrank';

  @override
  String get guest_access_door_code => 'Türcode';

  @override
  String get guest_access_building_access => 'Gebäudezugang';

  @override
  String get guest_access_building_instructions =>
      'Anweisungen zum Gebäudezugang';

  @override
  String get guest_access_apartment_access => 'Wohnungszugang';

  @override
  String get guest_access_apartment_instructions =>
      'Anweisungen zum Wohnungszugang';

  @override
  String get guest_access_location => 'Standort';

  @override
  String get guest_access_contact => 'Kontakt';

  @override
  String get guest_access_contact_description =>
      'Kontaktieren Sie uns, wenn Sie Hilfe benötigen';

  @override
  String guest_access_copied(String label) {
    return '$label in die Zwischenablage kopiert';
  }

  @override
  String get guest_access_open_maps => 'In Karten öffnen';

  @override
  String get guest_access_network => 'Netzwerk';

  @override
  String get guest_access_network_name => 'Netzwerkname';

  @override
  String get guest_access_password => 'Passwort';

  @override
  String get guest_access_company_name => 'BF Stay';

  @override
  String get guest_access_house_rules => 'Hausordnung';

  @override
  String get guest_access_rules_warning =>
      'Bitte lesen Sie die Hausordnung vor Ihrer Ankunft';

  @override
  String get guest_access_your_accommodation => 'Ihre Unterkunft';

  @override
  String get guest_access_your_codes => 'Ihre Codes';

  @override
  String get guest_access_guest => 'Gast';

  @override
  String guest_access_welcome_message(String unitName) {
    return 'Willkommen in $unitName';
  }

  @override
  String guest_access_hello(String name) {
    return 'Hallo $name';
  }

  @override
  String guest_access_codes_available_datetime(String date, String time) {
    return 'Verfügbar am $date um $time';
  }

  @override
  String guest_access_codes_available_message(String time) {
    return 'Ihr Code ist ab $time verfügbar';
  }

  @override
  String get guest_access_loading_instructions =>
      'Anweisungen werden geladen...';

  @override
  String get guest_access_cannot_load_instructions =>
      'Anweisungen können nicht geladen werden';

  @override
  String get guest_access_rule_no_parties_title => 'Keine Partys';

  @override
  String get guest_access_rule_no_parties_description =>
      'Partys oder Veranstaltungen sind nicht erlaubt';

  @override
  String get guest_access_rule_no_smoking_title => 'Rauchverbot';

  @override
  String get guest_access_rule_smoke_free_description =>
      'Dies ist eine rauchfreie Unterkunft';

  @override
  String get guest_access_rule_registered_only_title =>
      'Nur registrierte Gäste';

  @override
  String get guest_access_rule_registered_only_description =>
      'Nur registrierte Gäste haben Zutritt';

  @override
  String get guest_accommodation_title => 'Unterkunft';

  @override
  String get guest_accommodation_error_loading => 'Fehler beim Laden';

  @override
  String get guest_accommodation_error_occurred => 'Ein Fehler ist aufgetreten';

  @override
  String get guest_accommodation_no_booking => 'Buchung nicht gefunden';

  @override
  String get guest_accommodation_booking_not_found => 'Buchung nicht gefunden';

  @override
  String get guest_accommodation_no_unit_info =>
      'Keine Informationen zur Einheit verfügbar';

  @override
  String get guest_accommodation_address => 'Adresse';

  @override
  String get guest_accommodation_address_unavailable =>
      'Adresse nicht verfügbar';

  @override
  String get guest_accommodation_box_location => 'Standort der Box';

  @override
  String get guest_accommodation_access_codes => 'Zugangscodes';

  @override
  String get guest_accommodation_access_instructions => 'Zugangsanweisungen';

  @override
  String get guest_accommodation_main_door => 'Haupteingang';

  @override
  String get guest_accommodation_door_code => 'Türcode';

  @override
  String get guest_accommodation_portal_code => 'Portalcode';

  @override
  String get guest_accommodation_key_box_code => 'Schlüsselboxcode';

  @override
  String get guest_accommodation_keybox_description =>
      'Code für die Schlüsselbox';

  @override
  String get guest_accommodation_wifi_password => 'WiFi-Passwort';

  @override
  String guest_accommodation_rooms_count(int count) {
    return '$count Zimmer';
  }

  @override
  String get guest_accommodation_hotel_rules => 'Hotelregeln';

  @override
  String get guest_accommodation_apartment_rules => 'Wohnungsregeln';

  @override
  String get guest_accommodation_rules_description =>
      'Überprüfen Sie die Regeln Ihrer Unterkunft';

  @override
  String guest_accommodation_rules_load_error(String error) {
    return 'Fehler beim Laden der Regeln: $error';
  }

  @override
  String guest_accommodation_codes_available_datetime(
    String date,
    String time,
  ) {
    return 'Verfügbar am $date um $time';
  }

  @override
  String guest_accommodation_codes_available_message(String time) {
    return 'Ihre Codes sind verfügbar, wenn Ihr Aufenthalt beginnt ($time)';
  }

  @override
  String guest_accommodation_file_not_found(String message) {
    return 'Datei nicht gefunden: $message';
  }

  @override
  String get guest_accommodation_cannot_open_document =>
      'Dokument kann nicht geöffnet werden';

  @override
  String get guest_accommodation_tap_for_access_info =>
      'Tippen für Zugangsinformationen';

  @override
  String get guest_chat_default_title => 'Chat';

  @override
  String get guest_chat_online => 'Online';

  @override
  String get guest_chat_start_conversation => 'Gespräch starten';

  @override
  String get guest_chat_welcome_message =>
      'Hallo! Wie können wir Ihnen helfen?';

  @override
  String get guest_checkin_label => 'Check-in';

  @override
  String get guest_checkin_back => 'Zurück';

  @override
  String get guest_checkin_continue => 'Weiter';

  @override
  String get guest_checkin_complete => 'Abschließen';

  @override
  String get guest_checkin_loading_booking => 'Buchungsdaten werden geladen...';

  @override
  String get guest_checkin_error_loading => 'Fehler beim Laden';

  @override
  String get guest_checkin_booking => 'Buchung';

  @override
  String get guest_checkin_code => 'Code';

  @override
  String get guest_checkin_guests_label => 'Gäste';

  @override
  String guest_checkin_guests_count(int count) {
    return '$count Gäste';
  }

  @override
  String guest_checkin_guests_registered(int count) {
    return '$count registriert';
  }

  @override
  String guest_checkin_guests_summary(int count) {
    return '$count Gäste';
  }

  @override
  String get guest_checkin_guest_data => 'Gastdaten';

  @override
  String get guest_checkin_guest_data_description =>
      'Füllen Sie die Daten für alle Gäste aus';

  @override
  String get guest_checkin_holder_badge => 'HAUPTGAST';

  @override
  String get guest_checkin_holder_signature => 'Unterschrift des Hauptgastes';

  @override
  String get guest_checkin_no_name => 'Kein Name';

  @override
  String get guest_checkin_guest_no_name => 'Gast ohne Namen';

  @override
  String guest_checkin_adults_children(int adults, int children) {
    return '$adults Erwachsene und $children Minderjährige';
  }

  @override
  String get guest_checkin_minor_badge => 'MINDERJÄHRIG';

  @override
  String guest_checkin_young_document_required(int age) {
    return 'Unter $age, Dokument erforderlich';
  }

  @override
  String get guest_checkin_document_required => 'Dokument erforderlich';

  @override
  String get guest_checkin_upload => 'Hochladen';

  @override
  String guest_checkin_documents_uploaded(int completed, int total) {
    return '$completed von $total Dokumenten hochgeladen';
  }

  @override
  String get guest_checkin_all_documents_uploaded =>
      'Alle Dokumente hochgeladen';

  @override
  String get guest_checkin_upload_documents_description =>
      'Laden Sie Fotos der Ausweisdokumente für alle Gäste hoch';

  @override
  String get guest_checkin_uploaded_documents => 'Hochgeladene Dokumente';

  @override
  String get guest_checkin_pending_documents => 'Ausstehende Dokumente';

  @override
  String get guest_checkin_identity_documents => 'Ausweisdokumente';

  @override
  String get guest_checkin_signature_description =>
      'Unterschrift des Hauptgastes der Buchung';

  @override
  String get guest_checkin_signature_pending => 'Unterschrift ausstehend';

  @override
  String get guest_checkin_signature_captured => 'Unterschrift erfasst';

  @override
  String get guest_checkin_signature_captured_short => 'Unterschrift';

  @override
  String get guest_checkin_clear_signature => 'Unterschrift löschen';

  @override
  String get guest_checkin_step_guests => 'Gäste';

  @override
  String get guest_checkin_step_documents => 'Dokumente';

  @override
  String get guest_checkin_step_signature => 'Unterschrift';

  @override
  String get guest_checkin_step_confirm => 'Bestätigen';

  @override
  String get guest_checkin_online => 'Online';

  @override
  String get guest_checkin_pending => 'Ausstehend';

  @override
  String get guest_checkin_validated => 'Validiert';

  @override
  String get guest_checkin_waiting_validation => 'Warten auf Validierung';

  @override
  String get guest_checkin_completed => 'Abgeschlossen';

  @override
  String get guest_checkin_completed_success =>
      'Check-in erfolgreich abgeschlossen';

  @override
  String get guest_checkin_sending => 'Wird gesendet...';

  @override
  String get guest_checkin_progress => 'Check-in Fortschritt';

  @override
  String get guest_checkin_confirmation => 'Check-in Bestätigung';

  @override
  String get guest_checkin_confirmation_description =>
      'Ihr Check-in wurde gesendet. Sie müssen nun warten, bis die Unterkunft ihn validiert.';

  @override
  String get guest_checkin_legal_notice => 'Rechtlicher Hinweis';

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
    return '$count Nächte';
  }

  @override
  String guest_checkout_guests_count(int count) {
    return '$count Gäste';
  }

  @override
  String get guest_checkout_stay_summary => 'Aufenthaltsübersicht';

  @override
  String get guest_checkout_confirm => 'Bestätigen';

  @override
  String get guest_checkout_confirm_button => 'Check-out bestätigen';

  @override
  String get guest_checkout_confirm_dialog_title => 'Check-out bestätigen?';

  @override
  String get guest_checkout_confirm_dialog_message =>
      'Sie sind dabei, Ihren Check-out zu bestätigen. Möchten Sie fortfahren?';

  @override
  String get guest_checkout_confirm_info => 'Check-out wird bestätigt...';

  @override
  String get guest_checkout_processing => 'Wird verarbeitet...';

  @override
  String get guest_checkout_completed => 'Check-out abgeschlossen';

  @override
  String get guest_checkout_thank_you => 'Vielen Dank für Ihren Aufenthalt!';

  @override
  String get guest_checkout_feedback_title => 'Ihre Meinung ist wichtig';

  @override
  String get guest_checkout_feedback_hint =>
      'Erzählen Sie uns von Ihrer Erfahrung...';

  @override
  String get guest_checkout_rating_title => 'Bewerten Sie Ihren Aufenthalt';

  @override
  String get guest_checkout_review_description =>
      'Ihre Meinung hilft anderen Reisenden';

  @override
  String get guest_checkout_loading => 'Wird geladen...';

  @override
  String get guest_checkout_error_loading => 'Fehler beim Laden';

  @override
  String get guest_checkout_already_done => 'Check-out bereits erfolgt';

  @override
  String get guest_checkout_already_done_message =>
      'Sie haben bereits ausgecheckt. Vielen Dank!';

  @override
  String get guest_home_welcome => 'Willkommen';

  @override
  String get guest_home_welcome_stay => 'Willkommen zu Ihrem Aufenthalt';

  @override
  String guest_home_hello_name(String name) {
    return 'Hallo, $name';
  }

  @override
  String get guest_home_your_stay => 'Ihr Aufenthalt';

  @override
  String get guest_home_no_booking => 'Keine Buchungen';

  @override
  String get guest_home_not_authenticated => 'Nicht angemeldet';

  @override
  String get guest_home_stay_active_enjoy =>
      'Ihr Aufenthalt ist aktiv. Genießen Sie ihn!';

  @override
  String get guest_home_quick_actions => 'Schnellaktionen';

  @override
  String get guest_home_checkin => 'Check-in';

  @override
  String get guest_home_checkout => 'Check-out';

  @override
  String get guest_home_chat => 'Chat';

  @override
  String get guest_home_guide => 'Führer';

  @override
  String get guest_home_rules => 'Regeln';

  @override
  String get guest_home_parkings => 'Parkplatz';

  @override
  String get guest_home_accommodations => 'Unterkünfte';

  @override
  String get guest_home_accommodation => 'Unterkunft';

  @override
  String guest_home_rooms_count(int count) {
    return '$count Zimmer';
  }

  @override
  String get guest_home_guests => 'Gäste';

  @override
  String guest_home_nights(int count) {
    return '$count Nächte';
  }

  @override
  String get guest_home_what_to_see => 'Was besichtigen';

  @override
  String get guest_home_instructions => 'Anweisungen';

  @override
  String get guest_home_my_accommodation => 'Meine Unterkunft';

  @override
  String get guest_home_booking_cancelled => 'Buchung storniert';

  @override
  String get guest_home_booking_cancelled_message =>
      'Ihre Buchung wurde storniert. Bitte kontaktieren Sie die Rezeption.';

  @override
  String get guest_home_cancellation_reason => 'Stornogrund';

  @override
  String get guest_home_checkin_pending => 'Check-in ausstehend';

  @override
  String get guest_home_checkin_sent_waiting =>
      'Check-in gesendet, warte auf Validierung';

  @override
  String get guest_home_checkin_rejected => 'Check-in abgelehnt';

  @override
  String get guest_home_rejection_reason => 'Ablehnungsgrund';

  @override
  String get guest_home_pending_validation => 'Validierung ausstehend';

  @override
  String get guest_home_complete_checkin_access =>
      'Check-in abschließen, um Zugang zu erhalten';

  @override
  String get guest_home_contact_reception => 'Rezeption kontaktieren';

  @override
  String get guest_home_correct_errors_resend =>
      'Fehler korrigieren und erneut senden';

  @override
  String get guest_home_physical_registration => 'Persönliche Anmeldung';

  @override
  String get guest_home_romantic_pack => 'Romantikpaket';

  @override
  String guest_jacuzzi_note(String note) {
    return 'Hinweis: $note';
  }

  @override
  String get public_services_title => 'Unsere Leistungen';

  @override
  String get public_service_rules_title => 'Hausordnung';

  @override
  String get public_service_rules_desc => 'Regeln und Empfehlungen.';

  @override
  String public_copyright(int year) {
    return '© $year BF Stay • Alle Rechte vorbehalten';
  }

  @override
  String get public_access_booking => 'Auf meine Buchung zugreifen';

  @override
  String staff_dashboard_greeting(String name) {
    return 'Hallo $name';
  }

  @override
  String get staff_dashboard_control_panel => 'Kontrollpanel';

  @override
  String get staff_dashboard_daily_summary => 'Tageszusammenfassung';

  @override
  String get staff_dashboard_occupancy => 'Auslastung';

  @override
  String get staff_dashboard_pending => 'Ausstehend';

  @override
  String get staff_dashboard_pending_checkin => 'Ausstehende Check-ins';

  @override
  String get staff_dashboard_pending_checkout => 'Ausstehende Check-outs';

  @override
  String get staff_dashboard_pending_tasks => 'Ausstehende Aufgaben';

  @override
  String get staff_dashboard_checkins_today => 'Heutige Check-ins';

  @override
  String get staff_dashboard_checkouts_today => 'Heutige Check-outs';

  @override
  String get staff_dashboard_quick_actions => 'Schnellaktionen';

  @override
  String get staff_dashboard_manage_checkins => 'Check-ins verwalten';

  @override
  String get staff_dashboard_view_guests => 'Gäste anzeigen';

  @override
  String staff_dashboard_room_extras(String room) {
    return 'Zimmer $room - Extras';
  }

  @override
  String get staff_dashboard_cleaning_request => 'Reinigungsanforderung';

  @override
  String staff_dashboard_room_guest(String room, String guest) {
    return 'Zimmer $room - $guest';
  }

  @override
  String get staff_dashboard_generate_report => 'Bericht erstellen';

  @override
  String get staff_checkins_title => 'Check-ins';

  @override
  String get staff_checkins_tab_pending => 'Ausstehend';

  @override
  String get staff_checkins_tab_in_progress => 'In Bearbeitung';

  @override
  String get staff_checkins_tab_completed => 'Abgeschlossen';

  @override
  String get staff_checkins_status_pending => 'Ausstehend';

  @override
  String get staff_checkins_status_in_progress => 'In Bearbeitung';

  @override
  String get staff_checkins_status_completed => 'Abgeschlossen';

  @override
  String get staff_checkins_start => 'Starten';

  @override
  String get staff_checkins_new_checkin => 'Neuer Check-in';

  @override
  String get staff_checkins_complete => 'Abschließen';

  @override
  String get staff_checkins_view_details => 'Details anzeigen';

  @override
  String get guest_access_wifi_password_label => 'WiFi-Passwort';

  @override
  String get guest_access_locker_provided_by_staff =>
      'Vom Personal bereitgestellt';

  @override
  String get guest_access_rule_smoke_free_title => 'Rauchverbot';

  @override
  String get guest_accommodation_view_rules_pdf => 'Regeln als PDF anzeigen';

  @override
  String get public_hero_title_line1 => 'Dein Aufenthalt,';

  @override
  String get public_hero_title_line2 => 'Erhöht';

  @override
  String get admin_booking_send_whatsapp_title => 'Code per WhatsApp senden';

  @override
  String get admin_booking_send_whatsapp_no_phone =>
      'Gast hat keine Telefonnummer';

  @override
  String get admin_booking_send_whatsapp_no_phone_desc =>
      'Geben Sie eine Telefonnummer ein, um den Code per WhatsApp zu senden.';

  @override
  String get admin_booking_send_whatsapp_phone_hint => '+49 170 000 000';

  @override
  String get admin_booking_send_whatsapp_error =>
      'WhatsApp konnte nicht geöffnet werden';

  @override
  String admin_booking_send_whatsapp_message(
    String propertyName,
    String bookingCode,
    String checkIn,
    String checkOut,
  ) {
    return '🏠 *$propertyName*\n📋 Buchung: *$bookingCode*\n📅 Check-in: $checkIn\n📅 Check-out: $checkOut\n\nLaden Sie die BF Stay App herunter, um Ihren Aufenthalt zu verwalten.';
  }
}
