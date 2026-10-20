import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/services/local_user_data_cleaner.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_flutter/features/profile/domain/usecases/delete_account.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => const [];
}

class UpdateFullNameRequested extends ProfileEvent {
  const UpdateFullNameRequested({required this.userId, required this.fullName});

  final String userId;
  final String fullName;

  @override
  List<Object?> get props => [userId, fullName];
}

class AcknowledgeProfileFeedback extends ProfileEvent {
  const AcknowledgeProfileFeedback();
}

/// El usuario confirmó (escribiendo [confirmation]) que quiere eliminar su
/// cuenta.
class DeleteAccountRequested extends ProfileEvent {
  const DeleteAccountRequested({
    required this.userId,
    required this.confirmation,
  });

  final String userId;
  final String confirmation;

  @override
  List<Object?> get props => [userId, confirmation];
}

// ── State ──────────────────────────────────────────────────────────────────

enum ProfileSubmissionStatus { idle, submitting, success, failure }

/// Estado de la eliminación de cuenta, separado de [ProfileSubmissionStatus]
/// para que el sheet de nombre y la zona de peligro no se pisen el feedback.
enum AccountDeletionStatus { idle, deleting, deleted, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileSubmissionStatus.idle,
    this.lastSavedFullName,
    this.errorMessage,
    this.deletionStatus = AccountDeletionStatus.idle,
    this.deletionErrorMessage,
  });

  final ProfileSubmissionStatus status;

  /// Nombre que la API confirmó haber persistido. La UI lo usa para
  /// notificar refreshes al `AuthBloc` (que mantiene el `User` global).
  final String? lastSavedFullName;
  final String? errorMessage;

  final AccountDeletionStatus deletionStatus;
  final String? deletionErrorMessage;

  ProfileState copyWith({
    ProfileSubmissionStatus? status,
    String? lastSavedFullName,
    String? errorMessage,
    bool clearError = false,
    AccountDeletionStatus? deletionStatus,
    String? deletionErrorMessage,
    bool clearDeletionError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      lastSavedFullName: lastSavedFullName ?? this.lastSavedFullName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      deletionStatus: deletionStatus ?? this.deletionStatus,
      deletionErrorMessage: clearDeletionError
          ? null
          : (deletionErrorMessage ?? this.deletionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    lastSavedFullName,
    errorMessage,
    deletionStatus,
    deletionErrorMessage,
  ];
}

// ── Bloc ───────────────────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this.repository,
    required this.deleteAccount,
    required this.localDataCleaner,
    required this.signOut,
  }) : super(const ProfileState()) {
    on<UpdateFullNameRequested>(_onUpdateFullName);
    on<DeleteAccountRequested>(_onDeleteAccount);
    on<AcknowledgeProfileFeedback>(
      (_, emit) => emit(
        state.copyWith(
          status: ProfileSubmissionStatus.idle,
          clearError: true,
          deletionStatus: state.deletionStatus == AccountDeletionStatus.failure
              ? AccountDeletionStatus.idle
              : null,
          clearDeletionError: true,
        ),
      ),
    );
  }

  final ProfileRepository repository;
  final DeleteAccount deleteAccount;
  final LocalUserDataCleaner localDataCleaner;
  final SignOut signOut;

  Future<void> _onUpdateFullName(
    UpdateFullNameRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ProfileSubmissionStatus.submitting,
        clearError: true,
      ),
    );
    final result = await repository.updateFullName(
      userId: event.userId,
      fullName: event.fullName.trim(),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileSubmissionStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (savedName) => emit(
        state.copyWith(
          status: ProfileSubmissionStatus.success,
          lastSavedFullName: savedName ?? event.fullName.trim(),
        ),
      ),
    );
  }

  Future<void> _onDeleteAccount(
    DeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.deletionStatus == AccountDeletionStatus.deleting ||
        state.deletionStatus == AccountDeletionStatus.deleted) {
      return;
    }
    emit(
      state.copyWith(
        deletionStatus: AccountDeletionStatus.deleting,
        clearDeletionError: true,
      ),
    );

    final result = await deleteAccount(confirmation: event.confirmation);
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      // La cuenta sigue intacta: no se toca nada local.
      emit(
        state.copyWith(
          deletionStatus: AccountDeletionStatus.failure,
          deletionErrorMessage: failure.message,
        ),
      );
      return;
    }

    // La cuenta ya no existe en el servidor: limpiamos el dispositivo antes
    // de salir para no dejar datos del usuario borrado.
    await localDataCleaner.purgeUserData(event.userId);
    emit(state.copyWith(deletionStatus: AccountDeletionStatus.deleted));

    // Último paso: cerrar sesión. El SDK borra la sesión local antes de
    // llamar al servidor (que responde 403/404 para un usuario eliminado y
    // el SDK lo ignora), así que el AuthBloc recibe `signedOut` y el router
    // lleva a /login aunque la llamada falle.
    final signOutResult = await signOut();
    signOutResult.fold(
      (f) => AppLogger.instance.warning(
        'delete_account: signOut local falló tras borrar la cuenta: '
        '${f.message}',
      ),
      (_) {},
    );
  }
}
