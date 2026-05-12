// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class SPt extends S {
  SPt([String locale = 'pt']) : super(locale);

  @override
  String get common_app_name => 'BF Stay';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_exit => 'Sair';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_loading => 'Carregando...';

  @override
  String get common_retry => 'Tentar novamente';

  @override
  String get common_accept => 'Aceitar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_back => 'Voltar';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error => 'Erro';

  @override
  String get common_success => 'Sucesso';

  @override
  String get common_no_data => 'Sem dados';

  @override
  String get common_yes => 'Sim';

  @override
  String get common_no => 'Não';

  @override
  String get common_send => 'Enviar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_search => 'Pesquisar';

  @override
  String get common_later => 'Mais tarde';

  @override
  String get common_update => 'Atualizar';

  @override
  String get common_understood => 'Entendido';

  @override
  String get common_exit_app_title => 'Sair do BF Stay';

  @override
  String get common_exit_app_message =>
      'Tem certeza de que deseja sair do aplicativo?\n\nSua sessão permanecerá ativa quando você voltar.';

  @override
  String get common_logout_title => 'Terminar sessão';

  @override
  String get common_logout_message =>
      'Tem certeza de que deseja terminar sessão?\n\nVocê poderá voltar a acessar com seu código de reserva quando precisar.';

  @override
  String get common_logout_button => 'Terminar sessão';

  @override
  String get common_splash_ready => 'Pronto';

  @override
  String get common_splash_loading => 'Carregando...';

  @override
  String get common_update_force_title => 'Atualização Obrigatória';

  @override
  String get common_update_available_title => 'Nova Versão Disponível';

  @override
  String get common_update_force_message =>
      'É necessário atualizar o aplicativo para continuar a usá-lo. Esta versão inclui melhorias importantes e correções de segurança.';

  @override
  String get common_update_available_message =>
      'Há uma nova versão disponível com melhorias e correções. Deseja atualizar agora?';

  @override
  String common_update_version(String version) {
    return 'Versão $version';
  }

  @override
  String get common_page_not_found => 'Página não encontrada';

  @override
  String get common_invalid_route => 'Rota inválida';

  @override
  String get common_back_to_home => 'Voltar ao início';

  @override
  String get common_theme_light => 'Claro';

  @override
  String get common_theme_dark => 'Escuro';

  @override
  String get common_theme_mode_light => 'Modo Claro';

  @override
  String get common_theme_mode_dark => 'Modo Escuro';

  @override
  String get common_theme_system => 'Sistema';

  @override
  String get common_theme_app_label => 'Tema do aplicativo';

  @override
  String common_copied_to_clipboard(String type) {
    return '$type copiado para a área de transferência';
  }

  @override
  String get common_phone_type => 'Telefone';

  @override
  String get common_email_type => 'Email';

  @override
  String get enum_booking_status_created => 'Criada';

  @override
  String get enum_booking_status_confirmed => 'Confirmada';

  @override
  String get enum_booking_status_active => 'Ativa';

  @override
  String get enum_booking_status_in_house => 'Na casa';

  @override
  String get enum_booking_status_checked_out => 'Finalizada';

  @override
  String get enum_booking_status_closed => 'Fechada';

  @override
  String get enum_booking_status_cancelled => 'Cancelada';

  @override
  String get enum_booking_status_created_desc =>
      'Reserva criada, pendente de confirmação';

  @override
  String get enum_booking_status_confirmed_desc =>
      'Reserva confirmada, pendente de check-in';

  @override
  String get enum_booking_status_active_desc =>
      'Check-in validado, painel completo acessível';

  @override
  String get enum_booking_status_in_house_desc =>
      'Hóspede fisicamente no alojamento';

  @override
  String get enum_booking_status_checked_in_legacy_desc =>
      'Check-in validado (legacy)';

  @override
  String get enum_booking_status_checked_out_desc =>
      'Check-out realizado, hóspede saiu';

  @override
  String get enum_booking_status_closed_desc => 'Reserva finalizada e fechada';

  @override
  String get enum_booking_status_cancelled_desc => 'Reserva cancelada';

  @override
  String get enum_checkin_status_not_started => 'Pendente';

  @override
  String get enum_checkin_status_in_progress => 'Em progresso';

  @override
  String get enum_checkin_status_submitted => 'Enviado';

  @override
  String get enum_checkin_status_validated => 'Validado';

  @override
  String get enum_checkin_status_rejected => 'Rejeitado';

  @override
  String get enum_checkin_status_cancelled => 'Cancelado';

  @override
  String get enum_checkin_status_not_started_desc =>
      'O hóspede ainda não iniciou o check-in';

  @override
  String get enum_checkin_status_in_progress_desc =>
      'O hóspede está a completar os seus dados';

  @override
  String get enum_checkin_status_submitted_desc =>
      'Pendente de revisão pelo administrador';

  @override
  String get enum_checkin_status_validated_desc =>
      'Check-in validado, estadia autorizada';

  @override
  String get enum_checkin_status_rejected_desc =>
      'Requer correção pelo hóspede';

  @override
  String get enum_checkin_status_cancelled_desc =>
      'Reserva cancelada, contacte a receção';

  @override
  String get enum_checkout_status_not_started => 'Não iniciado';

  @override
  String get enum_checkout_status_requested => 'Solicitado';

  @override
  String get enum_checkout_status_validated => 'Validado';

  @override
  String get enum_checkout_status_rejected => 'Rejeitado';

  @override
  String get enum_checkout_status_not_started_desc =>
      'A estadia ainda está em curso';

  @override
  String get enum_checkout_status_requested_desc =>
      'O hóspede solicitou o check-out';

  @override
  String get enum_checkout_status_validated_desc =>
      'Check-out validado, reserva pronta para fechar';

  @override
  String get enum_checkout_status_rejected_desc => 'Há incidências a resolver';

  @override
  String get public_badge_exclusivity => 'EXCLUSIVIDADE GARANTIDA';

  @override
  String get public_hero_title_prefix => 'A Sua Estadia, ';

  @override
  String get public_hero_title_suffix => 'Elevada';

  @override
  String get public_cta_access_booking => 'Aceder à minha reserva';

  @override
  String get public_services_section_title => 'Os Nossos Serviços';

  @override
  String get public_footer_brand_name => 'BF STAY';

  @override
  String public_footer_copyright(int year) {
    return '© $year BF Stay • Todos os direitos reservados';
  }

  @override
  String get public_footer_privacy_policy => 'Política de Privacidade';

  @override
  String get public_service_checkin_title => 'Check-in digital';

  @override
  String get public_service_checkin_desc => 'Registro sem espera.';

  @override
  String get public_service_checkout_title => 'Check-out digital';

  @override
  String get public_service_checkout_desc => 'Saída rápida e simples.';

  @override
  String get public_service_house_rules_title => 'Regras da casa';

  @override
  String get public_service_house_rules_desc => 'Regras e recomendações.';

  @override
  String get public_service_what_to_see_title => 'O que visitar?';

  @override
  String get public_service_what_to_see_desc =>
      'Locais de interesse nas proximidades.';

  @override
  String get public_service_parking_title => 'Parqueamentos';

  @override
  String get public_service_parking_desc => 'Opções de estacionamento.';

  @override
  String get public_service_chat_title => 'Chat';

  @override
  String get public_service_chat_desc => 'Concierge virtual 24/7.';

  @override
  String get public_service_accommodations_title => 'Alojamentos';

  @override
  String get public_service_accommodations_desc => 'Outras propriedades.';

  @override
  String get public_service_reviews_title => 'Avaliações';

  @override
  String get public_service_reviews_desc => 'Opiniões dos hóspedes.';

  @override
  String get public_service_parking_title_light => 'Estacionamentos Próximos';

  @override
  String get public_service_accommodations_title_light =>
      'Os Nossos Alojamentos';

  @override
  String get public_service_accommodations_desc_light =>
      'Outras propriedades disponíveis.';

  @override
  String get public_service_reviews_title_light => 'Avaliações e Comentários';

  @override
  String get public_hero_subtitle =>
      'Gestão inteligente para alojamentos exclusivos.';

  @override
  String get auth_login_brand_name => 'BF Stay';

  @override
  String get auth_login_subtitle => 'Painel de Controlo';

  @override
  String get auth_feature_bookings => 'Gestão de reservas';

  @override
  String get auth_feature_checkin => 'Check-in digital';

  @override
  String get auth_feature_chat => 'Chat com hóspedes';

  @override
  String get auth_feature_keyless => 'Acesso sem chaves';

  @override
  String get auth_field_email => 'Email';

  @override
  String get auth_field_password => 'Palavra-passe';

  @override
  String get auth_validation_email_required =>
      'Por favor introduza o seu email';

  @override
  String get auth_validation_email_invalid =>
      'Por favor introduza um email válido';

  @override
  String get auth_validation_password_required =>
      'Por favor introduza a sua palavra-passe';

  @override
  String get auth_validation_password_min_length =>
      'A palavra-passe deve ter pelo menos 6 caracteres';

  @override
  String get auth_forgot_password => 'Esqueceu a palavra-passe?';

  @override
  String get auth_login_button => 'Iniciar Sessão';

  @override
  String get auth_divider_or => 'ou';

  @override
  String get auth_guest_access_button => 'Acesso com código de reserva';

  @override
  String get auth_login_footer => 'BF Stay © 2026';

  @override
  String get auth_recover_password_title => 'Recuperar Palavra-passe';

  @override
  String get auth_recover_password_body =>
      'Introduza o seu email e enviaremos instruções para redefinir a sua palavra-passe.';

  @override
  String get auth_recover_password_sent => 'Email de recuperação enviado';

  @override
  String get auth_button_send => 'Enviar';

  @override
  String get auth_booking_access_title => 'Acesso de Hóspede';

  @override
  String get auth_booking_benefit_code => 'Código de reserva';

  @override
  String get auth_booking_benefit_personal => 'Acesso personalizado';

  @override
  String get auth_booking_benefit_instant => 'Acesso instantâneo';

  @override
  String get auth_booking_benefit_secure_checkin => 'Check-in seguro';

  @override
  String get auth_booking_code_info_short =>
      'O código de reserva foi enviado no email de confirmação.';

  @override
  String get auth_booking_code_info_full =>
      'O código de reserva foi enviado no email de confirmação da sua reserva.';

  @override
  String get auth_booking_desktop_subtitle =>
      'Desfrute da sua estadia com acesso digital';

  @override
  String get auth_booking_form_subtitle =>
      'Introduza o seu código de reserva para aceder ao seu alojamento';

  @override
  String get auth_booking_field_code => 'Código de Reserva';

  @override
  String get auth_booking_code_hint => 'XX-XXXX-XXXX';

  @override
  String get auth_booking_validation_code_required =>
      'Por favor introduza o seu código de reserva';

  @override
  String get auth_booking_validation_code_invalid =>
      'O formato do código não é válido';

  @override
  String get auth_booking_access_button => 'Aceder';

  @override
  String get auth_booking_help_title => 'Onde encontro o meu código?';

  @override
  String get auth_booking_help_body =>
      'O código de reserva foi enviado no email de confirmação da sua reserva. Tem o formato BF-XXXXX.';

  @override
  String get auth_booking_footer => 'BF Stay © 2026';

  @override
  String get auth_booking_error_title => 'Erro de Acesso';

  @override
  String get auth_booking_error_code_not_found =>
      'O código de reserva não existe. Por favor, verifique que o escreveu corretamente.';

  @override
  String get auth_booking_error_code_expired =>
      'Este código de reserva expirou. Contacte a receção para obter um novo.';

  @override
  String get auth_booking_error_email_mismatch =>
      'O email não coincide com o da reserva. Verifique que é o mesmo email que usou ao reservar.';

  @override
  String get auth_booking_error_generic =>
      'Não foi possível verificar o código de reserva. Por favor, tente novamente.';

  @override
  String get auth_booking_error_dismiss => 'Entendido';

  @override
  String get auth_sheet_title => 'Acesso à sua reserva';

  @override
  String get auth_sheet_subtitle =>
      'Introduza o seu email e o código que recebeu';

  @override
  String get auth_sheet_label_email => 'CORREIO ELETRÓNICO';

  @override
  String get auth_sheet_hint_email => 'seu@email.com';

  @override
  String get auth_sheet_label_code => 'CÓDIGO DE RESERVA';

  @override
  String get auth_sheet_hint_code => 'BF-XXXX-XXXX';

  @override
  String get auth_sheet_submit_button => 'Aceder à minha reserva';

  @override
  String get auth_sheet_help_text =>
      'Não tem o seu código? Contacte o seu alojamento';

  @override
  String get auth_admin_sheet_title => 'Acesso privado';

  @override
  String get auth_admin_sheet_subtitle =>
      'Apenas pessoal autorizado de BF-Stay';

  @override
  String get auth_admin_label_email => 'CORREIO ELETRÓNICO';

  @override
  String get auth_admin_hint_email => 'admin@bfstay.com';

  @override
  String get auth_admin_label_password => 'PALAVRA-PASSE';

  @override
  String get auth_admin_hint_password => '••••••••';

  @override
  String get auth_admin_error_unauthorized => 'Não tem acesso a este painel';

  @override
  String get auth_admin_submit_button => 'Aceder ao painel';

  @override
  String get guest_settings_title => 'Definições';

  @override
  String get guest_settings_section_language => 'Idioma';

  @override
  String get guest_settings_language_title => 'Idioma da aplicação';

  @override
  String get guest_settings_language_subtitle =>
      'Selecione o idioma da interface';

  @override
  String get guest_settings_section_legal => 'Legal';

  @override
  String get guest_settings_privacy_policy_title => 'Política de Privacidade';

  @override
  String get guest_settings_privacy_policy_subtitle =>
      'Consulte a nossa política de privacidade';

  @override
  String get guest_settings_privacy_open_error =>
      'Não foi possível abrir a política de privacidade';

  @override
  String get notification_channel_name => 'BF Stay Notificações';

  @override
  String get notification_channel_description =>
      'Canal de notificações de BF Stay';

  @override
  String get notification_checkin_validated_title => '✅ Check-in Validado';

  @override
  String get notification_checkin_validated_body =>
      'O seu check-in foi validado corretamente. Bem-vindo!';

  @override
  String get notification_checkin_rejected_title => '❌ Check-in Rejeitado';

  @override
  String get notification_checkin_rejected_body =>
      'O seu check-in foi rejeitado. Por favor, reveja a sua documentação.';

  @override
  String notification_checkin_rejected_body_with_reason(String reason) {
    return 'O seu check-in foi rejeitado: $reason';
  }

  @override
  String get notification_booking_cancelled_title => '🚫 Reserva Cancelada';

  @override
  String get notification_booking_cancelled_body =>
      'A sua reserva foi cancelada. Contacte a receção.';

  @override
  String notification_booking_cancelled_body_with_reason(String reason) {
    return 'A sua reserva foi cancelada: $reason';
  }

  @override
  String get notification_checkin_status_update_title =>
      '📋 Atualização de Check-in';

  @override
  String notification_checkin_status_update_body(String status) {
    return 'O estado do seu check-in mudou para: $status';
  }

  @override
  String get notification_admin_checkin_submitted_title =>
      '📝 Novo Check-in Pendente';

  @override
  String notification_admin_checkin_submitted_body(
    String guestName,
    String unitName,
  ) {
    return '$guestName enviou o seu check-in para $unitName. Pendente de revisão.';
  }

  @override
  String get guest_parking_title => 'Estacionamentos';

  @override
  String get guest_parking_available_singular => 'estacionamento disponível';

  @override
  String get guest_parking_available_plural => 'estacionamentos disponíveis';

  @override
  String get guest_parking_error_loading => 'Erro ao carregar';

  @override
  String get guest_parking_empty_title => 'Não há estacionamentos';

  @override
  String get guest_parking_empty_subtitle =>
      'Em breve adicionaremos informação de estacionamentos próximos';

  @override
  String guest_parking_for_unit(String unitName) {
    return 'Estacionamentos para $unitName';
  }

  @override
  String guest_parking_gps_label(String label) {
    return 'GPS: $label';
  }

  @override
  String get guest_parking_info_zones_title =>
      'INFORMAÇÃO ZONAS DE ESTACIONAMENTO';

  @override
  String get guest_parking_plaza_arenal_title => 'ESTACIONAMENTO PLAZA ARENAL';

  @override
  String get guest_parking_plaza_arenal_subtitle => 'A cerca de 5 minutos a pé';

  @override
  String get guest_parking_plaza_arenal_content =>
      '• Pagando a estadia através da app El Parking: 6,95€/24h\n• Reservando através do seu site: 8€/24h (mínimo 24h)\n• Pagando o ticket na máquina: 16€/24h';

  @override
  String get guest_parking_centro_title => 'ESTACIONAMENTO NA ZONA CENTRO';

  @override
  String get guest_parking_centro_subtitle => 'O.R.A AZUL';

  @override
  String get guest_parking_centro_content =>
      '• Segunda a Sexta: 09:00 - 13:30 e 17:00 - 20:00\n• Sábados: 09:00 - 14:00\n• Julho e Agosto: 09:00 - 14:00';

  @override
  String get guest_parking_free_zone_title => 'ESTACIONAMENTO ZONA GRATUITA';

  @override
  String get guest_parking_free_zone_subtitle => 'A cerca de 10 minutos a pé';

  @override
  String get guest_parking_free_zone_content =>
      'Zona livre de estacionamento rotativo.';

  @override
  String get guest_checkin_camera_not_available => 'Não há câmeras disponíveis';

  @override
  String guest_checkin_camera_init_error(String error) {
    return 'Erro ao inicializar câmera: $error';
  }

  @override
  String guest_checkin_camera_capture_error(String error) {
    return 'Erro ao capturar: $error';
  }

  @override
  String get guest_checkin_camera_scan_title => 'Digitalizar Documento';

  @override
  String get guest_checkin_camera_starting => 'A iniciar câmera...';

  @override
  String get guest_checkin_camera_frame_hint =>
      'Enquadre o documento dentro do retângulo';

  @override
  String get guest_checkin_camera_document_label => 'Documento de Identidade';

  @override
  String get admin_chat_messages => 'Mensagens';

  @override
  String get admin_chat_conversation_deleted => 'Conversa eliminada';

  @override
  String get admin_chat_empty_title => 'Sem conversas';

  @override
  String get admin_chat_empty_subtitle =>
      'As conversas com hóspedes\naparecerão aqui';

  @override
  String get guest_chat_input_hint => 'Escreva uma mensagem...';

  @override
  String get admin_booking_detail_title => 'Detalhe de Reserva';

  @override
  String get admin_booking_not_found => 'Reserva não encontrada';

  @override
  String admin_booking_error(String error) {
    return 'Erro: $error';
  }

  @override
  String admin_booking_error_validating(String error) {
    return 'Erro ao validar: $error';
  }

  @override
  String admin_booking_error_rejecting(String error) {
    return 'Erro ao rejeitar: $error';
  }

  @override
  String admin_booking_error_validating_checkout(String error) {
    return 'Erro ao validar check-out: $error';
  }

  @override
  String admin_booking_error_rejecting_checkout(String error) {
    return 'Erro ao rejeitar check-out: $error';
  }

  @override
  String admin_booking_error_closing(String error) {
    return 'Erro ao fechar reserva: $error';
  }

  @override
  String admin_booking_error_cancelling(String error) {
    return 'Erro ao cancelar reserva: $error';
  }

  @override
  String admin_booking_error_deleting(String error) {
    return 'Erro ao eliminar reserva: $error';
  }

  @override
  String admin_booking_error_updating(String error) {
    return 'Erro ao atualizar: $error';
  }

  @override
  String get admin_booking_resend_error => 'Não foi possível reenviar o código';

  @override
  String get admin_booking_notification_sent =>
      'Notificação enviada corretamente';

  @override
  String get admin_booking_notification_error => 'Erro ao enviar a notificação';

  @override
  String get admin_booking_code_resent => 'Código reenviado corretamente';

  @override
  String get admin_booking_checkin_validated =>
      'Check-in validado corretamente';

  @override
  String get admin_booking_checkin_rejected => 'Check-in rejeitado';

  @override
  String get admin_booking_checkout_validated =>
      'Check-out validado corretamente';

  @override
  String get admin_booking_checkout_rejected => 'Check-out rejeitado';

  @override
  String get admin_booking_incidents_detected => 'Incidências detetadas';

  @override
  String get admin_booking_closed_successfully =>
      'Reserva fechada corretamente';

  @override
  String get admin_booking_cancelled_successfully =>
      'Reserva cancelada corretamente';

  @override
  String get admin_booking_deleted_successfully =>
      'Reserva eliminada corretamente';

  @override
  String get admin_booking_keybox_updated => 'Código keybox atualizado';

  @override
  String get admin_booking_already_closed_title => 'Reserva já fechada';

  @override
  String get admin_booking_already_closed_message =>
      'Esta reserva já se encontra fechada.';

  @override
  String get admin_booking_already_cancelled_title => 'Reserva já cancelada';

  @override
  String get admin_booking_already_cancelled_message =>
      'Esta reserva já se encontra cancelada.';

  @override
  String get admin_booking_cannot_delete_title => 'Não é possível eliminar';

  @override
  String admin_booking_cannot_delete_message(String status) {
    return 'Não é possível eliminar uma reserva em estado $status.';
  }

  @override
  String get admin_booking_cancel_booking => 'Cancelar Reserva';

  @override
  String get admin_booking_cancel_booking_confirm =>
      'Tem a certeza de que deseja cancelar esta reserva? Esta ação não pode ser desfeita.';

  @override
  String get admin_booking_no_keep => 'Não, manter';

  @override
  String get admin_booking_yes_cancel => 'Sim, cancelar';

  @override
  String get admin_booking_delete_booking => 'Eliminar Reserva';

  @override
  String get admin_booking_delete_confirm =>
      'Tem a certeza de que deseja eliminar completamente esta reserva e todos os seus dados associados? Esta ação é irreversível.';

  @override
  String get admin_booking_close_booking => 'Fechar Reserva';

  @override
  String get admin_booking_close_confirm =>
      'Deseja fechar manualmente esta reserva? Será registada a data de encerramento.';

  @override
  String get admin_booking_close_notes_hint =>
      'Notas de encerramento (opcional)';

  @override
  String get admin_booking_reject_checkout => 'Rejeitar Check-out';

  @override
  String get admin_booking_reject_checkout_desc =>
      'Indique as incidências detetadas para rejeitar o check-out.';

  @override
  String get admin_booking_incidents_hint =>
      'Descreva as incidências detetadas...';

  @override
  String get admin_booking_reject => 'Rejeitar';

  @override
  String get admin_booking_reject_checkin => 'Rejeitar Check-in';

  @override
  String get admin_booking_reject_checkin_desc =>
      'Indique o motivo da rejeição do check-in.';

  @override
  String get admin_booking_reject_reason_hint =>
      'Motivo da rejeição (opcional)...';

  @override
  String admin_booking_share_code_message(String code) {
    return 'O seu código de acesso é: $code';
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
  String get admin_booking_share_download_app => 'Descarregue a app: BF Stay';

  @override
  String get admin_booking_edit_keybox_title => 'Código Keybox';

  @override
  String get admin_booking_edit_keybox_desc =>
      'Introduza o código da caixa de chaves';

  @override
  String get admin_booking_checkin_done => 'Check-in realizado';

  @override
  String get admin_booking_checkout_done => 'Check-out realizado';

  @override
  String get admin_booking_units_label => 'quartos';

  @override
  String get admin_booking_email_sent => 'Email enviado';

  @override
  String get admin_booking_email_pending => 'Email pendente';

  @override
  String get admin_booking_code_used => 'Código utilizado';

  @override
  String get admin_booking_code_unused => 'Código não utilizado';

  @override
  String get admin_booking_checkin_ok => 'Check-in OK';

  @override
  String get admin_booking_checkin_pending => 'Pendente de validação';

  @override
  String get admin_booking_checkin_in_progress => 'Em progresso';

  @override
  String get admin_booking_no_checkin => 'Sem check-in';

  @override
  String get admin_booking_guest_section => 'HÓSPEDE';

  @override
  String get admin_booking_no_name => 'Sem nome';

  @override
  String get admin_booking_reservation_section => 'RESERVA';

  @override
  String get admin_booking_checkin_label => 'Check-in';

  @override
  String get admin_booking_checkout_label => 'Check-out';

  @override
  String get admin_booking_night_singular => 'noite';

  @override
  String get admin_booking_night_plural => 'noites';

  @override
  String get admin_booking_years_label => 'anos';

  @override
  String get admin_booking_rooms_section => 'Quartos';

  @override
  String get admin_booking_wifi_label => 'WiFi';

  @override
  String get admin_booking_wifi_network_label => 'Rede:';

  @override
  String get admin_booking_wifi_password_label => 'Palavra-passe:';

  @override
  String get admin_booking_wifi_password_clipboard => 'Palavra-passe WiFi';

  @override
  String get admin_booking_access_code_label => 'Código de acesso';

  @override
  String get admin_booking_access_code_clipboard => 'Código de acesso';

  @override
  String get admin_booking_access_instructions_label => 'Instruções de acesso';

  @override
  String get admin_booking_access_codes_section => 'CÓDIGOS DE ACESSO';

  @override
  String get admin_booking_reservation_code_label => 'Código de reserva';

  @override
  String get admin_booking_share_button => 'Partilhar';

  @override
  String get admin_booking_keybox_not_set => 'Não configurado';

  @override
  String get admin_booking_keybox_code_label => 'Código Keybox';

  @override
  String get admin_booking_keybox_code_clipboard => 'Código Keybox';

  @override
  String get admin_booking_checkin_not_started => 'Check-in não iniciado';

  @override
  String get admin_booking_checkin_validated_status => 'Check-in validado';

  @override
  String get admin_booking_checkin_rejected_status => 'Check-in rejeitado';

  @override
  String get admin_booking_checkin_pending_validation =>
      'Pendente de validação';

  @override
  String get admin_booking_checkin_in_progress_status =>
      'Check-in em progresso';

  @override
  String get admin_booking_checkin_section => 'CHECK-IN';

  @override
  String get admin_booking_docs_pending => 'documentos pendentes';

  @override
  String get admin_booking_validate_button => 'Validar';

  @override
  String get admin_booking_reject_button => 'Rejeitar';

  @override
  String get admin_booking_internal_notes_section => 'NOTAS INTERNAS';

  @override
  String get admin_booking_closed_status => 'Reserva fechada';

  @override
  String get admin_booking_checkout_validated_status => 'Check-out validado';

  @override
  String get admin_booking_checkout_incidents_status =>
      'Check-out com incidências';

  @override
  String get admin_booking_checkout_requested_status => 'Check-out solicitado';

  @override
  String get admin_booking_checkout_pending_status => 'Check-out pendente';

  @override
  String get admin_booking_checkout_section => 'CHECK-OUT';

  @override
  String get admin_booking_requested_label => 'Solicitado:';

  @override
  String get admin_booking_notes_label => 'Notas:';

  @override
  String get admin_booking_incidents_button => 'Incidências';

  @override
  String get admin_booking_close_booking_button => 'Fechar Reserva';

  @override
  String get admin_booking_close_booking_description =>
      'O hóspede não solicitou check-out. Pode fechar a reserva manualmente.';

  @override
  String get admin_booking_signature_section => 'ASSINATURA DO TITULAR';

  @override
  String get admin_booking_signature_unavailable => 'Assinatura não disponível';

  @override
  String get admin_booking_actions_section => 'AÇÕES';

  @override
  String get admin_booking_resend_code_title => 'Reenviar código por email';

  @override
  String get admin_booking_last_sent_label => 'Último envio:';

  @override
  String get admin_booking_na => 'N/A';

  @override
  String get admin_booking_not_sent_yet => 'Ainda não foi enviado';

  @override
  String get admin_booking_room_ready_title => 'Quarto disponível';

  @override
  String get admin_booking_room_ready_subtitle =>
      'Notifique o hóspede que o quarto está pronto e pode aceder';

  @override
  String get admin_booking_cancel_booking_title => 'Cancelar reserva';

  @override
  String get admin_booking_cancel_booking_subtitle =>
      'Marque a reserva como cancelada';

  @override
  String get admin_booking_delete_booking_title => 'Eliminar reserva';

  @override
  String get admin_booking_delete_booking_subtitle =>
      'Apague completamente a reserva e os seus dados (apenas se não estiver finalizada)';

  @override
  String get admin_dashboard_admin_title => 'BF-Stay Admin';

  @override
  String get admin_dashboard_tab_summary => 'Resumo';

  @override
  String get admin_dashboard_tab_bookings => 'Reservas';

  @override
  String get admin_dashboard_tab_checkins => 'Check-ins';

  @override
  String get admin_dashboard_tab_invoices => 'Faturas';

  @override
  String get admin_dashboard_tab_marketing => 'Marketing';

  @override
  String get admin_dashboard_tab_properties => 'Alojamentos';

  @override
  String get guest_reviews_title => 'Avaliações';

  @override
  String get guest_reviews_write_review => 'Escrever avaliação';

  @override
  String get guest_reviews_published => 'Avaliação publicada corretamente';

  @override
  String get guest_reviews_publishing => 'A publicar avaliação...';

  @override
  String get guest_reviews_updating => 'A atualizar avaliação...';

  @override
  String get guest_reviews_deleting => 'A eliminar avaliação...';

  @override
  String get guest_reviews_loading => 'A carregar avaliações...';

  @override
  String get guest_reviews_delete_review => 'Eliminar avaliação';

  @override
  String get guest_reviews_delete_confirm =>
      'Tem a certeza de que quer eliminar a sua avaliação? Esta ação não pode ser desfeita.';

  @override
  String get guest_reviews_filter_all => 'Todas';

  @override
  String get guest_reviews_edit_review => 'Editar avaliação';

  @override
  String get guest_reviews_new_review => 'Nova avaliação';

  @override
  String get guest_reviews_updated => 'Avaliação atualizada';

  @override
  String get guest_reviews_info_public =>
      'A sua avaliação será pública e ajudará outros hóspedes a tomar decisões.';

  @override
  String get guest_reviews_your_rating => 'A sua classificação';

  @override
  String get guest_reviews_tap_stars => 'Toque nas estrelas para pontuar';

  @override
  String get guest_reviews_rating_1 => 'Muito mau';

  @override
  String get guest_reviews_rating_2 => 'Mau';

  @override
  String get guest_reviews_rating_3 => 'Regular';

  @override
  String get guest_reviews_rating_4 => 'Bom';

  @override
  String get guest_reviews_rating_5 => 'Excelente';

  @override
  String get guest_reviews_title_label => 'Título (opcional)';

  @override
  String get guest_reviews_title_hint => 'Resuma a sua experiência numa frase';

  @override
  String get guest_reviews_comment_required =>
      'Por favor, escreva um comentário';

  @override
  String get guest_reviews_comment_min_length =>
      'O comentário deve ter pelo menos 10 caracteres';

  @override
  String get guest_reviews_comment_label => 'O seu comentário *';

  @override
  String get guest_reviews_comment_hint => 'Conte-nos a sua experiência...';

  @override
  String get guest_reviews_save_changes => 'Guardar alterações';

  @override
  String get guest_reviews_publish_review => 'Publicar avaliação';

  @override
  String get guest_reviews_select_rating =>
      'Por favor, selecione uma pontuação';

  @override
  String get guest_reviews_saving => 'A guardar...';

  @override
  String get guest_alojamientos_title => 'Os Nossos Alojamentos';

  @override
  String get guest_alojamientos_error_title => 'Erro ao carregar';

  @override
  String get guest_alojamientos_empty_title => 'Não há alojamentos';

  @override
  String get guest_alojamientos_empty_subtitle =>
      'Não há alojamentos disponíveis neste momento';

  @override
  String guest_alojamientos_room_count(int count) {
    return '$count quartos';
  }

  @override
  String get guest_alojamiento_detail_title => 'Detalhe';

  @override
  String get guest_alojamiento_units_available => 'Unidades disponíveis';

  @override
  String get guest_alojamiento_no_units => 'Não há unidades disponíveis';

  @override
  String get guest_alojamiento_location => 'Localização';

  @override
  String get guest_alojamiento_common_areas => 'Zonas Comuns';

  @override
  String get guest_alojamiento_shared_spaces => 'Espaços partilhados';

  @override
  String get guest_alojamiento_common_areas_subtitle =>
      'Desfrute das áreas comuns do hotel';

  @override
  String get guest_alojamiento_no_photos => 'Não há fotos';

  @override
  String get guest_alojamiento_no_photos_subtitle =>
      'Não foram encontradas fotos de zonas comuns';

  @override
  String guest_alojamiento_photos_count(int count) {
    return '$count fotos';
  }

  @override
  String get guest_alojamiento_hotel_rooms_title => 'Hotel Boutique Jerez';

  @override
  String get guest_alojamiento_no_rooms => 'Não há quartos';

  @override
  String get guest_alojamiento_no_rooms_subtitle =>
      'Não há quartos disponíveis neste momento';

  @override
  String get guest_alojamiento_rooms => 'Quartos';

  @override
  String get guest_alojamiento_features => 'Características';

  @override
  String get guest_alojamiento_feature_flexible_checkin => 'Check-in flexível';

  @override
  String get guest_alojamiento_feature_wifi => 'WiFi gratuito';

  @override
  String get guest_alojamiento_feature_ac => 'Ar condicionado';

  @override
  String get guest_alojamiento_description => 'Descrição';

  @override
  String guest_alojamiento_description_text(String unitType) {
    return 'Descubra este $unitType completamente equipado para que a sua estadia seja o mais confortável possível. Tem tudo o necessário para desfrutar de Jerez ao seu ritmo.';
  }

  @override
  String get guest_alojamiento_services => 'Serviços incluídos';

  @override
  String get guest_alojamiento_service_kitchen => 'Cozinha equipada';

  @override
  String get guest_alojamiento_service_washer => 'Máquina de lavar';

  @override
  String get guest_alojamiento_service_tv => 'Smart TV';

  @override
  String get guest_alojamiento_service_bedding => 'Roupa de cama';

  @override
  String get guest_alojamiento_service_towels => 'Toalhas';

  @override
  String get guest_alojamiento_service_coffee => 'Máquina de café';

  @override
  String get guest_alojamiento_access_info => 'Informação de acesso';

  @override
  String get guest_alojamiento_box_location => 'Localização da caixa';

  @override
  String get guest_alojamiento_access_instructions => 'Instruções de acesso';

  @override
  String get guest_house_rules_title => 'Normas da Casa';

  @override
  String get guest_house_rules_subtitle => 'Consulte as normas e recomendações';

  @override
  String get guest_house_rules_empty_title => 'Não há normas';

  @override
  String get guest_house_rules_empty_subtitle =>
      'Este alojamento não tem normas registadas';

  @override
  String get guest_normas_title => 'Normas';

  @override
  String get guest_normas_hotel_title => 'Normas do Hotel';

  @override
  String get guest_normas_apartment_title => 'Normas do Apartamento';

  @override
  String get guest_normas_not_available => 'Não há normas disponíveis';

  @override
  String get guest_normas_image_error => 'Não foi possível carregar a imagem';

  @override
  String get guest_normas_generic_error => 'Ocorreu um erro';

  @override
  String get guest_que_ver_title => 'O que visitar?';

  @override
  String get guest_que_ver_clear_filters => 'Limpar';

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
  String get guest_que_ver_no_results => 'Sem resultados';

  @override
  String get guest_que_ver_no_places => 'Não há lugares';

  @override
  String get guest_que_ver_try_filters =>
      'Tente alterar os filtros de pesquisa';

  @override
  String get guest_que_ver_coming_soon =>
      'Em breve adicionaremos novos lugares';

  @override
  String get guest_que_ver_error_loading => 'Erro ao carregar o lugar';

  @override
  String get guest_que_ver_place_not_found => 'Lugar não encontrado';

  @override
  String get guest_que_ver_about_place => 'Sobre este lugar';

  @override
  String get guest_que_ver_address => 'Endereço';

  @override
  String get guest_que_ver_best_time => 'Melhor momento';

  @override
  String get guest_que_ver_location => 'Localização';

  @override
  String get guest_que_ver_practical_info => 'Informação prática';

  @override
  String get guest_que_ver_tips => 'Dicas';

  @override
  String get guest_que_ver_free_entry => 'Entrada gratuita';

  @override
  String get guest_que_ver_how_to_get => 'Como chegar';

  @override
  String get guest_que_ver_copy_link => 'Copiar link';

  @override
  String get guest_que_ver_official_web => 'Site oficial';

  @override
  String get guest_que_ver_link_copied =>
      'Link copiado para a área de transferência';

  @override
  String get guest_reviews_verified => 'Verificado';

  @override
  String get guest_reviews_show_less => 'Ver menos';

  @override
  String get guest_reviews_show_more => 'Ver mais';

  @override
  String get guest_reviews_empty_title => 'Sem avaliações ainda';

  @override
  String get guest_reviews_empty_subtitle =>
      'Seja o primeiro a partilhar a sua experiência';

  @override
  String get guest_reviews_write_first => 'Escrever avaliação';

  @override
  String guest_reviews_filter_empty_title(String filter) {
    return 'Sem resultados para $filter';
  }

  @override
  String get guest_reviews_filter_empty_subtitle =>
      'Tente selecionar outro filtro';

  @override
  String get guest_reviews_clear_filter => 'Limpar filtro';

  @override
  String guest_reviews_count_label(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avaliações',
      one: '1 avaliação',
    );
    return '$_temp0';
  }

  @override
  String get guest_reviews_no_reviews_title => 'Sem avaliações ainda';

  @override
  String get guest_reviews_be_first => 'Seja o primeiro';

  @override
  String get guest_access_no_booking => 'Não foi encontrada a reserva';

  @override
  String get guest_access_error_loading =>
      'Erro ao carregar os dados de acesso';

  @override
  String get guest_access_title => 'Acesso';

  @override
  String get guest_access_no_codes => 'Não há códigos de acesso disponíveis';

  @override
  String get guest_access_codes_title => 'Códigos de Acesso';

  @override
  String get guest_access_codes_subtitle =>
      'Utilize estes códigos para aceder ao seu alojamento';

  @override
  String get guest_access_main_code => 'Código principal';

  @override
  String get guest_access_main_door => 'Porta principal';

  @override
  String guest_access_valid_period(String from, String until) {
    return 'Válido de $from até $until';
  }

  @override
  String get guest_access_wifi_title => 'WiFi';

  @override
  String get guest_access_wifi_network => 'Rede:';

  @override
  String get guest_access_wifi_password => 'Palavra-passe:';

  @override
  String get guest_access_password_copied =>
      'Palavra-passe copiada para a área de transferência';

  @override
  String get guest_access_other_accesses => 'Outros acessos';

  @override
  String get guest_access_instructions => 'Instruções de acesso';

  @override
  String get guest_guide_title => 'Guia de Estadia';

  @override
  String get guest_guide_subtitle => 'Toda a informação da sua estadia';

  @override
  String get guest_guide_contact => 'Contacto';

  @override
  String get guest_guide_phone_1 => 'Telefone 1';

  @override
  String get guest_guide_phone_2 => 'Telefone 2';

  @override
  String get guest_guide_your_data => 'Os Seus Dados';

  @override
  String get guest_guide_accommodation => 'Alojamento';

  @override
  String get guest_guide_property => 'Propriedade';

  @override
  String get guest_guide_checkin => 'Check-in';

  @override
  String get guest_guide_checkout => 'Check-out';

  @override
  String get guest_guide_guests => 'Hóspedes';

  @override
  String get guest_guide_services => 'Serviços';

  @override
  String get guest_guide_wifi => 'WiFi';

  @override
  String get guest_guide_laundry => 'Lavandaria';

  @override
  String get guest_guide_laundry_desc => 'Serviço de lavandaria disponível';

  @override
  String get guest_guide_jacuzzi => 'Jacuzzi';

  @override
  String get guest_guide_ac => 'Ar Condicionado';

  @override
  String get guest_guide_ac_title => 'Ar Condicionado';

  @override
  String get guest_guide_ac_desc =>
      'Controlo de climatização no seu alojamento';

  @override
  String get guest_guide_tv => 'TV';

  @override
  String get guest_guide_tv_title => 'Televisão';

  @override
  String get guest_guide_tv_desc => 'Smart TV com canais e aplicações';

  @override
  String get guest_guide_not_available => 'Não disponível';

  @override
  String get guest_guide_wifi_desc => 'Ligação WiFi incluída';

  @override
  String get guest_guide_house_rules => 'Normas da Casa';

  @override
  String get guest_guide_rule_checkin => 'Check-in a partir das 16:00';

  @override
  String guest_guide_rule_checkout(String time) {
    return 'Check-out antes das $time';
  }

  @override
  String get guest_guide_rule_no_smoking => 'Não fumadores';

  @override
  String get guest_guide_rule_no_parties => 'Não são permitidas festas';

  @override
  String get guest_guide_rule_no_pets =>
      'Não são admitidos animais de estimação';

  @override
  String get guest_notifications_title => 'Notificações';

  @override
  String get guest_notifications_delete_all => 'Eliminar tudo';

  @override
  String get guest_notifications_delete_all_title =>
      'Eliminar todas as notificações';

  @override
  String get guest_notifications_delete_all_confirm =>
      'Tem a certeza de que deseja eliminar todas as notificações? Esta ação não pode ser desfeita.';

  @override
  String guest_notifications_unread_count(int count) {
    return '$count não lidos';
  }

  @override
  String get guest_notifications_mark_all => 'Marcar tudo como lido';

  @override
  String get guest_notifications_empty_title => 'Sem notificações';

  @override
  String get guest_notifications_empty_subtitle =>
      'Aqui aparecerão as notificações da sua estadia';

  @override
  String get guest_notifications_read => 'Lido';

  @override
  String get guest_romantic_title => 'Pack Romântico';

  @override
  String get guest_romantic_surprise => 'Surpreenda o seu parceiro';

  @override
  String get guest_romantic_unforgettable => 'Crie um momento inesquecível';

  @override
  String get guest_romantic_includes => 'O que inclui?';

  @override
  String get guest_romantic_decoration_title => 'Decoração Romântica';

  @override
  String get guest_romantic_decoration_desc =>
      'Pétalas de rosa, velas e decoração especial no quarto';

  @override
  String get guest_romantic_choose_title => 'Escolha o seu detalhe';

  @override
  String get guest_romantic_choose_desc =>
      'Garrafa de cava ou chocolate artesanal para acompanhar a noite';

  @override
  String get guest_romantic_basic_pack => 'Pack Romântico Básico';

  @override
  String get guest_romantic_price => '20,00 €';

  @override
  String get guest_romantic_book_now => 'Reservar Agora';

  @override
  String get guest_romantic_customize =>
      'Ou personalize com extras ao reservar';

  @override
  String get guest_romantic_redirect =>
      'Vai ser redirecionado para o site para completar a reserva do Pack Romântico. Continuar?';

  @override
  String get guest_romantic_how_to => 'Como reservar?';

  @override
  String get guest_romantic_step_1 => 'Selecione o Pack Romântico';

  @override
  String get guest_romantic_step_2 => 'Personalize os detalhes';

  @override
  String get guest_romantic_step_3 => 'Complete a reserva online';

  @override
  String get guest_romantic_step_4 => 'Desfrute da surpresa';

  @override
  String get guest_romantic_note =>
      'A decoração é preparada durante a sua ausência para que seja uma surpresa completa.';

  @override
  String get guest_jacuzzi_title => 'Jacuzzi';

  @override
  String get guest_jacuzzi_rules_title => 'Normas de Utilização';

  @override
  String get guest_jacuzzi_subtitle => 'Relaxe e desfrute';

  @override
  String get guest_jacuzzi_power => 'Ligar';

  @override
  String get guest_jacuzzi_power_step_1 =>
      'Prima o botão POWER para ligar o jacuzzi';

  @override
  String get guest_jacuzzi_power_step_2 => 'Aguarde até o painel se iluminar';

  @override
  String get guest_jacuzzi_power_step_3 =>
      'Selecione a temperatura desejada com os botões + e -';

  @override
  String get guest_jacuzzi_lock => 'Bloqueio do Painel';

  @override
  String get guest_jacuzzi_lock_step_1 =>
      'Para evitar ativações acidentais, pode bloquear o painel de controlo';

  @override
  String get guest_jacuzzi_lock_unlock => 'Desbloqueio';

  @override
  String get guest_jacuzzi_lock_unlock_step =>
      'Mantenha premido o botão LOCK durante 3 segundos';

  @override
  String get guest_jacuzzi_lock_manual => 'Bloqueio Manual';

  @override
  String get guest_jacuzzi_lock_manual_step =>
      'Prima e mantenha o botão LOCK durante 3 segundos para ativar';

  @override
  String get guest_jacuzzi_ozone => 'Função Ozono';

  @override
  String get guest_jacuzzi_ozone_intro =>
      'O sistema de ozono ajuda a manter a água limpa e desinfetada de forma automática.';

  @override
  String get guest_jacuzzi_ozone_step_1 => 'Prima o botão OZONE no painel';

  @override
  String get guest_jacuzzi_ozone_step_2 => 'A luz indicadora acender-se-á';

  @override
  String get guest_jacuzzi_ozone_step_3 =>
      'O sistema funcionará durante 30 minutos';

  @override
  String get guest_jacuzzi_ozone_step_4 =>
      'Desligar-se-á automaticamente ao terminar';

  @override
  String guest_jacuzzi_ozone_note(String note) {
    return 'Nota: $note';
  }

  @override
  String get guest_jacuzzi_massage => 'Funções de Massagem';

  @override
  String get guest_jacuzzi_air_jets => 'Jets de Ar';

  @override
  String get guest_jacuzzi_air_step_1 =>
      'Prima o botão AIR para ativar os jets de ar';

  @override
  String get guest_jacuzzi_air_step_2 =>
      'Ajuste a intensidade com os botões + e -';

  @override
  String get guest_jacuzzi_air_step_3 =>
      'Os jets criarão bolhas suaves na água';

  @override
  String get guest_jacuzzi_air_step_4 => 'Prima novamente para desativar';

  @override
  String get guest_jacuzzi_water_jets => 'Jets de Água';

  @override
  String get guest_jacuzzi_water_step_1 =>
      'Prima o botão JET para ativar os jets de água';

  @override
  String get guest_jacuzzi_water_step_2 =>
      'Os jets de água proporcionam uma massagem mais intensa';

  @override
  String get guest_jacuzzi_water_step_3 =>
      'Dirija os jets para as zonas de tensão muscular';

  @override
  String get guest_jacuzzi_water_step_4 => 'Prima novamente para desativar';

  @override
  String get guest_jacuzzi_important => 'Importante';

  @override
  String get guest_jacuzzi_water_level_info =>
      'O nível da água deve estar sempre acima dos jets para um correto funcionamento.';

  @override
  String get guest_jacuzzi_low_water_title => 'Se o nível estiver baixo:';

  @override
  String get guest_jacuzzi_low_water_stop => 'Pare o jacuzzi imediatamente';

  @override
  String get guest_jacuzzi_low_water_icon =>
      'Verifique o ícone de aviso no painel';

  @override
  String get guest_jacuzzi_low_water_resume =>
      'Encha com água até cobrir os jets antes de retomar.';

  @override
  String get guest_jacuzzi_water_responsibility => 'Uso Responsável da Água';

  @override
  String get guest_jacuzzi_water_refill_info =>
      'O jacuzzi tem uma capacidade considerável de água. Por favor, utilize-o de forma responsável.';

  @override
  String get guest_jacuzzi_capacity => 'Capacidade:';

  @override
  String get guest_jacuzzi_capacity_liters => '800 litros';

  @override
  String get guest_jacuzzi_water_regulation =>
      'O enchimento e esvaziamento do jacuzzi está regulado pelas normas locais de uso da água.';

  @override
  String get guest_jacuzzi_thanks =>
      'Obrigado pela sua colaboração no uso responsável da água.';

  @override
  String get guest_physical_registration_title => 'Registo Físico';

  @override
  String get guest_physical_registration_header => 'Registo na Receção';

  @override
  String get guest_physical_registration_subtitle =>
      'Complete o seu registo de forma presencial';

  @override
  String get guest_physical_registration_instructions => 'Instruções';

  @override
  String get guest_physical_registration_step_1_title => 'Dirija-se à receção';

  @override
  String get guest_physical_registration_step_1_desc =>
      'Vá à receção do hotel durante o horário de atendimento';

  @override
  String get guest_physical_registration_step_2_title =>
      'Apresente o seu documento';

  @override
  String get guest_physical_registration_step_2_desc =>
      'Mostre o seu documento de identidade original (DNI, passaporte ou carta de condução)';

  @override
  String get guest_physical_registration_step_3_title => 'Assine o registo';

  @override
  String get guest_physical_registration_step_3_desc =>
      'Assine o documento de registo de entrada';

  @override
  String get guest_physical_registration_step_4_title => 'Receba a sua chave';

  @override
  String get guest_physical_registration_step_4_desc =>
      'Entregaremos a chave do seu quarto';

  @override
  String get guest_physical_registration_schedule => 'Horário da Receção';

  @override
  String get guest_physical_registration_schedule_hours =>
      'Horário de atendimento';

  @override
  String get guest_physical_registration_schedule_days => 'Segunda a Sexta';

  @override
  String get guest_physical_registration_documents => 'Documentos Aceites';

  @override
  String get guest_physical_registration_doc_dni => 'DNI';

  @override
  String get guest_physical_registration_doc_passport => 'Passaporte';

  @override
  String get guest_physical_registration_doc_license => 'Carta de condução';

  @override
  String get guest_checkin_child_no_data =>
      'Menor de 14 anos, sem dados requeridos';

  @override
  String get guest_checkin_holder => 'Titular';

  @override
  String get guest_checkin_full_name => 'Nome completo';

  @override
  String get guest_checkin_email => 'Email';

  @override
  String get guest_checkin_phone => 'Telefone';

  @override
  String guest_checkin_young(int age) {
    return 'Menor ($age anos)';
  }

  @override
  String guest_checkin_adult(int number) {
    return 'Adulto $number';
  }

  @override
  String guest_checkin_guest(int number) {
    return 'Hóspede $number';
  }

  @override
  String get guest_checkin_document_id => 'Documento de identidade';

  @override
  String get guest_checkin_upload_document => 'Carregar documento';

  @override
  String get guest_checkin_document => 'Documento';

  @override
  String get guest_checkin_missing_photo => 'Falta foto do documento';

  @override
  String get guest_checkin_upload_document_title => 'Carregar Documento';

  @override
  String get guest_checkin_document_type => 'Tipo de documento';

  @override
  String get guest_checkin_document_number => 'Número de documento';

  @override
  String get guest_checkin_document_photo => 'Foto do documento';

  @override
  String get guest_checkin_image_captured => 'Imagem capturada';

  @override
  String get guest_checkin_tap_to_capture => 'Toque para capturar documento';

  @override
  String get guest_checkin_camera_or_gallery => 'Câmera ou galeria';

  @override
  String get guest_checkin_select_source => 'Selecionar origem';

  @override
  String get guest_checkin_camera => 'Câmera';

  @override
  String get guest_checkin_gallery => 'Galeria';

  @override
  String get guest_checkin_photo_required => 'Foto obrigatória';

  @override
  String get guest_checkin_document_number_required =>
      'Número de documento obrigatório';

  @override
  String get guest_checkin_confirm => 'Confirmar';

  @override
  String guest_checkin_capture_error(String error) {
    return 'Erro ao capturar imagem: $error';
  }

  @override
  String get admin_chat_title => 'Chat';

  @override
  String get admin_chat_online => 'Online';

  @override
  String get admin_chat_delete_conversation => 'Eliminar conversa';

  @override
  String get admin_chat_delete_confirm_body =>
      'Tem certeza de que deseja eliminar esta conversa?';

  @override
  String get admin_chat_deleted_success => 'Conversa eliminada com sucesso';

  @override
  String admin_chat_error_deleting(String error) {
    return 'Erro ao eliminar a conversa';
  }

  @override
  String get admin_checkin_detail_title => 'Detalhes do Check-in';

  @override
  String get admin_checkin_validate => 'Validar';

  @override
  String get admin_checkin_reject => 'Rejeitar';

  @override
  String get admin_checkin_cancel_booking => 'Cancelar Reserva';

  @override
  String get admin_checkin_error_loading => 'Erro ao carregar';

  @override
  String get admin_checkin_not_found => 'Check-in não encontrado';

  @override
  String get admin_checkin_status_pending => 'Pendente';

  @override
  String get admin_checkin_status_validated => 'Validado';

  @override
  String get admin_checkin_status_rejected => 'Rejeitado';

  @override
  String get admin_checkin_status_cancelled => 'Cancelado';

  @override
  String get admin_checkin_status_draft => 'Rascunho';

  @override
  String get admin_checkin_submitted_label => 'Enviado:';

  @override
  String get admin_checkin_validated_label => 'Validado:';

  @override
  String get admin_checkin_rejected_label => 'Rejeitado:';

  @override
  String get admin_checkin_cancelled_label => 'Cancelado:';

  @override
  String get admin_checkin_booking_info => 'Informação da Reserva';

  @override
  String get admin_checkin_property_label => 'Propriedade:';

  @override
  String get admin_checkin_units_label => 'quartos';

  @override
  String get admin_checkin_unit_label => 'quarto';

  @override
  String get admin_checkin_code_label => 'Código:';

  @override
  String get admin_checkin_checkin_date_label => 'Check-in:';

  @override
  String get admin_checkin_checkout_date_label => 'Check-out:';

  @override
  String get admin_checkin_guests_section => 'HÓSPEDES';

  @override
  String get admin_checkin_primary_badge => 'Titular';

  @override
  String get admin_checkin_na => 'N/D';

  @override
  String get admin_checkin_documents_section => 'DOCUMENTOS';

  @override
  String get admin_checkin_unknown_guest => 'Hóspede desconhecido';

  @override
  String get admin_checkin_signature_section => 'ASSINATURA';

  @override
  String get admin_checkin_doc_type_dni => 'DNI';

  @override
  String get admin_checkin_doc_type_nie => 'NIE';

  @override
  String get admin_checkin_doc_type_passport => 'Passaporte';

  @override
  String get admin_checkin_image_load_error => 'Erro ao carregar imagem';

  @override
  String get admin_checkin_validate_title => 'Validar Check-in';

  @override
  String get admin_checkin_validate_message =>
      'Tem certeza de que deseja validar este check-in?';

  @override
  String get admin_checkin_validated_success => 'Check-in validado com sucesso';

  @override
  String admin_checkin_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get admin_checkin_reject_title => 'Rejeitar Check-in';

  @override
  String get admin_checkin_reject_message =>
      'Tem certeza de que deseja rejeitar este check-in?';

  @override
  String get admin_checkin_reject_hint => 'Motivo da rejeição (opcional)...';

  @override
  String get admin_checkin_no_reason => 'Sem motivo';

  @override
  String get admin_checkin_rejected_success => 'Check-in rejeitado com sucesso';

  @override
  String get admin_checkin_cancel_message =>
      'Tem certeza de que deseja cancelar esta reserva?';

  @override
  String get admin_checkin_cancel_warning => 'Esta ação não pode ser desfeita.';

  @override
  String get admin_checkin_cancel_reason_label => 'Motivo do cancelamento';

  @override
  String get admin_checkin_cancel_reason_hint =>
      'Descreva o motivo do cancelamento...';

  @override
  String get admin_checkin_cancelled_success => 'Reserva cancelada com sucesso';

  @override
  String get admin_invoice_generate_pdf => 'Gerar PDF';

  @override
  String get admin_invoice_share => 'Compartilhar';

  @override
  String get admin_invoice_download => 'Baixar';

  @override
  String get admin_invoice_share_title => 'Compartilhar Fatura';

  @override
  String get admin_invoice_copy_link => 'Copiar link';

  @override
  String admin_invoice_pdf_saved(String path) {
    return 'PDF salvo com sucesso';
  }

  @override
  String get admin_invoice_issue => 'Emitir';

  @override
  String get admin_invoice_mark_paid => 'Marcar como paga';

  @override
  String admin_invoice_paid_on(String date) {
    return 'Paga em $date';
  }

  @override
  String admin_invoice_cancelled(String reason) {
    return 'Cancelada';
  }

  @override
  String get admin_invoice_issue_confirm_title => 'Emitir Fatura';

  @override
  String admin_invoice_issue_confirm_message(String invoiceNumber) {
    return 'Tem certeza de que deseja emitir esta fatura?';
  }

  @override
  String get admin_invoice_mark_paid_confirm_title => 'Marcar como Paga';

  @override
  String admin_invoice_mark_paid_confirm_message(String total) {
    return 'Confirma que o pagamento desta fatura foi recebido?';
  }

  @override
  String get admin_invoice_confirm_payment => 'Confirmar pagamento';

  @override
  String get admin_invoice_cancel_confirm_title => 'Cancelar Fatura';

  @override
  String get admin_invoice_cancel_reason_label => 'Motivo do cancelamento';

  @override
  String get admin_invoice_cancel_reason_hint =>
      'Descreva o motivo do cancelamento...';

  @override
  String get admin_invoice_dont_cancel => 'Não cancelar';

  @override
  String get admin_invoice_cancel_invoice => 'Cancelar fatura';

  @override
  String admin_invoice_error_generate_pdf(String error) {
    return 'Erro ao gerar PDF';
  }

  @override
  String admin_invoice_error_share(String error) {
    return 'Erro ao compartilhar';
  }

  @override
  String admin_invoice_error_download(String error) {
    return 'Erro ao baixar';
  }

  @override
  String get admin_invoice_nif_label => 'NIF/CIF:';

  @override
  String get admin_invoice_label => 'Fatura';

  @override
  String get admin_invoice_bill_to => 'Faturar para';

  @override
  String get admin_invoice_issue_date_label => 'Data de emissão:';

  @override
  String get admin_invoice_due_date_label => 'Data de vencimento:';

  @override
  String get admin_invoice_period_label => 'Período';

  @override
  String get admin_invoice_booking_label => 'Reserva';

  @override
  String get admin_invoice_no_line_items => 'Sem conceitos';

  @override
  String get admin_invoice_col_description => 'Descrição';

  @override
  String get admin_invoice_col_qty => 'Qtd';

  @override
  String get admin_invoice_col_price => 'Preço';

  @override
  String get admin_invoice_col_total => 'Total';

  @override
  String get admin_invoice_tax_base => 'Base imponível';

  @override
  String get admin_invoice_tax_label => 'IVA';

  @override
  String get admin_invoice_total_label => 'Total';

  @override
  String get admin_invoice_notes_label => 'Notas';

  @override
  String get admin_notifications_title => 'Notificações';

  @override
  String get admin_notifications_empty_title => 'Sem notificações';

  @override
  String get admin_notifications_empty_subtitle =>
      'As notificações aparecerão aqui';

  @override
  String get admin_notifications_mark_all_read => 'Marcar tudo como lido';

  @override
  String get admin_notifications_mark_read => 'Marcar como lido';

  @override
  String get admin_notifications_delete_all => 'Eliminar tudo';

  @override
  String get admin_notifications_delete_all_title =>
      'Eliminar todas as notificações';

  @override
  String get admin_notifications_delete_all_confirm =>
      'Tem certeza de que deseja eliminar todas as notificações?';

  @override
  String admin_notifications_unread_count(int count) {
    return '$count não lidos';
  }

  @override
  String get guest_access_checkin => 'Check-in';

  @override
  String get guest_access_checkout => 'Check-out';

  @override
  String get guest_access_checkout_label => 'Saída';

  @override
  String guest_access_checkout_until(String time) {
    return 'Até às $time';
  }

  @override
  String get guest_access_checkout_deadline => 'Hora limite de saída';

  @override
  String get guest_access_checkout_instructions => 'Instruções de saída';

  @override
  String get guest_access_code_label => 'Código';

  @override
  String guest_access_code_available_at(String date, String time) {
    return 'Disponível em $date às $time';
  }

  @override
  String get guest_access_code_provided_by_staff => 'Fornecido pelo pessoal';

  @override
  String get guest_access_locker_code => 'Código do cacifo';

  @override
  String get guest_access_locker_code_label => 'Código cacifo';

  @override
  String guest_access_locker_available_at(String date) {
    return 'Disponível em $date';
  }

  @override
  String get guest_access_key_locker => 'Cacifo de chaves';

  @override
  String get guest_access_door_code => 'Código da porta';

  @override
  String get guest_access_building_access => 'Acesso ao edifício';

  @override
  String get guest_access_building_instructions =>
      'Instruções de acesso ao edifício';

  @override
  String get guest_access_apartment_access => 'Acesso ao apartamento';

  @override
  String get guest_access_apartment_instructions =>
      'Instruções de acesso ao apartamento';

  @override
  String get guest_access_location => 'Localização';

  @override
  String get guest_access_contact => 'Contacto';

  @override
  String get guest_access_contact_description =>
      'Contacte-nos se precisar de ajuda';

  @override
  String guest_access_copied(String label) {
    return '$label copiado para a área de transferência';
  }

  @override
  String get guest_access_open_maps => 'Abrir no Maps';

  @override
  String get guest_access_network => 'Rede';

  @override
  String get guest_access_network_name => 'Nome da rede';

  @override
  String get guest_access_password => 'Palavra-passe';

  @override
  String get guest_access_company_name => 'BF Stay';

  @override
  String get guest_access_house_rules => 'Normas da casa';

  @override
  String get guest_access_rules_warning =>
      'Por favor, leia as normas da casa antes da sua chegada';

  @override
  String get guest_access_your_accommodation => 'O seu alojamento';

  @override
  String get guest_access_your_codes => 'Os seus códigos';

  @override
  String get guest_access_guest => 'Hóspede';

  @override
  String guest_access_welcome_message(String unitName) {
    return 'Bem-vindo a $unitName';
  }

  @override
  String guest_access_hello(String name) {
    return 'Olá $name';
  }

  @override
  String guest_access_codes_available_datetime(String date, String time) {
    return 'Disponível em $date às $time';
  }

  @override
  String guest_access_codes_available_message(String time) {
    return 'O seu código estará disponível a partir das $time';
  }

  @override
  String get guest_access_loading_instructions => 'A carregar instruções...';

  @override
  String get guest_access_cannot_load_instructions =>
      'Não é possível carregar as instruções';

  @override
  String get guest_access_rule_no_parties_title => 'Sem festas';

  @override
  String get guest_access_rule_no_parties_description =>
      'Não são permitidas festas nem eventos';

  @override
  String get guest_access_rule_no_smoking_title => 'Sem fumo';

  @override
  String get guest_access_rule_smoke_free_description =>
      'Esta é uma propriedade livre de fumo';

  @override
  String get guest_access_rule_registered_only_title => 'Apenas registados';

  @override
  String get guest_access_rule_registered_only_description =>
      'Apenas os hóspedes registados podem aceder';

  @override
  String get guest_accommodation_title => 'Alojamento';

  @override
  String get guest_accommodation_error_loading => 'Erro ao carregar';

  @override
  String get guest_accommodation_error_occurred => 'Ocorreu um erro';

  @override
  String get guest_accommodation_no_booking => 'Não foi encontrada a reserva';

  @override
  String get guest_accommodation_booking_not_found => 'Reserva não encontrada';

  @override
  String get guest_accommodation_no_unit_info => 'Não há informação da unidade';

  @override
  String get guest_accommodation_address => 'Endereço';

  @override
  String get guest_accommodation_address_unavailable =>
      'Endereço não disponível';

  @override
  String get guest_accommodation_box_location => 'Localização da caixa';

  @override
  String get guest_accommodation_access_codes => 'Códigos de acesso';

  @override
  String get guest_accommodation_access_instructions => 'Instruções de acesso';

  @override
  String get guest_accommodation_main_door => 'Porta principal';

  @override
  String get guest_accommodation_door_code => 'Código da porta';

  @override
  String get guest_accommodation_portal_code => 'Código do portal';

  @override
  String get guest_accommodation_key_box_code => 'Código da caixa de chaves';

  @override
  String get guest_accommodation_keybox_description =>
      'Código para a caixa de chaves';

  @override
  String get guest_accommodation_wifi_password => 'Palavra-passe WiFi';

  @override
  String guest_accommodation_rooms_count(int count) {
    return '$count quartos';
  }

  @override
  String get guest_accommodation_hotel_rules => 'Normas do hotel';

  @override
  String get guest_accommodation_apartment_rules => 'Normas do apartamento';

  @override
  String get guest_accommodation_rules_description =>
      'Consulte as normas do seu alojamento';

  @override
  String guest_accommodation_rules_load_error(String error) {
    return 'Erro ao carregar as normas: $error';
  }

  @override
  String guest_accommodation_codes_available_datetime(
    String date,
    String time,
  ) {
    return 'Disponível em $date às $time';
  }

  @override
  String guest_accommodation_codes_available_message(String time) {
    return 'Os seus códigos estarão disponíveis quando começar a sua estadia ($time)';
  }

  @override
  String guest_accommodation_file_not_found(String message) {
    return 'Ficheiro não encontrado: $message';
  }

  @override
  String get guest_accommodation_cannot_open_document =>
      'Não é possível abrir o documento';

  @override
  String get guest_accommodation_tap_for_access_info =>
      'Toque para ver informação de acesso';

  @override
  String get guest_chat_default_title => 'Chat';

  @override
  String get guest_chat_online => 'Em linha';

  @override
  String get guest_chat_start_conversation => 'Iniciar conversa';

  @override
  String get guest_chat_welcome_message => 'Olá! Em que podemos ajudá-lo?';

  @override
  String get guest_checkin_label => 'Check-in';

  @override
  String get guest_checkin_back => 'Voltar';

  @override
  String get guest_checkin_continue => 'Continuar';

  @override
  String get guest_checkin_complete => 'Completar';

  @override
  String get guest_checkin_loading_booking => 'A carregar dados da reserva...';

  @override
  String get guest_checkin_error_loading => 'Erro ao carregar';

  @override
  String get guest_checkin_booking => 'Reserva';

  @override
  String get guest_checkin_code => 'Código';

  @override
  String get guest_checkin_guests_label => 'Hóspedes';

  @override
  String guest_checkin_guests_count(int count) {
    return '$count hóspedes';
  }

  @override
  String guest_checkin_guests_registered(int count) {
    return '$count registados';
  }

  @override
  String guest_checkin_guests_summary(int count) {
    return '$count hóspedes';
  }

  @override
  String get guest_checkin_guest_data => 'Dados do hóspede';

  @override
  String get guest_checkin_guest_data_description =>
      'Complete os dados de todos os hóspedes';

  @override
  String get guest_checkin_holder_badge => 'TITULAR';

  @override
  String get guest_checkin_holder_signature => 'Assinatura do titular';

  @override
  String get guest_checkin_no_name => 'Sem nome';

  @override
  String get guest_checkin_guest_no_name => 'Hóspede sem nome';

  @override
  String guest_checkin_adults_children(int adults, int children) {
    return '$adults adultos e $children menores';
  }

  @override
  String get guest_checkin_minor_badge => 'MENOR';

  @override
  String guest_checkin_young_document_required(int age) {
    return 'Menor de $age anos, documento requerido';
  }

  @override
  String get guest_checkin_document_required => 'Documento requerido';

  @override
  String get guest_checkin_upload => 'Carregar';

  @override
  String guest_checkin_documents_uploaded(int completed, int total) {
    return '$completed de $total documentos carregados';
  }

  @override
  String get guest_checkin_all_documents_uploaded =>
      'Todos os documentos carregados';

  @override
  String get guest_checkin_upload_documents_description =>
      'Carregue as fotos dos documentos de identidade de todos os hóspedes';

  @override
  String get guest_checkin_uploaded_documents => 'Documentos carregados';

  @override
  String get guest_checkin_pending_documents => 'Documentos pendentes';

  @override
  String get guest_checkin_identity_documents => 'Documentos de identidade';

  @override
  String get guest_checkin_signature_description =>
      'Assinatura do titular da reserva';

  @override
  String get guest_checkin_signature_pending => 'Assinatura pendente';

  @override
  String get guest_checkin_signature_captured => 'Assinatura capturada';

  @override
  String get guest_checkin_signature_captured_short => 'Assinatura';

  @override
  String get guest_checkin_clear_signature => 'Apagar assinatura';

  @override
  String get guest_checkin_step_guests => 'Hóspedes';

  @override
  String get guest_checkin_step_documents => 'Documentos';

  @override
  String get guest_checkin_step_signature => 'Assinatura';

  @override
  String get guest_checkin_step_confirm => 'Confirmar';

  @override
  String get guest_checkin_online => 'Em linha';

  @override
  String get guest_checkin_pending => 'Pendente';

  @override
  String get guest_checkin_validated => 'Validado';

  @override
  String get guest_checkin_waiting_validation => 'À espera de validação';

  @override
  String get guest_checkin_completed => 'Concluído';

  @override
  String get guest_checkin_completed_success =>
      'Check-in concluído corretamente';

  @override
  String get guest_checkin_sending => 'A enviar...';

  @override
  String get guest_checkin_progress => 'Progresso do check-in';

  @override
  String get guest_checkin_confirmation => 'Confirmação de Check-in';

  @override
  String get guest_checkin_confirmation_description =>
      'O seu check-in foi enviado. Agora é necessário aguardar que o alojamento o valide.';

  @override
  String get guest_checkin_legal_notice => 'Aviso legal';

  @override
  String get guest_checkout_title => 'Check-out';

  @override
  String get guest_checkout_label => 'Saída';

  @override
  String get guest_checkout_checkin_label => 'Entrada';

  @override
  String get guest_checkout_checkout_label => 'Saída';

  @override
  String guest_checkout_nights_count(int count) {
    return '$count noites';
  }

  @override
  String guest_checkout_guests_count(int count) {
    return '$count hóspedes';
  }

  @override
  String get guest_checkout_stay_summary => 'Resumo da estadia';

  @override
  String get guest_checkout_confirm => 'Confirmar';

  @override
  String get guest_checkout_confirm_button => 'Confirmar saída';

  @override
  String get guest_checkout_confirm_dialog_title => 'Confirmar saída?';

  @override
  String get guest_checkout_confirm_dialog_message =>
      'Vai confirmar a sua saída. Deseja continuar?';

  @override
  String get guest_checkout_confirm_info => 'A confirmar saída...';

  @override
  String get guest_checkout_processing => 'A processar...';

  @override
  String get guest_checkout_completed => 'Check-out concluído';

  @override
  String get guest_checkout_thank_you => 'Obrigado pela sua estadia!';

  @override
  String get guest_checkout_feedback_title => 'A sua opinião importa-nos';

  @override
  String get guest_checkout_feedback_hint =>
      'Conte-nos como foi a sua experiência...';

  @override
  String get guest_checkout_rating_title => 'Avalie a sua estadia';

  @override
  String get guest_checkout_review_description =>
      'A sua opinião ajuda outros viajantes';

  @override
  String get guest_checkout_loading => 'A carregar...';

  @override
  String get guest_checkout_error_loading => 'Erro ao carregar';

  @override
  String get guest_checkout_already_done => 'Check-out já realizado';

  @override
  String get guest_checkout_already_done_message =>
      'Já realizou o check-out. Obrigado!';

  @override
  String get guest_home_welcome => 'Bem-vindo';

  @override
  String get guest_home_welcome_stay => 'Bem-vindo à sua estadia';

  @override
  String guest_home_hello_name(String name) {
    return 'Olá, $name';
  }

  @override
  String get guest_home_your_stay => 'A Sua Estadia';

  @override
  String get guest_home_no_booking => 'Não tem reservas';

  @override
  String get guest_home_not_authenticated => 'Não autenticado';

  @override
  String get guest_home_stay_active_enjoy =>
      'A sua estadia está ativa. Desfrute!';

  @override
  String get guest_home_quick_actions => 'Ações rápidas';

  @override
  String get guest_home_checkin => 'Check-in';

  @override
  String get guest_home_checkout => 'Check-out';

  @override
  String get guest_home_chat => 'Chat';

  @override
  String get guest_home_guide => 'Guia';

  @override
  String get guest_home_rules => 'Normas';

  @override
  String get guest_home_parkings => 'Estacionamentos';

  @override
  String get guest_home_accommodations => 'Alojamentos';

  @override
  String get guest_home_accommodation => 'Alojamento';

  @override
  String guest_home_rooms_count(int count) {
    return '$count qts';
  }

  @override
  String get guest_home_guests => 'Hóspedes';

  @override
  String guest_home_nights(int count) {
    return '$count noites';
  }

  @override
  String get guest_home_what_to_see => 'O que visitar';

  @override
  String get guest_home_instructions => 'Instruções';

  @override
  String get guest_home_my_accommodation => 'O meu alojamento';

  @override
  String get guest_home_booking_cancelled => 'Reserva cancelada';

  @override
  String get guest_home_booking_cancelled_message =>
      'A sua reserva foi cancelada. Contacte a receção.';

  @override
  String get guest_home_cancellation_reason => 'Motivo de cancelamento';

  @override
  String get guest_home_checkin_pending => 'Check-in pendente';

  @override
  String get guest_home_checkin_sent_waiting =>
      'Check-in enviado, à espera de validação';

  @override
  String get guest_home_checkin_rejected => 'Check-in rejeitado';

  @override
  String get guest_home_rejection_reason => 'Motivo da rejeição';

  @override
  String get guest_home_pending_validation => 'Pendente de validação';

  @override
  String get guest_home_complete_checkin_access =>
      'Complete o check-in para aceder';

  @override
  String get guest_home_contact_reception => 'Contacte a receção';

  @override
  String get guest_home_correct_errors_resend => 'Corrija os erros e reenvie';

  @override
  String get guest_home_physical_registration => 'Registo presencial';

  @override
  String get guest_home_romantic_pack => 'Pack Romântico';

  @override
  String guest_jacuzzi_note(String note) {
    return 'Nota: $note';
  }

  @override
  String get public_services_title => 'Os Nossos Serviços';

  @override
  String get public_service_rules_title => 'Normas da Casa';

  @override
  String get public_service_rules_desc => 'Regras e recomendações.';

  @override
  String public_copyright(int year) {
    return '© $year BF Stay • Todos os direitos reservados';
  }

  @override
  String get public_access_booking => 'Aceder à minha Reserva';

  @override
  String staff_dashboard_greeting(String name) {
    return 'Olá $name';
  }

  @override
  String get staff_dashboard_control_panel => 'Painel de Controlo';

  @override
  String get staff_dashboard_daily_summary => 'Resumo do dia';

  @override
  String get staff_dashboard_occupancy => 'Ocupação';

  @override
  String get staff_dashboard_pending => 'Pendentes';

  @override
  String get staff_dashboard_pending_checkin => 'Check-ins pendentes';

  @override
  String get staff_dashboard_pending_checkout => 'Check-outs pendentes';

  @override
  String get staff_dashboard_pending_tasks => 'Tarefas pendentes';

  @override
  String get staff_dashboard_checkins_today => 'Check-ins hoje';

  @override
  String get staff_dashboard_checkouts_today => 'Check-outs hoje';

  @override
  String get staff_dashboard_quick_actions => 'Ações rápidas';

  @override
  String get staff_dashboard_manage_checkins => 'Gerir check-ins';

  @override
  String get staff_dashboard_view_guests => 'Ver hóspedes';

  @override
  String staff_dashboard_room_extras(String room) {
    return 'Quarto $room - Extras';
  }

  @override
  String get staff_dashboard_cleaning_request => 'Pedido de limpeza';

  @override
  String staff_dashboard_room_guest(String room, String guest) {
    return 'Quarto $room - $guest';
  }

  @override
  String get staff_dashboard_generate_report => 'Gerar relatório';

  @override
  String get staff_checkins_title => 'Check-ins';

  @override
  String get staff_checkins_tab_pending => 'Pendentes';

  @override
  String get staff_checkins_tab_in_progress => 'Em progresso';

  @override
  String get staff_checkins_tab_completed => 'Concluídos';

  @override
  String get staff_checkins_status_pending => 'Pendente';

  @override
  String get staff_checkins_status_in_progress => 'Em progresso';

  @override
  String get staff_checkins_status_completed => 'Concluído';

  @override
  String get staff_checkins_start => 'Iniciar';

  @override
  String get staff_checkins_new_checkin => 'Novo check-in';

  @override
  String get staff_checkins_complete => 'Completar';

  @override
  String get staff_checkins_view_details => 'Ver detalhes';

  @override
  String get guest_access_wifi_password_label => 'Palavra-passe WiFi';

  @override
  String get guest_access_locker_provided_by_staff => 'Fornecido pelo pessoal';

  @override
  String get guest_access_rule_smoke_free_title => 'Sem fumo';

  @override
  String get guest_accommodation_view_rules_pdf => 'Ver normas em PDF';

  @override
  String get public_hero_title_line1 => 'A Sua Estadia,';

  @override
  String get public_hero_title_line2 => 'Elevada';

  @override
  String get admin_booking_send_whatsapp_title => 'Enviar código por WhatsApp';

  @override
  String get admin_booking_send_whatsapp_no_phone =>
      'O hóspede não tem número de telefone';

  @override
  String get admin_booking_send_whatsapp_no_phone_desc =>
      'Introduza um número de telefone para enviar o código por WhatsApp.';

  @override
  String get admin_booking_send_whatsapp_phone_hint => '+351 920 000 000';

  @override
  String get admin_booking_send_whatsapp_error =>
      'Não foi possível abrir o WhatsApp';

  @override
  String admin_booking_send_whatsapp_message(
    String propertyName,
    String bookingCode,
    String checkIn,
    String checkOut,
  ) {
    return '🏠 *$propertyName*\n📋 Reserva: *$bookingCode*\n📅 Check-in: $checkIn\n📅 Check-out: $checkOut\n\nDescarregue a app BF Stay para gerir a sua estadia.';
  }
}
