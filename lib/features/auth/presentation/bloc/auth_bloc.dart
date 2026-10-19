import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_flutter/core/error/failures.dart';
import '../../../../core/services/active_session_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final Stream<bool> authStateChanges;

  /// Servicio que persiste la sesión activa en SharedPreferences. Opcional
  /// para no romper tests que construyen el bloc en aislamiento; cuando está
  /// presente se limpia en logout para evitar sesiones fantasma.
  final ActiveSessionService? activeSessionService;
  late final StreamSubscription<bool> _authSubscription;

  AuthBloc({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signOut,
    required this.getCurrentUser,
    required this.authStateChanges,
    this.activeSessionService,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<UserProfileUpdated>(_onUserProfileUpdated);
    on<AuthErrorDismissed>((_, emit) {
      if (state is AuthError) emit(Unauthenticated());
    });

    _authSubscription = authStateChanges.listen((isAuthenticated) {
      add(AuthStateChanged(isAuthenticated: isAuthenticated));
    });
  }

  /// Convenience factory: takes the [AuthRepository] and wires the
  /// session stream from it. Useful for DI registration.
  factory AuthBloc.fromRepository({
    required AuthRepository authRepository,
    required SignInWithEmail signInWithEmail,
    required SignUpWithEmail signUpWithEmail,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    ActiveSessionService? activeSessionService,
  }) {
    return AuthBloc(
      signInWithEmail: signInWithEmail,
      signUpWithEmail: signUpWithEmail,
      signOut: signOut,
      getCurrentUser: getCurrentUser,
      authStateChanges: authRepository.authStateChanges,
      activeSessionService: activeSessionService,
    );
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    if (state is! AuthLoading) {
      emit(AuthLoading());
    }
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.isAuthenticated) {
      final result = await getCurrentUser();
      result.fold((failure) => emit(Unauthenticated()), (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      });
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthSubmitting) {
      emit(AuthSubmitting());
    }
    final result = await signInWithEmail(event.email, event.password);
    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) => _emitAuthenticatedFromCurrentUser(emit),
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthSubmitting) {
      emit(AuthSubmitting());
    }
    final result = await signUpWithEmail(
      event.email,
      event.password,
      event.fullName,
    );
    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) => _emitAuthenticatedFromCurrentUser(
        emit,
        noSession: AuthAwaitingEmailConfirmation(event.email),
      ),
    );
  }

  Future<void> _emitAuthenticatedFromCurrentUser(
    Emitter<AuthState> emit, {
    AuthState? noSession,
  }) async {
    final result = await getCurrentUser();
    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(noSession ?? Unauthenticated());
      }
    });
  }

  void _onUserProfileUpdated(
    UserProfileUpdated event,
    Emitter<AuthState> emit,
  ) {
    final current = state;
    if (current is! Authenticated) return;
    final newUser = current.user.copyWith(fullName: event.fullName);
    emit(Authenticated(newUser));
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthSubmitting) {
      emit(AuthSubmitting());
    }
    final result = await signOut();
    // Sin red el SDK ya borró la sesión local antes de fallar la llamada:
    // el usuario está fuera igual. Antes se mostraba "signOut failed: …" en
    // el login y la sesión activa local no se limpiaba.
    final signedOut = result.fold((f) => f is NetworkFailure, (_) => true);
    if (!signedOut) {
      emit(AuthError(result.fold((f) => f.message, (_) => '')));
      return;
    }
    // Limpiamos la sesión activa local antes de emitir Unauthenticated:
    // evita que `ActiveSessionWatcherBloc` reanude un entrenamiento del
    // usuario anterior al volver a entrar.
    await activeSessionService?.clear();
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
