import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/providers/home_provider.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-render when history/watchlist changes
    ref.watch(historyRefreshProvider);

    final allVod = ref.watch(allVodProvider).valueOrNull ?? [];
    final allSeries = ref.watch(allSeriesProvider).valueOrNull ?? [];
    final watchlistIds = AppStorage.watchlist;

    final vodItems = allVod
        .where((v) => watchlistIds.contains('vod_${v.streamId}'))
        .toList();
    final seriesItems = allSeries
        .where((s) => watchlistIds.contains('series_${s.seriesId}'))
        .toList();

    final isEmpty = vodItems.isEmpty && seriesItems.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi lista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!isEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, ref),
              child: const Text('Limpiar todo',
                  style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: isEmpty
          ? _EmptyWatchlist()
          : CustomScrollView(
              slivers: [
                if (vodItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Películas',
                    count: vodItems.length,
                    color: AppColors.primary,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final v = vodItems[i];
                          return _WatchlistTile(
                            id: 'vod_${v.streamId}',
                            title: v.name,
                            imageUrl: v.streamIcon,
                            subtitle: [
                              if (v.year.isNotEmpty) v.year,
                              if (v.genre?.isNotEmpty == true) v.genre!,
                            ].join(' · '),
                            rating: v.ratingOutOf10 > 0
                                ? v.ratingOutOf10.toStringAsFixed(1)
                                : null,
                            onTap: () =>
                                context.push('/movie/${v.streamId}'),
                            onRemove: () {
                              AppStorage.removeFromWatchlist('vod_${v.streamId}');
                              ref.read(historyRefreshProvider.notifier).state++;
                            },
                          );
                        },
                        childCount: vodItems.length,
                      ),
                    ),
                  ),
                ],
                if (seriesItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Series',
                    count: seriesItems.length,
                    color: AppColors.secondary,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final s = seriesItems[i];
                          return _WatchlistTile(
                            id: 'series_${s.seriesId}',
                            title: s.name,
                            imageUrl: s.cover,
                            subtitle: [
                              if (s.year.isNotEmpty) s.year,
                              if (s.genre?.isNotEmpty == true) s.genre!,
                            ].join(' · '),
                            rating: s.ratingOutOf10 > 0
                                ? s.ratingOutOf10.toStringAsFixed(1)
                                : null,
                            onTap: () =>
                                context.push('/series/${s.seriesId}'),
                            onRemove: () {
                              AppStorage.removeFromWatchlist(
                                  'series_${s.seriesId}');
                              ref.read(historyRefreshProvider.notifier).state++;
                            },
                          );
                        },
                        childCount: seriesItems.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar lista'),
        content: const Text('¿Eliminar todo de tu lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in AppStorage.watchlist.toList()) {
                await AppStorage.removeFromWatchlist(id);
              }
              ref.read(historyRefreshProvider.notifier).state++;
            },
            child: Text('Limpiar todo',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyWatchlist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline_rounded,
              size: 72,
              color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          const Text('Tu lista está vacía',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Guarda películas y series para verlas más tarde pulsando el icono de marcador en su detalle.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.badge.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Watchlist tile ────────────────────────────────────────────────────────────

class _WatchlistTile extends StatelessWidget {
  final String id;
  final String title;
  final String? imageUrl;
  final String subtitle;
  final String? rating;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _WatchlistTile({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.subtitle,
    this.rating,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_remove_rounded,
                color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Quitar', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardHover, width: 0.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 90,
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface,
                                  child: const Icon(Icons.movie_rounded,
                                      color: AppColors.textMuted)),
                        )
                      : Container(color: AppColors.surface,
                          child: const Icon(Icons.movie_rounded,
                              color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    if (rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.ratingGold),
                          const SizedBox(width: 3),
                          Text(rating!,
                              style: AppTextStyles.rating
                                  .copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
