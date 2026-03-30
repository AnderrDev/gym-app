import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/workout/domain/entities/routine.dart';
import '../../features/workout/presentation/pages/active_workout_page.dart';
import '../../features/workout/presentation/pages/dashboard_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      print(
        'Router redirect triggered. Location: ${state.matchedLocation}, AuthState: ${authBloc.state}',
      );
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
        print('Redirecting to /login');
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        print('Redirecting to /dashboard');
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
        path: '/active-workout',
        builder: (context, state) {
          print(
            'GoRouter: Building /active-workout with extra: ${state.extra}',
          );
          try {
            final extras = state.extra as Map;
            final routine = extras['routine'] as Routine;
            final userId = extras['userId'] as String;
            return ActiveWorkoutPage(routine: routine, userId: userId);
          } catch (e, st) {
            print('GoRouter Error building /active-workout: $e\n$st');
            return Scaffold(body: Center(child: Text('Error: $e')));
          }
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
