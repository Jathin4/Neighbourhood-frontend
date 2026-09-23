import 'package:go_router/go_router.dart';
import '../../features/auth/session_gate_screen.dart';
import '../../features/auth/phone_entry_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/account_type_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/auth/community_match_screen.dart';
import '../../features/auth/pending_screen.dart';
import '../../features/resident/home_shell.dart';
import '../../features/resident/directory/directory_screen.dart';
import '../../features/resident/issues/issue_detail_screen.dart';
import '../../features/resident/services/provider_list_screen.dart';
import '../../features/resident/services/provider_profile_screen.dart';
import '../../features/resident/bookings/booking_detail_screen.dart';
import '../../features/resident/community/polls_events_screen.dart';
import '../../features/provider/provider_home_screen.dart';
import '../../features/provider/staff/staff_screen.dart';
import '../../features/provider/availability/availability_screen.dart';
import '../../features/provider/ledger/ledger_screen.dart';
import '../../features/provider/reviews/provider_reviews_screen.dart';
import '../../features/provider/support/support_tickets_screen.dart';
import '../../features/provider/provider_profile_edit_screen.dart';
import '../../features/provider/coverage/coverage_areas_screen.dart';
import '../../features/admin/admin_home_screen.dart';
import '../../features/admin/community/community_setup_screen.dart';
import '../../features/admin/community/bulk_import_screen.dart';
import '../../features/admin/members/membership_requests_screen.dart';
import '../../features/admin/members/residents_screen.dart';
import '../../features/admin/members/committee_roles_screen.dart';
import '../../features/admin/notices/notice_composer_screen.dart';
import '../../features/admin/issues/issue_board_screen.dart';
import '../../features/admin/pollsevents/poll_event_composer_screen.dart';
import '../../features/admin/providers/provider_verification_screen.dart';
import '../../features/admin/providers/provider_community_requests_screen.dart';
import '../../features/admin/providers/curated_providers_screen.dart';
import '../../features/admin/reports/reports_screen.dart';
import '../../features/admin/moderation/moderation_screen.dart';
import '../../features/admin/platform/platform_admin_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SessionGateScreen()),
    GoRoute(path: '/auth/route', builder: (context, state) => const SessionGateScreen()),
    GoRoute(path: '/auth/phone', builder: (context, state) => const PhoneEntryScreen()),
    GoRoute(
      path: '/auth/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpScreen(phone: extra['phone'] as String? ?? '', devOtp: extra['dev_otp'] as String?);
      },
    ),
    GoRoute(path: '/auth/account-type', builder: (context, state) => const AccountTypeScreen()),
    GoRoute(path: '/auth/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(
      path: '/auth/community-match',
      builder: (context, state) => CommunityMatchScreen(match: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(path: '/auth/pending', builder: (context, state) => const MembershipStatusScreen()),
    GoRoute(path: '/home', builder: (context, state) => const ResidentHomeShell()),
    GoRoute(path: '/directory', builder: (context, state) => const DirectoryScreen()),
    GoRoute(
      path: '/issues/:ticketNo',
      builder: (context, state) => IssueDetailScreen(ticketNo: state.pathParameters['ticketNo']!),
    ),
    GoRoute(
      path: '/services/:categoryKey',
      builder: (context, state) => ProviderListScreen(
        categoryKey: state.pathParameters['categoryKey']!,
        label: state.uri.queryParameters['label'] ?? '',
      ),
    ),
    GoRoute(
      path: '/providers/:id',
      builder: (context, state) => ProviderProfileScreen(providerId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/bookings/:id',
      builder: (context, state) => BookingDetailScreen(bookingId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/community/polls-events',
      builder: (context, state) => PollsEventsScreen(initialTab: state.uri.queryParameters['tab'] == 'events' ? 1 : 0),
    ),
    GoRoute(path: '/provider/home', builder: (context, state) => const ProviderHomeScreen()),
    GoRoute(path: '/provider/staff', builder: (context, state) => StaffScreen(providerId: int.parse(state.uri.queryParameters['provider_id']!))),
    GoRoute(path: '/provider/availability', builder: (context, state) => AvailabilityScreen(providerId: int.parse(state.uri.queryParameters['provider_id']!))),
    GoRoute(path: '/provider/ledger', builder: (context, state) => LedgerScreen(providerId: int.parse(state.uri.queryParameters['provider_id']!))),
    GoRoute(path: '/provider/reviews', builder: (context, state) => ProviderReviewsScreen(providerId: int.parse(state.uri.queryParameters['provider_id']!))),
    GoRoute(path: '/provider/support', builder: (context, state) => SupportTicketsScreen(providerId: int.parse(state.uri.queryParameters['provider_id']!))),
    GoRoute(path: '/provider/profile', builder: (context, state) => ProviderProfileEditScreen(providerId: int.parse(state.uri.queryParameters['provider_id']!))),
    GoRoute(path: '/provider/coverage', builder: (context, state) => const CoverageAreasScreen()),
    GoRoute(path: '/admin/home', builder: (context, state) => const AdminHomeScreen()),
    GoRoute(path: '/admin/community-setup', builder: (context, state) => const CommunitySetupScreen()),
    GoRoute(path: '/admin/bulk-import', builder: (context, state) => const BulkImportScreen()),
    GoRoute(path: '/admin/membership-requests', builder: (context, state) => const MembershipRequestsScreen()),
    GoRoute(path: '/admin/residents', builder: (context, state) => const ResidentsScreen()),
    GoRoute(path: '/admin/committee-roles', builder: (context, state) => const CommitteeRolesScreen()),
    GoRoute(path: '/admin/notices/new', builder: (context, state) => const NoticeComposerScreen()),
    GoRoute(path: '/admin/issues', builder: (context, state) => const IssueBoardScreen()),
    GoRoute(path: '/admin/polls-events/new', builder: (context, state) => const PollEventComposerScreen()),
    GoRoute(path: '/admin/providers/verification', builder: (context, state) => const ProviderVerificationScreen()),
    GoRoute(path: '/admin/providers/community-requests', builder: (context, state) => const ProviderCommunityRequestsScreen()),
    GoRoute(path: '/admin/providers/curated', builder: (context, state) => const CuratedProvidersScreen()),
    GoRoute(path: '/admin/reports', builder: (context, state) => const ReportsScreen()),
    GoRoute(path: '/admin/moderation', builder: (context, state) => const ModerationScreen()),
    GoRoute(path: '/admin/platform', builder: (context, state) => const PlatformAdminScreen()),
  ],
);
