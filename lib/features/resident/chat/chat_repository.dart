import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/providers.dart';

class ChatRepository {
  final ApiClient api;
  ChatRepository(this.api);

  Future<List<Map<String, dynamic>>> listConversations() async {
    final data = await api.get('/chat/conversations');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> startConversation(int otherUserId) async {
    final data = await api.post('/chat/conversations', data: {'other_user_id': otherUserId});
    return data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listMessages(int conversationId, {int limit = 50, int offset = 0}) async {
    final data = await api.get('/chat/conversations/$conversationId/messages', query: {'limit': limit, 'offset': offset});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String body) async {
    final data = await api.post('/chat/conversations/$conversationId/messages', data: {'body': body});
    return data as Map<String, dynamic>;
  }

  Future<void> markRead(int conversationId) async {
    await api.post('/chat/conversations/$conversationId/read');
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository(ref.watch(apiClientProvider)));
