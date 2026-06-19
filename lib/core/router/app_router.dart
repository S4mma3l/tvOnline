import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/app_storage.dart';
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
import '../../features/watchlist/screens/watchlist_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/profiles/screens/profile_selector_screen.dart';
import '../../features/profiles/providers/profiles_provider.dart';
import '../../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(serverConfigProvider);
  ref.watch(profileSelectedProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final isConfigured = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      if (!isConfigured) return loc == '/setup' ? null : '/setup';
      if (loc == '/setup') return '/';

      // Show profile selector when multiple profiles exist and none selected yet
      if (loc != '/profiles') {
        final profiles = AppStorage.profiles;
        final profileSelected = ref.read(profileSelectedProvider);
        if (profiles.length > 1 && !profileSelected) return '/profiles';
        // Auto-select single profile without showing selector
        if (profiles.length == 1 && !profileSelected) {
          AppStorage.setActiveProfile(profiles.first.id);
          ref.read(profileSelectedProvider.notifier).state = true;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (_, __) => const ServerConfigScreen(),
      ),

      GoRoute(
        path: '/profiles',
        name: 'profiles',
        builder: (_, __) => const ProfileSelectorScreen(),
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
            episodeList: extra['episodeList'] != null
                ? List<Map<String, dynamic>>.from(
                    (extra['episodeList'] as List)
                        .map((e) => Map<String, dynamic>.from(e as Map)))
                : null,
            episodeIndex: extra['episodeIndex'] as int?,
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
        redirect: (context, state) {
          final config = ref.read(serverConfigProvider).valueOrNull;
          final role = config?.userInfo?['user_info']?['role'] as String?;
          if (role != 'admin') return '/';
          return null;
        },
        builder: (_, __) => const AdminScreen(),
      ),
      GoRoute(
        path: '/watchlist',
        name: 'watchlist',
        builder: (_, __) => const WatchlistScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (_, __) => const HistoryScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri}'),
      ),
    ),
  );
});
