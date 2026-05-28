import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/payroll/domain/payroll_lock.dart';
import 'package:ekstra/features/payroll/presentation/payroll_providers.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/shared/widgets/info_tooltip_button.dart';
import 'package:ekstra/shared/widgets/instant_date_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  late final TextEditingController _workplaceController;
  late final TextEditingController _referenceController;
  late OvertimeType _type;
  late double _multiplier;
  late double _hours;
  late DateTime _selectedDate;
  late bool _isPayrollChecked;

  @override
  void initState() {
    super.initState();
    _hours = widget.entry?.hours ?? 2;
    _selectedDate = widget.entry?.date ?? widget.date;
    _hoursController = TextEditingController(text: _formatHours(_hours));
    _noteController = TextEditingController(text: widget.entry?.note ?? '');
    _workplaceController = TextEditingController(
      text: widget.entry?.workplaceNote ?? '',
    );
    _referenceController = TextEditingController(
      text: widget.entry?.referenceCode ?? '',
    );
    _type = widget.entry?.overtimeType ?? OvertimeType.normal;
    _multiplier = widget.entry?.multiplier ?? widget.settings.defaultMultiplier;
    _isPayrollChecked = widget.entry?.isPayrollChecked ?? false;
    if (widget.entry == null) {
      _applyDateSuggestion(_selectedDate);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    _workplaceController.dispose();
    _referenceController.dispose();
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
    setState(() {
      _selectedDate = selected;
      if (widget.entry == null) {
        _applyDateSuggestion(selected);
      }
    });
  }

  void _applyDateSuggestion(DateTime date) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (!isWeekend) return;
    _type = OvertimeType.weekend;
    _multiplier = OvertimeType.weekend.suggestedMultiplier;
  }

  Future<void> _save() async {
    if (_hours <= 0) return;
    final canEditLockedMonth = await _confirmLockedMonthEdit();
    if (!canEditLockedMonth) return;
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
      hourlyRate:
          widget.entry?.hourlyRateSnapshot ?? widget.settings.hourlyRate,
      workplaceNote: _workplaceController.text.trim(),
      referenceCode: _referenceController.text.trim(),
      isPayrollChecked: _isPayrollChecked,
      existingId: isMovingExistingEntry ? null : widget.entry?.id,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmLockedMonthEdit() async {
    final lock = await ref.read(
      payrollLockProvider(
        PayrollLock.keyFor(
          year: _selectedDate.year,
          month: _selectedDate.month,
        ),
      ).future,
    );
    if (lock == null) return true;
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bu ay kilitli'),
          content: const Text(
            'Bu ay bordro kapanışıyla kilitlenmiş. Değişiklik yapmak kapanmış raporu etkileyebilir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yine de düzenle'),
            ),
          ],
        );
      },
    );
    return result == true;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF13243A), Color(0xFF07111F)]
              : const [Color(0xFFFFFFFF), Color(0xFFF3F7FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
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
              _SheetHeader(
                title: title,
                isEditing: widget.entry != null,
                onDelete: _delete,
              ),
              const SizedBox(height: 14),
              _DateSelector(
                date: _selectedDate,
                hasExistingEntry: widget.entry != null,
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF0D1B2F), Color(0xFF101F34)]
                        : const [Color(0xFFFFFFFF), Color(0xFFF4F8FC)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.20),
                  ),
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
              _OvertimeTypeSelector(
                selected: _type,
                onChanged: (value) {
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
              const SizedBox(height: 12),
              TextField(
                controller: _workplaceController,
                decoration: const InputDecoration(
                  labelText: 'Birim / vardiya notu',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Referans / kanıt no',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bordroda kontrol edildi'),
                subtitle: const Text(
                  'Ay sonunda bu kaydı bordro ile karşılaştırdığını işaretler.',
                ),
                value: _isPayrollChecked,
                onChanged: (value) => setState(() {
                  _isPayrollChecked = value;
                }),
              ),
              const SizedBox(height: 14),
              _EarningPreview(
                value: currency.format(preview),
                hours: _hours,
                multiplier: _multiplier,
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
          ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.04, end: 0),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.isEditing,
    required this.onDelete,
  });

  final String title;
  final bool isEditing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.bolt_rounded, color: AppColors.navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                isEditing
                    ? 'Bu günün mesaisini düzenliyorsun.'
                    : '2 dokunuşla mesaini kazanca çevir.',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (isEditing)
          IconButton.filledTonal(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Bu günü sil',
          ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.hasExistingEntry,
    required this.onTap,
  });

  final DateTime date;
  final bool hasExistingEntry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.navy2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: AppColors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mesai tarihi',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMMM yyyy', 'tr_TR').format(date),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              if (hasExistingEntry)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Kayıtlı',
                    style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_rounded, color: AppColors.muted, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _OvertimeTypeSelector extends StatelessWidget {
  const _OvertimeTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final OvertimeType selected;
  final ValueChanged<OvertimeType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mesai tipi',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: OvertimeType.values.map((type) {
            final isSelected = selected == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == OvertimeType.values.last ? 0 : 8,
                ),
                child: _TypeChip(
                  type: type,
                  selected: isSelected,
                  onTap: () => onChanged(type),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final OvertimeType type;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (type) {
      OvertimeType.normal => Icons.work_history_rounded,
      OvertimeType.weekend => Icons.weekend_rounded,
      OvertimeType.holiday => Icons.celebration_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 78,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.orange.withValues(alpha: 0.18)
                : AppColors.navy2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : _icon,
                color: selected ? AppColors.orange : AppColors.muted,
                size: 19,
              ),
              const Spacer(),
              Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                '${type.suggestedMultiplier}x',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningPreview extends StatelessWidget {
  const _EarningPreview({
    required this.value,
    required this.hours,
    required this.multiplier,
  });

  final String value;
  final double hours;
  final double multiplier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.green.withValues(alpha: 0.22),
            AppColors.orange.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} saat × ${multiplier}x',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
