import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../providers/home_provider.dart';
import '../widgets/hero_banner.dart';
import '../widgets/content_carousel.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroItems = ref.watch(heroBannerItemsProvider);
    final trendingVod = ref.watch(trendingVodProvider);
    final topRatedVod = ref.watch(topRatedVodProvider);
    final topSeries = ref.watch(topRatedSeriesProvider);
    final featuredCats = ref.watch(featuredCategoriesProvider);
    final allVodAsync = ref.watch(allVodProvider);
    final config = ref.watch(serverConfigProvider).valueOrNull;
    final continueWatching = ref.watch(continueWatchingProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, config?.displayName),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(allVodProvider);
          ref.invalidate(allSeriesProvider);
          ref.invalidate(vodCategoriesProvider);
          ref.invalidate(seriesCategoriesProvider);
          ref.invalidate(continueWatchingProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Hero Banner
            SliverToBoxAdapter(
              child: allVodAsync.when(
                data: (_) => HeroBanner(items: heroItems),
                loading: () => const ShimmerHero(),
                error: (e, _) => _ErrorBanner(error: e.toString()),
              ),
            ),

            // Continue Watching (only shown when there's history)
            if (continueWatching.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _ContinueWatchingCarousel(items: continueWatching),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Trending now
            SliverToBoxAdapter(
              child: allVodAsync.when(
                data: (_) => ContentCarousel(
                  title: 'Tendencias ahora',
                  items: trendingVod
                      .map((v) => ContentCardData(
                            id: v.streamId,
                            title: v.name,
                            imageUrl: v.streamIcon,
                            rating: v.ratingOutOf10 > 0
                                ? v.ratingOutOf10.toStringAsFixed(1)
                                : null,
                            year: v.year,
                            genre: v.genre,
                            type: 'movie',
                            onTap: () =>
                                context.push('/movie/${v.streamId}'),
                          ))
                      .toList(),
                  onSeeAll: () => context.go('/movies'),
                  cardWidth: 120,
                  cardHeight: 180,
                ),
                loading: () =>
                    const ShimmerCarousel(cardWidth: 120, cardHeight: 180),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Top rated movies
            SliverToBoxAdapter(
              child: allVodAsync.when(
                data: (_) => ContentCarousel(
                  title: 'Mejor valoradas',
                  items: topRatedVod
                      .map((v) => ContentCardData(
                            id: v.streamId,
                            title: v.name,
                            imageUrl: v.streamIcon,
                            rating: v.ratingOutOf10 > 0
                                ? v.ratingOutOf10.toStringAsFixed(1)
                                : null,
                            year: v.year,
                            type: 'movie',
                            onTap: () =>
                                context.push('/movie/${v.streamId}'),
                          ))
                      .toList(),
                  onSeeAll: () => context.go('/movies'),
                  cardWidth: 130,
                  cardHeight: 195,
                ),
                loading: () =>
                    const ShimmerCarousel(cardWidth: 130, cardHeight: 195),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Top series
            SliverToBoxAdapter(
              child: ref.watch(allSeriesProvider).when(
                    data: (_) => ContentCarousel(
                      title: 'Series recomendadas',
                      items: topSeries
                          .map((s) => ContentCardData(
                                id: s.seriesId,
                                title: s.name,
                                imageUrl: s.cover,
                                rating: s.ratingOutOf10 > 0
                                    ? s.ratingOutOf10.toStringAsFixed(1)
                                    : null,
                                year: s.year,
                                type: 'series',
                                onTap: () =>
                                    context.push('/series/${s.seriesId}'),
                              ))
                          .toList(),
                      onSeeAll: () => context.go('/series'),
                      cardWidth: 120,
                      cardHeight: 180,
                    ),
                    loading: () => const ShimmerCarousel(
                        cardWidth: 120, cardHeight: 180),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Category carousels
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final cat = featuredCats[i];
                  final category = cat['category'];
                  final items =
                      (cat['items'] as List).cast<dynamic>().take(20).toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: ContentCarousel(
                      title: category.categoryName,
                      items: items.map((v) {
                        return ContentCardData(
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
                      }).toList(),
                      onSeeAll: () => context.go('/movies'),
                      cardWidth: 120,
                      cardHeight: 180,
                    ),
                  );
                },
                childCount: featuredCats.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String? username) {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC0A0A0F), Colors.transparent],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'tv',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Online',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_outline_rounded, color: Colors.white),
          tooltip: 'Mi lista',
          onPressed: () => context.push('/watchlist'),
        ),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary,
              child: Text(
                username?.isNotEmpty == true
                    ? username![0].toUpperCase()
                    : 'U',
                style: AppTextStyles.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Continue Watching carousel ────────────────────────────────────────────────

// AnimatedList carousel — items se animan al eliminarse, sin SnackBar
class _ContinueWatchingCarousel extends ConsumerStatefulWidget {
  final List<WatchHistoryEntry> items;
  const _ContinueWatchingCarousel({required this.items});

  @override
  ConsumerState<_ContinueWatchingCarousel> createState() =>
      _ContinueWatchingCarouselState();
}

class _ContinueWatchingCarouselState
    extends ConsumerState<_ContinueWatchingCarousel> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<WatchHistoryEntry> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(_ContinueWatchingCarousel old) {
    super.didUpdateWidget(old);
    // Sync when external list changes (e.g. after "Limpiar todo")
    if (old.items != widget.items) {
      setState(() => _items = List.from(widget.items));
    }
  }

  void _remove(int index) {
    if (index >= _items.length) return;
    final removed = _items[index];
    _items.removeAt(index);

    // Animate item out
    _listKey.currentState?.removeItem(
      index,
      (ctx, anim) => SizeTransition(
        sizeFactor: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        axis: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: FadeTransition(
            opacity: anim,
            child: _ContinueCard(
              entry: removed,
              onNavigate: () {},
              onDeleteTap: () {},
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );

    // Delete from storage in background
    AppStorage.removeFromHistory(removed.watchKey).then((_) {
      ref.read(historyRefreshProvider.notifier).state++;
    });
  }

  void _navigate(WatchHistoryEntry entry) {
    if (entry.type == 'vod') context.push('/movie/${entry.streamId}');
    if (entry.type == 'series') context.push('/series/${entry.streamId}');
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Eliminar todo de "Continuar viendo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStorage.clearHistory();
              setState(() => _items.clear());
              ref.read(historyRefreshProvider.notifier).state++;
            },
            child: const Text('Limpiar todo',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.play_circle_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Continuar viendo',
                    style: AppTextStyles.sectionTitle),
              ),
              TextButton.icon(
                onPressed: _confirmClearAll,
                icon: const Icon(Icons.delete_sweep_rounded,
                    size: 16, color: AppColors.textMuted),
                label: const Text('Limpiar',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textMuted)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: AnimatedList(
            key: _listKey,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            initialItemCount: _items.length,
            itemBuilder: (_, index, animation) {
              final entry = _items[index];
              return SizeTransition(
                sizeFactor:
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                axis: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Dismissible(
                    key: ValueKey(entry.watchKey),
                    direction: DismissDirection.up,
                    onDismissed: (_) => _remove(index),
                    background: Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.white, size: 22),
                    ),
                    child: _ContinueCard(
                      entry: entry,
                      onNavigate: () => _navigate(entry),
                      onDeleteTap: () => _remove(index),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final WatchHistoryEntry entry;
  final VoidCallback onNavigate;
  final VoidCallback onDeleteTap;

  const _ContinueCard({
    required this.entry,
    required this.onNavigate,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNavigate,
      child: SizedBox(
        width: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              if (entry.poster != null && entry.poster!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: entry.poster!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.card),
                )
              else
                Container(color: AppColors.card),

              // Gradient
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xEE000000)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),

              // Title + time + progress
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                      child: Text(
                        entry.title,
                        style: AppTextStyles.titleSmall
                            .copyWith(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                      child: Text(
                        _remaining(),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white60),
                      ),
                    ),
                    LinearProgressIndicator(
                      value: entry.progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary),
                    ),
                  ],
                ),
              ),

              // Play button center
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                ),
              ),

              // ✕ delete button — single tap, top right
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onDeleteTap,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _remaining() {
    final remaining = entry.durationSeconds - entry.positionSeconds;
    if (remaining <= 0) return 'Terminado';
    final m = remaining ~/ 60;
    if (m < 60) return '$m min restantes';
    final h = m ~/ 60;
    final rm = m % 60;
    return '${h}h ${rm}m restantes';
  }
}


class _ErrorBanner extends ConsumerWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('No se pudo cargar el contenido',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(error,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(allVodProvider);
                ref.invalidate(allSeriesProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
