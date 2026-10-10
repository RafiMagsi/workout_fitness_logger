import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/workout/presentation/pages/home_page.dart';
import '../../features/workout/presentation/pages/log_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/awards/presentation/pages/awards_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Dev/QA hook: override the launch tab (e.g. /progress) without editing
  // routes elsewhere.
  const initialLocation = String.fromEnvironment(
    'INITIAL_LOCATION',
    defaultValue: '/',
  );
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                name: 'progress',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProgressPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/awards',
                name: 'awards',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AwardsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HistoryPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/log',
        name: 'log',
        pageBuilder: (context, state) {
          final exerciseType = state.uri.queryParameters['exercise'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: LogPage(exerciseType: exerciseType),
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text(
            'Page not found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    ),
  );
});
