import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils/circuit_breaker.dart';

void main() {
  group('CircuitBreakerConfig', () {
    group('defaults', () {
      test('default config has sensible values', () {
        const config = CircuitBreakerConfig();
        expect(config.failureThreshold, 5);
        expect(config.resetTimeout, const Duration(seconds: 30));
        expect(config.halfOpenTimeout, const Duration(seconds: 5));
        expect(config.successThreshold, 3);
      });
    });

    group('paymentDefault', () {
      test('has lower failure threshold for payment services', () {
        const config = CircuitBreakerConfig.paymentDefault;
        expect(config.failureThreshold, 3);
        expect(config.resetTimeout, const Duration(seconds: 30));
        expect(config.successThreshold, 2);
      });
    });

    group('searchDefault', () {
      test('has higher thresholds for search services', () {
        const config = CircuitBreakerConfig.searchDefault;
        expect(config.failureThreshold, 5);
        expect(config.resetTimeout, const Duration(seconds: 60));
        expect(config.halfOpenTimeout, const Duration(seconds: 10));
        expect(config.successThreshold, 3);
      });
    });

    group('lenientDefault', () {
      test('has highest thresholds for non-critical services', () {
        const config = CircuitBreakerConfig.lenientDefault;
        expect(config.failureThreshold, 10);
        expect(config.resetTimeout, const Duration(minutes: 2));
        expect(config.halfOpenTimeout, const Duration(seconds: 15));
        expect(config.successThreshold, 2);
      });
    });

    group('custom config', () {
      test('allows custom values', () {
        const config = CircuitBreakerConfig(
          failureThreshold: 20,
          resetTimeout: Duration(minutes: 5),
          halfOpenTimeout: Duration(seconds: 30),
          successThreshold: 5,
        );
        expect(config.failureThreshold, 20);
        expect(config.resetTimeout, const Duration(minutes: 5));
        expect(config.halfOpenTimeout, const Duration(seconds: 30));
        expect(config.successThreshold, 5);
      });
    });
  });

  group('CircuitState', () {
    test('has exactly 3 states', () {
      expect(CircuitState.values.length, 3);
    });

    test('contains expected states', () {
      expect(CircuitState.values, contains(CircuitState.closed));
      expect(CircuitState.values, contains(CircuitState.open));
      expect(CircuitState.values, contains(CircuitState.halfOpen));
    });

    test('state names are lowercase', () {
      expect(CircuitState.closed.name, 'closed');
      expect(CircuitState.open.name, 'open');
      expect(CircuitState.halfOpen.name, 'halfOpen');
    });
  });

  group('CircuitBreakerMetrics', () {
    test('toMap returns correct structure', () {
      final now = DateTime.now();
      final metrics = CircuitBreakerMetrics(
        state: CircuitState.halfOpen,
        failureCount: 3,
        successCount: 2,
        lastFailureTime: now,
        secondsUntilRetry: 45,
      );

      final json = metrics.toJson();
      expect(json['state'], 'halfOpen');
      expect(json['failureCount'], 3);
      expect(json['successCount'], 2);
      expect(json['lastFailureTime'], now.toIso8601String());
      expect(json['secondsUntilRetry'], 45);
    });

    test('handles null lastFailureTime', () {
      final metrics = CircuitBreakerMetrics(
        state: CircuitState.closed,
        failureCount: 0,
        successCount: 0,
        lastFailureTime: null,
        secondsUntilRetry: 0,
      );

      final json = metrics.toJson();
      expect(json['lastFailureTime'], isNull);
    });

    test('all states are serializable', () {
      for (final state in CircuitState.values) {
        final metrics = CircuitBreakerMetrics(
          state: state,
          failureCount: 0,
          successCount: 0,
          lastFailureTime: null,
          secondsUntilRetry: 0,
        );
        final json = metrics.toJson();
        expect(json['state'], state.name);
      }
    });
  });

  group('CircuitBreakerOpenException', () {
    test('includes service name in message', () {
      final exception = CircuitBreakerOpenException(
        serviceName: 'stripe',
        retryAfter: const Duration(seconds: 30),
      );
      expect(exception.toString(), contains('stripe'));
    });

    test('includes retry time in message', () {
      final exception = CircuitBreakerOpenException(
        serviceName: 'test',
        retryAfter: const Duration(seconds: 45),
      );
      expect(exception.toString(), contains('45s'));
    });

    test('stores service name', () {
      final exception = CircuitBreakerOpenException(
        serviceName: 'meilisearch',
        retryAfter: Duration.zero,
      );
      expect(exception.serviceName, 'meilisearch');
    });

    test('stores retryAfter', () {
      final exception = CircuitBreakerOpenException(
        serviceName: 'test',
        retryAfter: const Duration(minutes: 2),
      );
      expect(exception.retryAfter, const Duration(minutes: 2));
    });

    test('handles zero retry duration', () {
      final exception = CircuitBreakerOpenException(
        serviceName: 'test',
        retryAfter: Duration.zero,
      );
      expect(exception.retryAfter, Duration.zero);
      expect(exception.toString(), contains('0s'));
    });
  });

  group('CircuitBreaker', () {
    group('initialization', () {
      test('starts in closed state', () {
        final breaker = CircuitBreaker(name: 'test');
        expect(breaker.state, CircuitState.closed);
        expect(breaker.isClosed, isTrue);
        expect(breaker.isOpen, isFalse);
      });

      test('accepts custom config', () {
        final breaker = CircuitBreaker(
          name: 'test',
          config: const CircuitBreakerConfig(failureThreshold: 10),
        );
        expect(breaker.config.failureThreshold, 10);
      });

      test('uses default config when not provided', () {
        final breaker = CircuitBreaker(name: 'test');
        expect(breaker.config, const CircuitBreakerConfig());
      });
    });

    group('reset', () {
      test('resets to closed state', () async {
        final breaker = CircuitBreaker(
          name: 'test',
          config: const CircuitBreakerConfig(failureThreshold: 1),
        );

        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}

        expect(breaker.isOpen, isTrue);
        breaker.reset();
        expect(breaker.isClosed, isTrue);
      });

      test('clears failure count', () async {
        final breaker = CircuitBreaker(
          name: 'test',
          config: const CircuitBreakerConfig(failureThreshold: 5),
        );

        for (var i = 0; i < 3; i++) {
          try {
            await breaker.execute(() async => throw Exception('fail'));
          } catch (_) {}
        }

        var metrics = breaker.getMetrics();
        expect(metrics.failureCount, 3);

        breaker.reset();
        metrics = breaker.getMetrics();
        expect(metrics.failureCount, 0);
      });

      test('clears lastFailureTime', () async {
        final breaker = CircuitBreaker(
          name: 'test',
          config: const CircuitBreakerConfig(failureThreshold: 1),
        );

        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}

        breaker.reset();
        final metrics = breaker.getMetrics();
        expect(metrics.lastFailureTime, isNull);
      });
    });

    group('getMetrics', () {
      test('returns current state', () {
        final breaker = CircuitBreaker(name: 'test');
        final metrics = breaker.getMetrics();
        expect(metrics.state, CircuitState.closed);
      });

      test('tracks failures', () async {
        final breaker = CircuitBreaker(
          name: 'test',
          config: const CircuitBreakerConfig(failureThreshold: 5),
        );

        for (var i = 0; i < 3; i++) {
          try {
            await breaker.execute(() async => throw Exception('fail'));
          } catch (_) {}
        }

        final metrics = breaker.getMetrics();
        expect(metrics.failureCount, 3);
      });

      test('tracks success count in halfOpen', () async {
        final breaker = CircuitBreaker(
          name: 'test',
          config: const CircuitBreakerConfig(
            failureThreshold: 1,
            resetTimeout: Duration(milliseconds: 10),
            successThreshold: 3,
          ),
        );

        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 20));

        await breaker.execute(() async => 'success');
        final metrics = breaker.getMetrics();
        expect(metrics.successCount, 1);
      });
    });
  });

  group('CircuitBreakerRegistry', () {
    setUp(() {
      CircuitBreakerRegistry.clear();
    });

    tearDown(() {
      CircuitBreakerRegistry.clear();
    });

    test('returns same instance for same name', () {
      final breaker1 = CircuitBreakerRegistry.get('test');
      final breaker2 = CircuitBreakerRegistry.get('test');
      expect(identical(breaker1, breaker2), isTrue);
    });

    test('returns different instances for different names', () {
      final breaker1 = CircuitBreakerRegistry.get('test1');
      final breaker2 = CircuitBreakerRegistry.get('test2');
      expect(identical(breaker1, breaker2), isFalse);
    });

    test('uses custom config on first get', () {
      final breaker = CircuitBreakerRegistry.get(
        'custom',
        config: const CircuitBreakerConfig(failureThreshold: 99),
      );
      expect(breaker.config.failureThreshold, 99);
    });

    test('ignores config on subsequent gets', () {
      CircuitBreakerRegistry.get(
        'test',
        config: const CircuitBreakerConfig(failureThreshold: 50),
      );

      final breaker = CircuitBreakerRegistry.get(
        'test',
        config: const CircuitBreakerConfig(failureThreshold: 10),
      );
      expect(breaker.config.failureThreshold, 50);
    });

    test('getAllMetrics returns all registered breakers', () {
      CircuitBreakerRegistry.get('b1');
      CircuitBreakerRegistry.get('b2');
      CircuitBreakerRegistry.get('b3');

      final allMetrics = CircuitBreakerRegistry.getAllMetrics();
      expect(allMetrics.length, 3);
      expect(allMetrics.keys, containsAll(['b1', 'b2', 'b3']));
    });

    test('resetAll resets all breakers', () async {
      final b1 = CircuitBreakerRegistry.get(
        'b1',
        config: const CircuitBreakerConfig(failureThreshold: 1),
      );
      final b2 = CircuitBreakerRegistry.get(
        'b2',
        config: const CircuitBreakerConfig(failureThreshold: 1),
      );

      try {
        await b1.execute(() async => throw Exception('fail'));
      } catch (_) {}
      try {
        await b2.execute(() async => throw Exception('fail'));
      } catch (_) {}

      expect(b1.isOpen, isTrue);
      expect(b2.isOpen, isTrue);

      CircuitBreakerRegistry.resetAll();

      expect(b1.isClosed, isTrue);
      expect(b2.isClosed, isTrue);
    });

    test('clear removes all breakers', () {
      CircuitBreakerRegistry.get('b1');
      CircuitBreakerRegistry.get('b2');

      CircuitBreakerRegistry.clear();

      final allMetrics = CircuitBreakerRegistry.getAllMetrics();
      expect(allMetrics, isEmpty);
    });

    test('creates new instance after clear', () {
      final original = CircuitBreakerRegistry.get('test');
      CircuitBreakerRegistry.clear();
      final newBreaker = CircuitBreakerRegistry.get('test');
      expect(identical(original, newBreaker), isFalse);
    });
  });
}
