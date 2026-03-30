import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error del servidor']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Error de caché local']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Sin conexión a internet']) : super(message);
}
