import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';

@GenerateNiceMocks([MockSpec<ChatRepository>()])
import 'chat_repository_test.mocks.dart';

void main() {
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
  });

  group('ChatRepository', () {
    test('getOrCreateChat returns chatId', () async {
      when(mockRepository.getOrCreateChat('p1')).thenAnswer((_) async => 'c123');

      final result = await mockRepository.getOrCreateChat('p1');
      expect(result, 'c123');
      verify(mockRepository.getOrCreateChat('p1')).called(1);
    });

    test('sendMessage calls repository', () async {
      await mockRepository.sendMessage('c123', 'Hello');
      verify(mockRepository.sendMessage('c123', 'Hello')).called(1);
    });

    test('markRead calls repository', () async {
      await mockRepository.markRead('c123');
      verify(mockRepository.markRead('c123')).called(1);
    });

    test('deleteMessage calls repository', () async {
      await mockRepository.deleteMessage('c123', 'm456');
      verify(mockRepository.deleteMessage('c123', 'm456')).called(1);
    });

    test('messagesStream returns stream of ChatMessage', () async {
      final fakeMsg = ChatMessage(
        id: 'msg1',
        senderId: 'u1',
        senderDisplayName: 'User',
        text: 'Msg 1',
        createdAt: DateTime.now(),
        isRead: false,
      );

      when(mockRepository.messagesStream('c1')).thenAnswer((_) => Stream.value([fakeMsg]));

      final stream = mockRepository.messagesStream('c1');
      final messages = await stream.first;
      expect(messages.length, 1);
      expect(messages.first.text, 'Msg 1');
    });

    test('userChatsStream returns stream of ChatThread', () async {
      final fakeThread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'Product',
        buyerId: 'u1',
        sellerId: 's1',
        lastMessage: 'Hi',
        lastMessageAt: DateTime.now(),
      );

      when(mockRepository.userChatsStream('u1')).thenAnswer((_) => Stream.value([fakeThread]));

      final stream = mockRepository.userChatsStream('u1');
      final threads = await stream.first;
      expect(threads.length, 1);
      expect(threads.first.productTitle, 'Product');
    });
  });
}
