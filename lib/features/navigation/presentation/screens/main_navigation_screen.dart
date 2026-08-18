import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/screens/home_dashboard_screen.dart';
import '../../../mesh/presentation/screens/mesh_screen.dart';
import '../../../rescue/presentation/screens/rescue_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: _onTabTapped),
      const MeshScreen(),
      const RescueScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.lightSurface,
          border: Border(
            top: BorderSide(color: AppColors.lightBorder, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primaryIndigoLight,
              iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(color: AppColors.primaryIndigo, size: 24);
                }
                return const IconThemeData(color: AppColors.textDarkSecondary, size: 22);
              }),
              labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryIndigo,
                  );
                }
                return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDarkSecondary,
                );
              }),
            ),
            child: NavigationBar(
              height: 64,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppColors.primaryIndigoLight,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, size: 22, color: AppColors.textDarkSecondary),
                  selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryIndigo, size: 24),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.hub_outlined, size: 22, color: AppColors.textDarkSecondary),
                  selectedIcon: Icon(Icons.hub_rounded, color: AppColors.primaryIndigo, size: 24),
                  label: 'Mesh',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emergency_outlined, size: 22, color: AppColors.textDarkSecondary),
                  selectedIcon: Icon(Icons.emergency_rounded, color: AppColors.emergencyRed, size: 24),
                  label: 'Rescue',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded, size: 22, color: AppColors.textDarkSecondary),
                  selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryIndigo, size: 24),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
