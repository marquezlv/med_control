import 'package:flutter/material.dart';

import '../models/medication_model.dart';
import '../services/medication.dart';
import 'medications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenMedicationManager,
    required this.refreshSignal,
  });

  final VoidCallback onOpenMedicationManager;
  final int refreshSignal;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MedicationService _service = MedicationService.instance;

  late Future<_HomeTodayData> _todayFuture;
  late DateTime _displayedMonth;

  static const Map<int, String> _weekdayLabels = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _todayFuture = _loadTodayData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _reload();
    }
  }

  Future<_HomeTodayData> _loadTodayData() async {
    final now = DateTime.now();
    final allMedications = await _service.getAllMedications();
    final medications = allMedications
        .where((medication) => medication.daysOfWeek.contains(now.weekday))
        .toList();
    final takenIds = await _service.getTakenMedicationIdsForDate(now);
    return _HomeTodayData(
      medications: medications,
      takenIds: takenIds,
      allMedications: allMedications,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _todayFuture = _loadTodayData();
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  Future<void> _onTakenChanged(MedicationModel medication, bool value) async {
    final id = medication.id;
    if (id == null) {
      return;
    }

    await _service.setMedicationTaken(
      medicationId: id,
      date: DateTime.now(),
      taken: value,
    );
    if (!mounted) {
      return;
    }
    await _reload();
  }

  Future<void> _openMedication(MedicationModel medication) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicationFormScreen(initialMedication: medication),
      ),
    );
    if (!mounted) {
      return;
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: FutureBuilder<_HomeTodayData>(
        future: _todayFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erro ao carregar dados: ${snapshot.error}'),
              ),
            );
          }

          final data =
              snapshot.data ??
              const _HomeTodayData(
                medications: <MedicationModel>[],
                takenIds: <int>{},
                allMedications: <MedicationModel>[],
              );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Medicamentos de hoje',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (data.medications.isEmpty)
                  Card(
                    child: ListTile(
                      title: const Text('Nenhum medicamento para hoje.'),
                      subtitle: const Text('Toque para abrir medicamentos.'),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: widget.onOpenMedicationManager,
                    ),
                  )
                else
                  for (final medication in data.medications)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _openMedication(medication),
                        leading: CircleAvatar(
                          backgroundColor: MedicationModel.parseColor(
                            medication.colorHex,
                          ),
                        ),
                        title: Text(medication.name),
                        subtitle: Text(
                          'Dose: ${medication.dosage} • Qtd: ${medication.quantity}',
                        ),
                        trailing: Checkbox(
                          value: data.takenIds.contains(medication.id),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            _onTakenChanged(medication, value);
                          },
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Calendário de medicamentos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                _MedicationWeekCalendar(
                  displayedMonth: _displayedMonth,
                  medications: data.allMedications,
                  weekdayLabels: _weekdayLabels,
                  onPreviousMonth: () => _changeMonth(-1),
                  onNextMonth: () => _changeMonth(1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeTodayData {
  const _HomeTodayData({
    required this.medications,
    required this.takenIds,
    required this.allMedications,
  });

  final List<MedicationModel> medications;
  final Set<int> takenIds;
  final List<MedicationModel> allMedications;
}

class _MedicationWeekCalendar extends StatelessWidget {
  const _MedicationWeekCalendar({
    required this.displayedMonth,
    required this.medications,
    required this.weekdayLabels,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime displayedMonth;
  final List<MedicationModel> medications;
  final Map<int, String> weekdayLabels;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  // Weekday order starting with Sunday (7), then Mon-Sat (1-6)
  static const List<int> _weekStartOrder = [7, 1, 2, 3, 4, 5, 6];

  List<DateTime> _buildCalendarDays() {
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;

    // Calculate leading empty days with Sunday-start logic
    var firstWeekday = firstDay.weekday;
    if (firstWeekday == 7) {
      firstWeekday = 0; // Sunday as 0 for alignment
    }
    final leadingEmptyDays = firstWeekday;

    // Add previous month's days to fill leading slots
    final previousMonthLastDay = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      0,
    ).day;
    final leadingDays = List<DateTime>.generate(
      leadingEmptyDays,
      (index) => DateTime(
        displayedMonth.year,
        displayedMonth.month - 1,
        previousMonthLastDay - leadingEmptyDays + index + 1,
      ),
    );

    // Current month days
    final currentDays = List<DateTime>.generate(
      daysInMonth,
      (index) => DateTime(displayedMonth.year, displayedMonth.month, index + 1),
    );

    // Add next month's days to fill trailing slots
    final totalSlots = leadingEmptyDays + daysInMonth;
    final trailingDays = List<DateTime>.generate(
      (7 - (totalSlots % 7)) % 7,
      (index) =>
          DateTime(displayedMonth.year, displayedMonth.month + 1, index + 1),
    );

    return [...leadingDays, ...currentDays, ...trailingDays];
  }

  List<MedicationModel> _medicationsForDate(DateTime date) {
    return medications
        .where((medication) => medication.daysOfWeek.contains(date.weekday))
        .toList();
  }

  /// Calculate expected quantity for a medication on a specific date,
  /// counting dosage deductions from today forward.
  int _calculateQuantityForDate(MedicationModel medication, DateTime date) {
    if (date.isBefore(DateTime.now())) {
      return medication.quantity; // Past dates: show current quantity
    }

    int qty = medication.quantity;
    DateTime currentDate = DateTime.now();

    while (!currentDate.isAfter(date)) {
      if (medication.daysOfWeek.contains(currentDate.weekday)) {
        qty -= medication.dosage;
        if (qty < 0) qty = 0;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return qty;
  }

  String _monthLabel() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[displayedMonth.month - 1]} ${displayedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final calendarDays = _buildCalendarDays();
    final legendMedications = [...medications]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Text(
                    _monthLabel(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next month',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weekday headers starting with Sunday
            Row(
              children: List<Widget>.generate(7, (index) {
                final weekday = _weekStartOrder[index];
                final label = weekday == 7
                    ? 'Dom'
                    : weekdayLabels[weekday] ?? '';
                return Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                );
              }),
            ),
            ...List<Widget>.generate(calendarDays.length ~/ 7, (rowIndex) {
              final week = calendarDays.skip(rowIndex * 7).take(7).toList();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: week.map((date) {
                  final isCurrentMonth = date.month == displayedMonth.month;
                  final isToday = DateUtils.isSameDay(date, today);
                  final dayMedications = _medicationsForDate(date);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Builder(
                        builder: (ctx) {
                          // Calculate visible balls for this day to determine height
                          final visibleBalls = dayMedications
                              .where(
                                (med) =>
                                    _calculateQuantityForDate(med, date) > 0,
                              )
                              .length;

                          // Adaptive height: base height expands for many balls
                          final minHeight = visibleBalls > 10
                              ? 80.0
                              : visibleBalls > 5
                              ? 70.0
                              : 50.0;

                          return Container(
                            constraints: BoxConstraints(minHeight: minHeight),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : isCurrentMonth
                                  ? Theme.of(context).colorScheme.surface
                                  : Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: isCurrentMonth
                                            ? null
                                            : Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.color
                                                  ?.withValues(alpha: 0.5),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                if (isCurrentMonth)
                                  Wrap(
                                    spacing: 3,
                                    runSpacing: 3,
                                    children: dayMedications.map((medication) {
                                      final qty = _calculateQuantityForDate(
                                        medication,
                                        date,
                                      );
                                      final isRunoutDay = qty <= 0;

                                      // Don't display the ball if medication has run out
                                      if (isRunoutDay) {
                                        return const SizedBox.shrink();
                                      }

                                      // Adaptive ball sizing based on medication count per day
                                      final ballSize =
                                          dayMedications.length > 10
                                          ? 4.0
                                          : dayMedications.length > 5
                                          ? 5.5
                                          : 7.0;

                                      return Tooltip(
                                        message: medication.name,
                                        child: Container(
                                          width: ballSize,
                                          height: ballSize,
                                          decoration: BoxDecoration(
                                            color: MedicationModel.parseColor(
                                              medication.colorHex,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                // Runout alerts - one day before it reaches 0
                                if (isCurrentMonth)
                                  ...dayMedications
                                      .where((med) {
                                        final qty = _calculateQuantityForDate(
                                          med,
                                          date,
                                        );
                                        final qtyTomorrow =
                                            _calculateQuantityForDate(
                                              med,
                                              date.add(const Duration(days: 1)),
                                            );
                                        // Show alert one day before runout
                                        return qty > 0 && qtyTomorrow <= 0;
                                      })
                                      .map((med) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => _showRunoutAlert(
                                              context,
                                              med.name,
                                              date.add(const Duration(days: 1)),
                                            ),
                                            child: const Tooltip(
                                              message:
                                                  'Medication will run out soon',
                                              child: Icon(
                                                Icons.warning_rounded,
                                                size: 14,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 16),
            Text('Legenda', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (legendMedications.isEmpty)
              Text(
                'Nenhum medicamento registrado ainda.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: legendMedications.map((medication) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: MedicationModel.parseColor(
                              medication.colorHex,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(medication.name),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showRunoutAlert(
    BuildContext context,
    String medicationName,
    DateTime runoutDate,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Medicação acaba esse dia'),
          content: Text(
            'Esta medicação "$medicationName" acabará em ${runoutDate.day.toString().padLeft(2, '0')}-${runoutDate.month.toString().padLeft(2, '0')}-${runoutDate.year}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
