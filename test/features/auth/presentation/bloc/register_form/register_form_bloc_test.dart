import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/register_form/register_form_state.dart';

void main() {
  group('RegisterFormBloc', () {
    test('estado inicial: tres inputs pure, no válido', () {
      final bloc = RegisterFormBloc();
      expect(bloc.state.fullName.isPure, isTrue);
      expect(bloc.state.email.isPure, isTrue);
      expect(bloc.state.password.isPure, isTrue);
      expect(bloc.state.isValid, isFalse);
    });

    blocTest<RegisterFormBloc, RegisterFormState>(
      'tres inputs válidos → isValid',
      build: RegisterFormBloc.new,
      act: (bloc) => bloc
        ..add(const RegisterFullNameChanged('Ander'))
        ..add(const RegisterEmailChanged('a@example.com'))
        ..add(const RegisterPasswordChanged('Str0ng!Pass')),
      verify: (bloc) {
        expect(bloc.state.isValid, isTrue);
      },
    );

    blocTest<RegisterFormBloc, RegisterFormState>(
      'fullName de un carácter → tooShort',
      build: RegisterFormBloc.new,
      act: (bloc) => bloc.add(const RegisterFullNameChanged('A')),
      verify: (bloc) {
        expect(bloc.state.fullName.isValid, isFalse);
      },
    );
  });
}
