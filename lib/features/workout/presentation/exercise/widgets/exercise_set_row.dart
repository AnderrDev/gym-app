import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_focus_parts.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_parts.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_readonly.dart';

/// Fila densa de tracking de una serie: una sola línea con inputs siempre
/// visibles (prev/target precargados) y un botón ✓ que guarda con 1 tap.
class ExerciseSetRow extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final bool isDone;
  final SetLog? completedLog;
  final SetLog? lastPerformanceLog;
  final String sessionId;
  final String exerciseId;
  final bool readOnly;
  final void Function(SetLog log) onSaved;
  final void Function(int setIndex)? onUnsaved;

  const ExerciseSetRow({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.isDone,
    required this.completedLog,
    required this.lastPerformanceLog,
    required this.sessionId,
    required this.exerciseId,
    required this.readOnly,
    required this.onSaved,
    this.onUnsaved,
  });

  @override
  State<ExerciseSetRow> createState() => _ExerciseSetRowState();
}

class _ExerciseSetRowState extends State<ExerciseSetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;
  // Cuál input está "seleccionado" (cursor + chips), independiente del teclado.
  SetRowFocusedField _focused = SetRowFocusedField.none;
  // Cuál input tiene el teclado abierto. Default: ninguno. Se activa con tap
  // explícito en el chip "✎ Tipear".
  SetRowFocusedField _keyboardField = SetRowFocusedField.none;
  // Snapshot del estado "dirty" (valores actuales != guardado). Lo trackeamos
  // como state para que la UI (tooltip, futuros affordances visuales) refleje
  // cuando tap ✓ va a re-guardar vs desmarcar.
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl =
        TextEditingController(text: _weightText(_initialWeightFor(widget)))
          ..addListener(_recomputeDirty);
    _repsCtrl = TextEditingController(text: _repsText(_initialRepsFor(widget)))
      ..addListener(_recomputeDirty);
    _weightFocus = FocusNode()..addListener(_onFocusChange);
    _repsFocus = FocusNode()..addListener(_onFocusChange);
  }

  // Solo rebuildea cuando _dirty cruza el umbral, no por cada keystroke.
  void _recomputeDirty() {
    final next = _isDirty;
    if (next == _dirty) return;
    setState(() => _dirty = next);
  }

  void _onFocusChange() {
    final next = _weightFocus.hasFocus
        ? SetRowFocusedField.weight
        : _repsFocus.hasFocus
        ? SetRowFocusedField.reps
        : SetRowFocusedField.none;
    if (next == _focused) return;
    setState(() {
      _focused = next;
      // Si cambiamos de campo (o perdemos focus), apagamos el modo teclado.
      if (next != _keyboardField) _keyboardField = SetRowFocusedField.none;
    });
  }

  // Flutter detecta el cambio de `keyboardType` (none → number) en el próximo
  // build y restablece la conexión con el sistema de input.
  void _openKeyboardForFocused() {
    if (_focused == SetRowFocusedField.none) return;
    setState(() => _keyboardField = _focused);
  }

  // Si target/last-performance cambió externamente y el usuario aún no
  // tipeó nada custom, sincronizamos el prefill. Si ya es custom, no lo
  // pisamos para no perder lo escrito.
  @override
  void didUpdateWidget(covariant ExerciseSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncIfPristine(_weightCtrl,
        _weightText(_initialWeightFor(oldWidget)),
        _weightText(_initialWeightFor(widget)));
    _syncIfPristine(_repsCtrl,
        _repsText(_initialRepsFor(oldWidget)),
        _repsText(_initialRepsFor(widget)));
    _recomputeDirty();
  }

  /// Prefill del peso para la serie en curso. Prioridad:
  ///   1. Si la serie ya está guardada → respeta lo registrado.
  ///   2. Última performance del ejercicio (RPC `get_last_exercise_performances`).
  ///   3. `target_weight` configurado en la rutina.
  /// Si ninguno aplica, devuelve 0 — el campo muestra "0" en vez de quedar
  /// vacío para que el usuario tenga un valor inicial sobre el cual ajustar.
  static double _initialWeightFor(ExerciseSetRow w) {
    if (w.isDone) return w.completedLog!.actualWeight;
    final last = w.lastPerformanceLog?.actualWeight;
    if (last != null && last > 0) return last;
    return w.targetWeight;
  }

  static int _initialRepsFor(ExerciseSetRow w) {
    if (w.isDone) return w.completedLog!.actualReps;
    final last = w.lastPerformanceLog?.actualReps;
    if (last != null && last > 0) return last;
    return w.targetReps;
  }

  String _weightText(double w) => _formatWeight(w);
  String _repsText(int r) => r.toString();

  void _syncIfPristine(
    TextEditingController ctrl,
    String previousPrefill,
    String nextPrefill,
  ) {
    if (previousPrefill == nextPrefill) return;
    if (ctrl.text != previousPrefill) return;
    ctrl.value = TextEditingValue(
      text: nextPrefill,
      selection: TextSelection.collapsed(offset: nextPrefill.length),
    );
  }

  String _formatWeight(double w) =>
      w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  void _bumpWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text) ?? 0.0;
    final next = (current + delta).clamp(0.0, 9999.0);
    final text =
        next % 1 == 0 ? next.toStringAsFixed(0) : next.toStringAsFixed(1);
    _weightCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    // En web el click del chip blurrea el TextField → `_focused` cae a
    // `none` y la fila de chips colapsa. Re-focuseamos para mantener los
    // chips visibles y permitir taps repetidos. En móvil esto es no-op
    // porque el touch no roba el focus.
    if (!_weightFocus.hasFocus) _weightFocus.requestFocus();
    HapticFeedback.selectionClick();
  }

  void _bumpReps(int delta) {
    final next = ((int.tryParse(_repsCtrl.text) ?? 0) + delta).clamp(0, 999);
    final text = next.toString();
    _repsCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (!_repsFocus.hasFocus) _repsFocus.requestFocus();
    HapticFeedback.selectionClick();
  }

  // tap ✓ re-guarda cuando hay edición pendiente; si no, desmarca.
  bool get _isDirty {
    if (!widget.isDone) return false;
    final saved = widget.completedLog;
    if (saved == null) return false;
    final w = double.tryParse(_weightCtrl.text) ?? 0.0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    return w != saved.actualWeight || r != saved.actualReps;
  }

  void _onTapCheck() {
    final weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    if (widget.isDone && !_isDirty) {
      if (widget.onUnsaved == null) return;
      HapticFeedback.mediumImpact();
      widget.onUnsaved!(widget.setNumber);
      return;
    }
    // No registrar una serie sin peso o sin reps. El usuario tiene que
    // capturar al menos un valor mayor a 0 en cada campo antes de marcar.
    if (weight <= 0 || reps <= 0) {
      HapticFeedback.lightImpact();
      // Focuseamos el primer campo que está en 0 para guiar al usuario.
      if (weight <= 0) {
        _weightFocus.requestFocus();
      } else {
        _repsFocus.requestFocus();
      }
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onSaved(SetLog(
      sessionId: widget.sessionId,
      exerciseId: widget.exerciseId,
      actualWeight: weight,
      actualReps: reps,
      setIndex: widget.setNumber,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return ExerciseSetRowReadOnly(
        setNumber: widget.setNumber,
        isDone: widget.isDone,
        completedLog: widget.completedLog,
      );
    }
    return _buildEditable();
  }

  // ── Modo edición (sesión activa) ──────────────────────────────────
  Widget _buildEditable() {
    final prev = widget.lastPerformanceLog;
    final prevLabel = prev == null
        ? null
        : '${_formatWeight(prev.actualWeight)}×${prev.actualReps}';
    final accent = widget.isDone ? AppColors.success : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isDone
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDone
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SetCircle(
                label: '${widget.setNumber}',
                filled: widget.isDone,
                active: !widget.isDone,
              ),
              const SizedBox(width: 10),
              if (prevLabel != null) ...[
                PrevPerformanceLabel(label: prevLabel),
                const SizedBox(width: 6),
              ],
              // `TextInputType.none` suprime el teclado del sistema sin
              // bloquear edición programática (chips, paste, etc). El usuario
              // habilita teclado tocando el chip ✎.
              Expanded(
                child: CompactNumberField(
                  key: ValueKey('weight_${widget.exerciseId}_${widget.setNumber}'),
                  controller: _weightCtrl,
                  focusNode: _weightFocus,
                  suffix: 'kg',
                  decimal: true,
                  suppressKeyboard: _keyboardField != SetRowFocusedField.weight,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 64,
                child: CompactNumberField(
                  key: ValueKey('reps_${widget.exerciseId}_${widget.setNumber}'),
                  controller: _repsCtrl,
                  focusNode: _repsFocus,
                  suffix: 'reps',
                  decimal: false,
                  suppressKeyboard: _keyboardField != SetRowFocusedField.reps,
                ),
              ),
              const SizedBox(width: 6),
              SetSaveButton(
                key: ValueKey('save_${widget.exerciseId}_${widget.setNumber}'),
                isDone: widget.isDone,
                accent: accent,
                onTap: _onTapCheck,
                tooltip: widget.isDone
                    ? (_dirty ? 'Guardar cambios' : 'Tocá para desmarcar')
                    : 'Guardar serie',
              ),
            ],
          ),
          FocusChipsRow(
            focused: _focused,
            keyboardField: _keyboardField,
            onBumpWeight: _bumpWeight,
            onBumpReps: _bumpReps,
            onOpenKeyboardForFocused: _openKeyboardForFocused,
          ),
        ],
      ),
    );
  }
}
