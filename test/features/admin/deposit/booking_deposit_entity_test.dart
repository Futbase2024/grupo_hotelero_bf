import 'package:bf_stay/core/enums/enums.dart';
import 'package:bf_stay/features/admin/dashboard/presentation/widgets/checkins/checkin_list_tile.dart';
import 'package:bf_stay/features/admin/dashboard/presentation/widgets/checkins/checkin_status_style.dart';
import 'package:bf_stay/features/admin/domain/entities/admin_entities.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _depositJson({
  String depositStatus = 'none',
  Object? checkins = const {'status': 'submitted'},
  Object? properties = const {'name': 'Casa BF', 'default_deposit_cents': 20000},
}) {
  return {
    'id': 'booking-1',
    'booking_code': 'BF-123',
    'property_id': 'property-1',
    'guest_first_name': 'Ana',
    'last_name': 'García',
    'guest_email': 'ana@example.com',
    'guest_phone': '',
    'primary_guest_user_id': null,
    'deposit_status': depositStatus,
    'deposit_amount_cents': depositStatus == 'none' ? null : 15000,
    'deposit_payment_link': 'https://pasarela.test/pago',
    'deposit_sent_via': ['chat', 'whatsapp'],
    'deposit_requested_at': '2026-10-19T10:00:00Z',
    'properties': properties,
    'checkins': checkins,
  };
}

AdminBookingEntity _booking({
  String? checkinStatus,
  String? checkinId = 'checkin-1',
  DepositStatus depositStatus = DepositStatus.none,
}) {
  return AdminBookingEntity.empty().copyWith(
    id: 'booking-1',
    checkinId: checkinId,
    checkinStatus: checkinStatus,
    depositStatus: depositStatus,
  );
}

void main() {
  group('DepositStatus.fromString', () {
    test('convierte los valores de BD y usa none por defecto', () {
      expect(DepositStatus.fromString('pending'), DepositStatus.pending);
      expect(DepositStatus.fromString('PAID'), DepositStatus.paid);
      expect(DepositStatus.fromString('returned'), DepositStatus.returned);
      expect(DepositStatus.fromString(null), DepositStatus.none);
      expect(DepositStatus.fromString('otro'), DepositStatus.none);
    });

    test('solo pending bloquea la validación', () {
      expect(
        DepositStatus.values.where((status) => status.isPending),
        [DepositStatus.pending],
      );
    });
  });

  group('BookingDepositEntity.fromJson', () {
    test('lee la fianza, el importe sugerido y el estado del check-in', () {
      final deposit = BookingDepositEntity.fromJson(
        _depositJson(depositStatus: 'pending'),
      );

      expect(deposit.status, DepositStatus.pending);
      expect(deposit.amountCents, 15000);
      expect(deposit.suggestedAmountCents, 20000);
      expect(deposit.propertyName, 'Casa BF');
      expect(deposit.guestName, 'Ana García');
      expect(deposit.checkinStatus, 'submitted');
      expect(deposit.sentVia, ['chat', 'whatsapp']);
      expect(deposit.requestedAt, DateTime.utc(2026, 10, 19, 10));
    });

    test('acepta las relaciones embebidas como lista', () {
      final deposit = BookingDepositEntity.fromJson(
        _depositJson(
          checkins: const [
            {'status': 'validated'},
          ],
          properties: const [
            {'name': 'Casa BF', 'default_deposit_cents': null},
          ],
        ),
      );

      expect(deposit.checkinStatus, 'validated');
      expect(deposit.suggestedAmountCents, isNull);
    });

    test('sin check-in ni alojamiento no falla', () {
      final deposit = BookingDepositEntity.fromJson(
        _depositJson(checkins: null, properties: const []),
      );

      expect(deposit.checkinStatus, isNull);
      expect(deposit.propertyName, '');
    });

    test('detecta los canales disponibles', () {
      final deposit = BookingDepositEntity.fromJson(_depositJson());

      expect(deposit.hasGuestEmail, isTrue);
      expect(deposit.hasGuestPhone, isFalse);
      expect(deposit.hasGuestAppUser, isFalse);
    });
  });

  group('BookingDepositEntity reglas', () {
    test('solo se puede pedir si no hay fianza y el check-in sigue abierto', () {
      BookingDepositEntity build(String status, String? checkinStatus) =>
          BookingDepositEntity.fromJson(
            _depositJson(
              depositStatus: status,
              checkins: checkinStatus == null ? null : {'status': checkinStatus},
            ),
          );

      expect(build('none', null).canRequest, isTrue);
      expect(build('none', 'submitted').canRequest, isTrue);
      expect(build('none', 'rejected').canRequest, isTrue);
      expect(build('none', 'validated').canRequest, isFalse);
      expect(build('none', 'cancelled').canRequest, isFalse);
      expect(build('pending', 'submitted').canRequest, isFalse);
    });

    test('confirmar el pago solo valida si el check-in está enviado', () {
      BookingDepositEntity build(String checkinStatus) =>
          BookingDepositEntity.fromJson(
            _depositJson(
              depositStatus: 'pending',
              checkins: {'status': checkinStatus},
            ),
          );

      expect(build('submitted').willValidateOnConfirm, isTrue);
      expect(build('in_progress').willValidateOnConfirm, isFalse);
    });
  });

  group('Listado de check-ins con fianza', () {
    test('la fianza pendiente prevalece sobre el estado del check-in', () {
      final booking = _booking(
        checkinStatus: 'submitted',
        depositStatus: DepositStatus.pending,
      );

      expect(booking.isAwaitingDeposit, isTrue);
      expect(
        CheckinStatusStyle.forBooking(booking),
        CheckinStatusStyle.awaitingDeposit,
      );
    });

    test('sin fianza o ya validado se usa el estado del check-in', () {
      expect(
        CheckinStatusStyle.forBooking(_booking(checkinStatus: 'submitted')),
        CheckinStatusStyle.submitted,
      );
      expect(
        CheckinStatusStyle.forBooking(
          _booking(
            checkinStatus: 'validated',
            depositStatus: DepositStatus.paid,
          ),
        ),
        CheckinStatusStyle.validated,
      );
    });

    test('el estado de fianza no se cuela en los filtros ni en fromStatus', () {
      expect(CheckinStatusStyle.awaitingDeposit.status, isNull);
      expect(CheckinStatusStyle.fromStatus(null), CheckinStatusStyle.notStarted);
    });

    test('con fianza pendiente no se ofrece el check-in manual', () {
      expect(
        CheckinListTile.canDoManualCheckin(
          _booking(checkinStatus: 'in_progress'),
        ),
        isTrue,
      );
      expect(
        CheckinListTile.canDoManualCheckin(
          _booking(
            checkinStatus: 'in_progress',
            depositStatus: DepositStatus.pending,
          ),
        ),
        isFalse,
      );
    });

    test('AdminBookingEntity lee deposit_status del listado', () {
      final booking = AdminBookingEntity.fromJson({
        'id': 'booking-1',
        'checkin_status': 'submitted',
        'deposit_status': 'pending',
      });

      expect(booking.depositStatus, DepositStatus.pending);
      expect(booking.toJson()['deposit_status'], 'pending');
    });
  });
}
