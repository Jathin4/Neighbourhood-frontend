import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_repository.dart';

/// The community an admin is currently managing. Platform admins can switch
/// between all communities; community admins typically have just their own.
final selectedCommunityIdProvider = StateProvider<int?>((ref) => null);

final adminCommunitiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final communities = await ref.watch(adminRepositoryProvider).listCommunities();
  if (communities.isNotEmpty && ref.read(selectedCommunityIdProvider) == null) {
    ref.read(selectedCommunityIdProvider.notifier).state = communities.first['id'] as int;
  }
  return communities;
});

final towersProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, communityId) => ref.watch(adminRepositoryProvider).listTowers(communityId),
);

final unitsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, towerId) => ref.watch(adminRepositoryProvider).listUnits(towerId),
);
