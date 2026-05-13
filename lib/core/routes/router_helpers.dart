import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'args/routing_args.dart';

/// Helpers de navegación tipados. Las features no deben llamar a
/// `context.push(AppRoutes.*, extra: ...)` directamente — eso esconde el
/// shape del extra y rompe en runtime si cambia. Usá los helpers de aquí.

void goToLogin(BuildContext context) => context.go(AppRoutes.login);

void goToRegister(BuildContext context) => context.go(AppRoutes.register);

void goToDashboard(BuildContext context) => context.go(AppRoutes.dashboard);

Future<bool?> pushRoutineList(BuildContext context) =>
    context.push<bool>(AppRoutes.routineList);

Future<bool?> pushRoutineEditor(BuildContext context, {String? routineId}) =>
    context.push<bool>(AppRoutes.routineEditor, extra: routineId);

Future<bool?> pushDayEditor(BuildContext context, DayEditorArgs args) =>
    context.push<bool>(AppRoutes.dayEditor, extra: args);

Future<bool?> pushRoutineDay(BuildContext context, RoutineDayArgs args) =>
    context.push<bool>(AppRoutes.routineDay, extra: args);

void pushRoutineStats(BuildContext context, RoutineStatsArgs args) =>
    context.push(AppRoutes.routineStats, extra: args);

void pushExerciseProgress(BuildContext context, ExerciseProgressArgs args) =>
    context.push(AppRoutes.exerciseProgress, extra: args);
