import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/error_mapper.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.remote});

  final ProfileRemoteDataSource remote;

  @override
  Future<Either<Failure, String?>> updateFullName({
    required String userId,
    required String fullName,
  }) => guard(() => remote.updateFullName(userId, fullName));
}
