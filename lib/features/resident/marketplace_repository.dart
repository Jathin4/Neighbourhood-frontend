import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/providers.dart';

class MarketplaceRepository {
  final ApiClient api;
  MarketplaceRepository(this.api);

  Future<List<Map<String, dynamic>>> listCategories() async {
    final data = await api.get('/service-categories');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> searchProviders({required String category, int? communityId}) async {
    final data = await api.get('/providers/search', query: {'category': category, if (communityId != null) 'community_id': communityId});
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getProviderProfile(int providerId) async => await api.get('/providers/$providerId') as Map<String, dynamic>;

  Future<void> toggleFavourite(int providerId, bool add) async {
    if (add) {
      await api.post('/providers/$providerId/favourite');
    } else {
      await api.delete('/providers/$providerId/favourite');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int providerId,
    required int categoryId,
    required String description,
    String? preferredTime,
    int? budgetMinor,
  }) async {
    final idempotencyKey = 'booking-${DateTime.now().microsecondsSinceEpoch}';
    final data = await api.post(
      '/bookings',
      data: {
        'provider_id': providerId,
        'category_id': categoryId,
        'description': description,
        if (preferredTime != null) 'preferred_time': preferredTime,
        if (budgetMinor != null) 'budget_minor': budgetMinor,
      },
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listMyBookings() async {
    final data = await api.get('/bookings/mine');
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getBookingDetail(int bookingId) async => await api.get('/bookings/$bookingId') as Map<String, dynamic>;

  Future<Map<String, dynamic>> initiatePayment(int bookingId, int amountMinorUnits) async {
    final idempotencyKey = 'payment-${DateTime.now().microsecondsSinceEpoch}';
    final data = await api.post(
      '/bookings/$bookingId/payments/initiate',
      data: {'amount_minor_units': amountMinorUnits},
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recordOffPlatformPayment(int bookingId, String note) async =>
      await api.post('/bookings/$bookingId/off-platform-payment', data: {'note': note}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> cancelBooking(int bookingId, String reason) async =>
      await api.patch('/bookings/$bookingId/cancel', data: {'reason': reason}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> confirmBooking(int bookingId) async => await api.patch('/bookings/$bookingId/confirm') as Map<String, dynamic>;

  Future<Map<String, dynamic>> submitReview(int bookingId, {required int rating, String? text}) async => await api.post(
        '/bookings/$bookingId/review',
        data: {'rating': rating, if (text != null && text.isNotEmpty) 'text': text},
      ) as Map<String, dynamic>;
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) => MarketplaceRepository(ref.watch(apiClientProvider)));
