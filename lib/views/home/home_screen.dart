import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../shift/shift_list_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_breakpoints.dart';

/// Main home screen with bottom navigation.
/// Contains Dashboard, Shifts, Statistics, and Settings tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ShiftListScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppBreakpoints.compact;

        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                    },
                    extended: constraints.maxWidth >= AppBreakpoints.medium,
                    backgroundColor:
                        isDark ? AppColors.surfaceDark : Colors.white,
                    selectedIconTheme: IconThemeData(color: primaryColor),
                    selectedLabelTextStyle: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: Text('Dashboard'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.list_alt_outlined),
                        selectedIcon: Icon(Icons.list_alt_rounded),
                        label: Text('Shifts'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.analytics_outlined),
                        selectedIcon: Icon(Icons.analytics_rounded),
                        label: Text('Stats'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                  VerticalDivider(
                    width: 1,
                    color: isDark
                        ? AppColors.cardDarkElevated
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                  Expanded(child: _buildIndexedBody()),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: _buildIndexedBody(),
          bottomNavigationBar: _buildBottomNav(primaryColor, isDark),
        );
      },
    );
  }

  Widget _buildIndexedBody() {
    return IndexedStack(
      index: _currentIndex,
      children: _screens,
    );
  }

  Widget _buildBottomNav(Color primaryColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.dashboard_rounded,
                'Dashboard',
                primaryColor,
                isDark,
              ),
              _buildNavItem(
                1,
                Icons.list_alt_rounded,
                'Shifts',
                primaryColor,
                isDark,
              ),
              _buildNavItem(
                2,
                Icons.analytics_rounded,
                'Stats',
                primaryColor,
                isDark,
              ),
              _buildNavItem(
                3,
                Icons.settings_rounded,
                'Settings',
                primaryColor,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
