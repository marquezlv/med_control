import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../services/note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.refreshSignal});

  final int refreshSignal;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _service = NoteService.instance;

  late Future<List<NoteModel>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = _service.getAllNotes();
  }

  @override
  void didUpdateWidget(covariant NotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _notesFuture = _service.getAllNotes();
    });
  }

  Future<void> _openNoteForm([NoteModel? note]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteFormScreen(initialNote: note),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _confirmDelete(NoteModel note) async {
    final id = note.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir nota?'),
          content: const Text('Esta nota será removida permanentemente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _service.deleteNote(id);
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteForm(),
        tooltip: 'Nova nota',
        child: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<List<NoteModel>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erro ao carregar notas: ${snapshot.error}'),
              ),
            );
          }

          final notes = snapshot.data ?? <NoteModel>[];
          if (notes.isEmpty) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => _openNoteForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar primeira nota'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () => _openNoteForm(note),
                      onLongPress: () => _confirmDelete(note),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.title != null &&
                                note.title!.trim().isNotEmpty) ...[
                              Text(
                                note.title!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              _formatDateTime(note.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
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

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({super.key, this.initialNote});

  final NoteModel? initialNote;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final NoteService _service = NoteService.instance;
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialNote?.title ?? '');
    _textController =
        TextEditingController(text: widget.initialNote?.text ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final editing = widget.initialNote;
    final titleText = _titleController.text.trim();
    if (editing == null) {
      await _service.createNote(
        NoteModel(
          text: _textController.text.trim(),
          createdAt: DateTime.now(),
          title: titleText.isEmpty ? null : titleText,
        ),
      );
    } else {
      await _service.updateNote(
        editing.copyWith(
          text: _textController.text.trim(),
          title: titleText.isEmpty ? null : titleText,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialNote != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar nota' : 'Nova nota'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Categoria (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Escreva sua nota aqui...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A nota não pode estar vazia.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
