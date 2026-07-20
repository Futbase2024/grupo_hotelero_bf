// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get guest_romantic_request_sent =>
      'Hemos avisado al alojamiento. Te contactarán para confirmar los detalles.';

  @override
  String get guest_romantic_request_error =>
      'No se pudo registrar tu solicitud. Inténtalo de nuevo.';

  @override
  String get common_app_name => 'BF Stay';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_exit => 'Salir';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_loading => 'Cargando...';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_accept => 'Aceptar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_back => 'Volver';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Éxito';

  @override
  String get common_no_data => 'No hay datos';

  @override
  String get common_yes => 'Sí';

  @override
  String get common_no => 'No';

  @override
  String get common_send => 'Enviar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_later => 'Más tarde';

  @override
  String get common_update => 'Actualizar';

  @override
  String get common_understood => 'Entendido';

  @override
  String get common_exit_app_title => 'Salir de BF Stay';

  @override
  String get common_exit_app_message =>
      '¿Estás seguro de que deseas salir de la aplicación?\n\nTu sesión permanecerá activa cuando vuelvas a entrar.';

  @override
  String get common_logout_title => 'Cerrar sesión';

  @override
  String get common_logout_message =>
      '¿Estás seguro de que deseas cerrar sesión?\n\nPodrás volver a acceder con tu código de reserva cuando lo necesites.';

  @override
  String get common_logout_button => 'Cerrar sesión';

  @override
  String get common_splash_ready => 'Listo';

  @override
  String get common_splash_loading => 'Cargando...';

  @override
  String get common_update_force_title => 'Actualización Requerida';

  @override
  String get common_update_available_title => 'Nueva Versión Disponible';

  @override
  String get common_update_force_message =>
      'Es necesario actualizar la aplicación para continuar usándola. Esta versión incluye mejoras importantes y correcciones de seguridad.';

  @override
  String get common_update_available_message =>
      'Hay una nueva versión disponible con mejoras y correcciones. ¿Deseas actualizar ahora?';

  @override
  String common_update_version(String version) {
    return 'Versión $version';
  }

  @override
  String get common_page_not_found => 'Página no encontrada';

  @override
  String get common_invalid_route => 'Ruta no válida';

  @override
  String get common_back_to_home => 'Volver al inicio';

  @override
  String get common_theme_light => 'Claro';

  @override
  String get common_theme_dark => 'Oscuro';

  @override
  String get common_theme_mode_light => 'Modo Claro';

  @override
  String get common_theme_mode_dark => 'Modo Oscuro';

  @override
  String get common_theme_system => 'Sistema';

  @override
  String get common_theme_app_label => 'Tema de la aplicación';

  @override
  String common_copied_to_clipboard(String type) {
    return '$type copiado al portapapeles';
  }

  @override
  String get common_phone_type => 'Teléfono';

  @override
  String get common_email_type => 'Email';

  @override
  String get enum_booking_status_created => 'Creada';

  @override
  String get enum_booking_status_confirmed => 'Confirmada';

  @override
  String get enum_booking_status_active => 'Activa';

  @override
  String get enum_booking_status_in_house => 'En casa';

  @override
  String get enum_booking_status_checked_out => 'Finalizada';

  @override
  String get enum_booking_status_closed => 'Cerrada';

  @override
  String get enum_booking_status_cancelled => 'Cancelada';

  @override
  String get enum_booking_status_created_desc =>
      'Reserva creada, pendiente de confirmación';

  @override
  String get enum_booking_status_confirmed_desc =>
      'Reserva confirmada, pendiente de check-in';

  @override
  String get enum_booking_status_active_desc =>
      'Check-in validado, panel completo accesible';

  @override
  String get enum_booking_status_in_house_desc =>
      'Huésped físicamente en el alojamiento';

  @override
  String get enum_booking_status_checked_in_legacy_desc =>
      'Check-in validado (legacy)';

  @override
  String get enum_booking_status_checked_out_desc =>
      'Check-out realizado, huésped ha salido';

  @override
  String get enum_booking_status_closed_desc => 'Reserva finalizada y cerrada';

  @override
  String get enum_booking_status_cancelled_desc => 'Reserva cancelada';

  @override
  String get enum_checkin_status_not_started => 'Pendiente';

  @override
  String get enum_checkin_status_in_progress => 'En progreso';

  @override
  String get enum_checkin_status_submitted => 'Enviado';

  @override
  String get enum_checkin_status_validated => 'Validado';

  @override
  String get enum_checkin_status_rejected => 'Rechazado';

  @override
  String get enum_checkin_status_cancelled => 'Cancelado';

  @override
  String get enum_checkin_status_not_started_desc =>
      'El huésped aún no ha iniciado el check-in';

  @override
  String get enum_checkin_status_in_progress_desc =>
      'El huésped está completando sus datos';

  @override
  String get enum_checkin_status_submitted_desc =>
      'Pendiente de revisión por el administrador';

  @override
  String get enum_checkin_status_validated_desc =>
      'Check-in validado, estancia autorizada';

  @override
  String get enum_checkin_status_rejected_desc =>
      'Requiere corrección por el huésped';

  @override
  String get enum_checkin_status_cancelled_desc =>
      'Reserva cancelada, contacte con recepción';

  @override
  String get enum_checkout_status_not_started => 'Sin iniciar';

  @override
  String get enum_checkout_status_requested => 'Solicitado';

  @override
  String get enum_checkout_status_validated => 'Validado';

  @override
  String get enum_checkout_status_rejected => 'Rechazado';

  @override
  String get enum_checkout_status_not_started_desc =>
      'La estancia aún está en curso';

  @override
  String get enum_checkout_status_requested_desc =>
      'El huésped ha solicitado el check-out';

  @override
  String get enum_checkout_status_validated_desc =>
      'Check-out validado, reserva lista para cerrar';

  @override
  String get enum_checkout_status_rejected_desc =>
      'Hay incidencias que resolver';

  @override
  String get public_badge_exclusivity => 'EXCLUSIVIDAD GARANTIZADA';

  @override
  String get public_hero_title_prefix => 'Tu Estancia, ';

  @override
  String get public_hero_title_suffix => 'Elevada';

  @override
  String get public_cta_access_booking => 'Acceder a mi Reserva';

  @override
  String get public_services_section_title => 'Nuestros Servicios';

  @override
  String get public_footer_brand_name => 'BF STAY';

  @override
  String public_footer_copyright(int year) {
    return '© $year BF Stay • Todos los derechos reservados';
  }

  @override
  String get public_footer_privacy_policy => 'Política de Privacidad';

  @override
  String get public_service_checkin_title => 'Check-in Digital';

  @override
  String get public_service_checkin_desc => 'Registro de entrada sin esperas.';

  @override
  String get public_service_checkout_title => 'Check-out Digital';

  @override
  String get public_service_checkout_desc => 'Salida rápida y sencilla.';

  @override
  String get public_service_house_rules_title => 'Normas de la Casa';

  @override
  String get public_service_house_rules_desc => 'Reglas y recomendaciones.';

  @override
  String get public_service_what_to_see_title => '¿Qué ver?';

  @override
  String get public_service_what_to_see_desc => 'Lugares de interés cercanos.';

  @override
  String get public_service_parking_title => 'Aparcamientos';

  @override
  String get public_service_parking_desc => 'Opciones de parking.';

  @override
  String get public_service_chat_title => 'Chat';

  @override
  String get public_service_chat_desc => 'Conserje virtual 24/7.';

  @override
  String get public_service_accommodations_title => 'Alojamientos';

  @override
  String get public_service_accommodations_desc => 'Otras propiedades.';

  @override
  String get public_service_reviews_title => 'Reseñas';

  @override
  String get public_service_reviews_desc => 'Opiniones de huéspedes.';

  @override
  String get public_service_parking_title_light => 'Aparcamientos Cercanos';

  @override
  String get public_service_accommodations_title_light =>
      'Nuestros Alojamientos';

  @override
  String get public_service_accommodations_desc_light =>
      'Otras propiedades disponibles.';

  @override
  String get public_service_reviews_title_light => 'Reseñas y Comentarios';

  @override
  String get public_hero_subtitle =>
      'Gestión inteligente para alojamientos exclusivos.';

  @override
  String get auth_login_brand_name => 'BF Stay';

  @override
  String get auth_login_subtitle => 'Panel de Control';

  @override
  String get auth_feature_bookings => 'Gestión de reservas';

  @override
  String get auth_feature_checkin => 'Check-in digital';

  @override
  String get auth_feature_chat => 'Chat con huéspedes';

  @override
  String get auth_feature_keyless => 'Acceso sin llaves';

  @override
  String get auth_field_email => 'Email';

  @override
  String get auth_field_password => 'Contraseña';

  @override
  String get auth_validation_email_required => 'Por favor ingresa tu email';

  @override
  String get auth_validation_email_invalid =>
      'Por favor ingresa un email válido';

  @override
  String get auth_validation_password_required =>
      'Por favor ingresa tu contraseña';

  @override
  String get auth_validation_password_min_length =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get auth_forgot_password => '¿Olvidaste tu contraseña?';

  @override
  String get auth_login_button => 'Iniciar Sesión';

  @override
  String get auth_divider_or => 'o';

  @override
  String get auth_guest_access_button => 'Acceso con código de reserva';

  @override
  String get auth_login_footer => 'BF Stay © 2026';

  @override
  String get auth_recover_password_title => 'Recuperar Contraseña';

  @override
  String get auth_recover_password_body =>
      'Ingresa tu email y te enviaremos instrucciones para restablecer tu contraseña.';

  @override
  String get auth_recover_password_sent => 'Email de recuperación enviado';

  @override
  String get auth_button_send => 'Enviar';

  @override
  String get auth_booking_access_title => 'Acceso de Huésped';

  @override
  String get auth_booking_benefit_code => 'Código de reserva';

  @override
  String get auth_booking_benefit_personal => 'Acceso personalizado';

  @override
  String get auth_booking_benefit_instant => 'Acceso instantáneo';

  @override
  String get auth_booking_benefit_secure_checkin => 'Check-in seguro';

  @override
  String get auth_booking_code_info_short =>
      'El código de reserva lo recibiste en el email de confirmación.';

  @override
  String get auth_booking_code_info_full =>
      'El código de reserva lo recibiste en el email de confirmación de tu reserva.';

  @override
  String get auth_booking_desktop_subtitle =>
      'Disfruta de tu estancia con acceso digital';

  @override
  String get auth_booking_form_subtitle =>
      'Ingresa tu código de reserva para acceder a tu alojamiento';

  @override
  String get auth_booking_field_code => 'Código de Reserva';

  @override
  String get auth_booking_code_hint => 'XX-XXXX-XXXX';

  @override
  String get auth_booking_validation_code_required =>
      'Por favor ingresa tu código de reserva';

  @override
  String get auth_booking_validation_code_invalid =>
      'El formato del código no es válido';

  @override
  String get auth_booking_access_button => 'Acceder';

  @override
  String get auth_booking_help_title => '¿Dónde encuentro mi código?';

  @override
  String get auth_booking_help_body =>
      'El código de reserva lo recibiste en el email de confirmación de tu reserva. Tiene el formato BF-XXXXX.';

  @override
  String get auth_booking_footer => 'BF Stay © 2026';

  @override
  String get auth_booking_error_title => 'Error de Acceso';

  @override
  String get auth_booking_error_code_not_found =>
      'El código de reserva no existe. Por favor, verifica que lo hayas escrito correctamente.';

  @override
  String get auth_booking_error_code_expired =>
      'Este código de reserva ha expirado. Contacta con recepción para obtener uno nuevo.';

  @override
  String get auth_booking_error_email_mismatch =>
      'El email no coincide con el de la reserva. Verifica que sea el mismo email que usaste al reservar.';

  @override
  String get auth_booking_error_generic =>
      'No se pudo verificar el código de reserva. Por favor, inténtalo de nuevo.';

  @override
  String get auth_booking_error_dismiss => 'Entendido';

  @override
  String get auth_sheet_title => 'Acceso a tu reserva';

  @override
  String get auth_sheet_subtitle =>
      'Introduce tu correo y el código que recibiste';

  @override
  String get auth_sheet_label_email => 'CORREO ELECTRÓNICO';

  @override
  String get auth_sheet_hint_email => 'tu@correo.com';

  @override
  String get auth_sheet_label_code => 'CÓDIGO DE RESERVA';

  @override
  String get auth_sheet_hint_code => 'BF-XXXX-XXXX';

  @override
  String get auth_sheet_submit_button => 'Acceder a mi reserva';

  @override
  String get auth_sheet_help_text =>
      '¿No tienes tu código? Contacta con tu alojamiento';

  @override
  String get auth_admin_sheet_title => 'Acceso privado';

  @override
  String get auth_admin_sheet_subtitle => 'Solo personal autorizado de BF-Stay';

  @override
  String get auth_admin_label_email => 'CORREO ELECTRÓNICO';

  @override
  String get auth_admin_hint_email => 'admin@bfstay.com';

  @override
  String get auth_admin_label_password => 'CONTRASEÑA';

  @override
  String get auth_admin_hint_password => '••••••••';

  @override
  String get auth_admin_error_unauthorized => 'No tienes acceso a este panel';

  @override
  String get auth_admin_submit_button => 'Acceder al panel';

  @override
  String get guest_settings_title => 'Ajustes';

  @override
  String get guest_settings_section_language => 'Idioma';

  @override
  String get guest_settings_language_title => 'Idioma de la aplicación';

  @override
  String get guest_settings_language_subtitle =>
      'Selecciona el idioma de la interfaz';

  @override
  String get guest_settings_section_legal => 'Legal';

  @override
  String get guest_settings_privacy_policy_title => 'Política de Privacidad';

  @override
  String get guest_settings_privacy_policy_subtitle =>
      'Consulta nuestra política de privacidad';

  @override
  String get guest_settings_privacy_open_error =>
      'No se pudo abrir la política de privacidad';

  @override
  String get notification_channel_name => 'BF Stay Notificaciones';

  @override
  String get notification_channel_description =>
      'Canal de notificaciones de BF Stay';

  @override
  String get notification_checkin_validated_title => '✅ Check-in Validado';

  @override
  String get notification_checkin_validated_body =>
      'Tu check-in ha sido validado correctamente. ¡Bienvenido!';

  @override
  String get notification_checkin_rejected_title => '❌ Check-in Rechazado';

  @override
  String get notification_checkin_rejected_body =>
      'Tu check-in ha sido rechazado. Por favor, revisa tu documentación.';

  @override
  String notification_checkin_rejected_body_with_reason(String reason) {
    return 'Tu check-in ha sido rechazado: $reason';
  }

  @override
  String get notification_booking_cancelled_title => '🚫 Reserva Cancelada';

  @override
  String get notification_booking_cancelled_body =>
      'Tu reserva ha sido cancelada. Contacta con recepción.';

  @override
  String notification_booking_cancelled_body_with_reason(String reason) {
    return 'Tu reserva ha sido cancelada: $reason';
  }

  @override
  String get notification_checkin_status_update_title =>
      '📋 Actualización de Check-in';

  @override
  String notification_checkin_status_update_body(String status) {
    return 'El estado de tu check-in ha cambiado a: $status';
  }

  @override
  String get notification_admin_checkin_submitted_title =>
      '📝 Nuevo Check-in Pendiente';

  @override
  String notification_admin_checkin_submitted_body(
    String guestName,
    String unitName,
  ) {
    return '$guestName ha enviado su check-in para $unitName. Pendiente de revisión.';
  }

  @override
  String get guest_parking_title => 'Parkings';

  @override
  String get guest_parking_available_singular => 'parking disponible';

  @override
  String get guest_parking_available_plural => 'parkings disponibles';

  @override
  String get guest_parking_error_loading => 'Error al cargar';

  @override
  String get guest_parking_empty_title => 'No hay parkings';

  @override
  String get guest_parking_empty_subtitle =>
      'Pronto añadiremos información de parkings cercanos';

  @override
  String guest_parking_for_unit(String unitName) {
    return 'Parkings para $unitName';
  }

  @override
  String guest_parking_gps_label(String label) {
    return 'GPS: $label';
  }

  @override
  String get guest_parking_info_zones_title =>
      'INFORMACIÓN ZONAS DE APARCAMIENTO';

  @override
  String get guest_parking_plaza_arenal_title => 'PARKING PLAZA ARENAL';

  @override
  String get guest_parking_plaza_arenal_subtitle => 'A unos 5 minutos andando';

  @override
  String get guest_parking_plaza_arenal_content =>
      '• Abonando la estancia a través de la app El Parking: 6,95€/24h\n• Reservando a través de su web: 8€/24h (mínimo 24h)\n• Abonando el ticket en la máquina: 16€/24h';

  @override
  String get guest_parking_centro_title => 'PARKING EN ZONA CENTRO';

  @override
  String get guest_parking_centro_subtitle => 'O.R.A AZUL';

  @override
  String get guest_parking_centro_content =>
      '• Lunes a Viernes: 9:00 - 13:30 y 17:00 - 20:00\n• Sábados: 9:00 - 14:00\n• Julio y Agosto: 9:00 - 14:00';

  @override
  String get guest_parking_free_zone_title => 'PARKING ZONA GRATUITA';

  @override
  String get guest_parking_free_zone_subtitle => 'A unos 10 minutos andando';

  @override
  String get guest_parking_free_zone_content =>
      'Zona libre de estacionamiento rotativo.';

  @override
  String get guest_checkin_camera_not_available => 'No hay cámaras disponibles';

  @override
  String guest_checkin_camera_init_error(String error) {
    return 'Error al inicializar cámara: $error';
  }

  @override
  String guest_checkin_camera_capture_error(String error) {
    return 'Error al capturar: $error';
  }

  @override
  String get guest_checkin_camera_scan_title => 'Escanear Documento';

  @override
  String get guest_checkin_camera_starting => 'Iniciando cámara...';

  @override
  String get guest_checkin_camera_frame_hint =>
      'Encuadra el documento dentro del recuadro';

  @override
  String get guest_checkin_camera_document_label => 'Documento de Identidad';

  @override
  String get admin_chat_messages => 'Mensajes';

  @override
  String get admin_chat_conversation_deleted => 'Conversación eliminada';

  @override
  String get admin_chat_empty_title => 'Sin conversaciones';

  @override
  String get admin_chat_empty_subtitle =>
      'Las conversaciones con huéspedes\naparecerán aquí';

  @override
  String get guest_chat_input_hint => 'Escribe un mensaje...';

  @override
  String get admin_booking_detail_title => 'Detalle de Reserva';

  @override
  String get admin_booking_not_found => 'Reserva no encontrada';

  @override
  String admin_booking_error(String error) {
    return 'Error: $error';
  }

  @override
  String admin_booking_error_validating(String error) {
    return 'Error al validar: $error';
  }

  @override
  String admin_booking_error_rejecting(String error) {
    return 'Error al rechazar: $error';
  }

  @override
  String admin_booking_error_validating_checkout(String error) {
    return 'Error al validar check-out: $error';
  }

  @override
  String admin_booking_error_rejecting_checkout(String error) {
    return 'Error al rechazar check-out: $error';
  }

  @override
  String admin_booking_error_closing(String error) {
    return 'Error al cerrar reserva: $error';
  }

  @override
  String admin_booking_error_cancelling(String error) {
    return 'Error al cancelar reserva: $error';
  }

  @override
  String admin_booking_error_deleting(String error) {
    return 'Error al eliminar reserva: $error';
  }

  @override
  String admin_booking_error_updating(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String get admin_booking_resend_error => 'No se pudo reenviar el código';

  @override
  String get admin_booking_notification_sent =>
      'Notificación enviada correctamente';

  @override
  String get admin_booking_notification_error =>
      'Error al enviar la notificación';

  @override
  String get admin_booking_code_resent => 'Código reenviado correctamente';

  @override
  String get admin_booking_checkin_validated =>
      'Check-in validado correctamente';

  @override
  String get admin_booking_checkin_rejected => 'Check-in rechazado';

  @override
  String get admin_booking_checkout_validated =>
      'Check-out validado correctamente';

  @override
  String get admin_booking_checkout_rejected => 'Check-out rechazado';

  @override
  String get admin_booking_incidents_detected => 'Incidencias detectadas';

  @override
  String get admin_booking_closed_successfully =>
      'Reserva cerrada correctamente';

  @override
  String get admin_booking_cancelled_successfully =>
      'Reserva cancelada correctamente';

  @override
  String get admin_booking_deleted_successfully =>
      'Reserva eliminada correctamente';

  @override
  String get admin_booking_keybox_updated => 'Código keybox actualizado';

  @override
  String get admin_booking_already_closed_title => 'Reserva ya cerrada';

  @override
  String get admin_booking_already_closed_message =>
      'Esta reserva ya se encuentra cerrada.';

  @override
  String get admin_booking_already_cancelled_title => 'Reserva ya cancelada';

  @override
  String get admin_booking_already_cancelled_message =>
      'Esta reserva ya se encuentra cancelada.';

  @override
  String get admin_booking_cannot_delete_title => 'No se puede eliminar';

  @override
  String admin_booking_cannot_delete_message(String status) {
    return 'No se puede eliminar una reserva en estado $status.';
  }

  @override
  String get admin_booking_cancel_booking => 'Cancelar Reserva';

  @override
  String get admin_booking_cancel_booking_confirm =>
      '¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.';

  @override
  String get admin_booking_no_keep => 'No, mantener';

  @override
  String get admin_booking_yes_cancel => 'Sí, cancelar';

  @override
  String get admin_booking_delete_booking => 'Eliminar Reserva';

  @override
  String get admin_booking_delete_confirm =>
      '¿Estás seguro de que deseas eliminar completamente esta reserva y todos sus datos asociados? Esta acción es irreversible.';

  @override
  String get admin_booking_close_booking => 'Cerrar Reserva';

  @override
  String get admin_booking_close_confirm =>
      '¿Deseas cerrar manualmente esta reserva? Se registrará la fecha de cierre.';

  @override
  String get admin_booking_close_notes_hint => 'Notas de cierre (opcional)';

  @override
  String get admin_booking_reject_checkout => 'Rechazar Check-out';

  @override
  String get admin_booking_reject_checkout_desc =>
      'Indica las incidencias detectadas para rechazar el check-out.';

  @override
  String get admin_booking_incidents_hint =>
      'Describe las incidencias detectadas...';

  @override
  String get admin_booking_reject => 'Rechazar';

  @override
  String get admin_booking_reject_checkin => 'Rechazar Check-in';

  @override
  String get admin_booking_reject_checkin_desc =>
      'Indica el motivo del rechazo del check-in.';

  @override
  String get admin_booking_reject_reason_hint =>
      'Motivo del rechazo (opcional)...';

  @override
  String admin_booking_share_code_message(String code) {
    return 'Tu código de acceso es: $code';
  }

  @override
  String admin_booking_share_keybox_code(String code) {
    return 'Código keybox: $code';
  }

  @override
  String admin_booking_share_dates(String checkIn, String checkOut) {
    return 'Check-in: $checkIn | Check-out: $checkOut';
  }

  @override
  String get admin_booking_share_download_app => 'Descarga la app: BF Stay';

  @override
  String get admin_booking_edit_keybox_title => 'Código Keybox';

  @override
  String get admin_booking_edit_keybox_desc =>
      'Introduce el código de la caja de llaves';

  @override
  String get admin_booking_checkin_done => 'Check-in realizado';

  @override
  String get admin_booking_checkout_done => 'Check-out realizado';

  @override
  String get admin_booking_units_label => 'habitaciones';

  @override
  String get admin_booking_email_sent => 'Email enviado';

  @override
  String get admin_booking_email_pending => 'Email pendiente';

  @override
  String get admin_booking_code_used => 'Código usado';

  @override
  String get admin_booking_code_unused => 'Código sin usar';

  @override
  String get admin_booking_checkin_ok => 'Check-in OK';

  @override
  String get admin_booking_checkin_pending => 'Pendiente validación';

  @override
  String get admin_booking_checkin_in_progress => 'En progreso';

  @override
  String get admin_booking_no_checkin => 'Sin check-in';

  @override
  String get admin_booking_guest_section => 'HUÉSPED';

  @override
  String get admin_booking_no_name => 'Sin nombre';

  @override
  String get admin_booking_reservation_section => 'RESERVA';

  @override
  String get admin_booking_checkin_label => 'Check-in';

  @override
  String get admin_booking_checkout_label => 'Check-out';

  @override
  String get admin_booking_night_singular => 'noche';

  @override
  String get admin_booking_night_plural => 'noches';

  @override
  String get admin_booking_years_label => 'años';

  @override
  String get admin_booking_rooms_section => 'Habitaciones';

  @override
  String get admin_booking_wifi_label => 'WiFi';

  @override
  String get admin_booking_wifi_network_label => 'Red:';

  @override
  String get admin_booking_wifi_password_label => 'Contraseña:';

  @override
  String get admin_booking_wifi_password_clipboard => 'Contraseña WiFi';

  @override
  String get admin_booking_access_code_label => 'Código de acceso';

  @override
  String get admin_booking_access_code_clipboard => 'Código de acceso';

  @override
  String get admin_booking_access_instructions_label =>
      'Instrucciones de acceso';

  @override
  String get admin_booking_access_codes_section => 'CÓDIGOS DE ACCESO';

  @override
  String get admin_booking_reservation_code_label => 'Código de reserva';

  @override
  String get admin_booking_share_button => 'Compartir';

  @override
  String get admin_booking_keybox_not_set => 'No configurado';

  @override
  String get admin_booking_keybox_code_label => 'Código Keybox';

  @override
  String get admin_booking_keybox_code_clipboard => 'Código Keybox';

  @override
  String get admin_booking_checkin_not_started => 'Check-in no iniciado';

  @override
  String get admin_booking_checkin_validated_status => 'Check-in validado';

  @override
  String get admin_booking_checkin_rejected_status => 'Check-in rechazado';

  @override
  String get admin_booking_checkin_pending_validation =>
      'Pendiente de validación';

  @override
  String get admin_booking_checkin_in_progress_status => 'Check-in en progreso';

  @override
  String get admin_booking_checkin_section => 'CHECK-IN';

  @override
  String get admin_booking_docs_pending => 'documentos pendientes';

  @override
  String get admin_booking_validate_button => 'Validar';

  @override
  String get admin_booking_reject_button => 'Rechazar';

  @override
  String get admin_booking_internal_notes_section => 'NOTAS INTERNAS';

  @override
  String get admin_booking_closed_status => 'Reserva cerrada';

  @override
  String get admin_booking_checkout_validated_status => 'Check-out validado';

  @override
  String get admin_booking_checkout_incidents_status =>
      'Check-out con incidencias';

  @override
  String get admin_booking_checkout_requested_status => 'Check-out solicitado';

  @override
  String get admin_booking_checkout_pending_status => 'Check-out pendiente';

  @override
  String get admin_booking_checkout_section => 'CHECK-OUT';

  @override
  String get admin_booking_requested_label => 'Solicitado:';

  @override
  String get admin_booking_notes_label => 'Notas:';

  @override
  String get admin_booking_incidents_button => 'Incidencias';

  @override
  String get admin_booking_close_booking_button => 'Cerrar Reserva';

  @override
  String get admin_booking_close_booking_description =>
      'El huésped no ha solicitado check-out. Puedes cerrar la reserva manualmente.';

  @override
  String get admin_booking_signature_section => 'FIRMA DEL TITULAR';

  @override
  String get admin_booking_signature_unavailable => 'Firma no disponible';

  @override
  String get admin_booking_actions_section => 'ACCIONES';

  @override
  String get admin_booking_resend_code_title => 'Reenviar código por email';

  @override
  String get admin_booking_last_sent_label => 'Último envío:';

  @override
  String get admin_booking_na => 'N/A';

  @override
  String get admin_booking_not_sent_yet => 'Aún no se ha enviado';

  @override
  String get admin_booking_room_ready_title => 'Habitación disponible';

  @override
  String get admin_booking_room_ready_subtitle =>
      'Notifica al huésped que la habitación está lista y puede acceder';

  @override
  String get admin_booking_cancel_booking_title => 'Cancelar reserva';

  @override
  String get admin_booking_cancel_booking_subtitle =>
      'Marca la reserva como cancelada';

  @override
  String get admin_booking_delete_booking_title => 'Eliminar reserva';

  @override
  String get admin_booking_delete_booking_subtitle =>
      'Borra completamente la reserva y sus datos (solo si no está finalizada)';

  @override
  String get admin_dashboard_admin_title => 'BF-Stay Admin';

  @override
  String get admin_dashboard_tab_summary => 'Resumen';

  @override
  String get admin_dashboard_tab_bookings => 'Reservas';

  @override
  String get admin_dashboard_tab_checkins => 'Check-ins';

  @override
  String get admin_dashboard_tab_invoices => 'Facturas';

  @override
  String get admin_dashboard_tab_marketing => 'Marketing';

  @override
  String get admin_dashboard_tab_properties => 'Alojamientos';

  @override
  String get guest_reviews_title => 'Reseñas';

  @override
  String get guest_reviews_write_review => 'Escribir reseña';

  @override
  String get guest_reviews_published => 'Reseña publicada correctamente';

  @override
  String get guest_reviews_publishing => 'Publicando reseña...';

  @override
  String get guest_reviews_updating => 'Actualizando reseña...';

  @override
  String get guest_reviews_deleting => 'Eliminando reseña...';

  @override
  String get guest_reviews_loading => 'Cargando reseñas...';

  @override
  String get guest_reviews_delete_review => 'Eliminar reseña';

  @override
  String get guest_reviews_delete_confirm =>
      '¿Estás seguro de que quieres eliminar tu reseña? Esta acción no se puede deshacer.';

  @override
  String get guest_reviews_filter_all => 'Todas';

  @override
  String get guest_reviews_edit_review => 'Editar reseña';

  @override
  String get guest_reviews_new_review => 'Nueva reseña';

  @override
  String get guest_reviews_updated => 'Reseña actualizada';

  @override
  String get guest_reviews_info_public =>
      'Tu reseña será pública y ayudará a otros huéspedes a tomar decisiones.';

  @override
  String get guest_reviews_your_rating => 'Tu valoración';

  @override
  String get guest_reviews_tap_stars => 'Toca las estrellas para puntuar';

  @override
  String get guest_reviews_rating_1 => 'Muy malo';

  @override
  String get guest_reviews_rating_2 => 'Malo';

  @override
  String get guest_reviews_rating_3 => 'Regular';

  @override
  String get guest_reviews_rating_4 => 'Bueno';

  @override
  String get guest_reviews_rating_5 => 'Excelente';

  @override
  String get guest_reviews_title_label => 'Título (opcional)';

  @override
  String get guest_reviews_title_hint => 'Resume tu experiencia en una frase';

  @override
  String get guest_reviews_comment_required =>
      'Por favor, escribe un comentario';

  @override
  String get guest_reviews_comment_min_length =>
      'El comentario debe tener al menos 10 caracteres';

  @override
  String get guest_reviews_comment_label => 'Tu comentario *';

  @override
  String get guest_reviews_comment_hint => 'Cuéntanos tu experiencia...';

  @override
  String get guest_reviews_save_changes => 'Guardar cambios';

  @override
  String get guest_reviews_publish_review => 'Publicar reseña';

  @override
  String get guest_reviews_select_rating =>
      'Por favor, selecciona una puntuación';

  @override
  String get guest_reviews_saving => 'Guardando...';

  @override
  String get guest_alojamientos_title => 'Nuestros Alojamientos';

  @override
  String get guest_alojamientos_error_title => 'Error al cargar';

  @override
  String get guest_alojamientos_empty_title => 'No hay alojamientos';

  @override
  String get guest_alojamientos_empty_subtitle =>
      'No hay alojamientos disponibles en este momento';

  @override
  String guest_alojamientos_room_count(int count) {
    return '$count habitaciones';
  }

  @override
  String get guest_alojamiento_detail_title => 'Detalle';

  @override
  String get guest_alojamiento_units_available => 'Unidades disponibles';

  @override
  String get guest_alojamiento_no_units => 'No hay unidades disponibles';

  @override
  String get guest_alojamiento_location => 'Ubicación';

  @override
  String get guest_alojamiento_common_areas => 'Zonas Comunes';

  @override
  String get guest_alojamiento_shared_spaces => 'Espacios compartidos';

  @override
  String get guest_alojamiento_common_areas_subtitle =>
      'Disfruta de las áreas comunes del hotel';

  @override
  String get guest_alojamiento_no_photos => 'No hay fotos';

  @override
  String get guest_alojamiento_no_photos_subtitle =>
      'No se encontraron fotos de zonas comunes';

  @override
  String guest_alojamiento_photos_count(int count) {
    return '$count fotos';
  }

  @override
  String get guest_alojamiento_hotel_rooms_title => 'Hotel Boutique Jerez';

  @override
  String get guest_alojamiento_no_rooms => 'No hay habitaciones';

  @override
  String get guest_alojamiento_no_rooms_subtitle =>
      'No hay habitaciones disponibles en este momento';

  @override
  String get guest_alojamiento_rooms => 'Habitaciones';

  @override
  String get guest_alojamiento_features => 'Características';

  @override
  String get guest_alojamiento_feature_flexible_checkin => 'Check-in flexible';

  @override
  String get guest_alojamiento_feature_wifi => 'WiFi gratuito';

  @override
  String get guest_alojamiento_feature_ac => 'Aire acondicionado';

  @override
  String get guest_alojamiento_description => 'Descripción';

  @override
  String guest_alojamiento_description_text(String unitType) {
    return 'Descubre este $unitType completamente equipado para que tu estancia sea lo más cómoda posible. Cuenta con todo lo necesario para disfrutar de Jerez a tu ritmo.';
  }

  @override
  String get guest_alojamiento_services => 'Servicios incluidos';

  @override
  String get guest_alojamiento_service_kitchen => 'Cocina equipada';

  @override
  String get guest_alojamiento_service_washer => 'Lavadora';

  @override
  String get guest_alojamiento_service_tv => 'Smart TV';

  @override
  String get guest_alojamiento_service_bedding => 'Ropa de cama';

  @override
  String get guest_alojamiento_service_towels => 'Toallas';

  @override
  String get guest_alojamiento_service_coffee => 'Cafetera';

  @override
  String get guest_alojamiento_access_info => 'Información de acceso';

  @override
  String get guest_alojamiento_box_location => 'Ubicación de la caja';

  @override
  String get guest_alojamiento_access_instructions => 'Instrucciones de acceso';

  @override
  String get guest_house_rules_title => 'Normas de la Casa';

  @override
  String get guest_house_rules_subtitle =>
      'Consulta las normas y recomendaciones';

  @override
  String get guest_house_rules_empty_title => 'No hay normas';

  @override
  String get guest_house_rules_empty_subtitle =>
      'Este alojamiento no tiene normas registradas';

  @override
  String get guest_normas_title => 'Normas';

  @override
  String get guest_normas_hotel_title => 'Normas del Hotel';

  @override
  String get guest_normas_apartment_title => 'Normas del Apartamento';

  @override
  String get guest_normas_not_available => 'No hay normas disponibles';

  @override
  String get guest_normas_image_error => 'No se pudo cargar la imagen';

  @override
  String get guest_normas_generic_error => 'Ha ocurrido un error';

  @override
  String get guest_que_ver_title => '¿Qué ver?';

  @override
  String get guest_que_ver_clear_filters => 'Limpiar';

  @override
  String guest_que_ver_places_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares',
      one: '1 lugar',
    );
    return '$_temp0';
  }

  @override
  String get guest_que_ver_no_results => 'Sin resultados';

  @override
  String get guest_que_ver_no_places => 'No hay lugares';

  @override
  String get guest_que_ver_try_filters =>
      'Prueba a cambiar los filtros de búsqueda';

  @override
  String get guest_que_ver_coming_soon => 'Pronto añadiremos nuevos lugares';

  @override
  String get guest_que_ver_error_loading => 'Error al cargar el lugar';

  @override
  String get guest_que_ver_place_not_found => 'Lugar no encontrado';

  @override
  String get guest_que_ver_about_place => 'Sobre este lugar';

  @override
  String get guest_que_ver_address => 'Dirección';

  @override
  String get guest_que_ver_best_time => 'Mejor momento';

  @override
  String get guest_que_ver_location => 'Ubicación';

  @override
  String get guest_que_ver_practical_info => 'Información práctica';

  @override
  String get guest_que_ver_tips => 'Consejos';

  @override
  String get guest_que_ver_free_entry => 'Entrada gratuita';

  @override
  String get guest_que_ver_how_to_get => 'Cómo llegar';

  @override
  String get guest_que_ver_copy_link => 'Copiar enlace';

  @override
  String get guest_que_ver_official_web => 'Web oficial';

  @override
  String get guest_que_ver_link_copied => 'Enlace copiado al portapapeles';

  @override
  String get guest_reviews_verified => 'Verificado';

  @override
  String get guest_reviews_show_less => 'Ver menos';

  @override
  String get guest_reviews_show_more => 'Ver más';

  @override
  String get guest_reviews_empty_title => 'Sin reseñas aún';

  @override
  String get guest_reviews_empty_subtitle =>
      'Sé el primero en compartir tu experiencia';

  @override
  String get guest_reviews_write_first => 'Escribir reseña';

  @override
  String guest_reviews_filter_empty_title(String filter) {
    return 'Sin resultados para $filter';
  }

  @override
  String get guest_reviews_filter_empty_subtitle =>
      'Prueba a seleccionar otro filtro';

  @override
  String get guest_reviews_clear_filter => 'Limpiar filtro';

  @override
  String guest_reviews_count_label(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reseñas',
      one: '1 reseña',
    );
    return '$_temp0';
  }

  @override
  String get guest_reviews_no_reviews_title => 'Sin reseñas aún';

  @override
  String get guest_reviews_be_first => 'Sé el primero';

  @override
  String get guest_access_no_booking => 'No se encontró la reserva';

  @override
  String get guest_access_error_loading =>
      'Error al cargar los datos de acceso';

  @override
  String get guest_access_title => 'Acceso';

  @override
  String get guest_access_no_codes => 'No hay códigos de acceso disponibles';

  @override
  String get guest_access_codes_title => 'Códigos de Acceso';

  @override
  String get guest_access_codes_subtitle =>
      'Usa estos códigos para acceder a tu alojamiento';

  @override
  String get guest_access_main_code => 'Código principal';

  @override
  String get guest_access_main_door => 'Puerta principal';

  @override
  String guest_access_valid_period(String from, String until) {
    return 'Válido del $from al $until';
  }

  @override
  String get guest_access_wifi_title => 'WiFi';

  @override
  String get guest_access_wifi_network => 'Red:';

  @override
  String get guest_access_wifi_password => 'Contraseña:';

  @override
  String get guest_access_password_copied =>
      'Contraseña copiada al portapapeles';

  @override
  String get guest_access_other_accesses => 'Otros accesos';

  @override
  String get guest_access_instructions => 'Instrucciones de acceso';

  @override
  String get guest_guide_title => 'Guía de Estancia';

  @override
  String get guest_guide_subtitle => 'Toda la información de tu estancia';

  @override
  String get guest_guide_contact => 'Contacto';

  @override
  String get guest_guide_phone_1 => 'Teléfono 1';

  @override
  String get guest_guide_phone_2 => 'Teléfono 2';

  @override
  String get guest_guide_your_data => 'Tus Datos';

  @override
  String get guest_guide_accommodation => 'Alojamiento';

  @override
  String get guest_guide_property => 'Propiedad';

  @override
  String get guest_guide_checkin => 'Check-in';

  @override
  String get guest_guide_checkout => 'Check-out';

  @override
  String get guest_guide_guests => 'Huéspedes';

  @override
  String get guest_guide_services => 'Servicios';

  @override
  String get guest_guide_wifi => 'WiFi';

  @override
  String get guest_guide_laundry => 'Lavandería';

  @override
  String get guest_guide_laundry_desc => 'Servicio de lavandería disponible';

  @override
  String get guest_guide_jacuzzi => 'Jacuzzi';

  @override
  String get guest_guide_ac => 'Aire Acondicionado';

  @override
  String get guest_guide_ac_title => 'Aire Acondicionado';

  @override
  String get guest_guide_ac_desc =>
      'Control de climatización en tu alojamiento';

  @override
  String get guest_guide_tv => 'TV';

  @override
  String get guest_guide_tv_title => 'Televisión';

  @override
  String get guest_guide_tv_desc => 'Smart TV con canales y aplicaciones';

  @override
  String get guest_guide_not_available => 'No disponible';

  @override
  String get guest_guide_wifi_desc => 'Conexión WiFi incluida';

  @override
  String get guest_guide_house_rules => 'Normas de la Casa';

  @override
  String get guest_guide_rule_checkin => 'Check-in a partir de las 16:00';

  @override
  String guest_guide_rule_checkout(String time) {
    return 'Check-out antes de las $time';
  }

  @override
  String get guest_guide_rule_no_smoking => 'No fumador';

  @override
  String get guest_guide_rule_no_parties => 'No se permiten fiestas';

  @override
  String get guest_guide_rule_no_pets => 'No se admiten mascotas';

  @override
  String get guest_notifications_title => 'Notificaciones';

  @override
  String get guest_notifications_delete_all => 'Eliminar todo';

  @override
  String get guest_notifications_delete_all_title =>
      'Eliminar todas las notificaciones';

  @override
  String get guest_notifications_delete_all_confirm =>
      '¿Estás seguro de que deseas eliminar todas las notificaciones? Esta acción no se puede deshacer.';

  @override
  String guest_notifications_unread_count(int count) {
    return '$count sin leer';
  }

  @override
  String get guest_notifications_mark_all => 'Marcar todo como leído';

  @override
  String get guest_notifications_empty_title => 'Sin notificaciones';

  @override
  String get guest_notifications_empty_subtitle =>
      'Aquí aparecerán las notificaciones de tu estancia';

  @override
  String get guest_notifications_read => 'Leído';

  @override
  String get guest_romantic_title => 'Pack Romántico';

  @override
  String get guest_romantic_surprise => 'Sorprende a tu pareja';

  @override
  String get guest_romantic_unforgettable => 'Crea un momento inolvidable';

  @override
  String get guest_romantic_includes => '¿Qué incluye?';

  @override
  String get guest_romantic_decoration_title => 'Decoración Romántica';

  @override
  String get guest_romantic_decoration_desc =>
      'Pétalos de rosa, velas y decoración especial en la habitación';

  @override
  String get guest_romantic_choose_title => 'Elige tu detalle';

  @override
  String get guest_romantic_choose_desc =>
      'Botella de cava o chocolate artesanal para acompañar la velada';

  @override
  String get guest_romantic_basic_pack => 'Pack Romántico Básico';

  @override
  String get guest_romantic_price => '20,00 €';

  @override
  String get guest_romantic_book_now => 'Reservar Ahora';

  @override
  String get guest_romantic_customize =>
      'O personalízalo con extras al reservar';

  @override
  String get guest_romantic_redirect =>
      'Vas a ser redirigido a la web para completar la reserva del Pack Romántico. ¿Continuar?';

  @override
  String get guest_romantic_how_to => '¿Cómo reservar?';

  @override
  String get guest_romantic_step_1 => 'Selecciona el Pack Romántico';

  @override
  String get guest_romantic_step_2 => 'Personaliza los detalles';

  @override
  String get guest_romantic_step_3 => 'Completa la reserva online';

  @override
  String get guest_romantic_step_4 => 'Disfruta de la sorpresa';

  @override
  String get guest_romantic_note =>
      'La decoración se prepara durante tu ausencia para que sea una sorpresa completa.';

  @override
  String get guest_jacuzzi_title => 'Jacuzzi';

  @override
  String get guest_jacuzzi_rules_title => 'Normas de Uso';

  @override
  String get guest_jacuzzi_subtitle => 'Relájate y disfruta';

  @override
  String get guest_jacuzzi_power => 'Encendido';

  @override
  String get guest_jacuzzi_power_step_1 =>
      'Pulsa el botón POWER para encender el jacuzzi';

  @override
  String get guest_jacuzzi_power_step_2 => 'Espera a que el panel se ilumine';

  @override
  String get guest_jacuzzi_power_step_3 =>
      'Selecciona la temperatura deseada con los botones + y -';

  @override
  String get guest_jacuzzi_lock => 'Bloqueo del Panel';

  @override
  String get guest_jacuzzi_lock_step_1 =>
      'Para evitar activaciones accidentales, puedes bloquear el panel de control';

  @override
  String get guest_jacuzzi_lock_unlock => 'Desbloqueo';

  @override
  String get guest_jacuzzi_lock_unlock_step =>
      'Mantén pulsado el botón LOCK durante 3 segundos';

  @override
  String get guest_jacuzzi_lock_manual => 'Bloqueo Manual';

  @override
  String get guest_jacuzzi_lock_manual_step =>
      'Pulsa y mantén el botón LOCK durante 3 segundos para activar';

  @override
  String get guest_jacuzzi_ozone => 'Función Ozono';

  @override
  String get guest_jacuzzi_ozone_intro =>
      'El sistema de ozono ayuda a mantener el agua limpia y desinfectada de forma automática.';

  @override
  String get guest_jacuzzi_ozone_step_1 => 'Pulsa el botón OZONE en el panel';

  @override
  String get guest_jacuzzi_ozone_step_2 => 'Se activará la luz indicadora';

  @override
  String get guest_jacuzzi_ozone_step_3 =>
      'El sistema se ejecutará durante 30 minutos';

  @override
  String get guest_jacuzzi_ozone_step_4 =>
      'Se desactivará automáticamente al finalizar';

  @override
  String guest_jacuzzi_ozone_note(String note) {
    return 'Nota: $note';
  }

  @override
  String get guest_jacuzzi_massage => 'Funciones de Masaje';

  @override
  String get guest_jacuzzi_air_jets => 'Jets de Aire';

  @override
  String get guest_jacuzzi_air_step_1 =>
      'Pulsa el botón AIR para activar los jets de aire';

  @override
  String get guest_jacuzzi_air_step_2 =>
      'Ajusta la intensidad con los botones + y -';

  @override
  String get guest_jacuzzi_air_step_3 =>
      'Los jets crearán burbujas suaves en el agua';

  @override
  String get guest_jacuzzi_air_step_4 => 'Pulsa de nuevo para desactivar';

  @override
  String get guest_jacuzzi_water_jets => 'Jets de Agua';

  @override
  String get guest_jacuzzi_water_step_1 =>
      'Pulsa el botón JET para activar los jets de agua';

  @override
  String get guest_jacuzzi_water_step_2 =>
      'Los jets de agua proporcionan un masaje más intenso';

  @override
  String get guest_jacuzzi_water_step_3 =>
      'Dirige los jets hacia las zonas de tensión muscular';

  @override
  String get guest_jacuzzi_water_step_4 => 'Pulsa de nuevo para desactivar';

  @override
  String get guest_jacuzzi_important => 'Importante';

  @override
  String get guest_jacuzzi_water_level_info =>
      'El nivel del agua debe estar siempre por encima de los jets para un correcto funcionamiento.';

  @override
  String get guest_jacuzzi_low_water_title => 'Si el nivel es bajo:';

  @override
  String get guest_jacuzzi_low_water_stop => 'Detén el jacuzzi inmediatamente';

  @override
  String get guest_jacuzzi_low_water_icon =>
      'Verifica el icono de advertencia en el panel';

  @override
  String get guest_jacuzzi_low_water_resume =>
      'Rellena con agua hasta cubrir los jets antes de reanudar.';

  @override
  String get guest_jacuzzi_water_responsibility => 'Uso Responsable del Agua';

  @override
  String get guest_jacuzzi_water_refill_info =>
      'El jacuzzi tiene una capacidad considerable de agua. Por favor, úsalo de forma responsable.';

  @override
  String get guest_jacuzzi_capacity => 'Capacidad:';

  @override
  String get guest_jacuzzi_capacity_liters => '800 litros';

  @override
  String get guest_jacuzzi_water_regulation =>
      'El llenado y vaciado del jacuzzi está regulado por las normas locales de uso del agua.';

  @override
  String get guest_jacuzzi_thanks =>
      'Gracias por tu colaboración en el uso responsable del agua.';

  @override
  String get guest_physical_registration_title => 'Registro Físico';

  @override
  String get guest_physical_registration_header => 'Registro en Recepción';

  @override
  String get guest_physical_registration_subtitle =>
      'Completa tu registro de forma presencial';

  @override
  String get guest_physical_registration_instructions => 'Instrucciones';

  @override
  String get guest_physical_registration_step_1_title => 'Acude a recepción';

  @override
  String get guest_physical_registration_step_1_desc =>
      'Dirígete a la recepción del hotel durante el horario de atención';

  @override
  String get guest_physical_registration_step_2_title =>
      'Presenta tu documento';

  @override
  String get guest_physical_registration_step_2_desc =>
      'Muestra tu documento de identidad original (DNI, pasaporte o carnet de conducir)';

  @override
  String get guest_physical_registration_step_3_title => 'Firma el registro';

  @override
  String get guest_physical_registration_step_3_desc =>
      'Firma el documento de registro de entrada';

  @override
  String get guest_physical_registration_step_4_title => 'Recibe tu llave';

  @override
  String get guest_physical_registration_step_4_desc =>
      'Te entregaremos la llave de tu habitación';

  @override
  String get guest_physical_registration_schedule => 'Horario de Recepción';

  @override
  String get guest_physical_registration_schedule_hours =>
      'Horario de atención';

  @override
  String get guest_physical_registration_schedule_days => 'Lunes a Viernes';

  @override
  String get guest_physical_registration_documents => 'Documentos Aceptados';

  @override
  String get guest_physical_registration_doc_dni => 'DNI';

  @override
  String get guest_physical_registration_doc_passport => 'Pasaporte';

  @override
  String get guest_physical_registration_doc_license => 'Carnet de conducir';

  @override
  String get guest_checkin_child_no_data =>
      'Menor de 14 años, sin datos requeridos';

  @override
  String get guest_checkin_holder => 'Titular';

  @override
  String get guest_checkin_full_name => 'Nombre completo';

  @override
  String get guest_checkin_email => 'Email';

  @override
  String get guest_checkin_phone => 'Teléfono';

  @override
  String guest_checkin_young(int age) {
    return 'Menor ($age años)';
  }

  @override
  String guest_checkin_adult(int number) {
    return 'Adulto $number';
  }

  @override
  String guest_checkin_guest(int number) {
    return 'Huésped $number';
  }

  @override
  String get guest_checkin_document_id => 'Documento de identidad';

  @override
  String get guest_checkin_upload_document => 'Subir documento';

  @override
  String get guest_checkin_document => 'Documento';

  @override
  String get guest_checkin_missing_photo => 'Falta foto del documento';

  @override
  String get guest_checkin_upload_document_title => 'Subir Documento';

  @override
  String get guest_checkin_document_type => 'Tipo de documento';

  @override
  String get guest_checkin_document_number => 'Número de documento';

  @override
  String get guest_checkin_document_photo => 'Foto del documento';

  @override
  String get guest_checkin_image_captured => 'Imagen capturada';

  @override
  String get guest_checkin_tap_to_capture => 'Toca para capturar documento';

  @override
  String get guest_checkin_camera_or_gallery => 'Cámara o galería';

  @override
  String get guest_checkin_select_source => 'Seleccionar origen';

  @override
  String get guest_checkin_camera => 'Cámara';

  @override
  String get guest_checkin_gallery => 'Galería';

  @override
  String get guest_checkin_photo_required => 'Foto obligatoria';

  @override
  String get guest_checkin_document_number_required =>
      'Introduce el número de documento';

  @override
  String get guest_checkin_confirm => 'Confirmar';

  @override
  String guest_checkin_capture_error(String error) {
    return 'Error al capturar imagen: $error';
  }

  @override
  String get admin_chat_title => 'Chat';

  @override
  String get admin_chat_online => 'En línea';

  @override
  String get chat_delete_message => 'Eliminar mensaje';

  @override
  String get chat_delete_message_confirm_body =>
      '¿Seguro que quieres eliminar este mensaje? Esta acción no se puede deshacer.';

  @override
  String get chat_delete_message_error => 'No se pudo eliminar el mensaje';

  @override
  String get admin_chat_delete_conversation => 'Eliminar conversación';

  @override
  String get admin_chat_delete_confirm_body =>
      '¿Estás seguro de que deseas eliminar esta conversación?';

  @override
  String get admin_chat_deleted_success =>
      'Conversación eliminada correctamente';

  @override
  String admin_chat_error_deleting(String error) {
    return 'Error al eliminar la conversación: $error';
  }

  @override
  String get admin_checkin_detail_title => 'Detalle de Check-in';

  @override
  String get admin_checkin_validate => 'Validar';

  @override
  String get admin_checkin_reject => 'Rechazar';

  @override
  String get admin_checkin_cancel_booking => 'Cancelar Reserva';

  @override
  String get admin_checkin_error_loading => 'Error al cargar';

  @override
  String get admin_checkin_not_found => 'Check-in no encontrado';

  @override
  String get admin_checkin_status_pending => 'Pendiente';

  @override
  String get admin_checkin_status_validated => 'Validado';

  @override
  String get admin_checkin_status_rejected => 'Rechazado';

  @override
  String get admin_checkin_status_cancelled => 'Cancelado';

  @override
  String get admin_checkin_status_draft => 'Borrador';

  @override
  String get admin_checkin_submitted_label => 'Enviado:';

  @override
  String get admin_checkin_validated_label => 'Validado:';

  @override
  String get admin_checkin_rejected_label => 'Rechazado:';

  @override
  String get admin_checkin_cancelled_label => 'Cancelado:';

  @override
  String get admin_checkin_booking_info => 'Información de Reserva';

  @override
  String get admin_checkin_property_label => 'Propiedad:';

  @override
  String get admin_checkin_units_label => 'hab';

  @override
  String get admin_checkin_unit_label => 'hab';

  @override
  String get admin_checkin_code_label => 'Código:';

  @override
  String get admin_checkin_checkin_date_label => 'Check-in:';

  @override
  String get admin_checkin_checkout_date_label => 'Check-out:';

  @override
  String get admin_checkin_guests_section => 'HUÉSPEDES';

  @override
  String get admin_checkin_primary_badge => 'Titular';

  @override
  String get admin_checkin_na => 'N/A';

  @override
  String get admin_checkin_documents_section => 'DOCUMENTOS';

  @override
  String get admin_checkin_unknown_guest => 'Huésped desconocido';

  @override
  String get admin_checkin_signature_section => 'FIRMA';

  @override
  String get admin_checkin_doc_type_dni => 'DNI';

  @override
  String get admin_checkin_doc_type_nie => 'NIE';

  @override
  String get admin_checkin_doc_type_passport => 'Pasaporte';

  @override
  String get admin_checkin_image_load_error => 'Error al cargar imagen';

  @override
  String get admin_checkin_validate_title => 'Validar Check-in';

  @override
  String get admin_checkin_validate_message =>
      '¿Estás seguro de que deseas validar este check-in?';

  @override
  String get admin_checkin_validated_success =>
      'Check-in validado correctamente';

  @override
  String admin_checkin_error(String error) {
    return 'Error: $error';
  }

  @override
  String get admin_checkin_reject_title => 'Rechazar Check-in';

  @override
  String get admin_checkin_reject_message =>
      '¿Estás seguro de que deseas rechazar este check-in?';

  @override
  String get admin_checkin_reject_hint => 'Motivo del rechazo (opcional)...';

  @override
  String get admin_checkin_no_reason => 'Sin motivo';

  @override
  String get admin_checkin_rejected_success =>
      'Check-in rechazado correctamente';

  @override
  String get admin_checkin_cancel_message =>
      '¿Estás seguro de que deseas cancelar esta reserva?';

  @override
  String get admin_checkin_cancel_warning =>
      'Esta acción no se puede deshacer.';

  @override
  String get admin_checkin_cancel_reason_label => 'Motivo de cancelación';

  @override
  String get admin_checkin_cancel_reason_hint =>
      'Describe el motivo de la cancelación...';

  @override
  String get admin_checkin_cancelled_success =>
      'Reserva cancelada correctamente';

  @override
  String get admin_invoice_generate_pdf => 'Generar PDF';

  @override
  String get admin_invoice_share => 'Compartir';

  @override
  String get admin_invoice_download => 'Descargar';

  @override
  String get admin_invoice_share_title => 'Compartir Factura';

  @override
  String get admin_invoice_copy_link => 'Copiar enlace';

  @override
  String admin_invoice_pdf_saved(String path) {
    return 'PDF guardado en: $path';
  }

  @override
  String get admin_invoice_issue => 'Emitir';

  @override
  String get admin_invoice_mark_paid => 'Marcar como pagada';

  @override
  String admin_invoice_paid_on(String date) {
    return 'Pagada el $date';
  }

  @override
  String admin_invoice_cancelled(String reason) {
    return 'Cancelada: $reason';
  }

  @override
  String get admin_invoice_issue_confirm_title => 'Emitir Factura';

  @override
  String admin_invoice_issue_confirm_message(String invoiceNumber) {
    return '¿Estás seguro de que deseas emitir la factura $invoiceNumber?';
  }

  @override
  String get admin_invoice_mark_paid_confirm_title => 'Marcar como Pagada';

  @override
  String admin_invoice_mark_paid_confirm_message(String total) {
    return '¿Confirmas que se ha recibido el pago de $total?';
  }

  @override
  String get admin_invoice_confirm_payment => 'Confirmar pago';

  @override
  String get admin_invoice_cancel_confirm_title => 'Cancelar Factura';

  @override
  String get admin_invoice_cancel_reason_label => 'Motivo de cancelación';

  @override
  String get admin_invoice_cancel_reason_hint =>
      'Describe el motivo de la cancelación...';

  @override
  String get admin_invoice_dont_cancel => 'No cancelar';

  @override
  String get admin_invoice_cancel_invoice => 'Cancelar factura';

  @override
  String admin_invoice_error_generate_pdf(String error) {
    return 'Error al generar PDF: $error';
  }

  @override
  String admin_invoice_error_share(String error) {
    return 'Error al compartir: $error';
  }

  @override
  String admin_invoice_error_download(String error) {
    return 'Error al descargar: $error';
  }

  @override
  String get admin_invoice_nif_label => 'NIF/CIF:';

  @override
  String get admin_invoice_label => 'Factura';

  @override
  String get admin_invoice_bill_to => 'Facturar a';

  @override
  String get admin_invoice_issue_date_label => 'Fecha de emisión:';

  @override
  String get admin_invoice_due_date_label => 'Fecha de vencimiento:';

  @override
  String get admin_invoice_period_label => 'Período';

  @override
  String get admin_invoice_booking_label => 'Reserva';

  @override
  String get admin_invoice_no_line_items => 'Sin conceptos';

  @override
  String get admin_invoice_col_description => 'Descripción';

  @override
  String get admin_invoice_col_qty => 'Cant.';

  @override
  String get admin_invoice_col_price => 'Precio';

  @override
  String get admin_invoice_col_total => 'Total';

  @override
  String get admin_invoice_tax_base => 'Base imponible';

  @override
  String get admin_invoice_tax_label => 'IVA';

  @override
  String get admin_invoice_total_label => 'Total';

  @override
  String get admin_invoice_notes_label => 'Notas';

  @override
  String get admin_notifications_title => 'Notificaciones';

  @override
  String get admin_notifications_empty_title => 'Sin notificaciones';

  @override
  String get admin_notifications_empty_subtitle =>
      'Las notificaciones aparecerán aquí';

  @override
  String get admin_notifications_mark_all_read => 'Marcar todo como leído';

  @override
  String get admin_notifications_mark_read => 'Marcar como leído';

  @override
  String get admin_notifications_delete_all => 'Eliminar todo';

  @override
  String get admin_notifications_delete_all_title =>
      'Eliminar todas las notificaciones';

  @override
  String get admin_notifications_delete_all_confirm =>
      '¿Estás seguro de que deseas eliminar todas las notificaciones?';

  @override
  String admin_notifications_unread_count(int count) {
    return '$count sin leer';
  }

  @override
  String get guest_access_checkin => 'Check-in';

  @override
  String get guest_access_checkout => 'Check-out';

  @override
  String get guest_access_checkout_label => 'Salida';

  @override
  String guest_access_checkout_until(String time) {
    return 'Hasta las $time';
  }

  @override
  String get guest_access_checkout_deadline => 'Hora límite de salida';

  @override
  String get guest_access_checkout_instructions => 'Instrucciones de salida';

  @override
  String get guest_access_code_label => 'Código';

  @override
  String guest_access_code_available_at(String date, String time) {
    return 'Disponible el $date a las $time';
  }

  @override
  String get guest_access_code_provided_by_staff =>
      'Proporcionado por el personal';

  @override
  String get guest_access_locker_code => 'Código del casillero';

  @override
  String get guest_access_locker_code_label => 'Código casillero';

  @override
  String guest_access_locker_available_at(String date) {
    return 'Disponible el $date';
  }

  @override
  String get guest_access_key_locker => 'Casillero de llaves';

  @override
  String get guest_access_door_code => 'Código de la puerta';

  @override
  String get guest_access_building_access => 'Acceso al edificio';

  @override
  String get guest_access_building_instructions =>
      'Instrucciones de acceso al edificio';

  @override
  String get guest_access_apartment_access => 'Acceso al apartamento';

  @override
  String get guest_access_apartment_instructions =>
      'Instrucciones de acceso al apartamento';

  @override
  String get guest_access_location => 'Ubicación';

  @override
  String get guest_access_contact => 'Contacto';

  @override
  String get guest_access_contact_description =>
      'Contacta con nosotros si necesitas ayuda';

  @override
  String guest_access_copied(String label) {
    return '$label copiado al portapapeles';
  }

  @override
  String get guest_access_open_maps => 'Abrir en Maps';

  @override
  String get guest_access_network => 'Red';

  @override
  String get guest_access_network_name => 'Nombre de red';

  @override
  String get guest_access_password => 'Contraseña';

  @override
  String get guest_access_company_name => 'BF Stay';

  @override
  String get guest_access_house_rules => 'Normas de la casa';

  @override
  String get guest_access_rules_warning =>
      'Por favor, lee las normas de la casa antes de tu llegada';

  @override
  String get guest_access_your_accommodation => 'Tu alojamiento';

  @override
  String get guest_access_your_codes => 'Tus códigos';

  @override
  String get guest_access_guest => 'Huésped';

  @override
  String guest_access_welcome_message(String unitName) {
    return 'Bienvenido a $unitName';
  }

  @override
  String guest_access_hello(String name) {
    return 'Hola $name';
  }

  @override
  String guest_access_codes_available_datetime(String date, String time) {
    return 'Disponible el $date a las $time';
  }

  @override
  String guest_access_codes_available_message(String time) {
    return 'Tu código estará disponible a partir de $time';
  }

  @override
  String get guest_access_loading_instructions => 'Cargando instrucciones...';

  @override
  String get guest_access_cannot_load_instructions =>
      'No se pueden cargar las instrucciones';

  @override
  String get guest_access_rule_no_parties_title => 'No fiestas';

  @override
  String get guest_access_rule_no_parties_description =>
      'No se permiten fiestas ni eventos';

  @override
  String get guest_access_rule_no_smoking_title => 'Sin humo';

  @override
  String get guest_access_rule_smoke_free_description =>
      'Esta es una propiedad libre de humo';

  @override
  String get guest_access_rule_registered_only_title => 'Solo registrados';

  @override
  String get guest_access_rule_registered_only_description =>
      'Solo los huéspedes registrados pueden acceder';

  @override
  String get guest_accommodation_title => 'Alojamiento';

  @override
  String get guest_accommodation_error_loading => 'Error al cargar';

  @override
  String get guest_accommodation_error_occurred => 'Ha ocurrido un error';

  @override
  String get guest_accommodation_no_booking => 'No se encontró la reserva';

  @override
  String get guest_accommodation_booking_not_found => 'Reserva no encontrada';

  @override
  String get guest_accommodation_no_unit_info =>
      'No hay información de la unidad';

  @override
  String get guest_accommodation_address => 'Dirección';

  @override
  String get guest_accommodation_address_unavailable =>
      'Dirección no disponible';

  @override
  String get guest_accommodation_box_location => 'Ubicación de la caja';

  @override
  String get guest_accommodation_access_codes => 'Códigos de acceso';

  @override
  String get guest_accommodation_access_instructions =>
      'Instrucciones de acceso';

  @override
  String get guest_accommodation_main_door => 'Puerta principal';

  @override
  String get guest_accommodation_door_code => 'Código de la puerta';

  @override
  String get guest_accommodation_portal_code => 'Código del portal';

  @override
  String get guest_accommodation_key_box_code => 'Código de la caja de llaves';

  @override
  String get guest_accommodation_keybox_description =>
      'Código para la caja de llaves';

  @override
  String get guest_accommodation_wifi_password => 'Contraseña WiFi';

  @override
  String guest_accommodation_rooms_count(int count) {
    return '$count habitaciones';
  }

  @override
  String get guest_accommodation_hotel_rules => 'Normas del hotel';

  @override
  String get guest_accommodation_apartment_rules => 'Normas del apartamento';

  @override
  String get guest_accommodation_rules_description =>
      'Consulta las normas de tu alojamiento';

  @override
  String guest_accommodation_rules_load_error(String error) {
    return 'Error al cargar las normas: $error';
  }

  @override
  String guest_accommodation_codes_available_datetime(
    String date,
    String time,
  ) {
    return 'Disponible el $date a las $time';
  }

  @override
  String guest_accommodation_codes_available_message(String time) {
    return 'Tus códigos estarán disponibles cuando comience tu estancia ($time)';
  }

  @override
  String guest_accommodation_file_not_found(String message) {
    return 'Archivo no encontrado: $message';
  }

  @override
  String get guest_accommodation_cannot_open_document =>
      'No se puede abrir el documento';

  @override
  String get guest_accommodation_tap_for_access_info =>
      'Toca para ver información de acceso';

  @override
  String get guest_chat_default_title => 'Chat';

  @override
  String get guest_chat_online => 'En línea';

  @override
  String get guest_chat_start_conversation => 'Iniciar conversación';

  @override
  String get guest_chat_welcome_message => '¡Hola! ¿En qué podemos ayudarte?';

  @override
  String get guest_checkin_label => 'Check-in';

  @override
  String get guest_checkin_back => 'Atrás';

  @override
  String get guest_checkin_continue => 'Continuar';

  @override
  String get guest_checkin_complete => 'Completar';

  @override
  String get guest_checkin_loading_booking => 'Cargando datos de la reserva...';

  @override
  String get guest_checkin_error_loading => 'Error al cargar';

  @override
  String get guest_checkin_booking => 'Reserva';

  @override
  String get guest_checkin_code => 'Código';

  @override
  String get guest_checkin_guests_label => 'Huéspedes';

  @override
  String guest_checkin_guests_count(int count) {
    return '$count huéspedes';
  }

  @override
  String guest_checkin_guests_registered(int count) {
    return '$count registrados';
  }

  @override
  String guest_checkin_guests_summary(int count) {
    return '$count huéspedes';
  }

  @override
  String get guest_checkin_guest_data => 'Datos del huésped';

  @override
  String get guest_checkin_guest_data_description =>
      'Completa los datos de todos los huéspedes';

  @override
  String get guest_checkin_holder_badge => 'TITULAR';

  @override
  String get guest_checkin_holder_signature => 'Firma del titular';

  @override
  String get guest_checkin_no_name => 'Sin nombre';

  @override
  String get guest_checkin_guest_no_name => 'Huésped sin nombre';

  @override
  String guest_checkin_adults_children(int adults, int children) {
    return '$adults adultos y $children menores';
  }

  @override
  String get guest_checkin_minor_badge => 'MENOR';

  @override
  String guest_checkin_young_document_required(int age) {
    return 'Menor de $age años, documento requerido';
  }

  @override
  String get guest_checkin_document_required => 'Documento requerido';

  @override
  String get guest_checkin_upload => 'Subir';

  @override
  String guest_checkin_documents_uploaded(int completed, int total) {
    return '$completed de $total documentos subidos';
  }

  @override
  String get guest_checkin_all_documents_uploaded =>
      'Todos los documentos subidos';

  @override
  String get guest_checkin_upload_documents_description =>
      'Sube las fotos de los documentos de identidad de todos los huéspedes';

  @override
  String get guest_checkin_uploaded_documents => 'Documentos subidos';

  @override
  String get guest_checkin_pending_documents => 'Documentos pendientes';

  @override
  String get guest_checkin_identity_documents => 'Documentos de identidad';

  @override
  String get guest_checkin_signature_description =>
      'Firma del titular de la reserva';

  @override
  String get guest_checkin_signature_pending => 'Firma pendiente';

  @override
  String get guest_checkin_signature_captured => 'Firma capturada';

  @override
  String get guest_checkin_signature_captured_short => 'Firma';

  @override
  String get guest_checkin_clear_signature => 'Borrar firma';

  @override
  String get guest_checkin_step_guests => 'Huéspedes';

  @override
  String get guest_checkin_step_documents => 'Documentos';

  @override
  String get guest_checkin_step_signature => 'Firma';

  @override
  String get guest_checkin_step_confirm => 'Confirmar';

  @override
  String get guest_checkin_online => 'En línea';

  @override
  String get guest_checkin_pending => 'Pendiente';

  @override
  String get guest_checkin_validated => 'Validado';

  @override
  String get guest_checkin_waiting_validation => 'Esperando validación';

  @override
  String get guest_checkin_completed => 'Completado';

  @override
  String get guest_checkin_completed_success =>
      'Check-in completado correctamente';

  @override
  String get guest_checkin_sending => 'Enviando...';

  @override
  String get guest_checkin_progress => 'Progreso del check-in';

  @override
  String get guest_checkin_confirmation => 'Confirmación de Check-in';

  @override
  String get guest_checkin_confirmation_description =>
      'Tu check-in ha sido enviado. Ahora hay que esperar a que el alojamiento lo valide.';

  @override
  String get guest_checkin_legal_notice => 'Aviso legal';

  @override
  String get guest_checkout_title => 'Check-out';

  @override
  String get guest_checkout_label => 'Salida';

  @override
  String get guest_checkout_checkin_label => 'Entrada';

  @override
  String get guest_checkout_checkout_label => 'Salida';

  @override
  String guest_checkout_nights_count(int count) {
    return '$count noches';
  }

  @override
  String guest_checkout_guests_count(int count) {
    return '$count huéspedes';
  }

  @override
  String get guest_checkout_stay_summary => 'Resumen de la estancia';

  @override
  String get guest_checkout_confirm => 'Confirmar';

  @override
  String get guest_checkout_confirm_button => 'Confirmar salida';

  @override
  String get guest_checkout_confirm_dialog_title => '¿Confirmar salida?';

  @override
  String get guest_checkout_confirm_dialog_message =>
      'Vas a confirmar tu salida. ¿Deseas continuar?';

  @override
  String get guest_checkout_confirm_info => 'Confirmando salida...';

  @override
  String get guest_checkout_processing => 'Procesando...';

  @override
  String get guest_checkout_completed => 'Check-out completado';

  @override
  String get guest_checkout_thank_you => '¡Gracias por tu estancia!';

  @override
  String get guest_checkout_feedback_title => 'Tu opinión nos importa';

  @override
  String get guest_checkout_feedback_hint =>
      'Cuéntanos cómo ha sido tu experiencia...';

  @override
  String get guest_checkout_rating_title => 'Valora tu estancia';

  @override
  String get guest_checkout_review_description =>
      'Tu opinión ayuda a otros viajeros';

  @override
  String get guest_checkout_loading => 'Cargando...';

  @override
  String get guest_checkout_error_loading => 'Error al cargar';

  @override
  String get guest_checkout_already_done => 'Check-out ya realizado';

  @override
  String get guest_checkout_already_done_message =>
      'Ya has realizado el check-out. ¡Gracias!';

  @override
  String get guest_home_welcome => 'Bienvenido';

  @override
  String get guest_home_welcome_stay => 'Bienvenido a tu estancia';

  @override
  String guest_home_hello_name(String name) {
    return 'Hola, $name';
  }

  @override
  String get guest_home_your_stay => 'Tu Estancia';

  @override
  String get guest_home_no_booking => 'No tienes reservas';

  @override
  String get guest_home_not_authenticated => 'No autenticado';

  @override
  String get guest_home_stay_active_enjoy =>
      'Tu estancia está activa. ¡Disfruta!';

  @override
  String get guest_home_quick_actions => 'Acciones rápidas';

  @override
  String get guest_home_checkin => 'Check-in';

  @override
  String get guest_home_checkout => 'Check-out';

  @override
  String get guest_home_chat => 'Chat';

  @override
  String get guest_home_guide => 'Guía';

  @override
  String get guest_home_rules => 'Normas';

  @override
  String get guest_home_parkings => 'Parkings';

  @override
  String get guest_home_accommodations => 'Alojamientos';

  @override
  String get guest_home_accommodation => 'Alojamiento';

  @override
  String guest_home_rooms_count(int count) {
    return '$count hab';
  }

  @override
  String get guest_home_guests => 'Huéspedes';

  @override
  String guest_home_nights(int count) {
    return '$count noches';
  }

  @override
  String get guest_home_what_to_see => 'Qué ver';

  @override
  String get guest_home_instructions => 'Instrucciones';

  @override
  String get guest_home_my_accommodation => 'Mi alojamiento';

  @override
  String get guest_home_booking_cancelled => 'Reserva cancelada';

  @override
  String get guest_home_booking_cancelled_message =>
      'Tu reserva ha sido cancelada. Contacta con recepción.';

  @override
  String get guest_home_cancellation_reason => 'Motivo de cancelación';

  @override
  String get guest_home_checkin_pending => 'Check-in pendiente';

  @override
  String get guest_home_checkin_sent_waiting =>
      'Check-in enviado, esperando validación';

  @override
  String get guest_home_checkin_rejected => 'Check-in rechazado';

  @override
  String get guest_home_rejection_reason => 'Motivo del rechazo';

  @override
  String get guest_home_pending_validation => 'Pendiente de validación';

  @override
  String get guest_home_complete_checkin_access =>
      'Completa el check-in para acceder';

  @override
  String get guest_home_contact_reception => 'Contacta con recepción';

  @override
  String get guest_home_correct_errors_resend =>
      'Corrige los errores y vuelve a enviar';

  @override
  String get guest_home_physical_registration => 'Registro presencial';

  @override
  String get guest_home_romantic_pack => 'Pack Romántico';

  @override
  String guest_jacuzzi_note(String note) {
    return 'Nota: $note';
  }

  @override
  String get public_services_title => 'Nuestros Servicios';

  @override
  String get public_service_rules_title => 'Normas de la Casa';

  @override
  String get public_service_rules_desc => 'Reglas y recomendaciones.';

  @override
  String public_copyright(int year) {
    return '© $year BF Stay • Todos los derechos reservados';
  }

  @override
  String get public_access_booking => 'Acceder a mi Reserva';

  @override
  String staff_dashboard_greeting(String name) {
    return 'Hola $name';
  }

  @override
  String get staff_dashboard_control_panel => 'Panel de Control';

  @override
  String get staff_dashboard_daily_summary => 'Resumen del día';

  @override
  String get staff_dashboard_occupancy => 'Ocupación';

  @override
  String get staff_dashboard_pending => 'Pendientes';

  @override
  String get staff_dashboard_pending_checkin => 'Check-ins pendientes';

  @override
  String get staff_dashboard_pending_checkout => 'Check-outs pendientes';

  @override
  String get staff_dashboard_pending_tasks => 'Tareas pendientes';

  @override
  String get staff_dashboard_checkins_today => 'Check-ins hoy';

  @override
  String get staff_dashboard_checkouts_today => 'Check-outs hoy';

  @override
  String get staff_dashboard_quick_actions => 'Acciones rápidas';

  @override
  String get staff_dashboard_manage_checkins => 'Gestionar check-ins';

  @override
  String get staff_dashboard_view_guests => 'Ver huéspedes';

  @override
  String staff_dashboard_room_extras(String room) {
    return 'Habitación $room - Extras';
  }

  @override
  String get staff_dashboard_cleaning_request => 'Solicitud de limpieza';

  @override
  String staff_dashboard_room_guest(String room, String guest) {
    return 'Habitación $room - $guest';
  }

  @override
  String get staff_dashboard_generate_report => 'Generar informe';

  @override
  String get staff_checkins_title => 'Check-ins';

  @override
  String get staff_checkins_tab_pending => 'Pendientes';

  @override
  String get staff_checkins_tab_in_progress => 'En progreso';

  @override
  String get staff_checkins_tab_completed => 'Completados';

  @override
  String get staff_checkins_status_pending => 'Pendiente';

  @override
  String get staff_checkins_status_in_progress => 'En progreso';

  @override
  String get staff_checkins_status_completed => 'Completado';

  @override
  String get staff_checkins_start => 'Iniciar';

  @override
  String get staff_checkins_new_checkin => 'Nuevo check-in';

  @override
  String get staff_checkins_complete => 'Completar';

  @override
  String get staff_checkins_view_details => 'Ver detalles';

  @override
  String get guest_access_wifi_password_label => 'Contraseña WiFi';

  @override
  String get guest_access_locker_provided_by_staff =>
      'Proporcionado por el personal';

  @override
  String get guest_access_rule_smoke_free_title => 'Sin humo';

  @override
  String get guest_accommodation_view_rules_pdf => 'Ver normas en PDF';

  @override
  String get public_hero_title_line1 => 'Tu Estancia,';

  @override
  String get public_hero_title_line2 => 'Elevada';

  @override
  String get admin_booking_send_whatsapp_title => 'Enviar código por WhatsApp';

  @override
  String get admin_booking_send_whatsapp_no_phone =>
      'El huésped no tiene teléfono';

  @override
  String get admin_booking_send_whatsapp_no_phone_desc =>
      'Introduce un número de teléfono para enviar el código por WhatsApp.';

  @override
  String get admin_booking_send_whatsapp_phone_hint => '+34 600 000 000';

  @override
  String get admin_booking_send_whatsapp_error => 'No se pudo abrir WhatsApp';

  @override
  String admin_booking_send_whatsapp_message(
    String propertyName,
    String bookingCode,
    String checkIn,
    String checkOut,
  ) {
    return '🏠 *$propertyName*\n📋 Reserva: *$bookingCode*\n📅 Check-in: $checkIn\n📅 Check-out: $checkOut\n\nDescarga la app BF Stay para gestionar tu estancia.';
  }
}
