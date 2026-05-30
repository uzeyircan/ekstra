import 'package:ekstra/core/config/supabase_config.dart';
import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/auth/presentation/auth_providers.dart';
import 'package:ekstra/shared/widgets/brand_logo.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSignUp = true;
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      await controller.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await controller.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    state.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignUp
                  ? 'Hesap olusturuldu. Mevcut mesai verilerin korundu.'
                  : 'Giris yapildi. Mesai verilerin aynen duruyor.',
            ),
          ),
        );
        context.go('/settings');
      },
      error: (error, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const BrandLogo(),
        const SizedBox(height: 18),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignUp ? 'Hesap olustur' : 'Giris yap',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hesaba gecsen de hesapsiz moda donsen de bu cihazdaki mesai, vardiya ve ayar verilerin silinmez.',
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Yeni hesap')),
                  ButtonSegment(value: false, label: Text('Giris')),
                ],
                selected: {_isSignUp},
                onSelectionChanged: isLoading
                    ? null
                    : (value) => setState(() => _isSignUp = value.first),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.mail_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                onSubmitted: (_) => isLoading ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Sifre',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isSignUp
                              ? Icons.person_add_rounded
                              : Icons.login_rounded,
                        ),
                  label: Text(_isSignUp ? 'Hesap olustur' : 'Giris yap'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PremiumPanel(
          child: Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  SupabaseConfig.isConfigured
                      ? 'Hesap girisi Supabase ile yapilir. Bu surumde mevcut cihaz verilerin korunur; bulut veri senkronizasyonu sonraki adimda acilacak.'
                      : 'Supabase bilgileri verilmedigi icin bu hesap bu cihazda yerel olarak saklanir.',
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
