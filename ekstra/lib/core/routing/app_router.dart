import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ekstra/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ekstra/features/onboarding/presentation/splash_screen.dart';
import 'package:ekstra/features/reports/presentation/monthly_report_screen.dart';
import 'package:ekstra/features/reports/presentation/yearly_report_screen.dart';
import 'package:ekstra/features/settings/presentation/settings_screen.dart';
import 'package:ekstra/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _transitionPage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _transitionPage(state: state, child: const OnboardingScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _transitionPage(state: state, child: const DashboardScreen()),
          ),
          GoRoute(
            path: '/monthly',
            pageBuilder: (context, state) => _transitionPage(
              state: state,
              child: const MonthlyReportScreen(),
            ),
          ),
          GoRoute(
            path: '/yearly',
            pageBuilder: (context, state) => _transitionPage(
              state: state,
              child: const YearlyReportScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _transitionPage(state: state, child: const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _transitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ColoredBox(
        color: AppColors.navy,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.025, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
