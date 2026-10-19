import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/login_form/login_form_state.dart';

void main() {
  group('LoginFormBloc', () {
    test('estado inicial: ambos pure, no válido', () {
      final bloc = LoginFormBloc();
      expect(bloc.state.email.isPure, isTrue);
      expect(bloc.state.password.isPure, isTrue);
      expect(bloc.state.isValid, isFalse);
    });

    blocTest<LoginFormBloc, LoginFormState>(
      'EmailChanged + PasswordChanged → isValid cuando ambos válidos',
      build: LoginFormBloc.new,
      act: (bloc) => bloc
        ..add(const LoginEmailChanged('user@example.com'))
        ..add(const LoginPasswordChanged('Str0ng!Pass')),
      verify: (bloc) {
        expect(bloc.state.isValid, isTrue);
      },
    );

    blocTest<LoginFormBloc, LoginFormState>(
      'email mal formateado → state.email.error.invalid',
      build: LoginFormBloc.new,
      act: (bloc) => bloc.add(const LoginEmailChanged('no-es-email')),
      verify: (bloc) {
        expect(bloc.state.email.isValid, isFalse);
        expect(bloc.state.isValid, isFalse);
      },
    );

    blocTest<LoginFormBloc, LoginFormState>(
      'password corto → state.password.error.tooShort',
      build: LoginFormBloc.new,
      act: (bloc) => bloc.add(const LoginPasswordChanged('123')),
      verify: (bloc) {
        expect(bloc.state.password.isValid, isFalse);
      },
    );
  });
}
