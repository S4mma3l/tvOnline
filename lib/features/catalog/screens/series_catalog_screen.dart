import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../../home/providers/home_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/filter_bar.dart';

class SeriesCatalogScreen extends ConsumerStatefulWidget {
  const SeriesCatalogScreen({super.key});

  @override
  ConsumerState<SeriesCatalogScreen> createState() =>
      _SeriesCatalogScreenState();
}

class _SeriesCatalogScreenState extends ConsumerState<SeriesCatalogScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _crossAxisCount(double width) {
    if (width >= 1200) return 7;
    if (width >= 900) return 6;
    if (width >= 700) return 5;
    if (width >= 500) return 4;
    if (width >= 360) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final catalogState = ref.watch(seriesCatalogStateProvider);
    final seriesAsync = ref.watch(allSeriesProvider);
    final filtered = ref.watch(filteredSeriesProvider);
    final categories =
        ref.watch(seriesCategoriesProvider).valueOrNull ?? [];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            title: const Text('Series'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar serie...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref
                                      .read(seriesCatalogStateProvider.notifier)
                                      .state = catalogState.copyWith(
                                          searchQuery: '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (q) {
                        ref.read(seriesCatalogStateProvider.notifier).state =
                            catalogState.copyWith(searchQuery: q);
                      },
                    ),
                  ),
                  FilterBar(
                    categories: categories,
                    selectedCategoryId: catalogState.selectedCategoryId,
                    sortBy: catalogState.sortBy,
                    onCategoryChanged: (id) {
                      ref.read(seriesCatalogStateProvider.notifier).state =
                          id == null
                              ? catalogState.copyWith(clearCategory: true)
                              : catalogState.copyWith(selectedCategoryId: id);
                    },
                    onSortChanged: (s) {
                      ref.read(seriesCatalogStateProvider.notifier).state =
                          catalogState.copyWith(sortBy: s);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
        body: seriesAsync.when(
          loading: () => const ShimmerGrid(),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (_) {
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text('Sin resultados',
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      catalogState.searchQuery.isNotEmpty
                          ? 'No encontramos series para "${catalogState.searchQuery}"'
                          : 'No hay series en esta categoría',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (catalogState.searchQuery.isNotEmpty ||
                        catalogState.selectedCategoryId != null) ...[
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(seriesCatalogStateProvider.notifier)
                              .state = catalogState.copyWith(
                            searchQuery: '',
                            clearCategory: true,
                          );
                        },
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Limpiar filtros'),
                      ),
                    ],
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              cacheExtent: 800,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount(width),
                childAspectRatio: 0.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final s = filtered[i];
                // Find the most recent watched episode for this series
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
            );
          },
        ),
      ),
    );
  }
}
