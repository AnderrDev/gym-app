import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/sync/presentation/sync_status_badge.dart';
import 'package:gym_flutter/core/sync/presentation/sync_status_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_state.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_active_session_banner.dart';
import 'package:gym_flutter/injection_container.dart';

/// Shell raíz de la app autenticada.
///
/// Provee:
///   1. La `NavigationBar` persistente con los 4 destinos (HOY, RUTINAS,
///      PROGRESO, PERFIL). El `StatefulShellRoute.indexedStack` se encarga
///      de mantener cada branch con su propio Navigator y conservar estado
///      al cambiar de tab.
///   2. El banner global de "sesión activa" — antes vivía en el dashboard,
///      ahora se renderiza encima de cualquiera de los 4 tabs porque la
///      sesión activa es estado cross-cutting.
///   3. El `ActiveSessionWatcherBloc` para el subtree (provisto vía DI) —
///      se dispara `CheckActiveSession(userId)` cuando hay `Authenticated`.
class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key, required this.navigationShell});

  /// Lo provee `StatefulShellRoute.indexedStack#builder`. Expone el branch
  /// activo y `goBranch()` para conmutar.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // El SyncStatusBloc sólo está registrado en plataformas con persistencia
    // local (Phase 2). Si no, montamos el shell sin badge.
    final hasSyncBloc = sl.isRegistered<SyncStatusBloc>();
    final shell = BlocProvider<ActiveSessionWatcherBloc>(
      create: (_) => sl<ActiveSessionWatcherBloc>(),
      child: _AppShellView(navigationShell: navigationShell),
    );
    if (!hasSyncBloc) return shell;
    return BlocProvider<SyncStatusBloc>(
      create: (_) => sl<SyncStatusBloc>(),
      child: shell,
    );
  }
}

class _AppShellView extends StatefulWidget {
  const _AppShellView({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<_AppShellView> createState() => _AppShellViewState();
}

class _AppShellViewState extends State<_AppShellView> {
  /// True una vez que disparamos `CheckActiveSession` por primera vez.
  /// En web reload el `AuthBloc` empieza en `AuthInitial`. El `initState`
  /// puede correr antes y la lectura síncrona de `AuthBloc.state` salía
  /// sin disparar nada — el banner nunca aparecía. El `BlocListener`
  /// del build cubre ese race; el flag evita doble dispatch.
  bool _initialCheckDispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;
      _initialCheckDispatched = true;
      context.read<ActiveSessionWatcherBloc>().add(
        CheckActiveSession(authState.user.id),
      );
    });
  }

  Future<void> _resumeActiveSession(ActiveSessionInfo info) async {
    // Reconstruimos un `RoutineDay` mínimo: la routine-day page solo necesita
    // el id+nombre para reanudar la sesión activa (los ejercicios reales los
    // re-carga el `RoutineDayBloc` desde el backend).
    final routineDay = RoutineDay(
      id: info.routineDayId,
      routineId: '',
      name: info.routineDayName,
      dayOfWeek: info.sessionDate.weekday,
      exercises: const [],
    );
    final watcherBloc = context.read<ActiveSessionWatcherBloc>();
    final didFinish = await pushRoutineDay(
      context,
      RoutineDayArgs(
        routineDay: routineDay,
        userId: info.userId,
        sessionDate: info.sessionDate,
      ),
    );
    if (didFinish == true) {
      watcherBloc.add(const ClearActiveSession());
    }
  }

  void _onDestinationSelected(int index) {
    HapticFeedback.lightImpact();
    final shell = widget.navigationShell;
    // Si tap-eo la pestaña actual, volvemos al root de ese branch (popea
    // cualquier ruta apilada). Si es otra pestaña, switch normal.
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          !_initialCheckDispatched && curr is Authenticated,
      listener: (context, authState) {
        if (!mounted || authState is! Authenticated) return;
        _initialCheckDispatched = true;
        context.read<ActiveSessionWatcherBloc>().add(
          CheckActiveSession(authState.user.id),
        );
      },
      child: _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // SafeArea envolviendo el shell ENTERO consume el inset del status
      // bar / Dynamic Island UNA SOLA VEZ. Sin esto, el AppBar del Scaffold
      // interno (DashboardPage, RoutinesPage, etc.) re-paddingea por la
      // status bar encima de la SafeArea, generando un gap visual gigante
      // entre el banner y el título.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Badge de sync — solo se renderiza si el SyncStatusBloc está
            // provisto (plataformas con persistencia local). El badge
            // mismo es un SizedBox.shrink() cuando no hay nada que mostrar.
            if (sl.isRegistered<SyncStatusBloc>())
              const Align(
                alignment: Alignment.centerRight,
                child: SyncStatusBadge(),
              ),
            BlocSelector<
              ActiveSessionWatcherBloc,
              ActiveSessionWatcherState,
              ActiveSessionInfo?
            >(
              selector: (state) =>
                  state.hasActiveSession ? state.session : null,
              builder: (context, session) {
                if (session == null) return const SizedBox.shrink();
                return DashboardActiveSessionBanner(
                  session: session,
                  onTap: () => _resumeActiveSession(session),
                );
              },
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.primary.withValues(alpha: 0.16),
          labelTextStyle: WidgetStatePropertyAll(
            AppTextStyles.label.copyWith(letterSpacing: 1.2),
          ),
          // a11y/contraste: forzamos `textSecondary` (#6E6E73 ≈ 4.78:1 sobre
          // background blanco — supera WCAG AA UI 3:1) para iconos inactivos
          // y `primary` para los seleccionados, evitando depender del default
          // `onSurfaceVariant` del ColorScheme.
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return const IconThemeData(color: AppColors.textSecondary, size: 24);
          }),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          // Nota a11y: Material 3 ya envuelve cada `NavigationDestination` en
          // `Semantics(role: tab, selected: ...)` y agrega un label posicional
          // localizado (`MaterialLocalizations.tabLabel`, en `es` produce
          // "Pestaña N de 4"). Solo aportamos `tooltip` explícito por destino
          // para hover/long-press en web/desktop sin perder el label corto.
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_rounded),
              selectedIcon: Icon(Icons.today_rounded),
              label: 'HOY',
              tooltip: 'Pestaña HOY — resumen del día',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_fire_department_rounded),
              selectedIcon: Icon(Icons.local_fire_department_rounded),
              label: 'RUTINAS',
              tooltip: 'Pestaña RUTINAS — gestionar rutinas',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_rounded),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'PROGRESO',
              tooltip: 'Pestaña PROGRESO — métricas e historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'PERFIL',
              tooltip: 'Pestaña PERFIL — cuenta y ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
