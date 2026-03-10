import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/repositories/checkin_repository.dart';

/// Implementación del repositorio de check-in
class CheckinRepositoryImpl implements CheckinRepository {
  CheckinRepositoryImpl();

  SupabaseClient get _client => SupabaseConfig.client;
  String? get _userId => SupabaseConfig.currentSession?.user.id;

  /// Bucket de storage para documentos de huéspedes
  static const String _documentsBucket = 'guest-documents';

  /// Contraseña genérica para cuentas de huéspedes
  /// Todos los huéspedes usan la misma contraseña ya que el acceso está protegido por booking_code
  static const String _guestPassword = 'BFGuest2024!';

  /// Asegura que el usuario está autenticado y el primary_guest_user_id está asignado
  /// Crea una cuenta con el email del huésped si no existe
  /// Lanza excepción si no se puede asegurar la autenticación
  Future<void> _ensurePrimaryGuestUserId(String bookingId) async {
    // 1. Obtener datos de la reserva (incluye email del huésped)
    final booking = await _client
        .from('bookings')
        .select('primary_guest_user_id, booking_code, guest_email')
        .eq('id', bookingId)
        .single();

    final guestEmail = booking['guest_email'] as String?;
    final currentPrimaryId = booking['primary_guest_user_id'] as String?;
    final currentUserId = _userId;

    debugPrint('📋 [_ensurePrimaryGuestUserId] Email: $guestEmail, CurrentUser: $currentUserId, PrimaryId: $currentPrimaryId');

    // 2. Verificar si ya estamos autenticados como el usuario correcto
    if (currentUserId != null && currentUserId == currentPrimaryId) {
      debugPrint('✅ [_ensurePrimaryGuestUserId] Ya autenticado como el usuario correcto');
      return;
    }

    // 3. Si hay un primary_guest_user_id pero no somos ese usuario, necesitamos
    //    hacer login con el email del huésped para obtener ese ID
    if (currentPrimaryId != null && guestEmail != null && guestEmail.isNotEmpty) {
      debugPrint('🔄 [_ensurePrimaryGuestUserId] Reserva ya tiene primary_guest_user_id, intentando login con email del huésped');
      await _signInGuestAndVerify(bookingId, guestEmail, booking['booking_code'] as String, currentPrimaryId);
      return;
    }

    // 4. Si no hay email, no podemos crear cuenta
    if (guestEmail == null || guestEmail.isEmpty) {
      debugPrint('⚠️ [_ensurePrimaryGuestUserId] No hay email del huésped, usando sesión anónima');
      await _ensureAnonymousSession(bookingId, booking['booking_code'] as String);
      return;
    }

    // 5. Intentar login o registro con el email del huésped
    await _signInOrSignUpGuest(guestEmail, bookingId, booking['booking_code'] as String);
  }

  /// Intenta hacer login con el email del huésped y verifica que obtiene el ID correcto
  Future<void> _signInGuestAndVerify(String bookingId, String email, String bookingCode, String expectedUserId) async {
    debugPrint('🔐 [_signInGuestAndVerify] Intentando login con: $email para obtener ID: $expectedUserId');

    final response = await _client.auth.signInWithPassword(
      email: email.toLowerCase().trim(),
      password: _guestPassword,
    );

    if (response.user == null) {
      debugPrint('❌ [_signInGuestAndVerify] Login falló - usuario null');
      throw Exception('No se pudo autenticar como el huésped principal de esta reserva');
    }

    debugPrint('✅ [_signInGuestAndVerify] Login exitoso: ${response.user!.id}');

    if (response.user!.id == expectedUserId) {
      debugPrint('✅ [_signInGuestAndVerify] ID coincide con primary_guest_user_id');
      return;
    }

    // El usuario se logueó pero con un ID diferente
    // Esto puede pasar si la cuenta se creó con otra sesión
    debugPrint('⚠️ [_signInGuestAndVerify] ID NO coincide. Esperado: $expectedUserId, Obtenido: ${response.user!.id}');

    // Actualizar el primary_guest_user_id al nuevo ID del usuario autenticado
    debugPrint('🔄 [_signInGuestAndVerify] Actualizando primary_guest_user_id al nuevo ID...');
    await _assignPrimaryGuestId(bookingId, bookingCode, response.user!.id);
  }

