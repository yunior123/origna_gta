import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/services/notification_service.dart';

import 'notification_service_test.mocks.dart';

@GenerateMocks([FirebaseMessaging, NotificationSettings])
void main() {
  group('NotificationService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseMessaging mockMessaging;
    late MockNotificationSettings mockSettings;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockMessaging = MockFirebaseMessaging();
      mockSettings = MockNotificationSettings();

      // Ensure instance overrides the messaging platform
      NotificationService.instance.messagingOverride = mockMessaging;
    });

    test('Initializes and saves FCM token on authorized permission', () async {
      const testUid = 'user_123';
      const testToken = 'fake_fcm_token_xyz';

      when(mockSettings.authorizationStatus).thenReturn(AuthorizationStatus.authorized);
      when(
        mockMessaging.requestPermission(
          alert: anyNamed('alert'),
          announcement: anyNamed('announcement'),
          badge: anyNamed('badge'),
          carPlay: anyNamed('carPlay'),
          criticalAlert: anyNamed('criticalAlert'),
          provisional: anyNamed('provisional'),
          sound: anyNamed('sound'),
        ),
      ).thenAnswer((_) async => mockSettings);

      when(mockMessaging.getToken()).thenAnswer((_) async => testToken);
      when(mockMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());

      // Pre-seed a user in FakeFirestore
      await fakeFirestore.collection(Collections.users).doc(testUid).set({Fields.email: 'test@example.com'});

      final container = ProviderContainer(overrides: [userIdProvider.overrideWith((ref) => testUid), firestoreProvider.overrideWithValue(fakeFirestore)]);

      // We explicitly set the container for testing purposes
      // avoiding the need for WidgetRef
      NotificationService.instance.testContainerOverride = container;

      // Call the method to save the token
      await NotificationService.instance.saveTokenToFirestore();

      // Verify it was written to fake firestore
      final userDoc = await fakeFirestore.collection(Collections.users).doc(testUid).get();
      expect(userDoc.exists, true);
      expect(userDoc.data()?[Fields.fcmToken], testToken);
      expect(userDoc.data()?[Fields.fcmTokenUpdatedAt], isA<Timestamp>());
    });
  });
}
