import 'package:ekstra/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false});

  static const appIconPath = 'assets/logo/ekstra_app_icon.png';
  static const wordmarkPath = 'assets/logo/ekstra_wordmark.png';

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Image.asset(
        appIconPath,
        width: 42,
        height: 42,
        filterQuality: FilterQuality.high,
      );
    }

    return Container(
      width: 178,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        wordmarkPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
