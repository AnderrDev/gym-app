import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileRepository repository;
  late MockDeleteAccount deleteAccount;
  late MockLocalUserDataCleaner cleaner;
  late MockSignOut signOut;

  const tUserId = 'user-123';
  const tFullName = 'Ander Cifuentes';

  setUp(() {
    repository = MockProfileRepository();
    deleteAccount = MockDeleteAccount();
    cleaner = MockLocalUserDataCleaner();
    signOut = MockSignOut();
  });

  ProfileBloc buildBloc() => ProfileBloc(
    repository: repository,
    deleteAccount: deleteAccount,
    localDataCleaner: cleaner,
    signOut: signOut,
  );

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

  group('DeleteAccountRequested', () {
    const event = DeleteAccountRequested(
      userId: tUserId,
      confirmation: 'ELIMINAR',
    );

    blocTest<ProfileBloc, ProfileState>(
      'éxito: borra en servidor, limpia el dispositivo, emite deleted y '
      'cierra sesión (en ese orden)',
      build: () {
        when(
          () => deleteAccount(confirmation: any(named: 'confirmation')),
        ).thenAnswer((_) async => const Right(null));
        when(() => cleaner.purgeUserData(any())).thenAnswer((_) async {});
        when(() => signOut()).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(event),
      expect: () => const [
        ProfileState(deletionStatus: AccountDeletionStatus.deleting),
        ProfileState(deletionStatus: AccountDeletionStatus.deleted),
      ],
      verify: (_) {
        verifyInOrder([
          () => deleteAccount(confirmation: 'ELIMINAR'),
          () => cleaner.purgeUserData(tUserId),
          () => signOut(),
        ]);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'éxito aunque signOut falle: la cuenta ya no existe, sigue en deleted',
      build: () {
        when(
          () => deleteAccount(confirmation: any(named: 'confirmation')),
        ).thenAnswer((_) async => const Right(null));
        when(() => cleaner.purgeUserData(any())).thenAnswer((_) async {});
        when(
          () => signOut(),
        ).thenAnswer((_) async => const Left(AuthFailure('403')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(event),
      expect: () => const [
        ProfileState(deletionStatus: AccountDeletionStatus.deleting),
        ProfileState(deletionStatus: AccountDeletionStatus.deleted),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'fallo: emite failure con el mensaje y no limpia nada ni cierra sesión',
      build: () {
        when(
          () => deleteAccount(confirmation: any(named: 'confirmation')),
        ).thenAnswer((_) async => const Left(ServerFailure('sin servidor')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(event),
      expect: () => const [
        ProfileState(deletionStatus: AccountDeletionStatus.deleting),
        ProfileState(
          deletionStatus: AccountDeletionStatus.failure,
          deletionErrorMessage: 'sin servidor',
        ),
      ],
      verify: (_) {
        verifyNever(() => cleaner.purgeUserData(any()));
        verifyNever(() => signOut());
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'ignora una segunda petición mientras ya se está eliminando',
      build: buildBloc,
      seed: () =>
          const ProfileState(deletionStatus: AccountDeletionStatus.deleting),
      act: (bloc) => bloc.add(event),
      expect: () => const <ProfileState>[],
      verify: (_) {
        verifyNever(
          () => deleteAccount(confirmation: any(named: 'confirmation')),
        );
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'AcknowledgeProfileFeedback devuelve un fallo de borrado a idle',
      build: buildBloc,
      seed: () => const ProfileState(
        deletionStatus: AccountDeletionStatus.failure,
        deletionErrorMessage: 'x',
      ),
      act: (bloc) => bloc.add(const AcknowledgeProfileFeedback()),
      expect: () => const [ProfileState()],
    );
  });
}
