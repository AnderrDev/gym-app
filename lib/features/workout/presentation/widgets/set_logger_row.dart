import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/set_log.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';

class SetLoggerRow extends StatefulWidget {
  final String sessionId;
  final String exerciseId;
  final int setIndex;
  final VoidCallback onSetSaved;

  const SetLoggerRow({
    super.key,
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
    required this.onSetSaved,
  });

  @override
  State<SetLoggerRow> createState() => _SetLoggerRowState();
}

class _SetLoggerRowState extends State<SetLoggerRow> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  bool _isSaved = false;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _saveSet() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    if (weight > 0 && reps > 0) {
      final setLog = SetLog(
        sessionId: widget.sessionId,
        exerciseId: widget.exerciseId,
        actualWeight: weight,
        actualReps: reps,
        setIndex: widget.setIndex,
      );

      context.read<WorkoutBloc>().add(AddSetLogEvent(setLog));
      setState(() {
        _isSaved = true;
      });
      widget.onSetSaved();

      // Clean up for next set input (optional depending on UX preference)
      _weightController.clear();
      _repsController.clear();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isSaved = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '${widget.setIndex}',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'lbs',
              hintStyle: AppTextStyles.bodyMedium,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'reps',
              hintStyle: AppTextStyles.bodyMedium,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        BlocConsumer<WorkoutBloc, WorkoutState>(
          listener: (context, state) {
            // Note: Listener handles global events like showing a snackbar.
            // But since BLoC state is single globally per feature, one set being saved
            // triggers it for all rows. In a prod app, SetLogSuccess would contain the exerciseId/setIndex.
          },
          builder: (context, state) {
            return IconButton(
              icon: Icon(
                _isSaved ? Icons.check_circle : Icons.save,
                color: _isSaved ? AppColors.accent : AppColors.primary,
              ),
              onPressed: _saveSet,
            );
          },
        ),
      ],
    );
  }
}
