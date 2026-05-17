import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/content_card.dart';

class ContentCarousel extends StatelessWidget {
  final String title;
  final List<ContentCardData> items;
  final VoidCallback? onSeeAll;
  final double cardWidth;
  final double cardHeight;

  const ContentCarousel({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    this.cardWidth = 120,
    this.cardHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.sectionTitle),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('Ver todo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
            ],
          ),
        ),
        SizedBox(
          height: cardHeight + 60, // card + title below
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              return ContentCard(
                id: item.id,
                title: item.title,
                imageUrl: item.imageUrl,
                rating: item.rating,
                year: item.year,
                genre: item.genre,
                type: item.type,
                onTap: item.onTap,
                width: cardWidth,
                height: cardHeight,
              );
            },
          ),
        ),
      ],
    );
  }
}

class ContentCardData {
  final int id;
  final String title;
  final String? imageUrl;
  final String? rating;
  final String? year;
  final String? genre;
  final String type;
  final VoidCallback? onTap;

  const ContentCardData({
    required this.id,
    required this.title,
    this.imageUrl,
    this.rating,
    this.year,
    this.genre,
    this.type = 'movie',
    this.onTap,
  });
}
