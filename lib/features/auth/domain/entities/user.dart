import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? fullName;

  const User({required this.id, required this.email, this.fullName});

  User copyWith({String? id, String? email, String? fullName}) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName];
}
