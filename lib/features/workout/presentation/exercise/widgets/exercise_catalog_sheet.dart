import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_catalog_tile.dart';

/// Bottom sheet de selección de ejercicios desde el catálogo real (Supabase).
///
/// Devuelve `List<ExerciseCatalogItem>` con los seleccionados (no incluye los
/// que ya estaban en el día). Filtros por grupo muscular y búsqueda libre.
class ExerciseCatalogSheet extends StatefulWidget {
  const ExerciseCatalogSheet({
    super.key,
    required this.catalog,
    this.alreadySelectedIds = const {},
  });

  /// Catálogo cargado desde el bloc.
  final List<ExerciseCatalogItem> catalog;

  /// Ids de ejercicios ya presentes en el día (se muestran bloqueados).
  final Set<String> alreadySelectedIds;

  @override
  State<ExerciseCatalogSheet> createState() => _ExerciseCatalogSheetState();
}

class _ExerciseCatalogSheetState extends State<ExerciseCatalogSheet> {
  static const String _allCategory = 'Todos';
  String _selectedCategory = _allCategory;
  String _searchQuery = '';

  /// Items seleccionados (no incluidos en `alreadySelectedIds`).
  final Set<String> _selectedIds = <String>{};

  List<String> get _categories {
    final muscles = widget.catalog
        .map((e) => e.muscleGroup)
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return [_allCategory, ...muscles];
  }

  List<ExerciseCatalogItem> get _filteredExercises {
    final query = _searchQuery.toLowerCase();
    return widget.catalog.where((e) {
      final matchesCategory =
          _selectedCategory == _allCategory ||
          e.muscleGroup == _selectedCategory;
      final matchesSearch =
          query.isEmpty || e.name.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<ExerciseCatalogItem> _buildResult() {
    return widget.catalog
        .where((e) => _selectedIds.contains(e.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(),
          _buildCategoryFilter(),
          const SizedBox(height: 8),
          Divider(color: context.colors.surfaceHighlight, height: 1),
          Expanded(
            child: _filteredExercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      final isAlreadyInDay = widget.alreadySelectedIds.contains(
                        exercise.id,
                      );
                      final isSelected =
                          isAlreadyInDay || _selectedIds.contains(exercise.id);
                      return ExerciseCatalogTile(
                        exercise: exercise,
                        isSelected: isSelected,
                        isAlreadyInDay: isAlreadyInDay,
                        onTap: () {
                          setState(() {
                            if (_selectedIds.contains(exercise.id)) {
                              _selectedIds.remove(exercise.id);
                            } else {
                              _selectedIds.add(exercise.id);
                            }
                          });
                          HapticFeedback.lightImpact();
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          pushExerciseDetail(context, exercise.id);
                        },
                      );
                    },
                  ),
          ),
          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.textDisabled,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.lgPlus,
            Spacing.xl,
            Spacing.sm,
          ),
          child: Row(
            children: [
              Text('Catálogo', style: context.text.headlineMedium),
              const Spacer(),
              Text(
                '${_selectedIds.length} seleccionados',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.surfaceHighlight, width: 0.5),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: context.text.bodyLarge,
          decoration: InputDecoration(
            icon: Icon(Icons.search_rounded, color: context.colors.textDisabled, size: 20),
            hintText: 'Press banca, sentadilla...',
            hintStyle: TextStyle(color: context.colors.textDisabled, fontSize: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final cats = _categories;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final cat = cats[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedCategory = cat);
                  HapticFeedback.selectionClick();
                }
              },
              backgroundColor: context.colors.surface,
              selectedColor: context.colors.primary,
              labelStyle: TextStyle(
                color: isSelected ? context.colors.onPrimary : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.surfaceHighlight,
                  width: 0.5,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: context.colors.textDisabled),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay ejercicios en esta categoría'
                : 'No encontramos nada para "$_searchQuery"',
            style: TextStyle(color: context.colors.textDisabled),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final hasSelection = _selectedIds.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        boxShadow: [
          BoxShadow(color: context.colors.overlay.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: ElevatedButton(
        onPressed: hasSelection
            ? () => Navigator.pop(context, _buildResult())
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.primary,
          disabledBackgroundColor: context.colors.surface,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          hasSelection
              ? 'Añadir ${_selectedIds.length} ejercicios'
              : 'Selecciona ejercicios',
          style: TextStyle(
            color: hasSelection ? context.colors.onPrimary : context.colors.textDisabled,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
