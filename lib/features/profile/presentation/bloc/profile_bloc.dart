import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';

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

// ── State ──────────────────────────────────────────────────────────────────

enum ProfileSubmissionStatus { idle, submitting, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileSubmissionStatus.idle,
    this.lastSavedFullName,
    this.errorMessage,
  });

  final ProfileSubmissionStatus status;

  /// Nombre que la API confirmó haber persistido. La UI lo usa para
  /// notificar refreshes al `AuthBloc` (que mantiene el `User` global).
  final String? lastSavedFullName;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileSubmissionStatus? status,
    String? lastSavedFullName,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      lastSavedFullName: lastSavedFullName ?? this.lastSavedFullName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, lastSavedFullName, errorMessage];
}

// ── Bloc ───────────────────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this.repository}) : super(const ProfileState()) {
    on<UpdateFullNameRequested>(_onUpdateFullName);
    on<AcknowledgeProfileFeedback>(
      (_, emit) => emit(
        state.copyWith(status: ProfileSubmissionStatus.idle, clearError: true),
      ),
    );
  }

  final ProfileRepository repository;

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
}
