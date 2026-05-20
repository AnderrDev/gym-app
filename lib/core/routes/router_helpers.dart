import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'args/routing_args.dart';

/// Helpers de navegación tipados. Las features no deben llamar a
/// `context.push(AppRoutes.*, extra: ...)` directamente — eso esconde el
/// shape del extra y rompe en runtime si cambia. Usá los helpers de aquí.

void goToLogin(BuildContext context) => context.go(AppRoutes.login);

void goToRegister(BuildContext context) => context.go(AppRoutes.register);

// ── Bottom-nav branches (shell tabs) ──────────────────────────────────────
//
// Cuando una pantalla dentro del shell quiere cambiar de tab, debe usar uno
// de estos helpers — NO `push` (porque eso superpone una ruta fullscreen
// sobre la actual y oculta la NavigationBar).

void goToDashboard(BuildContext context) => context.go(AppRoutes.dashboard);

void goToRoutines(BuildContext context) => context.go(AppRoutes.routines);

void goToProgress(BuildContext context) => context.go(AppRoutes.progress);

void goToProfile(BuildContext context) => context.go(AppRoutes.profile);

// ── Fullscreen pushes (NO viven dentro del shell) ─────────────────────────

Future<bool?> pushRoutineEditor(BuildContext context, {String? routineId}) =>
    context.push<bool>(AppRoutes.routineEditor, extra: routineId);

Future<bool?> pushDayEditor(BuildContext context, DayEditorArgs args) =>
    context.push<bool>(AppRoutes.dayEditor, extra: args);

Future<bool?> pushRoutineDay(BuildContext context, RoutineDayArgs args) =>
    context.push<bool>(AppRoutes.routineDay, extra: args);

/// Push de stats de rutina. Codificamos los args en el query string del
/// URL (además de pasar `extra` por compat con go_router) para que el
/// refresh del browser en web reconstruya la pantalla sin caer a
/// `_invalidArgs`. Mismo motivo para [pushExerciseProgress].
void pushRoutineStats(BuildContext context, RoutineStatsArgs args) {
  final uri = Uri(
    path: AppRoutes.routineStats,
    queryParameters: args.toQueryParams(),
  );
  context.push(uri.toString(), extra: args);
}

void pushExerciseProgress(BuildContext context, ExerciseProgressArgs args) {
  final uri = Uri(
    path: AppRoutes.exerciseProgress,
    queryParameters: args.toQueryParams(),
  );
  context.push(uri.toString(), extra: args);
}

/// Detalle de un ejercicio del catálogo (media + instrucciones).
/// Push fullscreen — accesible desde day-editor, active workout, catálogo y
/// progress.
Future<void> pushExerciseDetail(BuildContext context, String exerciseId) =>
    context.push<void>('${AppRoutes.exerciseDetail}/$exerciseId');
