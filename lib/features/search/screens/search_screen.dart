import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/content_card.dart';
import '../../home/providers/home_provider.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

enum _SearchFilter { all, movies, series }

final _searchFilterProvider =
    StateProvider<_SearchFilter>((ref) => _SearchFilter.all);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final filter = ref.watch(_searchFilterProvider);
    final allVod = ref.watch(allVodProvider).valueOrNull ?? [];
    final allSeries = ref.watch(allSeriesProvider).valueOrNull ?? [];

    final q = query.toLowerCase();

    final vodResults = (q.isEmpty || filter == _SearchFilter.series)
        ? <dynamic>[]
        : allVod
            .where((v) =>
                v.name.toLowerCase().contains(q) ||
                (v.genre?.toLowerCase().contains(q) ?? false) ||
                (v.director?.toLowerCase().contains(q) ?? false) ||
                (v.cast?.toLowerCase().contains(q) ?? false))
            .take(50)
            .toList();

    final seriesResults = (q.isEmpty || filter == _SearchFilter.movies)
        ? <dynamic>[]
        : allSeries
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                (s.genre?.toLowerCase().contains(q) ?? false) ||
                (s.director?.toLowerCase().contains(q) ?? false))
            .take(30)
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar películas, series, actores...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 22, color: AppColors.textMuted),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _ctrl.clear();
                            ref.read(_searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
                onChanged: (q) =>
                    ref.read(_searchQueryProvider.notifier).state = q,
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todo',
                    selected: filter == _SearchFilter.all,
                    onTap: () => ref
                        .read(_searchFilterProvider.notifier)
                        .state = _SearchFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Películas',
                    selected: filter == _SearchFilter.movies,
                    onTap: () => ref
                        .read(_searchFilterProvider.notifier)
                        .state = _SearchFilter.movies,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Series',
                    selected: filter == _SearchFilter.series,
                    onTap: () => ref
                        .read(_searchFilterProvider.notifier)
                        .state = _SearchFilter.series,
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: query.isEmpty
                  ? const _EmptySearch()
                  : (vodResults.isEmpty && seriesResults.isEmpty)
                      ? _NoResults(query: query)
                      : _SearchResults(
                          vodResults: vodResults,
                          seriesResults: seriesResults,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardHover,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.badge.copyWith(
            color: selected ? Colors.white : AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded,
              size: 64, color: AppColors.textMuted.withValues(alpha:0.4)),
          const SizedBox(height: 16),
          const Text('Busca tu película favorita',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          const Text('Puedes buscar por título, género, actor o director',
              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('Sin resultados', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('No encontramos nada para "$query"',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List vodResults;
  final List seriesResults;

  const _SearchResults({
    required this.vodResults,
    required this.seriesResults,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Movies section
        if (vodResults.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  const Text('Películas', style: AppTextStyles.sectionTitle),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${vodResults.length}',
                      style: AppTextStyles.badge
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols(context),
                childAspectRatio: 0.62,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final v = vodResults[i];
                  final prog =
                      AppStorage.getWatchProgress('vod_${v.streamId}');
                  final progress = prog != null
                      ? (prog['position'] as int? ?? 0) /
                          ((prog['duration'] as int? ?? 1).clamp(1, 999999))
                      : null;
                  return GridCard(
                    id: v.streamId,
                    title: v.name,
                    imageUrl: v.streamIcon,
                    rating: v.ratingOutOf10 > 0
                        ? v.ratingOutOf10.toStringAsFixed(1)
                        : null,
                    year: v.year,
                    type: 'movie',
                    progress: progress,
                    onTap: () => context.push('/movie/${v.streamId}'),
                  );
                },
                childCount: vodResults.length,
              ),
            ),
          ),
        ],

        // Series section
        if (seriesResults.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  const Text('Series', style: AppTextStyles.sectionTitle),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${seriesResults.length}',
                      style: AppTextStyles.badge
                          .copyWith(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols(context),
                childAspectRatio: 0.62,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s = seriesResults[i];
                  final lastEntry = AppStorage.watchHistory
                      .where((e) =>
                          e.type == 'series' && e.streamId == s.seriesId)
                      .firstOrNull;
                  final progress = lastEntry != null && lastEntry.progress > 0
                      ? lastEntry.progress
                      : null;
                  return GridCard(
                    id: s.seriesId,
                    title: s.name,
                    imageUrl: s.cover,
                    rating: s.ratingOutOf10 > 0
                        ? s.ratingOutOf10.toStringAsFixed(1)
                        : null,
                    year: s.year,
                    type: 'series',
                    progress: progress,
                    onTap: () => context.push('/series/${s.seriesId}'),
                  );
                },
                childCount: seriesResults.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  int _cols(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 5;
    if (w >= 600) return 4;
    return 3;
  }
}
