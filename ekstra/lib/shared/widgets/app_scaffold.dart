import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/auth/presentation/auth_providers.dart';
import 'package:ekstra/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final MenuController _profileMenuController = MenuController();

  int get _index {
    if (widget.location.startsWith('/monthly')) return 0;
    if (widget.location.startsWith('/yearly')) return 2;
    return 1;
  }

  bool get _isDetailRoute =>
      widget.location.startsWith('/settings') ||
      widget.location.startsWith('/auth') ||
      widget.location.startsWith('/history') ||
      widget.location.startsWith('/shifts') ||
      widget.location.startsWith('/live') ||
      widget.location.startsWith('/pro');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: _isDetailRoute
            ? IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const BrandLogo(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MenuAnchor(
              controller: _profileMenuController,
              alignmentOffset: const Offset(-188, 8),
              style: MenuStyle(
                backgroundColor: const WidgetStatePropertyAll(
                  AppColors.surface,
                ),
                elevation: const WidgetStatePropertyAll(0),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                shadowColor: WidgetStatePropertyAll(
                  AppColors.navy.withValues(alpha: 0.55),
                ),
              ),
              menuChildren: [
                _ProfileMenuPanel(
                  onClose: _profileMenuController.close,
                  onSettingsPressed: () {
                    _profileMenuController.close();
                    context.go('/settings');
                  },
                ),
              ],
              builder: (context, controller, child) {
                final isOpen = controller.isOpen;
                return IconButton.filledTonal(
                  tooltip: 'Profil',
                  style: IconButton.styleFrom(
                    backgroundColor: isOpen
                        ? AppColors.orange.withValues(alpha: 0.18)
                        : AppColors.surface2,
                    foregroundColor: isOpen
                        ? AppColors.orange
                        : AppColors.muted,
                    fixedSize: const Size(44, 44),
                  ),
                  onPressed: () {
                    controller.isOpen ? controller.close() : controller.open();
                    setState(() {});
                  },
                  icon: const Icon(Icons.account_circle_rounded),
                );
              },
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF07111F),
                    Color(0xFF09182A),
                    Color(0xFF07111F),
                  ]
                : const [
                    Color(0xFFF7FAFE),
                    Color(0xFFEFF5FC),
                    Color(0xFFF7FAFE),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _AppBackgroundPainter(isDark)),
              ),
            ),
            widget.child,
          ],
        ),
      ),
      bottomNavigationBar: _isDetailRoute
          ? null
          : _EkstraBottomNav(
              selectedIndex: _index,
              onSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/monthly');
                    break;
                  case 1:
                    context.go('/');
                    break;
                  case 2:
                    context.go('/yearly');
                    break;
                }
              },
            ),
    );
  }
}

class _EkstraBottomNav extends StatelessWidget {
  const _EkstraBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 86,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
        decoration: BoxDecoration(
          color: AppColors.navy2.withValues(alpha: 0.98),
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Ay',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            Expanded(
              child: _PanelNavItem(
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Yıl',
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelNavItem extends StatelessWidget {
  const _PanelNavItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 44,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppColors.orange, AppColors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : AppColors.surface2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.16)
                      : AppColors.border,
                  width: 2,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.24),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Icon(
                Icons.dashboard_rounded,
                color: selected ? AppColors.navy : AppColors.white,
                size: 27,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Panel',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBackgroundPainter extends CustomPainter {
  const _AppBackgroundPainter(this.isDark);

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.orange.withValues(alpha: isDark ? 0.12 : 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 160));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 160), topPaint);

    final linePaint = Paint()
      ..color = (isDark ? AppColors.border : AppColors.lightBorder).withValues(
        alpha: isDark ? 0.18 : 0.34,
      )
      ..strokeWidth = 1;
    const spacing = 36.0;
    for (var y = 28.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AppBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _ProfileMenuPanel extends ConsumerWidget {
  const _ProfileMenuPanel({
    required this.onClose,
    required this.onSettingsPressed,
  });

  final VoidCallback onClose;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authSession = authState.value;
    final isAuthenticated = authSession?.isAuthenticated == true;
    return SizedBox(
      width: 224,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navy2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAuthenticated
                                  ? authSession!.email
                                  : 'Yerel profil',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAuthenticated
                                  ? 'Hesapli kullanim'
                                  : 'Hesapsiz kullanim',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 10),
                  _ProfileAuthAction(
                    isAuthenticated: isAuthenticated,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            if (isAuthenticated) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signOut(keepLocalData: true);
                              onClose();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Hesaptan cikildi. Mesai verilerin silinmedi.',
                                  ),
                                ),
                              );
                              return;
                            }
                            onClose();
                            context.go('/auth');
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.tune_rounded,
              label: 'Ayarlar',
              subtitle: 'Ücret, tarih ve hesap',
              onPressed: onSettingsPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAuthAction extends StatelessWidget {
  const _ProfileAuthAction({
    required this.isAuthenticated,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isAuthenticated ? AppColors.orange : AppColors.green;
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(
                  isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
                  color: color,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isLoading
                      ? 'Kontrol ediliyor'
                      : isAuthenticated
                      ? 'Oturumu kapat'
                      : 'Oturum aç',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: AppColors.green, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
