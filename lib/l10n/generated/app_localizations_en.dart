// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get guest_romantic_request_sent =>
      'We\'ve notified the property. They\'ll contact you to confirm the details.';

  @override
  String get guest_romantic_request_error =>
      'We couldn\'t register your request. Please try again.';

  @override
  String get common_app_name => 'BF Stay';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_exit => 'Exit';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_close => 'Close';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_accept => 'Accept';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_back => 'Back';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get common_no_data => 'No data';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_send => 'Send';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_search => 'Search';

  @override
  String get common_later => 'Later';

  @override
  String get common_update => 'Update';

  @override
  String get common_understood => 'Understood';

  @override
  String get common_exit_app_title => 'Exit BF Stay';

  @override
  String get common_exit_app_message =>
      'Are you sure you want to exit the app?\n\nYour session will remain active when you come back.';

  @override
  String get common_logout_title => 'Sign Out';

  @override
  String get common_logout_message =>
      'Are you sure you want to sign out?\n\nYou can log back in with your booking code whenever you need to.';

  @override
  String get common_logout_button => 'Sign Out';

  @override
  String get common_splash_ready => 'Ready';

  @override
  String get common_splash_loading => 'Loading...';

  @override
  String get common_update_force_title => 'Update Required';

  @override
  String get common_update_available_title => 'New Version Available';

  @override
  String get common_update_force_message =>
      'You need to update the app to continue using it. This version includes important improvements and security fixes.';

  @override
  String get common_update_available_message =>
      'A new version is available with improvements and fixes. Would you like to update now?';

  @override
  String common_update_version(String version) {
    return 'Version $version';
  }

  @override
  String get common_page_not_found => 'Page not found';

  @override
  String get common_invalid_route => 'Invalid route';

  @override
  String get common_back_to_home => 'Back to home';

  @override
  String get common_theme_light => 'Light';

  @override
  String get common_theme_dark => 'Dark';

  @override
  String get common_theme_mode_light => 'Light Mode';

  @override
  String get common_theme_mode_dark => 'Dark Mode';

  @override
  String get common_theme_system => 'System';

  @override
  String get common_theme_app_label => 'App theme';

  @override
  String common_copied_to_clipboard(String type) {
    return '$type copied to clipboard';
  }

  @override
  String get common_phone_type => 'Phone';

  @override
  String get common_email_type => 'Email';

  @override
  String get enum_booking_status_created => 'Created';

  @override
  String get enum_booking_status_confirmed => 'Confirmed';

  @override
  String get enum_booking_status_active => 'Active';

  @override
  String get enum_booking_status_in_house => 'In House';

  @override
  String get enum_booking_status_checked_out => 'Checked Out';

  @override
  String get enum_booking_status_closed => 'Closed';

  @override
  String get enum_booking_status_cancelled => 'Cancelled';

  @override
  String get enum_booking_status_created_desc =>
      'Booking created, pending confirmation';

  @override
  String get enum_booking_status_confirmed_desc =>
      'Booking confirmed, pending check-in';

  @override
  String get enum_booking_status_active_desc =>
      'Check-in validated, full panel accessible';

  @override
  String get enum_booking_status_in_house_desc =>
      'Guest physically at the property';

  @override
  String get enum_booking_status_checked_in_legacy_desc =>
      'Check-in validated (legacy)';

  @override
  String get enum_booking_status_checked_out_desc =>
      'Check-out completed, guest has left';

  @override
  String get enum_booking_status_closed_desc => 'Booking finished and closed';

  @override
  String get enum_booking_status_cancelled_desc => 'Booking cancelled';

  @override
  String get enum_checkin_status_not_started => 'Pending';

  @override
  String get enum_checkin_status_in_progress => 'In Progress';

  @override
  String get enum_checkin_status_submitted => 'Submitted';

  @override
  String get enum_checkin_status_validated => 'Validated';

  @override
  String get enum_checkin_status_rejected => 'Rejected';

  @override
  String get enum_checkin_status_cancelled => 'Cancelled';

  @override
  String get enum_checkin_status_not_started_desc =>
      'The guest has not started check-in yet';

  @override
  String get enum_checkin_status_in_progress_desc =>
      'The guest is filling in their details';

  @override
  String get enum_checkin_status_submitted_desc =>
      'Pending review by the administrator';

  @override
  String get enum_checkin_status_validated_desc =>
      'Check-in validated, stay authorized';

  @override
  String get enum_checkin_status_rejected_desc =>
      'Requires correction by the guest';

  @override
  String get enum_checkin_status_cancelled_desc =>
      'Booking cancelled, please contact reception';

  @override
  String get enum_checkout_status_not_started => 'Not Started';

  @override
  String get enum_checkout_status_requested => 'Requested';

  @override
  String get enum_checkout_status_validated => 'Validated';

  @override
  String get enum_checkout_status_rejected => 'Rejected';

  @override
  String get enum_checkout_status_not_started_desc =>
      'The stay is still in progress';

  @override
  String get enum_checkout_status_requested_desc =>
      'The guest has requested check-out';

  @override
  String get enum_checkout_status_validated_desc =>
      'Check-out validated, booking ready to close';

  @override
  String get enum_checkout_status_rejected_desc =>
      'There are issues to resolve';

  @override
  String get public_badge_exclusivity => 'GUARANTEED EXCLUSIVITY';

  @override
  String get public_hero_title_prefix => 'Your Stay, ';

  @override
  String get public_hero_title_suffix => 'Elevated';

  @override
  String get public_cta_access_booking => 'Access My Booking';

  @override
  String get public_services_section_title => 'Our Services';

  @override
  String get public_footer_brand_name => 'BF STAY';

  @override
  String public_footer_copyright(int year) {
    return '© $year BF Stay • All rights reserved';
  }

  @override
  String get public_footer_privacy_policy => 'Privacy Policy';

  @override
  String get public_service_checkin_title => 'Digital Check-in';

  @override
  String get public_service_checkin_desc => 'Check in without waiting.';

  @override
  String get public_service_checkout_title => 'Digital Check-out';

  @override
  String get public_service_checkout_desc => 'Quick and easy departure.';

  @override
  String get public_service_house_rules_title => 'House Rules';

  @override
  String get public_service_house_rules_desc => 'Rules and recommendations.';

  @override
  String get public_service_what_to_see_title => 'What to See';

  @override
  String get public_service_what_to_see_desc => 'Nearby points of interest.';

  @override
  String get public_service_parking_title => 'Parking';

  @override
  String get public_service_parking_desc => 'Parking options.';

  @override
  String get public_service_chat_title => 'Chat';

  @override
  String get public_service_chat_desc => '24/7 virtual concierge.';

  @override
  String get public_service_accommodations_title => 'Accommodations';

  @override
  String get public_service_accommodations_desc => 'Other properties.';

  @override
  String get public_service_reviews_title => 'Reviews';

  @override
  String get public_service_reviews_desc => 'Guest reviews.';

  @override
  String get public_service_parking_title_light => 'Nearby Parking';

  @override
  String get public_service_accommodations_title_light => 'Our Accommodations';

  @override
  String get public_service_accommodations_desc_light =>
      'Other available properties.';

  @override
  String get public_service_reviews_title_light => 'Reviews and Comments';

  @override
  String get public_hero_subtitle =>
      'Smart management for exclusive accommodations.';

  @override
  String get auth_login_brand_name => 'BF Stay';

  @override
  String get auth_login_subtitle => 'Control Panel';

  @override
  String get auth_feature_bookings => 'Booking management';

  @override
  String get auth_feature_checkin => 'Digital check-in';

  @override
  String get auth_feature_chat => 'Guest chat';

  @override
  String get auth_feature_keyless => 'Keyless access';

  @override
  String get auth_field_email => 'Email';

  @override
  String get auth_field_password => 'Password';

  @override
  String get auth_validation_email_required => 'Please enter your email';

  @override
  String get auth_validation_email_invalid => 'Please enter a valid email';

  @override
  String get auth_validation_password_required => 'Please enter your password';

  @override
  String get auth_validation_password_min_length =>
      'Password must be at least 6 characters';

  @override
  String get auth_forgot_password => 'Forgot your password?';

  @override
  String get auth_login_button => 'Sign In';

  @override
  String get auth_divider_or => 'or';

  @override
  String get auth_guest_access_button => 'Access with booking code';

  @override
  String get auth_login_footer => 'BF Stay © 2026';

  @override
  String get auth_recover_password_title => 'Recover Password';

  @override
  String get auth_recover_password_body =>
      'Enter your email and we will send you instructions to reset your password.';

  @override
  String get auth_recover_password_sent => 'Recovery email sent';

  @override
  String get auth_button_send => 'Send';

  @override
  String get auth_booking_access_title => 'Guest Access';

  @override
  String get auth_booking_benefit_code => 'Booking code';

  @override
  String get auth_booking_benefit_personal => 'Personalized access';

  @override
  String get auth_booking_benefit_instant => 'Instant access';

  @override
  String get auth_booking_benefit_secure_checkin => 'Secure check-in';

  @override
  String get auth_booking_code_info_short =>
      'You received your booking code in the confirmation email.';

  @override
  String get auth_booking_code_info_full =>
      'You received your booking code in your booking confirmation email.';

  @override
  String get auth_booking_desktop_subtitle =>
      'Enjoy your stay with digital access';

  @override
  String get auth_booking_form_subtitle =>
      'Enter your booking code to access your accommodation';

  @override
  String get auth_booking_field_code => 'Booking Code';

  @override
  String get auth_booking_code_hint => 'XX-XXXX-XXXX';

  @override
  String get auth_booking_validation_code_required =>
      'Please enter your booking code';

  @override
  String get auth_booking_validation_code_invalid =>
      'The code format is not valid';

  @override
  String get auth_booking_access_button => 'Access';

  @override
  String get auth_booking_help_title => 'Where do I find my code?';

  @override
  String get auth_booking_help_body =>
      'You received your booking code in the booking confirmation email. It has the format BF-XXXXX.';

  @override
  String get auth_booking_footer => 'BF Stay © 2026';

  @override
  String get auth_booking_error_title => 'Access Error';

  @override
  String get auth_booking_error_code_not_found =>
      'The booking code does not exist. Please check that you have entered it correctly.';

  @override
  String get auth_booking_error_code_expired =>
      'This booking code has expired. Contact reception to get a new one.';

  @override
  String get auth_booking_error_email_mismatch =>
      'The email does not match the booking. Please make sure it is the same email you used when booking.';

  @override
  String get auth_booking_error_generic =>
      'Could not verify the booking code. Please try again.';

  @override
  String get auth_booking_error_dismiss => 'Understood';

  @override
  String get auth_sheet_title => 'Access your booking';

  @override
  String get auth_sheet_subtitle =>
      'Enter your email and the code you received';

  @override
  String get auth_sheet_label_email => 'EMAIL';

  @override
  String get auth_sheet_hint_email => 'you@email.com';

  @override
  String get auth_sheet_label_code => 'BOOKING CODE';

  @override
  String get auth_sheet_hint_code => 'BF-XXXX-XXXX';

  @override
  String get auth_sheet_submit_button => 'Access my booking';

  @override
  String get auth_sheet_help_text =>
      'Don\'t have your code? Contact your accommodation';

  @override
  String get auth_admin_sheet_title => 'Private access';

  @override
  String get auth_admin_sheet_subtitle => 'BF-Stay authorized staff only';

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
      'You do not have access to this panel';

  @override
  String get auth_admin_submit_button => 'Access panel';

  @override
  String get guest_settings_title => 'Settings';

  @override
  String get guest_settings_section_language => 'Language';

  @override
  String get guest_settings_language_title => 'App language';

  @override
  String get guest_settings_language_subtitle =>
      'Select the interface language';

  @override
  String get guest_settings_section_legal => 'Legal';

  @override
  String get guest_settings_privacy_policy_title => 'Privacy Policy';

  @override
  String get guest_settings_privacy_policy_subtitle =>
      'View our privacy policy';

  @override
  String get guest_settings_privacy_open_error =>
      'Could not open the privacy policy';

  @override
  String get notification_channel_name => 'BF Stay Notifications';

  @override
  String get notification_channel_description => 'BF Stay notification channel';

  @override
  String get notification_checkin_validated_title => '✅ Check-in Validated';

  @override
  String get notification_checkin_validated_body =>
      'Your check-in has been successfully validated. Welcome!';

  @override
  String get notification_checkin_rejected_title => '❌ Check-in Rejected';

  @override
  String get notification_checkin_rejected_body =>
      'Your check-in has been rejected. Please review your documentation.';

  @override
  String notification_checkin_rejected_body_with_reason(String reason) {
    return 'Your check-in has been rejected: $reason';
  }

  @override
  String get notification_booking_cancelled_title => '🚫 Booking Cancelled';

  @override
  String get notification_booking_cancelled_body =>
      'Your booking has been cancelled. Contact reception.';

  @override
  String notification_booking_cancelled_body_with_reason(String reason) {
    return 'Your booking has been cancelled: $reason';
  }

  @override
  String get notification_checkin_status_update_title => '📋 Check-in Update';

  @override
  String notification_checkin_status_update_body(String status) {
    return 'Your check-in status has changed to: $status';
  }

  @override
  String get notification_admin_checkin_submitted_title =>
      '📝 New Pending Check-in';

  @override
  String notification_admin_checkin_submitted_body(
    String guestName,
    String unitName,
  ) {
    return '$guestName has submitted their check-in for $unitName. Pending review.';
  }

  @override
  String get guest_parking_title => 'Parking';

  @override
  String get guest_parking_available_singular => 'parking available';

  @override
  String get guest_parking_available_plural => 'parkings available';

  @override
  String get guest_parking_error_loading => 'Error loading';

  @override
  String get guest_parking_empty_title => 'No parkings';

  @override
  String get guest_parking_empty_subtitle =>
      'We will soon add information about nearby parking';

  @override
  String guest_parking_for_unit(String unitName) {
    return 'Parking for $unitName';
  }

  @override
  String guest_parking_gps_label(String label) {
    return 'GPS: $label';
  }

  @override
  String get guest_parking_info_zones_title => 'PARKING ZONES INFORMATION';

  @override
  String get guest_parking_plaza_arenal_title => 'PLAZA ARENAL PARKING';

  @override
  String get guest_parking_plaza_arenal_subtitle => 'About a 5-minute walk';

  @override
  String get guest_parking_plaza_arenal_content =>
      '• Paying via El Parking app: 6,95€/24h\n• Booking through their website: 8€/24h (minimum 24h)\n• Paying ticket at the machine: 16€/24h';

  @override
  String get guest_parking_centro_title => 'CITY CENTRE PARKING';

  @override
  String get guest_parking_centro_subtitle => 'O.R.A BLUE ZONE';

  @override
  String get guest_parking_centro_content =>
      '• Monday to Friday: 9:00 - 13:30 and 17:00 - 20:00\n• Saturday: 9:00 - 14:00\n• July and August: 9:00 - 14:00';

  @override
  String get guest_parking_free_zone_title => 'FREE PARKING ZONE';

  @override
  String get guest_parking_free_zone_subtitle => 'About a 10-minute walk';

  @override
  String get guest_parking_free_zone_content => 'Free rotating parking area.';

  @override
  String get guest_checkin_camera_not_available => 'No cameras available';

  @override
  String guest_checkin_camera_init_error(String error) {
    return 'Error initializing camera: $error';
  }

  @override
  String guest_checkin_camera_capture_error(String error) {
    return 'Capture error: $error';
  }

  @override
  String get guest_checkin_camera_scan_title => 'Scan Document';

  @override
  String get guest_checkin_camera_starting => 'Starting camera...';

  @override
  String get guest_checkin_camera_frame_hint =>
      'Frame the document inside the box';

  @override
  String get guest_checkin_camera_document_label => 'Identity Document';

  @override
  String get admin_chat_messages => 'Messages';

  @override
  String get admin_chat_conversation_deleted => 'Conversation deleted';

  @override
  String get admin_chat_empty_title => 'No conversations';

  @override
  String get admin_chat_empty_subtitle =>
      'Conversations with guests\nwill appear here';

  @override
  String get guest_chat_input_hint => 'Type a message...';

  @override
  String get admin_booking_detail_title => 'Booking Detail';

  @override
  String get admin_booking_not_found => 'Booking not found';

  @override
  String admin_booking_error(String error) {
    return 'Error: $error';
  }

  @override
  String admin_booking_error_validating(String error) {
    return 'Error validating: $error';
  }

  @override
  String admin_booking_error_rejecting(String error) {
    return 'Error rejecting: $error';
  }

  @override
  String admin_booking_error_validating_checkout(String error) {
    return 'Error validating check-out: $error';
  }

  @override
  String admin_booking_error_rejecting_checkout(String error) {
    return 'Error rejecting check-out: $error';
  }

  @override
  String admin_booking_error_closing(String error) {
    return 'Error closing booking: $error';
  }

  @override
  String admin_booking_error_cancelling(String error) {
    return 'Error cancelling booking: $error';
  }

  @override
  String admin_booking_error_deleting(String error) {
    return 'Error deleting booking: $error';
  }

  @override
  String admin_booking_error_updating(String error) {
    return 'Error updating: $error';
  }

  @override
  String get admin_booking_resend_error => 'Could not resend code';

  @override
  String get admin_booking_notification_sent =>
      'Notification sent successfully';

  @override
  String get admin_booking_notification_error => 'Error sending notification';

  @override
  String get admin_booking_code_resent => 'Code resent successfully';

  @override
  String get admin_booking_checkin_validated =>
      'Check-in validated successfully';

  @override
  String get admin_booking_checkin_rejected => 'Check-in rejected';

  @override
  String get admin_booking_checkout_validated =>
      'Check-out validated successfully';

  @override
  String get admin_booking_checkout_rejected => 'Check-out rejected';

  @override
  String get admin_booking_incidents_detected => 'Incidents detected';

  @override
  String get admin_booking_closed_successfully => 'Booking closed successfully';

  @override
  String get admin_booking_cancelled_successfully =>
      'Booking cancelled successfully';

  @override
  String get admin_booking_deleted_successfully =>
      'Booking deleted successfully';

  @override
  String get admin_booking_keybox_updated => 'Keybox code updated';

  @override
  String get admin_booking_already_closed_title => 'Booking already closed';

  @override
  String get admin_booking_already_closed_message =>
      'This booking is already closed.';

  @override
  String get admin_booking_already_cancelled_title =>
      'Booking already cancelled';

  @override
  String get admin_booking_already_cancelled_message =>
      'This booking is already cancelled.';

  @override
  String get admin_booking_cannot_delete_title => 'Cannot delete';

  @override
  String admin_booking_cannot_delete_message(String status) {
    return 'Cannot delete a booking in $status status.';
  }

  @override
  String get admin_booking_cancel_booking => 'Cancel Booking';

  @override
  String get admin_booking_cancel_booking_confirm =>
      'Are you sure you want to cancel this booking? This action cannot be undone.';

  @override
  String get admin_booking_no_keep => 'No, keep it';

  @override
  String get admin_booking_yes_cancel => 'Yes, cancel';

  @override
  String get admin_booking_delete_booking => 'Delete Booking';

  @override
  String get admin_booking_delete_confirm =>
      'Are you sure you want to completely delete this booking and all its data? This action is irreversible.';

  @override
  String get admin_booking_close_booking => 'Close Booking';

  @override
  String get admin_booking_close_confirm =>
      'Do you want to manually close this booking?';

  @override
  String get admin_booking_close_notes_hint => 'Closing notes (optional)';

  @override
  String get admin_booking_reject_checkout => 'Reject Check-out';

  @override
  String get admin_booking_reject_checkout_desc =>
      'Indicate the incidents detected to reject the check-out.';

  @override
  String get admin_booking_incidents_hint =>
      'Describe the incidents detected...';

  @override
  String get admin_booking_reject => 'Reject';

  @override
  String get admin_booking_reject_checkin => 'Reject Check-in';

  @override
  String get admin_booking_reject_checkin_desc =>
      'Indicate the reason for rejecting the check-in.';

  @override
  String get admin_booking_reject_reason_hint =>
      'Rejection reason (optional)...';

  @override
  String admin_booking_share_code_message(String code) {
    return 'Your access code is: $code';
  }

  @override
  String admin_booking_share_keybox_code(String code) {
    return 'Keybox code: $code';
  }

  @override
  String admin_booking_share_dates(String checkIn, String checkOut) {
    return 'Check-in: $checkIn | Check-out: $checkOut';
  }

  @override
  String get admin_booking_share_download_app => 'Download the app: BF Stay';

  @override
  String get admin_booking_edit_keybox_title => 'Keybox Code';

  @override
  String get admin_booking_edit_keybox_desc => 'Enter the keybox code';

  @override
  String get admin_booking_checkin_done => 'Check-in done';

  @override
  String get admin_booking_checkout_done => 'Check-out done';

  @override
  String get admin_booking_units_label => 'rooms';

  @override
  String get admin_booking_email_sent => 'Email sent';

  @override
  String get admin_booking_email_pending => 'Email pending';

  @override
  String get admin_booking_code_used => 'Code used';

  @override
  String get admin_booking_code_unused => 'Code unused';

  @override
  String get admin_booking_checkin_ok => 'Check-in OK';

  @override
  String get admin_booking_checkin_pending => 'Pending validation';

  @override
  String get admin_booking_checkin_in_progress => 'In progress';

  @override
  String get admin_booking_no_checkin => 'No check-in';

  @override
  String get admin_booking_guest_section => 'GUEST';

  @override
  String get admin_booking_no_name => 'No name';

  @override
  String get admin_booking_reservation_section => 'RESERVATION';

  @override
  String get admin_booking_checkin_label => 'Check-in';

  @override
  String get admin_booking_checkout_label => 'Check-out';

  @override
  String get admin_booking_night_singular => 'night';

  @override
  String get admin_booking_night_plural => 'nights';

  @override
  String get admin_booking_years_label => 'years';

  @override
  String get admin_booking_rooms_section => 'Rooms';

  @override
  String get admin_booking_wifi_label => 'WiFi';

  @override
  String get admin_booking_wifi_network_label => 'Network:';

  @override
  String get admin_booking_wifi_password_label => 'Password:';

  @override
  String get admin_booking_wifi_password_clipboard => 'WiFi Password';

  @override
  String get admin_booking_access_code_label => 'Access Code';

  @override
  String get admin_booking_access_code_clipboard => 'Access Code';

  @override
  String get admin_booking_access_instructions_label => 'Access Instructions';

  @override
  String get admin_booking_access_codes_section => 'ACCESS CODES';

  @override
  String get admin_booking_reservation_code_label => 'Reservation Code';

  @override
  String get admin_booking_share_button => 'Share';

  @override
  String get admin_booking_keybox_not_set => 'Not configured';

  @override
  String get admin_booking_keybox_code_label => 'Keybox Code';

  @override
  String get admin_booking_keybox_code_clipboard => 'Keybox Code';

  @override
  String get admin_booking_checkin_not_started => 'Check-in not started';

  @override
  String get admin_booking_checkin_validated_status => 'Check-in validated';

  @override
  String get admin_booking_checkin_rejected_status => 'Check-in rejected';

  @override
  String get admin_booking_checkin_pending_validation => 'Pending validation';

  @override
  String get admin_booking_checkin_in_progress_status => 'Check-in in progress';

  @override
  String get admin_booking_checkin_section => 'CHECK-IN';

  @override
  String get admin_booking_docs_pending => 'documents pending';

  @override
  String get admin_booking_validate_button => 'Validate';

  @override
  String get admin_booking_reject_button => 'Reject';

  @override
  String get admin_booking_internal_notes_section => 'INTERNAL NOTES';

  @override
  String get admin_booking_closed_status => 'Booking closed';

  @override
  String get admin_booking_checkout_validated_status => 'Check-out validated';

  @override
  String get admin_booking_checkout_incidents_status =>
      'Check-out with incidents';

  @override
  String get admin_booking_checkout_requested_status => 'Check-out requested';

  @override
  String get admin_booking_checkout_pending_status => 'Check-out pending';

  @override
  String get admin_booking_checkout_section => 'CHECK-OUT';

  @override
  String get admin_booking_requested_label => 'Requested:';

  @override
  String get admin_booking_notes_label => 'Notes:';

  @override
  String get admin_booking_incidents_button => 'Incidents';

  @override
  String get admin_booking_close_booking_button => 'Close Booking';

  @override
  String get admin_booking_close_booking_description =>
      'The guest has not requested check-out. You can manually close the booking.';

  @override
  String get admin_booking_signature_section => 'HOLDER SIGNATURE';

  @override
  String get admin_booking_signature_unavailable => 'Signature unavailable';

  @override
  String get admin_booking_actions_section => 'ACTIONS';

  @override
  String get admin_booking_resend_code_title => 'Resend code by email';

  @override
  String get admin_booking_last_sent_label => 'Last sent:';

  @override
  String get admin_booking_na => 'N/A';

  @override
  String get admin_booking_not_sent_yet => 'Not sent yet';

  @override
  String get admin_booking_room_ready_title => 'Room ready';

  @override
  String get admin_booking_room_ready_subtitle =>
      'Notify the guest that the room is ready and they can access';

  @override
  String get admin_booking_cancel_booking_title => 'Cancel booking';

  @override
  String get admin_booking_cancel_booking_subtitle =>
      'Mark the booking as cancelled';

  @override
  String get admin_booking_delete_booking_title => 'Delete booking';

  @override
  String get admin_booking_delete_booking_subtitle =>
      'Completely delete the booking and its data (only if not finalized)';

  @override
  String get admin_dashboard_admin_title => 'BF-Stay Admin';

  @override
  String get admin_dashboard_tab_summary => 'Summary';

  @override
  String get admin_dashboard_tab_bookings => 'Bookings';

  @override
  String get admin_dashboard_tab_checkins => 'Check-ins';

  @override
  String get admin_dashboard_tab_invoices => 'Invoices';

  @override
  String get admin_dashboard_tab_marketing => 'Marketing';

  @override
  String get admin_dashboard_tab_properties => 'Properties';

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
  String get guest_alojamientos_title => 'Our Accommodations';

  @override
  String get guest_alojamientos_error_title => 'Error loading';

  @override
  String get guest_alojamientos_empty_title => 'No accommodations';

  @override
  String get guest_alojamientos_empty_subtitle =>
      'No accommodations available at this time';

  @override
  String guest_alojamientos_room_count(int count) {
    return '$count rooms';
  }

  @override
  String get guest_alojamiento_detail_title => 'Details';

  @override
  String get guest_alojamiento_units_available => 'Available units';

  @override
  String get guest_alojamiento_no_units => 'No units available';

  @override
  String get guest_alojamiento_location => 'Location';

  @override
  String get guest_alojamiento_common_areas => 'Common Areas';

  @override
  String get guest_alojamiento_shared_spaces => 'Shared spaces';

  @override
  String get guest_alojamiento_common_areas_subtitle =>
      'Enjoy the hotel\'s common areas';

  @override
  String get guest_alojamiento_no_photos => 'No photos';

  @override
  String get guest_alojamiento_no_photos_subtitle =>
      'No common area photos found';

  @override
  String guest_alojamiento_photos_count(int count) {
    return '$count photos';
  }

  @override
  String get guest_alojamiento_hotel_rooms_title => 'Hotel Boutique Jerez';

  @override
  String get guest_alojamiento_no_rooms => 'No rooms';

  @override
  String get guest_alojamiento_no_rooms_subtitle =>
      'No rooms available at this time';

  @override
  String get guest_alojamiento_rooms => 'Rooms';

  @override
  String get guest_alojamiento_features => 'Features';

  @override
  String get guest_alojamiento_feature_flexible_checkin => 'Flexible check-in';

  @override
  String get guest_alojamiento_feature_wifi => 'Free WiFi';

  @override
  String get guest_alojamiento_feature_ac => 'Air conditioning';

  @override
  String get guest_alojamiento_description => 'Description';

  @override
  String guest_alojamiento_description_text(String unitType) {
    return 'Discover this fully equipped $unitType to make your stay as comfortable as possible. It has everything you need to enjoy Jerez at your own pace.';
  }

  @override
  String get guest_alojamiento_services => 'Included services';

  @override
  String get guest_alojamiento_service_kitchen => 'Equipped kitchen';

  @override
  String get guest_alojamiento_service_washer => 'Washing machine';

  @override
  String get guest_alojamiento_service_tv => 'Smart TV';

  @override
  String get guest_alojamiento_service_bedding => 'Bedding';

  @override
  String get guest_alojamiento_service_towels => 'Towels';

  @override
  String get guest_alojamiento_service_coffee => 'Coffee maker';

  @override
  String get guest_alojamiento_access_info => 'Access information';

  @override
  String get guest_alojamiento_box_location => 'Box location';

  @override
  String get guest_alojamiento_access_instructions => 'Access instructions';

  @override
  String get guest_house_rules_title => 'House Rules';

  @override
  String get guest_house_rules_subtitle =>
      'Check the rules and recommendations';

  @override
  String get guest_house_rules_empty_title => 'No rules';

  @override
  String get guest_house_rules_empty_subtitle =>
      'This accommodation has no registered rules';

  @override
  String get guest_normas_title => 'Rules';

  @override
  String get guest_normas_hotel_title => 'Hotel Rules';

  @override
  String get guest_normas_apartment_title => 'Apartment Rules';

  @override
  String get guest_normas_not_available => 'No rules available';

  @override
  String get guest_normas_image_error => 'Could not load the image';

  @override
  String get guest_normas_generic_error => 'An error has occurred';

  @override
  String get guest_que_ver_title => 'What to see?';

  @override
  String get guest_que_ver_clear_filters => 'Clear';

  @override
  String guest_que_ver_places_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get guest_que_ver_no_results => 'No results';

  @override
  String get guest_que_ver_no_places => 'No places';

  @override
  String get guest_que_ver_try_filters => 'Try changing the search filters';

  @override
  String get guest_que_ver_coming_soon => 'We will soon add new places';

  @override
  String get guest_que_ver_error_loading => 'Error loading the place';

  @override
  String get guest_que_ver_place_not_found => 'Place not found';

  @override
  String get guest_que_ver_about_place => 'About this place';

  @override
  String get guest_que_ver_address => 'Address';

  @override
  String get guest_que_ver_best_time => 'Best time to visit';

  @override
  String get guest_que_ver_location => 'Location';

  @override
  String get guest_que_ver_practical_info => 'Practical information';

  @override
  String get guest_que_ver_tips => 'Tips';

  @override
  String get guest_que_ver_free_entry => 'Free entry';

  @override
  String get guest_que_ver_how_to_get => 'How to get there';

  @override
  String get guest_que_ver_copy_link => 'Copy link';

  @override
  String get guest_que_ver_official_web => 'Official website';

  @override
  String get guest_que_ver_link_copied => 'Link copied to clipboard';

  @override
  String get guest_reviews_verified => 'Verified';

  @override
  String get guest_reviews_show_less => 'Show less';

  @override
  String get guest_reviews_show_more => 'Show more';

  @override
  String get guest_reviews_empty_title => 'No reviews yet';

  @override
  String get guest_reviews_empty_subtitle =>
      'Be the first to share your experience';

  @override
  String get guest_reviews_write_first => 'Write review';

  @override
  String guest_reviews_filter_empty_title(String filter) {
    return 'No results for $filter';
  }

  @override
  String get guest_reviews_filter_empty_subtitle =>
      'Try selecting another filter';

  @override
  String get guest_reviews_clear_filter => 'Clear filter';

  @override
  String guest_reviews_count_label(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get guest_reviews_no_reviews_title => 'No reviews yet';

  @override
  String get guest_reviews_be_first => 'Be the first';

  @override
  String get guest_access_no_booking => 'Booking not found';

  @override
  String get guest_access_error_loading => 'Error loading access data';

  @override
  String get guest_access_title => 'Access';

  @override
  String get guest_access_no_codes => 'No access codes available';

  @override
  String get guest_access_codes_title => 'Access Codes';

  @override
  String get guest_access_codes_subtitle =>
      'Use these codes to access your accommodation';

  @override
  String get guest_access_main_code => 'Main code';

  @override
  String get guest_access_main_door => 'Main door';

  @override
  String guest_access_valid_period(String from, String until) {
    return 'Valid from $from to $until';
  }

  @override
  String get guest_access_wifi_title => 'WiFi';

  @override
  String get guest_access_wifi_network => 'Network:';

  @override
  String get guest_access_wifi_password => 'Password:';

  @override
  String get guest_access_password_copied => 'Password copied to clipboard';

  @override
  String get guest_access_other_accesses => 'Other accesses';

  @override
  String get guest_access_instructions => 'Access instructions';

  @override
  String get guest_guide_title => 'Stay Guide';

  @override
  String get guest_guide_subtitle => 'All the information about your stay';

  @override
  String get guest_guide_contact => 'Contact';

  @override
  String get guest_guide_phone_1 => 'Phone 1';

  @override
  String get guest_guide_phone_2 => 'Phone 2';

  @override
  String get guest_guide_your_data => 'Your Data';

  @override
  String get guest_guide_accommodation => 'Accommodation';

  @override
  String get guest_guide_property => 'Property';

  @override
  String get guest_guide_checkin => 'Check-in';

  @override
  String get guest_guide_checkout => 'Check-out';

  @override
  String get guest_guide_guests => 'Guests';

  @override
  String get guest_guide_services => 'Services';

  @override
  String get guest_guide_wifi => 'WiFi';

  @override
  String get guest_guide_laundry => 'Laundry';

  @override
  String get guest_guide_laundry_desc => 'Laundry service available';

  @override
  String get guest_guide_jacuzzi => 'Jacuzzi';

  @override
  String get guest_guide_ac => 'Air Conditioning';

  @override
  String get guest_guide_ac_title => 'Air Conditioning';

  @override
  String get guest_guide_ac_desc => 'Climate control in your accommodation';

  @override
  String get guest_guide_tv => 'TV';

  @override
  String get guest_guide_tv_title => 'Television';

  @override
  String get guest_guide_tv_desc => 'Smart TV with channels and apps';

  @override
  String get guest_guide_not_available => 'Not available';

  @override
  String get guest_guide_wifi_desc => 'WiFi connection included';

  @override
  String get guest_guide_house_rules => 'House Rules';

  @override
  String get guest_guide_rule_checkin => 'Check-in from 4:00 PM';

  @override
  String guest_guide_rule_checkout(String time) {
    return 'Check-out before $time';
  }

  @override
  String get guest_guide_rule_no_smoking => 'No smoking';

  @override
  String get guest_guide_rule_no_parties => 'No parties allowed';

  @override
  String get guest_guide_rule_no_pets => 'No pets allowed';

  @override
  String get guest_notifications_title => 'Notifications';

  @override
  String get guest_notifications_delete_all => 'Delete all';

  @override
  String get guest_notifications_delete_all_title => 'Delete all notifications';

  @override
  String get guest_notifications_delete_all_confirm =>
      'Are you sure you want to delete all notifications? This action cannot be undone.';

  @override
  String guest_notifications_unread_count(int count) {
    return '$count unread';
  }

  @override
  String get guest_notifications_mark_all => 'Mark all as read';

  @override
  String get guest_notifications_empty_title => 'No notifications';

  @override
  String get guest_notifications_empty_subtitle =>
      'Notifications about your stay will appear here';

  @override
  String get guest_notifications_read => 'Read';

  @override
  String get guest_romantic_title => 'Romantic Pack';

  @override
  String get guest_romantic_surprise => 'Surprise your partner';

  @override
  String get guest_romantic_unforgettable => 'Create an unforgettable moment';

  @override
  String get guest_romantic_includes => 'What\'s included?';

  @override
  String get guest_romantic_decoration_title => 'Romantic Decoration';

  @override
  String get guest_romantic_decoration_desc =>
      'Rose petals, candles and special room decoration';

  @override
  String get guest_romantic_choose_title => 'Choose your detail';

  @override
  String get guest_romantic_choose_desc =>
      'Bottle of cava or artisan chocolate to accompany the evening';

  @override
  String get guest_romantic_basic_pack => 'Basic Romantic Pack';

  @override
  String get guest_romantic_price => '€20.00';

  @override
  String get guest_romantic_book_now => 'Book Now';

  @override
  String get guest_romantic_customize =>
      'Or customize with extras when booking';

  @override
  String get guest_romantic_redirect =>
      'You will be redirected to the website to complete the Romantic Pack reservation. Continue?';

  @override
  String get guest_romantic_how_to => 'How to book?';

  @override
  String get guest_romantic_step_1 => 'Select the Romantic Pack';

  @override
  String get guest_romantic_step_2 => 'Customize the details';

  @override
  String get guest_romantic_step_3 => 'Complete the reservation online';

  @override
  String get guest_romantic_step_4 => 'Enjoy the surprise';

  @override
  String get guest_romantic_note =>
      'The decoration is prepared during your absence so it comes as a complete surprise.';

  @override
  String get guest_jacuzzi_title => 'Jacuzzi';

  @override
  String get guest_jacuzzi_rules_title => 'Usage Rules';

  @override
  String get guest_jacuzzi_subtitle => 'Relax and enjoy';

  @override
  String get guest_jacuzzi_power => 'Power';

  @override
  String get guest_jacuzzi_power_step_1 =>
      'Pulsa el botón POWER para encender el jacuzzi';

  @override
  String get guest_jacuzzi_power_step_2 => 'Espera a que el panel se ilumine';

  @override
  String get guest_jacuzzi_power_step_3 =>
      'Selecciona la temperatura deseada con los botones + y -';

  @override
  String get guest_jacuzzi_lock => 'Panel Lock';

  @override
  String get guest_jacuzzi_lock_step_1 =>
      'Para evitar activaciones accidentales, puedes bloquear el panel de control';

  @override
  String get guest_jacuzzi_lock_unlock => 'Unlock';

  @override
  String get guest_jacuzzi_lock_unlock_step =>
      'Press and hold the LOCK button for 3 seconds';

  @override
  String get guest_jacuzzi_lock_manual => 'Manual Lock';

  @override
  String get guest_jacuzzi_lock_manual_step =>
      'Press and hold the LOCK button for 3 seconds to activate';

  @override
  String get guest_jacuzzi_ozone => 'Ozone Function';

  @override
  String get guest_jacuzzi_ozone_intro =>
      'The ozone system helps keep the water clean and disinfected automatically.';

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
  String get guest_jacuzzi_massage => 'Massage Functions';

  @override
  String get guest_jacuzzi_air_jets => 'Air Jets';

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
  String get guest_jacuzzi_water_jets => 'Water Jets';

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
  String get guest_jacuzzi_important => 'Important';

  @override
  String get guest_jacuzzi_water_level_info =>
      'The water level must always be above the jets for proper functioning.';

  @override
  String get guest_jacuzzi_low_water_title => 'If the level is low:';

  @override
  String get guest_jacuzzi_low_water_stop => 'Stop the jacuzzi immediately';

  @override
  String get guest_jacuzzi_low_water_icon =>
      'Check the warning icon on the panel';

  @override
  String get guest_jacuzzi_low_water_resume =>
      'Fill with water to cover the jets before resuming.';

  @override
  String get guest_jacuzzi_water_responsibility => 'Responsible Water Use';

  @override
  String get guest_jacuzzi_water_refill_info =>
      'The jacuzzi has a considerable water capacity. Please use it responsibly.';

  @override
  String get guest_jacuzzi_capacity => 'Capacity:';

  @override
  String get guest_jacuzzi_capacity_liters => '800 liters';

  @override
  String get guest_jacuzzi_water_regulation =>
      'Filling and draining the jacuzzi is regulated by local water usage regulations.';

  @override
  String get guest_jacuzzi_thanks =>
      'Thank you for your collaboration in responsible water use.';

  @override
  String get guest_physical_registration_title => 'Physical Registration';

  @override
  String get guest_physical_registration_header => 'Registration at Reception';

  @override
  String get guest_physical_registration_subtitle =>
      'Complete your registration in person';

  @override
  String get guest_physical_registration_instructions => 'Instructions';

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
  String get guest_physical_registration_schedule => 'Reception Hours';

  @override
  String get guest_physical_registration_schedule_hours => 'Business hours';

  @override
  String get guest_physical_registration_schedule_days => 'Monday to Friday';

  @override
  String get guest_physical_registration_documents => 'Accepted Documents';

  @override
  String get guest_physical_registration_doc_dni => 'DNI';

  @override
  String get guest_physical_registration_doc_passport => 'Passport';

  @override
  String get guest_physical_registration_doc_license => 'Driver\'s license';

  @override
  String get guest_checkin_child_no_data => 'Under 14, no data required';

  @override
  String get guest_checkin_holder => 'Primary';

  @override
  String get guest_checkin_full_name => 'Full name';

  @override
  String get guest_checkin_email => 'Email';

  @override
  String get guest_checkin_phone => 'Phone';

  @override
  String guest_checkin_young(int age) {
    return 'Minor ($age years old)';
  }

  @override
  String guest_checkin_adult(int number) {
    return 'Adult $number';
  }

  @override
  String guest_checkin_guest(int number) {
    return 'Guest $number';
  }

  @override
  String get guest_checkin_document_id => 'Identity document';

  @override
  String get guest_checkin_upload_document => 'Upload document';

  @override
  String get guest_checkin_document => 'Document';

  @override
  String get guest_checkin_missing_photo => 'Document photo missing';

  @override
  String get guest_checkin_upload_document_title => 'Upload Document';

  @override
  String get guest_checkin_document_type => 'Document type';

  @override
  String get guest_checkin_document_number => 'Document number';

  @override
  String get guest_checkin_document_photo => 'Document photo';

  @override
  String get guest_checkin_image_captured => 'Image captured';

  @override
  String get guest_checkin_tap_to_capture => 'Tap to capture document';

  @override
  String get guest_checkin_camera_or_gallery => 'Camera or gallery';

  @override
  String get guest_checkin_select_source => 'Select source';

  @override
  String get guest_checkin_camera => 'Camera';

  @override
  String get guest_checkin_gallery => 'Gallery';

  @override
  String get guest_checkin_photo_required => 'Photo required';

  @override
  String get guest_checkin_document_number_required =>
      'Document number is required';

  @override
  String get guest_checkin_confirm => 'Confirm';

  @override
  String guest_checkin_capture_error(String error) {
    return 'Error al capturar imagen: $error';
  }

  @override
  String get admin_chat_title => 'Chat';

  @override
  String get admin_chat_online => 'Online';

  @override
  String get chat_delete_message => 'Delete message';

  @override
  String get chat_delete_message_confirm_body =>
      'Are you sure you want to delete this message? This action cannot be undone.';

  @override
  String get chat_delete_message_error => 'Could not delete the message';

  @override
  String get admin_chat_delete_conversation => 'Delete conversation';

  @override
  String get admin_chat_delete_confirm_body =>
      'Are you sure you want to delete this conversation?';

  @override
  String get admin_chat_deleted_success => 'Conversation deleted successfully';

  @override
  String admin_chat_error_deleting(String error) {
    return 'Error deleting conversation: $error';
  }

  @override
  String get admin_checkin_detail_title => 'Check-in Detail';

  @override
  String get admin_checkin_validate => 'Validate';

  @override
  String get admin_checkin_reject => 'Reject';

  @override
  String get admin_checkin_cancel_booking => 'Cancel Booking';

  @override
  String get admin_checkin_error_loading => 'Error loading';

  @override
  String get admin_checkin_not_found => 'Check-in not found';

  @override
  String get admin_checkin_status_pending => 'Pending';

  @override
  String get admin_checkin_status_validated => 'Validated';

  @override
  String get admin_checkin_status_rejected => 'Rejected';

  @override
  String get admin_checkin_status_cancelled => 'Cancelled';

  @override
  String get admin_checkin_status_draft => 'Draft';

  @override
  String get admin_checkin_submitted_label => 'Submitted:';

  @override
  String get admin_checkin_validated_label => 'Validated:';

  @override
  String get admin_checkin_rejected_label => 'Rejected:';

  @override
  String get admin_checkin_cancelled_label => 'Cancelled:';

  @override
  String get admin_checkin_booking_info => 'Booking Info';

  @override
  String get admin_checkin_property_label => 'Property:';

  @override
  String get admin_checkin_units_label => 'rooms';

  @override
  String get admin_checkin_unit_label => 'room';

  @override
  String get admin_checkin_code_label => 'Code:';

  @override
  String get admin_checkin_checkin_date_label => 'Check-in:';

  @override
  String get admin_checkin_checkout_date_label => 'Check-out:';

  @override
  String get admin_checkin_guests_section => 'GUESTS';

  @override
  String get admin_checkin_primary_badge => 'Primary';

  @override
  String get admin_checkin_na => 'N/A';

  @override
  String get admin_checkin_documents_section => 'DOCUMENTS';

  @override
  String get admin_checkin_unknown_guest => 'Unknown guest';

  @override
  String get admin_checkin_signature_section => 'SIGNATURE';

  @override
  String get admin_checkin_doc_type_dni => 'DNI';

  @override
  String get admin_checkin_doc_type_nie => 'NIE';

  @override
  String get admin_checkin_doc_type_passport => 'Passport';

  @override
  String get admin_checkin_image_load_error => 'Error loading image';

  @override
  String get admin_checkin_validate_title => 'Validate Check-in';

  @override
  String get admin_checkin_validate_message =>
      'Are you sure you want to validate this check-in?';

  @override
  String get admin_checkin_validated_success =>
      'Check-in validated successfully';

  @override
  String admin_checkin_error(String error) {
    return 'Error: $error';
  }

  @override
  String get admin_checkin_reject_title => 'Reject Check-in';

  @override
  String get admin_checkin_reject_message =>
      'Are you sure you want to reject this check-in?';

  @override
  String get admin_checkin_reject_hint => 'Reason for rejection (optional)...';

  @override
  String get admin_checkin_no_reason => 'No reason';

  @override
  String get admin_checkin_rejected_success => 'Check-in rejected successfully';

  @override
  String get admin_checkin_cancel_message =>
      'Are you sure you want to cancel this booking?';

  @override
  String get admin_checkin_cancel_warning => 'This action cannot be undone.';

  @override
  String get admin_checkin_cancel_reason_label => 'Cancellation reason';

  @override
  String get admin_checkin_cancel_reason_hint =>
      'Describe the reason for cancellation...';

  @override
  String get admin_checkin_cancelled_success =>
      'Booking cancelled successfully';

  @override
  String get admin_invoice_generate_pdf => 'Generate PDF';

  @override
  String get admin_invoice_share => 'Share';

  @override
  String get admin_invoice_download => 'Download';

  @override
  String get admin_invoice_share_title => 'Share Invoice';

  @override
  String get admin_invoice_copy_link => 'Copy link';

  @override
  String admin_invoice_pdf_saved(String path) {
    return 'PDF saved to: $path';
  }

  @override
  String get admin_invoice_issue => 'Issue';

  @override
  String get admin_invoice_mark_paid => 'Mark as paid';

  @override
  String admin_invoice_paid_on(String date) {
    return 'Paid on $date';
  }

  @override
  String admin_invoice_cancelled(String reason) {
    return 'Cancelled: $reason';
  }

  @override
  String get admin_invoice_issue_confirm_title => 'Issue Invoice';

  @override
  String admin_invoice_issue_confirm_message(String invoiceNumber) {
    return 'Are you sure you want to issue invoice $invoiceNumber?';
  }

  @override
  String get admin_invoice_mark_paid_confirm_title => 'Mark as Paid';

  @override
  String admin_invoice_mark_paid_confirm_message(String total) {
    return 'Do you confirm that payment of $total has been received?';
  }

  @override
  String get admin_invoice_confirm_payment => 'Confirm payment';

  @override
  String get admin_invoice_cancel_confirm_title => 'Cancel Invoice';

  @override
  String get admin_invoice_cancel_reason_label => 'Cancellation reason';

  @override
  String get admin_invoice_cancel_reason_hint =>
      'Describe the reason for cancellation...';

  @override
  String get admin_invoice_dont_cancel => 'Don\'t cancel';

  @override
  String get admin_invoice_cancel_invoice => 'Cancel invoice';

  @override
  String admin_invoice_error_generate_pdf(String error) {
    return 'Error generating PDF: $error';
  }

  @override
  String admin_invoice_error_share(String error) {
    return 'Error sharing: $error';
  }

  @override
  String admin_invoice_error_download(String error) {
    return 'Error downloading: $error';
  }

  @override
  String get admin_invoice_nif_label => 'NIF/CIF:';

  @override
  String get admin_invoice_label => 'Invoice';

  @override
  String get admin_invoice_bill_to => 'Bill to';

  @override
  String get admin_invoice_issue_date_label => 'Issue date:';

  @override
  String get admin_invoice_due_date_label => 'Due date:';

  @override
  String get admin_invoice_period_label => 'Period';

  @override
  String get admin_invoice_booking_label => 'Booking';

  @override
  String get admin_invoice_no_line_items => 'No items';

  @override
  String get admin_invoice_col_description => 'Description';

  @override
  String get admin_invoice_col_qty => 'Qty';

  @override
  String get admin_invoice_col_price => 'Price';

  @override
  String get admin_invoice_col_total => 'Total';

  @override
  String get admin_invoice_tax_base => 'Tax base';

  @override
  String get admin_invoice_tax_label => 'VAT';

  @override
  String get admin_invoice_total_label => 'Total';

  @override
  String get admin_invoice_notes_label => 'Notes';

  @override
  String get admin_notifications_title => 'Notifications';

  @override
  String get admin_notifications_empty_title => 'No notifications';

  @override
  String get admin_notifications_empty_subtitle =>
      'Notifications will appear here';

  @override
  String get admin_notifications_mark_all_read => 'Mark all as read';

  @override
  String get admin_notifications_mark_read => 'Mark as read';

  @override
  String get admin_notifications_delete_all => 'Delete all';

  @override
  String get admin_notifications_delete_all_title => 'Delete all notifications';

  @override
  String get admin_notifications_delete_all_confirm =>
      'Are you sure you want to delete all notifications?';

  @override
  String admin_notifications_unread_count(int count) {
    return '$count unread';
  }

  @override
  String get guest_access_checkin => 'Check-in';

  @override
  String get guest_access_checkout => 'Check-out';

  @override
  String get guest_access_checkout_label => 'Checkout';

  @override
  String guest_access_checkout_until(String time) {
    return 'Until $time';
  }

  @override
  String get guest_access_checkout_deadline => 'Checkout deadline';

  @override
  String get guest_access_checkout_instructions => 'Checkout instructions';

  @override
  String get guest_access_code_label => 'Code';

  @override
  String guest_access_code_available_at(String date, String time) {
    return 'Available on $date at $time';
  }

  @override
  String get guest_access_code_provided_by_staff => 'Provided by staff';

  @override
  String get guest_access_locker_code => 'Locker code';

  @override
  String get guest_access_locker_code_label => 'Locker code';

  @override
  String guest_access_locker_available_at(String date) {
    return 'Available on $date';
  }

  @override
  String get guest_access_key_locker => 'Key locker';

  @override
  String get guest_access_door_code => 'Door code';

  @override
  String get guest_access_building_access => 'Building access';

  @override
  String get guest_access_building_instructions =>
      'Building access instructions';

  @override
  String get guest_access_apartment_access => 'Apartment access';

  @override
  String get guest_access_apartment_instructions =>
      'Apartment access instructions';

  @override
  String get guest_access_location => 'Location';

  @override
  String get guest_access_contact => 'Contact';

  @override
  String get guest_access_contact_description => 'Contact us if you need help';

  @override
  String guest_access_copied(String label) {
    return '$label copied to clipboard';
  }

  @override
  String get guest_access_open_maps => 'Open in Maps';

  @override
  String get guest_access_network => 'Network';

  @override
  String get guest_access_network_name => 'Network name';

  @override
  String get guest_access_password => 'Password';

  @override
  String get guest_access_company_name => 'BF Stay';

  @override
  String get guest_access_house_rules => 'House rules';

  @override
  String get guest_access_rules_warning =>
      'Please read the house rules before your arrival';

  @override
  String get guest_access_your_accommodation => 'Your accommodation';

  @override
  String get guest_access_your_codes => 'Your codes';

  @override
  String get guest_access_guest => 'Guest';

  @override
  String guest_access_welcome_message(String unitName) {
    return 'Welcome to $unitName';
  }

  @override
  String guest_access_hello(String name) {
    return 'Hello $name';
  }

  @override
  String guest_access_codes_available_datetime(String date, String time) {
    return 'Available on $date at $time';
  }

  @override
  String guest_access_codes_available_message(String time) {
    return 'Your code will be available from $time';
  }

  @override
  String get guest_access_loading_instructions => 'Loading instructions...';

  @override
  String get guest_access_cannot_load_instructions =>
      'Cannot load instructions';

  @override
  String get guest_access_rule_no_parties_title => 'No parties';

  @override
  String get guest_access_rule_no_parties_description =>
      'No parties or events allowed';

  @override
  String get guest_access_rule_no_smoking_title => 'No smoking';

  @override
  String get guest_access_rule_smoke_free_description =>
      'This is a smoke-free property';

  @override
  String get guest_access_rule_registered_only_title => 'Registered only';

  @override
  String get guest_access_rule_registered_only_description =>
      'Only registered guests can access';

  @override
  String get guest_accommodation_title => 'Accommodation';

  @override
  String get guest_accommodation_error_loading => 'Error loading';

  @override
  String get guest_accommodation_error_occurred => 'An error occurred';

  @override
  String get guest_accommodation_no_booking => 'Booking not found';

  @override
  String get guest_accommodation_booking_not_found => 'Booking not found';

  @override
  String get guest_accommodation_no_unit_info => 'No unit info available';

  @override
  String get guest_accommodation_address => 'Address';

  @override
  String get guest_accommodation_address_unavailable => 'Address unavailable';

  @override
  String get guest_accommodation_box_location => 'Box location';

  @override
  String get guest_accommodation_access_codes => 'Access codes';

  @override
  String get guest_accommodation_access_instructions => 'Access instructions';

  @override
  String get guest_accommodation_main_door => 'Main door';

  @override
  String get guest_accommodation_door_code => 'Door code';

  @override
  String get guest_accommodation_portal_code => 'Portal code';

  @override
  String get guest_accommodation_key_box_code => 'Key box code';

  @override
  String get guest_accommodation_keybox_description => 'Code for key box';

  @override
  String get guest_accommodation_wifi_password => 'WiFi password';

  @override
  String guest_accommodation_rooms_count(int count) {
    return '$count rooms';
  }

  @override
  String get guest_accommodation_hotel_rules => 'Hotel rules';

  @override
  String get guest_accommodation_apartment_rules => 'Apartment rules';

  @override
  String get guest_accommodation_rules_description =>
      'Check your accommodation rules';

  @override
  String guest_accommodation_rules_load_error(String error) {
    return 'Error loading rules: $error';
  }

  @override
  String guest_accommodation_codes_available_datetime(
    String date,
    String time,
  ) {
    return 'Available on $date at $time';
  }

  @override
  String guest_accommodation_codes_available_message(String time) {
    return 'Your codes will be available when your stay begins ($time)';
  }

  @override
  String guest_accommodation_file_not_found(String message) {
    return 'File not found: $message';
  }

  @override
  String get guest_accommodation_cannot_open_document => 'Cannot open document';

  @override
  String get guest_accommodation_tap_for_access_info => 'Tap for access info';

  @override
  String get guest_chat_default_title => 'Chat';

  @override
  String get guest_chat_online => 'Online';

  @override
  String get guest_chat_start_conversation => 'Start conversation';

  @override
  String get guest_chat_welcome_message => 'Hello! How can we help you?';

  @override
  String get guest_checkin_label => 'Check-in';

  @override
  String get guest_checkin_back => 'Back';

  @override
  String get guest_checkin_continue => 'Continue';

  @override
  String get guest_checkin_complete => 'Complete';

  @override
  String get guest_checkin_loading_booking => 'Loading booking data...';

  @override
  String get guest_checkin_error_loading => 'Error loading';

  @override
  String get guest_checkin_booking => 'Booking';

  @override
  String get guest_checkin_code => 'Code';

  @override
  String get guest_checkin_guests_label => 'Guests';

  @override
  String guest_checkin_guests_count(int count) {
    return '$count guests';
  }

  @override
  String guest_checkin_guests_registered(int count) {
    return '$count registered';
  }

  @override
  String guest_checkin_guests_summary(int count) {
    return '$count guests';
  }

  @override
  String get guest_checkin_guest_data => 'Guest data';

  @override
  String get guest_checkin_guest_data_description =>
      'Complete the data for all guests';

  @override
  String get guest_checkin_holder_badge => 'PRIMARY';

  @override
  String get guest_checkin_holder_signature => 'Primary guest signature';

  @override
  String get guest_checkin_no_name => 'No name';

  @override
  String get guest_checkin_guest_no_name => 'Guest without name';

  @override
  String guest_checkin_adults_children(int adults, int children) {
    return '$adults adults and $children minors';
  }

  @override
  String get guest_checkin_minor_badge => 'MINOR';

  @override
  String guest_checkin_young_document_required(int age) {
    return 'Under $age, document required';
  }

  @override
  String get guest_checkin_document_required => 'Document required';

  @override
  String get guest_checkin_upload => 'Upload';

  @override
  String guest_checkin_documents_uploaded(int completed, int total) {
    return '$completed of $total documents uploaded';
  }

  @override
  String get guest_checkin_all_documents_uploaded => 'All documents uploaded';

  @override
  String get guest_checkin_upload_documents_description =>
      'Upload photos of identity documents for all guests';

  @override
  String get guest_checkin_uploaded_documents => 'Uploaded documents';

  @override
  String get guest_checkin_pending_documents => 'Pending documents';

  @override
  String get guest_checkin_identity_documents => 'Identity documents';

  @override
  String get guest_checkin_signature_description =>
      'Signature of the booking primary guest';

  @override
  String get guest_checkin_signature_pending => 'Signature pending';

  @override
  String get guest_checkin_signature_captured => 'Signature captured';

  @override
  String get guest_checkin_signature_captured_short => 'Signature';

  @override
  String get guest_checkin_clear_signature => 'Clear signature';

  @override
  String get guest_checkin_step_guests => 'Guests';

  @override
  String get guest_checkin_step_documents => 'Documents';

  @override
  String get guest_checkin_step_signature => 'Signature';

  @override
  String get guest_checkin_step_confirm => 'Confirm';

  @override
  String get guest_checkin_online => 'Online';

  @override
  String get guest_checkin_pending => 'Pending';

  @override
  String get guest_checkin_validated => 'Validated';

  @override
  String get guest_checkin_waiting_validation => 'Waiting validation';

  @override
  String get guest_checkin_completed => 'Completed';

  @override
  String get guest_checkin_completed_success =>
      'Check-in completed successfully';

  @override
  String get guest_checkin_sending => 'Sending...';

  @override
  String get guest_checkin_progress => 'Check-in progress';

  @override
  String get guest_checkin_confirmation => 'Check-in Confirmation';

  @override
  String get guest_checkin_confirmation_description =>
      'Your check-in has been sent. Now you need to wait for the accommodation to validate it.';

  @override
  String get guest_checkin_legal_notice => 'Legal notice';

  @override
  String get guest_checkout_title => 'Check-out';

  @override
  String get guest_checkout_label => 'Checkout';

  @override
  String get guest_checkout_checkin_label => 'Check-in';

  @override
  String get guest_checkout_checkout_label => 'Check-out';

  @override
  String guest_checkout_nights_count(int count) {
    return '$count nights';
  }

  @override
  String guest_checkout_guests_count(int count) {
    return '$count guests';
  }

  @override
  String get guest_checkout_stay_summary => 'Stay summary';

  @override
  String get guest_checkout_confirm => 'Confirm';

  @override
  String get guest_checkout_confirm_button => 'Confirm checkout';

  @override
  String get guest_checkout_confirm_dialog_title => 'Confirm checkout?';

  @override
  String get guest_checkout_confirm_dialog_message =>
      'You are about to confirm your checkout. Do you want to continue?';

  @override
  String get guest_checkout_confirm_info => 'Confirming checkout...';

  @override
  String get guest_checkout_processing => 'Processing...';

  @override
  String get guest_checkout_completed => 'Checkout completed';

  @override
  String get guest_checkout_thank_you => 'Thank you for your stay!';

  @override
  String get guest_checkout_feedback_title => 'Your opinion matters';

  @override
  String get guest_checkout_feedback_hint => 'Tell us about your experience...';

  @override
  String get guest_checkout_rating_title => 'Rate your stay';

  @override
  String get guest_checkout_review_description =>
      'Your opinion helps other travelers';

  @override
  String get guest_checkout_loading => 'Loading...';

  @override
  String get guest_checkout_error_loading => 'Error loading';

  @override
  String get guest_checkout_already_done => 'Checkout already done';

  @override
  String get guest_checkout_already_done_message =>
      'You have already checked out. Thank you!';

  @override
  String get guest_home_welcome => 'Welcome';

  @override
  String get guest_home_welcome_stay => 'Welcome to your stay';

  @override
  String guest_home_hello_name(String name) {
    return 'Hello, $name';
  }

  @override
  String get guest_home_your_stay => 'Your Stay';

  @override
  String get guest_home_no_booking => 'No bookings';

  @override
  String get guest_home_not_authenticated => 'Not authenticated';

  @override
  String get guest_home_stay_active_enjoy => 'Your stay is active. Enjoy!';

  @override
  String get guest_home_quick_actions => 'Quick actions';

  @override
  String get guest_home_checkin => 'Check-in';

  @override
  String get guest_home_checkout => 'Check-out';

  @override
  String get guest_home_chat => 'Chat';

  @override
  String get guest_home_guide => 'Guide';

  @override
  String get guest_home_rules => 'Rules';

  @override
  String get guest_home_parkings => 'Parking';

  @override
  String get guest_home_accommodations => 'Accommodations';

  @override
  String get guest_home_accommodation => 'Accommodation';

  @override
  String guest_home_rooms_count(int count) {
    return '$count rooms';
  }

  @override
  String get guest_home_guests => 'Guests';

  @override
  String guest_home_nights(int count) {
    return '$count nights';
  }

  @override
  String get guest_home_what_to_see => 'What to see';

  @override
  String get guest_home_instructions => 'Instructions';

  @override
  String get guest_home_my_accommodation => 'My accommodation';

  @override
  String get guest_home_booking_cancelled => 'Booking cancelled';

  @override
  String get guest_home_booking_cancelled_message =>
      'Your booking has been cancelled. Contact reception.';

  @override
  String get guest_home_cancellation_reason => 'Cancellation reason';

  @override
  String get guest_home_checkin_pending => 'Check-in pending';

  @override
  String get guest_home_checkin_sent_waiting =>
      'Check-in sent, waiting validation';

  @override
  String get guest_home_checkin_rejected => 'Check-in rejected';

  @override
  String get guest_home_rejection_reason => 'Rejection reason';

  @override
  String get guest_home_pending_validation => 'Pending validation';

  @override
  String get guest_home_complete_checkin_access =>
      'Complete check-in to access';

  @override
  String get guest_home_contact_reception => 'Contact reception';

  @override
  String get guest_home_correct_errors_resend => 'Correct errors and resend';

  @override
  String get guest_home_physical_registration => 'In-person registration';

  @override
  String get guest_home_romantic_pack => 'Romantic Pack';

  @override
  String guest_jacuzzi_note(String note) {
    return 'Note: $note';
  }

  @override
  String get public_services_title => 'Our Services';

  @override
  String get public_service_rules_title => 'House Rules';

  @override
  String get public_service_rules_desc => 'Rules and recommendations.';

  @override
  String public_copyright(int year) {
    return '© $year BF Stay • All rights reserved';
  }

  @override
  String get public_access_booking => 'Access My Booking';

  @override
  String staff_dashboard_greeting(String name) {
    return 'Hello $name';
  }

  @override
  String get staff_dashboard_control_panel => 'Control Panel';

  @override
  String get staff_dashboard_daily_summary => 'Daily Summary';

  @override
  String get staff_dashboard_occupancy => 'Occupancy';

  @override
  String get staff_dashboard_pending => 'Pending';

  @override
  String get staff_dashboard_pending_checkin => 'Pending check-ins';

  @override
  String get staff_dashboard_pending_checkout => 'Pending check-outs';

  @override
  String get staff_dashboard_pending_tasks => 'Pending tasks';

  @override
  String get staff_dashboard_checkins_today => 'Check-ins today';

  @override
  String get staff_dashboard_checkouts_today => 'Check-outs today';

  @override
  String get staff_dashboard_quick_actions => 'Quick actions';

  @override
  String get staff_dashboard_manage_checkins => 'Manage check-ins';

  @override
  String get staff_dashboard_view_guests => 'View guests';

  @override
  String staff_dashboard_room_extras(String room) {
    return 'Room $room - Extras';
  }

  @override
  String get staff_dashboard_cleaning_request => 'Cleaning request';

  @override
  String staff_dashboard_room_guest(String room, String guest) {
    return 'Room $room - $guest';
  }

  @override
  String get staff_dashboard_generate_report => 'Generate report';

  @override
  String get staff_checkins_title => 'Check-ins';

  @override
  String get staff_checkins_tab_pending => 'Pending';

  @override
  String get staff_checkins_tab_in_progress => 'In Progress';

  @override
  String get staff_checkins_tab_completed => 'Completed';

  @override
  String get staff_checkins_status_pending => 'Pending';

  @override
  String get staff_checkins_status_in_progress => 'In Progress';

  @override
  String get staff_checkins_status_completed => 'Completed';

  @override
  String get staff_checkins_start => 'Start';

  @override
  String get staff_checkins_new_checkin => 'New check-in';

  @override
  String get staff_checkins_complete => 'Complete';

  @override
  String get staff_checkins_view_details => 'View details';

  @override
  String get guest_access_wifi_password_label => 'WiFi Password';

  @override
  String get guest_access_locker_provided_by_staff => 'Provided by staff';

  @override
  String get guest_access_rule_smoke_free_title => 'No smoking';

  @override
  String get guest_accommodation_view_rules_pdf => 'View rules as PDF';

  @override
  String get public_hero_title_line1 => 'Your Stay,';

  @override
  String get public_hero_title_line2 => 'Elevated';

  @override
  String get admin_booking_send_whatsapp_title => 'Send code via WhatsApp';

  @override
  String get admin_booking_send_whatsapp_no_phone =>
      'Guest has no phone number';

  @override
  String get admin_booking_send_whatsapp_no_phone_desc =>
      'Enter a phone number to send the code via WhatsApp.';

  @override
  String get admin_booking_send_whatsapp_phone_hint => '+44 700 000 000';

  @override
  String get admin_booking_send_whatsapp_error => 'Could not open WhatsApp';

  @override
  String admin_booking_send_whatsapp_message(
    String propertyName,
    String bookingCode,
    String checkIn,
    String checkOut,
  ) {
    return '🏠 *$propertyName*\n📋 Booking: *$bookingCode*\n📅 Check-in: $checkIn\n📅 Check-out: $checkOut\n\nDownload the BF Stay app to manage your stay.';
  }
}
