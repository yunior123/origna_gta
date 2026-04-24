import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/services/error_event_service.dart';

void main() {
  group('ErrorEventService.buildPayload', () {
    test('builds a support-grade payload with identifiers, auth context, and metadata', () {
      final payload = ErrorEventService.buildPayload(
        error: StateError('login failed'),
        userFacingCode: 'ORIGNA-AUTH-011',
        userFacingMessage: 'Invalid email or password [ORIGNA-AUTH-011]',
        environment: 'dev',
        sentryEventId: 'abc123',
        stackTrace: StackTrace.current,
        context: 'auth.login',
        userId: 'user-123',
        email: 'qa@origna.ca',
        extras: <String, dynamic>{
          'contactEmail': 'qa@origna.ca',
          'contactName': 'QA User',
          'reproSteps': <String>['open login', 'submit bad password'],
          'bugDescription': 'Server failed while user attempted login',
        },
      );

      expect(payload[Fields.internalEventId], startsWith('SE-'));
      expect(payload[Fields.errorCode], 'ORIGNA-AUTH-011');
      expect(payload[Fields.sentryEventId], 'abc123');
      expect(payload[Fields.routeOrAction], 'auth.login');
      expect(payload[Fields.userId], 'user-123');
      expect(payload[Fields.email], 'qa@origna.ca');
      expect(payload[Fields.createdAt], isA<FieldValue>());

      final metadata = payload[Fields.metadata] as Map<String, dynamic>;
      expect(metadata['contactEmail'], 'qa@origna.ca');
      expect(metadata['contactName'], 'QA User');
      expect(metadata['bugDescription'], contains('user attempted login'));
      expect(metadata['reproSteps'], <String>['open login', 'submit bad password']);
      expect(metadata['capturedAtUtc'], isA<String>());
      expect(metadata['platform'], isA<String>());
      expect(metadata['buildMode'], isA<String>());
      expect(metadata['isWeb'], isA<bool>());
    });

    test('truncates oversized message and stack trace fields', () {
      final hugeMessage = 'x' * 5000;
      final hugeStack = StackTrace.fromString('y' * 13000);

      final payload = ErrorEventService.buildPayload(
        error: Exception(hugeMessage),
        userFacingCode: null,
        userFacingMessage: 'fallback',
        environment: 'test',
        stackTrace: hugeStack,
      );

      expect((payload[Fields.errorMessage] as String).length, lessThanOrEqualTo(4003));
      expect((payload[Fields.stackTrace] as String).length, lessThanOrEqualTo(12003));
      expect(payload[Fields.errorCode], 'ORIGNA-SYS-999');
    });
  });
}
