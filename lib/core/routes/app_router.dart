import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/workout/domain/entities/routine_day.dart';
import '../../features/workout/presentation/pages/routine_day_page.dart';
import '../../features/workout/presentation/pages/dashboard_page.dart';
import '../../features/workout/presentation/pages/database_inspector_page.dart';
import '../../features/workout/presentation/pages/routine_list_page.dart';
import '../../features/workout/presentation/pages/routine_editor_page.dart';
import '../../features/workout/presentation/pages/day_editor_page.dart';
import '../../features/workout/presentation/pages/routine_stats_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final bool isAuthenticated = authBloc.state is Authenticated;
      final bool isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final bool isInitial =
          authBloc.state is AuthInitial || authBloc.state is AuthLoading;

      if (isInitial) {
        // Wait until auth state is determined
        return null;
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/db-inspector',
        builder: (context, state) => const DatabaseInspectorPage(),
      ),
      GoRoute(
        path: '/routine-list',
        builder: (context, state) => const RoutineListPage(),
      ),
      GoRoute(
        path: '/routine-editor',
        builder: (context, state) {
          final routineId = state.extra as String?;
          return RoutineEditorPage(routineId: routineId);
        },
      ),
      GoRoute(
        path: '/day-editor',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final day = extras['day'] as RoutineDay;
          final routineId = extras['routineId'] as String;
          return DayEditorPage(day: day, routineId: routineId);
        },
      ),
      GoRoute(
        path: '/routine-day',
        builder: (context, state) {
          try {
            final extras = state.extra as Map;
            final routineDay = extras['routineDay'] as RoutineDay;
            final userId = extras['userId'] as String;
            final sessionDate = extras['sessionDate'] as DateTime;
            return RoutineDayPage(
              routineDay: routineDay,
              userId: userId,
              sessionDate: sessionDate,
            );
          } catch (e) {
            return Scaffold(body: Center(child: Text('Error: $e')));
          }
        },
      ),
      GoRoute(
        path: '/routine-stats',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return RoutineStatsPage(
            userId: extras['userId'] as String,
            routineId: extras['routineId'] as String,
            routineName: extras['routineName'] as String,
          );
        },
      ),
    ],
  );
}

// Convert AuthBloc stream to Listenable so GoRouter can refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
