import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercises_catalog.dart';

class SessionExerciseSelection {
  const SessionExerciseSelection({
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
  });

  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
}

class SessionExerciseSheet extends StatefulWidget {
  const SessionExerciseSheet({
    super.key,
    required this.getCatalog,
    required this.excludedExerciseIds,
    this.replacing,
    this.remainingSets,
  });

  final GetExercisesCatalog getCatalog;
  final Set<String> excludedExerciseIds;
  final Exercise? replacing;
  final int? remainingSets;

  static Future<SessionExerciseSelection?> show(
    BuildContext context, {
    required GetExercisesCatalog getCatalog,
    required Set<String> excludedExerciseIds,
    Exercise? replacing,
    int? remainingSets,
  }) => AdaptiveSheet.showRaw<SessionExerciseSelection>(
    context,
    builder: (_) => SessionExerciseSheet(
      getCatalog: getCatalog,
      excludedExerciseIds: excludedExerciseIds,
      replacing: replacing,
      remainingSets: remainingSets,
    ),
  );

  @override
  State<SessionExerciseSheet> createState() => _SessionExerciseSheetState();
}

class _SessionExerciseSheetState extends State<SessionExerciseSheet> {
  final _search = TextEditingController();
  late final TextEditingController _sets;
  final _reps = TextEditingController(text: '10');
  final _weight = TextEditingController(text: '0');
  Timer? _debounce;
  int _request = 0;
  bool _loading = true;
  bool _failed = false;
  List<ExerciseCatalogItem> _items = [];
  ExerciseCatalogItem? _selected;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(
      text: (widget.replacing != null ? widget.remainingSets ?? 3 : 3)
          .toString(),
    );
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final query = _search.text.trim();
    try {
      final result = await widget.getCatalog(
        search: query.isEmpty ? null : query,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        result.fold((_) => _failed = true, (items) {
          _items = items
              .where(
                (item) =>
                    !widget.excludedExerciseIds.contains(item.id) &&
                    item.id != widget.replacing?.id,
              )
              .toList();
        });
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    // Invalidate pending responses immediately, before the debounce fires.
    ++_request;
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 250), _load);
  }

  int? _integer(TextEditingController controller, int max) {
    final value = int.tryParse(controller.text.trim());
    return value != null && value >= 1 && value <= max ? value : null;
  }

  double? get _parsedWeight {
    final value = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    return value != null && value.isFinite && value >= 0 && value <= 10000
        ? value
        : null;
  }

  bool get _valid =>
      _selected != null &&
      _integer(_sets, 100) != null &&
      _integer(_reps, 1000) != null &&
      _parsedWeight != null;

  void _confirm() {
    if (!_valid) return;
    Navigator.of(context).pop(
      SessionExerciseSelection(
        exerciseId: _selected!.id,
        targetSets: _integer(_sets, 100)!,
        targetReps: _integer(_reps, 1000)!,
        targetWeight: _parsedWeight!,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  Widget _numberField(
    String label,
    TextEditingController controller,
    String? error, {
    bool decimal = false,
  }) => TextField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      errorText: error,
      border: const OutlineInputBorder(),
    ),
    onChanged: (_) => setState(() {}),
  );

  @override
  Widget build(BuildContext context) {
    final title = widget.replacing == null
        ? 'Añadir ejercicio extra'
        : 'Sustituir ejercicio';
    final theme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Solo esta sesión',
                style: theme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.replacing == null
                    ? 'Elige un ejercicio y confirma sus objetivos. Tu rutina habitual se conserva.'
                    : 'Sustituye ${widget.replacing!.name} para las series pendientes. Las series realizadas se conservan.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _search,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  labelText: 'Buscar ejercicio',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_failed) ...[
                const Text(
                  'No se pudo cargar el catálogo. Inténtalo de nuevo.',
                ),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ] else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay ejercicios disponibles para esta búsqueda.',
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (_, index) {
                      final item = _items[index];
                      final selected = _selected?.id == item.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        title: Text(item.name),
                        subtitle: Text(item.muscleGroup),
                        selected: selected,
                        trailing: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        onTap: () => setState(() => _selected = item),
                      );
                    },
                  ),
                ),
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Seleccionado: ${_selected!.name}',
                    style: theme.titleSmall,
                  ),
                ),
              const SizedBox(height: 20),
              _numberField(
                'Series',
                _sets,
                _integer(_sets, 100) == null
                    ? 'Introduce de 1 a 100 series'
                    : null,
              ),
              const SizedBox(height: 16),
              _numberField(
                'Repeticiones',
                _reps,
                _integer(_reps, 1000) == null
                    ? 'Introduce de 1 a 1000 repeticiones'
                    : null,
              ),
              const SizedBox(height: 16),
              _numberField(
                'Peso (kg)',
                _weight,
                _parsedWeight == null
                    ? 'Introduce un peso entre 0 y 10000 kg'
                    : null,
                decimal: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Usa 0 kg para ejercicios con peso corporal.',
                style: theme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _valid ? _confirm : null,
                child: Text(title),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
