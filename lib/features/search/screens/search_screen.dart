import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/content_card.dart';
import '../../home/providers/home_provider.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

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
    final allVod = ref.watch(allVodProvider).valueOrNull ?? [];
    final allSeries = ref.watch(allSeriesProvider).valueOrNull ?? [];

    final q = query.toLowerCase();
    final vodResults = q.isEmpty
        ? <dynamic>[]
        : allVod
            .where((v) =>
                v.name.toLowerCase().contains(q) ||
                (v.genre?.toLowerCase().contains(q) ?? false) ||
                (v.director?.toLowerCase().contains(q) ?? false) ||
                (v.cast?.toLowerCase().contains(q) ?? false))
            .take(50)
            .toList();

    final seriesResults = q.isEmpty
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Expanded(
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
                                    size: 18,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  _ctrl.clear();
                                  ref
                                      .read(_searchQueryProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                      ),
                      onChanged: (q) =>
                          ref.read(_searchQueryProvider.notifier).state = q,
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: query.isEmpty
                  ? _EmptySearch()
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

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded,
              size: 64, color: AppColors.textMuted.withOpacity(0.4)),
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
                      color: AppColors.primary.withOpacity(0.15),
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
                  return GridCard(
                    id: v.streamId,
                    title: v.name,
                    imageUrl: v.streamIcon,
                    rating: v.ratingOutOf10 > 0
                        ? v.ratingOutOf10.toStringAsFixed(1)
                        : null,
                    year: v.year,
                    type: 'movie',
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
                  return GridCard(
                    id: s.seriesId,
                    title: s.name,
                    imageUrl: s.cover,
                    rating: s.ratingOutOf10 > 0
                        ? s.ratingOutOf10.toStringAsFixed(1)
                        : null,
                    year: s.year,
                    type: 'series',
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
