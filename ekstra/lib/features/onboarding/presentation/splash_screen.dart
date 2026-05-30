import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    settingsAsync.whenData((settings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(settings.hasCompletedOnboarding ? '/' : '/onboarding');
      });
    });

    if (settingsAsync.hasError) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: Text(
            'Acilis verileri okunamadi.',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: BrandLogo()),
      backgroundColor: AppColors.navy,
    ).animate().fadeIn(duration: 400.ms);
  }
}
