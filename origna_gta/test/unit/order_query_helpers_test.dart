import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/repositories/order_query_helpers.dart';
import 'package:origna_gta/models/enum_extensions.dart';
import 'package:origna_gta/models/generated/base_models.dart'
    show PaymentStatus;
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  group('OrderQueryHelpers static methods', () {
    group('paymentStatusToString', () {
      test('maps awaitingPayment', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.awaitingPayment,
          ),
          PaymentStatusValues.awaitingPayment,
        );
      });

      test('maps processing', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.processing,
          ),
          PaymentStatusValues.processing,
        );
      });

      test('maps paid', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(models.PaymentStatus.paid),
          PaymentStatusValues.paid,
        );
      });

      test('maps authorized', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.authorized,
          ),
          PaymentStatusValues.authorized,
        );
      });

      test('maps captured', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.captured,
          ),
          PaymentStatusValues.captured,
        );
      });

      test('maps paymentFailed', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.paymentFailed,
          ),
          PaymentStatusValues.paymentFailed,
        );
      });

      test('maps refunded', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.refunded,
          ),
          PaymentStatusValues.refunded,
        );
      });

      test('maps sessionExpired', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.sessionExpired,
          ),
          PaymentStatusValues.sessionExpired,
        );
      });

      test('maps cancelled', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.cancelled,
          ),
          PaymentStatusValues.cancelled,
        );
      });

      test('maps authorizationExpired', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.authorizationExpired,
          ),
          PaymentStatusValues.authorizationExpired,
        );
      });

      test('maps disputed', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.disputed,
          ),
          PaymentStatusValues.disputed,
        );
      });

      test('maps capturing', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.capturing,
          ),
          PaymentStatusValues.capturing,
        );
      });

      test('maps cancelling', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.cancelling,
          ),
          PaymentStatusValues.cancelling,
        );
      });

      test('maps expiring', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.expiring,
          ),
          PaymentStatusValues.expiring,
        );
      });

      test('maps partiallyRefunded', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.partiallyRefunded,
          ),
          PaymentStatusValues.partiallyRefunded,
        );
      });

      test('maps voided', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(models.PaymentStatus.voided),
          PaymentStatusValues.voided,
        );
      });

      test('maps cancelFailed', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.cancelFailed,
          ),
          PaymentStatusValues.cancelFailed,
        );
      });

      test('all PaymentStatus enum values have a mapping', () {
        final allValues = models.PaymentStatus.values;
        for (final status in allValues) {
          final result = OrderQueryHelpers.paymentStatusToString(status);
          expect(result, isNotEmpty);
          expect(result, isA<String>());
        }
      });

      test('returns underscore format for all statuses', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.awaitingPayment,
          ),
          contains('_'),
        );
        expect(
          OrderQueryHelpers.paymentStatusToString(models.PaymentStatus.paid),
          isNot(contains('_')),
        );
      });
    });

    group('normalizeId', () {
      test('strips collection prefix', () {
        expect(OrderQueryHelpers.normalizeId('orders:abc123'), 'abc123');
      });

      test('returns id as-is when no colon', () {
        expect(OrderQueryHelpers.normalizeId('abc123'), 'abc123');
      });

      test('handles multiple colons by taking last part', () {
        expect(OrderQueryHelpers.normalizeId('a:b:c'), 'c');
      });

      test('handles empty string after colon', () {
        expect(OrderQueryHelpers.normalizeId('orders:'), '');
      });

      test('handles empty string input', () {
        expect(OrderQueryHelpers.normalizeId(''), '');
      });

      test('handles single character input', () {
        expect(OrderQueryHelpers.normalizeId('x'), 'x');
      });

      test('handles UUID-style IDs', () {
        const uuid = '550e8400-e29b-41d4-a716-446655440000';
        expect(OrderQueryHelpers.normalizeId(uuid), uuid);
      });

      test('handles collection:uuid format', () {
        const uuid = '550e8400-e29b-41d4-a716-446655440000';
        expect(OrderQueryHelpers.normalizeId('orders:$uuid'), uuid);
      });

      test('handles numeric IDs', () {
        expect(OrderQueryHelpers.normalizeId('orders:12345'), '12345');
      });

      test('handles IDs with special characters', () {
        expect(
          OrderQueryHelpers.normalizeId('orders:test_id-123'),
          'test_id-123',
        );
      });

      test('handles only colon', () {
        expect(OrderQueryHelpers.normalizeId(':'), '');
      });

      test('handles leading colon', () {
        expect(OrderQueryHelpers.normalizeId(':test'), 'test');
      });
    });

    group('activePaymentStatuses', () {
      test('contains expected statuses', () {
        final statuses = OrderQueryHelpers.activePaymentStatuses;
        expect(statuses, contains(PaymentStatus.authorized.value));
        expect(statuses, contains(PaymentStatus.captured.value));
        expect(statuses, contains(PaymentStatus.disputed.value));
        expect(statuses, contains(PaymentStatus.refunded.value));
        expect(statuses, contains(PaymentStatus.cancelled.value));
        expect(statuses, contains(PaymentStatus.authorizationExpired.value));
      });

      test('has 6 entries', () {
        expect(OrderQueryHelpers.activePaymentStatuses.length, 6);
      });

      test('does not contain awaitingPayment', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.awaitingPayment.value)),
        );
      });

      test('does not contain processing', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.processing.value)),
        );
      });

      test('does not contain paid', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.paid.value)),
        );
      });

      test('does not contain paymentFailed', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.paymentFailed.value)),
        );
      });

      test('does not contain sessionExpired', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.sessionExpired.value)),
        );
      });

      test('is a List<String>', () {
        expect(OrderQueryHelpers.activePaymentStatuses, isA<List<String>>());
      });

      test('all values are valid PaymentStatusValues', () {
        final allValidValues = PaymentStatusValues.all.toSet();
        for (final status in OrderQueryHelpers.activePaymentStatuses) {
          expect(allValidValues, contains(status));
        }
      });

      test('contains no duplicates', () {
        final statuses = OrderQueryHelpers.activePaymentStatuses;
        final uniqueStatuses = statuses.toSet();
        expect(statuses.length, uniqueStatuses.length);
      });
    });
  });
}
