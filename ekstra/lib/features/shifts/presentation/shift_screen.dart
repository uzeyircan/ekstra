import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/shifts/domain/shift.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';
import 'package:ekstra/features/shifts/domain/shift_schedule_service.dart';
import 'package:ekstra/features/shifts/domain/shift_template.dart';
import 'package:ekstra/features/shifts/presentation/shift_providers.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ShiftScreen extends ConsumerStatefulWidget {
  const ShiftScreen({super.key});

  @override
  ConsumerState<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends ConsumerState<ShiftScreen> {
  ShiftRepeatType _repeatType = ShiftRepeatType.weekdays;
  final Set<int> _selectedWeekdays = {
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  };
  String? _selectedTemplateId;
  String? _alternateTemplateId;

  @override
  Widget build(BuildContext context) {
    final shifts = ref.watch(shiftsProvider);
    final templatesAsync = ref.watch(shiftTemplatesProvider);
    final assignmentsAsync = ref.watch(shiftAssignmentsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          'Vardiya planı',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vardiya şablonu seç, tekrar kuralını belirle ve bu ayın planını tek dokunuşla oluştur.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        templatesAsync.when(
          data: (templates) {
            final enabled = templates
                .where((template) => template.isEnabled)
                .toList();
            return _ScheduleBuilderPanel(
              templates: enabled,
              selectedTemplateId: _selectedTemplateId,
              alternateTemplateId: _alternateTemplateId,
              repeatType: _repeatType,
              selectedWeekdays: _selectedWeekdays,
              onTemplateChanged: (id) =>
                  setState(() => _selectedTemplateId = id),
              onAlternateChanged: (id) =>
                  setState(() => _alternateTemplateId = id),
              onRepeatChanged: (type) => setState(() => _repeatType = type),
              onWeekdayToggled: _toggleWeekday,
              onGenerate: _generateCurrentMonth,
            );
          },
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text('Vardiya şablonları okunamadı: $error'),
        ),
        const SizedBox(height: 16),
        assignmentsAsync.when(
          data: (assignments) => _AssignmentsPreview(assignments: assignments),
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text('Vardiya planı okunamadı: $error'),
        ),
        const SizedBox(height: 16),
        shifts.when(
          data: (items) => Column(
            children: items
                .map(
                  (shift) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShiftTile(shift: shift),
                  ),
                )
                .toList(),
          ),
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text('Vardiyalar okunamadı: $error'),
        ),
      ],
    );
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (selectedWeekdaysContains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  bool selectedWeekdaysContains(int weekday) {
    return _selectedWeekdays.contains(weekday);
  }

  Future<void> _generateCurrentMonth(List<ShiftTemplate> templates) async {
    if (templates.isEmpty) return;
    final template = templates.firstWhere(
      (item) => item.id == _selectedTemplateId,
      orElse: () => templates.first,
    );
    final alternate = templates
        .where((item) => item.id == _alternateTemplateId)
        .firstOrNull;
    await ref
        .read(shiftAssignmentsProvider.notifier)
        .generateMonth(
          month: DateTime.now(),
          template: template,
          repeatType: _repeatType,
          selectedWeekdays: _selectedWeekdays,
          alternateTemplate: alternate,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu ayın vardiya planı oluşturuldu.')),
    );
  }
}

class _ScheduleBuilderPanel extends StatelessWidget {
  const _ScheduleBuilderPanel({
    required this.templates,
    required this.selectedTemplateId,
    required this.alternateTemplateId,
    required this.repeatType,
    required this.selectedWeekdays,
    required this.onTemplateChanged,
    required this.onAlternateChanged,
    required this.onRepeatChanged,
    required this.onWeekdayToggled,
    required this.onGenerate,
  });

  final List<ShiftTemplate> templates;
  final String? selectedTemplateId;
  final String? alternateTemplateId;
  final ShiftRepeatType repeatType;
  final Set<int> selectedWeekdays;
  final ValueChanged<String> onTemplateChanged;
  final ValueChanged<String?> onAlternateChanged;
  final ValueChanged<ShiftRepeatType> onRepeatChanged;
  final ValueChanged<int> onWeekdayToggled;
  final ValueChanged<List<ShiftTemplate>> onGenerate;

