import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../store.dart';

const _snoozeChoices = [5, 10, 15];

/// Narrow weekday name for DateTime.monday..sunday.
String weekday(BuildContext context, int day) =>
    MaterialLocalizations.of(context).narrowWeekdays[day % 7];

String daysText(BuildContext context, Set<int> days) => days.isEmpty
    ? AppLocalizations.of(context).once
    : [
        for (var d = 1; d <= 7; d++)
          if (days.contains(d)) weekday(context, d),
      ].join(' ');

class EditScreen extends StatefulWidget {
  const EditScreen({this.alarm, super.key});
  final AlarmData? alarm; // null = new alarm

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final AlarmData _a =
      widget.alarm ?? AlarmData(id: store.nextId, hour: 7, minute: 0);
  late final _label = TextEditingController(text: _a.label);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _a.hour, minute: _a.minute),
    );
    if (t == null) return;
    setState(
      () => _a
        ..hour = t.hour
        ..minute = t.minute,
    );
  }

  Future<void> _save() async {
    _a
      ..label = _label.text.trim()
      ..enabled = true;
    await store.save(_a, AppLocalizations.of(context).guessTheBird);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await store.delete(_a);
    if (mounted) Navigator.of(context).pop();
  }

  /// A round day toggle; TalkBack reads the full day name.
  Widget _day(BuildContext context, int d) {
    final scheme = Theme.of(context).colorScheme;
    final on = _a.days.contains(d);
    // 2024-01-01 is a Monday, so day d is January d.
    final name = DateFormat.EEEE(Localizations.localeOf(context).toString())
        .format(DateTime(2024, 1, d));
    return IconButton(
      tooltip: name,
      isSelected: on,
      onPressed: () => setState(
        () => _a.days = on ? ({..._a.days}..remove(d)) : {..._a.days, d},
      ),
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 7 × 48 dp don't fit
        backgroundColor: on ? scheme.primary : null,
        foregroundColor: on ? scheme.onPrimary : scheme.onSurface,
        side: on ? null : BorderSide(color: scheme.onSurface),
      ),
      icon: Text(weekday(context, d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.alarm != null)
            IconButton(
              onPressed: _delete,
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextButton(
            onPressed: _pickTime,
            child: Text(
              TimeOfDay(hour: _a.hour, minute: _a.minute).format(context),
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (var d = 1; d <= 7; d++) Expanded(child: _day(context, d)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: l.label),
          ),
          const SizedBox(height: 24),
          DropdownButton<int>(
            value: _a.snoozeMinutes,
            isExpanded: true,
            items: [
              for (final m in _snoozeChoices)
                DropdownMenuItem(value: m, child: Text(l.snoozeMinutes(m))),
            ],
            onChanged: (m) => setState(() => _a.snoozeMinutes = m!),
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}
