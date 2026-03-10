import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/products/stock_notification_provider.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<Query>(),
  MockSpec<QuerySnapshot>(),
])
import 'stock_notification_notifier_test.mocks.dart';

void main() {
  late MockOrignaBase mockOrignaBase;
  late MockCollectionRef mockCollection;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockSnapshot;
  late ProviderContainer container;

  setUp(() {
    mockOrignaBase = MockOrignaBase();
    mockCollection = MockCollectionRef();
    mockQuery = MockQuery();
    mockSnapshot = MockQuerySnapshot();

    when(mockOrignaBase.collection(any)).thenReturn(mockCollection);
    when(mockCollection.where(any,
      isEqualTo: anyNamed('isEqualTo'),
    )).thenReturn(mockQuery);
    when(mockQuery.where(any,
      isEqualTo: anyNamed('isEqualTo'),
    )).thenReturn(mockQuery);
    when(mockQuery.limit(any)).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

    container = ProviderContainer(
      overrides: [
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        obUserIdProvider.overrideWithValue('user_123'),
        obAuthStateProvider.overrideWith((ref) => Stream.value(
          const AuthState(status: AuthStatus.authenticated, userId: 'user_123'),
        )),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('StockNotificationNotifier Unit Tests', () {
    test('init sets state based on query result', () async {
      when(mockSnapshot.docs).thenReturn([_fakeDoc()]);

      final provider = stockNotificationNotifierProvider((productId: 'prod_123', variantKey: null));
      final sub = container.listen(provider, (_, _) {});

      int count = 0;
      while (container.read(provider).isLoading && count < 20) {
        await Future.delayed(const Duration(milliseconds: 50));
        count++;
      }

      final state = container.read(provider);
      expect(state.value, isTrue);
      sub.close();
    });

    test('subscribe calls backend and updates state', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenAnswer((_) async => {'success': true});

      final provider = stockNotificationNotifierProvider((productId: 'prod_123', variantKey: 'red'));
      final sub = container.listen(provider, (_, _) {});

      while (container.read(provider).isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final notifier = container.read(provider.notifier);
      await notifier.subscribe();

      final state = container.read(provider);
      expect(state.value, isTrue);
      verify(mockOrignaBase.request('POST', '/api/products/stock-notify/subscribe', body: anyNamed('body'))).called(1);
      sub.close();
    });

    test('unsubscribe calls backend and updates state', () async {
      when(mockSnapshot.docs).thenReturn([_fakeDoc()]);
      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenAnswer((_) async => {'success': true});

      final provider = stockNotificationNotifierProvider((productId: 'prod_123', variantKey: null));
      final sub = container.listen(provider, (_, _) {});

      while (container.read(provider).isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final notifier = container.read(provider.notifier);
      await notifier.unsubscribe();

      final state = container.read(provider);
      expect(state.value, isFalse);
      verify(mockOrignaBase.request('POST', '/api/products/stock-notify/unsubscribe', body: anyNamed('body'))).called(1);
      sub.close();
    });
  });
}

/// Fake document for query results.
Document _fakeDoc() => Document(id: 'doc_1', collection: 'test', data: {});
