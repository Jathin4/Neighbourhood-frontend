import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/providers.dart';

class ResidentRepository {
  final ApiClient api;
  ResidentRepository(this.api);

  Future<Map<String, dynamic>> getDashboard() async => await api.get('/residents/me/dashboard') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listNotices({int limit = 20, int offset = 0}) async {
    final data = await api.get('/notices', query: {'limit': limit, 'offset': offset});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> markNoticeRead(int noticeId) async => api.post('/notices/$noticeId/read');

  Future<List<Map<String, dynamic>>> listMyIssues({int limit = 20, int offset = 0}) async {
    final data = await api.get('/issues/mine', query: {'limit': limit, 'offset': offset});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getIssueDetail(String ticketNo) async => await api.get('/issues/$ticketNo') as Map<String, dynamic>;

  Future<Map<String, dynamic>> createIssue({
    required int communityId,
    required String category,
    required String description,
    String? location,
    String urgency = 'Normal',
  }) async {
    final data = await api.post('/issues', data: {
      'community_id': communityId,
      'category': category,
      'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      'urgency': urgency,
    });
    return data as Map<String, dynamic>;
  }

  Future<void> reopenIssue(int issueId, String reason) async => api.post('/issues/$issueId/reopen', data: {'reason': reason});

  Future<void> addIssueComment(int issueId, String comment) async => api.post('/issues/$issueId/comments', data: {'comment': comment});

  Future<List<Map<String, dynamic>>> searchDirectory({String? query, int limit = 30}) async {
    final data = await api.get('/directory', query: {if (query != null && query.isNotEmpty) 'query': query, 'limit': limit});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> updatePrivacy({bool? phoneVisible, bool? emailVisible}) async {
    await api.patch('/residents/me/privacy', data: {
      if (phoneVisible != null) 'phone_visible': phoneVisible,
      if (emailVisible != null) 'email_visible': emailVisible,
    });
  }
}

final residentRepositoryProvider = Provider<ResidentRepository>((ref) => ResidentRepository(ref.watch(apiClientProvider)));
