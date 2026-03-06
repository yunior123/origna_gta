import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFunctions>(),
  MockSpec<HttpsCallable>(),
  MockSpec<HttpsCallableResult>()
])
import 'chat_repository_test.mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late ChatRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
    
    repository = ChatRepository(fakeFirestore, mockFunctions);
  });

  group('ChatRepository', () {
    test('messagesStream returns messages', () async {
      final chatId = 'chat_123';
      await fakeFirestore
          .collection(Collections.chats)
          .doc(chatId)
          .collection(Collections.chatMessages)
          .doc('m1')
          .set({
        Fields.senderId: 'u1',
        Fields.senderDisplayName: 'User 1',
        Fields.messageText: 'Hello',
        Fields.createdAt: Timestamp.now(),
        Fields.isRead: false,
      });

      final stream = repository.messagesStream(chatId);
      final list = await stream.first;

      expect(list.length, 1);
      expect(list.first.text, 'Hello');
    });

    test('getOrCreateChat calls cloud function', () async {
      when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({Fields.chatId: 'new_chat_123'});

      final result = await repository.getOrCreateChat('prod_123');

      expect(result, 'new_chat_123');
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.getOrCreateChat)).called(1);
    });

    test('sendMessage calls cloud function', () async {
      when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      await repository.sendMessage('chat_123', 'Hello world');

      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.sendMessage)).called(1);
      verify(mockCallable.call({
        Fields.chatId: 'chat_123',
        Fields.messageText: 'Hello world',
      })).called(1);
    });
  });
}
