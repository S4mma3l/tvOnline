import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/vod_stream.dart';

class HeroBanner extends StatefulWidget {
  final List<VodStream> items;

  const HeroBanner({super.key, required this.items});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late PageController _pageCtrl;
  int _current = 0;
  Timer? _timer;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.items.isEmpty) return;
      final next = (_current + 1) % widget.items.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAndResume() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 8), _startTimer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final height = MediaQuery.of(context).size.height * 0.58;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) {
              setState(() => _current = i);
              _pauseAndResume();
            },
            itemCount: widget.items.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: _pauseAndResume,
              child: _HeroBannerItem(item: widget.items[i]),
            ),
          ),
          // Bottom gradient to blend with background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: height * 0.6,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.heroGradient),
            ),
          ),
          // Content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _HeroBannerContent(
              item: widget.items[_current],
              pageController: _pageCtrl,
              itemCount: widget.items.length,
              currentIndex: _current,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBannerItem extends StatelessWidget {
  final VodStream item;
  const _HeroBannerItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: item.streamIcon ?? '',
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.surface),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surface,
        child: const Center(
          child: Icon(Icons.movie_rounded, size: 60, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _HeroBannerContent extends StatelessWidget {
  final VodStream item;
  final PageController pageController;
  final int itemCount;
  final int currentIndex;

  const _HeroBannerContent({
    required this.item,
    required this.pageController,
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Genres tags
          if (item.genre != null && item.genre!.isNotEmpty)
            _GenreTags(genres: item.genre!),

          const SizedBox(height: 10),

          // Title
          Text(
            item.name,
            style: AppTextStyles.displayMedium.copyWith(
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha:0.8),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Meta row
          Row(
            children: [
              if (item.ratingOutOf10 > 0) ...[
                const Icon(Icons.star_rounded,
                    size: 16, color: AppColors.ratingGold),
                const SizedBox(width: 4),
                Text(
                  item.ratingOutOf10.toStringAsFixed(1),
                  style: AppTextStyles.rating,
                ),
                const SizedBox(width: 14),
              ],
              if (item.year.isNotEmpty)
                Text(item.year, style: AppTextStyles.bodyMedium),
              if (item.year.isNotEmpty && item.durationFormatted.isNotEmpty)
                const Text('  ·  ', style: AppTextStyles.bodyMedium),
              if (item.durationFormatted.isNotEmpty)
                Text(item.durationFormatted,
                    style: AppTextStyles.bodyMedium),
            ],
          ),

          const SizedBox(height: 6),

          // Plot
          if (item.plot != null && item.plot!.isNotEmpty)
            Text(
              item.plot!,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: [
              _PlayButton(
                onTap: () => context.push('/movie/${item.streamId}'),
              ),
              const SizedBox(width: 12),
              _InfoButton(
                onTap: () => context.push('/movie/${item.streamId}'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Page indicator
          Center(
            child: SmoothPageIndicator(
              controller: pageController,
              count: itemCount,
              effect: const WormEffect(
                dotWidth: 7,
                dotHeight: 7,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.textMuted,
                spacing: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text('Reproducir', style: AppTextStyles.button),
          ],
        ),
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _InfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha:0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text('Más info', style: AppTextStyles.button),
          ],
        ),
      ),
    );
  }
}

class _GenreTags extends StatelessWidget {
  final String genres;
  const _GenreTags({required this.genres});

  @override
  Widget build(BuildContext context) {
    final tags = genres.split(',').map((e) => e.trim()).take(3).toList();
    return Wrap(
      spacing: 6,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha:0.2)),
          ),
          child: Text(tag, style: AppTextStyles.badge),
        );
      }).toList(),
    );
  }
}
