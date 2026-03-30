import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    print('DashboardPage initState called');
    final authState = context.read<AuthBloc>().state;
    print('DashboardPage initState authState: $authState');
    if (authState is Authenticated) {
      context.read<WorkoutBloc>().add(FetchAssignedRoutines(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Smart Gym Tracker', style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutRequested());
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.read<WorkoutBloc>().add(
              FetchAssignedRoutines(state.user.id),
            );
          }
        },
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            print(
              'DashboardPage BlocBuilder evaluating state: ${state.runtimeType}',
            );
            if (state is WorkoutInitial || state is WorkoutLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (state is WorkoutError) {
              return Center(
                child: Text(
                  'Error loading routines: ${state.message}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              );
            } else if (state is RoutinesLoaded) {
              final routines = state.routines;

              if (routines.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      title: Text(routine.name, style: AppTextStyles.bodyLarge),
                      subtitle: Text(
                        '${routine.exerciseCount} exercises',
                        style: AppTextStyles.label,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      onTap: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is Authenticated) {
                          context.push(
                            '/active-workout',
                            extra: {
                              'routine': routine,
                              'userId': authState.user.id,
                            },
                          );
                        }
                      },
                    ),
                  );
                },
              );
            }
            return Center(
              child: Text(
                'Unhandled State: ${state.runtimeType}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.surfaceHighlight,
          ),
          const SizedBox(height: 16),
          Text('No routines assigned yet.', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Ask your coach to assign you a routine\nor check back later.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
