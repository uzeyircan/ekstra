import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/monetization/domain/purchase_result.dart';
import 'package:ekstra/features/monetization/presentation/entitlement_providers.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementControllerProvider).value;
    final productAsync = ref.watch(proProductProvider);
    final isPro = entitlement?.isPro ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.navy,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ekstra Pro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mesaini, kazancını ve raporlarını reklamsız takip et.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _StatusPill(isPro: isPro),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _BenefitTile(
          icon: Icons.block_rounded,
          title: 'Reklamsız kullanım',
          subtitle: 'Rewarded reklam izlemeden gelişmiş özellikleri aç.',
        ),
        const _BenefitTile(
          icon: Icons.description_rounded,
          title: 'Sınırsız rapor',
          subtitle: 'PDF ve Excel dışa aktarma sınırı olmadan çalış.',
        ),
        const _BenefitTile(
          icon: Icons.analytics_rounded,
          title: 'Detaylı maaş analizi',
          subtitle:
              'Kazanç, mesai ve dönem karşılaştırmalarını daha derin gör.',
        ),
        const _BenefitTile(
          icon: Icons.ios_share_rounded,
          title: 'PDF / Excel dışa aktarma',
          subtitle: 'İnsan kaynakları için düzenli rapor çıktıları hazırla.',
        ),
        const _BenefitTile(
          icon: Icons.notifications_active_rounded,
          title: 'Gelişmiş bildirimler',
          subtitle: 'Vardiya, maaş günü ve dönem özetlerini daha akıllı yönet.',
        ),
        const SizedBox(height: 10),
        productAsync.when(
          data: (product) => FilledButton.icon(
            onPressed: isPro || !product.isAvailable
                ? null
                : () => _buyPro(context, ref),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text(
              isPro
                  ? 'Pro aktif'
                  : product.isAvailable
                  ? 'Pro’ya Geç ${product.price}'
                  : 'Pro mağazada hazır değil',
            ),
          ),
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.error_outline_rounded),
            label: const Text('Mağaza bilgisi alınamadı'),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Reklam izleme, kilitli özelliklerde işlem sırasında açılır.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_circle_rounded),
          label: const Text('Reklam izleyerek devam et'),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Daha sonra'),
        ),
      ],
    );
  }

  Future<void> _buyPro(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(purchaseServiceProvider).buyPro();
    if (!context.mounted) return;
    final message = switch (result.status) {
      PurchaseResultStatus.started =>
        'Satın alma penceresi açıldı. İşlem tamamlanınca Pro aktif olur.',
      PurchaseResultStatus.restored => 'Satın alımlar geri yükleniyor.',
      PurchaseResultStatus.storeUnavailable => 'Mağaza şu an kullanılamıyor.',
      PurchaseResultStatus.productUnavailable =>
        result.message.isEmpty
            ? 'Pro ürünü mağazada bulunamadı.'
            : result.message,
      PurchaseResultStatus.failed => 'Satın alma başlatılamadı.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isPro ? AppColors.green : AppColors.orange).withValues(
          alpha: 0.14,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isPro ? AppColors.green : AppColors.orange).withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Text(
        isPro ? 'Pro aktif' : 'Free plan',
        style: TextStyle(
          color: isPro ? AppColors.green : AppColors.orange,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.green, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
