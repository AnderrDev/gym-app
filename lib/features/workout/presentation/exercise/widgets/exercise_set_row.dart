import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

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

enum _FocusedField { none, weight, reps }

class _ExerciseSetRowState extends State<ExerciseSetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;
  // Cuál input está "seleccionado" (cursor + chips), independiente del teclado.
  _FocusedField _focused = _FocusedField.none;
  // Cuál input tiene el teclado abierto. Default: ninguno. Se activa con tap
  // explícito en el chip "✎ Tipear".
  _FocusedField _keyboardField = _FocusedField.none;
  // Snapshot del estado "dirty" (valores actuales != guardado). Lo trackeamos
  // como state para que la UI (tooltip, futuros affordances visuales) refleje
  // cuando tap ✓ va a re-guardar vs desmarcar.
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final w = _initialWeightFor(widget);
    final r = _initialRepsFor(widget);
    _weightCtrl = TextEditingController(text: _weightText(w));
    _repsCtrl = TextEditingController(text: _repsText(r));
    _weightFocus = FocusNode()..addListener(_onFocusChange);
    _repsFocus = FocusNode()..addListener(_onFocusChange);
    _weightCtrl.addListener(_recomputeDirty);
    _repsCtrl.addListener(_recomputeDirty);
  }

  /// Solo rebuildea cuando _dirty cruza el umbral (no por cada keystroke).
  void _recomputeDirty() {
    final next = _isDirty;
    if (next == _dirty) return;
    setState(() => _dirty = next);
  }

  void _onFocusChange() {
    final next = _weightFocus.hasFocus
        ? _FocusedField.weight
        : _repsFocus.hasFocus
        ? _FocusedField.reps
        : _FocusedField.none;
    if (next == _focused) return;
    setState(() {
      _focused = next;
      // Si cambiamos de campo (o perdemos focus), apagamos el modo teclado.
      if (next != _keyboardField) _keyboardField = _FocusedField.none;
    });
  }

  void _openKeyboardForFocused() {
    if (_focused == _FocusedField.none) return;
    setState(() => _keyboardField = _focused);
    // Flutter detecta el cambio de `keyboardType` (none → number) en el
    // próximo build y restablece la conexión con el sistema de input;
    // el teclado aparece automáticamente.
  }

  @override
  void didUpdateWidget(covariant ExerciseSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el target/last-performance del widget cambió externamente (p.ej. el
    // usuario editó el target remoto) y el usuario aún no tipeó nada custom
    // — es decir, el input matchea con el prefill anterior — sincronizamos
    // el controller con el nuevo prefill. Si el texto ya es custom, no lo
    // pisamos para no perder lo que escribió.
    _syncIfPristine(
      _weightCtrl,
      _weightText(_initialWeightFor(oldWidget)),
      _weightText(_initialWeightFor(widget)),
    );
    _syncIfPristine(
      _repsCtrl,
      _repsText(_initialRepsFor(oldWidget)),
      _repsText(_initialRepsFor(widget)),
    );
    // El log guardado pudo haber cambiado (re-save o desmarcar) — recomputo
    // el dirty para que el tooltip y futuro affordance reflejen el estado.
    _recomputeDirty();
  }

  static double _initialWeightFor(ExerciseSetRow w) {
    if (w.isDone) return w.completedLog!.actualWeight;
    return w.lastPerformanceLog?.actualWeight ?? w.targetWeight;
  }

  static int _initialRepsFor(ExerciseSetRow w) {
    if (w.isDone) return w.completedLog!.actualReps;
    return w.lastPerformanceLog?.actualReps ?? w.targetReps;
  }

  String _weightText(double w) => w > 0 ? _formatWeight(w) : '';
  String _repsText(int r) => r > 0 ? r.toString() : '';

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
    final text = next % 1 == 0
        ? next.toStringAsFixed(0)
        : next.toStringAsFixed(1);
    _weightCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    HapticFeedback.selectionClick();
  }

  void _bumpReps(int delta) {
    final current = int.tryParse(_repsCtrl.text) ?? 0;
    final next = (current + delta).clamp(0, 999);
    final text = next.toString();
    _repsCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    HapticFeedback.selectionClick();
  }

  /// `true` cuando la serie está guardada pero los valores actuales en los
  /// inputs difieren del log guardado. Bajo ese estado, tap ✓ re-guarda en
  /// vez de desmarcar.
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
      // Mismos valores que el guardado → toggle desmarcar.
      if (widget.onUnsaved == null) return;
      HapticFeedback.mediumImpact();
      widget.onUnsaved!(widget.setNumber);
      return;
    }
    // Caso nuevo (no done) o done con valores editados → guardar.
    if (reps <= 0) return;
    HapticFeedback.mediumImpact();
    widget.onSaved(
      SetLog(
        sessionId: widget.sessionId,
        exerciseId: widget.exerciseId,
        actualWeight: weight,
        actualReps: reps,
        setIndex: widget.setNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) return _buildReadOnly();
    return _buildEditable();
  }

  // ── Modo lectura (historial) ──────────────────────────────────────
  Widget _buildReadOnly() {
    final log = widget.completedLog;
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDone
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          _SetCircle(label: '${widget.setNumber}', filled: widget.isDone),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              log != null
                  ? '${_formatWeight(log.actualWeight)} kg × ${log.actualReps} reps'
                  : '— sin registro —',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: widget.isDone ? FontWeight.w600 : FontWeight.w400,
                color: widget.isDone
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          if (widget.isDone)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 18,
            ),
        ],
      ),
    );
  }

  // ── Modo edición (sesión activa) ──────────────────────────────────
  Widget _buildEditable() {
    final hasPrev = widget.lastPerformanceLog != null;
    final prevLabel = hasPrev
        ? '${_formatWeight(widget.lastPerformanceLog!.actualWeight)}×${widget.lastPerformanceLog!.actualReps}'
        : null;
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
              _SetCircle(
                label: '${widget.setNumber}',
                filled: widget.isDone,
                active: !widget.isDone,
              ),
              const SizedBox(width: 10),
              if (prevLabel != null) ...[
                SizedBox(
                  width: 54,
                  child: Text(
                    prevLabel,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: _CompactNumberField(
                  key: ValueKey(
                    'weight_${widget.exerciseId}_${widget.setNumber}',
                  ),
                  controller: _weightCtrl,
                  focusNode: _weightFocus,
                  suffix: 'kg',
                  decimal: true,
                  // `TextInputType.none` suprime el teclado del sistema
                  // sin bloquear edición programática (chips, paste, etc).
                  // El usuario habilita teclado tocando el chip ✎.
                  suppressKeyboard: _keyboardField != _FocusedField.weight,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 64,
                child: _CompactNumberField(
                  key: ValueKey(
                    'reps_${widget.exerciseId}_${widget.setNumber}',
                  ),
                  controller: _repsCtrl,
                  focusNode: _repsFocus,
                  suffix: 'reps',
                  decimal: false,
                  suppressKeyboard: _keyboardField != _FocusedField.reps,
                ),
              ),
              const SizedBox(width: 6),
              _SaveButton(
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
          // Chip strip de ajustes rápidos: aparece al focusear un input.
          // AnimatedSize anima el cambio de altura sin recrear widgets.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _focused == _FocusedField.none
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: _focused == _FocusedField.weight
                              ? _QuickStepStrip(
                                  steps: const [-2.5, -1, 1, 2.5],
                                  formatter: (v) => v > 0
                                      ? '+${_formatStep(v)}'
                                      : _formatStep(v),
                                  onTap: (v) => _bumpWeight(v),
                                )
                              : _QuickStepStrip(
                                  steps: const [-1, 1, 2],
                                  formatter: (v) => v > 0
                                      ? '+${v.toInt()}'
                                      : v.toInt().toString(),
                                  onTap: (v) => _bumpReps(v.toInt()),
                                ),
                        ),
                        const SizedBox(width: 6),
                        // Chip "Tipear": abre el teclado para valores
                        // arbitrarios. El tap normal en el campo solo
                        // muestra chips, nunca el teclado.
                        _KeyboardToggleChip(
                          isActive: _keyboardField == _focused,
                          onTap: _keyboardField == _focused
                              ? null
                              : _openKeyboardForFocused,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _formatStep(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _CompactNumberField extends StatelessWidget {
  const _CompactNumberField({
    super.key,
    required this.controller,
    required this.suffix,
    required this.decimal,
    this.focusNode,
    this.suppressKeyboard = false,
  });

  final TextEditingController controller;
  final String suffix;
  final bool decimal;
  final FocusNode? focusNode;
  // `true` => `TextInputType.none` (campo focuseable pero el sistema no
  // muestra el teclado). `false` => número con decimales según el flag.
  final bool suppressKeyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      showCursor: true,
      keyboardType: suppressKeyboard
          ? TextInputType.none
          : TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        suffixText: suffix,
        suffixStyle: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    super.key,
    required this.isDone,
    required this.accent,
    required this.onTap,
    this.tooltip,
  });

  final bool isDone;
  final Color accent;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDone ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 20,
          color: isDone ? AppColors.onPrimary : accent,
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Strip de chips `-2.5 / -1 / +1 / +2.5` (o el set de pasos que reciba).
/// Aparece debajo de la fila cuando el input está focuseado y mutan el
/// controller del campo. No piden focus, así el input no pierde el cursor.
class _QuickStepStrip extends StatelessWidget {
  const _QuickStepStrip({
    required this.steps,
    required this.formatter,
    required this.onTap,
  });

  final List<double> steps;
  final String Function(double) formatter;
  final void Function(double) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _QuickStepChip(
              label: formatter(steps[i]),
              onTap: () => onTap(steps[i]),
              positive: steps[i] > 0,
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyboardToggleChip extends StatelessWidget {
  const _KeyboardToggleChip({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.keyboard_alt_outlined, size: 16, color: color),
      ),
    );
  }
}

class _QuickStepChip extends StatelessWidget {
  const _QuickStepChip({
    required this.label,
    required this.onTap,
    required this.positive,
  });

  final String label;
  final VoidCallback onTap;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.primary : AppColors.textSecondary;
    // GestureDetector (no InkWell) para no robar el focus del TextField.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SetCircle extends StatelessWidget {
  final String label;
  final bool filled;
  final bool active;

  const _SetCircle({
    required this.label,
    required this.filled,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.success
        : active
        ? AppColors.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final border = filled
        ? AppColors.success
        : active
        ? AppColors.primary
        : AppColors.textSecondary;
    final textColor = filled
        ? AppColors.onPrimary
        : active
        ? AppColors.primary
        : AppColors.textSecondary;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
