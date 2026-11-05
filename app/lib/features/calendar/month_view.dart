import 'package:flutter/material.dart';

import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/features/calendar/sale_card.dart';
import 'package:brandnest/features/calendar/sale_phase.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Weeks start on Monday, the way a Pakistani wall calendar does.
const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class MonthView extends StatefulWidget {
  const MonthView({
    super.key,
    required this.sales,
    required this.now,
    required this.onRefresh,
  });

  final List<SaleEvent> sales;
  final DateTime now;
  final Future<void> Function() onRefresh;

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  late DateTime _month = DateTime(widget.now.year, widget.now.month);
  late DateTime _selectedDay = DateTime(
    widget.now.year,
    widget.now.month,
    widget.now.day,
  );

  @override
  Widget build(BuildContext context) {
    final undated = widget.sales.where(isUndated).toList();
    final onSelectedDay = widget.sales
        .where((sale) => coversDay(sale, _selectedDay))
        .toList();
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _MonthHeader(
            month: _month,
            onStep: (months) => setState(
              () => _month = DateTime(_month.year, _month.month + months),
            ),
          ),
          _DayGrid(
            month: _month,
            today: widget.now,
            selectedDay: _selectedDay,
            hasSale: _hasSale,
            onSelect: (day) => setState(() => _selectedDay = day),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'On ${formatDay(_selectedDay)}',
            sales: onSelectedDay,
            now: widget.now,
            emptyText: 'No sale runs on this day.',
          ),
          // Brands often announce a sale without an end date; those belong to no
          // square on the grid, but they are the ones running right now.
          if (undated.isNotEmpty)
            _Section(title: 'Running now, no end date announced', sales: undated, now: widget.now),
        ],
      ),
    );
  }

  bool _hasSale(DateTime day) => widget.sales.any((sale) => coversDay(sale, day));
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onStep});

  final DateTime month;
  final void Function(int months) onStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => onStep(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Text(
          '${_monthNames[month.month - 1]} ${month.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: () => onStep(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.today,
    required this.selectedDay,
    required this.hasSale,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selectedDay;
  final bool Function(DateTime) hasSale;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month);
    final blanksBefore = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return Column(
      children: [
        Row(
          children: [
            for (final initial in _weekdayInitials)
              Expanded(
                child: Center(
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var index = 0; index < blanksBefore; index++) const SizedBox(),
            for (var dayNumber = 1; dayNumber <= daysInMonth; dayNumber++)
              _DayCell(
                day: DateTime(month.year, month.month, dayNumber),
                today: today,
                selectedDay: selectedDay,
                hasSale: hasSale(DateTime(month.year, month.month, dayNumber)),
                onSelect: onSelect,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.selectedDay,
    required this.hasSale,
    required this.onSelect,
  });

  final DateTime day;
  final DateTime today;
  final DateTime selectedDay;
  final bool hasSale;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = _sameDay(day, selectedDay);
    final isToday = _sameDay(day, today);
    return InkWell(
      onTap: () => onSelect(day),
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? theme.colorScheme.primary : null,
              border: isToday && !isSelected
                  ? Border.all(color: theme.colorScheme.primary)
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimary : null,
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 5,
            child: hasSale
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: const SizedBox(width: 5, height: 5),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.sales,
    required this.now,
    this.emptyText,
  });

  final String title;
  final List<SaleEvent> sales;
  final DateTime now;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: theme.textTheme.titleSmall),
        ),
        if (sales.isEmpty && emptyText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emptyText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        for (final sale in sales) SaleCard(sale: sale, now: now),
      ],
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
