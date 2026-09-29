/// Committee capability keys — must match the `can_*` strings the backend's
/// fn__has_capability() checks against. Shared between the admin screen that
/// grants these (committee_roles_screen) and the resident screen that lets a
/// committee member act on them (profile_screen).
const committeeCapabilityKeys = [
  'can_create_notice',
  'can_assign_issue',
  'can_create_poll',
  'can_create_event',
  'can_manage_structure',
];

const committeeCapabilityLabels = {
  'can_create_notice': 'Post community notices',
  'can_assign_issue': 'Assign and manage issues',
  'can_create_poll': 'Create polls',
  'can_create_event': 'Create events',
  'can_manage_structure': 'Manage towers and units',
};

/// Where a resident holding this capability goes to act on it — reuses the
/// existing admin screens, which are already generic over selectedCommunityIdProvider.
const committeeCapabilityRoutes = {
  'can_create_notice': '/admin/notices/new',
  'can_assign_issue': '/admin/issues',
  'can_create_poll': '/admin/polls-events/new',
  'can_create_event': '/admin/polls-events/new',
  'can_manage_structure': '/admin/community-setup',
};
