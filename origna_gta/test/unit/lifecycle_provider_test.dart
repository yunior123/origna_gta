import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/lifecycle_provider.dart';

void main() {
  group('appLifecycleProvider', () {
    test('resume transition is false when previous state is null', () {
      expect(isResumeTransition(null, AppLifecycleState.resumed), isFalse);
    });

    test('resume transition is false when next state is not resumed', () {
      expect(
        isResumeTransition(
          AppLifecycleState.paused,
          AppLifecycleState.inactive,
        ),
        isFalse,
      );
    });

    test(
      'resume transition is false when previous state is already resumed',
      () {
        expect(
          isResumeTransition(
            AppLifecycleState.resumed,
            AppLifecycleState.resumed,
          ),
          isFalse,
        );
      },
    );

    test('resume transition is true when returning from paused', () {
      expect(
        isResumeTransition(AppLifecycleState.paused, AppLifecycleState.resumed),
        isTrue,
      );
    });

    test('resume transition is true when returning from hidden', () {
      expect(
        isResumeTransition(AppLifecycleState.hidden, AppLifecycleState.resumed),
        isTrue,
      );
    });

    test('resume transition is true when returning from detached', () {
      expect(
        isResumeTransition(
          AppLifecycleState.detached,
          AppLifecycleState.resumed,
        ),
        isTrue,
      );
    });
  });
}
