import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// CWE-312: Simple XOR obfuscation for stored credentials.
// Prevents credentials from being trivially readable in storage files.
// Not a substitute for OS-level secure storage (use flutter_secure_storage for production).
String _obfuscate(String value) {
  const key = String.fromEnvironment('STORAGE_OBFUSCATION_KEY', defaultValue: 'tv0nL!n3K3y#2026');
  final bytes = utf8.encode(value);
  final keyBytes = utf8.encode(key);
  final result = List<int>.generate(
    bytes.length,
    (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
  );
  return base64Encode(result);
}

String _deobfuscate(String value) {
  try {
    final bytes = base64Decode(value);
    const key = String.fromEnvironment('STORAGE_OBFUSCATION_KEY', defaultValue: 'tv0nL!n3K3y#2026');
    final keyBytes = utf8.encode(key);
    final result = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(result);
  } catch (_) {
    return value; // Fallback for legacy plaintext values
  }
}

class AppStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'AppStorage.init() must be called first');
    return _prefs!;
  }

  // ── Server config ─────────────────────────────────────────────────────────

  // CWE-312: credentials stored obfuscated
  static String? get serverUrl {
    final v = _p.getString(AppConstants.keyServerUrl);
    return v != null ? _deobfuscate(v) : null;
  }

  static String? get username {
    final v = _p.getString(AppConstants.keyUsername);
    return v != null ? _deobfuscate(v) : null;
  }

  static String? get password {
    final v = _p.getString(AppConstants.keyPassword);
    return v != null ? _deobfuscate(v) : null;
  }

  static Future<void> saveServerConfig({
    required String url,
    required String user,
    required String pass,
  }) async {
    final cleanUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');
    // CWE-20: validate URL format before saving
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      throw ArgumentError('URL must start with http:// or https://');
    }
    await Future.wait([
      _p.setString(AppConstants.keyServerUrl, _obfuscate(cleanUrl)),
      _p.setString(AppConstants.keyUsername, _obfuscate(user.trim())),
      _p.setString(AppConstants.keyPassword, _obfuscate(pass.trim())),
    ]);
  }

  static bool get isConfigured =>
      serverUrl != null &&
      username != null &&
      password != null &&
      serverUrl!.isNotEmpty &&
      username!.isNotEmpty &&
      password!.isNotEmpty;

  static Future<void> clearConfig() async {
    await Future.wait([
      _p.remove(AppConstants.keyServerUrl),
      _p.remove(AppConstants.keyUsername),
      _p.remove(AppConstants.keyPassword),
      _p.remove(AppConstants.keyUserInfo),
    ]);
  }

  // ── User info ─────────────────────────────────────────────────────────────

  static Map<String, dynamic>? get userInfo {
    final raw = _p.getString(AppConstants.keyUserInfo);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveUserInfo(Map<String, dynamic> info) async {
    await _p.setString(AppConstants.keyUserInfo, jsonEncode(info));
  }

  // ── Watchlist ─────────────────────────────────────────────────────────────

  static List<String> get watchlist =>
      _p.getStringList(AppConstants.keyWatchlist) ?? [];

  static Future<void> addToWatchlist(String id) async {
    final list = watchlist;
    if (!list.contains(id)) {
      list.add(id);
      await _p.setStringList(AppConstants.keyWatchlist, list);
    }
  }

  static Future<void> removeFromWatchlist(String id) async {
    final list = watchlist..remove(id);
    await _p.setStringList(AppConstants.keyWatchlist, list);
  }

  static bool isInWatchlist(String id) => watchlist.contains(id);

  // ── Watch progress (position only) ───────────────────────────────────────

  static Map<String, dynamic> get _watchProgress {
    final raw = _p.getString(AppConstants.keyWatchHistory);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveWatchProgress({
    required String key,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final map = _watchProgress;
    map[key] = {
      'position': positionSeconds,
      'duration': durationSeconds,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _p.setString(AppConstants.keyWatchHistory, jsonEncode(map));
  }

  static Map<String, dynamic>? getWatchProgress(String key) =>
      _watchProgress[key] as Map<String, dynamic>?;

  // ── Rich watch history (with title, poster, metadata) ────────────────────

  static const _keyHistory = 'watch_history_rich';
  static const int _maxHistory = 50;

  static List<WatchHistoryEntry> get watchHistory {
    final raw = _p.getString(_keyHistory);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => WatchHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> removeFromHistory(String watchKey) async {
    final list = watchHistory..removeWhere((e) => e.watchKey == watchKey);
    await _p.setString(_keyHistory, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> clearHistory() async {
    await _p.remove(_keyHistory);
  }

  static Future<void> addToHistory(WatchHistoryEntry entry) async {
    final list = watchHistory;
    list.removeWhere((e) => e.watchKey == entry.watchKey);
    list.insert(0, entry);
    if (list.length > _maxHistory) list.removeLast();
    await _p.setString(_keyHistory, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  /// Items started but not finished (5% → 90%)
  static List<WatchHistoryEntry> get continueWatching {
    return watchHistory
        .where((e) => e.progress >= 0.05 && e.progress < 0.9)
        .toList();
  }

  // ── Per-content track settings (audio + subtitle per watchKey) ────────────

  static const _keyTrackSettings = 'track_settings_';

  static ContentTrackSettings? getTrackSettings(String watchKey) {
    final raw = _p.getString('$_keyTrackSettings$watchKey');
    if (raw == null) return null;
    return ContentTrackSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveTrackSettings(
      String watchKey, ContentTrackSettings settings) async {
    await _p.setString(
        '$_keyTrackSettings$watchKey', jsonEncode(settings.toJson()));
  }

  // ── Global playback settings ──────────────────────────────────────────────

  static String get videoQuality =>
      _p.getString(AppConstants.keyVideoQuality) ?? 'auto';
  static Future<void> setVideoQuality(String q) =>
      _p.setString(AppConstants.keyVideoQuality, q);

  static String get subtitleLanguage =>
      _p.getString(AppConstants.keySubtitleLanguage) ?? 'off';
  static Future<void> setSubtitleLanguage(String lang) =>
      _p.setString(AppConstants.keySubtitleLanguage, lang);

  static String get audioLanguage =>
      _p.getString(AppConstants.keyAudioLanguage) ?? 'original';
  static Future<void> setAudioLanguage(String lang) =>
      _p.setString(AppConstants.keyAudioLanguage, lang);
}

// ── Data models ───────────────────────────────────────────────────────────────

class WatchHistoryEntry {
  final String watchKey;
  final String title;
  final String? poster;
  final String type; // 'vod' | 'series' | 'live'
  final int streamId;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime updatedAt;

  const WatchHistoryEntry({
    required this.watchKey,
    required this.title,
    this.poster,
    required this.type,
    required this.streamId,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
  });

  double get progress =>
      durationSeconds > 0 ? positionSeconds / durationSeconds : 0.0;

  bool get isLive => type == 'live';

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> j) =>
      WatchHistoryEntry(
        watchKey: j['watchKey'] as String,
        title: j['title'] as String,
        poster: j['poster'] as String?,
        type: j['type'] as String? ?? 'vod',
        streamId: j['streamId'] as int? ?? 0,
        positionSeconds: j['positionSeconds'] as int? ?? 0,
        durationSeconds: j['durationSeconds'] as int? ?? 0,
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'watchKey': watchKey,
        'title': title,
        'poster': poster,
        'type': type,
        'streamId': streamId,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class ContentTrackSettings {
  final String? audioTrackId;
  final String? audioLanguage;
  final String? subtitleTrackId;
  final String? subtitleLanguage;

  const ContentTrackSettings({
    this.audioTrackId,
    this.audioLanguage,
    this.subtitleTrackId,
    this.subtitleLanguage,
  });

  factory ContentTrackSettings.fromJson(Map<String, dynamic> j) =>
      ContentTrackSettings(
        audioTrackId: j['audioTrackId'] as String?,
        audioLanguage: j['audioLanguage'] as String?,
        subtitleTrackId: j['subtitleTrackId'] as String?,
        subtitleLanguage: j['subtitleLanguage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'audioTrackId': audioTrackId,
        'audioLanguage': audioLanguage,
        'subtitleTrackId': subtitleTrackId,
        'subtitleLanguage': subtitleLanguage,
      };
}
