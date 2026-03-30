import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'core/routes/app_router.dart';
import 'features/workout/presentation/bloc/workout_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.instance.init();

  // Initialize Dependency Injection
  await di.init();

  runApp(const SmartGymTrackerApp());
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
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<WorkoutBloc>(create: (context) => di.sl<WorkoutBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Smart Gym Tracker',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          useMaterial3: true,
        ),
        routerConfig: _appRouter.router,
      ),
    );
  }
}
