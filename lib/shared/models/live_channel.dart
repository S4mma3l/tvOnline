class LiveChannel {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String? epgChannelId;
  final String? categoryId;
  final List<int> categoryIds;
  final bool tvArchive;
  final int tvArchiveDuration;
  final bool isKids;

  const LiveChannel({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.epgChannelId,
    this.categoryId,
    this.categoryIds = const [],
    this.tvArchive = false,
    this.tvArchiveDuration = 0,
    this.isKids = false,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    List<int> catIds = [];
    if (json['category_ids'] is List) {
      catIds = (json['category_ids'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    return LiveChannel(
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString(),
      epgChannelId: json['epg_channel_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      categoryIds: catIds,
      tvArchive: json['tv_archive'] == 1 || json['tv_archive'] == '1',
      tvArchiveDuration:
          int.tryParse(json['tv_archive_duration']?.toString() ?? '0') ?? 0,
      isKids: json['is_kids'] == 1 || json['is_kids'] == '1',
    );
  }

  String streamUrl(String baseUrl, String username, String password) {
    return '$baseUrl/live/$username/$password/$streamId.m3u8';
  }
}
