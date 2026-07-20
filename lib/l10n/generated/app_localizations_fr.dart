// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get guest_romantic_request_sent =>
      'Nous avons prévenu l\'hébergement. Ils vous contacteront pour confirmer les détails.';

  @override
  String get guest_romantic_request_error =>
      'Impossible d\'enregistrer votre demande. Veuillez réessayer.';

  @override
  String get common_app_name => 'BF Stay';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_exit => 'Quitter';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_accept => 'Accepter';

  @override
  String get common_continue => 'Continuer';

  @override
  String get common_back => 'Retour';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error => 'Erreur';

  @override
  String get common_success => 'Succès';

  @override
  String get common_no_data => 'Aucune donnée';

  @override
  String get common_yes => 'Oui';

  @override
  String get common_no => 'Non';

  @override
  String get common_send => 'Envoyer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_search => 'Rechercher';

  @override
  String get common_later => 'Plus tard';

  @override
  String get common_update => 'Mettre à jour';

  @override
  String get common_understood => 'Compris';

  @override
  String get common_exit_app_title => 'Quitter BF Stay';

  @override
  String get common_exit_app_message =>
      'Êtes-vous sûr de vouloir quitter l\'application ?\n\nVotre session restera active à votre retour.';

  @override
  String get common_logout_title => 'Se déconnecter';

  @override
  String get common_logout_message =>
      'Êtes-vous sûr de vouloir vous déconnecter ?\n\nVous pouvez vous reconnecter avec votre code de réservation à tout moment.';

  @override
  String get common_logout_button => 'Se déconnecter';

  @override
  String get common_splash_ready => 'Prêt';

  @override
  String get common_splash_loading => 'Chargement...';

  @override
  String get common_update_force_title => 'Mise à jour requise';

  @override
  String get common_update_available_title => 'Nouvelle version disponible';

  @override
  String get common_update_force_message =>
      'Vous devez mettre à jour l\'application pour continuer à l\'utiliser. Cette version inclut des améliorations importantes et des correctifs de sécurité.';

  @override
  String get common_update_available_message =>
      'Une nouvelle version est disponible avec des améliorations et des correctifs. Souhaitez-vous mettre à jour maintenant ?';

  @override
  String common_update_version(String version) {
    return 'Version $version';
  }

  @override
  String get common_page_not_found => 'Page non trouvée';

  @override
  String get common_invalid_route => 'Route invalide';

  @override
  String get common_back_to_home => 'Retour à l\'accueil';

  @override
  String get common_theme_light => 'Clair';

  @override
  String get common_theme_dark => 'Sombre';

  @override
  String get common_theme_mode_light => 'Mode clair';

  @override
  String get common_theme_mode_dark => 'Mode sombre';

  @override
  String get common_theme_system => 'Système';

  @override
  String get common_theme_app_label => 'Thème de l\'application';

  @override
  String common_copied_to_clipboard(String type) {
    return '$type copié dans le presse-papiers';
  }

  @override
  String get common_phone_type => 'Téléphone';

  @override
  String get common_email_type => 'Email';

  @override
  String get enum_booking_status_created => 'Créée';

  @override
  String get enum_booking_status_confirmed => 'Confirmée';

  @override
  String get enum_booking_status_active => 'Active';

  @override
  String get enum_booking_status_in_house => 'En maison';

  @override
  String get enum_booking_status_checked_out => 'Parti';

  @override
  String get enum_booking_status_closed => 'Fermée';

  @override
  String get enum_booking_status_cancelled => 'Annulée';

  @override
  String get enum_booking_status_created_desc =>
      'Réservation créée, en attente de confirmation';

  @override
  String get enum_booking_status_confirmed_desc =>
      'Réservation confirmée, en attente du check-in';

  @override
  String get enum_booking_status_active_desc =>
      'Check-in validé, panneau complet accessible';

  @override
  String get enum_booking_status_in_house_desc =>
      'Client physiquement sur place';

  @override
  String get enum_booking_status_checked_in_legacy_desc =>
      'Check-in validé (legacy)';

  @override
  String get enum_booking_status_checked_out_desc =>
      'Check-out effectué, le client est parti';

  @override
  String get enum_booking_status_closed_desc =>
      'Réservation terminée et fermée';

  @override
  String get enum_booking_status_cancelled_desc => 'Réservation annulée';

  @override
  String get enum_checkin_status_not_started => 'En attente';

  @override
  String get enum_checkin_status_in_progress => 'En cours';

  @override
  String get enum_checkin_status_submitted => 'Soumis';

  @override
  String get enum_checkin_status_validated => 'Validé';

  @override
  String get enum_checkin_status_rejected => 'Rejeté';

  @override
  String get enum_checkin_status_cancelled => 'Annulé';

  @override
  String get enum_checkin_status_not_started_desc =>
      'Le client n\'a pas encore commencé le check-in';

  @override
  String get enum_checkin_status_in_progress_desc =>
      'Le client est en train de remplir ses informations';

  @override
  String get enum_checkin_status_submitted_desc =>
      'En attente de vérification par l\'administrateur';

  @override
  String get enum_checkin_status_validated_desc =>
      'Check-in validé, séjour autorisé';

  @override
  String get enum_checkin_status_rejected_desc =>
      'Nécessite une correction par le client';

  @override
  String get enum_checkin_status_cancelled_desc =>
      'Réservation annulée, veuillez contacter la réception';

  @override
  String get enum_checkout_status_not_started => 'Non commencé';

  @override
  String get enum_checkout_status_requested => 'Demandé';

  @override
  String get enum_checkout_status_validated => 'Validé';

  @override
  String get enum_checkout_status_rejected => 'Rejeté';

  @override
  String get enum_checkout_status_not_started_desc =>
      'Le séjour est toujours en cours';

  @override
  String get enum_checkout_status_requested_desc =>
      'Le client a demandé le check-out';

  @override
  String get enum_checkout_status_validated_desc =>
      'Check-out validé, réservation prête à fermer';

  @override
  String get enum_checkout_status_rejected_desc =>
      'Il y a des problèmes à résoudre';

  @override
  String get public_badge_exclusivity => 'EXCLUSIVITÉ GARANTIE';

  @override
  String get public_hero_title_prefix => 'Votre séjour, ';

  @override
  String get public_hero_title_suffix => 'Élevé';

  @override
  String get public_cta_access_booking => 'Accéder à ma réservation';

  @override
  String get public_services_section_title => 'Nos Services';

  @override
  String get public_footer_brand_name => 'BF STAY';

  @override
  String public_footer_copyright(int year) {
    return '© $year BF Stay • Tous droits réservés';
  }

  @override
  String get public_footer_privacy_policy => 'Politique de confidentialité';

  @override
  String get public_service_checkin_title => 'Enregistrement numérique';

  @override
  String get public_service_checkin_desc => 'Enregistrement sans attente.';

  @override
  String get public_service_checkout_title => 'Départ numérique';

  @override
  String get public_service_checkout_desc => 'Départ rapide.';

  @override
  String get public_service_house_rules_title => 'Règlement intérieur';

  @override
  String get public_service_house_rules_desc => 'Règles et recommandations.';

  @override
  String get public_service_what_to_see_title => 'Que visiter?';

  @override
  String get public_service_what_to_see_desc =>
      'Points d\'intérêt à proximité.';

  @override
  String get public_service_parking_title => 'Parkings';

  @override
  String get public_service_parking_desc => 'Options de stationnement.';

  @override
  String get public_service_chat_title => 'Chat';

  @override
  String get public_service_chat_desc => 'Conciergerie virtuelle 24h/24.';

  @override
  String get public_service_accommodations_title => 'Hébergements';

  @override
  String get public_service_accommodations_desc => 'Autres propriétés.';

  @override
  String get public_service_reviews_title => 'Avis';

  @override
  String get public_service_reviews_desc => 'Avis des clients.';

  @override
  String get public_service_parking_title_light => 'Parkings à proximité';

  @override
  String get public_service_accommodations_title_light => 'Nos hébergements';

  @override
  String get public_service_accommodations_desc_light =>
      'Autres propriétés disponibles.';

  @override
  String get public_service_reviews_title_light => 'Avis et commentaires';

  @override
  String get public_hero_subtitle =>
      'Gestion intelligente pour hébergements exclusifs.';

  @override
  String get auth_login_brand_name => 'BF Stay';

  @override
  String get auth_login_subtitle => 'Panneau de contrôle';

  @override
  String get auth_feature_bookings => 'Gestion des réservations';

  @override
  String get auth_feature_checkin => 'Check-in numérique';

  @override
  String get auth_feature_chat => 'Chat avec les clients';

  @override
  String get auth_feature_keyless => 'Accès sans clé';

  @override
  String get auth_field_email => 'Email';

  @override
  String get auth_field_password => 'Mot de passe';

  @override
  String get auth_validation_email_required => 'Veuillez saisir votre email';

  @override
  String get auth_validation_email_invalid => 'Veuillez saisir un email valide';

  @override
  String get auth_validation_password_required =>
      'Veuillez saisir votre mot de passe';

  @override
  String get auth_validation_password_min_length =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get auth_forgot_password => 'Mot de passe oublié ?';

  @override
  String get auth_login_button => 'Se connecter';

  @override
  String get auth_divider_or => 'ou';

  @override
  String get auth_guest_access_button => 'Accéder avec un code de réservation';

  @override
  String get auth_login_footer => 'BF Stay © 2026';

  @override
  String get auth_recover_password_title => 'Récupérer le mot de passe';

  @override
  String get auth_recover_password_body =>
      'Saisissez votre email et nous vous enverrons les instructions pour réinitialiser votre mot de passe.';

  @override
  String get auth_recover_password_sent => 'Email de récupération envoyé';

  @override
  String get auth_button_send => 'Envoyer';

  @override
  String get auth_booking_access_title => 'Accès client';

  @override
  String get auth_booking_benefit_code => 'Code de réservation';

  @override
  String get auth_booking_benefit_personal => 'Accès personnalisé';

  @override
  String get auth_booking_benefit_instant => 'Accès instantané';

  @override
  String get auth_booking_benefit_secure_checkin => 'Check-in sécurisé';

  @override
  String get auth_booking_code_info_short =>
      'Vous avez reçu votre code de réservation dans l\'email de confirmation.';

  @override
  String get auth_booking_code_info_full =>
      'Vous avez reçu votre code de réservation dans l\'email de confirmation de réservation.';

  @override
  String get auth_booking_desktop_subtitle =>
      'Profitez de votre séjour avec un accès numérique';

  @override
  String get auth_booking_form_subtitle =>
      'Saisissez votre code de réservation pour accéder à votre hébergement';

  @override
  String get auth_booking_field_code => 'Code de réservation';

  @override
  String get auth_booking_code_hint => 'XX-XXXX-XXXX';

  @override
  String get auth_booking_validation_code_required =>
      'Veuillez saisir votre code de réservation';

  @override
  String get auth_booking_validation_code_invalid =>
      'Le format du code n\'est pas valide';

  @override
  String get auth_booking_access_button => 'Accéder';

  @override
  String get auth_booking_help_title => 'Où trouver mon code ?';

  @override
  String get auth_booking_help_body =>
      'Vous avez reçu votre code de réservation dans l\'email de confirmation de réservation. Il a le format BF-XXXXX.';

  @override
  String get auth_booking_footer => 'BF Stay © 2026';

  @override
  String get auth_booking_error_title => 'Erreur d\'accès';

  @override
  String get auth_booking_error_code_not_found =>
      'Le code de réservation n\'existe pas. Veuillez vérifier que vous l\'avez saisi correctement.';

  @override
  String get auth_booking_error_code_expired =>
      'Ce code de réservation a expiré. Contactez la réception pour en obtenir un nouveau.';

  @override
  String get auth_booking_error_email_mismatch =>
      'L\'email ne correspond pas à la réservation. Assurez-vous que c\'est le même email que vous avez utilisé lors de la réservation.';

  @override
  String get auth_booking_error_generic =>
      'Impossible de vérifier le code de réservation. Veuillez réessayer.';

  @override
  String get auth_booking_error_dismiss => 'Compris';

  @override
  String get auth_sheet_title => 'Accéder à votre réservation';

  @override
  String get auth_sheet_subtitle =>
      'Saisissez votre email et le code que vous avez reçu';

  @override
  String get auth_sheet_label_email => 'EMAIL';

  @override
  String get auth_sheet_hint_email => 'vous@email.com';

  @override
  String get auth_sheet_label_code => 'CODE DE RÉSERVATION';

  @override
  String get auth_sheet_hint_code => 'BF-XXXX-XXXX';

  @override
  String get auth_sheet_submit_button => 'Accéder à ma réservation';

  @override
  String get auth_sheet_help_text =>
      'Vous n\'avez pas votre code ? Contactez votre hébergement';

  @override
  String get auth_admin_sheet_title => 'Accès privé';

  @override
  String get auth_admin_sheet_subtitle =>
      'Réservé au personnel autorisé BF-Stay';

  @override
  String get auth_admin_label_email => 'EMAIL';

  @override
  String get auth_admin_hint_email => 'admin@bfstay.com';

  @override
  String get auth_admin_label_password => 'MOT DE PASSE';

  @override
  String get auth_admin_hint_password => '••••••••';

  @override
  String get auth_admin_error_unauthorized =>
      'Vous n\'avez pas accès à ce panneau';

  @override
  String get auth_admin_submit_button => 'Accéder au panneau';

  @override
  String get guest_settings_title => 'Paramètres';

  @override
  String get guest_settings_section_language => 'Langue';

  @override
  String get guest_settings_language_title => 'Langue de l\'application';

  @override
  String get guest_settings_language_subtitle =>
      'Sélectionnez la langue de l\'interface';

  @override
  String get guest_settings_section_legal => 'Mentions légales';

  @override
  String get guest_settings_privacy_policy_title =>
      'Politique de confidentialité';

  @override
  String get guest_settings_privacy_policy_subtitle =>
      'Consulter notre politique de confidentialité';

  @override
  String get guest_settings_privacy_open_error =>
      'Impossible d\'ouvrir la politique de confidentialité';

  @override
  String get notification_channel_name => 'Notifications BF Stay';

  @override
  String get notification_channel_description =>
      'Canal de notifications BF Stay';

  @override
  String get notification_checkin_validated_title => '✅ Check-in Validé';

  @override
  String get notification_checkin_validated_body =>
      'Votre check-in a été validé avec succès. Bienvenue !';

  @override
  String get notification_checkin_rejected_title => '❌ Check-in Rejeté';

  @override
  String get notification_checkin_rejected_body =>
      'Votre check-in a été rejeté. Veuillez vérifier votre documentation.';

  @override
  String notification_checkin_rejected_body_with_reason(String reason) {
    return 'Votre check-in a été rejeté : $reason';
  }

  @override
  String get notification_booking_cancelled_title => '🚫 Réservation Annulée';

  @override
  String get notification_booking_cancelled_body =>
      'Votre réservation a été annulée. Contactez la réception.';

  @override
  String notification_booking_cancelled_body_with_reason(String reason) {
    return 'Votre réservation a été annulée : $reason';
  }

  @override
  String get notification_checkin_status_update_title =>
      '📋 Mise à jour du Check-in';

  @override
  String notification_checkin_status_update_body(String status) {
    return 'Le statut de votre check-in a changé en : $status';
  }

  @override
  String get notification_admin_checkin_submitted_title =>
      '📝 Nouveau Check-in en attente';

  @override
  String notification_admin_checkin_submitted_body(
    String guestName,
    String unitName,
  ) {
    return '$guestName a soumis son check-in pour $unitName. En attente de vérification.';
  }

  @override
  String get guest_parking_title => 'Parking';

  @override
  String get guest_parking_available_singular => 'parking disponible';

  @override
  String get guest_parking_available_plural => 'parkings disponibles';

  @override
  String get guest_parking_error_loading => 'Erreur de chargement';

  @override
  String get guest_parking_empty_title => 'Aucun parking';

  @override
  String get guest_parking_empty_subtitle =>
      'Nous ajouterons bientôt des informations sur les parkings à proximité';

  @override
  String guest_parking_for_unit(String unitName) {
    return 'Parking pour $unitName';
  }

  @override
  String guest_parking_gps_label(String label) {
    return 'GPS : $label';
  }

  @override
  String get guest_parking_info_zones_title =>
      'INFORMATIONS SUR LES ZONES DE STATIONNEMENT';

  @override
  String get guest_parking_plaza_arenal_title => 'PARKING PLAZA ARENAL';

  @override
  String get guest_parking_plaza_arenal_subtitle =>
      'À environ 5 minutes à pied';

  @override
  String get guest_parking_plaza_arenal_content =>
      '• Paiement via l\'application El Parking : 6,95 €/24h\n• Réservation sur leur site web : 8 €/24h (minimum 24h)\n• Paiement au distributeur : 16 €/24h';

  @override
  String get guest_parking_centro_title => 'PARKING CENTRE-VILLE';

  @override
  String get guest_parking_centro_subtitle => 'ZONE BLEUE O.R.A';

  @override
  String get guest_parking_centro_content =>
      '• Lundi au vendredi : 9:00 - 13:30 et 17:00 - 20:00\n• Samedi : 9:00 - 14:00\n• Juillet et août : 9:00 - 14:00';

  @override
  String get guest_parking_free_zone_title => 'ZONE DE STATIONNEMENT GRATUIT';

  @override
  String get guest_parking_free_zone_subtitle => 'À environ 10 minutes à pied';

  @override
  String get guest_parking_free_zone_content =>
      'Zone de stationnement tournant gratuit.';

  @override
  String get guest_checkin_camera_not_available => 'Aucune caméra disponible';

  @override
  String guest_checkin_camera_init_error(String error) {
    return 'Erreur d\'initialisation de la caméra : $error';
  }

  @override
  String guest_checkin_camera_capture_error(String error) {
    return 'Erreur de capture : $error';
  }

  @override
  String get guest_checkin_camera_scan_title => 'Scanner le document';

  @override
  String get guest_checkin_camera_starting => 'Démarrage de la caméra...';

  @override
  String get guest_checkin_camera_frame_hint =>
      'Cadrez le document dans le cadre';

  @override
  String get guest_checkin_camera_document_label => 'Document d\'identité';

  @override
  String get admin_chat_messages => 'Messages';

  @override
  String get admin_chat_conversation_deleted => 'Conversation supprimée';

  @override
  String get admin_chat_empty_title => 'Aucune conversation';

  @override
  String get admin_chat_empty_subtitle =>
      'Les conversations avec les clients\napparaîtront ici';

  @override
  String get guest_chat_input_hint => 'Écrire un message...';

  @override
  String get admin_booking_detail_title => 'Détail de la réservation';

  @override
  String get admin_booking_not_found => 'Réservation non trouvée';

  @override
  String admin_booking_error(String error) {
    return 'Erreur : $error';
  }

  @override
  String admin_booking_error_validating(String error) {
    return 'Erreur lors de la validation : $error';
  }

  @override
  String admin_booking_error_rejecting(String error) {
    return 'Erreur lors du rejet : $error';
  }

  @override
  String admin_booking_error_validating_checkout(String error) {
    return 'Erreur lors de la validation du check-out : $error';
  }

  @override
  String admin_booking_error_rejecting_checkout(String error) {
    return 'Erreur lors du rejet du check-out : $error';
  }

  @override
  String admin_booking_error_closing(String error) {
    return 'Erreur lors de la fermeture de la réservation : $error';
  }

  @override
  String admin_booking_error_cancelling(String error) {
    return 'Erreur lors de l\'annulation de la réservation : $error';
  }

  @override
  String admin_booking_error_deleting(String error) {
    return 'Erreur lors de la suppression de la réservation : $error';
  }

  @override
  String admin_booking_error_updating(String error) {
    return 'Erreur lors de la mise à jour : $error';
  }

  @override
  String get admin_booking_resend_error => 'Impossible de renvoyer le code';

  @override
  String get admin_booking_notification_sent =>
      'Notification envoyée avec succès';

  @override
  String get admin_booking_notification_error =>
      'Erreur lors de l\'envoi de la notification';

  @override
  String get admin_booking_code_resent => 'Code renvoyé avec succès';

  @override
  String get admin_booking_checkin_validated => 'Check-in validé avec succès';

  @override
  String get admin_booking_checkin_rejected => 'Check-in rejeté';

  @override
  String get admin_booking_checkout_validated => 'Check-out validé avec succès';

  @override
  String get admin_booking_checkout_rejected => 'Check-out rejeté';

  @override
  String get admin_booking_incidents_detected => 'Incidents détectés';

  @override
  String get admin_booking_closed_successfully =>
      'Réservation fermée avec succès';

  @override
  String get admin_booking_cancelled_successfully =>
      'Réservation annulée avec succès';

  @override
  String get admin_booking_deleted_successfully =>
      'Réservation supprimée avec succès';

  @override
  String get admin_booking_keybox_updated => 'Code keybox mis à jour';

  @override
  String get admin_booking_already_closed_title => 'Réservation déjà fermée';

  @override
  String get admin_booking_already_closed_message =>
      'Cette réservation est déjà fermée.';

  @override
  String get admin_booking_already_cancelled_title =>
      'Réservation déjà annulée';

  @override
  String get admin_booking_already_cancelled_message =>
      'Cette réservation est déjà annulée.';

  @override
  String get admin_booking_cannot_delete_title => 'Impossible de supprimer';

  @override
  String admin_booking_cannot_delete_message(String status) {
    return 'Impossible de supprimer une réservation avec le statut $status.';
  }

  @override
  String get admin_booking_cancel_booking => 'Annuler la réservation';

  @override
  String get admin_booking_cancel_booking_confirm =>
      'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.';

  @override
  String get admin_booking_no_keep => 'Non, conserver';

  @override
  String get admin_booking_yes_cancel => 'Oui, annuler';

  @override
  String get admin_booking_delete_booking => 'Supprimer la réservation';

  @override
  String get admin_booking_delete_confirm =>
      'Êtes-vous sûr de vouloir supprimer complètement cette réservation et toutes ses données associées ? Cette action est irréversible.';

  @override
  String get admin_booking_close_booking => 'Fermer la réservation';

  @override
  String get admin_booking_close_confirm =>
      'Souhaitez-vous fermer manuellement cette réservation ? La date de fermeture sera enregistrée.';

  @override
  String get admin_booking_close_notes_hint =>
      'Notes de fermeture (facultatif)';

  @override
  String get admin_booking_reject_checkout => 'Rejeter le check-out';

  @override
  String get admin_booking_reject_checkout_desc =>
      'Indiquez les incidents détectés pour rejeter le check-out.';

  @override
  String get admin_booking_incidents_hint =>
      'Décrivez les incidents détectés...';

  @override
  String get admin_booking_reject => 'Rejeter';

  @override
  String get admin_booking_reject_checkin => 'Rejeter le check-in';

  @override
  String get admin_booking_reject_checkin_desc =>
      'Indiquez le motif du rejet du check-in.';

  @override
  String get admin_booking_reject_reason_hint =>
      'Motif du rejet (facultatif)...';

  @override
  String admin_booking_share_code_message(String code) {
    return 'Votre code d\'accès est : $code';
  }

  @override
  String admin_booking_share_keybox_code(String code) {
    return 'Code keybox : $code';
  }

  @override
  String admin_booking_share_dates(String checkIn, String checkOut) {
    return 'Check-in : $checkIn | Check-out : $checkOut';
  }

  @override
  String get admin_booking_share_download_app =>
      'Téléchargez l\'application : BF Stay';

  @override
  String get admin_booking_edit_keybox_title => 'Code Keybox';

  @override
  String get admin_booking_edit_keybox_desc =>
      'Saisissez le code de la boîte à clés';

  @override
  String get admin_booking_checkin_done => 'Check-in effectué';

  @override
  String get admin_booking_checkout_done => 'Check-out effectué';

  @override
  String get admin_booking_units_label => 'chambres';

  @override
  String get admin_booking_email_sent => 'Email envoyé';

  @override
  String get admin_booking_email_pending => 'Email en attente';

  @override
  String get admin_booking_code_used => 'Code utilisé';

  @override
  String get admin_booking_code_unused => 'Code non utilisé';

  @override
  String get admin_booking_checkin_ok => 'Check-in OK';

  @override
  String get admin_booking_checkin_pending => 'En attente de validation';

  @override
  String get admin_booking_checkin_in_progress => 'En cours';

  @override
  String get admin_booking_no_checkin => 'Sans check-in';

  @override
  String get admin_booking_guest_section => 'CLIENT';

  @override
  String get admin_booking_no_name => 'Sans nom';

  @override
  String get admin_booking_reservation_section => 'RÉSERVATION';

  @override
  String get admin_booking_checkin_label => 'Check-in';

  @override
  String get admin_booking_checkout_label => 'Check-out';

  @override
  String get admin_booking_night_singular => 'nuit';

  @override
  String get admin_booking_night_plural => 'nuits';

  @override
  String get admin_booking_years_label => 'ans';

  @override
  String get admin_booking_rooms_section => 'Chambres';

  @override
  String get admin_booking_wifi_label => 'WiFi';

  @override
  String get admin_booking_wifi_network_label => 'Réseau :';

  @override
  String get admin_booking_wifi_password_label => 'Mot de passe :';

  @override
  String get admin_booking_wifi_password_clipboard => 'Mot de passe WiFi';

  @override
  String get admin_booking_access_code_label => 'Code d\'accès';

  @override
  String get admin_booking_access_code_clipboard => 'Code d\'accès';

  @override
  String get admin_booking_access_instructions_label => 'Instructions d\'accès';

  @override
  String get admin_booking_access_codes_section => 'CODES D\'ACCÈS';

  @override
  String get admin_booking_reservation_code_label => 'Code de réservation';

  @override
  String get admin_booking_share_button => 'Partager';

  @override
  String get admin_booking_keybox_not_set => 'Non configuré';

  @override
  String get admin_booking_keybox_code_label => 'Code Keybox';

  @override
  String get admin_booking_keybox_code_clipboard => 'Code Keybox';

  @override
  String get admin_booking_checkin_not_started => 'Check-in non commencé';

  @override
  String get admin_booking_checkin_validated_status => 'Check-in validé';

  @override
  String get admin_booking_checkin_rejected_status => 'Check-in rejeté';

  @override
  String get admin_booking_checkin_pending_validation =>
      'En attente de validation';

  @override
  String get admin_booking_checkin_in_progress_status => 'Check-in en cours';

  @override
  String get admin_booking_checkin_section => 'CHECK-IN';

  @override
  String get admin_booking_docs_pending => 'documents en attente';

  @override
  String get admin_booking_validate_button => 'Valider';

  @override
  String get admin_booking_reject_button => 'Rejeter';

  @override
  String get admin_booking_internal_notes_section => 'NOTES INTERNES';

  @override
  String get admin_booking_closed_status => 'Réservation fermée';

  @override
  String get admin_booking_checkout_validated_status => 'Check-out validé';

  @override
  String get admin_booking_checkout_incidents_status =>
      'Check-out avec incidents';

  @override
  String get admin_booking_checkout_requested_status => 'Check-out demandé';

  @override
  String get admin_booking_checkout_pending_status => 'Check-out en attente';

  @override
  String get admin_booking_checkout_section => 'CHECK-OUT';

  @override
  String get admin_booking_requested_label => 'Demandé :';

  @override
  String get admin_booking_notes_label => 'Notes :';

  @override
  String get admin_booking_incidents_button => 'Incidents';

  @override
  String get admin_booking_close_booking_button => 'Fermer la réservation';

  @override
  String get admin_booking_close_booking_description =>
      'Le client n\'a pas demandé de check-out. Vous pouvez fermer la réservation manuellement.';

  @override
  String get admin_booking_signature_section => 'SIGNATURE DU TITULAIRE';

  @override
  String get admin_booking_signature_unavailable => 'Signature non disponible';

  @override
  String get admin_booking_actions_section => 'ACTIONS';

  @override
  String get admin_booking_resend_code_title => 'Renvoyer le code par email';

  @override
  String get admin_booking_last_sent_label => 'Dernier envoi :';

  @override
  String get admin_booking_na => 'N/A';

  @override
  String get admin_booking_not_sent_yet => 'Pas encore envoyé';

  @override
  String get admin_booking_room_ready_title => 'Chambre disponible';

  @override
  String get admin_booking_room_ready_subtitle =>
      'Notifiez le client que la chambre est prête et qu\'il peut y accéder';

  @override
  String get admin_booking_cancel_booking_title => 'Annuler la réservation';

  @override
  String get admin_booking_cancel_booking_subtitle =>
      'Marquer la réservation comme annulée';

  @override
  String get admin_booking_delete_booking_title => 'Supprimer la réservation';

  @override
  String get admin_booking_delete_booking_subtitle =>
      'Supprimer complètement la réservation et ses données (uniquement si elle n\'est pas finalisée)';

  @override
  String get admin_dashboard_admin_title => 'BF-Stay Admin';

  @override
  String get admin_dashboard_tab_summary => 'Résumé';

  @override
  String get admin_dashboard_tab_bookings => 'Réservations';

  @override
  String get admin_dashboard_tab_checkins => 'Check-ins';

  @override
  String get admin_dashboard_tab_invoices => 'Factures';

  @override
  String get admin_dashboard_tab_marketing => 'Marketing';

  @override
  String get admin_dashboard_tab_properties => 'Hébergements';

  @override
  String get guest_reviews_title => 'Avis';

  @override
  String get guest_reviews_write_review => 'Écrire un avis';

  @override
  String get guest_reviews_published => 'Avis publié avec succès';

  @override
  String get guest_reviews_publishing => 'Publication de l\'avis...';

  @override
  String get guest_reviews_updating => 'Mise à jour de l\'avis...';

  @override
  String get guest_reviews_deleting => 'Suppression de l\'avis...';

  @override
  String get guest_reviews_loading => 'Chargement des avis...';

  @override
  String get guest_reviews_delete_review => 'Supprimer l\'avis';

  @override
  String get guest_reviews_delete_confirm =>
      'Êtes-vous sûr de vouloir supprimer votre avis ? Cette action est irréversible.';

  @override
  String get guest_reviews_filter_all => 'Tous';

  @override
  String get guest_reviews_edit_review => 'Modifier l\'avis';

  @override
  String get guest_reviews_new_review => 'Nouvel avis';

  @override
  String get guest_reviews_updated => 'Avis mis à jour';

  @override
  String get guest_reviews_info_public =>
      'Votre avis sera public et aidera d\'autres clients à prendre des décisions.';

  @override
  String get guest_reviews_your_rating => 'Votre évaluation';

  @override
  String get guest_reviews_tap_stars => 'Appuyez sur les étoiles pour noter';

  @override
  String get guest_reviews_rating_1 => 'Très mauvais';

  @override
  String get guest_reviews_rating_2 => 'Mauvais';

  @override
  String get guest_reviews_rating_3 => 'Moyen';

  @override
  String get guest_reviews_rating_4 => 'Bon';

  @override
  String get guest_reviews_rating_5 => 'Excellent';

  @override
  String get guest_reviews_title_label => 'Titre (facultatif)';

  @override
  String get guest_reviews_title_hint =>
      'Résumez votre expérience en une phrase';

  @override
  String get guest_reviews_comment_required => 'Veuillez écrire un commentaire';

  @override
  String get guest_reviews_comment_min_length =>
      'Le commentaire doit contenir au moins 10 caractères';

  @override
  String get guest_reviews_comment_label => 'Votre commentaire *';

  @override
  String get guest_reviews_comment_hint => 'Parlez-nous de votre expérience...';

  @override
  String get guest_reviews_save_changes => 'Enregistrer les modifications';

  @override
  String get guest_reviews_publish_review => 'Publier l\'avis';

  @override
  String get guest_reviews_select_rating => 'Veuillez sélectionner une note';

  @override
  String get guest_reviews_saving => 'Enregistrement...';

  @override
  String get guest_alojamientos_title => 'Nos hébergements';

  @override
  String get guest_alojamientos_error_title => 'Erreur de chargement';

  @override
  String get guest_alojamientos_empty_title => 'Aucun hébergement';

  @override
  String get guest_alojamientos_empty_subtitle =>
      'Aucun hébergement disponible pour le moment';

  @override
  String guest_alojamientos_room_count(int count) {
    return '$count chambres';
  }

  @override
  String get guest_alojamiento_detail_title => 'Détails';

  @override
  String get guest_alojamiento_units_available => 'Unités disponibles';

  @override
  String get guest_alojamiento_no_units => 'Aucune unité disponible';

  @override
  String get guest_alojamiento_location => 'Localisation';

  @override
  String get guest_alojamiento_common_areas => 'Espaces communs';

  @override
  String get guest_alojamiento_shared_spaces => 'Espaces partagés';

  @override
  String get guest_alojamiento_common_areas_subtitle =>
      'Profitez des espaces communs de l\'hôtel';

  @override
  String get guest_alojamiento_no_photos => 'Aucune photo';

  @override
  String get guest_alojamiento_no_photos_subtitle =>
      'Aucune photo des espaces communs trouvée';

  @override
  String guest_alojamiento_photos_count(int count) {
    return '$count photos';
  }

  @override
  String get guest_alojamiento_hotel_rooms_title => 'Hotel Boutique Jerez';

  @override
  String get guest_alojamiento_no_rooms => 'Aucune chambre';

  @override
  String get guest_alojamiento_no_rooms_subtitle =>
      'Aucune chambre disponible pour le moment';

  @override
  String get guest_alojamiento_rooms => 'Chambres';

  @override
  String get guest_alojamiento_features => 'Caractéristiques';

  @override
  String get guest_alojamiento_feature_flexible_checkin => 'Check-in flexible';

  @override
  String get guest_alojamiento_feature_wifi => 'WiFi gratuit';

  @override
  String get guest_alojamiento_feature_ac => 'Climatisation';

  @override
  String get guest_alojamiento_description => 'Description';

  @override
  String guest_alojamiento_description_text(String unitType) {
    return 'Découvrez ce $unitType entièrement équipé pour rendre votre séjour le plus confortable possible. Il dispose de tout ce dont vous avez besoin pour profiter de Jerez à votre rythme.';
  }

  @override
  String get guest_alojamiento_services => 'Services inclus';

  @override
  String get guest_alojamiento_service_kitchen => 'Cuisine équipée';

  @override
  String get guest_alojamiento_service_washer => 'Machine à laver';

  @override
  String get guest_alojamiento_service_tv => 'Smart TV';

  @override
  String get guest_alojamiento_service_bedding => 'Literie';

  @override
  String get guest_alojamiento_service_towels => 'Serviettes';

  @override
  String get guest_alojamiento_service_coffee => 'Cafetière';

  @override
  String get guest_alojamiento_access_info => 'Informations d\'accès';

  @override
  String get guest_alojamiento_box_location => 'Emplacement du coffre';

  @override
  String get guest_alojamiento_access_instructions => 'Instructions d\'accès';

  @override
  String get guest_house_rules_title => 'Règlement intérieur';

  @override
  String get guest_house_rules_subtitle =>
      'Consultez les règles et recommandations';

  @override
  String get guest_house_rules_empty_title => 'Aucune règle';

  @override
  String get guest_house_rules_empty_subtitle =>
      'Cet hébergement n\'a pas de règles enregistrées';

  @override
  String get guest_normas_title => 'Règles';

  @override
  String get guest_normas_hotel_title => 'Règles de l\'hôtel';

  @override
  String get guest_normas_apartment_title => 'Règles de l\'appartement';

  @override
  String get guest_normas_not_available => 'Aucune règle disponible';

  @override
  String get guest_normas_image_error => 'Impossible de charger l\'image';

  @override
  String get guest_normas_generic_error => 'Une erreur s\'est produite';

  @override
  String get guest_que_ver_title => 'Que voir ?';

  @override
  String get guest_que_ver_clear_filters => 'Effacer';

  @override
  String guest_que_ver_places_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lieux',
      one: '1 lieu',
    );
    return '$_temp0';
  }

  @override
  String get guest_que_ver_no_results => 'Aucun résultat';

  @override
  String get guest_que_ver_no_places => 'Aucun lieu';

  @override
  String get guest_que_ver_try_filters =>
      'Essayez de modifier les filtres de recherche';

  @override
  String get guest_que_ver_coming_soon =>
      'Nous ajouterons bientôt de nouveaux lieux';

  @override
  String get guest_que_ver_error_loading => 'Erreur lors du chargement du lieu';

  @override
  String get guest_que_ver_place_not_found => 'Lieu non trouvé';

  @override
  String get guest_que_ver_about_place => 'À propos de ce lieu';

  @override
  String get guest_que_ver_address => 'Adresse';

  @override
  String get guest_que_ver_best_time => 'Meilleur moment pour visiter';

  @override
  String get guest_que_ver_location => 'Localisation';

  @override
  String get guest_que_ver_practical_info => 'Informations pratiques';

  @override
  String get guest_que_ver_tips => 'Conseils';

  @override
  String get guest_que_ver_free_entry => 'Entrée gratuite';

  @override
  String get guest_que_ver_how_to_get => 'Comment y accéder';

  @override
  String get guest_que_ver_copy_link => 'Copier le lien';

  @override
  String get guest_que_ver_official_web => 'Site officiel';

  @override
  String get guest_que_ver_link_copied => 'Lien copié dans le presse-papiers';

  @override
  String get guest_reviews_verified => 'Vérifié';

  @override
  String get guest_reviews_show_less => 'Afficher moins';

  @override
  String get guest_reviews_show_more => 'Afficher plus';

  @override
  String get guest_reviews_empty_title => 'Aucun avis pour le moment';

  @override
  String get guest_reviews_empty_subtitle =>
      'Soyez le premier à partager votre expérience';

  @override
  String get guest_reviews_write_first => 'Écrire un avis';

  @override
  String guest_reviews_filter_empty_title(String filter) {
    return 'Aucun résultat pour $filter';
  }

  @override
  String get guest_reviews_filter_empty_subtitle =>
      'Essayez de sélectionner un autre filtre';

  @override
  String get guest_reviews_clear_filter => 'Effacer le filtre';

  @override
  String guest_reviews_count_label(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return '$_temp0';
  }

  @override
  String get guest_reviews_no_reviews_title => 'Aucun avis pour le moment';

  @override
  String get guest_reviews_be_first => 'Soyez le premier';

  @override
  String get guest_access_no_booking => 'Réservation non trouvée';

  @override
  String get guest_access_error_loading =>
      'Erreur lors du chargement des données d\'accès';

  @override
  String get guest_access_title => 'Accès';

  @override
  String get guest_access_no_codes => 'Aucun code d\'accès disponible';

  @override
  String get guest_access_codes_title => 'Codes d\'accès';

  @override
  String get guest_access_codes_subtitle =>
      'Utilisez ces codes pour accéder à votre hébergement';

  @override
  String get guest_access_main_code => 'Code principal';

  @override
  String get guest_access_main_door => 'Porte principale';

  @override
  String guest_access_valid_period(String from, String until) {
    return 'Valide du $from au $until';
  }

  @override
  String get guest_access_wifi_title => 'WiFi';

  @override
  String get guest_access_wifi_network => 'Réseau :';

  @override
  String get guest_access_wifi_password => 'Mot de passe :';

  @override
  String get guest_access_password_copied =>
      'Mot de passe copié dans le presse-papiers';

  @override
  String get guest_access_other_accesses => 'Autres accès';

  @override
  String get guest_access_instructions => 'Instructions d\'accès';

  @override
  String get guest_guide_title => 'Guide du séjour';

  @override
  String get guest_guide_subtitle => 'Toutes les informations sur votre séjour';

  @override
  String get guest_guide_contact => 'Contact';

  @override
  String get guest_guide_phone_1 => 'Téléphone 1';

  @override
  String get guest_guide_phone_2 => 'Téléphone 2';

  @override
  String get guest_guide_your_data => 'Vos données';

  @override
  String get guest_guide_accommodation => 'Hébergement';

  @override
  String get guest_guide_property => 'Propriété';

  @override
  String get guest_guide_checkin => 'Check-in';

  @override
  String get guest_guide_checkout => 'Check-out';

  @override
  String get guest_guide_guests => 'Clients';

  @override
  String get guest_guide_services => 'Services';

  @override
  String get guest_guide_wifi => 'WiFi';

  @override
  String get guest_guide_laundry => 'Blanchisserie';

  @override
  String get guest_guide_laundry_desc => 'Service de blanchisserie disponible';

  @override
  String get guest_guide_jacuzzi => 'Jacuzzi';

  @override
  String get guest_guide_ac => 'Climatisation';

  @override
  String get guest_guide_ac_title => 'Climatisation';

  @override
  String get guest_guide_ac_desc =>
      'Contrôle de la température dans votre hébergement';

  @override
  String get guest_guide_tv => 'TV';

  @override
  String get guest_guide_tv_title => 'Télévision';

  @override
  String get guest_guide_tv_desc => 'Smart TV avec chaînes et applications';

  @override
  String get guest_guide_not_available => 'Non disponible';

  @override
  String get guest_guide_wifi_desc => 'Connexion WiFi incluse';

  @override
  String get guest_guide_house_rules => 'Règlement intérieur';

  @override
  String get guest_guide_rule_checkin => 'Check-in à partir de 16h00';

  @override
  String guest_guide_rule_checkout(String time) {
    return 'Check-out avant $time';
  }

  @override
  String get guest_guide_rule_no_smoking => 'Non-fumeur';

  @override
  String get guest_guide_rule_no_parties => 'Fêtes interdites';

  @override
  String get guest_guide_rule_no_pets => 'Animaux non autorisés';

  @override
  String get guest_notifications_title => 'Notifications';

  @override
  String get guest_notifications_delete_all => 'Tout supprimer';

  @override
  String get guest_notifications_delete_all_title =>
      'Supprimer toutes les notifications';

  @override
  String get guest_notifications_delete_all_confirm =>
      'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action est irréversible.';

  @override
  String guest_notifications_unread_count(int count) {
    return '$count non lues';
  }

  @override
  String get guest_notifications_mark_all => 'Tout marquer comme lu';

  @override
  String get guest_notifications_empty_title => 'Aucune notification';

  @override
  String get guest_notifications_empty_subtitle =>
      'Les notifications relatives à votre séjour apparaîtront ici';

  @override
  String get guest_notifications_read => 'Lu';

  @override
  String get guest_romantic_title => 'Pack romantique';

  @override
  String get guest_romantic_surprise => 'Surprenez votre partenaire';

  @override
  String get guest_romantic_unforgettable => 'Créez un moment inoubliable';

  @override
  String get guest_romantic_includes => 'Qu\'est-ce qui est inclus ?';

  @override
  String get guest_romantic_decoration_title => 'Décoration romantique';

  @override
  String get guest_romantic_decoration_desc =>
      'Pétales de rose, bougies et décoration spéciale de la chambre';

  @override
  String get guest_romantic_choose_title => 'Choisissez votre cadeau';

  @override
  String get guest_romantic_choose_desc =>
      'Bouteille de cava ou chocolat artisanal pour accompagner la soirée';

  @override
  String get guest_romantic_basic_pack => 'Pack romantique basique';

  @override
  String get guest_romantic_price => '20,00 €';

  @override
  String get guest_romantic_book_now => 'Réserver maintenant';

  @override
  String get guest_romantic_customize =>
      'Ou personnalisez avec des extras lors de la réservation';

  @override
  String get guest_romantic_redirect =>
      'Vous serez redirigé vers le site web pour finaliser la réservation du Pack romantique. Continuer ?';

  @override
  String get guest_romantic_how_to => 'Comment réserver ?';

  @override
  String get guest_romantic_step_1 => 'Sélectionnez le Pack romantique';

  @override
  String get guest_romantic_step_2 => 'Personnalisez les détails';

  @override
  String get guest_romantic_step_3 => 'Finalisez la réservation en ligne';

  @override
  String get guest_romantic_step_4 => 'Profitez de la surprise';

  @override
  String get guest_romantic_note =>
      'La décoration est préparée en votre absence pour que ce soit une vraie surprise.';

  @override
  String get guest_jacuzzi_title => 'Jacuzzi';

  @override
  String get guest_jacuzzi_rules_title => 'Règles d\'utilisation';

  @override
  String get guest_jacuzzi_subtitle => 'Détendez-vous et profitez';

  @override
  String get guest_jacuzzi_power => 'Alimentation';

  @override
  String get guest_jacuzzi_power_step_1 =>
      'Appuyez sur le bouton POWER pour allumer le jacuzzi';

  @override
  String get guest_jacuzzi_power_step_2 => 'Attendez que le panneau s\'allume';

  @override
  String get guest_jacuzzi_power_step_3 =>
      'Sélectionnez la température souhaitée avec les boutons + et -';

  @override
  String get guest_jacuzzi_lock => 'Verrouillage du panneau';

  @override
  String get guest_jacuzzi_lock_step_1 =>
      'Pour éviter les activations accidentelles, vous pouvez verrouiller le panneau de contrôle';

  @override
  String get guest_jacuzzi_lock_unlock => 'Déverrouiller';

  @override
  String get guest_jacuzzi_lock_unlock_step =>
      'Appuyez et maintenez le bouton LOCK pendant 3 secondes';

  @override
  String get guest_jacuzzi_lock_manual => 'Verrouillage manuel';

  @override
  String get guest_jacuzzi_lock_manual_step =>
      'Appuyez et maintenez le bouton LOCK pendant 3 secondes pour activer';

  @override
  String get guest_jacuzzi_ozone => 'Fonction ozone';

  @override
  String get guest_jacuzzi_ozone_intro =>
      'Le système d\'ozone aide à garder l\'eau propre et désinfectée automatiquement.';

  @override
  String get guest_jacuzzi_ozone_step_1 =>
      'Appuyez sur le bouton OZONE sur le panneau';

  @override
  String get guest_jacuzzi_ozone_step_2 => 'Le voyant lumineux s\'activera';

  @override
  String get guest_jacuzzi_ozone_step_3 =>
      'Le système fonctionnera pendant 30 minutes';

  @override
  String get guest_jacuzzi_ozone_step_4 =>
      'Il se désactivera automatiquement à la fin';

  @override
  String guest_jacuzzi_ozone_note(String note) {
    return 'Note : $note';
  }

  @override
  String get guest_jacuzzi_massage => 'Fonctions de massage';

  @override
  String get guest_jacuzzi_air_jets => 'Jets d\'air';

  @override
  String get guest_jacuzzi_air_step_1 =>
      'Appuyez sur le bouton AIR pour activer les jets d\'air';

  @override
  String get guest_jacuzzi_air_step_2 =>
      'Ajustez l\'intensité avec les boutons + et -';

  @override
  String get guest_jacuzzi_air_step_3 =>
      'Les jets créeront des bulles douces dans l\'eau';

  @override
  String get guest_jacuzzi_air_step_4 => 'Appuyez à nouveau pour désactiver';

  @override
  String get guest_jacuzzi_water_jets => 'Jets d\'eau';

  @override
  String get guest_jacuzzi_water_step_1 =>
      'Appuyez sur le bouton JET pour activer les jets d\'eau';

  @override
  String get guest_jacuzzi_water_step_2 =>
      'Les jets d\'eau offrent un massage plus intense';

  @override
  String get guest_jacuzzi_water_step_3 =>
      'Dirigez les jets vers les zones de tension musculaire';

  @override
  String get guest_jacuzzi_water_step_4 => 'Appuyez à nouveau pour désactiver';

  @override
  String get guest_jacuzzi_important => 'Important';

  @override
  String get guest_jacuzzi_water_level_info =>
      'Le niveau d\'eau doit toujours être au-dessus des jets pour un bon fonctionnement.';

  @override
  String get guest_jacuzzi_low_water_title => 'Si le niveau est bas :';

  @override
  String get guest_jacuzzi_low_water_stop => 'Arrêtez le jacuzzi immédiatement';

  @override
  String get guest_jacuzzi_low_water_icon =>
      'Vérifiez l\'icône d\'avertissement sur le panneau';

  @override
  String get guest_jacuzzi_low_water_resume =>
      'Remplissez d\'eau pour couvrir les jets avant de reprendre.';

  @override
  String get guest_jacuzzi_water_responsibility =>
      'Utilisation responsable de l\'eau';

  @override
  String get guest_jacuzzi_water_refill_info =>
      'Le jacuzzi a une capacité d\'eau considérable. Veuillez l\'utiliser de manière responsable.';

  @override
  String get guest_jacuzzi_capacity => 'Capacité :';

  @override
  String get guest_jacuzzi_capacity_liters => '800 litres';

  @override
  String get guest_jacuzzi_water_regulation =>
      'Le remplissage et la vidange du jacuzzi sont réglementés par les réglementations locales sur l\'utilisation de l\'eau.';

  @override
  String get guest_jacuzzi_thanks =>
      'Merci pour votre collaboration dans l\'utilisation responsable de l\'eau.';

  @override
  String get guest_physical_registration_title => 'Enregistrement physique';

  @override
  String get guest_physical_registration_header =>
      'Enregistrement à la réception';

  @override
  String get guest_physical_registration_subtitle =>
      'Complétez votre enregistrement en personne';

  @override
  String get guest_physical_registration_instructions => 'Instructions';

  @override
  String get guest_physical_registration_step_1_title =>
      'Rendez-vous à la réception';

  @override
  String get guest_physical_registration_step_1_desc =>
      'Dirigez-vous vers la réception de l\'hôtel pendant les heures d\'ouverture';

  @override
  String get guest_physical_registration_step_2_title =>
      'Présentez votre document';

  @override
  String get guest_physical_registration_step_2_desc =>
      'Montrez votre document d\'identité original (DNI, passeport ou permis de conduire)';

  @override
  String get guest_physical_registration_step_3_title => 'Signez le registre';

  @override
  String get guest_physical_registration_step_3_desc =>
      'Signez le document d\'enregistrement d\'entrée';

  @override
  String get guest_physical_registration_step_4_title => 'Recevez votre clé';

  @override
  String get guest_physical_registration_step_4_desc =>
      'Nous vous remettrons la clé de votre chambre';

  @override
  String get guest_physical_registration_schedule => 'Horaires de la réception';

  @override
  String get guest_physical_registration_schedule_hours =>
      'Heures d\'ouverture';

  @override
  String get guest_physical_registration_schedule_days =>
      'Du lundi au vendredi';

  @override
  String get guest_physical_registration_documents => 'Documents acceptés';

  @override
  String get guest_physical_registration_doc_dni => 'DNI';

  @override
  String get guest_physical_registration_doc_passport => 'Passeport';

  @override
  String get guest_physical_registration_doc_license => 'Permis de conduire';

  @override
  String get guest_checkin_child_no_data =>
      'Moins de 14 ans, aucune donnée requise';

  @override
  String get guest_checkin_holder => 'Principal';

  @override
  String get guest_checkin_full_name => 'Nom complet';

  @override
  String get guest_checkin_email => 'Email';

  @override
  String get guest_checkin_phone => 'Téléphone';

  @override
  String guest_checkin_young(int age) {
    return 'Mineur ($age ans)';
  }

  @override
  String guest_checkin_adult(int number) {
    return 'Adulte $number';
  }

  @override
  String guest_checkin_guest(int number) {
    return 'Client $number';
  }

  @override
  String get guest_checkin_document_id => 'Document d\'identité';

  @override
  String get guest_checkin_upload_document => 'Télécharger le document';

  @override
  String get guest_checkin_document => 'Document';

  @override
  String get guest_checkin_missing_photo => 'Photo du document manquante';

  @override
  String get guest_checkin_upload_document_title => 'Télécharger le document';

  @override
  String get guest_checkin_document_type => 'Type de document';

  @override
  String get guest_checkin_document_number => 'Numéro de document';

  @override
  String get guest_checkin_document_photo => 'Photo du document';

  @override
  String get guest_checkin_image_captured => 'Image capturée';

  @override
  String get guest_checkin_tap_to_capture =>
      'Appuyez pour capturer le document';

  @override
  String get guest_checkin_camera_or_gallery => 'Caméra ou galerie';

  @override
  String get guest_checkin_select_source => 'Sélectionner la source';

  @override
  String get guest_checkin_camera => 'Caméra';

  @override
  String get guest_checkin_gallery => 'Galerie';

  @override
  String get guest_checkin_photo_required => 'Photo requise';

  @override
  String get guest_checkin_document_number_required =>
      'Numéro de document requis';

  @override
  String get guest_checkin_confirm => 'Confirmer';

  @override
  String guest_checkin_capture_error(String error) {
    return 'Erreur lors de la capture de l\'image : $error';
  }

  @override
  String get admin_chat_title => 'Chat';

  @override
  String get admin_chat_online => 'En ligne';

  @override
  String get chat_delete_message => 'Supprimer le message';

  @override
  String get chat_delete_message_confirm_body =>
      'Voulez-vous vraiment supprimer ce message ? Cette action est irréversible.';

  @override
  String get chat_delete_message_error => 'Impossible de supprimer le message';

  @override
  String get admin_chat_delete_conversation => 'Supprimer la conversation';

  @override
  String get admin_chat_delete_confirm_body =>
      'Êtes-vous sûr de vouloir supprimer cette conversation ?';

  @override
  String get admin_chat_deleted_success => 'Conversation supprimée avec succès';

  @override
  String admin_chat_error_deleting(String error) {
    return 'Erreur lors de la suppression de la conversation : $error';
  }

  @override
  String get admin_checkin_detail_title => 'Détail du check-in';

  @override
  String get admin_checkin_validate => 'Valider';

  @override
  String get admin_checkin_reject => 'Rejeter';

  @override
  String get admin_checkin_cancel_booking => 'Annuler la réservation';

  @override
  String get admin_checkin_error_loading => 'Erreur de chargement';

  @override
  String get admin_checkin_not_found => 'Check-in non trouvé';

  @override
  String get admin_checkin_status_pending => 'En attente';

  @override
  String get admin_checkin_status_validated => 'Validé';

  @override
  String get admin_checkin_status_rejected => 'Rejeté';

  @override
  String get admin_checkin_status_cancelled => 'Annulé';

  @override
  String get admin_checkin_status_draft => 'Brouillon';

  @override
  String get admin_checkin_submitted_label => 'Soumis :';

  @override
  String get admin_checkin_validated_label => 'Validé :';

  @override
  String get admin_checkin_rejected_label => 'Rejeté :';

  @override
  String get admin_checkin_cancelled_label => 'Annulé :';

  @override
  String get admin_checkin_booking_info => 'Informations sur la réservation';

  @override
  String get admin_checkin_property_label => 'Propriété :';

  @override
  String get admin_checkin_units_label => 'chambres';

  @override
  String get admin_checkin_unit_label => 'chambre';

  @override
  String get admin_checkin_code_label => 'Code :';

  @override
  String get admin_checkin_checkin_date_label => 'Check-in :';

  @override
  String get admin_checkin_checkout_date_label => 'Check-out :';

  @override
  String get admin_checkin_guests_section => 'CLIENTS';

  @override
  String get admin_checkin_primary_badge => 'Principal';

  @override
  String get admin_checkin_na => 'N/A';

  @override
  String get admin_checkin_documents_section => 'DOCUMENTS';

  @override
  String get admin_checkin_unknown_guest => 'Client inconnu';

  @override
  String get admin_checkin_signature_section => 'SIGNATURE';

  @override
  String get admin_checkin_doc_type_dni => 'DNI';

  @override
  String get admin_checkin_doc_type_nie => 'NIE';

  @override
  String get admin_checkin_doc_type_passport => 'Passeport';

  @override
  String get admin_checkin_image_load_error =>
      'Erreur lors du chargement de l\'image';

  @override
  String get admin_checkin_validate_title => 'Valider le check-in';

  @override
  String get admin_checkin_validate_message =>
      'Êtes-vous sûr de vouloir valider ce check-in ?';

  @override
  String get admin_checkin_validated_success => 'Check-in validé avec succès';

  @override
  String admin_checkin_error(String error) {
    return 'Erreur : $error';
  }

  @override
  String get admin_checkin_reject_title => 'Rejeter le check-in';

  @override
  String get admin_checkin_reject_message =>
      'Êtes-vous sûr de vouloir rejeter ce check-in ?';

  @override
  String get admin_checkin_reject_hint => 'Motif du rejet (facultatif)...';

  @override
  String get admin_checkin_no_reason => 'Aucun motif';

  @override
  String get admin_checkin_rejected_success => 'Check-in rejeté avec succès';

  @override
  String get admin_checkin_cancel_message =>
      'Êtes-vous sûr de vouloir annuler cette réservation ?';

  @override
  String get admin_checkin_cancel_warning => 'Cette action est irréversible.';

  @override
  String get admin_checkin_cancel_reason_label => 'Motif de l\'annulation';

  @override
  String get admin_checkin_cancel_reason_hint =>
      'Décrivez le motif de l\'annulation...';

  @override
  String get admin_checkin_cancelled_success =>
      'Réservation annulée avec succès';

  @override
  String get admin_invoice_generate_pdf => 'Générer le PDF';

  @override
  String get admin_invoice_share => 'Partager';

  @override
  String get admin_invoice_download => 'Télécharger';

  @override
  String get admin_invoice_share_title => 'Partager la facture';

  @override
  String get admin_invoice_copy_link => 'Copier le lien';

  @override
  String admin_invoice_pdf_saved(String path) {
    return 'PDF enregistré dans : $path';
  }

  @override
  String get admin_invoice_issue => 'Émettre';

  @override
  String get admin_invoice_mark_paid => 'Marquer comme payé';

  @override
  String admin_invoice_paid_on(String date) {
    return 'Payé le $date';
  }

  @override
  String admin_invoice_cancelled(String reason) {
    return 'Annulée : $reason';
  }

  @override
  String get admin_invoice_issue_confirm_title => 'Émettre la facture';

  @override
  String admin_invoice_issue_confirm_message(String invoiceNumber) {
    return 'Êtes-vous sûr de vouloir émettre la facture $invoiceNumber ?';
  }

  @override
  String get admin_invoice_mark_paid_confirm_title => 'Marquer comme payé';

  @override
  String admin_invoice_mark_paid_confirm_message(String total) {
    return 'Confirmez-vous la réception du paiement de $total ?';
  }

  @override
  String get admin_invoice_confirm_payment => 'Confirmer le paiement';

  @override
  String get admin_invoice_cancel_confirm_title => 'Annuler la facture';

  @override
  String get admin_invoice_cancel_reason_label => 'Motif de l\'annulation';

  @override
  String get admin_invoice_cancel_reason_hint =>
      'Décrivez le motif de l\'annulation...';

  @override
  String get admin_invoice_dont_cancel => 'Ne pas annuler';

  @override
  String get admin_invoice_cancel_invoice => 'Annuler la facture';

  @override
  String admin_invoice_error_generate_pdf(String error) {
    return 'Erreur lors de la génération du PDF : $error';
  }

  @override
  String admin_invoice_error_share(String error) {
    return 'Erreur lors du partage : $error';
  }

  @override
  String admin_invoice_error_download(String error) {
    return 'Erreur lors du téléchargement : $error';
  }

  @override
  String get admin_invoice_nif_label => 'NIF/CIF :';

  @override
  String get admin_invoice_label => 'Facture';

  @override
  String get admin_invoice_bill_to => 'Facturer à';

  @override
  String get admin_invoice_issue_date_label => 'Date d\'émission :';

  @override
  String get admin_invoice_due_date_label => 'Date d\'échéance :';

  @override
  String get admin_invoice_period_label => 'Période';

  @override
  String get admin_invoice_booking_label => 'Réservation';

  @override
  String get admin_invoice_no_line_items => 'Aucun article';

  @override
  String get admin_invoice_col_description => 'Description';

  @override
  String get admin_invoice_col_qty => 'Qté';

  @override
  String get admin_invoice_col_price => 'Prix';

  @override
  String get admin_invoice_col_total => 'Total';

  @override
  String get admin_invoice_tax_base => 'Base imposable';

  @override
  String get admin_invoice_tax_label => 'TVA';

  @override
  String get admin_invoice_total_label => 'Total';

  @override
  String get admin_invoice_notes_label => 'Notes';

  @override
  String get admin_notifications_title => 'Notifications';

  @override
  String get admin_notifications_empty_title => 'Aucune notification';

  @override
  String get admin_notifications_empty_subtitle =>
      'Les notifications apparaîtront ici';

  @override
  String get admin_notifications_mark_all_read => 'Tout marquer comme lu';

  @override
  String get admin_notifications_mark_read => 'Marquer comme lu';

  @override
  String get admin_notifications_delete_all => 'Tout supprimer';

  @override
  String get admin_notifications_delete_all_title =>
      'Supprimer toutes les notifications';

  @override
  String get admin_notifications_delete_all_confirm =>
      'Êtes-vous sûr de vouloir supprimer toutes les notifications ?';

  @override
  String admin_notifications_unread_count(int count) {
    return '$count non lues';
  }

  @override
  String get guest_access_checkin => 'Check-in';

  @override
  String get guest_access_checkout => 'Check-out';

  @override
  String get guest_access_checkout_label => 'Check-out';

  @override
  String guest_access_checkout_until(String time) {
    return 'Jusqu\'à $time';
  }

  @override
  String get guest_access_checkout_deadline => 'Heure limite de check-out';

  @override
  String get guest_access_checkout_instructions => 'Instructions de check-out';

  @override
  String get guest_access_code_label => 'Code';

  @override
  String guest_access_code_available_at(String date, String time) {
    return 'Disponible le $date à $time';
  }

  @override
  String get guest_access_code_provided_by_staff => 'Fourni par le personnel';

  @override
  String get guest_access_locker_code => 'Code du casier';

  @override
  String get guest_access_locker_code_label => 'Code du casier';

  @override
  String guest_access_locker_available_at(String date) {
    return 'Disponible le $date';
  }

  @override
  String get guest_access_key_locker => 'Casier à clés';

  @override
  String get guest_access_door_code => 'Code de la porte';

  @override
  String get guest_access_building_access => 'Accès à l\'immeuble';

  @override
  String get guest_access_building_instructions =>
      'Instructions d\'accès à l\'immeuble';

  @override
  String get guest_access_apartment_access => 'Accès à l\'appartement';

  @override
  String get guest_access_apartment_instructions =>
      'Instructions d\'accès à l\'appartement';

  @override
  String get guest_access_location => 'Localisation';

  @override
  String get guest_access_contact => 'Contact';

  @override
  String get guest_access_contact_description =>
      'Contactez-nous si vous avez besoin d\'aide';

  @override
  String guest_access_copied(String label) {
    return '$label copié dans le presse-papiers';
  }

  @override
  String get guest_access_open_maps => 'Ouvrir dans Maps';

  @override
  String get guest_access_network => 'Réseau';

  @override
  String get guest_access_network_name => 'Nom du réseau';

  @override
  String get guest_access_password => 'Mot de passe';

  @override
  String get guest_access_company_name => 'BF Stay';

  @override
  String get guest_access_house_rules => 'Règlement intérieur';

  @override
  String get guest_access_rules_warning =>
      'Veuillez lire le règlement intérieur avant votre arrivée';

  @override
  String get guest_access_your_accommodation => 'Votre hébergement';

  @override
  String get guest_access_your_codes => 'Vos codes';

  @override
  String get guest_access_guest => 'Client';

  @override
  String guest_access_welcome_message(String unitName) {
    return 'Bienvenue à $unitName';
  }

  @override
  String guest_access_hello(String name) {
    return 'Bonjour $name';
  }

  @override
  String guest_access_codes_available_datetime(String date, String time) {
    return 'Disponible le $date à $time';
  }

  @override
  String guest_access_codes_available_message(String time) {
    return 'Votre code sera disponible à partir de $time';
  }

  @override
  String get guest_access_loading_instructions =>
      'Chargement des instructions...';

  @override
  String get guest_access_cannot_load_instructions =>
      'Impossible de charger les instructions';

  @override
  String get guest_access_rule_no_parties_title => 'Fêtes interdites';

  @override
  String get guest_access_rule_no_parties_description =>
      'Fêtes et événements non autorisés';

  @override
  String get guest_access_rule_no_smoking_title => 'Non-fumeur';

  @override
  String get guest_access_rule_smoke_free_description =>
      'Cette propriété est non-fumeur';

  @override
  String get guest_access_rule_registered_only_title =>
      'Clients enregistrés uniquement';

  @override
  String get guest_access_rule_registered_only_description =>
      'Seuls les clients enregistrés peuvent accéder';

  @override
  String get guest_accommodation_title => 'Hébergement';

  @override
  String get guest_accommodation_error_loading => 'Erreur de chargement';

  @override
  String get guest_accommodation_error_occurred => 'Une erreur s\'est produite';

  @override
  String get guest_accommodation_no_booking => 'Réservation non trouvée';

  @override
  String get guest_accommodation_booking_not_found => 'Réservation non trouvée';

  @override
  String get guest_accommodation_no_unit_info =>
      'Aucune information sur l\'unité disponible';

  @override
  String get guest_accommodation_address => 'Adresse';

  @override
  String get guest_accommodation_address_unavailable =>
      'Adresse non disponible';

  @override
  String get guest_accommodation_box_location => 'Emplacement du coffre';

  @override
  String get guest_accommodation_access_codes => 'Codes d\'accès';

  @override
  String get guest_accommodation_access_instructions => 'Instructions d\'accès';

  @override
  String get guest_accommodation_main_door => 'Porte principale';

  @override
  String get guest_accommodation_door_code => 'Code de la porte';

  @override
  String get guest_accommodation_portal_code => 'Code du portail';

  @override
  String get guest_accommodation_key_box_code => 'Code du coffre à clés';

  @override
  String get guest_accommodation_keybox_description =>
      'Code pour le coffre à clés';

  @override
  String get guest_accommodation_wifi_password => 'Mot de passe WiFi';

  @override
  String guest_accommodation_rooms_count(int count) {
    return '$count chambres';
  }

  @override
  String get guest_accommodation_hotel_rules => 'Règles de l\'hôtel';

  @override
  String get guest_accommodation_apartment_rules => 'Règles de l\'appartement';

  @override
  String get guest_accommodation_rules_description =>
      'Consultez les règles de votre hébergement';

  @override
  String guest_accommodation_rules_load_error(String error) {
    return 'Erreur lors du chargement des règles : $error';
  }

  @override
  String guest_accommodation_codes_available_datetime(
    String date,
    String time,
  ) {
    return 'Disponible le $date à $time';
  }

  @override
  String guest_accommodation_codes_available_message(String time) {
    return 'Vos codes seront disponibles au début de votre séjour ($time)';
  }

  @override
  String guest_accommodation_file_not_found(String message) {
    return 'Fichier non trouvé : $message';
  }

  @override
  String get guest_accommodation_cannot_open_document =>
      'Impossible d\'ouvrir le document';

  @override
  String get guest_accommodation_tap_for_access_info =>
      'Appuyez pour les informations d\'accès';

  @override
  String get guest_chat_default_title => 'Chat';

  @override
  String get guest_chat_online => 'En ligne';

  @override
  String get guest_chat_start_conversation => 'Démarrer la conversation';

  @override
  String get guest_chat_welcome_message =>
      'Bonjour ! Comment pouvons-nous vous aider ?';

  @override
  String get guest_checkin_label => 'Check-in';

  @override
  String get guest_checkin_back => 'Retour';

  @override
  String get guest_checkin_continue => 'Continuer';

  @override
  String get guest_checkin_complete => 'Terminer';

  @override
  String get guest_checkin_loading_booking =>
      'Chargement des données de réservation...';

  @override
  String get guest_checkin_error_loading => 'Erreur de chargement';

  @override
  String get guest_checkin_booking => 'Réservation';

  @override
  String get guest_checkin_code => 'Code';

  @override
  String get guest_checkin_guests_label => 'Clients';

  @override
  String guest_checkin_guests_count(int count) {
    return '$count clients';
  }

  @override
  String guest_checkin_guests_registered(int count) {
    return '$count enregistrés';
  }

  @override
  String guest_checkin_guests_summary(int count) {
    return '$count clients';
  }

  @override
  String get guest_checkin_guest_data => 'Données du client';

  @override
  String get guest_checkin_guest_data_description =>
      'Complétez les données pour tous les clients';

  @override
  String get guest_checkin_holder_badge => 'PRINCIPAL';

  @override
  String get guest_checkin_holder_signature => 'Signature du client principal';

  @override
  String get guest_checkin_no_name => 'Sans nom';

  @override
  String get guest_checkin_guest_no_name => 'Client sans nom';

  @override
  String guest_checkin_adults_children(int adults, int children) {
    return '$adults adultes et $children mineurs';
  }

  @override
  String get guest_checkin_minor_badge => 'MINEUR';

  @override
  String guest_checkin_young_document_required(int age) {
    return 'Moins de $age ans, document requis';
  }

  @override
  String get guest_checkin_document_required => 'Document requis';

  @override
  String get guest_checkin_upload => 'Télécharger';

  @override
  String guest_checkin_documents_uploaded(int completed, int total) {
    return '$completed sur $total documents téléchargés';
  }

  @override
  String get guest_checkin_all_documents_uploaded =>
      'Tous les documents téléchargés';

  @override
  String get guest_checkin_upload_documents_description =>
      'Téléchargez les photos des documents d\'identité de tous les clients';

  @override
  String get guest_checkin_uploaded_documents => 'Documents téléchargés';

  @override
  String get guest_checkin_pending_documents => 'Documents en attente';

  @override
  String get guest_checkin_identity_documents => 'Documents d\'identité';

  @override
  String get guest_checkin_signature_description =>
      'Signature du client principal de la réservation';

  @override
  String get guest_checkin_signature_pending => 'Signature en attente';

  @override
  String get guest_checkin_signature_captured => 'Signature capturée';

  @override
  String get guest_checkin_signature_captured_short => 'Signature';

  @override
  String get guest_checkin_clear_signature => 'Effacer la signature';

  @override
  String get guest_checkin_step_guests => 'Clients';

  @override
  String get guest_checkin_step_documents => 'Documents';

  @override
  String get guest_checkin_step_signature => 'Signature';

  @override
  String get guest_checkin_step_confirm => 'Confirmer';

  @override
  String get guest_checkin_online => 'En ligne';

  @override
  String get guest_checkin_pending => 'En attente';

  @override
  String get guest_checkin_validated => 'Validé';

  @override
  String get guest_checkin_waiting_validation => 'En attente de validation';

  @override
  String get guest_checkin_completed => 'Terminé';

  @override
  String get guest_checkin_completed_success => 'Check-in effectué avec succès';

  @override
  String get guest_checkin_sending => 'Envoi en cours...';

  @override
  String get guest_checkin_progress => 'Progression du check-in';

  @override
  String get guest_checkin_confirmation => 'Confirmation du check-in';

  @override
  String get guest_checkin_confirmation_description =>
      'Votre check-in a été envoyé. Vous devez maintenant attendre que l\'hébergement le valide.';

  @override
  String get guest_checkin_legal_notice => 'Mentions légales';

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
    return '$count nuits';
  }

  @override
  String guest_checkout_guests_count(int count) {
    return '$count clients';
  }

  @override
  String get guest_checkout_stay_summary => 'Résumé du séjour';

  @override
  String get guest_checkout_confirm => 'Confirmer';

  @override
  String get guest_checkout_confirm_button => 'Confirmer le check-out';

  @override
  String get guest_checkout_confirm_dialog_title => 'Confirmer le check-out ?';

  @override
  String get guest_checkout_confirm_dialog_message =>
      'Vous êtes sur le point de confirmer votre check-out. Voulez-vous continuer ?';

  @override
  String get guest_checkout_confirm_info => 'Confirmation du check-out...';

  @override
  String get guest_checkout_processing => 'Traitement en cours...';

  @override
  String get guest_checkout_completed => 'Check-out effectué';

  @override
  String get guest_checkout_thank_you => 'Merci pour votre séjour !';

  @override
  String get guest_checkout_feedback_title => 'Votre avis compte';

  @override
  String get guest_checkout_feedback_hint =>
      'Parlez-nous de votre expérience...';

  @override
  String get guest_checkout_rating_title => 'Évaluez votre séjour';

  @override
  String get guest_checkout_review_description =>
      'Votre avis aide d\'autres voyageurs';

  @override
  String get guest_checkout_loading => 'Chargement...';

  @override
  String get guest_checkout_error_loading => 'Erreur de chargement';

  @override
  String get guest_checkout_already_done => 'Check-out déjà effectué';

  @override
  String get guest_checkout_already_done_message =>
      'Vous avez déjà effectué le check-out. Merci !';

  @override
  String get guest_home_welcome => 'Bienvenue';

  @override
  String get guest_home_welcome_stay => 'Bienvenue dans votre séjour';

  @override
  String guest_home_hello_name(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get guest_home_your_stay => 'Votre séjour';

  @override
  String get guest_home_no_booking => 'Aucune réservation';

  @override
  String get guest_home_not_authenticated => 'Non authentifié';

  @override
  String get guest_home_stay_active_enjoy =>
      'Votre séjour est actif. Profitez !';

  @override
  String get guest_home_quick_actions => 'Actions rapides';

  @override
  String get guest_home_checkin => 'Check-in';

  @override
  String get guest_home_checkout => 'Check-out';

  @override
  String get guest_home_chat => 'Chat';

  @override
  String get guest_home_guide => 'Guide';

  @override
  String get guest_home_rules => 'Règles';

  @override
  String get guest_home_parkings => 'Parking';

  @override
  String get guest_home_accommodations => 'Hébergements';

  @override
  String get guest_home_accommodation => 'Hébergement';

  @override
  String guest_home_rooms_count(int count) {
    return '$count chambres';
  }

  @override
  String get guest_home_guests => 'Clients';

  @override
  String guest_home_nights(int count) {
    return '$count nuits';
  }

  @override
  String get guest_home_what_to_see => 'Que voir';

  @override
  String get guest_home_instructions => 'Instructions';

  @override
  String get guest_home_my_accommodation => 'Mon hébergement';

  @override
  String get guest_home_booking_cancelled => 'Réservation annulée';

  @override
  String get guest_home_booking_cancelled_message =>
      'Votre réservation a été annulée. Contactez la réception.';

  @override
  String get guest_home_cancellation_reason => 'Motif de l\'annulation';

  @override
  String get guest_home_checkin_pending => 'Check-in en attente';

  @override
  String get guest_home_checkin_sent_waiting =>
      'Check-in envoyé, en attente de validation';

  @override
  String get guest_home_checkin_rejected => 'Check-in rejeté';

  @override
  String get guest_home_rejection_reason => 'Motif du rejet';

  @override
  String get guest_home_pending_validation => 'En attente de validation';

  @override
  String get guest_home_complete_checkin_access =>
      'Complétez le check-in pour accéder';

  @override
  String get guest_home_contact_reception => 'Contacter la réception';

  @override
  String get guest_home_correct_errors_resend =>
      'Corrigez les erreurs et renvoyez';

  @override
  String get guest_home_physical_registration => 'Enregistrement en personne';

  @override
  String get guest_home_romantic_pack => 'Pack romantique';

  @override
  String guest_jacuzzi_note(String note) {
    return 'Note : $note';
  }

  @override
  String get public_services_title => 'Nos services';

  @override
  String get public_service_rules_title => 'Règlement intérieur';

  @override
  String get public_service_rules_desc => 'Règles et recommandations.';

  @override
  String public_copyright(int year) {
    return '© $year BF Stay • Tous droits réservés';
  }

  @override
  String get public_access_booking => 'Accéder à ma réservation';

  @override
  String staff_dashboard_greeting(String name) {
    return 'Bonjour $name';
  }

  @override
  String get staff_dashboard_control_panel => 'Panneau de contrôle';

  @override
  String get staff_dashboard_daily_summary => 'Résumé journalier';

  @override
  String get staff_dashboard_occupancy => 'Occupation';

  @override
  String get staff_dashboard_pending => 'En attente';

  @override
  String get staff_dashboard_pending_checkin => 'Check-ins en attente';

  @override
  String get staff_dashboard_pending_checkout => 'Check-outs en attente';

  @override
  String get staff_dashboard_pending_tasks => 'Tâches en attente';

  @override
  String get staff_dashboard_checkins_today => 'Check-ins aujourd\'hui';

  @override
  String get staff_dashboard_checkouts_today => 'Check-outs aujourd\'hui';

  @override
  String get staff_dashboard_quick_actions => 'Actions rapides';

  @override
  String get staff_dashboard_manage_checkins => 'Gérer les check-ins';

  @override
  String get staff_dashboard_view_guests => 'Voir les clients';

  @override
  String staff_dashboard_room_extras(String room) {
    return 'Chambre $room - Extras';
  }

  @override
  String get staff_dashboard_cleaning_request => 'Demande de nettoyage';

  @override
  String staff_dashboard_room_guest(String room, String guest) {
    return 'Chambre $room - $guest';
  }

  @override
  String get staff_dashboard_generate_report => 'Générer un rapport';

  @override
  String get staff_checkins_title => 'Check-ins';

  @override
  String get staff_checkins_tab_pending => 'En attente';

  @override
  String get staff_checkins_tab_in_progress => 'En cours';

  @override
  String get staff_checkins_tab_completed => 'Terminés';

  @override
  String get staff_checkins_status_pending => 'En attente';

  @override
  String get staff_checkins_status_in_progress => 'En cours';

  @override
  String get staff_checkins_status_completed => 'Terminé';

  @override
  String get staff_checkins_start => 'Démarrer';

  @override
  String get staff_checkins_new_checkin => 'Nouveau check-in';

  @override
  String get staff_checkins_complete => 'Terminer';

  @override
  String get staff_checkins_view_details => 'Voir les détails';

  @override
  String get guest_access_wifi_password_label => 'Mot de passe WiFi';

  @override
  String get guest_access_locker_provided_by_staff => 'Fourni par le personnel';

  @override
  String get guest_access_rule_smoke_free_title => 'Non-fumeur';

  @override
  String get guest_accommodation_view_rules_pdf => 'Voir le règlement en PDF';

  @override
  String get public_hero_title_line1 => 'Votre séjour,';

  @override
  String get public_hero_title_line2 => 'Élevé';

  @override
  String get admin_booking_send_whatsapp_title =>
      'Envoyer le code par WhatsApp';

  @override
  String get admin_booking_send_whatsapp_no_phone =>
      'Le client n\'a pas de numéro de téléphone';

  @override
  String get admin_booking_send_whatsapp_no_phone_desc =>
      'Entrez un numéro de téléphone pour envoyer le code par WhatsApp.';

  @override
  String get admin_booking_send_whatsapp_phone_hint => '+33 6 00 00 00 00';

  @override
  String get admin_booking_send_whatsapp_error =>
      'Impossible d\'ouvrir WhatsApp';

  @override
  String admin_booking_send_whatsapp_message(
    String propertyName,
    String bookingCode,
    String checkIn,
    String checkOut,
  ) {
    return '🏠 *$propertyName*\n📋 Réservation : *$bookingCode*\n📅 Check-in : $checkIn\n📅 Check-out : $checkOut\n\nTéléchargez l\'application BF Stay pour gérer votre séjour.';
  }
}
