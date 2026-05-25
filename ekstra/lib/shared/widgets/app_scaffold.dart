import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
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
    if (widget.location.startsWith('/monthly')) return 1;
    if (widget.location.startsWith('/yearly')) return 2;
    return 0;
  }

  bool get _isSettings => widget.location.startsWith('/settings');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSettings
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
      body: widget.child,
      bottomNavigationBar: _isSettings
          ? null
          : NavigationBar(
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
              ],
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/monthly');
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

class _ProfileMenuPanel extends StatelessWidget {
  const _ProfileMenuPanel({required this.onSettingsPressed});

  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
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
              child: Row(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yerel profil',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cihazda kayıtlı',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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
