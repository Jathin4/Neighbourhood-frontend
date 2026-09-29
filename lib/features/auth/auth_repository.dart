import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/providers.dart';

class AuthRepository {
  final ApiClient api;
  final AuthStorage storage;
  AuthRepository(this.api, this.storage);

  /// Returns the dev-only OTP echoed by the backend when DEV_EXPOSE_OTP=true, else null.
  Future<String?> sendOtp(String phone) async {
    final data = await api.post('/auth/otp/send', data: {'phone': phone});
    return data['dev_otp'] as String?;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final data = await api.post('/auth/otp/verify', data: {'phone': phone, 'otp': otp});
    await storage.saveSession(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      userId: data['user']['id'].toString(),
      role: data['user']['role'],
    );
    return data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final data = await api.get('/residents/me');
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerResident({required String fullName, String? householdRelationship}) async {
    final data = await api.post('/residents', data: {
      'full_name': fullName,
      if (householdRelationship != null) 'household_relationship': householdRelationship,
    });
    return data as Map<String, dynamic>;
  }

  Future<void> requestMembership({required int communityId}) async {
    await api.post('/residents/membership-requests', data: {'community_id': communityId, 'method': 'admin-approval'});
  }

  Future<void> changePhone(String newPhone, String otp) async {
    await api.post('/auth/change-phone', data: {'new_phone': newPhone, 'otp': otp});
  }

  Future<void> sendFcmToken(String fcmToken) async {
    await api.post('/auth/fcm-token', data: {'fcm_token': fcmToken});
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {
      // Best-effort — clear local session regardless.
    }
    await storage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(authStorageProvider)),
);
