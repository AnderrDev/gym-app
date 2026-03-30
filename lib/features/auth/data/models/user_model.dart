import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({required super.id, required super.email, super.fullName});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'full_name': fullName};
  }
}
