import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gym_flutter/core/config/supabase_config.dart';
import 'package:gym_flutter/core/error/error_reporter.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/observability/app_bloc_observer.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/platform/url_strategy_stub.dart'
    if (dart.library.js_interop) 'package:gym_flutter/core/platform/url_strategy_web.dart';
import 'package:gym_flutter/core/routes/app_router.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/core/platform/capabilities.dart';
import 'package:gym_flutter/injection_container.dart' as di;

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    configureWebUrlStrategy();
    FlutterError.onError = ErrorReporter.onFlutterError;
    PlatformDispatcher.instance.onError = ErrorReporter.onPlatformError;
    Bloc.observer = AppBlocObserver();

    if (Capabilities.supportsOrientationLock) {
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
    }
    if (Capabilities.supportsSystemUiStyling) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }

    await initializeDateFormatting('es', null);

    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // `.env` ausente en builds release/CI: las credenciales llegan vía --dart-define.
    }

    try {
      await SupabaseConfig.instance.init();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'supabase_init');
      runApp(_BootstrapErrorApp(error: e));
      return;
    }

    try {
      await di.init();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'di_init');
      runApp(_BootstrapErrorApp(error: e));
      return;
    }

    // Notificaciones: init del plugin local + Live Activities (iOS 16.1+) +
    // re-posteo si había una sesión activa persistida (recovery tras app
    // killed).
    try {
      await di.sl<NotificationService>().init();
      await di.sl<LiveActivitiesBridge>().init();
      await di.sl<ActiveWorkoutNotifier>().bootstrapFromPersistedSession();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'notifications_init');
      // No bloquea el bootstrap: la app sigue sin noti si esto falla.
    }

    AppLogger.instance.info('App bootstrap completado');
    runApp(const SmartGymTrackerApp());
  }, (error, stack) => ErrorReporter.report(error, stack, context: 'zone'));
}

class SmartGymTrackerApp extends StatefulWidget {
  const SmartGymTrackerApp({super.key});

  @override
  State<SmartGymTrackerApp> createState() => _SmartGymTrackerAppState();
}

class _SmartGymTrackerAppState extends State<SmartGymTrackerApp> {
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>()..add(AppStarted());
    _appRouter = AppRouter(_authBloc);
  }

  @override
  void dispose() {
    // Cancela la suscripción de `GoRouterRefreshStream` al `authBloc.stream`.
    // El bloc en sí lo administra GetIt como singleton, así que no se cierra.
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Smart Gym Tracker',
        theme: AppTheme.dark,
        routerConfig: _appRouter.router,
        // SelectionArea hace seleccionable cualquier `Text` debajo. Útil
        // en web (copiar nombres de ejercicios, fechas, pesos del
        // historial) y benigna en móvil (no interfiere con TextField).
        builder: (context, child) => SelectionArea(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  /// En web Safari modo privado bloquea `localStorage`, lo que hace estallar
  /// el init de Supabase y `SharedPreferences` con `SecurityError` /
  /// `QuotaExceededError`. Detectamos el patrón para mostrar un mensaje
  /// accionable en vez del stack trace crudo.
  ({String title, String body}) _friendly() {
    final raw = '$error';
    if (kIsWeb) {
      final s = raw.toLowerCase();
      final looksLikeStorageBlock = s.contains('localstorage') ||
          s.contains('quotaexceeded') ||
          s.contains('securityerror') ||
          (s.contains('storage') && s.contains('access'));
      if (looksLikeStorageBlock) {
        return (
          title: 'Tu navegador está bloqueando el almacenamiento',
          body:
              'Esto suele pasar en el modo privado de Safari. Abrí la app en '
                  'una pestaña normal (sin modo privado) y volvé a intentar.',
        );
      }
    }
    return (title: 'No pudimos arrancar la app', body: raw);
  }

  @override
  Widget build(BuildContext context) {
    final msg = _friendly();
    return MaterialApp(
      title: 'Smart Gym Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  msg.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  msg.body,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
