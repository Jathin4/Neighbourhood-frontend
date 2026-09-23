import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import 'dashboard/dashboard_screen.dart';
import 'notices/notices_screen.dart';
import 'issues/issues_screen.dart';
import 'services/services_screen.dart';
import 'profile/profile_screen.dart';

/// Lets any screen switch tabs (e.g. a dashboard quick-link jumping to Services).
final residentTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell: Home / Notices / Issues / Services / Profile — matches the
/// prototype exactly. Each tab keeps its own scroll/filter state via IndexedStack.
class ResidentHomeShell extends ConsumerWidget {
  const ResidentHomeShell({super.key});

  static const _screens = [
    DashboardScreen(),
    NoticesScreen(),
    IssuesScreen(),
    ServicesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(residentTabIndexProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => ref.read(residentTabIndexProvider.notifier).state = i,
        selectedFontSize: 10.5,
        unselectedFontSize: 10.5,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home, color: TnnColors.goldDeep), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description, color: TnnColors.goldDeep), label: 'Notices'),
          BottomNavigationBarItem(icon: Icon(Icons.star_border), activeIcon: Icon(Icons.star, color: TnnColors.goldDeep), label: 'Issues'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build, color: TnnColors.goldDeep), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person, color: TnnColors.goldDeep), label: 'Profile'),
        ],
      ),
    );
  }
}
