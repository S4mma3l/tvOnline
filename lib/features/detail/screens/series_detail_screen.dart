import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/series_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/detail_provider.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final int seriesId;
  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  ConsumerState<SeriesDetailScreen> createState() =>
      _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  int _selectedSeason = 1;

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(seriesInfoProvider(widget.seriesId));
    final seasons = ref.watch(seriesSeasonsProvider(widget.seriesId));
    final config = ref.watch(serverConfigProvider).valueOrNull;

    return Scaffold(
      body: infoAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(e.toString())),
        ),
        data: (data) {
          final info = data['info'] as Map<String, dynamic>? ?? {};
          final title = info['name']?.toString() ?? 'Sin título';
          final cover = info['cover']?.toString() ??
              info['movie_image']?.toString() ?? '';
          final plot = info['plot']?.toString() ?? '';
          final rating =
              double.tryParse(info['rating']?.toString() ?? '') ?? 0.0;
          final year = info['releaseDate']?.toString() ?? '';
          final genre = info['genre']?.toString() ?? '';

          // Set first available season (synchronously when not yet set)
          if (seasons.isNotEmpty && !seasons.containsKey(_selectedSeason)) {
            _selectedSeason = (seasons.keys.toList()..sort()).first;
          }

          final currentEpisodes = seasons[_selectedSeason] ?? [];

          // Flat episode list sorted by season then episode number
          final sortedSeasonKeys = seasons.keys.toList()..sort();
          final allEpisodesFlat =
              sortedSeasonKeys.expand((s) => seasons[s] ?? []).toList();
          final episodeListForRouter = config != null
              ? allEpisodesFlat
                  .map((e) => <String, dynamic>{
                        'url':
                            '${config.serverUrl}/series/${config.username}/${config.password}/${e.id}.${e.containerExtension}',
                        'title':
                            '$title - T${e.season}:E${e.episodeNum} ${e.title}',
                        'watchKey': 'series_${e.id}',
                        'poster': e.movieImage ?? cover,
                        'type': 'series',
                        'streamId': widget.seriesId,
                      })
                  .toList()
              : <Map<String, dynamic>>[];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface),
                        )
                      else
                        Container(color: AppColors.surface),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: AppColors.heroGradient),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (rating > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 16, color: AppColors.ratingGold),
                                const SizedBox(width: 4),
                                Text(rating.toStringAsFixed(1),
                                    style: AppTextStyles.rating),
                              ],
                            ),
                          if (year.isNotEmpty)
                            Text(year, style: AppTextStyles.bodyMedium),
                          Text('${seasons.length} temporada${seasons.length == 1 ? '' : 's'}',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (genre.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: genre
                              .split(',')
                              .map((g) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(g.trim(),
                                        style: AppTextStyles.labelMedium),
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 16),
                      if (plot.isNotEmpty)
                        Text(plot,
                            style: AppTextStyles.bodyLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),

              // Season selector
              SliverToBoxAdapter(
                child: _SeasonSelector(
                  seasons: seasons.keys.toList()..sort(),
                  selected: _selectedSeason,
                  onSelected: (s) => setState(() => _selectedSeason = s),
                ),
              ),

              // Episodes
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final ep = currentEpisodes[i];
                    final streamUrl = config != null
                        ? '${config.serverUrl}/series/${config.username}/${config.password}/${ep.id}.${ep.containerExtension}'
                        : '';
                    final epIdxInFlat = allEpisodesFlat.indexOf(ep);
                    final prog = AppStorage.getWatchProgress('series_${ep.id}');
                    final epProgress = prog != null
                        ? (prog['position'] as int? ?? 0) /
                            ((prog['duration'] as int? ?? 1).clamp(1, 999999))
                        : null;
                    return _EpisodeTile(
                      episode: ep,
                      progress: epProgress,
                      onTap: () => context.push('/player', extra: {
                        'url': streamUrl,
                        'title': '$title - T${ep.season}:E${ep.episodeNum} ${ep.title}',
                        'watchKey': 'series_${ep.id}',
                        'poster': ep.movieImage ?? cover,
                        'type': 'series',
                        'streamId': widget.seriesId,
                        'episodeList': episodeListForRouter,
                        'episodeIndex': epIdxInFlat,
                      }),
                    );
                  },
                  childCount: currentEpisodes.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          );
        },
      ),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  final List<int> seasons;
  final int selected;
  final ValueChanged<int> onSelected;

  const _SeasonSelector({
    required this.seasons,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: seasons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = seasons[i];
          final isSelected = s == selected;
          return GestureDetector(
            onTap: () => onSelected(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Temporada $s',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final SeriesEpisode episode;
  final double? progress; // 0.0–1.0, null = not watched
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.episode,
    required this.onTap,
    this.progress,
  });

  bool get _watched => (progress ?? 0) >= 0.9;
  bool get _inProgress => (progress ?? 0) >= 0.05 && !_watched;

  String _remaining(Map<String, dynamic>? prog) {
    if (prog == null) return '';
    final pos = prog['position'] as int? ?? 0;
    final dur = prog['duration'] as int? ?? 0;
    final rem = dur - pos;
    if (rem <= 0) return '';
    if (rem >= 3600) return '${rem ~/ 3600}h ${(rem % 3600) ~/ 60}m';
    if (rem >= 60) return '${rem ~/ 60}m restantes';
    return '${rem}s restantes';
  }

  @override
  Widget build(BuildContext context) {
    final prog = AppStorage.getWatchProgress('series_${episode.id}');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: _watched
              ? AppColors.success.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _watched
                ? AppColors.success.withValues(alpha: 0.3)
                : _inProgress
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.cardHover,
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Episode number bubble
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _watched
                          ? AppColors.success.withValues(alpha: 0.15)
                          : _inProgress
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _watched
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.success, size: 22)
                          : Text(
                              '${episode.episodeNum ?? '?'}',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: _inProgress
                                    ? AppColors.primary
                                    : null,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title, duration, remaining
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: _watched
                                ? AppColors.textSecondary
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episode.durationFormatted.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(episode.durationFormatted,
                              style: AppTextStyles.bodySmall),
                        ],
                        if (_inProgress && prog != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            _remaining(prog),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary),
                          ),
                        ],
                        if (_watched) ...[
                          const SizedBox(height: 3),
                          Text('Visto',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.success)),
                        ],
                        if (!_watched &&
                            !_inProgress &&
                            episode.plot != null &&
                            episode.plot!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            episode.plot!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _watched
                        ? Icons.replay_rounded
                        : Icons.play_circle_rounded,
                    size: 36,
                    color: _watched ? AppColors.textMuted : AppColors.primary,
                  ),
                ],
              ),
            ),
            // Progress bar for in-progress episodes
            if (_inProgress && progress != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: AppColors.surface,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
