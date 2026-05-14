import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/alert_config.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';

/// Wrapper sobre el plugin `live_activities`. En iOS 16.1+ encapsula la
/// creación / update / end de la `ActiveWorkoutAttributes` declarada en el
/// target nativo `SmartGymTrackerActivityExtension`. En cualquier otra
/// plataforma o iOS < 16.1 todas las llamadas son no-ops.
class LiveActivitiesBridge {
  LiveActivitiesBridge({LiveActivities? plugin})
    : _plugin = plugin ?? LiveActivities();

  final LiveActivities _plugin;

  /// Bundle ID del App Group compartido entre Runner y el widget extension.
  /// Tiene que matchear con lo seteado en Xcode → Signing & Capabilities.
  static const _appGroupId = 'group.com.gymtracker.gym_flutter';

  bool _initialized = false;
  bool _isAvailable = false;
  String? _activityId;

  /// `true` cuando estamos en iOS 16.1+ y el sistema permite Live Activities.
  /// Para Android / web / iOS < 16.1 siempre `false`.
  bool get isAvailable => _isAvailable;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _plugin.init(appGroupId: _appGroupId);
      final enabled = await _plugin.areActivitiesEnabled();
      _isAvailable = enabled;
      AppLogger.instance.info(
        'LiveActivitiesBridge: init OK, available=$_isAvailable',
      );
    } catch (e) {
      AppLogger.instance.warning('LiveActivitiesBridge.init: $e');
      _isAvailable = false;
    }
  }

  /// Tag interno del activity — identifica el tipo "workout" para queries y
  /// updates en el plugin. Único por sesión: usa el timestamp de creación.
  String _newActivityTag() =>
      'active_workout_${DateTime.now().millisecondsSinceEpoch}';

  /// Crea la Live Activity y guarda su id internamente. Si ya hay una
  /// activa, la finaliza primero (regla: una sesión activa por user).
  Future<void> start({
    required String dayName,
    required DateTime sessionStartedAt,
    required int totalSets,
  }) async {
    if (!_isAvailable) return;
    if (_activityId != null) {
      await end();
    }
    try {
      final id = await _plugin.createActivity(
        _newActivityTag(),
        _payloadForCreate(
          dayName: dayName,
          totalSets: totalSets,
          sessionStartedAt: sessionStartedAt,
        ),
        removeWhenAppIsKilled: false,
        // CRÍTICO: con `true` (default) el plugin llama
        // `Activity.request(pushType: .token)`, que requiere la capability
        // de Push Notifications (APNs entitlement). Sin esa capability
        // ActivityKit rechaza la creación con
        // `com.apple.ActivityKit.ActivityInput error 0`. Para LAs locales
        // (sin servidor push) lo desactivamos.
        iOSEnableRemoteUpdates: false,
      );
      _activityId = id;
      AppLogger.instance.info(
        'LiveActivitiesBridge.start: activityId=$id dayName="$dayName"',
      );
    } catch (e) {
      AppLogger.instance.warning('LiveActivitiesBridge.start: $e');
    }
  }

  Future<void> update({
    required String dayName,
    required DateTime sessionStartedAt,
    required int completedSets,
    required int totalSets,
    DateTime? restEndsAt,
    bool alertOnUpdate = false,
  }) async {
    if (!_isAvailable) return;
    final id = _activityId;
    if (id == null) return;
    try {
      await _plugin.updateActivity(
        id,
        _payloadForUpdate(
          dayName: dayName,
          completedSets: completedSets,
          totalSets: totalSets,
          sessionStartedAt: sessionStartedAt,
          restEndsAt: restEndsAt,
        ),
        // `alertConfig` hace que iOS muestre el banner/sonido del sistema
        // sobre la Dynamic Island cuando llega el update — útil para
        // notificar "¡fin del descanso!" sin que el user esté mirando.
        alertConfig: alertOnUpdate
            ? AlertConfig(
                title: '¡A entrenar!',
                body: 'Próxima serie te espera',
                sound: 'default',
              )
            : null,
      );
      AppLogger.instance.info(
        'LiveActivitiesBridge.update: sets=$completedSets/$totalSets '
        'resting=${restEndsAt != null} alert=$alertOnUpdate',
      );
    } catch (e) {
      AppLogger.instance.warning('LiveActivitiesBridge.update: $e');
    }
  }

  Future<void> end() async {
    if (!_isAvailable) return;
    final id = _activityId;
    if (id == null) return;
    _activityId = null;
    try {
      await _plugin.endActivity(id);
    } catch (e) {
      AppLogger.instance.warning('LiveActivitiesBridge.end: $e');
    }
  }

  /// Payload para `createActivity`. El plugin guarda cada key en un plist
  /// del App Group, y los plists NO aceptan `null` — si `restEndsAt` es
  /// null, **omitimos** la key (al crear no hay valor previo que borrar).
  ///
  /// Todos los valores van como `String` para evitar errores de decoding
  /// (`ActivityInput error 0`) por mismatches Int/Double/String en
  /// `ActivityAttributes`.
  Map<String, dynamic> _payloadForCreate({
    required String dayName,
    required int totalSets,
    required DateTime sessionStartedAt,
  }) => <String, dynamic>{
    'dayName': dayName,
    'completedSets': '0',
    'totalSets': totalSets.toString(),
    'sessionStartedAtMs': sessionStartedAt.millisecondsSinceEpoch.toString(),
  };

  /// Payload para `updateActivity`. Diferencia clave con el de create: si
  /// `restEndsAt` es null, mandamos la key con valor `null` EXPLÍCITO. El
  /// plugin detecta el null y **borra la key del UserDefaults compartido**,
  /// lo que hace que la LA vuelva a workout-view. Si la omitiéramos, el
  /// valor viejo persiste y la LA queda con countdown stale.
  Map<String, dynamic> _payloadForUpdate({
    required String dayName,
    required int completedSets,
    required int totalSets,
    required DateTime sessionStartedAt,
    required DateTime? restEndsAt,
  }) => <String, dynamic>{
    'dayName': dayName,
    'completedSets': completedSets.toString(),
    'totalSets': totalSets.toString(),
    'sessionStartedAtMs': sessionStartedAt.millisecondsSinceEpoch.toString(),
    'restEndsAtMs': restEndsAt?.millisecondsSinceEpoch.toString(),
  };
}
