import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/providers.dart';

class AdminRepository {
  final ApiClient api;
  AdminRepository(this.api);

  Future<List<Map<String, dynamic>>> listCommunities() async {
    final data = await api.get('/admin/communities');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCommunity({required String name, required String city}) async =>
      await api.post('/admin/communities', data: {'name': name, 'city': city}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateCommunity(int communityId, {required String name, required String city}) async =>
      await api.patch('/admin/communities/$communityId', data: {'name': name, 'city': city}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listTowers(int communityId) async {
    final data = await api.get('/admin/communities/$communityId/towers');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTower(int communityId, String name) async =>
      await api.post('/admin/towers', data: {'community_id': communityId, 'name': name}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createUnit(int towerId, String name) async =>
      await api.post('/admin/units', data: {'tower_id': towerId, 'name': name}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listUnits(int towerId) async {
    final data = await api.get('/admin/towers/$towerId/units');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> bulkImportResidents(int communityId, List<Map<String, dynamic>> rows) async =>
      await api.post('/admin/communities/$communityId/residents/bulk-import', data: {'rows': rows}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> searchResidents(int communityId, {String? query}) async {
    final data = await api.get('/admin/communities/$communityId/residents', query: {if (query != null) 'query': query});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listMembershipRequests(int communityId, {String? status}) async {
    final data = await api.get('/admin/membership-requests', query: {'community_id': communityId, if (status != null) 'status': status});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> decideMembershipRequest(int requestId, {required String status, String? reason}) async =>
      await api.patch('/admin/membership-requests/$requestId', data: {'status': status, if (reason != null) 'reason': reason}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> assignCommitteeRole(int communityId, int targetUserId, List<String> capabilities) async =>
      await api.post('/admin/committee-roles', data: {'community_id': communityId, 'target_user_id': targetUserId, 'capabilities': capabilities}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listIssues(int communityId, {String? status}) async {
    final data = await api.get('/admin/issues', query: {'community_id': communityId, if (status != null) 'status': status});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> assignIssue(int issueId, int ownerId, {String? note}) async =>
      await api.patch('/issues/$issueId/assign', data: {'owner_id': ownerId, if (note != null) 'note': note}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> transitionIssueStatus(int issueId, String status, {String? note}) async =>
      await api.patch('/issues/$issueId/status', data: {'status': status, if (note != null) 'note': note}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createNotice({
    required int communityId,
    required String title,
    required String content,
    required String priority,
    required String audienceType,
    String? expiryAt,
  }) async =>
      await api.post('/notices', data: {
        'community_id': communityId,
        'title': title,
        'content': content,
        'priority': priority,
        'audience_type': audienceType,
        if (expiryAt != null) 'expiry_at': expiryAt,
      }) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createPoll({
    required int communityId,
    required String question,
    required List<Map<String, String>> options,
    required String endAt,
    bool isAnonymous = false,
  }) async =>
      await api.post('/polls', data: {
        'community_id': communityId,
        'question': question,
        'options': options,
        'end_at': endAt,
        'is_anonymous': isAnonymous,
      }) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createEvent({
    required int communityId,
    required String title,
    required String dateTime,
    String? location,
    int? capacity,
  }) async =>
      await api.post('/events', data: {
        'community_id': communityId,
        'title': title,
        'date_time': dateTime,
        if (location != null) 'location': location,
        if (capacity != null) 'capacity': capacity,
      }) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> providerVerificationQueue({String states = 'Submitted,UnderReview'}) async {
    final data = await api.get('/admin/providers/verification-queue', query: {'states': states});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateProviderVerification(int providerId, String newState, {String? reason}) async =>
      await api.patch('/admin/providers/$providerId/verification', data: {'new_state': newState, if (reason != null) 'reason': reason}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createProvider({
    required String phone,
    required String businessName,
    required List<String> categories,
    required int communityId,
    bool autoVerify = true,
  }) async =>
      await api.post('/admin/providers', data: {
        'phone': phone,
        'business_name': businessName,
        'categories': categories,
        'community_id': communityId,
        'auto_verify': autoVerify,
      }) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listCommunityProviderRequests(int communityId, {String status = 'Pending'}) async {
    final data = await api.get('/admin/providers/community-requests', query: {'community_id': communityId, 'status': status});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> decideCommunityProviderRequest(int requestId, String newStatus, {String? note}) async =>
      await api.patch('/admin/providers/community-requests/$requestId', data: {'new_status': newStatus, if (note != null) 'note': note}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listCuratedProviders(int communityId) async {
    final data = await api.get('/admin/providers/curated', query: {'community_id': communityId});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> curateProvider(int communityId, int providerId, {String label = 'preferred'}) async =>
      await api.post('/admin/providers/curated', data: {'community_id': communityId, 'provider_id': providerId, 'label': label}) as Map<String, dynamic>;

  Future<void> removeCuratedProvider(int curatedId) async => api.delete('/admin/providers/curated/$curatedId');

  Future<Map<String, dynamic>> generateReport(int communityId, String reportType) async =>
      await api.get('/admin/reports', query: {'community_id': communityId, 'report_type': reportType}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> flaggedReviews() async {
    final data = await api.get('/admin/moderation/flagged-reviews');
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> moderateContent(String contentType, int contentId, String action, {String? reason}) async =>
      await api.post('/admin/moderation/$contentType/$contentId', data: {'action': action, if (reason != null) 'reason': reason}) as Map<String, dynamic>;

  // Platform admin
  Future<Map<String, dynamic>> createCategory({required String name, required String key, double commissionRate = 0.15, int slaHours = 48}) async =>
      await api.post('/platform/categories', data: {'name': name, 'key': key, 'commission_rate': commissionRate, 'sla_hours': slaHours}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateCategory(int categoryId, {double? commissionRate, int? slaHours}) async =>
      await api.patch('/platform/categories/$categoryId', data: {if (commissionRate != null) 'commission_rate': commissionRate, if (slaHours != null) 'sla_hours': slaHours}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateFeatureFlag({int? communityId, required String key, required bool enabled}) async =>
      await api.post('/platform/feature-flags', data: {if (communityId != null) 'community_id': communityId, 'key': key, 'enabled': enabled}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> auditLog({String? entityType}) async {
    final data = await api.get('/platform/audit-log', query: {if (entityType != null) 'entity_type': entityType});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> platformKpis() async => await api.get('/platform/kpis') as Map<String, dynamic>;
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref.watch(apiClientProvider)));