  /// Intenta hacer login o registro del huésped con su email
  /// Lanza excepción si no puede autenticar
  Future<void> _signInOrSignUpGuest(String email, String bookingId, String bookingCode) async {
    debugPrint('🔐 [_signInOrSignUpGuest] Intentando login con: $email');

    // Intentar login primero
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.toLowerCase().trim(),
        password: _guestPassword,
      );

      if (response.user != null) {
        debugPrint('✅ [_signInOrSignUpGuest] Login exitoso: ${response.user!.id}');
        await _assignPrimaryGuestId(bookingId, bookingCode, response.user!.id);
        return;
      }
    } on AuthException catch (e) {
      debugPrint('⚠️ [_signInOrSignUpGuest] Login falló con AuthException: ${e.message}');

      // Si es "Invalid login credentials", intentar registro
      if (e.message.contains('Invalid login credentials') || e.message.contains('invalid_credentials')) {
        debugPrint('🔄 [_signInOrSignUpGuest] Intentando registro...');

        try {
          final response = await _client.auth.signUp(
            email: email.toLowerCase().trim(),
            password: _guestPassword,
            emailRedirectTo: null, // Sin verificación de email
          );

          if (response.user != null) {
            debugPrint('✅ [_signInOrSignUpGuest] Registro exitoso: ${response.user!.id}');
            await _assignPrimaryGuestId(bookingId, bookingCode, response.user!.id);
            return;
          }
        } on AuthException catch (signUpError) {
          debugPrint('❌ [_signInOrSignUpGuest] Registro falló: ${signUpError.message}');

          // Si el email ya está registrado con otra contraseña, intentar de nuevo el login
          // ya que podría ser un problema de timing
          if (signUpError.message.contains('already registered') || signUpError.message.contains('already been registered')) {
            debugPrint('🔄 [_signInOrSignUpGuest] Email ya registrado, reintentando login...');
            try {
              final retryResponse = await _client.auth.signInWithPassword(
                email: email.toLowerCase().trim(),
                password: _guestPassword,
              );
              if (retryResponse.user != null) {
                debugPrint('✅ [_signInOrSignUpGuest] Login en retry exitoso: ${retryResponse.user!.id}');
                await _assignPrimaryGuestId(bookingId, bookingCode, retryResponse.user!.id);
                return;
              }
            } catch (_) {
              // Ignorar error en retry
            }
          }

          throw Exception('No se pudo autenticar el huésped. Por favor, contacte al administrador.');
        }
      }

      rethrow;
    }

    // Si llegamos aquí, algo salió mal
    throw Exception('No se pudo completar la autenticación del huésped');
  }

  /// Crea una sesión anónima como fallback (solo cuando NO hay primary_guest_user_id existente)
  Future<void> _ensureAnonymousSession(String bookingId, String bookingCode) async {
    var userId = _userId;

    if (userId == null) {
      debugPrint('🔐 [_ensureAnonymousSession] Creando sesión anónima...');
      final anonSession = await _client.auth.signInAnonymously();
      userId = anonSession.user?.id;
      debugPrint('✅ [_ensureAnonymousSession] Sesión anónima creada: $userId');
    }

    if (userId != null) {
      await _assignPrimaryGuestId(bookingId, bookingCode, userId);
    } else {
      throw Exception('No se pudo crear sesión para el huésped');
    }
  }

  /// Asigna el primary_guest_user_id a la reserva usando función RPC con SECURITY DEFINER
  Future<void> _assignPrimaryGuestId(String bookingId, String bookingCode, String userId) async {
    // Verificar si ya está asignado correctamente
    final booking = await _client
        .from('bookings')
        .select('primary_guest_user_id')
        .eq('id', bookingId)
        .single();

    if (booking['primary_guest_user_id'] == userId) {
      debugPrint('✅ [_assignPrimaryGuestId] Ya está asignado correctamente');
      return;
    }

    debugPrint('🔑 [_assignPrimaryGuestId] Asignando $userId a reserva $bookingId via RPC...');

    // Usar función RPC con SECURITY DEFINER que no tiene restricciones de RLS
    await _client.rpc(
      'assign_primary_guest_to_booking',
      params: {
        'p_booking_id': bookingId,
        'p_user_id': userId,
      },
    );

    debugPrint('✅ [_assignPrimaryGuestId] Asignado correctamente via RPC');
  }

  @override
  Future<CheckinBookingData> getBookingForCheckin(String bookingId) async {
    try {
      debugPrint('📋 [getBookingForCheckin] Obteniendo datos de reserva: $bookingId');

      // Consulta base sin JOINs problemáticos (en web causan aserción si son null)
      final response = await _client
          .from('bookings')
          .select('''
            id,
            booking_code,
            unit_id,
            property_id,
            checkin_date,
            checkout_date,
            num_adults,
            num_children,
            children_ages,
            guest_first_name,
            last_name,
            guest_email,
            guest_phone,
            checkins (
              id,
              status
            )
          ''')
          .eq('id', bookingId)
          .single();

      debugPrint('📋 [getBookingForCheckin] Reserva obtenida');

      // Obtener datos de unit y property por separado
      String? unitName;
      String? propertyId;
      String? propertyName;

      final unitId = response['unit_id'] as String?;
      final propId = response['property_id'] as String?;

      if (unitId != null) {
        try {
          final unitResponse = await _client
              .from('units')
              .select('name')
              .eq('id', unitId)
              .maybeSingle();
          unitName = unitResponse?['name'] as String?;
        } catch (e) {
          debugPrint('⚠️ [getBookingForCheckin] Error obteniendo unit: $e');
        }
      }

      if (propId != null) {
        try {
          final propertyResponse = await _client
              .from('properties')
              .select('id, name')
              .eq('id', propId)
              .maybeSingle();
          propertyId = propertyResponse?['id'] as String?;
          propertyName = propertyResponse?['name'] as String?;
        } catch (e) {
          debugPrint('⚠️ [getBookingForCheckin] Error obteniendo property: $e');
        }
      }

      // checkins puede ser un Map (relación uno-a-uno) o null
      final checkinRaw = response['checkins'];
      final checkin = checkinRaw != null && checkinRaw is Map<String, dynamic>
          ? checkinRaw
          : null;

      return CheckinBookingData.fromJson({
        ...response,
        'unit_name': unitName ?? '',
        'property_id': propertyId ?? propId ?? '',
        'property_name': propertyName ?? '',
        'checkin_id': checkin?['id'],
        'checkin_status': checkin?['status'],
      });
    } catch (e, s) {
      debugPrint('❌ [getBookingForCheckin] Error: $e');
      debugPrint('❌ [getBookingForCheckin] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<List<GuestEntity>> getBookingGuests(String bookingId) async {
    try {
      debugPrint('📋 [getBookingGuests] Obteniendo huéspedes de reserva: $bookingId');

      final response = await _client
          .from('booking_guests')
          .select('''
            is_primary,
            guests (
              id,
              full_name,
              email,
              phone,
              type,
              age,
              document_type,
              document_number,
              nationality,
              birth_date
            )
          ''')
          .eq('booking_id', bookingId);

      // Verificar qué huéspedes tienen documentos subidos
      final documentsResponse = await _client
          .from('guest_documents')
          .select('guest_id')
          .eq('booking_id', bookingId);

      final guestsWithDocuments = <String>{};
      for (final doc in documentsResponse as List) {
        final guestId = doc['guest_id'] as String?;
        if (guestId != null) {
          guestsWithDocuments.add(guestId);
        }
      }

      final guests = (response as List).map((row) {
        final guestData = row['guests'] as Map<String, dynamic>;
        final guestId = guestData['id'] as String?;
        return GuestEntity.fromJson({
          ...guestData,
          'is_primary': row['is_primary'] as bool? ?? false,
          'has_document_image': guestId != null && guestsWithDocuments.contains(guestId),
        });
      }).toList();

      debugPrint('📋 [getBookingGuests] ${guests.length} huéspedes obtenidos, ${guestsWithDocuments.length} con documentos');
      return guests;
    } catch (e, s) {
      debugPrint('❌ [getBookingGuests] Error: $e');
      debugPrint('❌ [getBookingGuests] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<GuestEntity> saveGuest({
    required String bookingId,
    required GuestEntity guest,
  }) async {
    try {
      debugPrint('💾 [saveGuest] Guardando huésped: ${guest.fullName}');

      // 🔑 Asegurar que el primary_guest_user_id está asignado antes de guardar
      await _ensurePrimaryGuestUserId(bookingId);

      if (guest.id != null) {
        // Actualizar huésped existente via RPC con SECURITY DEFINER
        await _client.rpc(
          'update_guest_for_booking',
          params: {
            'p_guest_id': guest.id,
            'p_booking_id': bookingId,
            'p_full_name': guest.fullName,
            'p_email': guest.email,
            'p_phone': guest.phone,
            'p_type': guest.type == GuestType.child ? 'child' : 'adult',
            'p_age': guest.age,
            'p_document_type': guest.documentType?.dbValue,
            'p_document_number': guest.documentNumber,
            'p_nationality': guest.nationality,
            'p_birth_date': guest.birthDate?.toIso8601String().split('T').first,
          },
        );

        debugPrint('💾 [saveGuest] Huésped actualizado via RPC: ${guest.id}');
        return guest;
      } else {
        // Crear nuevo huésped via RPC con SECURITY DEFINER
        final newGuestId = await _client.rpc(
          'insert_guest_for_booking',
          params: {
            'p_booking_id': bookingId,
            'p_full_name': guest.fullName,
            'p_email': guest.email,
            'p_phone': guest.phone,
            'p_type': guest.type == GuestType.child ? 'child' : 'adult',
            'p_age': guest.age,
            'p_document_type': guest.documentType?.dbValue,
            'p_document_number': guest.documentNumber,
            'p_nationality': guest.nationality,
            'p_birth_date': guest.birthDate?.toIso8601String().split('T').first,
            'p_is_primary': guest.isPrimary,
          },
        );

        debugPrint('💾 [saveGuest] Huésped creado via RPC: $newGuestId');

        return guest.copyWith(id: newGuestId as String);
      }
    } catch (e, s) {
      debugPrint('❌ [saveGuest] Error: $e');
      debugPrint('❌ [saveGuest] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<void> deleteGuest(String guestId) async {
    try {
      debugPrint('🗑️ [deleteGuest] Eliminando huésped: $guestId');

      // La relación se elimina en cascada por la FK
      await _client.from('guests').delete().eq('id', guestId);

      debugPrint('🗑️ [deleteGuest] Huésped eliminado');
    } catch (e, s) {
      debugPrint('❌ [deleteGuest] Error: $e');
      debugPrint('❌ [deleteGuest] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<String> uploadDocument({
    required String bookingId,
    required String guestId,
    required String docKind,
    required List<int> bytes,
    required String mimeType,
  }) async {
    try {
      debugPrint('📤 [uploadDocument] Subiendo documento: $docKind para huésped $guestId');

      // 🔑 Asegurar que el primary_guest_user_id está asignado y autenticado
      // Esto es CRÍTICO para que las políticas RLS del storage funcionen
      await _ensurePrimaryGuestUserId(bookingId);

      // Verificar que tenemos un usuario autenticado
      final currentUserId = _userId;
      debugPrint('📤 [uploadDocument] Usuario autenticado: $currentUserId');

      if (currentUserId == null) {
        throw Exception('No hay usuario autenticado para subir documentos');
      }

      // Generar nombre de archivo único
      // Estructura: guests/{booking_id}/{guest_id}/{doc_kind}/{fileName}
      // Esto coincide con las políticas RLS del bucket guest-documents
      final extension = mimeType.split('/').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = 'guests/$bookingId/$guestId/$docKind/$fileName';

      debugPrint('📤 [uploadDocument] Ruta de storage: $storagePath');

      // Subir al bucket
      await _client.storage
          .from(_documentsBucket)
          .uploadBinary(storagePath, Uint8List.fromList(bytes));

      // Guardar metadatos en la base de datos
      await _client.from('guest_documents').insert({
        'booking_id': bookingId,
        'guest_id': guestId,
        'doc_kind': docKind,
        'storage_path': storagePath,
        'mime_type': mimeType,
        'uploaded_by': _userId,
      });

      debugPrint('📤 [uploadDocument] Documento subido: $storagePath');
      return storagePath;
    } catch (e, s) {
      debugPrint('❌ [uploadDocument] Error: $e');
      debugPrint('❌ [uploadDocument] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<String> getDocumentUrl(String storagePath) async {
    try {
      // Generar URL firmada válida por 1 año (31536000 segundos)
      final url = await _client.storage
          .from(_documentsBucket)
          .createSignedUrl(storagePath, 31536000);

      return url;
    } catch (e, s) {
      debugPrint('❌ [getDocumentUrl] Error: $e');
      debugPrint('❌ [getDocumentUrl] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<void> submitCheckin({
    required String bookingId,
    required String signatureSvg,
  }) async {
    try {
      debugPrint('✅ [submitCheckin] Enviando check-in para reserva: $bookingId');

      // Usar función RPC con SECURITY DEFINER
      await _client.rpc(
        'submit_guest_checkin',
        params: {
          'p_booking_id': bookingId,
          'p_signature_svg': signatureSvg,
        },
      );

      debugPrint('✅ [submitCheckin] Check-in enviado correctamente via RPC');
    } catch (e, s) {
      debugPrint('❌ [submitCheckin] Error: $e');
      debugPrint('❌ [submitCheckin] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<CheckinStatus> getCheckinStatus(String bookingId) async {
    try {
      final response = await _client
          .from('checkins')
          .select('status')
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) return CheckinStatus.none;

      return CheckinStatusExtension.fromDbValue(response['status'] as String?);
    } catch (e, s) {
      debugPrint('❌ [getCheckinStatus] Error: $e');
      debugPrint('❌ [getCheckinStatus] StackTrace: $s');
      rethrow;
    }
  }

  @override
  Future<GuestEntity?> findGuestByEmail(String email) async {
    try {
      if (email.isEmpty) return null;

      debugPrint('🔍 [findGuestByEmail] Buscando huésped por email: $email');

      // Buscar el huésped más reciente con ese email que tenga documento
      // Usar ilike para búsqueda case-insensitive
      final response = await _client
          .from('guests')
          .select()
          .ilike('email', email.trim())
          .not('document_number', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [findGuestByEmail] No se encontró huésped con documento');
        return null;
      }

      debugPrint('✅ [findGuestByEmail] Huésped encontrado con documento: ${response['document_number']}');
      return GuestEntity.fromJson(response);
    } catch (e, s) {
      debugPrint('❌ [findGuestByEmail] Error: $e');
      debugPrint('❌ [findGuestByEmail] StackTrace: $s');
      return null; // No lanzar error, simplemente retornar null
    }
  }

  @override
  Future<ProfileData?> getProfileByEmail(String email) async {
    try {
      if (email.isEmpty) return null;

      debugPrint('🔍 [getProfileByEmail] Buscando perfil por email: $email');

      // Usar la función RPC para buscar perfil
      final response = await _client.rpc(
        'get_profile_by_email',
        params: {'p_email': email.trim()},
      );

      if (response == null || (response is List && response.isEmpty)) {
        debugPrint('🔍 [getProfileByEmail] No se encontró perfil');
        return null;
      }

      final profileData = response is List ? response.first : response;
      debugPrint('✅ [getProfileByEmail] Perfil encontrado: ${profileData['document_number']}');
      return ProfileData.fromJson(profileData);
    } catch (e, s) {
      debugPrint('❌ [getProfileByEmail] Error: $e');
      debugPrint('❌ [getProfileByEmail] StackTrace: $s');
      return null;
    }
  }

  @override
  Future<void> saveProfile(ProfileData profile) async {
    try {
      debugPrint('💾 [saveProfile] Guardando perfil: ${profile.email}');

      await _client.rpc(
        'upsert_profile',
        params: {
          'p_email': profile.email.trim(),
          'p_user_id': profile.userId,
          'p_full_name': profile.fullName,
          'p_phone': profile.phone,
          'p_document_type': profile.documentType,
          'p_document_number': profile.documentNumber,
          'p_nationality': profile.nationality,
          'p_birth_date': profile.birthDate?.toIso8601String().split('T').first,
        },
      );

      debugPrint('✅ [saveProfile] Perfil guardado correctamente');
    } catch (e, s) {
      debugPrint('❌ [saveProfile] Error: $e');
      debugPrint('❌ [saveProfile] StackTrace: $s');
      // No relanzar, es un guardado secundario
    }
  }

  @override
  Stream<CheckinStatus> watchCheckinStatus(String bookingId) {
    debugPrint('👁️ [watchCheckinStatus] Suscribiendo a cambios en check-in: $bookingId');

    return _client
        .from('checkins')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .map((data) {
          if (data.isEmpty) {
            debugPrint('👁️ [watchCheckinStatus] No hay datos');
            return CheckinStatus.none;
          }

          // Obtener el status del primer registro
          final record = data.first;
          final status = record['status'] as String?;
          debugPrint('👁️ [watchCheckinStatus] Nuevo estado: $status');
          return CheckinStatusExtension.fromDbValue(status);
        })
        .handleError((error) {
          debugPrint('❌ [watchCheckinStatus] Error en stream: $error');
        });
  }
}
