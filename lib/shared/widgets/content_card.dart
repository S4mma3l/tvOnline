import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shimmer_card.dart';

// Carousel card — fixed dimensions, title below image
class ContentCard extends StatefulWidget {
  final int id;
  final String title;
  final String? imageUrl;
  final String? rating;
  final String? year;
  final String? genre;
  final String type;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const ContentCard({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.rating,
    this.year,
    this.genre,
    this.type = 'movie',
    this.onTap,
    this.width = 120,
    this.height = 180,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Poster(
                width: widget.width,
                height: widget.height,
                imageUrl: widget.imageUrl,
                rating: widget.rating,
                type: widget.type,
                title: widget.title,
              ),
              const SizedBox(height: 5),
              Flexible(
                child: _Info(title: widget.title, year: widget.year),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Grid card — fills entire grid cell, title overlaid at bottom
class GridCard extends StatefulWidget {
  final int id;
  final String title;
  final String? imageUrl;
  final String? rating;
  final String? year;
  final String type;
  final double? progress; // 0.0–1.0 watch progress
  final VoidCallback? onTap;

  const GridCard({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.rating,
    this.year,
    this.type = 'movie',
    this.progress,
    this.onTap,
  });

  @override
  State<GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<GridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image
              _buildImage(),

              // Bottom gradient + title overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xEE000000)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.titleSmall
                            .copyWith(color: Colors.white, letterSpacing: 0),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.year != null && widget.year!.isNotEmpty)
                        Text(widget.year!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white60)),
                    ],
                  ),
                ),
              ),

              // Rating badge top-right (hidden when "VISTO" badge takes its place)
              if ((widget.progress == null || widget.progress! < 0.9) &&
                  widget.rating != null &&
                  widget.rating!.isNotEmpty)
                Positioned(
                  top: 7,
                  right: 7,
                  child: _RatingBadge(rating: widget.rating!),
                ),

              // "VISTO" badge top-right when finished (≥ 90%)
              if (widget.progress != null && widget.progress! >= 0.9)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 10, color: Colors.white),
                        SizedBox(width: 2),
                        Text('VISTO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),

              // Series badge top-left
              if (widget.type == 'series')
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('SERIE', style: AppTextStyles.badge),
                  ),
                ),

              // Watch progress bar at very bottom
              if (widget.progress != null && widget.progress! > 0.01)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10)),
                    child: LinearProgressIndicator(
                      value: widget.progress!.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.card),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppColors.card,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.type == 'series'
                ? Icons.tv_rounded
                : Icons.movie_rounded,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.title,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Poster extends StatelessWidget {
  final double width;
  final double height;
  final String? imageUrl;
  final String? rating;
  final String type;
  final String title;

  const _Poster({
    required this.width,
    required this.height,
    this.imageUrl,
    this.rating,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ShimmerCard(),
              errorWidget: (_, __, ___) => _fallback(),
            )
          else
            _fallback(),
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: height * 0.4,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardGradient),
            ),
          ),
          if (rating != null && rating!.isNotEmpty)
            Positioned(
                top: 7, right: 7, child: _RatingBadge(rating: rating!)),
          if (type == 'series')
            Positioned(
              top: 7, left: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('SERIE', style: AppTextStyles.badge),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.card,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type == 'series' ? Icons.tv_rounded : Icons.movie_rounded,
                size: 32, color: AppColors.textMuted),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(title,
                  style: AppTextStyles.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _Info extends StatelessWidget {
  final String title;
  final String? year;
  const _Info({required this.title, this.year});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: AppTextStyles.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (year != null && year!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(year!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final r = double.tryParse(rating) ?? 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: r >= 7.0 ? AppColors.ratingGold : AppColors.textMuted,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              size: 11,
              color: r >= 7.0 ? AppColors.ratingGold : AppColors.textMuted),
          const SizedBox(width: 2),
          Text(
            r.toStringAsFixed(1),
            style: AppTextStyles.badge.copyWith(
              color: r >= 7.0 ? AppColors.ratingGold : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
