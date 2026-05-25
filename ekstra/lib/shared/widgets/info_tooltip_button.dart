import 'package:ekstra/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class InfoTooltipButton extends StatelessWidget {
  const InfoTooltipButton({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: title,
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
      icon: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.question_mark_rounded,
          size: 14,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
