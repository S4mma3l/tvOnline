import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/home/providers/home_provider.dart';
import '../../../shared/models/vod_stream.dart';
import '../../../shared/models/series_model.dart';

// VOD catalog state
class CatalogState {
  final String? selectedCategoryId;
  final String searchQuery;
  final String sortBy; // 'rating' | 'name' | 'year' | 'added'
  final bool descending;

  const CatalogState({
    this.selectedCategoryId,
    this.searchQuery = '',
    this.sortBy = 'rating',
    this.descending = true,
  });

  CatalogState copyWith({
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    String? sortBy,
    bool? descending,
  }) {
    return CatalogState(
      selectedCategoryId:
          clearCategory ? null : selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
    );
  }
}

final vodCatalogStateProvider =
    StateProvider<CatalogState>((ref) => const CatalogState());

final filteredVodProvider = Provider<List<VodStream>>((ref) {
  final all = ref.watch(allVodProvider).valueOrNull ?? [];
  final state = ref.watch(vodCatalogStateProvider);

  var filtered = all.where((v) {
    // Category filter
    if (state.selectedCategoryId != null) {
      if (v.categoryId != state.selectedCategoryId) return false;
    }
    // Search
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      return v.name.toLowerCase().contains(q) ||
          (v.genre?.toLowerCase().contains(q) ?? false) ||
          (v.director?.toLowerCase().contains(q) ?? false) ||
          (v.cast?.toLowerCase().contains(q) ?? false);
    }
    return true;
  }).toList();

  // Sort
  filtered.sort((a, b) {
    int cmp;
    switch (state.sortBy) {
      case 'name':
        cmp = a.name.compareTo(b.name);
        break;
      case 'year':
        cmp = (a.year).compareTo(b.year);
        break;
      case 'added':
        cmp = (a.added ?? '').compareTo(b.added ?? '');
        break;
      default: // rating
        cmp = a.ratingOutOf10.compareTo(b.ratingOutOf10);
    }
    return state.descending ? -cmp : cmp;
  });

  return filtered;
});

// Series catalog state
final seriesCatalogStateProvider =
    StateProvider<CatalogState>((ref) => const CatalogState());

final filteredSeriesProvider = Provider<List<SeriesModel>>((ref) {
  final all = ref.watch(allSeriesProvider).valueOrNull ?? [];
  final state = ref.watch(seriesCatalogStateProvider);

  var filtered = all.where((s) {
    if (state.selectedCategoryId != null) {
      if (s.categoryId != state.selectedCategoryId) return false;
    }
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          (s.genre?.toLowerCase().contains(q) ?? false) ||
          (s.director?.toLowerCase().contains(q) ?? false) ||
          (s.cast?.toLowerCase().contains(q) ?? false);
    }
    return true;
  }).toList();

  filtered.sort((a, b) {
    int cmp;
    switch (state.sortBy) {
      case 'name':
        cmp = a.name.compareTo(b.name);
        break;
      case 'year':
        cmp = (a.year).compareTo(b.year);
        break;
      default:
        cmp = a.ratingOutOf10.compareTo(b.ratingOutOf10);
    }
    return state.descending ? -cmp : cmp;
  });

  return filtered;
});
