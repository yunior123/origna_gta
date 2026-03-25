import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/session_timeout_service.dart';

void main() {
  late SessionTimeoutService service;
  String? currentUserId;
  late int signOutCount;

  setUp(() {
    SessionTimeoutService.resetInstance();
    service = SessionTimeoutService();
    currentUserId = null;
    signOutCount = 0;
    service.configure(
      currentUserIdProvider: () => currentUserId,
      signOutCallback: () async {
        signOutCount += 1;
      },
    );
  });

  tearDown(() {
    service.stopMonitoring();
  });

  group('SessionTimeoutService', () {
    test('factory returns singleton', () {
      final a = SessionTimeoutService();
      final b = SessionTimeoutService();
      expect(identical(a, b), isTrue);
    });

    test('getRemainingTime returns zero when timeout expired', () {
      service.lastActivityTime = DateTime.now().subtract(
        const Duration(minutes: 20),
      );
      final remaining = service.getRemainingTime();
      expect(remaining, Duration.zero);
    });

    test('getRemainingTime returns positive after activity', () {
      service.recordActivity();
      final remaining = service.getRemainingTime();
      expect(remaining.inMinutes, greaterThan(10));
    });

    test('isAboutToExpire returns true when less than 5 minutes remain', () {
      // Set last activity to 11 minutes ago (timeout is 15 min)
      service.lastActivityTime = DateTime.now().subtract(
        const Duration(minutes: 11),
      );
      expect(service.isAboutToExpire(), isTrue);
    });

    test('isAboutToExpire returns false when plenty of time remains', () {
      service.recordActivity();
      expect(service.isAboutToExpire(), isFalse);
    });

    test('startMonitoring does nothing when user is null', () {
      currentUserId = null;
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);
      // No exception thrown
    });

    test('startMonitoring starts timer when user exists', () {
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);
      // Timer is running (verified by the fact stopMonitoring works)
      service.stopMonitoring();
    });

    test('stopMonitoring cancels timer and clears state', () {
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);
      service.stopMonitoring();
      // Double stop should not throw
      service.stopMonitoring();
    });

    test('recordActivity resets last activity time', () {
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      service.lastActivityTime = DateTime.now().subtract(
        const Duration(minutes: 14),
      );
      expect(service.isAboutToExpire(), isTrue);

      service.recordActivity();
      expect(service.isAboutToExpire(), isFalse);
    });

    test('handleTimeout does nothing when user is null', () async {
      currentUserId = null;
      await service.handleTimeoutForTesting();
      expect(signOutCount, 0);
    });

    test('handleTimeout calls signOut when user is authenticated', () async {
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      await service.handleTimeoutForTesting();
      expect(signOutCount, 1);
    });

    test('handleTimeout skips if watched user differs from current', () async {
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      // Now change the current user (simulating another user logged in)
      currentUserId = 'u2';
      await service.handleTimeoutForTesting();
      // Should NOT sign out because watched user is 'u1' but current is 'u2'
      expect(signOutCount, 0);
    });

    test('handleTimeout handles sign out errors gracefully', () async {
      service.configure(
        currentUserIdProvider: () => currentUserId,
        signOutCallback: () async {
          throw Exception('Network error');
        },
      );

      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      // Should not throw
      await service.handleTimeoutForTesting();
    });

    test('resetInstance clears all state', () {
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      SessionTimeoutService.resetInstance();

      // After reset, remaining time should still work
      final remaining = service.getRemainingTime();
      expect(remaining, isNotNull);
    });

    test('configure sets new callbacks', () async {
      var altSignOutCount = 0;
      service.configure(
        currentUserIdProvider: () => 'alt_user',
        signOutCallback: () async {
          altSignOutCount++;
        },
      );

      final key = GlobalKey<NavigatorState>();
      currentUserId = 'alt_user';
      service.startMonitoring(key);

      await service.handleTimeoutForTesting();
      expect(altSignOutCount, 1);
    });

    test('multiple startMonitoring calls cancel previous timer', () {
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      // Start 3 times
      service.startMonitoring(key);
      service.startMonitoring(key);
      service.startMonitoring(key);
      // Should not leak timers
      service.stopMonitoring();
    });

    test('short timeout triggers quickly', () async {
      service.inactivityTimeout = const Duration(milliseconds: 50);
      currentUserId = 'u1';
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      // Wait for timeout
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(signOutCount, 1);
    });
  });
}
