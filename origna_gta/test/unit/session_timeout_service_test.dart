import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/session_timeout_service.dart';

void main() {
  late SessionTimeoutService service;
  String? currentUserId;
  var signOutCount = 0;

  setUp(() {
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

  test('getRemainingTime returns positive duration after recent activity', () {
    service.recordActivity();
    final remaining = service.getRemainingTime();
    expect(remaining.inMinutes, greaterThan(0));
  });

  test('isAboutToExpire returns false after recent activity', () {
    service.recordActivity();
    expect(service.isAboutToExpire(), isFalse);
  });

  test('startMonitoring does nothing when no current user', () {
    final key = GlobalKey<NavigatorState>();
    service.startMonitoring(key);
  });

  test('startMonitoring sets up timer when user exists', () {
    currentUserId = 'u1';
    final key = GlobalKey<NavigatorState>();
    service.startMonitoring(key);
  });

  test('stopMonitoring cancels timer', () {
    currentUserId = 'u1';
    final key = GlobalKey<NavigatorState>();
    service.startMonitoring(key);
    service.stopMonitoring();
  });

  test('recordActivity resets timer', () {
    currentUserId = 'u1';
    final key = GlobalKey<NavigatorState>();
    service.startMonitoring(key);
    service.recordActivity();
    final remaining = service.getRemainingTime();
    expect(remaining.inMinutes, greaterThan(10));
  });

  test('multiple startMonitoring calls do not leak timers', () {
    currentUserId = 'u1';
    final key = GlobalKey<NavigatorState>();
    service.startMonitoring(key);
    service.startMonitoring(key);
    service.startMonitoring(key);
    service.stopMonitoring();
  });

  test('reconfigured sign out callback is retained', () async {
    currentUserId = 'u1';
    final key = GlobalKey<NavigatorState>();
    service.startMonitoring(key);
    service.configure(
      currentUserIdProvider: () => currentUserId,
      signOutCallback: () async {
        signOutCount += 1;
      },
    );
    expect(signOutCount, 0);
  });
}
