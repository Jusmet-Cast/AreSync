import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/adventures/presentation/pages/adventures_page.dart';
import '../features/coach/presentation/pages/coach_page.dart';
import '../features/nutrition/presentation/pages/nutrition_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/telemetry/presentation/pages/telemetry_page.dart';
import '../features/today/presentation/pages/today_page.dart';
import '../features/training/presentation/pages/session_page.dart';

/// Cinco destinos en la barra inferior: inicio, los tres pilares y perfil.
///
/// StatefulShellRoute conserva el estado de cada rama, asi que salir de una
/// sesion de fuerza para mirar la comida y volver no borra las series
/// cargadas.
///
/// Aventuras y Coach NO son destinos de la barra: una barra de mas de 5 items
/// deja de ser escaneable de un vistazo. Aventuras se entra desde el card de
/// "Hoy"; Coach desde el FAB flotante, siempre a mano sin competir por un
/// lugar fijo en la barra.
final GoRouter appRouter = GoRouter(
  initialLocation: '/hoy',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
              StatefulNavigationShell shell) =>
          _ShellScaffold(shell: shell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/hoy',
              builder: (BuildContext context, GoRouterState state) =>
                  const TodayPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/entreno',
              builder: (BuildContext context, GoRouterState state) =>
                  const SessionPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/nutricion',
              builder: (BuildContext context, GoRouterState state) =>
                  const NutritionPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/telemetria',
              builder: (BuildContext context, GoRouterState state) =>
                  const TelemetryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/perfil',
              builder: (BuildContext context, GoRouterState state) =>
                  const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/aventuras',
      builder: (BuildContext context, GoRouterState state) => const AdventuresPage(),
    ),
    GoRoute(
      path: '/coach',
      builder: (BuildContext context, GoRouterState state) => const CoachPage(),
    ),
  ],
);

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/coach'),
        tooltip: 'Coach',
        child: const Icon(Icons.auto_awesome),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (int i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Hoy'),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Entreno',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            label: 'Nutricion',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            label: 'Telemetria',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
