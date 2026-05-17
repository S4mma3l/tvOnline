import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/detail_provider.dart';

class VodDetailScreen extends ConsumerWidget {
  final int streamId;
  const VodDetailScreen({super.key, required this.streamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(vodInfoProvider(streamId));
    final config = ref.watch(serverConfigProvider).valueOrNull;

    return Scaffold(
      body: infoAsync.when(
        loading: () => const _LoadingDetail(),
        error: (e, _) => _ErrorDetail(error: e.toString()),
        data: (data) {
          final info = data['info'] as Map<String, dynamic>? ?? {};
          final movieData = data['movie_data'] as Map<String, dynamic>? ?? {};

          final title = info['name']?.toString() ??
              movieData['name']?.toString() ?? 'Sin título';
          final cover = info['cover_big']?.toString() ??
              info['movie_image']?.toString() ?? '';
          final plot = info['description']?.toString() ??
              info['plot']?.toString() ?? '';
          final rating =
              double.tryParse(info['rating']?.toString() ?? '') ?? 0.0;
          final year = info['releasedate']?.toString() ?? '';
          final genre = info['genre']?.toString() ?? '';
          final director = info['director']?.toString() ?? '';
          final cast = info['actors']?.toString() ?? '';
          final duration = info['duration']?.toString() ?? '';
          final country = info['country']?.toString() ?? '';
          final ext = movieData['container_extension']?.toString() ?? 'mkv';
          final streamUrl = config != null
              ? '${config.serverUrl}/movie/${config.username}/${config.password}/$streamId.$ext'
              : '';

          return CustomScrollView(
            slivers: [
              // Header with backdrop
              SliverAppBar(
                expandedHeight:
                    MediaQuery.of(context).size.height * 0.5,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () {},
                  ),
                ],
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
                      // Gradient overlay
                      const DecoratedBox(
                        decoration:
                            BoxDecoration(gradient: AppColors.heroGradient),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(title, style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 10),

                      // Meta row
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (rating > 0)
                            _MetaBadge(
                              icon: Icons.star_rounded,
                              text: rating.toStringAsFixed(1),
                              color: AppColors.ratingGold,
                            ),
                          if (year.isNotEmpty) _MetaText(text: year),
                          if (duration.isNotEmpty) _MetaText(text: duration),
                          if (country.isNotEmpty) _MetaText(text: country),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Genre tags
                      if (genre.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: genre
                              .split(',')
                              .map((g) => _GenreTag(label: g.trim()))
                              .toList(),
                        ),

                      const SizedBox(height: 22),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.play_arrow_rounded,
                              label: 'Reproducir',
                              primary: true,
                              onTap: () => context.push('/player', extra: {
                                'url': streamUrl,
                                'title': title,
                                'watchKey': 'vod_$streamId',
                                'poster': cover,
                                'type': 'vod',
                                'streamId': streamId,
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _WatchlistButton(id: 'vod_$streamId'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description
                      if (plot.isNotEmpty) ...[
                        const Text('Descripción',
                            style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 8),
                        _ExpandablePlot(plot: plot),
                        const SizedBox(height: 20),
                      ],

                      // Director & Cast
                      if (director.isNotEmpty) ...[
                        _InfoRow(label: 'Director', value: director),
                        const SizedBox(height: 8),
                      ],
                      if (cast.isNotEmpty) ...[
                        _InfoRow(label: 'Reparto', value: cast),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WatchlistButton extends ConsumerWidget {
  final String id;
  const _WatchlistButton({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatefulBuilder(
      builder: (context, setState) {
        final isIn = AppStorage.isInWatchlist(id);
        return GestureDetector(
          onTap: () async {
            if (isIn) {
              await AppStorage.removeFromWatchlist(id);
            } else {
              await AppStorage.addToWatchlist(id);
            }
            setState(() {});
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardHover),
            ),
            child: Icon(
              isIn ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isIn ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _ErrorDetail extends StatelessWidget {
  final String error;
  const _ErrorDetail({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(error, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MetaBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: AppTextStyles.titleMedium.copyWith(color: color)),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  final String text;
  const _MetaText({required this.text});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.bodyMedium);
}

class _GenreTag extends StatelessWidget {
  final String label;
  const _GenreTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardHover),
      ),
      child: Text(label, style: AppTextStyles.labelMedium),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: AppTextStyles.button),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: '$label: ',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.textMuted)),
          TextSpan(text: value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ExpandablePlot extends StatefulWidget {
  final String plot;
  const _ExpandablePlot({required this.plot});

  @override
  State<_ExpandablePlot> createState() => _ExpandablePlotState();
}

class _ExpandablePlotState extends State<_ExpandablePlot> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.plot,
            style: AppTextStyles.bodyLarge,
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _expanded ? 'Leer menos' : 'Leer más',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
