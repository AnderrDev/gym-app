import '../../domain/entities/user.dart';

/// Modelo de datos para `User`. Clase hermana (no extiende la entity freezed):
/// (de)serializa el JSON de Supabase y convierte hacia/desde la entidad.
class UserModel {
  final String id;
  final String email;
  final String? fullName;

  const UserModel({required this.id, required this.email, this.fullName});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(id: user.id, email: user.email, fullName: user.fullName);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'full_name': fullName};
  }

  User toEntity() => User(id: id, email: email, fullName: fullName);
}
