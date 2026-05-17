import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_storage.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/vod_stream.dart';
import '../../../shared/models/series_model.dart';
import '../../../shared/models/category_model.dart';

// All VOD loaded once, then split into carousels
final allVodProvider = FutureProvider<List<VodStream>>((ref) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) return [];
  return api.getVodStreams();
});

final allSeriesProvider = FutureProvider<List<SeriesModel>>((ref) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) return [];
  return api.getSeries();
});

final vodCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) return [];
  return api.getVodCategories();
});

final seriesCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) return [];
  return api.getSeriesCategories();
});

// Hero banner: top rated VOD
final heroBannerItemsProvider = Provider<List<VodStream>>((ref) {
  final vods = ref.watch(allVodProvider).valueOrNull ?? [];
  final sorted = [...vods]
    ..sort((a, b) => b.ratingOutOf10.compareTo(a.ratingOutOf10));
  return sorted.take(10).toList();
});

// Trending: recently added (last 30 days)
final trendingVodProvider = Provider<List<VodStream>>((ref) {
  final vods = ref.watch(allVodProvider).valueOrNull ?? [];
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final month = 30 * 24 * 3600;
  final recent = vods.where((v) {
    final ts = int.tryParse(v.added ?? '');
    return ts != null && (now - ts) < month;
  }).toList();
  if (recent.length >= 10) {
    return (recent..sort((a, b) => (b.added ?? '').compareTo(a.added ?? '')))
        .take(20)
        .toList();
  }
  return (vods..sort((a, b) => (b.added ?? '').compareTo(a.added ?? '')))
      .take(20)
      .toList();
});

// Top rated
final topRatedVodProvider = Provider<List<VodStream>>((ref) {
  final vods = ref.watch(allVodProvider).valueOrNull ?? [];
  return ([...vods]..sort((a, b) => b.ratingOutOf10.compareTo(a.ratingOutOf10)))
      .take(20)
      .toList();
});

// Top rated series
final topRatedSeriesProvider = Provider<List<SeriesModel>>((ref) {
  final series = ref.watch(allSeriesProvider).valueOrNull ?? [];
  return ([...series]..sort((a, b) => b.ratingOutOf10.compareTo(a.ratingOutOf10)))
      .take(20)
      .toList();
});

// Trigger to force continueWatchingProvider to rebuild after deletions
final historyRefreshProvider = StateProvider<int>((ref) => 0);

// Continue watching — from local storage, refreshes on demand
final continueWatchingProvider = Provider<List<WatchHistoryEntry>>((ref) {
  ref.watch(historyRefreshProvider); // rebuild when refresh triggered
  return AppStorage.continueWatching;
});

// Carousels by category (top 5 categories by content count)
final featuredCategoriesProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  final vods = ref.watch(allVodProvider).valueOrNull ?? [];
  final categories = ref.watch(vodCategoriesProvider).valueOrNull ?? [];

  final Map<String, List<VodStream>> byCat = {};
  for (final v in vods) {
    final cat = v.categoryId ?? '';
    byCat.putIfAbsent(cat, () => []).add(v);
  }

  return categories
      .where((c) => (byCat[c.categoryId]?.length ?? 0) >= 5)
      .map((c) => {
            'category': c,
            'items': (byCat[c.categoryId] ?? [])
              ..sort((a, b) => b.ratingOutOf10.compareTo(a.ratingOutOf10)),
          })
      .take(8)
      .toList();
});
