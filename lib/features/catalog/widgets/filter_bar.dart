import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/category_model.dart';

class FilterBar extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final String sortBy;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSortChanged;

  const FilterBar({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.sortBy,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _SortChip(
                label: 'Mejor valoradas',
                value: 'rating',
                selected: sortBy == 'rating',
                onTap: onSortChanged,
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'A–Z',
                value: 'name',
                selected: sortBy == 'name',
                onTap: onSortChanged,
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Año',
                value: 'year',
                selected: sortBy == 'year',
                onTap: onSortChanged,
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Recientes',
                value: 'added',
                selected: sortBy == 'added',
                onTap: onSortChanged,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Categories
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _CategoryChip(
                  label: 'Todo',
                  selected: selectedCategoryId == null,
                  onTap: () => onCategoryChanged(null),
                );
              }
              final cat = categories[i - 1];
              return _CategoryChip(
                label: cat.categoryName,
                selected: selectedCategoryId == cat.categoryId,
                onTap: () => onCategoryChanged(cat.categoryId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textMuted,
            width: selected ? 0 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
