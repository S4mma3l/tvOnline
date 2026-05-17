class VodStream {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String? rating;
  final double? ratingBased;
  final String? added;
  final String? categoryId;
  final List<int> categoryIds;
  final String containerExtension;
  final String? director;
  final String? cast;
  final String? plot;
  final String? releaseDate;
  final String? genre;
  final String? youtubeTrailer;
  final int? episodeRunTime;
  final String? country;

  const VodStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.rating,
    this.ratingBased,
    this.added,
    this.categoryId,
    this.categoryIds = const [],
    this.containerExtension = 'mkv',
    this.director,
    this.cast,
    this.plot,
    this.releaseDate,
    this.genre,
    this.youtubeTrailer,
    this.episodeRunTime,
    this.country,
  });

  factory VodStream.fromJson(Map<String, dynamic> json) {
    List<int> catIds = [];
    if (json['category_ids'] is List) {
      catIds = (json['category_ids'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    return VodStream(
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString(),
      rating: json['rating']?.toString(),
      ratingBased: double.tryParse(json['rating_5based']?.toString() ?? ''),
      added: json['added']?.toString(),
      categoryId: json['category_id']?.toString(),
      categoryIds: catIds,
      containerExtension:
          json['container_extension']?.toString() ?? 'mkv',
      director: json['director']?.toString(),
      cast: json['cast']?.toString(),
      plot: json['plot']?.toString(),
      releaseDate: json['releasedate']?.toString(),
      genre: json['genre']?.toString(),
      youtubeTrailer: json['youtube_trailer']?.toString(),
      episodeRunTime:
          int.tryParse(json['episode_run_time']?.toString() ?? ''),
      country: json['country']?.toString(),
    );
  }

  String streamUrl(String baseUrl, String username, String password) {
    return '$baseUrl/movie/$username/$password/$streamId.$containerExtension';
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

  String get durationFormatted {
    if (episodeRunTime == null) return '';
    final h = episodeRunTime! ~/ 60;
    final m = episodeRunTime! % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
