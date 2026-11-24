import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'analytics_page.dart';
import 'battery_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      HomePage(),
      AnalyticsPage(),
      BatteryPage(),
      SettingsPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.navBarBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primaryContainer,
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Image.asset('assets/logo.png',
                  width: 22, height: 22, fit: BoxFit.contain),
              selectedIcon: Image.asset('assets/logo.png',
                  width: 26, height: 26, fit: BoxFit.contain),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart, color: AppColors.primary),
              label: 'Analytics',
            ),
            const NavigationDestination(
              icon: Icon(Icons.battery_std_outlined),
              selectedIcon:
                  Icon(Icons.battery_full, color: AppColors.secondary),
              label: 'Battery',
            ),
            const NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
