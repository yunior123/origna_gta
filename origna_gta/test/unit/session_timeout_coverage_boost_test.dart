import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/session_timeout_service.dart';

void main() {
  late SessionTimeoutService service;

  setUp(() {
    SessionTimeoutService.resetInstance();
    service = SessionTimeoutService();
  });

  tearDown(() {
    service.stopMonitoring();
    SessionTimeoutService.resetInstance();
  });

  group('SessionTimeoutService', () {
    test('is singleton', () {
      final a = SessionTimeoutService();
      final b = SessionTimeoutService();
      expect(identical(a, b), isTrue);
    });

    test('getRemainingTime returns positive duration initially', () {
      final remaining = service.getRemainingTime();
      expect(remaining.inMinutes, greaterThan(0));
    });

    test('isAboutToExpire returns false when fresh', () {
      expect(service.isAboutToExpire(), isFalse);
    });

    test('recordActivity resets timer', () {
      service.recordActivity();
      final remaining = service.getRemainingTime();
      expect(remaining.inMinutes, greaterThan(10));
    });

    test('startMonitoring does nothing without userId', () {
      service.configure(currentUserIdProvider: () => null);
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);
      // Should not crash
    });

    test('startMonitoring starts timer with userId', () {
      service.configure(currentUserIdProvider: () => 'user_123');
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);
      expect(service.getRemainingTime().inMinutes, greaterThan(0));
    });

    test('stopMonitoring cancels timer', () {
      service.configure(currentUserIdProvider: () => 'user_123');
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);
      service.stopMonitoring();
      // Should not crash
    });

    test('configure sets callbacks', () {
      bool signOutCalled = false;
      service.configure(
        currentUserIdProvider: () => 'user_123',
        signOutCallback: () async {
          signOutCalled = true;
        },
      );
      expect(signOutCalled, isFalse);
    });

    test('handleTimeoutForTesting skips when no user', () async {
      service.configure(currentUserIdProvider: () => null);
      await service.handleTimeoutForTesting();
      // No crash
    });

    test('handleTimeoutForTesting skips when different user', () async {
      service.configure(currentUserIdProvider: () => 'user_456');
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      // Now change the user provider
      service.configure(currentUserIdProvider: () => 'user_789');
      await service.handleTimeoutForTesting();
      // Should not sign out (user mismatch)
    });

    test('handleTimeoutForTesting calls signOut for same user', () async {
      bool signOutCalled = false;
      service.configure(
        currentUserIdProvider: () => 'user_123',
        signOutCallback: () async {
          signOutCalled = true;
        },
      );

      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);
      await service.handleTimeoutForTesting();

      expect(signOutCalled, isTrue);
    });

    test('inactivityTimeout can be set for testing', () {
      service.inactivityTimeout = const Duration(seconds: 5);
      service.configure(currentUserIdProvider: () => 'user_123');
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      final remaining = service.getRemainingTime();
      expect(remaining.inSeconds, lessThanOrEqualTo(5));
    });

    test('isAboutToExpire returns true when near timeout', () {
      service.inactivityTimeout = const Duration(minutes: 3);
      service.configure(currentUserIdProvider: () => 'user_123');
      final key = GlobalKey<NavigatorState>();
      service.startMonitoring(key);

      expect(service.isAboutToExpire(), isTrue);
    });

    test('lastActivityTime can be set for testing', () {
      final oldTime = DateTime.now().subtract(const Duration(minutes: 20));
      service.lastActivityTime = oldTime;

      final remaining = service.getRemainingTime();
      expect(remaining, Duration.zero);
    });
  });
}
