import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/medication_model.dart';
import '../services/medication.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key, required this.refreshSignal});

  final int refreshSignal;

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final MedicationService _service = MedicationService.instance;

  late Future<List<MedicationModel>> _medicationsFuture;

  @override
  void initState() {
    super.initState();
    _medicationsFuture = _service.getAllMedications();
  }

  @override
  void didUpdateWidget(covariant MedicationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _medicationsFuture = _service.getAllMedications();
    });
  }

  Future<void> _openMedicationForm([MedicationModel? medication]) async {
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

  Future<void> _confirmDelete(MedicationModel medication) async {
    final id = medication.id;
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete medication?'),
          content: Text('This will remove ${medication.name} permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _service.deleteMedication(id);
    if (!mounted) {
      return;
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          IconButton(
            onPressed: _openMedicationForm,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add medication',
          ),
        ],
      ),
      body: FutureBuilder<List<MedicationModel>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading medications: ${snapshot.error}'),
              ),
            );
          }

          final medications = snapshot.data ?? <MedicationModel>[];
          if (medications.isEmpty) {
            return Center(
              child: FilledButton.icon(
                onPressed: _openMedicationForm,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add your first medication'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: MedicationModel.parseColor(
                          medication.colorHex,
                        ),
                      ),
                      title: Text(medication.name),
                      subtitle: Text('Qty: ${medication.quantity}'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _MedicationInfoRow(
                          label: 'Dosage',
                          value: '${medication.dosage}',
                        ),
                        _MedicationInfoRow(
                          label: 'Days',
                          value: _formatDays(medication.daysOfWeek),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openMedicationForm(medication),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(medication),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDays(List<int> days) {
    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final names = days.map((day) => labels[day]).whereType<String>().toList();
    return names.join(', ');
  }
}

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key, this.initialMedication});

  final MedicationModel? initialMedication;

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MedicationService _service = MedicationService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _dosageController;
  late Color _selectedColor;

  final Set<int> _selectedDays = <int>{};
  bool _isSaving = false;

  static const Map<int, String> _weekdayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMedication;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _quantityController = TextEditingController(
      text: (initial?.quantity ?? 0).toString(),
    );
    _selectedColor = MedicationModel.parseColor(initial?.colorHex ?? '#E77070');
    _dosageController = TextEditingController(
      text: (initial?.dosage ?? 1).toString(),
    );
    _selectedDays.addAll(initial?.daysOfWeek ?? const <int>[1]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day of the week.')),
      );
      return;
    }

    final editing = widget.initialMedication;
    final medication = MedicationModel(
      id: editing?.id,
      name: _nameController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      colorHex: MedicationModel.colorToHex(_selectedColor),
      dosage: int.parse(_dosageController.text.trim()),
      daysOfWeek: _selectedDays.toList()..sort(),
    );

    setState(() {
      _isSaving = true;
    });

    if (editing == null) {
      await _service.createMedication(medication);
    } else {
      await _service.updateMedication(medication);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openColorPicker() async {
    Color tempColor = _selectedColor;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose medication color'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: tempColor,
                  enableAlpha: false,
                  displayThumbColor: true,
                  labelTypes: const [ColorLabelType.hex],
                  onColorChanged: (color) {
                    setDialogState(() {
                      tempColor = color;
                    });
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _selectedColor = tempColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialMedication != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit medication' : 'Add medication'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Medication name *'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Current quantity'),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 0) {
                  return 'Enter a valid quantity.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openColorPicker,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medication color',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(MedicationModel.colorToHex(_selectedColor)),
                        ],
                      ),
                    ),
                    const Icon(Icons.color_lens_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dosageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dosage per day'),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid dosage.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text('Days of week'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _weekdayLabels.entries.map((entry) {
                final selected = _selectedDays.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedDays.add(entry.key);
                      } else {
                        _selectedDays.remove(entry.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving...' : 'Save medication'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationInfoRow extends StatelessWidget {
  const _MedicationInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
