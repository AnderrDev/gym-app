import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ExerciseCatalogSheet extends StatefulWidget {
  final List<String> selectedExerciseIds;
  const ExerciseCatalogSheet({super.key, this.selectedExerciseIds = const []});

  @override
  State<ExerciseCatalogSheet> createState() => _ExerciseCatalogSheetState();
}

class _ExerciseCatalogSheetState extends State<ExerciseCatalogSheet> {
  String _selectedCategory = 'Todos';
  final List<String> _categories = ['Todos', 'Pecho', 'Espalda', 'Pierna', 'Hombro', 'Brazo', 'Abs'];
  String _searchQuery = '';

  // Mock global list of exercises
  final List<Map<String, String>> _allExercises = [
    {'name': 'Press de Banca Plano', 'target': 'Pecho'},
    {'name': 'Press Inclinado Manc.', 'target': 'Pecho'},
    {'name': 'Aperturas en Polea', 'target': 'Pecho'},
    {'name': 'Dominadas Pronas', 'target': 'Espalda'},
    {'name': 'Remo con Barra', 'target': 'Espalda'},
    {'name': 'Jalón al Pecho', 'target': 'Espalda'},
    {'name': 'Sentadilla Libre', 'target': 'Pierna'},
    {'name': 'Prensa de Piernas', 'target': 'Pierna'},
    {'name': 'Extensión Cuádriceps', 'target': 'Pierna'},
    {'name': 'Curl de Bíceps Barra', 'target': 'Brazo'},
    {'name': 'Martillo Mancuernas', 'target': 'Brazo'},
    {'name': 'Extensión de Tríceps', 'target': 'Brazo'},
    {'name': 'Press Militar Barra', 'target': 'Hombro'},
    {'name': 'Elevaciones Laterales', 'target': 'Hombro'},
    {'name': 'Crunch Abdominal', 'target': 'Abs'},
    {'name': 'Elevación de Piernas', 'target': 'Abs'},
  ];

  final List<Map<String, String>> _selectedExercises = [];

  List<Map<String, String>> get _filteredExercises {
    return _allExercises.where((e) {
      final matchesCategory = _selectedCategory == 'Todos' || e['target'] == _selectedCategory;
      final matchesSearch = e['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // ── Handle & Header ──────────────────────────────────────
          _buildHeader(context),
          
          // ── Search Bar ───────────────────────────────────────────
          _buildSearchBar(),

          // ── Categories ───────────────────────────────────────────
          _buildCategoryFilter(),

          const SizedBox(height: 8),
          const Divider(color: AppColors.surfaceHighlight, height: 1),

          // ── Exercise list ────────────────────────────────────────
          Expanded(
            child: _filteredExercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _filteredExercises[index];
                    final isAlreadyInDay = widget.selectedExerciseIds.contains(exercise['name']); // Simplificación por ahora
                    final isSelected = isAlreadyInDay || _selectedExercises.any((e) => e['name'] == exercise['name']);
                    return _buildExerciseTile(exercise, isSelected, isAlreadyInDay);
                  },
                  ),
          ),

          // ── Bottom Action ────────────────────────────────────────
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
          width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.textDisabled, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Text('Catálogo', style: AppTextStyles.heading2),
              const Spacer(),
              Text('${_selectedExercises.length} seleccionados', 
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceHighlight, width: 0.5),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            icon: const Icon(Icons.search, color: AppColors.textDisabled, size: 20),
            hintText: 'Press banca, sentadilla...',
            hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
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
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.surfaceHighlight, width: 0.5),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseTile(Map<String, String> exercise, bool isSelected, bool isAlreadyInDay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isAlreadyInDay 
            ? AppColors.textDisabled.withOpacity(0.1)
            : (isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        enabled: !isAlreadyInDay,
        onTap: isAlreadyInDay ? null : () {
          setState(() {
            if (isSelected) {
              _selectedExercises.removeWhere((e) => e['name'] == exercise['name']);
            } else {
              _selectedExercises.add(exercise);
            }
          });
          HapticFeedback.lightImpact();
        },
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isAlreadyInDay 
                ? AppColors.surfaceHighlight 
                : (isSelected ? AppColors.primary : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isAlreadyInDay ? Icons.lock_outline : (isSelected ? Icons.check : Icons.fitness_center_outlined),
            color: isSelected && !isAlreadyInDay ? Colors.black : AppColors.textDisabled,
            size: 18,
          ),
        ),
        title: Text(exercise['name']!, style: AppTextStyles.bodyLarge.copyWith(
          color: isAlreadyInDay 
              ? AppColors.textDisabled 
              : (isSelected ? AppColors.primary : AppColors.textPrimary),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
        subtitle: Text(
          isAlreadyInDay ? 'Ya en tu rutina' : exercise['target']!, 
          style: AppTextStyles.label.copyWith(color: AppColors.textDisabled)
        ),
        trailing: isAlreadyInDay 
            ? null 
            : (isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text('No encontramos nada para "$_searchQuery"', style: TextStyle(color: AppColors.textDisabled)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    bool hasSelection = _selectedExercises.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: ElevatedButton(
        onPressed: hasSelection ? () => Navigator.pop(context, _selectedExercises) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.surface,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          hasSelection ? 'Añadir ${_selectedExercises.length} ejercicios' : 'Selecciona ejercicios',
          style: TextStyle(
            color: hasSelection ? Colors.black : AppColors.textDisabled,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
