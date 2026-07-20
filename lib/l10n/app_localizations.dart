import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @guest_romantic_request_sent.
  ///
  /// In es, this message translates to:
  /// **'Hemos avisado al alojamiento. Te contactarán para confirmar los detalles.'**
  String get guest_romantic_request_sent;

  /// No description provided for @guest_romantic_request_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar tu solicitud. Inténtalo de nuevo.'**
  String get guest_romantic_request_error;

  /// No description provided for @common_app_name.
  ///
  /// In es, this message translates to:
  /// **'BF Stay'**
  String get common_app_name;

  /// No description provided for @common_cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get common_cancel;

  /// No description provided for @common_exit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get common_exit;

  /// No description provided for @common_save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get common_delete;

  /// No description provided for @common_close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get common_close;

  /// No description provided for @common_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get common_loading;

  /// No description provided for @common_retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get common_retry;

  /// No description provided for @common_accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get common_accept;

  /// No description provided for @common_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get common_continue;

  /// No description provided for @common_back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get common_back;

  /// No description provided for @common_ok.
  ///
  /// In es, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get common_success;

  /// No description provided for @common_no_data.
  ///
  /// In es, this message translates to:
  /// **'No hay datos'**
  String get common_no_data;

  /// No description provided for @common_yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get common_send;

  /// No description provided for @common_edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get common_edit;

  /// No description provided for @common_search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get common_search;

  /// No description provided for @common_later.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get common_later;

  /// No description provided for @common_update.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get common_update;

  /// No description provided for @common_understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get common_understood;

  /// Title of the exit confirmation dialog
  ///
  /// In es, this message translates to:
  /// **'Salir de BF Stay'**
  String get common_exit_app_title;

  /// Message of the exit confirmation dialog
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas salir de la aplicación?\n\nTu sesión permanecerá activa cuando vuelvas a entrar.'**
  String get common_exit_app_message;

  /// No description provided for @common_logout_title.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get common_logout_title;

  /// No description provided for @common_logout_message.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?\n\nPodrás volver a acceder con tu código de reserva cuando lo necesites.'**
  String get common_logout_message;

  /// No description provided for @common_logout_button.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get common_logout_button;

  /// No description provided for @common_splash_ready.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get common_splash_ready;

  /// No description provided for @common_splash_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get common_splash_loading;

  /// No description provided for @common_update_force_title.
  ///
  /// In es, this message translates to:
  /// **'Actualización Requerida'**
  String get common_update_force_title;

  /// No description provided for @common_update_available_title.
  ///
  /// In es, this message translates to:
  /// **'Nueva Versión Disponible'**
  String get common_update_available_title;

  /// No description provided for @common_update_force_message.
  ///
  /// In es, this message translates to:
  /// **'Es necesario actualizar la aplicación para continuar usándola. Esta versión incluye mejoras importantes y correcciones de seguridad.'**
  String get common_update_force_message;

  /// No description provided for @common_update_available_message.
  ///
  /// In es, this message translates to:
  /// **'Hay una nueva versión disponible con mejoras y correcciones. ¿Deseas actualizar ahora?'**
  String get common_update_available_message;

  /// No description provided for @common_update_version.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String common_update_version(String version);

  /// No description provided for @common_page_not_found.
  ///
  /// In es, this message translates to:
  /// **'Página no encontrada'**
  String get common_page_not_found;

  /// No description provided for @common_invalid_route.
  ///
  /// In es, this message translates to:
  /// **'Ruta no válida'**
  String get common_invalid_route;

  /// No description provided for @common_back_to_home.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get common_back_to_home;

  /// No description provided for @common_theme_light.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get common_theme_light;

  /// No description provided for @common_theme_dark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get common_theme_dark;

  /// No description provided for @common_theme_mode_light.
  ///
  /// In es, this message translates to:
  /// **'Modo Claro'**
  String get common_theme_mode_light;

  /// No description provided for @common_theme_mode_dark.
  ///
  /// In es, this message translates to:
  /// **'Modo Oscuro'**
  String get common_theme_mode_dark;

  /// No description provided for @common_theme_system.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get common_theme_system;

  /// No description provided for @common_theme_app_label.
  ///
  /// In es, this message translates to:
  /// **'Tema de la aplicación'**
  String get common_theme_app_label;

  /// No description provided for @common_copied_to_clipboard.
  ///
  /// In es, this message translates to:
  /// **'{type} copiado al portapapeles'**
  String common_copied_to_clipboard(String type);

  /// No description provided for @common_phone_type.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get common_phone_type;

  /// No description provided for @common_email_type.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get common_email_type;

  /// No description provided for @enum_booking_status_created.
  ///
  /// In es, this message translates to:
  /// **'Creada'**
  String get enum_booking_status_created;

  /// No description provided for @enum_booking_status_confirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get enum_booking_status_confirmed;

  /// No description provided for @enum_booking_status_active.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get enum_booking_status_active;

  /// No description provided for @enum_booking_status_in_house.
  ///
  /// In es, this message translates to:
  /// **'En casa'**
  String get enum_booking_status_in_house;

  /// No description provided for @enum_booking_status_checked_out.
  ///
  /// In es, this message translates to:
  /// **'Finalizada'**
  String get enum_booking_status_checked_out;

  /// No description provided for @enum_booking_status_closed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get enum_booking_status_closed;

  /// No description provided for @enum_booking_status_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get enum_booking_status_cancelled;

  /// No description provided for @enum_booking_status_created_desc.
  ///
  /// In es, this message translates to:
  /// **'Reserva creada, pendiente de confirmación'**
  String get enum_booking_status_created_desc;

  /// No description provided for @enum_booking_status_confirmed_desc.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada, pendiente de check-in'**
  String get enum_booking_status_confirmed_desc;

  /// No description provided for @enum_booking_status_active_desc.
  ///
  /// In es, this message translates to:
  /// **'Check-in validado, panel completo accesible'**
  String get enum_booking_status_active_desc;

  /// No description provided for @enum_booking_status_in_house_desc.
  ///
  /// In es, this message translates to:
  /// **'Huésped físicamente en el alojamiento'**
  String get enum_booking_status_in_house_desc;

  /// No description provided for @enum_booking_status_checked_in_legacy_desc.
  ///
  /// In es, this message translates to:
  /// **'Check-in validado (legacy)'**
  String get enum_booking_status_checked_in_legacy_desc;

  /// No description provided for @enum_booking_status_checked_out_desc.
  ///
  /// In es, this message translates to:
  /// **'Check-out realizado, huésped ha salido'**
  String get enum_booking_status_checked_out_desc;

  /// No description provided for @enum_booking_status_closed_desc.
  ///
  /// In es, this message translates to:
  /// **'Reserva finalizada y cerrada'**
  String get enum_booking_status_closed_desc;

  /// No description provided for @enum_booking_status_cancelled_desc.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get enum_booking_status_cancelled_desc;

  /// No description provided for @enum_checkin_status_not_started.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get enum_checkin_status_not_started;

  /// No description provided for @enum_checkin_status_in_progress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get enum_checkin_status_in_progress;

  /// No description provided for @enum_checkin_status_submitted.
  ///
  /// In es, this message translates to:
  /// **'Enviado'**
  String get enum_checkin_status_submitted;

  /// No description provided for @enum_checkin_status_validated.
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get enum_checkin_status_validated;

  /// No description provided for @enum_checkin_status_rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get enum_checkin_status_rejected;

  /// No description provided for @enum_checkin_status_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get enum_checkin_status_cancelled;

  /// No description provided for @enum_checkin_status_not_started_desc.
  ///
  /// In es, this message translates to:
  /// **'El huésped aún no ha iniciado el check-in'**
  String get enum_checkin_status_not_started_desc;

  /// No description provided for @enum_checkin_status_in_progress_desc.
  ///
  /// In es, this message translates to:
  /// **'El huésped está completando sus datos'**
  String get enum_checkin_status_in_progress_desc;

  /// No description provided for @enum_checkin_status_submitted_desc.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de revisión por el administrador'**
  String get enum_checkin_status_submitted_desc;

  /// No description provided for @enum_checkin_status_validated_desc.
  ///
  /// In es, this message translates to:
  /// **'Check-in validado, estancia autorizada'**
  String get enum_checkin_status_validated_desc;

  /// No description provided for @enum_checkin_status_rejected_desc.
  ///
  /// In es, this message translates to:
  /// **'Requiere corrección por el huésped'**
  String get enum_checkin_status_rejected_desc;

  /// No description provided for @enum_checkin_status_cancelled_desc.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada, contacte con recepción'**
  String get enum_checkin_status_cancelled_desc;

  /// No description provided for @enum_checkout_status_not_started.
  ///
  /// In es, this message translates to:
  /// **'Sin iniciar'**
  String get enum_checkout_status_not_started;

  /// No description provided for @enum_checkout_status_requested.
  ///
  /// In es, this message translates to:
  /// **'Solicitado'**
  String get enum_checkout_status_requested;

  /// No description provided for @enum_checkout_status_validated.
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get enum_checkout_status_validated;

  /// No description provided for @enum_checkout_status_rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get enum_checkout_status_rejected;

  /// No description provided for @enum_checkout_status_not_started_desc.
  ///
  /// In es, this message translates to:
  /// **'La estancia aún está en curso'**
  String get enum_checkout_status_not_started_desc;

  /// No description provided for @enum_checkout_status_requested_desc.
  ///
  /// In es, this message translates to:
  /// **'El huésped ha solicitado el check-out'**
  String get enum_checkout_status_requested_desc;

  /// No description provided for @enum_checkout_status_validated_desc.
  ///
  /// In es, this message translates to:
  /// **'Check-out validado, reserva lista para cerrar'**
  String get enum_checkout_status_validated_desc;

  /// No description provided for @enum_checkout_status_rejected_desc.
  ///
  /// In es, this message translates to:
  /// **'Hay incidencias que resolver'**
  String get enum_checkout_status_rejected_desc;

  /// No description provided for @public_badge_exclusivity.
  ///
  /// In es, this message translates to:
  /// **'EXCLUSIVIDAD GARANTIZADA'**
  String get public_badge_exclusivity;

  /// No description provided for @public_hero_title_prefix.
  ///
  /// In es, this message translates to:
  /// **'Tu Estancia, '**
  String get public_hero_title_prefix;

  /// No description provided for @public_hero_title_suffix.
  ///
  /// In es, this message translates to:
  /// **'Elevada'**
  String get public_hero_title_suffix;

  /// No description provided for @public_cta_access_booking.
  ///
  /// In es, this message translates to:
  /// **'Acceder a mi Reserva'**
  String get public_cta_access_booking;

  /// No description provided for @public_services_section_title.
  ///
  /// In es, this message translates to:
  /// **'Nuestros Servicios'**
  String get public_services_section_title;

  /// No description provided for @public_footer_brand_name.
  ///
  /// In es, this message translates to:
  /// **'BF STAY'**
  String get public_footer_brand_name;

  /// No description provided for @public_footer_copyright.
  ///
  /// In es, this message translates to:
  /// **'© {year} BF Stay • Todos los derechos reservados'**
  String public_footer_copyright(int year);

  /// No description provided for @public_footer_privacy_policy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get public_footer_privacy_policy;

  /// No description provided for @public_service_checkin_title.
  ///
  /// In es, this message translates to:
  /// **'Check-in Digital'**
  String get public_service_checkin_title;

  /// No description provided for @public_service_checkin_desc.
  ///
  /// In es, this message translates to:
  /// **'Registro de entrada sin esperas.'**
  String get public_service_checkin_desc;

  /// No description provided for @public_service_checkout_title.
  ///
  /// In es, this message translates to:
  /// **'Check-out Digital'**
  String get public_service_checkout_title;

  /// No description provided for @public_service_checkout_desc.
  ///
  /// In es, this message translates to:
  /// **'Salida rápida y sencilla.'**
  String get public_service_checkout_desc;

  /// No description provided for @public_service_house_rules_title.
  ///
  /// In es, this message translates to:
  /// **'Normas de la Casa'**
  String get public_service_house_rules_title;

  /// No description provided for @public_service_house_rules_desc.
  ///
  /// In es, this message translates to:
  /// **'Reglas y recomendaciones.'**
  String get public_service_house_rules_desc;

  /// No description provided for @public_service_what_to_see_title.
  ///
  /// In es, this message translates to:
  /// **'¿Qué ver?'**
  String get public_service_what_to_see_title;

  /// No description provided for @public_service_what_to_see_desc.
  ///
  /// In es, this message translates to:
  /// **'Lugares de interés cercanos.'**
  String get public_service_what_to_see_desc;

  /// No description provided for @public_service_parking_title.
  ///
  /// In es, this message translates to:
  /// **'Aparcamientos'**
  String get public_service_parking_title;

  /// No description provided for @public_service_parking_desc.
  ///
  /// In es, this message translates to:
  /// **'Opciones de parking.'**
  String get public_service_parking_desc;

  /// No description provided for @public_service_chat_title.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get public_service_chat_title;

  /// No description provided for @public_service_chat_desc.
  ///
  /// In es, this message translates to:
  /// **'Conserje virtual 24/7.'**
  String get public_service_chat_desc;

  /// No description provided for @public_service_accommodations_title.
  ///
  /// In es, this message translates to:
  /// **'Alojamientos'**
  String get public_service_accommodations_title;

  /// No description provided for @public_service_accommodations_desc.
  ///
  /// In es, this message translates to:
  /// **'Otras propiedades.'**
  String get public_service_accommodations_desc;

  /// No description provided for @public_service_reviews_title.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get public_service_reviews_title;

  /// No description provided for @public_service_reviews_desc.
  ///
  /// In es, this message translates to:
  /// **'Opiniones de huéspedes.'**
  String get public_service_reviews_desc;

  /// No description provided for @public_service_parking_title_light.
  ///
  /// In es, this message translates to:
  /// **'Aparcamientos Cercanos'**
  String get public_service_parking_title_light;

  /// No description provided for @public_service_accommodations_title_light.
  ///
  /// In es, this message translates to:
  /// **'Nuestros Alojamientos'**
  String get public_service_accommodations_title_light;

  /// No description provided for @public_service_accommodations_desc_light.
  ///
  /// In es, this message translates to:
  /// **'Otras propiedades disponibles.'**
  String get public_service_accommodations_desc_light;

  /// No description provided for @public_service_reviews_title_light.
  ///
  /// In es, this message translates to:
  /// **'Reseñas y Comentarios'**
  String get public_service_reviews_title_light;

  /// No description provided for @public_hero_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión inteligente para alojamientos exclusivos.'**
  String get public_hero_subtitle;

  /// No description provided for @auth_login_brand_name.
  ///
  /// In es, this message translates to:
  /// **'BF Stay'**
  String get auth_login_brand_name;

  /// No description provided for @auth_login_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de Control'**
  String get auth_login_subtitle;

  /// No description provided for @auth_feature_bookings.
  ///
  /// In es, this message translates to:
  /// **'Gestión de reservas'**
  String get auth_feature_bookings;

  /// No description provided for @auth_feature_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in digital'**
  String get auth_feature_checkin;

  /// No description provided for @auth_feature_chat.
  ///
  /// In es, this message translates to:
  /// **'Chat con huéspedes'**
  String get auth_feature_chat;

  /// No description provided for @auth_feature_keyless.
  ///
  /// In es, this message translates to:
  /// **'Acceso sin llaves'**
  String get auth_feature_keyless;

  /// No description provided for @auth_field_email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get auth_field_email;

  /// No description provided for @auth_field_password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get auth_field_password;

  /// No description provided for @auth_validation_email_required.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu email'**
  String get auth_validation_email_required;

  /// No description provided for @auth_validation_email_invalid.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un email válido'**
  String get auth_validation_email_invalid;

  /// No description provided for @auth_validation_password_required.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu contraseña'**
  String get auth_validation_password_required;

  /// No description provided for @auth_validation_password_min_length.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get auth_validation_password_min_length;

  /// No description provided for @auth_forgot_password.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get auth_forgot_password;

  /// No description provided for @auth_login_button.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get auth_login_button;

  /// No description provided for @auth_divider_or.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get auth_divider_or;

  /// No description provided for @auth_guest_access_button.
  ///
  /// In es, this message translates to:
  /// **'Acceso con código de reserva'**
  String get auth_guest_access_button;

  /// No description provided for @auth_login_footer.
  ///
  /// In es, this message translates to:
  /// **'BF Stay © 2026'**
  String get auth_login_footer;

  /// No description provided for @auth_recover_password_title.
  ///
  /// In es, this message translates to:
  /// **'Recuperar Contraseña'**
  String get auth_recover_password_title;

  /// No description provided for @auth_recover_password_body.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu email y te enviaremos instrucciones para restablecer tu contraseña.'**
  String get auth_recover_password_body;

  /// No description provided for @auth_recover_password_sent.
  ///
  /// In es, this message translates to:
  /// **'Email de recuperación enviado'**
  String get auth_recover_password_sent;

  /// No description provided for @auth_button_send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get auth_button_send;

  /// No description provided for @auth_booking_access_title.
  ///
  /// In es, this message translates to:
  /// **'Acceso de Huésped'**
  String get auth_booking_access_title;

  /// No description provided for @auth_booking_benefit_code.
  ///
  /// In es, this message translates to:
  /// **'Código de reserva'**
  String get auth_booking_benefit_code;

  /// No description provided for @auth_booking_benefit_personal.
  ///
  /// In es, this message translates to:
  /// **'Acceso personalizado'**
  String get auth_booking_benefit_personal;

  /// No description provided for @auth_booking_benefit_instant.
  ///
  /// In es, this message translates to:
  /// **'Acceso instantáneo'**
  String get auth_booking_benefit_instant;

  /// No description provided for @auth_booking_benefit_secure_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in seguro'**
  String get auth_booking_benefit_secure_checkin;

  /// No description provided for @auth_booking_code_info_short.
  ///
  /// In es, this message translates to:
  /// **'El código de reserva lo recibiste en el email de confirmación.'**
  String get auth_booking_code_info_short;

  /// No description provided for @auth_booking_code_info_full.
  ///
  /// In es, this message translates to:
  /// **'El código de reserva lo recibiste en el email de confirmación de tu reserva.'**
  String get auth_booking_code_info_full;

  /// No description provided for @auth_booking_desktop_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Disfruta de tu estancia con acceso digital'**
  String get auth_booking_desktop_subtitle;

  /// No description provided for @auth_booking_form_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu código de reserva para acceder a tu alojamiento'**
  String get auth_booking_form_subtitle;

  /// No description provided for @auth_booking_field_code.
  ///
  /// In es, this message translates to:
  /// **'Código de Reserva'**
  String get auth_booking_field_code;

  /// No description provided for @auth_booking_code_hint.
  ///
  /// In es, this message translates to:
  /// **'XX-XXXX-XXXX'**
  String get auth_booking_code_hint;

  /// No description provided for @auth_booking_validation_code_required.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu código de reserva'**
  String get auth_booking_validation_code_required;

  /// No description provided for @auth_booking_validation_code_invalid.
  ///
  /// In es, this message translates to:
  /// **'El formato del código no es válido'**
  String get auth_booking_validation_code_invalid;

  /// No description provided for @auth_booking_access_button.
  ///
  /// In es, this message translates to:
  /// **'Acceder'**
  String get auth_booking_access_button;

  /// No description provided for @auth_booking_help_title.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde encuentro mi código?'**
  String get auth_booking_help_title;

  /// No description provided for @auth_booking_help_body.
  ///
  /// In es, this message translates to:
  /// **'El código de reserva lo recibiste en el email de confirmación de tu reserva. Tiene el formato BF-XXXXX.'**
  String get auth_booking_help_body;

  /// No description provided for @auth_booking_footer.
  ///
  /// In es, this message translates to:
  /// **'BF Stay © 2026'**
  String get auth_booking_footer;

  /// No description provided for @auth_booking_error_title.
  ///
  /// In es, this message translates to:
  /// **'Error de Acceso'**
  String get auth_booking_error_title;

  /// No description provided for @auth_booking_error_code_not_found.
  ///
  /// In es, this message translates to:
  /// **'El código de reserva no existe. Por favor, verifica que lo hayas escrito correctamente.'**
  String get auth_booking_error_code_not_found;

  /// No description provided for @auth_booking_error_code_expired.
  ///
  /// In es, this message translates to:
  /// **'Este código de reserva ha expirado. Contacta con recepción para obtener uno nuevo.'**
  String get auth_booking_error_code_expired;

  /// No description provided for @auth_booking_error_email_mismatch.
  ///
  /// In es, this message translates to:
  /// **'El email no coincide con el de la reserva. Verifica que sea el mismo email que usaste al reservar.'**
  String get auth_booking_error_email_mismatch;

  /// No description provided for @auth_booking_error_generic.
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar el código de reserva. Por favor, inténtalo de nuevo.'**
  String get auth_booking_error_generic;

  /// No description provided for @auth_booking_error_dismiss.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get auth_booking_error_dismiss;

  /// No description provided for @auth_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Acceso a tu reserva'**
  String get auth_sheet_title;

  /// No description provided for @auth_sheet_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu correo y el código que recibiste'**
  String get auth_sheet_subtitle;

  /// No description provided for @auth_sheet_label_email.
  ///
  /// In es, this message translates to:
  /// **'CORREO ELECTRÓNICO'**
  String get auth_sheet_label_email;

  /// No description provided for @auth_sheet_hint_email.
  ///
  /// In es, this message translates to:
  /// **'tu@correo.com'**
  String get auth_sheet_hint_email;

  /// No description provided for @auth_sheet_label_code.
  ///
  /// In es, this message translates to:
  /// **'CÓDIGO DE RESERVA'**
  String get auth_sheet_label_code;

  /// No description provided for @auth_sheet_hint_code.
  ///
  /// In es, this message translates to:
  /// **'BF-XXXX-XXXX'**
  String get auth_sheet_hint_code;

  /// No description provided for @auth_sheet_submit_button.
  ///
  /// In es, this message translates to:
  /// **'Acceder a mi reserva'**
  String get auth_sheet_submit_button;

  /// No description provided for @auth_sheet_help_text.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes tu código? Contacta con tu alojamiento'**
  String get auth_sheet_help_text;

  /// No description provided for @auth_admin_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Acceso privado'**
  String get auth_admin_sheet_title;

  /// No description provided for @auth_admin_sheet_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo personal autorizado de BF-Stay'**
  String get auth_admin_sheet_subtitle;

  /// No description provided for @auth_admin_label_email.
  ///
  /// In es, this message translates to:
  /// **'CORREO ELECTRÓNICO'**
  String get auth_admin_label_email;

  /// No description provided for @auth_admin_hint_email.
  ///
  /// In es, this message translates to:
  /// **'admin@bfstay.com'**
  String get auth_admin_hint_email;

  /// No description provided for @auth_admin_label_password.
  ///
  /// In es, this message translates to:
  /// **'CONTRASEÑA'**
  String get auth_admin_label_password;

  /// No description provided for @auth_admin_hint_password.
  ///
  /// In es, this message translates to:
  /// **'••••••••'**
  String get auth_admin_hint_password;

  /// No description provided for @auth_admin_error_unauthorized.
  ///
  /// In es, this message translates to:
  /// **'No tienes acceso a este panel'**
  String get auth_admin_error_unauthorized;

  /// No description provided for @auth_admin_submit_button.
  ///
  /// In es, this message translates to:
  /// **'Acceder al panel'**
  String get auth_admin_submit_button;

  /// No description provided for @guest_settings_title.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get guest_settings_title;

  /// No description provided for @guest_settings_section_language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get guest_settings_section_language;

  /// No description provided for @guest_settings_language_title.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la aplicación'**
  String get guest_settings_language_title;

  /// No description provided for @guest_settings_language_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el idioma de la interfaz'**
  String get guest_settings_language_subtitle;

  /// No description provided for @guest_settings_section_legal.
  ///
  /// In es, this message translates to:
  /// **'Legal'**
  String get guest_settings_section_legal;

  /// No description provided for @guest_settings_privacy_policy_title.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get guest_settings_privacy_policy_title;

  /// No description provided for @guest_settings_privacy_policy_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta nuestra política de privacidad'**
  String get guest_settings_privacy_policy_subtitle;

  /// No description provided for @guest_settings_privacy_open_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la política de privacidad'**
  String get guest_settings_privacy_open_error;

  /// No description provided for @notification_channel_name.
  ///
  /// In es, this message translates to:
  /// **'BF Stay Notificaciones'**
  String get notification_channel_name;

  /// No description provided for @notification_channel_description.
  ///
  /// In es, this message translates to:
  /// **'Canal de notificaciones de BF Stay'**
  String get notification_channel_description;

  /// No description provided for @notification_checkin_validated_title.
  ///
  /// In es, this message translates to:
  /// **'✅ Check-in Validado'**
  String get notification_checkin_validated_title;

  /// No description provided for @notification_checkin_validated_body.
  ///
  /// In es, this message translates to:
  /// **'Tu check-in ha sido validado correctamente. ¡Bienvenido!'**
  String get notification_checkin_validated_body;

  /// No description provided for @notification_checkin_rejected_title.
  ///
  /// In es, this message translates to:
  /// **'❌ Check-in Rechazado'**
  String get notification_checkin_rejected_title;

  /// No description provided for @notification_checkin_rejected_body.
  ///
  /// In es, this message translates to:
  /// **'Tu check-in ha sido rechazado. Por favor, revisa tu documentación.'**
  String get notification_checkin_rejected_body;

  /// No description provided for @notification_checkin_rejected_body_with_reason.
  ///
  /// In es, this message translates to:
  /// **'Tu check-in ha sido rechazado: {reason}'**
  String notification_checkin_rejected_body_with_reason(String reason);

  /// No description provided for @notification_booking_cancelled_title.
  ///
  /// In es, this message translates to:
  /// **'🚫 Reserva Cancelada'**
  String get notification_booking_cancelled_title;

  /// No description provided for @notification_booking_cancelled_body.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva ha sido cancelada. Contacta con recepción.'**
  String get notification_booking_cancelled_body;

  /// No description provided for @notification_booking_cancelled_body_with_reason.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva ha sido cancelada: {reason}'**
  String notification_booking_cancelled_body_with_reason(String reason);

  /// No description provided for @notification_checkin_status_update_title.
  ///
  /// In es, this message translates to:
  /// **'📋 Actualización de Check-in'**
  String get notification_checkin_status_update_title;

  /// No description provided for @notification_checkin_status_update_body.
  ///
  /// In es, this message translates to:
  /// **'El estado de tu check-in ha cambiado a: {status}'**
  String notification_checkin_status_update_body(String status);

  /// No description provided for @notification_admin_checkin_submitted_title.
  ///
  /// In es, this message translates to:
  /// **'📝 Nuevo Check-in Pendiente'**
  String get notification_admin_checkin_submitted_title;

  /// No description provided for @notification_admin_checkin_submitted_body.
  ///
  /// In es, this message translates to:
  /// **'{guestName} ha enviado su check-in para {unitName}. Pendiente de revisión.'**
  String notification_admin_checkin_submitted_body(
    String guestName,
    String unitName,
  );

  /// No description provided for @guest_parking_title.
  ///
  /// In es, this message translates to:
  /// **'Parkings'**
  String get guest_parking_title;

  /// No description provided for @guest_parking_available_singular.
  ///
  /// In es, this message translates to:
  /// **'parking disponible'**
  String get guest_parking_available_singular;

  /// No description provided for @guest_parking_available_plural.
  ///
  /// In es, this message translates to:
  /// **'parkings disponibles'**
  String get guest_parking_available_plural;

  /// No description provided for @guest_parking_error_loading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get guest_parking_error_loading;

  /// No description provided for @guest_parking_empty_title.
  ///
  /// In es, this message translates to:
  /// **'No hay parkings'**
  String get guest_parking_empty_title;

  /// No description provided for @guest_parking_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Pronto añadiremos información de parkings cercanos'**
  String get guest_parking_empty_subtitle;

  /// No description provided for @guest_parking_for_unit.
  ///
  /// In es, this message translates to:
  /// **'Parkings para {unitName}'**
  String guest_parking_for_unit(String unitName);

  /// No description provided for @guest_parking_gps_label.
  ///
  /// In es, this message translates to:
  /// **'GPS: {label}'**
  String guest_parking_gps_label(String label);

  /// No description provided for @guest_parking_info_zones_title.
  ///
  /// In es, this message translates to:
  /// **'INFORMACIÓN ZONAS DE APARCAMIENTO'**
  String get guest_parking_info_zones_title;

  /// No description provided for @guest_parking_plaza_arenal_title.
  ///
  /// In es, this message translates to:
  /// **'PARKING PLAZA ARENAL'**
  String get guest_parking_plaza_arenal_title;

  /// No description provided for @guest_parking_plaza_arenal_subtitle.
  ///
  /// In es, this message translates to:
  /// **'A unos 5 minutos andando'**
  String get guest_parking_plaza_arenal_subtitle;

  /// No description provided for @guest_parking_plaza_arenal_content.
  ///
  /// In es, this message translates to:
  /// **'• Abonando la estancia a través de la app El Parking: 6,95€/24h\n• Reservando a través de su web: 8€/24h (mínimo 24h)\n• Abonando el ticket en la máquina: 16€/24h'**
  String get guest_parking_plaza_arenal_content;

  /// No description provided for @guest_parking_centro_title.
  ///
  /// In es, this message translates to:
  /// **'PARKING EN ZONA CENTRO'**
  String get guest_parking_centro_title;

  /// No description provided for @guest_parking_centro_subtitle.
  ///
  /// In es, this message translates to:
  /// **'O.R.A AZUL'**
  String get guest_parking_centro_subtitle;

  /// No description provided for @guest_parking_centro_content.
  ///
  /// In es, this message translates to:
  /// **'• Lunes a Viernes: 9:00 - 13:30 y 17:00 - 20:00\n• Sábados: 9:00 - 14:00\n• Julio y Agosto: 9:00 - 14:00'**
  String get guest_parking_centro_content;

  /// No description provided for @guest_parking_free_zone_title.
  ///
  /// In es, this message translates to:
  /// **'PARKING ZONA GRATUITA'**
  String get guest_parking_free_zone_title;

  /// No description provided for @guest_parking_free_zone_subtitle.
  ///
  /// In es, this message translates to:
  /// **'A unos 10 minutos andando'**
  String get guest_parking_free_zone_subtitle;

  /// No description provided for @guest_parking_free_zone_content.
  ///
  /// In es, this message translates to:
  /// **'Zona libre de estacionamiento rotativo.'**
  String get guest_parking_free_zone_content;

  /// No description provided for @guest_checkin_camera_not_available.
  ///
  /// In es, this message translates to:
  /// **'No hay cámaras disponibles'**
  String get guest_checkin_camera_not_available;

  /// No description provided for @guest_checkin_camera_init_error.
  ///
  /// In es, this message translates to:
  /// **'Error al inicializar cámara: {error}'**
  String guest_checkin_camera_init_error(String error);

  /// No description provided for @guest_checkin_camera_capture_error.
  ///
  /// In es, this message translates to:
  /// **'Error al capturar: {error}'**
  String guest_checkin_camera_capture_error(String error);

  /// No description provided for @guest_checkin_camera_scan_title.
  ///
  /// In es, this message translates to:
  /// **'Escanear Documento'**
  String get guest_checkin_camera_scan_title;

  /// No description provided for @guest_checkin_camera_starting.
  ///
  /// In es, this message translates to:
  /// **'Iniciando cámara...'**
  String get guest_checkin_camera_starting;

  /// No description provided for @guest_checkin_camera_frame_hint.
  ///
  /// In es, this message translates to:
  /// **'Encuadra el documento dentro del recuadro'**
  String get guest_checkin_camera_frame_hint;

  /// No description provided for @guest_checkin_camera_document_label.
  ///
  /// In es, this message translates to:
  /// **'Documento de Identidad'**
  String get guest_checkin_camera_document_label;

  /// No description provided for @admin_chat_messages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get admin_chat_messages;

  /// No description provided for @admin_chat_conversation_deleted.
  ///
  /// In es, this message translates to:
  /// **'Conversación eliminada'**
  String get admin_chat_conversation_deleted;

  /// No description provided for @admin_chat_empty_title.
  ///
  /// In es, this message translates to:
  /// **'Sin conversaciones'**
  String get admin_chat_empty_title;

  /// No description provided for @admin_chat_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Las conversaciones con huéspedes\naparecerán aquí'**
  String get admin_chat_empty_subtitle;

  /// No description provided for @guest_chat_input_hint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get guest_chat_input_hint;

  /// No description provided for @admin_booking_detail_title.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Reserva'**
  String get admin_booking_detail_title;

  /// No description provided for @admin_booking_not_found.
  ///
  /// In es, this message translates to:
  /// **'Reserva no encontrada'**
  String get admin_booking_not_found;

  /// No description provided for @admin_booking_error.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String admin_booking_error(String error);

  /// No description provided for @admin_booking_error_validating.
  ///
  /// In es, this message translates to:
  /// **'Error al validar: {error}'**
  String admin_booking_error_validating(String error);

  /// No description provided for @admin_booking_error_rejecting.
  ///
  /// In es, this message translates to:
  /// **'Error al rechazar: {error}'**
  String admin_booking_error_rejecting(String error);

  /// No description provided for @admin_booking_error_validating_checkout.
  ///
  /// In es, this message translates to:
  /// **'Error al validar check-out: {error}'**
  String admin_booking_error_validating_checkout(String error);

  /// No description provided for @admin_booking_error_rejecting_checkout.
  ///
  /// In es, this message translates to:
  /// **'Error al rechazar check-out: {error}'**
  String admin_booking_error_rejecting_checkout(String error);

  /// No description provided for @admin_booking_error_closing.
  ///
  /// In es, this message translates to:
  /// **'Error al cerrar reserva: {error}'**
  String admin_booking_error_closing(String error);

  /// No description provided for @admin_booking_error_cancelling.
  ///
  /// In es, this message translates to:
  /// **'Error al cancelar reserva: {error}'**
  String admin_booking_error_cancelling(String error);

  /// No description provided for @admin_booking_error_deleting.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar reserva: {error}'**
  String admin_booking_error_deleting(String error);

  /// No description provided for @admin_booking_error_updating.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar: {error}'**
  String admin_booking_error_updating(String error);

  /// No description provided for @admin_booking_resend_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reenviar el código'**
  String get admin_booking_resend_error;

  /// No description provided for @admin_booking_notification_sent.
  ///
  /// In es, this message translates to:
  /// **'Notificación enviada correctamente'**
  String get admin_booking_notification_sent;

  /// No description provided for @admin_booking_notification_error.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar la notificación'**
  String get admin_booking_notification_error;

  /// No description provided for @admin_booking_code_resent.
  ///
  /// In es, this message translates to:
  /// **'Código reenviado correctamente'**
  String get admin_booking_code_resent;

  /// No description provided for @admin_booking_checkin_validated.
  ///
  /// In es, this message translates to:
  /// **'Check-in validado correctamente'**
  String get admin_booking_checkin_validated;

  /// No description provided for @admin_booking_checkin_rejected.
  ///
  /// In es, this message translates to:
  /// **'Check-in rechazado'**
  String get admin_booking_checkin_rejected;

  /// No description provided for @admin_booking_checkout_validated.
  ///
  /// In es, this message translates to:
  /// **'Check-out validado correctamente'**
  String get admin_booking_checkout_validated;

  /// No description provided for @admin_booking_checkout_rejected.
  ///
  /// In es, this message translates to:
  /// **'Check-out rechazado'**
  String get admin_booking_checkout_rejected;

  /// No description provided for @admin_booking_incidents_detected.
  ///
  /// In es, this message translates to:
  /// **'Incidencias detectadas'**
  String get admin_booking_incidents_detected;

  /// No description provided for @admin_booking_closed_successfully.
  ///
  /// In es, this message translates to:
  /// **'Reserva cerrada correctamente'**
  String get admin_booking_closed_successfully;

  /// No description provided for @admin_booking_cancelled_successfully.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada correctamente'**
  String get admin_booking_cancelled_successfully;

  /// No description provided for @admin_booking_deleted_successfully.
  ///
  /// In es, this message translates to:
  /// **'Reserva eliminada correctamente'**
  String get admin_booking_deleted_successfully;

  /// No description provided for @admin_booking_keybox_updated.
  ///
  /// In es, this message translates to:
  /// **'Código keybox actualizado'**
  String get admin_booking_keybox_updated;

  /// No description provided for @admin_booking_already_closed_title.
  ///
  /// In es, this message translates to:
  /// **'Reserva ya cerrada'**
  String get admin_booking_already_closed_title;

  /// No description provided for @admin_booking_already_closed_message.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya se encuentra cerrada.'**
  String get admin_booking_already_closed_message;

  /// No description provided for @admin_booking_already_cancelled_title.
  ///
  /// In es, this message translates to:
  /// **'Reserva ya cancelada'**
  String get admin_booking_already_cancelled_title;

  /// No description provided for @admin_booking_already_cancelled_message.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya se encuentra cancelada.'**
  String get admin_booking_already_cancelled_message;

  /// No description provided for @admin_booking_cannot_delete_title.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar'**
  String get admin_booking_cannot_delete_title;

  /// No description provided for @admin_booking_cannot_delete_message.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar una reserva en estado {status}.'**
  String admin_booking_cannot_delete_message(String status);

  /// No description provided for @admin_booking_cancel_booking.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Reserva'**
  String get admin_booking_cancel_booking;

  /// No description provided for @admin_booking_cancel_booking_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.'**
  String get admin_booking_cancel_booking_confirm;

  /// No description provided for @admin_booking_no_keep.
  ///
  /// In es, this message translates to:
  /// **'No, mantener'**
  String get admin_booking_no_keep;

  /// No description provided for @admin_booking_yes_cancel.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar'**
  String get admin_booking_yes_cancel;

  /// No description provided for @admin_booking_delete_booking.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Reserva'**
  String get admin_booking_delete_booking;

  /// No description provided for @admin_booking_delete_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar completamente esta reserva y todos sus datos asociados? Esta acción es irreversible.'**
  String get admin_booking_delete_confirm;

  /// No description provided for @admin_booking_close_booking.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Reserva'**
  String get admin_booking_close_booking;

  /// No description provided for @admin_booking_close_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas cerrar manualmente esta reserva? Se registrará la fecha de cierre.'**
  String get admin_booking_close_confirm;

  /// No description provided for @admin_booking_close_notes_hint.
  ///
  /// In es, this message translates to:
  /// **'Notas de cierre (opcional)'**
  String get admin_booking_close_notes_hint;

  /// No description provided for @admin_booking_reject_checkout.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Check-out'**
  String get admin_booking_reject_checkout;

  /// No description provided for @admin_booking_reject_checkout_desc.
  ///
  /// In es, this message translates to:
  /// **'Indica las incidencias detectadas para rechazar el check-out.'**
  String get admin_booking_reject_checkout_desc;

  /// No description provided for @admin_booking_incidents_hint.
  ///
  /// In es, this message translates to:
  /// **'Describe las incidencias detectadas...'**
  String get admin_booking_incidents_hint;

  /// No description provided for @admin_booking_reject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get admin_booking_reject;

  /// No description provided for @admin_booking_reject_checkin.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Check-in'**
  String get admin_booking_reject_checkin;

  /// No description provided for @admin_booking_reject_checkin_desc.
  ///
  /// In es, this message translates to:
  /// **'Indica el motivo del rechazo del check-in.'**
  String get admin_booking_reject_checkin_desc;

  /// No description provided for @admin_booking_reject_reason_hint.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo (opcional)...'**
  String get admin_booking_reject_reason_hint;

  /// No description provided for @admin_booking_share_code_message.
  ///
  /// In es, this message translates to:
  /// **'Tu código de acceso es: {code}'**
  String admin_booking_share_code_message(String code);

  /// No description provided for @admin_booking_share_keybox_code.
  ///
  /// In es, this message translates to:
  /// **'Código keybox: {code}'**
  String admin_booking_share_keybox_code(String code);

  /// No description provided for @admin_booking_share_dates.
  ///
  /// In es, this message translates to:
  /// **'Check-in: {checkIn} | Check-out: {checkOut}'**
  String admin_booking_share_dates(String checkIn, String checkOut);

  /// No description provided for @admin_booking_share_download_app.
  ///
  /// In es, this message translates to:
  /// **'Descarga la app: BF Stay'**
  String get admin_booking_share_download_app;

  /// No description provided for @admin_booking_edit_keybox_title.
  ///
  /// In es, this message translates to:
  /// **'Código Keybox'**
  String get admin_booking_edit_keybox_title;

  /// No description provided for @admin_booking_edit_keybox_desc.
  ///
  /// In es, this message translates to:
  /// **'Introduce el código de la caja de llaves'**
  String get admin_booking_edit_keybox_desc;

  /// No description provided for @admin_booking_checkin_done.
  ///
  /// In es, this message translates to:
  /// **'Check-in realizado'**
  String get admin_booking_checkin_done;

  /// No description provided for @admin_booking_checkout_done.
  ///
  /// In es, this message translates to:
  /// **'Check-out realizado'**
  String get admin_booking_checkout_done;

  /// No description provided for @admin_booking_units_label.
  ///
  /// In es, this message translates to:
  /// **'habitaciones'**
  String get admin_booking_units_label;

  /// No description provided for @admin_booking_email_sent.
  ///
  /// In es, this message translates to:
  /// **'Email enviado'**
  String get admin_booking_email_sent;

  /// No description provided for @admin_booking_email_pending.
  ///
  /// In es, this message translates to:
  /// **'Email pendiente'**
  String get admin_booking_email_pending;

  /// No description provided for @admin_booking_code_used.
  ///
  /// In es, this message translates to:
  /// **'Código usado'**
  String get admin_booking_code_used;

  /// No description provided for @admin_booking_code_unused.
  ///
  /// In es, this message translates to:
  /// **'Código sin usar'**
  String get admin_booking_code_unused;

  /// No description provided for @admin_booking_checkin_ok.
  ///
  /// In es, this message translates to:
  /// **'Check-in OK'**
  String get admin_booking_checkin_ok;

  /// No description provided for @admin_booking_checkin_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente validación'**
  String get admin_booking_checkin_pending;

  /// No description provided for @admin_booking_checkin_in_progress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get admin_booking_checkin_in_progress;

  /// No description provided for @admin_booking_no_checkin.
  ///
  /// In es, this message translates to:
  /// **'Sin check-in'**
  String get admin_booking_no_checkin;

  /// No description provided for @admin_booking_guest_section.
  ///
  /// In es, this message translates to:
  /// **'HUÉSPED'**
  String get admin_booking_guest_section;

  /// No description provided for @admin_booking_no_name.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get admin_booking_no_name;

  /// No description provided for @admin_booking_reservation_section.
  ///
  /// In es, this message translates to:
  /// **'RESERVA'**
  String get admin_booking_reservation_section;

  /// No description provided for @admin_booking_checkin_label.
  ///
  /// In es, this message translates to:
  /// **'Check-in'**
  String get admin_booking_checkin_label;

  /// No description provided for @admin_booking_checkout_label.
  ///
  /// In es, this message translates to:
  /// **'Check-out'**
  String get admin_booking_checkout_label;

  /// No description provided for @admin_booking_night_singular.
  ///
  /// In es, this message translates to:
  /// **'noche'**
  String get admin_booking_night_singular;

  /// No description provided for @admin_booking_night_plural.
  ///
  /// In es, this message translates to:
  /// **'noches'**
  String get admin_booking_night_plural;

  /// No description provided for @admin_booking_years_label.
  ///
  /// In es, this message translates to:
  /// **'años'**
  String get admin_booking_years_label;

  /// No description provided for @admin_booking_rooms_section.
  ///
  /// In es, this message translates to:
  /// **'Habitaciones'**
  String get admin_booking_rooms_section;

  /// No description provided for @admin_booking_wifi_label.
  ///
  /// In es, this message translates to:
  /// **'WiFi'**
  String get admin_booking_wifi_label;

  /// No description provided for @admin_booking_wifi_network_label.
  ///
  /// In es, this message translates to:
  /// **'Red:'**
  String get admin_booking_wifi_network_label;

  /// No description provided for @admin_booking_wifi_password_label.
  ///
  /// In es, this message translates to:
  /// **'Contraseña:'**
  String get admin_booking_wifi_password_label;

  /// No description provided for @admin_booking_wifi_password_clipboard.
  ///
  /// In es, this message translates to:
  /// **'Contraseña WiFi'**
  String get admin_booking_wifi_password_clipboard;

  /// No description provided for @admin_booking_access_code_label.
  ///
  /// In es, this message translates to:
  /// **'Código de acceso'**
  String get admin_booking_access_code_label;

  /// No description provided for @admin_booking_access_code_clipboard.
  ///
  /// In es, this message translates to:
  /// **'Código de acceso'**
  String get admin_booking_access_code_clipboard;

  /// No description provided for @admin_booking_access_instructions_label.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de acceso'**
  String get admin_booking_access_instructions_label;

  /// No description provided for @admin_booking_access_codes_section.
  ///
  /// In es, this message translates to:
  /// **'CÓDIGOS DE ACCESO'**
  String get admin_booking_access_codes_section;

  /// No description provided for @admin_booking_reservation_code_label.
  ///
  /// In es, this message translates to:
  /// **'Código de reserva'**
  String get admin_booking_reservation_code_label;

  /// No description provided for @admin_booking_share_button.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get admin_booking_share_button;

  /// No description provided for @admin_booking_keybox_not_set.
  ///
  /// In es, this message translates to:
  /// **'No configurado'**
  String get admin_booking_keybox_not_set;

  /// No description provided for @admin_booking_keybox_code_label.
  ///
  /// In es, this message translates to:
  /// **'Código Keybox'**
  String get admin_booking_keybox_code_label;

  /// No description provided for @admin_booking_keybox_code_clipboard.
  ///
  /// In es, this message translates to:
  /// **'Código Keybox'**
  String get admin_booking_keybox_code_clipboard;

  /// No description provided for @admin_booking_checkin_not_started.
  ///
  /// In es, this message translates to:
  /// **'Check-in no iniciado'**
  String get admin_booking_checkin_not_started;

  /// No description provided for @admin_booking_checkin_validated_status.
  ///
  /// In es, this message translates to:
  /// **'Check-in validado'**
  String get admin_booking_checkin_validated_status;

  /// No description provided for @admin_booking_checkin_rejected_status.
  ///
  /// In es, this message translates to:
  /// **'Check-in rechazado'**
  String get admin_booking_checkin_rejected_status;

  /// No description provided for @admin_booking_checkin_pending_validation.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de validación'**
  String get admin_booking_checkin_pending_validation;

  /// No description provided for @admin_booking_checkin_in_progress_status.
  ///
  /// In es, this message translates to:
  /// **'Check-in en progreso'**
  String get admin_booking_checkin_in_progress_status;

  /// No description provided for @admin_booking_checkin_section.
  ///
  /// In es, this message translates to:
  /// **'CHECK-IN'**
  String get admin_booking_checkin_section;

  /// No description provided for @admin_booking_docs_pending.
  ///
  /// In es, this message translates to:
  /// **'documentos pendientes'**
  String get admin_booking_docs_pending;

  /// No description provided for @admin_booking_validate_button.
  ///
  /// In es, this message translates to:
  /// **'Validar'**
  String get admin_booking_validate_button;

  /// No description provided for @admin_booking_reject_button.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get admin_booking_reject_button;

  /// No description provided for @admin_booking_internal_notes_section.
  ///
  /// In es, this message translates to:
  /// **'NOTAS INTERNAS'**
  String get admin_booking_internal_notes_section;

  /// No description provided for @admin_booking_closed_status.
  ///
  /// In es, this message translates to:
  /// **'Reserva cerrada'**
  String get admin_booking_closed_status;

  /// No description provided for @admin_booking_checkout_validated_status.
  ///
  /// In es, this message translates to:
  /// **'Check-out validado'**
  String get admin_booking_checkout_validated_status;

  /// No description provided for @admin_booking_checkout_incidents_status.
  ///
  /// In es, this message translates to:
  /// **'Check-out con incidencias'**
  String get admin_booking_checkout_incidents_status;

  /// No description provided for @admin_booking_checkout_requested_status.
  ///
  /// In es, this message translates to:
  /// **'Check-out solicitado'**
  String get admin_booking_checkout_requested_status;

  /// No description provided for @admin_booking_checkout_pending_status.
  ///
  /// In es, this message translates to:
  /// **'Check-out pendiente'**
  String get admin_booking_checkout_pending_status;

  /// No description provided for @admin_booking_checkout_section.
  ///
  /// In es, this message translates to:
  /// **'CHECK-OUT'**
  String get admin_booking_checkout_section;

  /// No description provided for @admin_booking_requested_label.
  ///
  /// In es, this message translates to:
  /// **'Solicitado:'**
  String get admin_booking_requested_label;

  /// No description provided for @admin_booking_notes_label.
  ///
  /// In es, this message translates to:
  /// **'Notas:'**
  String get admin_booking_notes_label;

  /// No description provided for @admin_booking_incidents_button.
  ///
  /// In es, this message translates to:
  /// **'Incidencias'**
  String get admin_booking_incidents_button;

  /// No description provided for @admin_booking_close_booking_button.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Reserva'**
  String get admin_booking_close_booking_button;

  /// No description provided for @admin_booking_close_booking_description.
  ///
  /// In es, this message translates to:
  /// **'El huésped no ha solicitado check-out. Puedes cerrar la reserva manualmente.'**
  String get admin_booking_close_booking_description;

  /// No description provided for @admin_booking_signature_section.
  ///
  /// In es, this message translates to:
  /// **'FIRMA DEL TITULAR'**
  String get admin_booking_signature_section;

  /// No description provided for @admin_booking_signature_unavailable.
  ///
  /// In es, this message translates to:
  /// **'Firma no disponible'**
  String get admin_booking_signature_unavailable;

  /// No description provided for @admin_booking_actions_section.
  ///
  /// In es, this message translates to:
  /// **'ACCIONES'**
  String get admin_booking_actions_section;

  /// No description provided for @admin_booking_resend_code_title.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código por email'**
  String get admin_booking_resend_code_title;

  /// No description provided for @admin_booking_last_sent_label.
  ///
  /// In es, this message translates to:
  /// **'Último envío:'**
  String get admin_booking_last_sent_label;

  /// No description provided for @admin_booking_na.
  ///
  /// In es, this message translates to:
  /// **'N/A'**
  String get admin_booking_na;

  /// No description provided for @admin_booking_not_sent_yet.
  ///
  /// In es, this message translates to:
  /// **'Aún no se ha enviado'**
  String get admin_booking_not_sent_yet;

  /// No description provided for @admin_booking_room_ready_title.
  ///
  /// In es, this message translates to:
  /// **'Habitación disponible'**
  String get admin_booking_room_ready_title;

  /// No description provided for @admin_booking_room_ready_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Notifica al huésped que la habitación está lista y puede acceder'**
  String get admin_booking_room_ready_subtitle;

  /// No description provided for @admin_booking_cancel_booking_title.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get admin_booking_cancel_booking_title;

  /// No description provided for @admin_booking_cancel_booking_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Marca la reserva como cancelada'**
  String get admin_booking_cancel_booking_subtitle;

  /// No description provided for @admin_booking_delete_booking_title.
  ///
  /// In es, this message translates to:
  /// **'Eliminar reserva'**
  String get admin_booking_delete_booking_title;

  /// No description provided for @admin_booking_delete_booking_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Borra completamente la reserva y sus datos (solo si no está finalizada)'**
  String get admin_booking_delete_booking_subtitle;

  /// No description provided for @admin_dashboard_admin_title.
  ///
  /// In es, this message translates to:
  /// **'BF-Stay Admin'**
  String get admin_dashboard_admin_title;

  /// No description provided for @admin_dashboard_tab_summary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get admin_dashboard_tab_summary;

  /// No description provided for @admin_dashboard_tab_bookings.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get admin_dashboard_tab_bookings;

  /// No description provided for @admin_dashboard_tab_checkins.
  ///
  /// In es, this message translates to:
  /// **'Check-ins'**
  String get admin_dashboard_tab_checkins;

  /// No description provided for @admin_dashboard_tab_invoices.
  ///
  /// In es, this message translates to:
  /// **'Facturas'**
  String get admin_dashboard_tab_invoices;

  /// No description provided for @admin_dashboard_tab_marketing.
  ///
  /// In es, this message translates to:
  /// **'Marketing'**
  String get admin_dashboard_tab_marketing;

  /// No description provided for @admin_dashboard_tab_properties.
  ///
  /// In es, this message translates to:
  /// **'Alojamientos'**
  String get admin_dashboard_tab_properties;

  /// No description provided for @guest_reviews_title.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get guest_reviews_title;

  /// No description provided for @guest_reviews_write_review.
  ///
  /// In es, this message translates to:
  /// **'Escribir reseña'**
  String get guest_reviews_write_review;

  /// No description provided for @guest_reviews_published.
  ///
  /// In es, this message translates to:
  /// **'Reseña publicada correctamente'**
  String get guest_reviews_published;

  /// No description provided for @guest_reviews_publishing.
  ///
  /// In es, this message translates to:
  /// **'Publicando reseña...'**
  String get guest_reviews_publishing;

  /// No description provided for @guest_reviews_updating.
  ///
  /// In es, this message translates to:
  /// **'Actualizando reseña...'**
  String get guest_reviews_updating;

  /// No description provided for @guest_reviews_deleting.
  ///
  /// In es, this message translates to:
  /// **'Eliminando reseña...'**
  String get guest_reviews_deleting;

  /// No description provided for @guest_reviews_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando reseñas...'**
  String get guest_reviews_loading;

  /// No description provided for @guest_reviews_delete_review.
  ///
  /// In es, this message translates to:
  /// **'Eliminar reseña'**
  String get guest_reviews_delete_review;

  /// No description provided for @guest_reviews_delete_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar tu reseña? Esta acción no se puede deshacer.'**
  String get guest_reviews_delete_confirm;

  /// No description provided for @guest_reviews_filter_all.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get guest_reviews_filter_all;

  /// No description provided for @guest_reviews_edit_review.
  ///
  /// In es, this message translates to:
  /// **'Editar reseña'**
  String get guest_reviews_edit_review;

  /// No description provided for @guest_reviews_new_review.
  ///
  /// In es, this message translates to:
  /// **'Nueva reseña'**
  String get guest_reviews_new_review;

  /// No description provided for @guest_reviews_updated.
  ///
  /// In es, this message translates to:
  /// **'Reseña actualizada'**
  String get guest_reviews_updated;

  /// No description provided for @guest_reviews_info_public.
  ///
  /// In es, this message translates to:
  /// **'Tu reseña será pública y ayudará a otros huéspedes a tomar decisiones.'**
  String get guest_reviews_info_public;

  /// No description provided for @guest_reviews_your_rating.
  ///
  /// In es, this message translates to:
  /// **'Tu valoración'**
  String get guest_reviews_your_rating;

  /// No description provided for @guest_reviews_tap_stars.
  ///
  /// In es, this message translates to:
  /// **'Toca las estrellas para puntuar'**
  String get guest_reviews_tap_stars;

  /// No description provided for @guest_reviews_rating_1.
  ///
  /// In es, this message translates to:
  /// **'Muy malo'**
  String get guest_reviews_rating_1;

  /// No description provided for @guest_reviews_rating_2.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get guest_reviews_rating_2;

  /// No description provided for @guest_reviews_rating_3.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get guest_reviews_rating_3;

  /// No description provided for @guest_reviews_rating_4.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get guest_reviews_rating_4;

  /// No description provided for @guest_reviews_rating_5.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get guest_reviews_rating_5;

  /// No description provided for @guest_reviews_title_label.
  ///
  /// In es, this message translates to:
  /// **'Título (opcional)'**
  String get guest_reviews_title_label;

  /// No description provided for @guest_reviews_title_hint.
  ///
  /// In es, this message translates to:
  /// **'Resume tu experiencia en una frase'**
  String get guest_reviews_title_hint;

  /// No description provided for @guest_reviews_comment_required.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe un comentario'**
  String get guest_reviews_comment_required;

  /// No description provided for @guest_reviews_comment_min_length.
  ///
  /// In es, this message translates to:
  /// **'El comentario debe tener al menos 10 caracteres'**
  String get guest_reviews_comment_min_length;

  /// No description provided for @guest_reviews_comment_label.
  ///
  /// In es, this message translates to:
  /// **'Tu comentario *'**
  String get guest_reviews_comment_label;

  /// No description provided for @guest_reviews_comment_hint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos tu experiencia...'**
  String get guest_reviews_comment_hint;

  /// No description provided for @guest_reviews_save_changes.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get guest_reviews_save_changes;

  /// No description provided for @guest_reviews_publish_review.
  ///
  /// In es, this message translates to:
  /// **'Publicar reseña'**
  String get guest_reviews_publish_review;

  /// No description provided for @guest_reviews_select_rating.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona una puntuación'**
  String get guest_reviews_select_rating;

  /// No description provided for @guest_reviews_saving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get guest_reviews_saving;

  /// No description provided for @guest_alojamientos_title.
  ///
  /// In es, this message translates to:
  /// **'Nuestros Alojamientos'**
  String get guest_alojamientos_title;

  /// No description provided for @guest_alojamientos_error_title.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get guest_alojamientos_error_title;

  /// No description provided for @guest_alojamientos_empty_title.
  ///
  /// In es, this message translates to:
  /// **'No hay alojamientos'**
  String get guest_alojamientos_empty_title;

  /// No description provided for @guest_alojamientos_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay alojamientos disponibles en este momento'**
  String get guest_alojamientos_empty_subtitle;

  /// No description provided for @guest_alojamientos_room_count.
  ///
  /// In es, this message translates to:
  /// **'{count} habitaciones'**
  String guest_alojamientos_room_count(int count);

  /// No description provided for @guest_alojamiento_detail_title.
  ///
  /// In es, this message translates to:
  /// **'Detalle'**
  String get guest_alojamiento_detail_title;

  /// No description provided for @guest_alojamiento_units_available.
  ///
  /// In es, this message translates to:
  /// **'Unidades disponibles'**
  String get guest_alojamiento_units_available;

  /// No description provided for @guest_alojamiento_no_units.
  ///
  /// In es, this message translates to:
  /// **'No hay unidades disponibles'**
  String get guest_alojamiento_no_units;

  /// No description provided for @guest_alojamiento_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get guest_alojamiento_location;

  /// No description provided for @guest_alojamiento_common_areas.
  ///
  /// In es, this message translates to:
  /// **'Zonas Comunes'**
  String get guest_alojamiento_common_areas;

  /// No description provided for @guest_alojamiento_shared_spaces.
  ///
  /// In es, this message translates to:
  /// **'Espacios compartidos'**
  String get guest_alojamiento_shared_spaces;

  /// No description provided for @guest_alojamiento_common_areas_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Disfruta de las áreas comunes del hotel'**
  String get guest_alojamiento_common_areas_subtitle;

  /// No description provided for @guest_alojamiento_no_photos.
  ///
  /// In es, this message translates to:
  /// **'No hay fotos'**
  String get guest_alojamiento_no_photos;

  /// No description provided for @guest_alojamiento_no_photos_subtitle.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron fotos de zonas comunes'**
  String get guest_alojamiento_no_photos_subtitle;

  /// No description provided for @guest_alojamiento_photos_count.
  ///
  /// In es, this message translates to:
  /// **'{count} fotos'**
  String guest_alojamiento_photos_count(int count);

  /// No description provided for @guest_alojamiento_hotel_rooms_title.
  ///
  /// In es, this message translates to:
  /// **'Hotel Boutique Jerez'**
  String get guest_alojamiento_hotel_rooms_title;

  /// No description provided for @guest_alojamiento_no_rooms.
  ///
  /// In es, this message translates to:
  /// **'No hay habitaciones'**
  String get guest_alojamiento_no_rooms;

  /// No description provided for @guest_alojamiento_no_rooms_subtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay habitaciones disponibles en este momento'**
  String get guest_alojamiento_no_rooms_subtitle;

  /// No description provided for @guest_alojamiento_rooms.
  ///
  /// In es, this message translates to:
  /// **'Habitaciones'**
  String get guest_alojamiento_rooms;

  /// No description provided for @guest_alojamiento_features.
  ///
  /// In es, this message translates to:
  /// **'Características'**
  String get guest_alojamiento_features;

  /// No description provided for @guest_alojamiento_feature_flexible_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in flexible'**
  String get guest_alojamiento_feature_flexible_checkin;

  /// No description provided for @guest_alojamiento_feature_wifi.
  ///
  /// In es, this message translates to:
  /// **'WiFi gratuito'**
  String get guest_alojamiento_feature_wifi;

  /// No description provided for @guest_alojamiento_feature_ac.
  ///
  /// In es, this message translates to:
  /// **'Aire acondicionado'**
  String get guest_alojamiento_feature_ac;

  /// No description provided for @guest_alojamiento_description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get guest_alojamiento_description;

  /// No description provided for @guest_alojamiento_description_text.
  ///
  /// In es, this message translates to:
  /// **'Descubre este {unitType} completamente equipado para que tu estancia sea lo más cómoda posible. Cuenta con todo lo necesario para disfrutar de Jerez a tu ritmo.'**
  String guest_alojamiento_description_text(String unitType);

  /// No description provided for @guest_alojamiento_services.
  ///
  /// In es, this message translates to:
  /// **'Servicios incluidos'**
  String get guest_alojamiento_services;

  /// No description provided for @guest_alojamiento_service_kitchen.
  ///
  /// In es, this message translates to:
  /// **'Cocina equipada'**
  String get guest_alojamiento_service_kitchen;

  /// No description provided for @guest_alojamiento_service_washer.
  ///
  /// In es, this message translates to:
  /// **'Lavadora'**
  String get guest_alojamiento_service_washer;

  /// No description provided for @guest_alojamiento_service_tv.
  ///
  /// In es, this message translates to:
  /// **'Smart TV'**
  String get guest_alojamiento_service_tv;

  /// No description provided for @guest_alojamiento_service_bedding.
  ///
  /// In es, this message translates to:
  /// **'Ropa de cama'**
  String get guest_alojamiento_service_bedding;

  /// No description provided for @guest_alojamiento_service_towels.
  ///
  /// In es, this message translates to:
  /// **'Toallas'**
  String get guest_alojamiento_service_towels;

  /// No description provided for @guest_alojamiento_service_coffee.
  ///
  /// In es, this message translates to:
  /// **'Cafetera'**
  String get guest_alojamiento_service_coffee;

  /// No description provided for @guest_alojamiento_access_info.
  ///
  /// In es, this message translates to:
  /// **'Información de acceso'**
  String get guest_alojamiento_access_info;

  /// No description provided for @guest_alojamiento_box_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de la caja'**
  String get guest_alojamiento_box_location;

  /// No description provided for @guest_alojamiento_access_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de acceso'**
  String get guest_alojamiento_access_instructions;

  /// No description provided for @guest_house_rules_title.
  ///
  /// In es, this message translates to:
  /// **'Normas de la Casa'**
  String get guest_house_rules_title;

  /// No description provided for @guest_house_rules_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta las normas y recomendaciones'**
  String get guest_house_rules_subtitle;

  /// No description provided for @guest_house_rules_empty_title.
  ///
  /// In es, this message translates to:
  /// **'No hay normas'**
  String get guest_house_rules_empty_title;

  /// No description provided for @guest_house_rules_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Este alojamiento no tiene normas registradas'**
  String get guest_house_rules_empty_subtitle;

  /// No description provided for @guest_normas_title.
  ///
  /// In es, this message translates to:
  /// **'Normas'**
  String get guest_normas_title;

  /// No description provided for @guest_normas_hotel_title.
  ///
  /// In es, this message translates to:
  /// **'Normas del Hotel'**
  String get guest_normas_hotel_title;

  /// No description provided for @guest_normas_apartment_title.
  ///
  /// In es, this message translates to:
  /// **'Normas del Apartamento'**
  String get guest_normas_apartment_title;

  /// No description provided for @guest_normas_not_available.
  ///
  /// In es, this message translates to:
  /// **'No hay normas disponibles'**
  String get guest_normas_not_available;

  /// No description provided for @guest_normas_image_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la imagen'**
  String get guest_normas_image_error;

  /// No description provided for @guest_normas_generic_error.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error'**
  String get guest_normas_generic_error;

  /// No description provided for @guest_que_ver_title.
  ///
  /// In es, this message translates to:
  /// **'¿Qué ver?'**
  String get guest_que_ver_title;

  /// No description provided for @guest_que_ver_clear_filters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get guest_que_ver_clear_filters;

  /// No description provided for @guest_que_ver_places_count.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 lugar} other{{count} lugares}}'**
  String guest_que_ver_places_count(int count);

  /// No description provided for @guest_que_ver_no_results.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get guest_que_ver_no_results;

  /// No description provided for @guest_que_ver_no_places.
  ///
  /// In es, this message translates to:
  /// **'No hay lugares'**
  String get guest_que_ver_no_places;

  /// No description provided for @guest_que_ver_try_filters.
  ///
  /// In es, this message translates to:
  /// **'Prueba a cambiar los filtros de búsqueda'**
  String get guest_que_ver_try_filters;

  /// No description provided for @guest_que_ver_coming_soon.
  ///
  /// In es, this message translates to:
  /// **'Pronto añadiremos nuevos lugares'**
  String get guest_que_ver_coming_soon;

  /// No description provided for @guest_que_ver_error_loading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el lugar'**
  String get guest_que_ver_error_loading;

  /// No description provided for @guest_que_ver_place_not_found.
  ///
  /// In es, this message translates to:
  /// **'Lugar no encontrado'**
  String get guest_que_ver_place_not_found;

  /// No description provided for @guest_que_ver_about_place.
  ///
  /// In es, this message translates to:
  /// **'Sobre este lugar'**
  String get guest_que_ver_about_place;

  /// No description provided for @guest_que_ver_address.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get guest_que_ver_address;

  /// No description provided for @guest_que_ver_best_time.
  ///
  /// In es, this message translates to:
  /// **'Mejor momento'**
  String get guest_que_ver_best_time;

  /// No description provided for @guest_que_ver_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get guest_que_ver_location;

  /// No description provided for @guest_que_ver_practical_info.
  ///
  /// In es, this message translates to:
  /// **'Información práctica'**
  String get guest_que_ver_practical_info;

  /// No description provided for @guest_que_ver_tips.
  ///
  /// In es, this message translates to:
  /// **'Consejos'**
  String get guest_que_ver_tips;

  /// No description provided for @guest_que_ver_free_entry.
  ///
  /// In es, this message translates to:
  /// **'Entrada gratuita'**
  String get guest_que_ver_free_entry;

  /// No description provided for @guest_que_ver_how_to_get.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get guest_que_ver_how_to_get;

  /// No description provided for @guest_que_ver_copy_link.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get guest_que_ver_copy_link;

  /// No description provided for @guest_que_ver_official_web.
  ///
  /// In es, this message translates to:
  /// **'Web oficial'**
  String get guest_que_ver_official_web;

  /// No description provided for @guest_que_ver_link_copied.
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado al portapapeles'**
  String get guest_que_ver_link_copied;

  /// No description provided for @guest_reviews_verified.
  ///
  /// In es, this message translates to:
  /// **'Verificado'**
  String get guest_reviews_verified;

  /// No description provided for @guest_reviews_show_less.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get guest_reviews_show_less;

  /// No description provided for @guest_reviews_show_more.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get guest_reviews_show_more;

  /// No description provided for @guest_reviews_empty_title.
  ///
  /// In es, this message translates to:
  /// **'Sin reseñas aún'**
  String get guest_reviews_empty_title;

  /// No description provided for @guest_reviews_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Sé el primero en compartir tu experiencia'**
  String get guest_reviews_empty_subtitle;

  /// No description provided for @guest_reviews_write_first.
  ///
  /// In es, this message translates to:
  /// **'Escribir reseña'**
  String get guest_reviews_write_first;

  /// No description provided for @guest_reviews_filter_empty_title.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para {filter}'**
  String guest_reviews_filter_empty_title(String filter);

  /// No description provided for @guest_reviews_filter_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Prueba a seleccionar otro filtro'**
  String get guest_reviews_filter_empty_subtitle;

  /// No description provided for @guest_reviews_clear_filter.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtro'**
  String get guest_reviews_clear_filter;

  /// No description provided for @guest_reviews_count_label.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 reseña} other{{count} reseñas}}'**
  String guest_reviews_count_label(int count);

  /// No description provided for @guest_reviews_no_reviews_title.
  ///
  /// In es, this message translates to:
  /// **'Sin reseñas aún'**
  String get guest_reviews_no_reviews_title;

  /// No description provided for @guest_reviews_be_first.
  ///
  /// In es, this message translates to:
  /// **'Sé el primero'**
  String get guest_reviews_be_first;

  /// No description provided for @guest_access_no_booking.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la reserva'**
  String get guest_access_no_booking;

  /// No description provided for @guest_access_error_loading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los datos de acceso'**
  String get guest_access_error_loading;

  /// No description provided for @guest_access_title.
  ///
  /// In es, this message translates to:
  /// **'Acceso'**
  String get guest_access_title;

  /// No description provided for @guest_access_no_codes.
  ///
  /// In es, this message translates to:
  /// **'No hay códigos de acceso disponibles'**
  String get guest_access_no_codes;

  /// No description provided for @guest_access_codes_title.
  ///
  /// In es, this message translates to:
  /// **'Códigos de Acceso'**
  String get guest_access_codes_title;

  /// No description provided for @guest_access_codes_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa estos códigos para acceder a tu alojamiento'**
  String get guest_access_codes_subtitle;

  /// No description provided for @guest_access_main_code.
  ///
  /// In es, this message translates to:
  /// **'Código principal'**
  String get guest_access_main_code;

  /// No description provided for @guest_access_main_door.
  ///
  /// In es, this message translates to:
  /// **'Puerta principal'**
  String get guest_access_main_door;

  /// No description provided for @guest_access_valid_period.
  ///
  /// In es, this message translates to:
  /// **'Válido del {from} al {until}'**
  String guest_access_valid_period(String from, String until);

  /// No description provided for @guest_access_wifi_title.
  ///
  /// In es, this message translates to:
  /// **'WiFi'**
  String get guest_access_wifi_title;

  /// No description provided for @guest_access_wifi_network.
  ///
  /// In es, this message translates to:
  /// **'Red:'**
  String get guest_access_wifi_network;

  /// No description provided for @guest_access_wifi_password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña:'**
  String get guest_access_wifi_password;

  /// No description provided for @guest_access_password_copied.
  ///
  /// In es, this message translates to:
  /// **'Contraseña copiada al portapapeles'**
  String get guest_access_password_copied;

  /// No description provided for @guest_access_other_accesses.
  ///
  /// In es, this message translates to:
  /// **'Otros accesos'**
  String get guest_access_other_accesses;

  /// No description provided for @guest_access_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de acceso'**
  String get guest_access_instructions;

  /// No description provided for @guest_guide_title.
  ///
  /// In es, this message translates to:
  /// **'Guía de Estancia'**
  String get guest_guide_title;

  /// No description provided for @guest_guide_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Toda la información de tu estancia'**
  String get guest_guide_subtitle;

  /// No description provided for @guest_guide_contact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get guest_guide_contact;

  /// No description provided for @guest_guide_phone_1.
  ///
  /// In es, this message translates to:
  /// **'Teléfono 1'**
  String get guest_guide_phone_1;

  /// No description provided for @guest_guide_phone_2.
  ///
  /// In es, this message translates to:
  /// **'Teléfono 2'**
  String get guest_guide_phone_2;

  /// No description provided for @guest_guide_your_data.
  ///
  /// In es, this message translates to:
  /// **'Tus Datos'**
  String get guest_guide_your_data;

  /// No description provided for @guest_guide_accommodation.
  ///
  /// In es, this message translates to:
  /// **'Alojamiento'**
  String get guest_guide_accommodation;

  /// No description provided for @guest_guide_property.
  ///
  /// In es, this message translates to:
  /// **'Propiedad'**
  String get guest_guide_property;

  /// No description provided for @guest_guide_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in'**
  String get guest_guide_checkin;

  /// No description provided for @guest_guide_checkout.
  ///
  /// In es, this message translates to:
  /// **'Check-out'**
  String get guest_guide_checkout;

  /// No description provided for @guest_guide_guests.
  ///
  /// In es, this message translates to:
  /// **'Huéspedes'**
  String get guest_guide_guests;

  /// No description provided for @guest_guide_services.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get guest_guide_services;

  /// No description provided for @guest_guide_wifi.
  ///
  /// In es, this message translates to:
  /// **'WiFi'**
  String get guest_guide_wifi;

  /// No description provided for @guest_guide_laundry.
  ///
  /// In es, this message translates to:
  /// **'Lavandería'**
  String get guest_guide_laundry;

  /// No description provided for @guest_guide_laundry_desc.
  ///
  /// In es, this message translates to:
  /// **'Servicio de lavandería disponible'**
  String get guest_guide_laundry_desc;

  /// No description provided for @guest_guide_jacuzzi.
  ///
  /// In es, this message translates to:
  /// **'Jacuzzi'**
  String get guest_guide_jacuzzi;

  /// No description provided for @guest_guide_ac.
  ///
  /// In es, this message translates to:
  /// **'Aire Acondicionado'**
  String get guest_guide_ac;

  /// No description provided for @guest_guide_ac_title.
  ///
  /// In es, this message translates to:
  /// **'Aire Acondicionado'**
  String get guest_guide_ac_title;

  /// No description provided for @guest_guide_ac_desc.
  ///
  /// In es, this message translates to:
  /// **'Control de climatización en tu alojamiento'**
  String get guest_guide_ac_desc;

  /// No description provided for @guest_guide_tv.
  ///
  /// In es, this message translates to:
  /// **'TV'**
  String get guest_guide_tv;

  /// No description provided for @guest_guide_tv_title.
  ///
  /// In es, this message translates to:
  /// **'Televisión'**
  String get guest_guide_tv_title;

  /// No description provided for @guest_guide_tv_desc.
  ///
  /// In es, this message translates to:
  /// **'Smart TV con canales y aplicaciones'**
  String get guest_guide_tv_desc;

  /// No description provided for @guest_guide_not_available.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get guest_guide_not_available;

  /// No description provided for @guest_guide_wifi_desc.
  ///
  /// In es, this message translates to:
  /// **'Conexión WiFi incluida'**
  String get guest_guide_wifi_desc;

  /// No description provided for @guest_guide_house_rules.
  ///
  /// In es, this message translates to:
  /// **'Normas de la Casa'**
  String get guest_guide_house_rules;

  /// No description provided for @guest_guide_rule_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in a partir de las 16:00'**
  String get guest_guide_rule_checkin;

  /// No description provided for @guest_guide_rule_checkout.
  ///
  /// In es, this message translates to:
  /// **'Check-out antes de las {time}'**
  String guest_guide_rule_checkout(String time);

  /// No description provided for @guest_guide_rule_no_smoking.
  ///
  /// In es, this message translates to:
  /// **'No fumador'**
  String get guest_guide_rule_no_smoking;

  /// No description provided for @guest_guide_rule_no_parties.
  ///
  /// In es, this message translates to:
  /// **'No se permiten fiestas'**
  String get guest_guide_rule_no_parties;

  /// No description provided for @guest_guide_rule_no_pets.
  ///
  /// In es, this message translates to:
  /// **'No se admiten mascotas'**
  String get guest_guide_rule_no_pets;

  /// No description provided for @guest_notifications_title.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get guest_notifications_title;

  /// No description provided for @guest_notifications_delete_all.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todo'**
  String get guest_notifications_delete_all;

  /// No description provided for @guest_notifications_delete_all_title.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas las notificaciones'**
  String get guest_notifications_delete_all_title;

  /// No description provided for @guest_notifications_delete_all_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar todas las notificaciones? Esta acción no se puede deshacer.'**
  String get guest_notifications_delete_all_confirm;

  /// No description provided for @guest_notifications_unread_count.
  ///
  /// In es, this message translates to:
  /// **'{count} sin leer'**
  String guest_notifications_unread_count(int count);

  /// No description provided for @guest_notifications_mark_all.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get guest_notifications_mark_all;

  /// No description provided for @guest_notifications_empty_title.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get guest_notifications_empty_title;

  /// No description provided for @guest_notifications_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán las notificaciones de tu estancia'**
  String get guest_notifications_empty_subtitle;

  /// No description provided for @guest_notifications_read.
  ///
  /// In es, this message translates to:
  /// **'Leído'**
  String get guest_notifications_read;

  /// No description provided for @guest_romantic_title.
  ///
  /// In es, this message translates to:
  /// **'Pack Romántico'**
  String get guest_romantic_title;

  /// No description provided for @guest_romantic_surprise.
  ///
  /// In es, this message translates to:
  /// **'Sorprende a tu pareja'**
  String get guest_romantic_surprise;

  /// No description provided for @guest_romantic_unforgettable.
  ///
  /// In es, this message translates to:
  /// **'Crea un momento inolvidable'**
  String get guest_romantic_unforgettable;

  /// No description provided for @guest_romantic_includes.
  ///
  /// In es, this message translates to:
  /// **'¿Qué incluye?'**
  String get guest_romantic_includes;

  /// No description provided for @guest_romantic_decoration_title.
  ///
  /// In es, this message translates to:
  /// **'Decoración Romántica'**
  String get guest_romantic_decoration_title;

  /// No description provided for @guest_romantic_decoration_desc.
  ///
  /// In es, this message translates to:
  /// **'Pétalos de rosa, velas y decoración especial en la habitación'**
  String get guest_romantic_decoration_desc;

  /// No description provided for @guest_romantic_choose_title.
  ///
  /// In es, this message translates to:
  /// **'Elige tu detalle'**
  String get guest_romantic_choose_title;

  /// No description provided for @guest_romantic_choose_desc.
  ///
  /// In es, this message translates to:
  /// **'Botella de cava o chocolate artesanal para acompañar la velada'**
  String get guest_romantic_choose_desc;

  /// No description provided for @guest_romantic_basic_pack.
  ///
  /// In es, this message translates to:
  /// **'Pack Romántico Básico'**
  String get guest_romantic_basic_pack;

  /// No description provided for @guest_romantic_price.
  ///
  /// In es, this message translates to:
  /// **'20,00 €'**
  String get guest_romantic_price;

  /// No description provided for @guest_romantic_book_now.
  ///
  /// In es, this message translates to:
  /// **'Reservar Ahora'**
  String get guest_romantic_book_now;

  /// No description provided for @guest_romantic_customize.
  ///
  /// In es, this message translates to:
  /// **'O personalízalo con extras al reservar'**
  String get guest_romantic_customize;

  /// No description provided for @guest_romantic_redirect.
  ///
  /// In es, this message translates to:
  /// **'Vas a ser redirigido a la web para completar la reserva del Pack Romántico. ¿Continuar?'**
  String get guest_romantic_redirect;

  /// No description provided for @guest_romantic_how_to.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo reservar?'**
  String get guest_romantic_how_to;

  /// No description provided for @guest_romantic_step_1.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el Pack Romántico'**
  String get guest_romantic_step_1;

  /// No description provided for @guest_romantic_step_2.
  ///
  /// In es, this message translates to:
  /// **'Personaliza los detalles'**
  String get guest_romantic_step_2;

  /// No description provided for @guest_romantic_step_3.
  ///
  /// In es, this message translates to:
  /// **'Completa la reserva online'**
  String get guest_romantic_step_3;

  /// No description provided for @guest_romantic_step_4.
  ///
  /// In es, this message translates to:
  /// **'Disfruta de la sorpresa'**
  String get guest_romantic_step_4;

  /// No description provided for @guest_romantic_note.
  ///
  /// In es, this message translates to:
  /// **'La decoración se prepara durante tu ausencia para que sea una sorpresa completa.'**
  String get guest_romantic_note;

  /// No description provided for @guest_jacuzzi_title.
  ///
  /// In es, this message translates to:
  /// **'Jacuzzi'**
  String get guest_jacuzzi_title;

  /// No description provided for @guest_jacuzzi_rules_title.
  ///
  /// In es, this message translates to:
  /// **'Normas de Uso'**
  String get guest_jacuzzi_rules_title;

  /// No description provided for @guest_jacuzzi_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Relájate y disfruta'**
  String get guest_jacuzzi_subtitle;

  /// No description provided for @guest_jacuzzi_power.
  ///
  /// In es, this message translates to:
  /// **'Encendido'**
  String get guest_jacuzzi_power;

  /// No description provided for @guest_jacuzzi_power_step_1.
  ///
  /// In es, this message translates to:
  /// **'Pulsa el botón POWER para encender el jacuzzi'**
  String get guest_jacuzzi_power_step_1;

  /// No description provided for @guest_jacuzzi_power_step_2.
  ///
  /// In es, this message translates to:
  /// **'Espera a que el panel se ilumine'**
  String get guest_jacuzzi_power_step_2;

  /// No description provided for @guest_jacuzzi_power_step_3.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la temperatura deseada con los botones + y -'**
  String get guest_jacuzzi_power_step_3;

  /// No description provided for @guest_jacuzzi_lock.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo del Panel'**
  String get guest_jacuzzi_lock;

  /// No description provided for @guest_jacuzzi_lock_step_1.
  ///
  /// In es, this message translates to:
  /// **'Para evitar activaciones accidentales, puedes bloquear el panel de control'**
  String get guest_jacuzzi_lock_step_1;

  /// No description provided for @guest_jacuzzi_lock_unlock.
  ///
  /// In es, this message translates to:
  /// **'Desbloqueo'**
  String get guest_jacuzzi_lock_unlock;

  /// No description provided for @guest_jacuzzi_lock_unlock_step.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado el botón LOCK durante 3 segundos'**
  String get guest_jacuzzi_lock_unlock_step;

  /// No description provided for @guest_jacuzzi_lock_manual.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo Manual'**
  String get guest_jacuzzi_lock_manual;

  /// No description provided for @guest_jacuzzi_lock_manual_step.
  ///
  /// In es, this message translates to:
  /// **'Pulsa y mantén el botón LOCK durante 3 segundos para activar'**
  String get guest_jacuzzi_lock_manual_step;

  /// No description provided for @guest_jacuzzi_ozone.
  ///
  /// In es, this message translates to:
  /// **'Función Ozono'**
  String get guest_jacuzzi_ozone;

  /// No description provided for @guest_jacuzzi_ozone_intro.
  ///
  /// In es, this message translates to:
  /// **'El sistema de ozono ayuda a mantener el agua limpia y desinfectada de forma automática.'**
  String get guest_jacuzzi_ozone_intro;

  /// No description provided for @guest_jacuzzi_ozone_step_1.
  ///
  /// In es, this message translates to:
  /// **'Pulsa el botón OZONE en el panel'**
  String get guest_jacuzzi_ozone_step_1;

  /// No description provided for @guest_jacuzzi_ozone_step_2.
  ///
  /// In es, this message translates to:
  /// **'Se activará la luz indicadora'**
  String get guest_jacuzzi_ozone_step_2;

  /// No description provided for @guest_jacuzzi_ozone_step_3.
  ///
  /// In es, this message translates to:
  /// **'El sistema se ejecutará durante 30 minutos'**
  String get guest_jacuzzi_ozone_step_3;

  /// No description provided for @guest_jacuzzi_ozone_step_4.
  ///
  /// In es, this message translates to:
  /// **'Se desactivará automáticamente al finalizar'**
  String get guest_jacuzzi_ozone_step_4;

  /// No description provided for @guest_jacuzzi_ozone_note.
  ///
  /// In es, this message translates to:
  /// **'Nota: {note}'**
  String guest_jacuzzi_ozone_note(String note);

  /// No description provided for @guest_jacuzzi_massage.
  ///
  /// In es, this message translates to:
  /// **'Funciones de Masaje'**
  String get guest_jacuzzi_massage;

  /// No description provided for @guest_jacuzzi_air_jets.
  ///
  /// In es, this message translates to:
  /// **'Jets de Aire'**
  String get guest_jacuzzi_air_jets;

  /// No description provided for @guest_jacuzzi_air_step_1.
  ///
  /// In es, this message translates to:
  /// **'Pulsa el botón AIR para activar los jets de aire'**
  String get guest_jacuzzi_air_step_1;

  /// No description provided for @guest_jacuzzi_air_step_2.
  ///
  /// In es, this message translates to:
  /// **'Ajusta la intensidad con los botones + y -'**
  String get guest_jacuzzi_air_step_2;

  /// No description provided for @guest_jacuzzi_air_step_3.
  ///
  /// In es, this message translates to:
  /// **'Los jets crearán burbujas suaves en el agua'**
  String get guest_jacuzzi_air_step_3;

  /// No description provided for @guest_jacuzzi_air_step_4.
  ///
  /// In es, this message translates to:
  /// **'Pulsa de nuevo para desactivar'**
  String get guest_jacuzzi_air_step_4;

  /// No description provided for @guest_jacuzzi_water_jets.
  ///
  /// In es, this message translates to:
  /// **'Jets de Agua'**
  String get guest_jacuzzi_water_jets;

  /// No description provided for @guest_jacuzzi_water_step_1.
  ///
  /// In es, this message translates to:
  /// **'Pulsa el botón JET para activar los jets de agua'**
  String get guest_jacuzzi_water_step_1;

  /// No description provided for @guest_jacuzzi_water_step_2.
  ///
  /// In es, this message translates to:
  /// **'Los jets de agua proporcionan un masaje más intenso'**
  String get guest_jacuzzi_water_step_2;

  /// No description provided for @guest_jacuzzi_water_step_3.
  ///
  /// In es, this message translates to:
  /// **'Dirige los jets hacia las zonas de tensión muscular'**
  String get guest_jacuzzi_water_step_3;

  /// No description provided for @guest_jacuzzi_water_step_4.
  ///
  /// In es, this message translates to:
  /// **'Pulsa de nuevo para desactivar'**
  String get guest_jacuzzi_water_step_4;

  /// No description provided for @guest_jacuzzi_important.
  ///
  /// In es, this message translates to:
  /// **'Importante'**
  String get guest_jacuzzi_important;

  /// No description provided for @guest_jacuzzi_water_level_info.
  ///
  /// In es, this message translates to:
  /// **'El nivel del agua debe estar siempre por encima de los jets para un correcto funcionamiento.'**
  String get guest_jacuzzi_water_level_info;

  /// No description provided for @guest_jacuzzi_low_water_title.
  ///
  /// In es, this message translates to:
  /// **'Si el nivel es bajo:'**
  String get guest_jacuzzi_low_water_title;

  /// No description provided for @guest_jacuzzi_low_water_stop.
  ///
  /// In es, this message translates to:
  /// **'Detén el jacuzzi inmediatamente'**
  String get guest_jacuzzi_low_water_stop;

  /// No description provided for @guest_jacuzzi_low_water_icon.
  ///
  /// In es, this message translates to:
  /// **'Verifica el icono de advertencia en el panel'**
  String get guest_jacuzzi_low_water_icon;

  /// No description provided for @guest_jacuzzi_low_water_resume.
  ///
  /// In es, this message translates to:
  /// **'Rellena con agua hasta cubrir los jets antes de reanudar.'**
  String get guest_jacuzzi_low_water_resume;

  /// No description provided for @guest_jacuzzi_water_responsibility.
  ///
  /// In es, this message translates to:
  /// **'Uso Responsable del Agua'**
  String get guest_jacuzzi_water_responsibility;

  /// No description provided for @guest_jacuzzi_water_refill_info.
  ///
  /// In es, this message translates to:
  /// **'El jacuzzi tiene una capacidad considerable de agua. Por favor, úsalo de forma responsable.'**
  String get guest_jacuzzi_water_refill_info;

  /// No description provided for @guest_jacuzzi_capacity.
  ///
  /// In es, this message translates to:
  /// **'Capacidad:'**
  String get guest_jacuzzi_capacity;

  /// No description provided for @guest_jacuzzi_capacity_liters.
  ///
  /// In es, this message translates to:
  /// **'800 litros'**
  String get guest_jacuzzi_capacity_liters;

  /// No description provided for @guest_jacuzzi_water_regulation.
  ///
  /// In es, this message translates to:
  /// **'El llenado y vaciado del jacuzzi está regulado por las normas locales de uso del agua.'**
  String get guest_jacuzzi_water_regulation;

  /// No description provided for @guest_jacuzzi_thanks.
  ///
  /// In es, this message translates to:
  /// **'Gracias por tu colaboración en el uso responsable del agua.'**
  String get guest_jacuzzi_thanks;

  /// No description provided for @guest_physical_registration_title.
  ///
  /// In es, this message translates to:
  /// **'Registro Físico'**
  String get guest_physical_registration_title;

  /// No description provided for @guest_physical_registration_header.
  ///
  /// In es, this message translates to:
  /// **'Registro en Recepción'**
  String get guest_physical_registration_header;

  /// No description provided for @guest_physical_registration_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Completa tu registro de forma presencial'**
  String get guest_physical_registration_subtitle;

  /// No description provided for @guest_physical_registration_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones'**
  String get guest_physical_registration_instructions;

  /// No description provided for @guest_physical_registration_step_1_title.
  ///
  /// In es, this message translates to:
  /// **'Acude a recepción'**
  String get guest_physical_registration_step_1_title;

  /// No description provided for @guest_physical_registration_step_1_desc.
  ///
  /// In es, this message translates to:
  /// **'Dirígete a la recepción del hotel durante el horario de atención'**
  String get guest_physical_registration_step_1_desc;

  /// No description provided for @guest_physical_registration_step_2_title.
  ///
  /// In es, this message translates to:
  /// **'Presenta tu documento'**
  String get guest_physical_registration_step_2_title;

  /// No description provided for @guest_physical_registration_step_2_desc.
  ///
  /// In es, this message translates to:
  /// **'Muestra tu documento de identidad original (DNI, pasaporte o carnet de conducir)'**
  String get guest_physical_registration_step_2_desc;

  /// No description provided for @guest_physical_registration_step_3_title.
  ///
  /// In es, this message translates to:
  /// **'Firma el registro'**
  String get guest_physical_registration_step_3_title;

  /// No description provided for @guest_physical_registration_step_3_desc.
  ///
  /// In es, this message translates to:
  /// **'Firma el documento de registro de entrada'**
  String get guest_physical_registration_step_3_desc;

  /// No description provided for @guest_physical_registration_step_4_title.
  ///
  /// In es, this message translates to:
  /// **'Recibe tu llave'**
  String get guest_physical_registration_step_4_title;

  /// No description provided for @guest_physical_registration_step_4_desc.
  ///
  /// In es, this message translates to:
  /// **'Te entregaremos la llave de tu habitación'**
  String get guest_physical_registration_step_4_desc;

  /// No description provided for @guest_physical_registration_schedule.
  ///
  /// In es, this message translates to:
  /// **'Horario de Recepción'**
  String get guest_physical_registration_schedule;

  /// No description provided for @guest_physical_registration_schedule_hours.
  ///
  /// In es, this message translates to:
  /// **'Horario de atención'**
  String get guest_physical_registration_schedule_hours;

  /// No description provided for @guest_physical_registration_schedule_days.
  ///
  /// In es, this message translates to:
  /// **'Lunes a Viernes'**
  String get guest_physical_registration_schedule_days;

  /// No description provided for @guest_physical_registration_documents.
  ///
  /// In es, this message translates to:
  /// **'Documentos Aceptados'**
  String get guest_physical_registration_documents;

  /// No description provided for @guest_physical_registration_doc_dni.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get guest_physical_registration_doc_dni;

  /// No description provided for @guest_physical_registration_doc_passport.
  ///
  /// In es, this message translates to:
  /// **'Pasaporte'**
  String get guest_physical_registration_doc_passport;

  /// No description provided for @guest_physical_registration_doc_license.
  ///
  /// In es, this message translates to:
  /// **'Carnet de conducir'**
  String get guest_physical_registration_doc_license;

  /// No description provided for @guest_checkin_child_no_data.
  ///
  /// In es, this message translates to:
  /// **'Menor de 14 años, sin datos requeridos'**
  String get guest_checkin_child_no_data;

  /// No description provided for @guest_checkin_holder.
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get guest_checkin_holder;

  /// No description provided for @guest_checkin_full_name.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get guest_checkin_full_name;

  /// No description provided for @guest_checkin_email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get guest_checkin_email;

  /// No description provided for @guest_checkin_phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get guest_checkin_phone;

  /// No description provided for @guest_checkin_young.
  ///
  /// In es, this message translates to:
  /// **'Menor ({age} años)'**
  String guest_checkin_young(int age);

  /// No description provided for @guest_checkin_adult.
  ///
  /// In es, this message translates to:
  /// **'Adulto {number}'**
  String guest_checkin_adult(int number);

  /// No description provided for @guest_checkin_guest.
  ///
  /// In es, this message translates to:
  /// **'Huésped {number}'**
  String guest_checkin_guest(int number);

  /// No description provided for @guest_checkin_document_id.
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad'**
  String get guest_checkin_document_id;

  /// No description provided for @guest_checkin_upload_document.
  ///
  /// In es, this message translates to:
  /// **'Subir documento'**
  String get guest_checkin_upload_document;

  /// No description provided for @guest_checkin_document.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get guest_checkin_document;

  /// No description provided for @guest_checkin_missing_photo.
  ///
  /// In es, this message translates to:
  /// **'Falta foto del documento'**
  String get guest_checkin_missing_photo;

  /// No description provided for @guest_checkin_upload_document_title.
  ///
  /// In es, this message translates to:
  /// **'Subir Documento'**
  String get guest_checkin_upload_document_title;

  /// No description provided for @guest_checkin_document_type.
  ///
  /// In es, this message translates to:
  /// **'Tipo de documento'**
  String get guest_checkin_document_type;

  /// No description provided for @guest_checkin_document_number.
  ///
  /// In es, this message translates to:
  /// **'Número de documento'**
  String get guest_checkin_document_number;

  /// No description provided for @guest_checkin_document_photo.
  ///
  /// In es, this message translates to:
  /// **'Foto del documento'**
  String get guest_checkin_document_photo;

  /// No description provided for @guest_checkin_image_captured.
  ///
  /// In es, this message translates to:
  /// **'Imagen capturada'**
  String get guest_checkin_image_captured;

  /// No description provided for @guest_checkin_tap_to_capture.
  ///
  /// In es, this message translates to:
  /// **'Toca para capturar documento'**
  String get guest_checkin_tap_to_capture;

  /// No description provided for @guest_checkin_camera_or_gallery.
  ///
  /// In es, this message translates to:
  /// **'Cámara o galería'**
  String get guest_checkin_camera_or_gallery;

  /// No description provided for @guest_checkin_select_source.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar origen'**
  String get guest_checkin_select_source;

  /// No description provided for @guest_checkin_camera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get guest_checkin_camera;

  /// No description provided for @guest_checkin_gallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get guest_checkin_gallery;

  /// No description provided for @guest_checkin_photo_required.
  ///
  /// In es, this message translates to:
  /// **'Foto obligatoria'**
  String get guest_checkin_photo_required;

  /// No description provided for @guest_checkin_document_number_required.
  ///
  /// In es, this message translates to:
  /// **'Introduce el número de documento'**
  String get guest_checkin_document_number_required;

  /// No description provided for @guest_checkin_confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get guest_checkin_confirm;

  /// No description provided for @guest_checkin_capture_error.
  ///
  /// In es, this message translates to:
  /// **'Error al capturar imagen: {error}'**
  String guest_checkin_capture_error(String error);

  /// No description provided for @admin_chat_title.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get admin_chat_title;

  /// No description provided for @admin_chat_online.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get admin_chat_online;

  /// No description provided for @chat_delete_message.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mensaje'**
  String get chat_delete_message;

  /// No description provided for @chat_delete_message_confirm_body.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar este mensaje? Esta acción no se puede deshacer.'**
  String get chat_delete_message_confirm_body;

  /// No description provided for @chat_delete_message_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar el mensaje'**
  String get chat_delete_message_error;

  /// No description provided for @admin_chat_delete_conversation.
  ///
  /// In es, this message translates to:
  /// **'Eliminar conversación'**
  String get admin_chat_delete_conversation;

  /// No description provided for @admin_chat_delete_confirm_body.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar esta conversación?'**
  String get admin_chat_delete_confirm_body;

  /// No description provided for @admin_chat_deleted_success.
  ///
  /// In es, this message translates to:
  /// **'Conversación eliminada correctamente'**
  String get admin_chat_deleted_success;

  /// No description provided for @admin_chat_error_deleting.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar la conversación: {error}'**
  String admin_chat_error_deleting(String error);

  /// No description provided for @admin_checkin_detail_title.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Check-in'**
  String get admin_checkin_detail_title;

  /// No description provided for @admin_checkin_validate.
  ///
  /// In es, this message translates to:
  /// **'Validar'**
  String get admin_checkin_validate;

  /// No description provided for @admin_checkin_reject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get admin_checkin_reject;

  /// No description provided for @admin_checkin_cancel_booking.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Reserva'**
  String get admin_checkin_cancel_booking;

  /// No description provided for @admin_checkin_error_loading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get admin_checkin_error_loading;

  /// No description provided for @admin_checkin_not_found.
  ///
  /// In es, this message translates to:
  /// **'Check-in no encontrado'**
  String get admin_checkin_not_found;

  /// No description provided for @admin_checkin_status_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get admin_checkin_status_pending;

  /// No description provided for @admin_checkin_status_validated.
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get admin_checkin_status_validated;

  /// No description provided for @admin_checkin_status_rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get admin_checkin_status_rejected;

  /// No description provided for @admin_checkin_status_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get admin_checkin_status_cancelled;

  /// No description provided for @admin_checkin_status_draft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get admin_checkin_status_draft;

  /// No description provided for @admin_checkin_submitted_label.
  ///
  /// In es, this message translates to:
  /// **'Enviado:'**
  String get admin_checkin_submitted_label;

  /// No description provided for @admin_checkin_validated_label.
  ///
  /// In es, this message translates to:
  /// **'Validado:'**
  String get admin_checkin_validated_label;

  /// No description provided for @admin_checkin_rejected_label.
  ///
  /// In es, this message translates to:
  /// **'Rechazado:'**
  String get admin_checkin_rejected_label;

  /// No description provided for @admin_checkin_cancelled_label.
  ///
  /// In es, this message translates to:
  /// **'Cancelado:'**
  String get admin_checkin_cancelled_label;

  /// No description provided for @admin_checkin_booking_info.
  ///
  /// In es, this message translates to:
  /// **'Información de Reserva'**
  String get admin_checkin_booking_info;

  /// No description provided for @admin_checkin_property_label.
  ///
  /// In es, this message translates to:
  /// **'Propiedad:'**
  String get admin_checkin_property_label;

  /// No description provided for @admin_checkin_units_label.
  ///
  /// In es, this message translates to:
  /// **'hab'**
  String get admin_checkin_units_label;

  /// No description provided for @admin_checkin_unit_label.
  ///
  /// In es, this message translates to:
  /// **'hab'**
  String get admin_checkin_unit_label;

  /// No description provided for @admin_checkin_code_label.
  ///
  /// In es, this message translates to:
  /// **'Código:'**
  String get admin_checkin_code_label;

  /// No description provided for @admin_checkin_checkin_date_label.
  ///
  /// In es, this message translates to:
  /// **'Check-in:'**
  String get admin_checkin_checkin_date_label;

  /// No description provided for @admin_checkin_checkout_date_label.
  ///
  /// In es, this message translates to:
  /// **'Check-out:'**
  String get admin_checkin_checkout_date_label;

  /// No description provided for @admin_checkin_guests_section.
  ///
  /// In es, this message translates to:
  /// **'HUÉSPEDES'**
  String get admin_checkin_guests_section;

  /// No description provided for @admin_checkin_primary_badge.
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get admin_checkin_primary_badge;

  /// No description provided for @admin_checkin_na.
  ///
  /// In es, this message translates to:
  /// **'N/A'**
  String get admin_checkin_na;

  /// No description provided for @admin_checkin_documents_section.
  ///
  /// In es, this message translates to:
  /// **'DOCUMENTOS'**
  String get admin_checkin_documents_section;

  /// No description provided for @admin_checkin_unknown_guest.
  ///
  /// In es, this message translates to:
  /// **'Huésped desconocido'**
  String get admin_checkin_unknown_guest;

  /// No description provided for @admin_checkin_signature_section.
  ///
  /// In es, this message translates to:
  /// **'FIRMA'**
  String get admin_checkin_signature_section;

  /// No description provided for @admin_checkin_doc_type_dni.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get admin_checkin_doc_type_dni;

  /// No description provided for @admin_checkin_doc_type_nie.
  ///
  /// In es, this message translates to:
  /// **'NIE'**
  String get admin_checkin_doc_type_nie;

  /// No description provided for @admin_checkin_doc_type_passport.
  ///
  /// In es, this message translates to:
  /// **'Pasaporte'**
  String get admin_checkin_doc_type_passport;

  /// No description provided for @admin_checkin_image_load_error.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar imagen'**
  String get admin_checkin_image_load_error;

  /// No description provided for @admin_checkin_validate_title.
  ///
  /// In es, this message translates to:
  /// **'Validar Check-in'**
  String get admin_checkin_validate_title;

  /// No description provided for @admin_checkin_validate_message.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas validar este check-in?'**
  String get admin_checkin_validate_message;

  /// No description provided for @admin_checkin_validated_success.
  ///
  /// In es, this message translates to:
  /// **'Check-in validado correctamente'**
  String get admin_checkin_validated_success;

  /// No description provided for @admin_checkin_error.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String admin_checkin_error(String error);

  /// No description provided for @admin_checkin_reject_title.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Check-in'**
  String get admin_checkin_reject_title;

  /// No description provided for @admin_checkin_reject_message.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas rechazar este check-in?'**
  String get admin_checkin_reject_message;

  /// No description provided for @admin_checkin_reject_hint.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo (opcional)...'**
  String get admin_checkin_reject_hint;

  /// No description provided for @admin_checkin_no_reason.
  ///
  /// In es, this message translates to:
  /// **'Sin motivo'**
  String get admin_checkin_no_reason;

  /// No description provided for @admin_checkin_rejected_success.
  ///
  /// In es, this message translates to:
  /// **'Check-in rechazado correctamente'**
  String get admin_checkin_rejected_success;

  /// No description provided for @admin_checkin_cancel_message.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cancelar esta reserva?'**
  String get admin_checkin_cancel_message;

  /// No description provided for @admin_checkin_cancel_warning.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get admin_checkin_cancel_warning;

  /// No description provided for @admin_checkin_cancel_reason_label.
  ///
  /// In es, this message translates to:
  /// **'Motivo de cancelación'**
  String get admin_checkin_cancel_reason_label;

  /// No description provided for @admin_checkin_cancel_reason_hint.
  ///
  /// In es, this message translates to:
  /// **'Describe el motivo de la cancelación...'**
  String get admin_checkin_cancel_reason_hint;

  /// No description provided for @admin_checkin_cancelled_success.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada correctamente'**
  String get admin_checkin_cancelled_success;

  /// No description provided for @admin_invoice_generate_pdf.
  ///
  /// In es, this message translates to:
  /// **'Generar PDF'**
  String get admin_invoice_generate_pdf;

  /// No description provided for @admin_invoice_share.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get admin_invoice_share;

  /// No description provided for @admin_invoice_download.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get admin_invoice_download;

  /// No description provided for @admin_invoice_share_title.
  ///
  /// In es, this message translates to:
  /// **'Compartir Factura'**
  String get admin_invoice_share_title;

  /// No description provided for @admin_invoice_copy_link.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get admin_invoice_copy_link;

  /// No description provided for @admin_invoice_pdf_saved.
  ///
  /// In es, this message translates to:
  /// **'PDF guardado en: {path}'**
  String admin_invoice_pdf_saved(String path);

  /// No description provided for @admin_invoice_issue.
  ///
  /// In es, this message translates to:
  /// **'Emitir'**
  String get admin_invoice_issue;

  /// No description provided for @admin_invoice_mark_paid.
  ///
  /// In es, this message translates to:
  /// **'Marcar como pagada'**
  String get admin_invoice_mark_paid;

  /// No description provided for @admin_invoice_paid_on.
  ///
  /// In es, this message translates to:
  /// **'Pagada el {date}'**
  String admin_invoice_paid_on(String date);

  /// No description provided for @admin_invoice_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada: {reason}'**
  String admin_invoice_cancelled(String reason);

  /// No description provided for @admin_invoice_issue_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'Emitir Factura'**
  String get admin_invoice_issue_confirm_title;

  /// No description provided for @admin_invoice_issue_confirm_message.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas emitir la factura {invoiceNumber}?'**
  String admin_invoice_issue_confirm_message(String invoiceNumber);

  /// No description provided for @admin_invoice_mark_paid_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'Marcar como Pagada'**
  String get admin_invoice_mark_paid_confirm_title;

  /// No description provided for @admin_invoice_mark_paid_confirm_message.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas que se ha recibido el pago de {total}?'**
  String admin_invoice_mark_paid_confirm_message(String total);

  /// No description provided for @admin_invoice_confirm_payment.
  ///
  /// In es, this message translates to:
  /// **'Confirmar pago'**
  String get admin_invoice_confirm_payment;

  /// No description provided for @admin_invoice_cancel_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Factura'**
  String get admin_invoice_cancel_confirm_title;

  /// No description provided for @admin_invoice_cancel_reason_label.
  ///
  /// In es, this message translates to:
  /// **'Motivo de cancelación'**
  String get admin_invoice_cancel_reason_label;

  /// No description provided for @admin_invoice_cancel_reason_hint.
  ///
  /// In es, this message translates to:
  /// **'Describe el motivo de la cancelación...'**
  String get admin_invoice_cancel_reason_hint;

  /// No description provided for @admin_invoice_dont_cancel.
  ///
  /// In es, this message translates to:
  /// **'No cancelar'**
  String get admin_invoice_dont_cancel;

  /// No description provided for @admin_invoice_cancel_invoice.
  ///
  /// In es, this message translates to:
  /// **'Cancelar factura'**
  String get admin_invoice_cancel_invoice;

  /// No description provided for @admin_invoice_error_generate_pdf.
  ///
  /// In es, this message translates to:
  /// **'Error al generar PDF: {error}'**
  String admin_invoice_error_generate_pdf(String error);

  /// No description provided for @admin_invoice_error_share.
  ///
  /// In es, this message translates to:
  /// **'Error al compartir: {error}'**
  String admin_invoice_error_share(String error);

  /// No description provided for @admin_invoice_error_download.
  ///
  /// In es, this message translates to:
  /// **'Error al descargar: {error}'**
  String admin_invoice_error_download(String error);

  /// No description provided for @admin_invoice_nif_label.
  ///
  /// In es, this message translates to:
  /// **'NIF/CIF:'**
  String get admin_invoice_nif_label;

  /// No description provided for @admin_invoice_label.
  ///
  /// In es, this message translates to:
  /// **'Factura'**
  String get admin_invoice_label;

  /// No description provided for @admin_invoice_bill_to.
  ///
  /// In es, this message translates to:
  /// **'Facturar a'**
  String get admin_invoice_bill_to;

  /// No description provided for @admin_invoice_issue_date_label.
  ///
  /// In es, this message translates to:
  /// **'Fecha de emisión:'**
  String get admin_invoice_issue_date_label;

  /// No description provided for @admin_invoice_due_date_label.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento:'**
  String get admin_invoice_due_date_label;

  /// No description provided for @admin_invoice_period_label.
  ///
  /// In es, this message translates to:
  /// **'Período'**
  String get admin_invoice_period_label;

  /// No description provided for @admin_invoice_booking_label.
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get admin_invoice_booking_label;

  /// No description provided for @admin_invoice_no_line_items.
  ///
  /// In es, this message translates to:
  /// **'Sin conceptos'**
  String get admin_invoice_no_line_items;

  /// No description provided for @admin_invoice_col_description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get admin_invoice_col_description;

  /// No description provided for @admin_invoice_col_qty.
  ///
  /// In es, this message translates to:
  /// **'Cant.'**
  String get admin_invoice_col_qty;

  /// No description provided for @admin_invoice_col_price.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get admin_invoice_col_price;

  /// No description provided for @admin_invoice_col_total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get admin_invoice_col_total;

  /// No description provided for @admin_invoice_tax_base.
  ///
  /// In es, this message translates to:
  /// **'Base imponible'**
  String get admin_invoice_tax_base;

  /// No description provided for @admin_invoice_tax_label.
  ///
  /// In es, this message translates to:
  /// **'IVA'**
  String get admin_invoice_tax_label;

  /// No description provided for @admin_invoice_total_label.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get admin_invoice_total_label;

  /// No description provided for @admin_invoice_notes_label.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get admin_invoice_notes_label;

  /// No description provided for @admin_notifications_title.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get admin_notifications_title;

  /// No description provided for @admin_notifications_empty_title.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get admin_notifications_empty_title;

  /// No description provided for @admin_notifications_empty_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones aparecerán aquí'**
  String get admin_notifications_empty_subtitle;

  /// No description provided for @admin_notifications_mark_all_read.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get admin_notifications_mark_all_read;

  /// No description provided for @admin_notifications_mark_read.
  ///
  /// In es, this message translates to:
  /// **'Marcar como leído'**
  String get admin_notifications_mark_read;

  /// No description provided for @admin_notifications_delete_all.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todo'**
  String get admin_notifications_delete_all;

  /// No description provided for @admin_notifications_delete_all_title.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas las notificaciones'**
  String get admin_notifications_delete_all_title;

  /// No description provided for @admin_notifications_delete_all_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar todas las notificaciones?'**
  String get admin_notifications_delete_all_confirm;

  /// No description provided for @admin_notifications_unread_count.
  ///
  /// In es, this message translates to:
  /// **'{count} sin leer'**
  String admin_notifications_unread_count(int count);

  /// No description provided for @guest_access_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in'**
  String get guest_access_checkin;

  /// No description provided for @guest_access_checkout.
  ///
  /// In es, this message translates to:
  /// **'Check-out'**
  String get guest_access_checkout;

  /// No description provided for @guest_access_checkout_label.
  ///
  /// In es, this message translates to:
  /// **'Salida'**
  String get guest_access_checkout_label;

  /// No description provided for @guest_access_checkout_until.
  ///
  /// In es, this message translates to:
  /// **'Hasta las {time}'**
  String guest_access_checkout_until(String time);

  /// No description provided for @guest_access_checkout_deadline.
  ///
  /// In es, this message translates to:
  /// **'Hora límite de salida'**
  String get guest_access_checkout_deadline;

  /// No description provided for @guest_access_checkout_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de salida'**
  String get guest_access_checkout_instructions;

  /// No description provided for @guest_access_code_label.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get guest_access_code_label;

  /// No description provided for @guest_access_code_available_at.
  ///
  /// In es, this message translates to:
  /// **'Disponible el {date} a las {time}'**
  String guest_access_code_available_at(String date, String time);

  /// No description provided for @guest_access_code_provided_by_staff.
  ///
  /// In es, this message translates to:
  /// **'Proporcionado por el personal'**
  String get guest_access_code_provided_by_staff;

  /// No description provided for @guest_access_locker_code.
  ///
  /// In es, this message translates to:
  /// **'Código del casillero'**
  String get guest_access_locker_code;

  /// No description provided for @guest_access_locker_code_label.
  ///
  /// In es, this message translates to:
  /// **'Código casillero'**
  String get guest_access_locker_code_label;

  /// No description provided for @guest_access_locker_available_at.
  ///
  /// In es, this message translates to:
  /// **'Disponible el {date}'**
  String guest_access_locker_available_at(String date);

  /// No description provided for @guest_access_key_locker.
  ///
  /// In es, this message translates to:
  /// **'Casillero de llaves'**
  String get guest_access_key_locker;

  /// No description provided for @guest_access_door_code.
  ///
  /// In es, this message translates to:
  /// **'Código de la puerta'**
  String get guest_access_door_code;

  /// No description provided for @guest_access_building_access.
  ///
  /// In es, this message translates to:
  /// **'Acceso al edificio'**
  String get guest_access_building_access;

  /// No description provided for @guest_access_building_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de acceso al edificio'**
  String get guest_access_building_instructions;

  /// No description provided for @guest_access_apartment_access.
  ///
  /// In es, this message translates to:
  /// **'Acceso al apartamento'**
  String get guest_access_apartment_access;

  /// No description provided for @guest_access_apartment_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de acceso al apartamento'**
  String get guest_access_apartment_instructions;

  /// No description provided for @guest_access_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get guest_access_location;

  /// No description provided for @guest_access_contact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get guest_access_contact;

  /// No description provided for @guest_access_contact_description.
  ///
  /// In es, this message translates to:
  /// **'Contacta con nosotros si necesitas ayuda'**
  String get guest_access_contact_description;

  /// No description provided for @guest_access_copied.
  ///
  /// In es, this message translates to:
  /// **'{label} copiado al portapapeles'**
  String guest_access_copied(String label);

  /// No description provided for @guest_access_open_maps.
  ///
  /// In es, this message translates to:
  /// **'Abrir en Maps'**
  String get guest_access_open_maps;

  /// No description provided for @guest_access_network.
  ///
  /// In es, this message translates to:
  /// **'Red'**
  String get guest_access_network;

  /// No description provided for @guest_access_network_name.
  ///
  /// In es, this message translates to:
  /// **'Nombre de red'**
  String get guest_access_network_name;

  /// No description provided for @guest_access_password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get guest_access_password;

  /// No description provided for @guest_access_company_name.
  ///
  /// In es, this message translates to:
  /// **'BF Stay'**
  String get guest_access_company_name;

  /// No description provided for @guest_access_house_rules.
  ///
  /// In es, this message translates to:
  /// **'Normas de la casa'**
  String get guest_access_house_rules;

  /// No description provided for @guest_access_rules_warning.
  ///
  /// In es, this message translates to:
  /// **'Por favor, lee las normas de la casa antes de tu llegada'**
  String get guest_access_rules_warning;

  /// No description provided for @guest_access_your_accommodation.
  ///
  /// In es, this message translates to:
  /// **'Tu alojamiento'**
  String get guest_access_your_accommodation;

  /// No description provided for @guest_access_your_codes.
  ///
  /// In es, this message translates to:
  /// **'Tus códigos'**
  String get guest_access_your_codes;

  /// No description provided for @guest_access_guest.
  ///
  /// In es, this message translates to:
  /// **'Huésped'**
  String get guest_access_guest;

  /// No description provided for @guest_access_welcome_message.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a {unitName}'**
  String guest_access_welcome_message(String unitName);

  /// No description provided for @guest_access_hello.
  ///
  /// In es, this message translates to:
  /// **'Hola {name}'**
  String guest_access_hello(String name);

  /// No description provided for @guest_access_codes_available_datetime.
  ///
  /// In es, this message translates to:
  /// **'Disponible el {date} a las {time}'**
  String guest_access_codes_available_datetime(String date, String time);

  /// No description provided for @guest_access_codes_available_message.
  ///
  /// In es, this message translates to:
  /// **'Tu código estará disponible a partir de {time}'**
  String guest_access_codes_available_message(String time);

  /// No description provided for @guest_access_loading_instructions.
  ///
  /// In es, this message translates to:
  /// **'Cargando instrucciones...'**
  String get guest_access_loading_instructions;

  /// No description provided for @guest_access_cannot_load_instructions.
  ///
  /// In es, this message translates to:
  /// **'No se pueden cargar las instrucciones'**
  String get guest_access_cannot_load_instructions;

  /// No description provided for @guest_access_rule_no_parties_title.
  ///
  /// In es, this message translates to:
  /// **'No fiestas'**
  String get guest_access_rule_no_parties_title;

  /// No description provided for @guest_access_rule_no_parties_description.
  ///
  /// In es, this message translates to:
  /// **'No se permiten fiestas ni eventos'**
  String get guest_access_rule_no_parties_description;

  /// No description provided for @guest_access_rule_no_smoking_title.
  ///
  /// In es, this message translates to:
  /// **'Sin humo'**
  String get guest_access_rule_no_smoking_title;

  /// No description provided for @guest_access_rule_smoke_free_description.
  ///
  /// In es, this message translates to:
  /// **'Esta es una propiedad libre de humo'**
  String get guest_access_rule_smoke_free_description;

  /// No description provided for @guest_access_rule_registered_only_title.
  ///
  /// In es, this message translates to:
  /// **'Solo registrados'**
  String get guest_access_rule_registered_only_title;

  /// No description provided for @guest_access_rule_registered_only_description.
  ///
  /// In es, this message translates to:
  /// **'Solo los huéspedes registrados pueden acceder'**
  String get guest_access_rule_registered_only_description;

  /// No description provided for @guest_accommodation_title.
  ///
  /// In es, this message translates to:
  /// **'Alojamiento'**
  String get guest_accommodation_title;

  /// No description provided for @guest_accommodation_error_loading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get guest_accommodation_error_loading;

  /// No description provided for @guest_accommodation_error_occurred.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error'**
  String get guest_accommodation_error_occurred;

  /// No description provided for @guest_accommodation_no_booking.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la reserva'**
  String get guest_accommodation_no_booking;

  /// No description provided for @guest_accommodation_booking_not_found.
  ///
  /// In es, this message translates to:
  /// **'Reserva no encontrada'**
  String get guest_accommodation_booking_not_found;

  /// No description provided for @guest_accommodation_no_unit_info.
  ///
  /// In es, this message translates to:
  /// **'No hay información de la unidad'**
  String get guest_accommodation_no_unit_info;

  /// No description provided for @guest_accommodation_address.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get guest_accommodation_address;

  /// No description provided for @guest_accommodation_address_unavailable.
  ///
  /// In es, this message translates to:
  /// **'Dirección no disponible'**
  String get guest_accommodation_address_unavailable;

  /// No description provided for @guest_accommodation_box_location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de la caja'**
  String get guest_accommodation_box_location;

  /// No description provided for @guest_accommodation_access_codes.
  ///
  /// In es, this message translates to:
  /// **'Códigos de acceso'**
  String get guest_accommodation_access_codes;

  /// No description provided for @guest_accommodation_access_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de acceso'**
  String get guest_accommodation_access_instructions;

  /// No description provided for @guest_accommodation_main_door.
  ///
  /// In es, this message translates to:
  /// **'Puerta principal'**
  String get guest_accommodation_main_door;

  /// No description provided for @guest_accommodation_door_code.
  ///
  /// In es, this message translates to:
  /// **'Código de la puerta'**
  String get guest_accommodation_door_code;

  /// No description provided for @guest_accommodation_portal_code.
  ///
  /// In es, this message translates to:
  /// **'Código del portal'**
  String get guest_accommodation_portal_code;

  /// No description provided for @guest_accommodation_key_box_code.
  ///
  /// In es, this message translates to:
  /// **'Código de la caja de llaves'**
  String get guest_accommodation_key_box_code;

  /// No description provided for @guest_accommodation_keybox_description.
  ///
  /// In es, this message translates to:
  /// **'Código para la caja de llaves'**
  String get guest_accommodation_keybox_description;

  /// No description provided for @guest_accommodation_wifi_password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña WiFi'**
  String get guest_accommodation_wifi_password;

  /// No description provided for @guest_accommodation_rooms_count.
  ///
  /// In es, this message translates to:
  /// **'{count} habitaciones'**
  String guest_accommodation_rooms_count(int count);

  /// No description provided for @guest_accommodation_hotel_rules.
  ///
  /// In es, this message translates to:
  /// **'Normas del hotel'**
  String get guest_accommodation_hotel_rules;

  /// No description provided for @guest_accommodation_apartment_rules.
  ///
  /// In es, this message translates to:
  /// **'Normas del apartamento'**
  String get guest_accommodation_apartment_rules;

  /// No description provided for @guest_accommodation_rules_description.
  ///
  /// In es, this message translates to:
  /// **'Consulta las normas de tu alojamiento'**
  String get guest_accommodation_rules_description;

  /// No description provided for @guest_accommodation_rules_load_error.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar las normas: {error}'**
  String guest_accommodation_rules_load_error(String error);

  /// No description provided for @guest_accommodation_codes_available_datetime.
  ///
  /// In es, this message translates to:
  /// **'Disponible el {date} a las {time}'**
  String guest_accommodation_codes_available_datetime(String date, String time);

  /// No description provided for @guest_accommodation_codes_available_message.
  ///
  /// In es, this message translates to:
  /// **'Tus códigos estarán disponibles cuando comience tu estancia ({time})'**
  String guest_accommodation_codes_available_message(String time);

  /// No description provided for @guest_accommodation_file_not_found.
  ///
  /// In es, this message translates to:
  /// **'Archivo no encontrado: {message}'**
  String guest_accommodation_file_not_found(String message);

  /// No description provided for @guest_accommodation_cannot_open_document.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir el documento'**
  String get guest_accommodation_cannot_open_document;

  /// No description provided for @guest_accommodation_tap_for_access_info.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver información de acceso'**
  String get guest_accommodation_tap_for_access_info;

  /// No description provided for @guest_chat_default_title.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get guest_chat_default_title;

  /// No description provided for @guest_chat_online.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get guest_chat_online;

  /// No description provided for @guest_chat_start_conversation.
  ///
  /// In es, this message translates to:
  /// **'Iniciar conversación'**
  String get guest_chat_start_conversation;

  /// No description provided for @guest_chat_welcome_message.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! ¿En qué podemos ayudarte?'**
  String get guest_chat_welcome_message;

  /// No description provided for @guest_checkin_label.
  ///
  /// In es, this message translates to:
  /// **'Check-in'**
  String get guest_checkin_label;

  /// No description provided for @guest_checkin_back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get guest_checkin_back;

  /// No description provided for @guest_checkin_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get guest_checkin_continue;

  /// No description provided for @guest_checkin_complete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get guest_checkin_complete;

  /// No description provided for @guest_checkin_loading_booking.
  ///
  /// In es, this message translates to:
  /// **'Cargando datos de la reserva...'**
  String get guest_checkin_loading_booking;

  /// No description provided for @guest_checkin_error_loading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get guest_checkin_error_loading;

  /// No description provided for @guest_checkin_booking.
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get guest_checkin_booking;

  /// No description provided for @guest_checkin_code.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get guest_checkin_code;

  /// No description provided for @guest_checkin_guests_label.
  ///
  /// In es, this message translates to:
  /// **'Huéspedes'**
  String get guest_checkin_guests_label;

  /// No description provided for @guest_checkin_guests_count.
  ///
  /// In es, this message translates to:
  /// **'{count} huéspedes'**
  String guest_checkin_guests_count(int count);

  /// No description provided for @guest_checkin_guests_registered.
  ///
  /// In es, this message translates to:
  /// **'{count} registrados'**
  String guest_checkin_guests_registered(int count);

  /// No description provided for @guest_checkin_guests_summary.
  ///
  /// In es, this message translates to:
  /// **'{count} huéspedes'**
  String guest_checkin_guests_summary(int count);

  /// No description provided for @guest_checkin_guest_data.
  ///
  /// In es, this message translates to:
  /// **'Datos del huésped'**
  String get guest_checkin_guest_data;

  /// No description provided for @guest_checkin_guest_data_description.
  ///
  /// In es, this message translates to:
  /// **'Completa los datos de todos los huéspedes'**
  String get guest_checkin_guest_data_description;

  /// No description provided for @guest_checkin_holder_badge.
  ///
  /// In es, this message translates to:
  /// **'TITULAR'**
  String get guest_checkin_holder_badge;

  /// No description provided for @guest_checkin_holder_signature.
  ///
  /// In es, this message translates to:
  /// **'Firma del titular'**
  String get guest_checkin_holder_signature;

  /// No description provided for @guest_checkin_no_name.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get guest_checkin_no_name;

  /// No description provided for @guest_checkin_guest_no_name.
  ///
  /// In es, this message translates to:
  /// **'Huésped sin nombre'**
  String get guest_checkin_guest_no_name;

  /// No description provided for @guest_checkin_adults_children.
  ///
  /// In es, this message translates to:
  /// **'{adults} adultos y {children} menores'**
  String guest_checkin_adults_children(int adults, int children);

  /// No description provided for @guest_checkin_minor_badge.
  ///
  /// In es, this message translates to:
  /// **'MENOR'**
  String get guest_checkin_minor_badge;

  /// No description provided for @guest_checkin_young_document_required.
  ///
  /// In es, this message translates to:
  /// **'Menor de {age} años, documento requerido'**
  String guest_checkin_young_document_required(int age);

  /// No description provided for @guest_checkin_document_required.
  ///
  /// In es, this message translates to:
  /// **'Documento requerido'**
  String get guest_checkin_document_required;

  /// No description provided for @guest_checkin_upload.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get guest_checkin_upload;

  /// No description provided for @guest_checkin_documents_uploaded.
  ///
  /// In es, this message translates to:
  /// **'{completed} de {total} documentos subidos'**
  String guest_checkin_documents_uploaded(int completed, int total);

  /// No description provided for @guest_checkin_all_documents_uploaded.
  ///
  /// In es, this message translates to:
  /// **'Todos los documentos subidos'**
  String get guest_checkin_all_documents_uploaded;

  /// No description provided for @guest_checkin_upload_documents_description.
  ///
  /// In es, this message translates to:
  /// **'Sube las fotos de los documentos de identidad de todos los huéspedes'**
  String get guest_checkin_upload_documents_description;

  /// No description provided for @guest_checkin_uploaded_documents.
  ///
  /// In es, this message translates to:
  /// **'Documentos subidos'**
  String get guest_checkin_uploaded_documents;

  /// No description provided for @guest_checkin_pending_documents.
  ///
  /// In es, this message translates to:
  /// **'Documentos pendientes'**
  String get guest_checkin_pending_documents;

  /// No description provided for @guest_checkin_identity_documents.
  ///
  /// In es, this message translates to:
  /// **'Documentos de identidad'**
  String get guest_checkin_identity_documents;

  /// No description provided for @guest_checkin_signature_description.
  ///
  /// In es, this message translates to:
  /// **'Firma del titular de la reserva'**
  String get guest_checkin_signature_description;

  /// No description provided for @guest_checkin_signature_pending.
  ///
  /// In es, this message translates to:
  /// **'Firma pendiente'**
  String get guest_checkin_signature_pending;

  /// No description provided for @guest_checkin_signature_captured.
  ///
  /// In es, this message translates to:
  /// **'Firma capturada'**
  String get guest_checkin_signature_captured;

  /// No description provided for @guest_checkin_signature_captured_short.
  ///
  /// In es, this message translates to:
  /// **'Firma'**
  String get guest_checkin_signature_captured_short;

  /// No description provided for @guest_checkin_clear_signature.
  ///
  /// In es, this message translates to:
  /// **'Borrar firma'**
  String get guest_checkin_clear_signature;

  /// No description provided for @guest_checkin_step_guests.
  ///
  /// In es, this message translates to:
  /// **'Huéspedes'**
  String get guest_checkin_step_guests;

  /// No description provided for @guest_checkin_step_documents.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get guest_checkin_step_documents;

  /// No description provided for @guest_checkin_step_signature.
  ///
  /// In es, this message translates to:
  /// **'Firma'**
  String get guest_checkin_step_signature;

  /// No description provided for @guest_checkin_step_confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get guest_checkin_step_confirm;

  /// No description provided for @guest_checkin_online.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get guest_checkin_online;

  /// No description provided for @guest_checkin_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get guest_checkin_pending;

  /// No description provided for @guest_checkin_validated.
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get guest_checkin_validated;

  /// No description provided for @guest_checkin_waiting_validation.
  ///
  /// In es, this message translates to:
  /// **'Esperando validación'**
  String get guest_checkin_waiting_validation;

  /// No description provided for @guest_checkin_completed.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get guest_checkin_completed;

  /// No description provided for @guest_checkin_completed_success.
  ///
  /// In es, this message translates to:
  /// **'Check-in completado correctamente'**
  String get guest_checkin_completed_success;

  /// No description provided for @guest_checkin_sending.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get guest_checkin_sending;

  /// No description provided for @guest_checkin_progress.
  ///
  /// In es, this message translates to:
  /// **'Progreso del check-in'**
  String get guest_checkin_progress;

  /// No description provided for @guest_checkin_confirmation.
  ///
  /// In es, this message translates to:
  /// **'Confirmación de Check-in'**
  String get guest_checkin_confirmation;

  /// No description provided for @guest_checkin_confirmation_description.
  ///
  /// In es, this message translates to:
  /// **'Tu check-in ha sido enviado. Ahora hay que esperar a que el alojamiento lo valide.'**
  String get guest_checkin_confirmation_description;

  /// No description provided for @guest_checkin_legal_notice.
  ///
  /// In es, this message translates to:
  /// **'Aviso legal'**
  String get guest_checkin_legal_notice;

  /// No description provided for @guest_checkout_title.
  ///
  /// In es, this message translates to:
  /// **'Check-out'**
  String get guest_checkout_title;

  /// No description provided for @guest_checkout_label.
  ///
  /// In es, this message translates to:
  /// **'Salida'**
  String get guest_checkout_label;

  /// No description provided for @guest_checkout_checkin_label.
  ///
  /// In es, this message translates to:
  /// **'Entrada'**
  String get guest_checkout_checkin_label;

  /// No description provided for @guest_checkout_checkout_label.
  ///
  /// In es, this message translates to:
  /// **'Salida'**
  String get guest_checkout_checkout_label;

  /// No description provided for @guest_checkout_nights_count.
  ///
  /// In es, this message translates to:
  /// **'{count} noches'**
  String guest_checkout_nights_count(int count);

  /// No description provided for @guest_checkout_guests_count.
  ///
  /// In es, this message translates to:
  /// **'{count} huéspedes'**
  String guest_checkout_guests_count(int count);

  /// No description provided for @guest_checkout_stay_summary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de la estancia'**
  String get guest_checkout_stay_summary;

  /// No description provided for @guest_checkout_confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get guest_checkout_confirm;

  /// No description provided for @guest_checkout_confirm_button.
  ///
  /// In es, this message translates to:
  /// **'Confirmar salida'**
  String get guest_checkout_confirm_button;

  /// No description provided for @guest_checkout_confirm_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar salida?'**
  String get guest_checkout_confirm_dialog_title;

  /// No description provided for @guest_checkout_confirm_dialog_message.
  ///
  /// In es, this message translates to:
  /// **'Vas a confirmar tu salida. ¿Deseas continuar?'**
  String get guest_checkout_confirm_dialog_message;

  /// No description provided for @guest_checkout_confirm_info.
  ///
  /// In es, this message translates to:
  /// **'Confirmando salida...'**
  String get guest_checkout_confirm_info;

  /// No description provided for @guest_checkout_processing.
  ///
  /// In es, this message translates to:
  /// **'Procesando...'**
  String get guest_checkout_processing;

  /// No description provided for @guest_checkout_completed.
  ///
  /// In es, this message translates to:
  /// **'Check-out completado'**
  String get guest_checkout_completed;

  /// No description provided for @guest_checkout_thank_you.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por tu estancia!'**
  String get guest_checkout_thank_you;

  /// No description provided for @guest_checkout_feedback_title.
  ///
  /// In es, this message translates to:
  /// **'Tu opinión nos importa'**
  String get guest_checkout_feedback_title;

  /// No description provided for @guest_checkout_feedback_hint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos cómo ha sido tu experiencia...'**
  String get guest_checkout_feedback_hint;

  /// No description provided for @guest_checkout_rating_title.
  ///
  /// In es, this message translates to:
  /// **'Valora tu estancia'**
  String get guest_checkout_rating_title;

  /// No description provided for @guest_checkout_review_description.
  ///
  /// In es, this message translates to:
  /// **'Tu opinión ayuda a otros viajeros'**
  String get guest_checkout_review_description;

  /// No description provided for @guest_checkout_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get guest_checkout_loading;

  /// No description provided for @guest_checkout_error_loading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get guest_checkout_error_loading;

  /// No description provided for @guest_checkout_already_done.
  ///
  /// In es, this message translates to:
  /// **'Check-out ya realizado'**
  String get guest_checkout_already_done;

  /// No description provided for @guest_checkout_already_done_message.
  ///
  /// In es, this message translates to:
  /// **'Ya has realizado el check-out. ¡Gracias!'**
  String get guest_checkout_already_done_message;

  /// No description provided for @guest_home_welcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get guest_home_welcome;

  /// No description provided for @guest_home_welcome_stay.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a tu estancia'**
  String get guest_home_welcome_stay;

  /// No description provided for @guest_home_hello_name.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String guest_home_hello_name(String name);

  /// No description provided for @guest_home_your_stay.
  ///
  /// In es, this message translates to:
  /// **'Tu Estancia'**
  String get guest_home_your_stay;

  /// No description provided for @guest_home_no_booking.
  ///
  /// In es, this message translates to:
  /// **'No tienes reservas'**
  String get guest_home_no_booking;

  /// No description provided for @guest_home_not_authenticated.
  ///
  /// In es, this message translates to:
  /// **'No autenticado'**
  String get guest_home_not_authenticated;

  /// No description provided for @guest_home_stay_active_enjoy.
  ///
  /// In es, this message translates to:
  /// **'Tu estancia está activa. ¡Disfruta!'**
  String get guest_home_stay_active_enjoy;

  /// No description provided for @guest_home_quick_actions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get guest_home_quick_actions;

  /// No description provided for @guest_home_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in'**
  String get guest_home_checkin;

  /// No description provided for @guest_home_checkout.
  ///
  /// In es, this message translates to:
  /// **'Check-out'**
  String get guest_home_checkout;

  /// No description provided for @guest_home_chat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get guest_home_chat;

  /// No description provided for @guest_home_guide.
  ///
  /// In es, this message translates to:
  /// **'Guía'**
  String get guest_home_guide;

  /// No description provided for @guest_home_rules.
  ///
  /// In es, this message translates to:
  /// **'Normas'**
  String get guest_home_rules;

  /// No description provided for @guest_home_parkings.
  ///
  /// In es, this message translates to:
  /// **'Parkings'**
  String get guest_home_parkings;

  /// No description provided for @guest_home_accommodations.
  ///
  /// In es, this message translates to:
  /// **'Alojamientos'**
  String get guest_home_accommodations;

  /// No description provided for @guest_home_accommodation.
  ///
  /// In es, this message translates to:
  /// **'Alojamiento'**
  String get guest_home_accommodation;

  /// No description provided for @guest_home_rooms_count.
  ///
  /// In es, this message translates to:
  /// **'{count} hab'**
  String guest_home_rooms_count(int count);

  /// No description provided for @guest_home_guests.
  ///
  /// In es, this message translates to:
  /// **'Huéspedes'**
  String get guest_home_guests;

  /// No description provided for @guest_home_nights.
  ///
  /// In es, this message translates to:
  /// **'{count} noches'**
  String guest_home_nights(int count);

  /// No description provided for @guest_home_what_to_see.
  ///
  /// In es, this message translates to:
  /// **'Qué ver'**
  String get guest_home_what_to_see;

  /// No description provided for @guest_home_instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones'**
  String get guest_home_instructions;

  /// No description provided for @guest_home_my_accommodation.
  ///
  /// In es, this message translates to:
  /// **'Mi alojamiento'**
  String get guest_home_my_accommodation;

  /// No description provided for @guest_home_booking_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get guest_home_booking_cancelled;

  /// No description provided for @guest_home_booking_cancelled_message.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva ha sido cancelada. Contacta con recepción.'**
  String get guest_home_booking_cancelled_message;

  /// No description provided for @guest_home_cancellation_reason.
  ///
  /// In es, this message translates to:
  /// **'Motivo de cancelación'**
  String get guest_home_cancellation_reason;

  /// No description provided for @guest_home_checkin_pending.
  ///
  /// In es, this message translates to:
  /// **'Check-in pendiente'**
  String get guest_home_checkin_pending;

  /// No description provided for @guest_home_checkin_sent_waiting.
  ///
  /// In es, this message translates to:
  /// **'Check-in enviado, esperando validación'**
  String get guest_home_checkin_sent_waiting;

  /// No description provided for @guest_home_checkin_rejected.
  ///
  /// In es, this message translates to:
  /// **'Check-in rechazado'**
  String get guest_home_checkin_rejected;

  /// No description provided for @guest_home_rejection_reason.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo'**
  String get guest_home_rejection_reason;

  /// No description provided for @guest_home_pending_validation.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de validación'**
  String get guest_home_pending_validation;

  /// No description provided for @guest_home_complete_checkin_access.
  ///
  /// In es, this message translates to:
  /// **'Completa el check-in para acceder'**
  String get guest_home_complete_checkin_access;

  /// No description provided for @guest_home_contact_reception.
  ///
  /// In es, this message translates to:
  /// **'Contacta con recepción'**
  String get guest_home_contact_reception;

  /// No description provided for @guest_home_correct_errors_resend.
  ///
  /// In es, this message translates to:
  /// **'Corrige los errores y vuelve a enviar'**
  String get guest_home_correct_errors_resend;

  /// No description provided for @guest_home_physical_registration.
  ///
  /// In es, this message translates to:
  /// **'Registro presencial'**
  String get guest_home_physical_registration;

  /// No description provided for @guest_home_romantic_pack.
  ///
  /// In es, this message translates to:
  /// **'Pack Romántico'**
  String get guest_home_romantic_pack;

  /// No description provided for @guest_jacuzzi_note.
  ///
  /// In es, this message translates to:
  /// **'Nota: {note}'**
  String guest_jacuzzi_note(String note);

  /// No description provided for @public_services_title.
  ///
  /// In es, this message translates to:
  /// **'Nuestros Servicios'**
  String get public_services_title;

  /// No description provided for @public_service_rules_title.
  ///
  /// In es, this message translates to:
  /// **'Normas de la Casa'**
  String get public_service_rules_title;

  /// No description provided for @public_service_rules_desc.
  ///
  /// In es, this message translates to:
  /// **'Reglas y recomendaciones.'**
  String get public_service_rules_desc;

  /// No description provided for @public_copyright.
  ///
  /// In es, this message translates to:
  /// **'© {year} BF Stay • Todos los derechos reservados'**
  String public_copyright(int year);

  /// No description provided for @public_access_booking.
  ///
  /// In es, this message translates to:
  /// **'Acceder a mi Reserva'**
  String get public_access_booking;

  /// No description provided for @staff_dashboard_greeting.
  ///
  /// In es, this message translates to:
  /// **'Hola {name}'**
  String staff_dashboard_greeting(String name);

  /// No description provided for @staff_dashboard_control_panel.
  ///
  /// In es, this message translates to:
  /// **'Panel de Control'**
  String get staff_dashboard_control_panel;

  /// No description provided for @staff_dashboard_daily_summary.
  ///
  /// In es, this message translates to:
  /// **'Resumen del día'**
  String get staff_dashboard_daily_summary;

  /// No description provided for @staff_dashboard_occupancy.
  ///
  /// In es, this message translates to:
  /// **'Ocupación'**
  String get staff_dashboard_occupancy;

  /// No description provided for @staff_dashboard_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get staff_dashboard_pending;

  /// No description provided for @staff_dashboard_pending_checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-ins pendientes'**
  String get staff_dashboard_pending_checkin;

  /// No description provided for @staff_dashboard_pending_checkout.
  ///
  /// In es, this message translates to:
  /// **'Check-outs pendientes'**
  String get staff_dashboard_pending_checkout;

  /// No description provided for @staff_dashboard_pending_tasks.
  ///
  /// In es, this message translates to:
  /// **'Tareas pendientes'**
  String get staff_dashboard_pending_tasks;

  /// No description provided for @staff_dashboard_checkins_today.
  ///
  /// In es, this message translates to:
  /// **'Check-ins hoy'**
  String get staff_dashboard_checkins_today;

  /// No description provided for @staff_dashboard_checkouts_today.
  ///
  /// In es, this message translates to:
  /// **'Check-outs hoy'**
  String get staff_dashboard_checkouts_today;

  /// No description provided for @staff_dashboard_quick_actions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get staff_dashboard_quick_actions;

  /// No description provided for @staff_dashboard_manage_checkins.
  ///
  /// In es, this message translates to:
  /// **'Gestionar check-ins'**
  String get staff_dashboard_manage_checkins;

  /// No description provided for @staff_dashboard_view_guests.
  ///
  /// In es, this message translates to:
  /// **'Ver huéspedes'**
  String get staff_dashboard_view_guests;

  /// No description provided for @staff_dashboard_room_extras.
  ///
  /// In es, this message translates to:
  /// **'Habitación {room} - Extras'**
  String staff_dashboard_room_extras(String room);

  /// No description provided for @staff_dashboard_cleaning_request.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de limpieza'**
  String get staff_dashboard_cleaning_request;

  /// No description provided for @staff_dashboard_room_guest.
  ///
  /// In es, this message translates to:
  /// **'Habitación {room} - {guest}'**
  String staff_dashboard_room_guest(String room, String guest);

  /// No description provided for @staff_dashboard_generate_report.
  ///
  /// In es, this message translates to:
  /// **'Generar informe'**
  String get staff_dashboard_generate_report;

  /// No description provided for @staff_checkins_title.
  ///
  /// In es, this message translates to:
  /// **'Check-ins'**
  String get staff_checkins_title;

  /// No description provided for @staff_checkins_tab_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get staff_checkins_tab_pending;

  /// No description provided for @staff_checkins_tab_in_progress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get staff_checkins_tab_in_progress;

  /// No description provided for @staff_checkins_tab_completed.
  ///
  /// In es, this message translates to:
  /// **'Completados'**
  String get staff_checkins_tab_completed;

  /// No description provided for @staff_checkins_status_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get staff_checkins_status_pending;

  /// No description provided for @staff_checkins_status_in_progress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get staff_checkins_status_in_progress;

  /// No description provided for @staff_checkins_status_completed.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get staff_checkins_status_completed;

  /// No description provided for @staff_checkins_start.
  ///
  /// In es, this message translates to:
  /// **'Iniciar'**
  String get staff_checkins_start;

  /// No description provided for @staff_checkins_new_checkin.
  ///
  /// In es, this message translates to:
  /// **'Nuevo check-in'**
  String get staff_checkins_new_checkin;

  /// No description provided for @staff_checkins_complete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get staff_checkins_complete;

  /// No description provided for @staff_checkins_view_details.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get staff_checkins_view_details;

  /// No description provided for @guest_access_wifi_password_label.
  ///
  /// In es, this message translates to:
  /// **'Contraseña WiFi'**
  String get guest_access_wifi_password_label;

  /// No description provided for @guest_access_locker_provided_by_staff.
  ///
  /// In es, this message translates to:
  /// **'Proporcionado por el personal'**
  String get guest_access_locker_provided_by_staff;

  /// No description provided for @guest_access_rule_smoke_free_title.
  ///
  /// In es, this message translates to:
  /// **'Sin humo'**
  String get guest_access_rule_smoke_free_title;

  /// No description provided for @guest_accommodation_view_rules_pdf.
  ///
  /// In es, this message translates to:
  /// **'Ver normas en PDF'**
  String get guest_accommodation_view_rules_pdf;

  /// No description provided for @public_hero_title_line1.
  ///
  /// In es, this message translates to:
  /// **'Tu Estancia,'**
  String get public_hero_title_line1;

  /// No description provided for @public_hero_title_line2.
  ///
  /// In es, this message translates to:
  /// **'Elevada'**
  String get public_hero_title_line2;

  /// No description provided for @admin_booking_send_whatsapp_title.
  ///
  /// In es, this message translates to:
  /// **'Enviar código por WhatsApp'**
  String get admin_booking_send_whatsapp_title;

  /// No description provided for @admin_booking_send_whatsapp_no_phone.
  ///
  /// In es, this message translates to:
  /// **'El huésped no tiene teléfono'**
  String get admin_booking_send_whatsapp_no_phone;

  /// No description provided for @admin_booking_send_whatsapp_no_phone_desc.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número de teléfono para enviar el código por WhatsApp.'**
  String get admin_booking_send_whatsapp_no_phone_desc;

  /// No description provided for @admin_booking_send_whatsapp_phone_hint.
  ///
  /// In es, this message translates to:
  /// **'+34 600 000 000'**
  String get admin_booking_send_whatsapp_phone_hint;

  /// No description provided for @admin_booking_send_whatsapp_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir WhatsApp'**
  String get admin_booking_send_whatsapp_error;

  /// No description provided for @admin_booking_send_whatsapp_message.
  ///
  /// In es, this message translates to:
  /// **'🏠 *{propertyName}*\n📋 Reserva: *{bookingCode}*\n📅 Check-in: {checkIn}\n📅 Check-out: {checkOut}\n\nDescarga la app BF Stay para gestionar tu estancia.'**
  String admin_booking_send_whatsapp_message(
    String propertyName,
    String bookingCode,
    String checkIn,
    String checkOut,
  );
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return SDe();
    case 'en':
      return SEn();
    case 'es':
      return SEs();
    case 'fr':
      return SFr();
    case 'it':
      return SIt();
    case 'pt':
      return SPt();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
