import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../../home/providers/home_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/filter_bar.dart';

class VodCatalogScreen extends ConsumerStatefulWidget {
  const VodCatalogScreen({super.key});

  @override
  ConsumerState<VodCatalogScreen> createState() => _VodCatalogScreenState();
}

class _VodCatalogScreenState extends ConsumerState<VodCatalogScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
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
    final catalogState = ref.watch(vodCatalogStateProvider);
    final vodAsync = ref.watch(allVodProvider);
    final filtered = ref.watch(filteredVodProvider);
    final categories = ref.watch(vodCategoriesProvider).valueOrNull ?? [];

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: AppColors.background,
            title: const Text('Películas'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar película...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref.read(vodCatalogStateProvider.notifier)
                                      .state = catalogState.copyWith(
                                          searchQuery: '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (q) {
                        ref.read(vodCatalogStateProvider.notifier).state =
                            catalogState.copyWith(searchQuery: q);
                      },
                    ),
                  ),
                  // Filter bar
                  FilterBar(
                    categories: categories,
                    selectedCategoryId: catalogState.selectedCategoryId,
                    sortBy: catalogState.sortBy,
                    onCategoryChanged: (id) {
                      ref.read(vodCatalogStateProvider.notifier).state =
                          id == null
                              ? catalogState.copyWith(clearCategory: true)
                              : catalogState.copyWith(selectedCategoryId: id);
                    },
                    onSortChanged: (s) {
                      ref.read(vodCatalogStateProvider.notifier).state =
                          catalogState.copyWith(sortBy: s);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
        body: vodAsync.when(
          loading: () => const ShimmerGrid(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(e.toString(), style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          data: (_) {
            if (filtered.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('Sin resultados', style: AppTextStyles.headlineSmall),
                    SizedBox(height: 6),
                    Text('Prueba con otro filtro o búsqueda',
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount(width),
                childAspectRatio: 0.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final v = filtered[i];
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
            );
          },
        ),
      ),
    );
  }
}
