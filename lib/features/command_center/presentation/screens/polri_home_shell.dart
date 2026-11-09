import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/sipelantas_bottom_nav.dart';
import '../../../auth/domain/entities/police_officer.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/police_login_screen.dart';
import 'polantas_field_violation_screen.dart';
import 'police_home_dashboard_view.dart';
import 'police_profile_screen.dart';
import 'unit_kamsel_radar_screen.dart';

final polriNavIndexProvider = StateProvider<int>((ref) => 0);

class PolriHomeShell extends ConsumerWidget {
  const PolriHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentIndex = ref.watch(polriNavIndexProvider);

    Widget bodyWidget;
    Widget? bottomNavWidget;

    if (!authState.isAuthenticated || authState.officer == null) {
      bodyWidget = const PoliceLoginScreen(key: ValueKey('police_login_screen'));
      bottomNavWidget = null;
    } else {
      final officer = authState.officer!;
      final bool isPolantas = officer.role == PoliceRole.polantas;

      final List<Widget> pages = [
        PoliceHomeDashboardView(
          officer: officer,
          onNavigateToInput: () {
            ref.read(polriNavIndexProvider.notifier).state = 1;
          },
        ),
        isPolantas
            ? const PolantasFieldViolationScreen()
            : const UnitKamselRadarScreen(),
        PoliceProfileScreen(officer: officer),
      ];

      final navItems = [
        const SipelantasNavItem(
          icon: Icons.home_outlined,
          label: 'Beranda',
        ),
        SipelantasNavItem(
          icon: isPolantas ? Icons.add_circle_outline : Icons.radar_outlined,
          label: isPolantas ? 'Tambah Tilang' : 'Radar Kamsel',
        ),
        const SipelantasNavItem(
          icon: Icons.person_outline,
          label: 'Profile',
        ),
      ];

      bodyWidget = IndexedStack(
        key: const ValueKey('police_main_flow'),
        index: currentIndex,
        children: pages,
      );

      bottomNavWidget = SipelantasBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(polriNavIndexProvider.notifier).state = index;
        },
        items: navItems,
        backgroundColor: const Color(0xFF131D31),
        activeColor: const Color(0xFFFF8A3D),
        inactiveColor: const Color(0xFF64748B),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C1322),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: bodyWidget,
      ),
      bottomNavigationBar: bottomNavWidget,
    );
  }
}
