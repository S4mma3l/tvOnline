class SeriesModel {
  final int seriesId;
  final String name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final String? rating;
  final double? ratingBased;
  final String? categoryId;
  final List<int> categoryIds;
  final String? youtubeTrailer;
  final int? episodeRunTime;
  final List<String> backdropPath;

  const SeriesModel({
    required this.seriesId,
    required this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.rating,
    this.ratingBased,
    this.categoryId,
    this.categoryIds = const [],
    this.youtubeTrailer,
    this.episodeRunTime,
    this.backdropPath = const [],
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    List<int> catIds = [];
    if (json['category_ids'] is List) {
      catIds = (json['category_ids'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    List<String> backdrops = [];
    if (json['backdrop_path'] is List) {
      backdrops = (json['backdrop_path'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SeriesModel(
      seriesId: int.tryParse(json['series_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      cover: json['cover']?.toString(),
      plot: json['plot']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
      rating: json['rating']?.toString(),
      ratingBased: double.tryParse(json['rating_5based']?.toString() ?? ''),
      categoryId: json['category_id']?.toString(),
      categoryIds: catIds,
      youtubeTrailer: json['youtube_trailer']?.toString(),
      episodeRunTime:
          int.tryParse(json['episode_run_time']?.toString() ?? ''),
      backdropPath: backdrops,
    );
  }

  double get ratingOutOf10 {
    if (rating != null) {
      return double.tryParse(rating!) ?? 0.0;
    }
    if (ratingBased != null) return ratingBased! * 2;
    return 0.0;
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.length >= 4 ? releaseDate!.substring(0, 4) : releaseDate!;
  }

  String? get backdropUrl => backdropPath.isNotEmpty ? backdropPath.first : null;
}

class SeriesEpisode {
  final int id;
  final String title;
  final int? season;
  final int? episodeNum;
  final String? plot;
  final String? info;
  final String containerExtension;
  final int? duration;
  final String? movieImage;

  const SeriesEpisode({
    required this.id,
    required this.title,
    this.season,
    this.episodeNum,
    this.plot,
    this.info,
    this.containerExtension = 'mkv',
    this.duration,
    this.movieImage,
  });

  factory SeriesEpisode.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>?;
    return SeriesEpisode(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Episodio',
      season: int.tryParse(json['season']?.toString() ?? ''),
      episodeNum: int.tryParse(json['episode_num']?.toString() ?? ''),
      plot: info?['plot']?.toString() ?? json['plot']?.toString(),
      info: json['info']?.toString(),
      containerExtension:
          json['container_extension']?.toString() ?? 'mkv',
      duration: int.tryParse(
          info?['duration_secs']?.toString() ?? ''),
      movieImage: info?['movie_image']?.toString(),
    );
  }

  String streamUrl(String baseUrl, String username, String password) {
    return '$baseUrl/series/$username/$password/$id.$containerExtension';
  }

  String get durationFormatted {
    if (duration == null) return '';
    final h = duration! ~/ 3600;
    final m = (duration! % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
