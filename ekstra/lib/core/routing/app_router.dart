import 'package:ekstra/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ekstra/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ekstra/features/onboarding/presentation/splash_screen.dart';
import 'package:ekstra/features/reports/presentation/monthly_report_screen.dart';
import 'package:ekstra/features/reports/presentation/yearly_report_screen.dart';
import 'package:ekstra/features/settings/presentation/settings_screen.dart';
import 'package:ekstra/shared/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(
            path: '/monthly',
            builder: (context, state) => const MonthlyReportScreen(),
          ),
          GoRoute(
            path: '/yearly',
            builder: (context, state) => const YearlyReportScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
