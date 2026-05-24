import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _rateController = TextEditingController();
  double _multiplier = 1.5;

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final rate = double.tryParse(_rateController.text.replaceAll(',', '.')) ?? 0;
    await ref.read(settingsControllerProvider.notifier).update(
          hourlyRate: rate,
          defaultMultiplier: _multiplier,
          hasCompletedOnboarding: true,
        );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(),
              const Spacer(),
              Text(
                'Ek mesaini gelire çevir.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Saatlik ücretini gir, varsayılan katsayını seç ve günlük mesaini saniyeler içinde kaydet.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saatlik ücret',
                  prefixIcon: Icon(Icons.payments_rounded),
                  suffixText: 'TRY',
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1x')),
                  ButtonSegment(value: 1.5, label: Text('1.5x')),
                  ButtonSegment(value: 2, label: Text('2x')),
                ],
                selected: {_multiplier},
                onSelectionChanged: (value) {
                  setState(() => _multiplier = value.first);
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Başla'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
