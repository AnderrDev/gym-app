import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

/// Estado base que todo `FormBloc` extiende.
///
/// Contiene `inputs` (lista de `FormzInput` para `Formz.validate`),
/// el `submissionStatus` y un `errorMessage` opcional para errores no
/// triviales (network/server) que no caben en un input específico.
abstract class FormStateBase extends Equatable {
  const FormStateBase({
    required this.inputs,
    this.submissionStatus = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  final List<FormzInput<dynamic, dynamic>> inputs;
  final FormzSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isValid => Formz.validate(inputs);

  bool get isSubmitting => submissionStatus == FormzSubmissionStatus.inProgress;

  bool get isSubmitDisabled => isSubmitting || !isValid;

  @override
  List<Object?> get props => [...inputs, submissionStatus, errorMessage];
}

/// Bloc base que toda feature de formulario puede extender. Mantiene un
/// patrón uniforme para validación reactiva y submission.
abstract class FormBlocBase<E, S extends FormStateBase> extends Bloc<E, S> {
  FormBlocBase(super.initialState);
}
