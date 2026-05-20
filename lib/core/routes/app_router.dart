import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import '../../features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import '../../features/workout/presentation/bloc/progress/progress_bloc.dart';
import '../../features/workout/presentation/bloc/routine_day/routine_day_bloc.dart';
import '../../features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import '../../features/workout/presentation/dashboard/pages/dashboard_page.dart';
import '../../features/workout/presentation/exercise/pages/exercise_progress_page.dart';
import '../../features/workout/presentation/progress/pages/progress_page.dart';
import '../../features/workout/presentation/routine_day/pages/routine_day_page.dart';
import '../../features/workout/presentation/routine_management/pages/day_editor_page.dart';
import '../../features/workout/presentation/routine_management/pages/routine_editor_page.dart';
import '../../features/workout/presentation/routine_management/pages/routine_list_page.dart';
import '../../features/workout/presentation/routine_stats/pages/routine_stats_page.dart';
import '../../injection_container.dart';
import 'app_routes.dart';
import 'app_shell_page.dart';
import 'args/routing_args.dart';
import 'titled_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  /// Listenable que reacciona a cambios del [AuthBloc] para que GoRouter
  /// re-evalúe `redirect`. Lo guardamos como campo para poder llamar
  /// `dispose()` desde el `StatefulWidget` que crea este `AppRouter` —
  /// antes se construía inline y nunca se cancelaba la suscripción.
  late final GoRouterRefreshStream _refreshListenable =
      GoRouterRefreshStream(authBloc.stream);

  // Keys separadas para el root (auth pages) y para cada branch del shell:
  // así `StatefulShellRoute.indexedStack` preserva el stack de cada tab.
  static final _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  static final _shellDashboardKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell-dashboard',
  );
  static final _shellRoutinesKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell-routines',
  );
  static final _shellProgressKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell-progress',
  );
  static final _shellProfileKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell-profile',
  );

  AppRouter(this.authBloc);

  /// Cancela la suscripción interna al `authBloc.stream`. Llamar desde
  /// `dispose()` del widget que crea este router.
  void dispose() {
    _refreshListenable.dispose();
  }

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: _refreshListenable,
    redirect: (context, state) {
      final bool isAuthenticated = authBloc.state is Authenticated;
      final bool isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      final bool isInitial =
          authBloc.state is AuthInitial || authBloc.state is AuthLoading;

      if (isInitial) {
        // Wait until auth state is determined
        return null;
      }

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // ── Auth (root, sin shell) ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            const TitledPage(title: 'Iniciar sesión', child: LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) =>
            const TitledPage(title: 'Crear cuenta', child: RegisterPage()),
      ),

      // ── Shell con bottom navigation persistente ────────────────────────
      //
      // Cada branch tiene su propio Navigator (preserva el back-stack al
      // cambiar de tab). Las rutas que viven FUERA del shell (routine-day,
      // routine-editor, etc.) se declaran abajo como `GoRoute` top-level y
      // se abren con `context.push` — superponen la NavigationBar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellPage(navigationShell: navigationShell),
        branches: [
          // Branch 1 — HOY (dashboard)
          StatefulShellBranch(
            navigatorKey: _shellDashboardKey,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => TitledPage(
                  title: 'Hoy',
                  child: BlocProvider<DashboardBloc>(
                    create: (_) => sl<DashboardBloc>(),
                    child: const DashboardPage(),
                  ),
                ),
              ),
            ],
          ),
          // Branch 2 — RUTINAS
          StatefulShellBranch(
            navigatorKey: _shellRoutinesKey,
            routes: [
              GoRoute(
                path: AppRoutes.routines,
                builder: (context, state) => TitledPage(
                  title: 'Rutinas',
                  child: BlocProvider<RoutineManagementBloc>(
                    create: (_) => sl<RoutineManagementBloc>(),
                    child: const RoutineListPage(),
                  ),
                ),
              ),
            ],
          ),
          // Branch 3 — PROGRESO
          StatefulShellBranch(
            navigatorKey: _shellProgressKey,
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => TitledPage(
                  title: 'Progreso',
                  child: BlocProvider<ProgressBloc>(
                    create: (_) => sl<ProgressBloc>(),
                    child: const ProgressPage(),
                  ),
                ),
              ),
            ],
          ),
          // Branch 4 — PERFIL (stub)
          StatefulShellBranch(
            navigatorKey: _shellProfileKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) =>
                    const TitledPage(title: 'Perfil', child: ProfilePage()),
              ),
            ],
          ),
        ],
      ),

      // ── Fullscreen routes (push, ocultan NavigationBar) ────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.routineEditor,
        builder: (context, state) {
          final routineId = state.extra as String?;
          return TitledPage(
            title: 'Editar rutina',
            child: BlocProvider<RoutineManagementBloc>(
              create: (_) => sl<RoutineManagementBloc>(),
              child: RoutineEditorPage(routineId: routineId),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.dayEditor,
        builder: (context, state) {
          final args = state.extra;
          if (args is! DayEditorArgs) return _invalidArgs(AppRoutes.dayEditor);
          return TitledPage(
            title: 'Editar día',
            child: BlocProvider<RoutineManagementBloc>(
              create: (_) => sl<RoutineManagementBloc>(),
              child: DayEditorPage(
                day: args.day,
                routineId: args.routineId,
                isOwner: args.isOwner,
              ),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.routineDay,
        builder: (context, state) {
          final args = state.extra;
          if (args is! RoutineDayArgs) return _invalidArgs(AppRoutes.routineDay);
          return TitledPage(
            title: args.routineDay.name,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<RoutineDayBloc>(
                  create: (_) => sl<RoutineDayBloc>(),
                ),
                BlocProvider<ActiveWorkoutBloc>(
                  create: (_) => sl<ActiveWorkoutBloc>(),
                ),
              ],
              child: RoutineDayPage(
                routineDay: args.routineDay,
                userId: args.userId,
                sessionDate: args.sessionDate,
              ),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.routineStats,
        builder: (context, state) {
          // Path normal: `state.extra` viene con args tipados (push desde
          // dashboard/progress). Path de reload web: `state.extra` es null
          // → reconstruimos desde el query string (`?userId=...`).
          final args = state.extra is RoutineStatsArgs
              ? state.extra as RoutineStatsArgs
              : RoutineStatsArgs.tryFromQuery(state.uri.queryParameters);
          if (args == null) return _invalidArgs(AppRoutes.routineStats);
          return TitledPage(
            title: 'Historial · ${args.routineName}',
            child: RoutineStatsPage(
              userId: args.userId,
              routineId: args.routineId,
              routineName: args.routineName,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.exerciseProgress,
        builder: (context, state) {
          final args = state.extra is ExerciseProgressArgs
              ? state.extra as ExerciseProgressArgs
              : ExerciseProgressArgs.tryFromQuery(state.uri.queryParameters);
          if (args == null) return _invalidArgs(AppRoutes.exerciseProgress);
          return TitledPage(
            title: args.exerciseName,
            child: ExerciseProgressPage(
              userId: args.userId,
              exerciseId: args.exerciseId,
              exerciseName: args.exerciseName,
            ),
          );
        },
      ),
    ],
  );

  /// Pantalla de fallback cuando un deep link / navegación llega sin los args
  /// tipados esperados. Antes esto crasheaba con un cast (`state.extra! as
  /// Foo`); ahora mostramos un mensaje y un botón a la home en lugar de
  /// tumbar la app.
  static Widget _invalidArgs(String route) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta inválida')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Faltan datos para abrir $route.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) => FilledButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Ir al dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convierte un `Stream` (típicamente `authBloc.stream`) en `Listenable`
/// para que GoRouter dispare `redirect` en cada cambio.
///
/// Nota: el bloc stream YA es broadcast — no se vuelve a llamar
/// `asBroadcastStream()` aquí porque eso crea un wrapper nuevo en cada
/// instanciación, dejando suscripciones huérfanas al stream original cada
/// vez que se reconstruye este listenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
