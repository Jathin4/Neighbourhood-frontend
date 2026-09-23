import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/providers.dart';

class ProviderRepository {
  final ApiClient api;
  ProviderRepository(this.api);

  /// The logged-in owner/staff's own provider row, or null if none exists yet
  /// (i.e. they haven't started onboarding).
  Future<Map<String, dynamic>?> getMyProvider() async {
    final data = await api.get('/providers/me');
    return data as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> submitApplication({
    required String businessName,
    required List<String> categories,
  }) async {
    final data = await api.post('/providers', data: {
      'business_name': businessName,
      'categories': categories,
    });
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateServiceCatalogue(int providerId, Map<String, dynamic> pricingModel) async =>
      await api.patch('/providers/me/service-catalogue', query: {'provider_id': providerId}, data: {'pricing_model': pricingModel}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> browseCommunities({String? search}) async {
    final data = await api.get('/communities/browse', query: {if (search != null && search.isNotEmpty) 'search': search});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> requestServeCommunity(int communityId) async =>
      await api.post('/providers/me/community-requests', data: {'community_id': communityId}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> myCommunityRequests() async {
    final data = await api.get('/providers/me/community-requests');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> submitDocument(int providerId, {required String docType, required String fileUrl}) async {
    final data = await api.post('/providers/$providerId/documents', data: {'doc_type': docType, 'file_url': fileUrl});
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDashboard(int providerId) async =>
      await api.get('/providers/me/dashboard', query: {'provider_id': providerId}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getLeads(int providerId) async {
    final data = await api.get('/providers/me/leads', query: {'provider_id': providerId});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listBookings(int providerId) async {
    final data = await api.get('/bookings/provider', query: {'provider_id': providerId});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> respondBooking(int bookingId, {required String action, String? proposedTime, String? note}) async {
    final data = await api.patch('/bookings/$bookingId/respond', data: {
      'action': action,
      if (proposedTime != null) 'proposed_time': proposedTime,
      if (note != null) 'note': note,
    });
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeBooking(int bookingId) async => await api.patch('/bookings/$bookingId/complete') as Map<String, dynamic>;

  Future<Map<String, dynamic>> cancelBooking(int bookingId, String reason) async =>
      await api.patch('/bookings/$bookingId/cancel', data: {'reason': reason}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> getAvailability(int providerId) async =>
      await api.get('/providers/me/availability', query: {'provider_id': providerId}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateAvailability(int providerId, {Map<String, dynamic>? weeklySchedule, List<dynamic>? blackoutDates}) async {
    final data = await api.patch(
      '/providers/me/availability',
      query: {'provider_id': providerId},
      data: {
        if (weeklySchedule != null) 'weekly_schedule': weeklySchedule,
        if (blackoutDates != null) 'blackout_dates': blackoutDates,
      },
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSettlementLedger(int providerId) async {
    final data = await api.get('/providers/$providerId/ledger');
    return data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listStaff(int providerId) async {
    final data = await api.get('/providers/me/staff', query: {'provider_id': providerId});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addStaff(int providerId, {required String phone, String role = 'technician'}) async =>
      await api.post('/providers/me/staff', query: {'provider_id': providerId}, data: {'staff_phone': phone, 'role': role}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateStaff(int providerId, int staffId, {bool? active}) async =>
      await api.patch('/providers/me/staff/$staffId', query: {'provider_id': providerId}, data: {if (active != null) 'active': active}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listReviews(int providerId) async {
    final profile = await api.get('/providers/$providerId');
    return ((profile as Map<String, dynamic>)['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> respondToReview(int reviewId, String response) async =>
      await api.post('/reviews/$reviewId/response', data: {'response': response}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createSupportTicket({int? providerId, required String subject, required String description}) async =>
      await api.post('/providers/me/support-tickets', data: {if (providerId != null) 'provider_id': providerId, 'subject': subject, 'description': description}) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listSupportTickets(int providerId) async {
    final data = await api.get('/providers/me/support-tickets', query: {'provider_id': providerId});
    return (data as List).cast<Map<String, dynamic>>();
  }
}

final providerRepositoryProvider = Provider<ProviderRepository>((ref) => ProviderRepository(ref.watch(apiClientProvider)));

/// The logged-in provider's own record (null if not yet onboarded). Shared
/// across every provider-portal screen so they all agree on verification state.
final myProviderProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) => ref.watch(providerRepositoryProvider).getMyProvider());
