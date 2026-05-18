import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/server_config_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/catalog/screens/vod_catalog_screen.dart';
import '../../features/catalog/screens/series_catalog_screen.dart';
import '../../features/detail/screens/vod_detail_screen.dart';
import '../../features/detail/screens/series_detail_screen.dart';
import '../../features/player/screens/player_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/live/screens/live_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/suggestions/screens/suggestions_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(serverConfigProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final isConfigured = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/setup';

      if (!isConfigured && !isAuthRoute) return '/setup';
      if (isConfigured && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (_, __) => const ServerConfigScreen(),
      ),

      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                name: 'movies',
                builder: (_, __) => const VodCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/series',
                name: 'series',
                builder: (_, __) => const SeriesCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/live',
                name: 'live',
                builder: (_, __) => const LiveScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (_, __) => const SearchScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail routes (outside shell so they cover full screen)
      GoRoute(
        path: '/movie/:id',
        name: 'movie-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return VodDetailScreen(streamId: id);
        },
      ),
      GoRoute(
        path: '/series/:id',
        name: 'series-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SeriesDetailScreen(seriesId: id);
        },
      ),
      GoRoute(
        path: '/player',
        name: 'player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PlayerScreen(
            streamUrl: extra['url'] as String,
            title: extra['title'] as String,
            watchKey: extra['watchKey'] as String? ?? '',
            poster: extra['poster'] as String?,
            type: extra['type'] as String? ?? 'vod',
            streamId: extra['streamId'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/suggestions',
        name: 'suggestions',
        builder: (_, __) => const SuggestionsScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri}'),
      ),
    ),
  );
});
