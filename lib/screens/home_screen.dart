import 'package:flutter/material.dart';

import '../models/medication_model.dart';
import '../services/medication.dart';
import 'medications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenMedicationManager});

  final VoidCallback onOpenMedicationManager;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MedicationService _service = MedicationService.instance;

  late Future<_HomeTodayData> _todayFuture;

  @override
  void initState() {
    super.initState();
    _todayFuture = _loadTodayData();
  }

  Future<_HomeTodayData> _loadTodayData() async {
    final now = DateTime.now();
    final medications = await _service.getMedicationsForWeekday(now.weekday);
    final takenIds = await _service.getTakenMedicationIdsForDate(now);
    return _HomeTodayData(medications: medications, takenIds: takenIds);
  }

  Future<void> _reload() async {
    setState(() {
      _todayFuture = _loadTodayData();
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
      appBar: AppBar(title: const Text('Home')),
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
                child: Text('Error loading home data: ${snapshot.error}'),
              ),
            );
          }

          final data =
              snapshot.data ??
              const _HomeTodayData(
                medications: <MedicationModel>[],
                takenIds: <int>{},
              );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Medicine today',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (data.medications.isEmpty)
                  Card(
                    child: ListTile(
                      title: const Text('No medications for today.'),
                      subtitle: const Text('Tap to open medications.'),
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
                        subtitle: Text('Dosage: ${medication.dosage}'),
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeTodayData {
  const _HomeTodayData({required this.medications, required this.takenIds});

  final List<MedicationModel> medications;
  final Set<int> takenIds;
}
