import 'package:dio/dio.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/vod_stream.dart';
import '../../shared/models/series_model.dart';
import '../../shared/models/live_channel.dart';

class XtreamApi {
  final Dio _dio;
  final String baseUrl;
  final String username;
  final String password;

  XtreamApi({
    required this.baseUrl,
    required this.username,
    required this.password,
  }) : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(minutes: 3), // 30K items JSON needs time
            headers: {'Accept': 'application/json'},
          ),
        );

  String get _base => '$baseUrl/player_api.php?username=$username&password=$password';

  Future<Map<String, dynamic>> authenticate() async {
    final response = await _dio.get(_base);
    return response.data as Map<String, dynamic>;
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getVodCategories() async {
    final response = await _dio.get('$_base&action=get_vod_categories');
    final list = response.data as List;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CategoryModel>> getSeriesCategories() async {
    final response = await _dio.get('$_base&action=get_series_categories');
    final list = response.data as List;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CategoryModel>> getLiveCategories() async {
    final response = await _dio.get('$_base&action=get_live_categories');
    final list = response.data as List;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── VOD ───────────────────────────────────────────────────────────────────

  Future<List<VodStream>> getVodStreams({String? categoryId}) async {
    final url = categoryId != null
        ? '$_base&action=get_vod_streams&category_id=$categoryId'
        : '$_base&action=get_vod_streams';
    final response = await _dio.get(url);
    final list = response.data as List;
    return list
        .map((e) => VodStream.fromJson(e as Map<String, dynamic>))
        .where((v) => v.streamId > 0)
        .toList();
  }

  Future<Map<String, dynamic>> getVodInfo(int vodId) async {
    final response = await _dio.get('$_base&action=get_vod_info&vod_id=$vodId');
    return response.data as Map<String, dynamic>;
  }

  // ── Series ────────────────────────────────────────────────────────────────

  Future<List<SeriesModel>> getSeries({String? categoryId}) async {
    final url = categoryId != null
        ? '$_base&action=get_series&category_id=$categoryId'
        : '$_base&action=get_series';
    final response = await _dio.get(url);
    final list = response.data as List;
    return list
        .map((e) => SeriesModel.fromJson(e as Map<String, dynamic>))
        .where((s) => s.seriesId > 0)
        .toList();
  }

  Future<Map<String, dynamic>> getSeriesInfo(int seriesId) async {
    final response =
        await _dio.get('$_base&action=get_series_info&series_id=$seriesId');
    return response.data as Map<String, dynamic>;
  }

  // ── Live TV ───────────────────────────────────────────────────────────────

  Future<List<LiveChannel>> getLiveStreams({String? categoryId}) async {
    final url = categoryId != null
        ? '$_base&action=get_live_streams&category_id=$categoryId'
        : '$_base&action=get_live_streams';
    final response = await _dio.get(url);
    final list = response.data as List;
    return list
        .map((e) => LiveChannel.fromJson(e as Map<String, dynamic>))
        .where((c) => c.streamId > 0)
        .toList();
  }

  // ── EPG ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getShortEpg(int streamId, {int limit = 4}) async {
    final response = await _dio.get(
        '$_base&action=get_short_epg&stream_id=$streamId&limit=$limit');
    return response.data as Map<String, dynamic>;
  }

  // ── Stream URLs ───────────────────────────────────────────────────────────

  String vodStreamUrl(int streamId, String extension) =>
      '$baseUrl/movie/$username/$password/$streamId.$extension';

  String seriesStreamUrl(int episodeId, String extension) =>
      '$baseUrl/series/$username/$password/$episodeId.$extension';

  String liveStreamUrl(int streamId) =>
      '$baseUrl/live/$username/$password/$streamId.m3u8';

  String get m3uUrl =>
      '$baseUrl/get.php?username=$username&password=$password&type=m3u_plus';
}
