import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
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
  final Stream<supabase.AuthState> authStateChanges;
  late final StreamSubscription _authSubscription;

  AuthBloc({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signOut,
    required this.getCurrentUser,
    Stream<supabase.AuthState>? authStateChanges,
  }) : authStateChanges =
           authStateChanges ??
           supabase.Supabase.instance.client.auth.onAuthStateChange,
       super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);

    // Escuchar automáticamente los cambios de estado de sesión (Supabase)
    // initialSession se dispara siempre al iniciar la app (con o sin sesión) y
    // es el único que resuelve el estado inicial, evitando la race condition
    // donde AppStarted lee currentUser antes de que Supabase restaure storage.
    _authSubscription = this.authStateChanges.listen((data) {
      final event = data.event;
      if (event == supabase.AuthChangeEvent.initialSession) {
        add(AuthStateChanged(isAuthenticated: data.session != null));
      } else if (event == supabase.AuthChangeEvent.signedIn ||
          event == supabase.AuthChangeEvent.userUpdated) {
        add(const AuthStateChanged(isAuthenticated: true));
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        add(const AuthStateChanged(isAuthenticated: false));
      }
    });
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    // Solo mostrar loading. El estado real lo resuelve el evento initialSession
    // de onAuthStateChange. Llamar getCurrentUser() aquí causaba Unauthenticated
    // prematuro porque currentUser es null antes de que Supabase restaure storage.
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
    result.fold((failure) {
      emit(AuthError(failure.message));
    }, (_) => null);
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
    result.fold((failure) {
      emit(AuthError(failure.message));
    }, (_) => null);
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthSubmitting) {
      emit(AuthSubmitting());
    }
    final result = await signOut();
    result.fold((failure) => emit(AuthError(failure.message)), (_) => null);
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
