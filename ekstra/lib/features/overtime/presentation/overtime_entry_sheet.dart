import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/shared/widgets/info_tooltip_button.dart';
import 'package:ekstra/shared/widgets/instant_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OvertimeEntrySheet extends ConsumerStatefulWidget {
  const OvertimeEntrySheet({
    required this.date,
    required this.settings,
    this.entry,
    super.key,
  });

  final DateTime date;
  final UserSettings settings;
  final OvertimeEntry? entry;

  @override
  ConsumerState<OvertimeEntrySheet> createState() => _OvertimeEntrySheetState();
}

class _OvertimeEntrySheetState extends ConsumerState<OvertimeEntrySheet> {
  late final TextEditingController _hoursController;
  late final TextEditingController _noteController;
  late OvertimeType _type;
  late double _multiplier;
  late double _hours;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _hours = widget.entry?.hours ?? 2;
    _selectedDate = widget.entry?.date ?? widget.date;
    _hoursController = TextEditingController(text: _formatHours(_hours));
    _noteController = TextEditingController(text: widget.entry?.note ?? '');
    _type = widget.entry?.overtimeType ?? OvertimeType.normal;
    _multiplier = widget.entry?.multiplier ?? widget.settings.defaultMultiplier;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatHours(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  void _setHours(double value) {
    final sanitized = value.clamp(0.5, 24).toDouble();
    setState(() {
      _hours = sanitized;
      _hoursController.text = _formatHours(sanitized);
      _hoursController.selection = TextSelection.collapsed(
        offset: _hoursController.text.length,
      );
    });
  }

  void _syncHoursFromText(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return;
    setState(() => _hours = parsed.clamp(0.5, 24).toDouble());
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showInstantDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      title: 'Mesai tarihi',
    );
    if (selected == null) return;
    setState(() => _selectedDate = selected);
  }

  Future<void> _save() async {
    if (_hours <= 0) return;
    final shouldContinue = await _confirmRiskySave();
    if (!shouldContinue) return;

    final controller = ref.read(overtimeEntriesProvider.notifier);
    final isMovingExistingEntry =
        widget.entry != null &&
        !DateKey.isSameDay(widget.entry!.date, _selectedDate);
    if (isMovingExistingEntry) {
      await controller.delete(widget.entry!.id);
    }
    await controller.upsertDay(
      date: _selectedDate,
      hours: _hours,
      note: _noteController.text.trim(),
      type: _type,
      multiplier: _multiplier,
      existingId: isMovingExistingEntry ? null : widget.entry?.id,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmRiskySave() async {
    final warnings = <String>[];
    final today = DateKey.onlyDate(DateTime.now());
    final selectedDay = DateKey.onlyDate(_selectedDate);
    final entries = ref.read(overtimeEntriesProvider).value ?? [];
    final conflictingEntry = entries
        .where(
          (entry) =>
              DateKey.isSameDay(entry.date, selectedDay) &&
              entry.id != widget.entry?.id,
        )
        .firstOrNull;

    if (selectedDay.isAfter(today)) {
      warnings.add('Seçilen tarih bugünden ileri.');
    }
    if (_hours > 16) {
      warnings.add('Girilen mesai 16 saatin üzerinde.');
    }
    if (conflictingEntry != null) {
      warnings.add(
        'Bu tarihte zaten kayıt var; kaydedersen o gün güncellenir.',
      );
    }
    if (warnings.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kaydı kontrol et'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: warnings.map((warning) => Text('• $warning')).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Düzenle'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yine de kaydet'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) return;
    await ref.read(overtimeEntriesProvider.notifier).delete(entry.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate);
    final preview = _hours * widget.settings.hourlyRate * _multiplier;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TRY ');

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mesaini hızlıca kaydet, gerekirse tarihi düzelt.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (widget.entry != null)
                  IconButton.filledTonal(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_rounded),
                    tooltip: 'Bu günü sil',
                  ),
              ],
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Mesai tarihi',
                  prefixIcon: Icon(Icons.event_available_rounded),
                ),
                child: Text(
                  DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navy2,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'Mesai saati',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundStepButton(
                        icon: Icons.remove_rounded,
                        onPressed: () => _setHours(_hours - 0.5),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: 112,
                        child: TextField(
                          controller: _hoursController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                          decoration: const InputDecoration(
                            suffixText: 's',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: _syncHoursFromText,
                        ),
                      ),
                      const SizedBox(width: 18),
                      _RoundStepButton(
                        icon: Icons.add_rounded,
                        onPressed: () => _setHours(_hours + 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: const [1, 2, 3, 4, 6].map((hours) {
                      return ChoiceChip(
                        selected: _hours == hours,
                        label: Text('${hours}s'),
                        onSelected: (_) => _setHours(hours.toDouble()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<OvertimeType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Mesai tipi',
                prefixIcon: Icon(Icons.work_history_rounded),
              ),
              items: OvertimeType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _type = value;
                  _multiplier = value.suggestedMultiplier;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                const InfoTooltipButton(
                  title: 'Mesai katsayısı',
                  message:
                      'Katsayı kazanç hesabında kullanılır. Formül: mesai saati × saatlik ücret × katsayı. Örneğin 2 saat, 200 TRY ve 1.5x = 600 TRY.',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Not',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.green.withValues(alpha: 0.18),
                    AppColors.orange.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: AppColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tahmini kazanç',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.format(preview),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.green,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const InfoTooltipButton(
                    title: 'Tahmini kazanç',
                    message:
                        'Bu tutar seçtiğin saat, saatlik ücret ve katsayıya göre hesaplanır. Formül: saat × saatlik ücret × katsayı.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.entry == null ? 'Mesai ekle' : 'Güncelle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        backgroundColor: AppColors.surface2,
        foregroundColor: AppColors.white,
      ),
    );
  }
}