  @override
  Widget build(BuildContext context) {
    final selectedId = selectedTemplateId ?? templates.firstOrNull?.id;

    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akıllı plan oluştur',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bu ay için tekrar eden vardiya atamaları hazırlar. Mevcut mesai kayıtlarını değiştirmez.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          if (templates.isEmpty)
            const Text(
              'Aktif vardiya şablonu yok. Aşağıdan en az bir vardiyayı aç.',
              style: TextStyle(color: AppColors.orange),
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                labelText: 'Ana vardiya',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
              items: templates
                  .map(
                    (template) => DropdownMenuItem(
                      value: template.id,
                      child: Text(template.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onTemplateChanged(value);
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<ShiftRepeatType>(
              segments: const [
                ButtonSegment(
                  value: ShiftRepeatType.everyDay,
                  label: Text('Her gün'),
                ),
                ButtonSegment(
                  value: ShiftRepeatType.weekdays,
                  label: Text('Hafta içi'),
                ),
                ButtonSegment(
                  value: ShiftRepeatType.selectedDays,
                  label: Text('Gün seç'),
                ),
                ButtonSegment(
                  value: ShiftRepeatType.alternatingWeeks,
                  label: Text('Dönüşümlü'),
                ),
              ],
              selected: {repeatType},
              onSelectionChanged: (values) => onRepeatChanged(values.first),
            ),
            if (repeatType == ShiftRepeatType.selectedDays) ...[
              const SizedBox(height: 12),
              _WeekdaySelector(
                selectedWeekdays: selectedWeekdays,
                onChanged: onWeekdayToggled,
              ),
            ],
            if (repeatType == ShiftRepeatType.alternatingWeeks) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: alternateTemplateId,
                decoration: const InputDecoration(
                  labelText: 'İkinci hafta vardiyası',
                  prefixIcon: Icon(Icons.swap_horiz_rounded),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    child: Text('Aynı vardiyayı kullan'),
                  ),
                  ...templates.map(
                    (template) => DropdownMenuItem<String?>(
                      value: template.id,
                      child: Text(template.name),
                    ),
                  ),
                ],
                onChanged: onAlternateChanged,
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onGenerate(templates),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Bu ayın planını oluştur'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selectedWeekdays,
    required this.onChanged,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      DateTime.monday: 'Pzt',
      DateTime.tuesday: 'Sal',
      DateTime.wednesday: 'Çar',
      DateTime.thursday: 'Per',
      DateTime.friday: 'Cum',
      DateTime.saturday: 'Cmt',
      DateTime.sunday: 'Paz',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.entries.map((item) {
        return FilterChip(
          label: Text(item.value),
          selected: selectedWeekdays.contains(item.key),
          onSelected: (_) => onChanged(item.key),
        );
      }).toList(),
    );
  }
}

class _AssignmentsPreview extends StatelessWidget {
  const _AssignmentsPreview({required this.assignments});

  final List<ShiftAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = assignments
        .where((assignment) => !assignment.date.isBefore(today))
        .take(7)
        .toList();

    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu ayın vardiya akışı',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            assignments.isEmpty
                ? 'Henüz oluşturulmuş vardiya ataması yok.'
                : '${assignments.length} gün planlandı. Yaklaşan vardiyalar:',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            const Text('-', style: TextStyle(color: AppColors.muted))
          else
            ...upcoming.map((assignment) {
              final color = Color(assignment.color);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${DateFormat('d MMM EEE', 'tr_TR').format(assignment.date)} • ${assignment.templateName}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${assignment.startTime}-${assignment.endTime}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ShiftTile extends ConsumerWidget {
  const _ShiftTile({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(shift.color);

    return PremiumPanel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.schedule_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${shift.startTime} - ${shift.endTime}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: shift.isEnabled,
            onChanged: (value) {
              ref.read(shiftsProvider.notifier).toggle(shift, value);
            },
          ),
        ],
      ),
    );
  }
}
