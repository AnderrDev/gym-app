import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';
import '../models/user_model.dart';

/// **Cache de UserModel para UI**, NO almacenamiento de tokens.
///
/// `SharedPreferences` se usa solo para datos no-sensibles (perfil mostrado
/// mientras se rehidrata la sesión). Cualquier dato secreto (refresh tokens,
/// API keys, biometrics) debe ir a `flutter_secure_storage` — ya está en
/// `pubspec.yaml` y se cableará en Fase 7 cuando se introduzcan tokens
/// custom.
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel userToCache);
  Future<UserModel?> getLastCachedUser();
  Future<void> clearCache();
}

const cachedUserKey = 'CACHED_USER';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel userToCache) {
    return sharedPreferences.setString(
      cachedUserKey,
      json.encode(userToCache.toJson()),
    );
  }

  @override
  Future<UserModel?> getLastCachedUser() async {
    final jsonString = sharedPreferences.getString(cachedUserKey);
    if (jsonString == null) return null;
    try {
      return UserModel.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
    } catch (e) {
      // Schema-drift desde una versión vieja (campos faltantes, casts rotos):
      // tirar el cache y caer a remoto en vez de propagar el crash.
      AppLogger.instance.warning(
        'getLastCachedUser: cache inválido descartado ($e)',
      );
      await clearCache();
      return null;
    }
  }

  @override
  Future<void> clearCache() {
    return sharedPreferences.remove(cachedUserKey);
  }
}
