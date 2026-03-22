import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';

void main() {
  group('WarehousesState', () {
    test('default state has empty warehouses and not loading', () {
      const state = WarehousesState();
      expect(state.warehouses, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates warehouses', () {
      const state = WarehousesState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.warehouses, isEmpty);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith updates errorMessage', () {
      const state = WarehousesState();
      final updated = state.copyWith(errorMessage: 'Something went wrong');
      expect(updated.errorMessage, 'Something went wrong');
    });

    test('copyWith preserves values when not specified', () {
      final state = WarehousesState(
        isLoading: true,
        isSuccess: true,
        errorMessage: 'old error',
      );
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
      expect(updated.isSuccess, isTrue);
      expect(updated.errorMessage, 'old error');
    });

    test('copyWith clears errorMessage when null passed', () {
      final state = WarehousesState(errorMessage: 'error');
      final updated = state.copyWith(errorMessage: null);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith updates isSuccess', () {
      const state = WarehousesState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });

    test('state equality works correctly', () {
      const state1 = WarehousesState(isLoading: true, isSuccess: false);
      const state2 = WarehousesState(isLoading: true, isSuccess: false);
      const state3 = WarehousesState(isLoading: false, isSuccess: true);

      expect(state1.isLoading, equals(state2.isLoading));
      expect(state1.isSuccess, equals(state2.isSuccess));
      expect(state1.isLoading, isNot(equals(state3.isLoading)));
    });

    test('copyWith with errorMessage preserves other fields', () {
      final state = WarehousesState(
        warehouses: [],
        isLoading: true,
        isSuccess: false,
      );
      final updated = state.copyWith(errorMessage: 'test error');
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isFalse);
      expect(updated.errorMessage, 'test error');
    });
  });
}
