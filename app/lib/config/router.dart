import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/household/household_screen.dart';
import '../screens/household/leaderboard_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/rooms/room_detail_screen.dart';
import '../screens/rooms/room_form_screen.dart';
import '../screens/rooms/rooms_screen.dart';
import '../screens/tasks/task_form_screen.dart';
import '../screens/tasks/task_history_screen.dart';
import '../widgets/shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Use a ValueNotifier to trigger GoRouter refresh without recreating it.
  // ref.watch would recreate the GoRouter on every auth state change,
  // resetting navigation to initialLocation.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (prev, next) => refreshNotifier.value++);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isLoginRoute = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/rooms',
            builder: (context, state) => const RoomsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const RoomFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    RoomDetailScreen(roomId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        RoomFormScreen(roomId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tasks/new',
            builder: (context, state) => TaskFormScreen(
              roomId: state.uri.queryParameters['roomId'],
            ),
          ),
          GoRoute(
            path: '/tasks/:id/edit',
            builder: (context, state) =>
                TaskFormScreen(taskId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'household',
                builder: (context, state) => const HouseholdScreen(),
              ),
              GoRoute(
                path: 'history',
                builder: (context, state) => const TaskHistoryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
