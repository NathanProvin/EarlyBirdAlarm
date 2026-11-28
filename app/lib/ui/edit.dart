import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../store.dart';

const _snoozeChoices = [5, 10, 15];
const _backupChoices = [3, 5, 10, 0]; // 0 = no backup alarm

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
  // Rebuilds the wheel when the dial sets the time (a wheel's start is read once).
  var _wheel = 0;

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
    setState(() {
      _a
        ..hour = t.hour
        ..minute = t.minute;
      _wheel++;
    });
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
        // A 40 dp circle with Android's 48 dp touch target: 7 × 48 dp fit a phone's width.
        tapTargetSize: MaterialTapTargetSize.padded,
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
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // The iPhone's scrolling numbers (1.4.1, user): a tick at each number; the
          // former dial stays behind the clock button.
          _TimeWheel(
            key: ValueKey(_wheel),
            hour: _a.hour,
            minute: _a.minute,
            onChanged: (h, m) => setState(
              () => _a
                ..hour = h
                ..minute = m,
            ),
          ),
          Center(
            child: IconButton(
              onPressed: _pickTime,
              tooltip: MaterialLocalizations.of(context).dialModeButtonLabel,
              icon: const Icon(Icons.schedule),
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
          const SizedBox(height: 8),
          DropdownButton<int>(
            value: _a.backupMinutes,
            isExpanded: true,
            items: [
              for (final m in _backupChoices)
                DropdownMenuItem(
                  value: m,
                  child: Text(m == 0 ? l.backupOff : l.backupMinutes(m)),
                ),
            ],
            onChanged: (m) => setState(() => _a.backupMinutes = m!),
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}

/// The iPhone's scrolling numbers (1.4.1, user): hours and minutes (and AM/PM on a 12-hour
/// phone) on looping wheels, big and spaced, a tick at each number. Its start is read once.
class _TimeWheel extends StatefulWidget {
  const _TimeWheel({
    required this.hour,
    required this.minute,
    required this.onChanged,
    super.key,
  });
  final int hour, minute;
  final void Function(int hour, int minute) onChanged;

  @override
  State<_TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<_TimeWheel> {
  late int _h = widget.hour, _m = widget.minute;
  late final _hours = FixedExtentScrollController(
    initialItem: MediaQuery.alwaysUse24HourFormatOf(context) ? _h : _h % 12,
  );
  late final _minutes = FixedExtentScrollController(initialItem: _m);
  late final _half = FixedExtentScrollController(initialItem: _h ~/ 12);

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _half.dispose();
    super.dispose();
  }

  void _set(int h, int m) {
    HapticFeedback.selectionClick();
    _h = h;
    _m = m;
    widget.onChanged(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context)
        .textTheme
        .displayMedium
        ?.copyWith(color: scheme.onSurface);
    final loc = MaterialLocalizations.of(context);
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    const extent = 72.0;
    Widget wheel(
      FixedExtentScrollController c,
      int count,
      String Function(int) label,
      ValueChanged<int> onPick, {
      bool loop = true,
      double width = 104,
    }) => SizedBox(
      width: width,
      child: CupertinoPicker(
        scrollController: c,
        itemExtent: extent,
        looping: loop,
        selectionOverlay: null, // one band behind all the wheels
        onSelectedItemChanged: onPick,
        children: [
          for (var i = 0; i < count; i++)
            Center(child: Text(label(i), style: style)),
        ],
      ),
    );
    String two(int n) => n.toString().padLeft(2, '0');
    return SizedBox(
      height: extent * 3.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: extent,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (h24)
                wheel(_hours, 24, two, (i) => _set(i, _m))
              else
                // 12-hour: index 0 shows 12; AM/PM kept from the third wheel.
                wheel(
                  _hours,
                  12,
                  (i) => '${i == 0 ? 12 : i}',
                  (i) => _set(i + (_h >= 12 ? 12 : 0), _m),
                ),
              const SizedBox(width: 32),
              wheel(_minutes, 60, two, (i) => _set(_h, i)),
              if (!h24) ...[
                const SizedBox(width: 16),
                wheel(
                  _half,
                  2,
                  (i) => i == 0
                      ? loc.anteMeridiemAbbreviation
                      : loc.postMeridiemAbbreviation,
                  (i) => _set(_h % 12 + 12 * i, _m),
                  loop: false,
                  width: 88,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
