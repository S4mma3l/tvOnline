import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/series_model.dart';

final vodInfoProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, vodId) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) throw Exception('No hay conexión al servidor');
  return api.getVodInfo(vodId);
});

final seriesInfoProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, seriesId) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) throw Exception('No hay conexión al servidor');
  return api.getSeriesInfo(seriesId);
});

// Parse series info into seasons map
final seriesSeasonsProvider =
    Provider.family<Map<int, List<SeriesEpisode>>, int>((ref, seriesId) {
  final info = ref.watch(seriesInfoProvider(seriesId)).valueOrNull;
  if (info == null) return {};

  final episodes = info['episodes'] as Map<String, dynamic>? ?? {};
  final Map<int, List<SeriesEpisode>> seasons = {};

  for (final entry in episodes.entries) {
    final season = int.tryParse(entry.key) ?? 1;
    final epList = (entry.value as List)
        .map((e) => SeriesEpisode.fromJson(e as Map<String, dynamic>))
        .toList();
    seasons[season] = epList;
  }

  return seasons;
});
