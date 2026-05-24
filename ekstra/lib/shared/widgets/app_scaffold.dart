import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  int get _index {
    if (location.startsWith('/monthly')) return 1;
    if (location.startsWith('/yearly')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.account_circle_rounded, color: AppColors.muted),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: AppColors.navy2,
        indicatorColor: AppColors.orange.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Ay',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Yıl',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Ayar',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/monthly');
            case 2:
              context.go('/yearly');
            case 3:
              context.go('/settings');
          }
        },
      ),
    );
  }
}
