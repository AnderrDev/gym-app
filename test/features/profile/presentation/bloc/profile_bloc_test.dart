import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileRepository repository;

  const tUserId = 'user-123';
  const tFullName = 'Ander Cifuentes';

  setUp(() {
    repository = MockProfileRepository();
  });

  ProfileBloc buildBloc() => ProfileBloc(repository: repository);

  group('UpdateFullNameRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emite submitting → success con el nombre persistido',
      build: () {
        when(
          () => repository.updateFullName(
            userId: any(named: 'userId'),
            fullName: any(named: 'fullName'),
          ),
        ).thenAnswer((_) async => const Right(tFullName));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const UpdateFullNameRequested(userId: tUserId, fullName: tFullName),
      ),
      expect: () => const [
        ProfileState(status: ProfileSubmissionStatus.submitting),
        ProfileState(
          status: ProfileSubmissionStatus.success,
          lastSavedFullName: tFullName,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.updateFullName(userId: tUserId, fullName: tFullName),
        ).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'trimea el nombre antes de delegar al repositorio',
      build: () {
        when(
          () => repository.updateFullName(
            userId: any(named: 'userId'),
            fullName: any(named: 'fullName'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const UpdateFullNameRequested(userId: tUserId, fullName: '   Ander  '),
      ),
      verify: (_) {
        verify(
          () => repository.updateFullName(userId: tUserId, fullName: 'Ander'),
        ).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'cuando la API devuelve null usa el trimmed input como lastSavedFullName',
      build: () {
        when(
          () => repository.updateFullName(
            userId: any(named: 'userId'),
            fullName: any(named: 'fullName'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const UpdateFullNameRequested(userId: tUserId, fullName: '  Ander  '),
      ),
      expect: () => const [
        ProfileState(status: ProfileSubmissionStatus.submitting),
        ProfileState(
          status: ProfileSubmissionStatus.success,
          lastSavedFullName: 'Ander',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite submitting → failure con el mensaje cuando el repo devuelve Left',
      build: () {
        when(
          () => repository.updateFullName(
            userId: any(named: 'userId'),
            fullName: any(named: 'fullName'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('boom')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const UpdateFullNameRequested(userId: tUserId, fullName: tFullName),
      ),
      expect: () => const [
        ProfileState(status: ProfileSubmissionStatus.submitting),
        ProfileState(
          status: ProfileSubmissionStatus.failure,
          errorMessage: 'boom',
        ),
      ],
    );
  });

  group('AcknowledgeProfileFeedback', () {
    blocTest<ProfileBloc, ProfileState>(
      'resetea status a idle y limpia errorMessage',
      build: buildBloc,
      seed: () => const ProfileState(
        status: ProfileSubmissionStatus.failure,
        errorMessage: 'algo falló',
      ),
      act: (bloc) => bloc.add(const AcknowledgeProfileFeedback()),
      expect: () => const [ProfileState(status: ProfileSubmissionStatus.idle)],
    );
  });
}
