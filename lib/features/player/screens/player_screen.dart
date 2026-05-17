import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/storage/app_storage.dart';
// WatchHistoryEntry and ContentTrackSettings are defined in app_storage.dart
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String streamUrl;
  final String title;
  final String watchKey;
  final String? poster;
  final String type;
  final int streamId;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    required this.watchKey,
    this.poster,
    this.type = 'vod',
    this.streamId = 0,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late final AnimationController _animCtrl;
  late final Animation<double> _controlsAnim;
  final _focusNode = FocusNode();

  bool _controlsVisible = true;
  bool _trackSettingsRestored = false;
  Timer? _hideTimer;
  final List<StreamSubscription> _subs = [];

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    _controlsAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );

    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 96 * 1024 * 1024, // 96 MB buffer
      ),
    );
    // Default VideoController — hardware acceleration managed by media_kit internally
    _controller = VideoController(_player);
    _initPlayback();
  }

  Future<void> _initPlayback() async {
    // Set MPV network properties BEFORE opening media
    try {
      final p = _player.platform as dynamic;
      // Network caching — key for smooth playback
      await p.setProperty('cache', 'yes');
      await p.setProperty('cache-secs', '60');
      await p.setProperty('demuxer-readahead-secs', '30');
      await p.setProperty('network-timeout', '60');
      await p.setProperty('stream-buffer-size', '4MiB');
      // Reduce audio sync issues
      await p.setProperty('audio-pitch-correction', 'yes');
      // Better seek performance
      await p.setProperty('hr-seek', 'yes');
      await p.setProperty('hr-seek-framedrop', 'yes');
    } catch (_) {
      // Web or platform doesn't support MPV properties
    }

    final saved = AppStorage.getWatchProgress(widget.watchKey);
    final startPos = saved != null
        ? Duration(seconds: (saved['position'] as int? ?? 0))
        : Duration.zero;

    await _player.open(Media(widget.streamUrl,
        start: startPos.inSeconds > 10 ? startPos : Duration.zero));

    _scheduleHide();

    // Save progress + history every 10 seconds
    _subs.add(_player.stream.position.listen((pos) {
      final dur = _player.state.duration.inSeconds;
      if (dur > 0 && pos.inSeconds % 10 == 0 && pos.inSeconds > 0) {
        AppStorage.saveWatchProgress(
          key: widget.watchKey,
          positionSeconds: pos.inSeconds,
          durationSeconds: dur,
        );
        // Save to rich history only for non-live content
        if (widget.type != 'live') {
          AppStorage.addToHistory(WatchHistoryEntry(
            watchKey: widget.watchKey,
            title: widget.title,
            poster: widget.poster,
            type: widget.type,
            streamId: widget.streamId,
            positionSeconds: pos.inSeconds,
            durationSeconds: dur,
            updatedAt: DateTime.now(),
          ));
        }
      }
    }));

    // Restore saved audio/subtitle settings when tracks are available
    _subs.add(_player.stream.tracks.listen((tracks) {
      if (!_trackSettingsRestored) {
        _trackSettingsRestored = true;
        _restoreTrackSettings(tracks);
      }
    }));
  }

  void _restoreTrackSettings(Tracks tracks) {
    final saved = AppStorage.getTrackSettings(widget.watchKey);
    if (saved == null) return;

    // Restore audio track
    if (saved.audioTrackId != null && tracks.audio.length > 1) {
      final audioTrack = tracks.audio.where(
        (t) => t.id == saved.audioTrackId ||
            (saved.audioLanguage != null && t.language == saved.audioLanguage),
      ).firstOrNull;
      if (audioTrack != null) _player.setAudioTrack(audioTrack);
    }

    // Restore subtitle track
    if (saved.subtitleTrackId == 'no') {
      _player.setSubtitleTrack(SubtitleTrack.no());
    } else if (saved.subtitleTrackId != null && tracks.subtitle.isNotEmpty) {
      final subTrack = tracks.subtitle.where(
        (t) => t.id == saved.subtitleTrackId ||
            (saved.subtitleLanguage != null &&
                t.language == saved.subtitleLanguage),
      ).firstOrNull;
      if (subTrack != null) _player.setSubtitleTrack(subTrack);
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode.dispose();
    _animCtrl.dispose();
    for (final s in _subs) s.cancel();
    _saveProgress();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _saveProgress() {
    final pos = _player.state.position.inSeconds;
    final dur = _player.state.duration.inSeconds;
    if (pos > 0) {
      AppStorage.saveWatchProgress(
        key: widget.watchKey,
        positionSeconds: pos,
        durationSeconds: dur,
      );
      if (widget.type != 'live' && dur > 0) {
        AppStorage.addToHistory(WatchHistoryEntry(
          watchKey: widget.watchKey,
          title: widget.title,
          poster: widget.poster,
          type: widget.type,
          streamId: widget.streamId,
          positionSeconds: pos,
          durationSeconds: dur,
          updatedAt: DateTime.now(),
        ));
      }
    }
    // Save current track selection
    _saveCurrentTrackSettings();
  }

  void _saveCurrentTrackSettings() {
    final audio = _player.state.track.audio;
    final subtitle = _player.state.track.subtitle;
    AppStorage.saveTrackSettings(
      widget.watchKey,
      ContentTrackSettings(
        audioTrackId: audio.id,
        audioLanguage: audio.language,
        subtitleTrackId: subtitle.id,
        subtitleLanguage: subtitle.language,
      ),
    );
  }

  // ── Controls visibility ───────────────────────────────────────────────────

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _player.state.playing) _fadeOutControls();
    });
  }

  void _fadeInControls() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _animCtrl.forward();
    _scheduleHide();
  }

  void _fadeOutControls() {
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _onActivity() => _fadeInControls();

  void _onBackgroundTap() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      _fadeOutControls();
    } else {
      _fadeInControls();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _exit() {
    _saveProgress();
    context.pop();
  }

  void _seekBy(Duration offset) {
    final target = _player.state.position + offset;
    _player.seek(target.isNegative ? Duration.zero : target);
    _onActivity();
  }

  void _openTracks() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _TracksSheet(player: _player),
    ).then((_) {
      if (mounted) {
        // Save the new track selection after user closes the panel
        _saveCurrentTrackSettings();
        _scheduleHide();
      }
    });
  }

  // ── Keyboard ──────────────────────────────────────────────────────────────

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    _onActivity();
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _exit();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        _player.playOrPause();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _seekBy(const Duration(seconds: -10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _seekBy(const Duration(seconds: 10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _player.setVolume((_player.state.volume + 10).clamp(0, 100));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _player.setVolume((_player.state.volume - 10).clamp(0, 100));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyM:
        _player.setVolume(
            _player.state.volume > 0 ? 0 : 100);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _MouseActivityDetector(
          onActivity: _onActivity,
          showCursor: _controlsVisible,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video ──────────────────────────────────────────────────
              Video(controller: _controller),

              // ── Tap layer (below controls in Z-order) ─────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onBackgroundTap,
                onDoubleTapDown: (d) {
                  final half = MediaQuery.of(context).size.width / 2;
                  _seekBy(d.localPosition.dx < half
                      ? const Duration(seconds: -10)
                      : const Duration(seconds: 10));
                },
              ),

              // ── Controls overlay (absorbs taps when visible) ───────────
              FadeTransition(
                opacity: _controlsAnim,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _ControlsOverlay(
                    player: _player,
                    title: widget.title,
                    onBack: _exit,
                    onSeek: _seekBy,
                    onActivity: _onActivity,
                    onTracks: _openTracks,
                    onBackgroundTap: _onBackgroundTap,
                  ),
                ),
              ),

              // ── Always-visible thin progress line ──────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _ThinProgress(player: _player, visible: !_controlsVisible),
              ),

              // ── Buffering spinner ──────────────────────────────────────
              _BufferingOverlay(player: _player),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mouse activity detector ───────────────────────────────────────────────────
// Wraps everything — detects mouse movement and controls cursor visibility

class _MouseActivityDetector extends StatelessWidget {
  final VoidCallback onActivity;
  final bool showCursor;
  final Widget child;

  const _MouseActivityDetector({
    required this.onActivity,
    required this.showCursor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: (_) => onActivity(),
      onPointerDown: (_) => onActivity(),
      child: MouseRegion(
        // Oculta el cursor cuando los controles están ocultos (solo macOS/desktop)
        cursor: showCursor
            ? SystemMouseCursors.basic
            : SystemMouseCursors.none,
        onHover: (_) => onActivity(),
        child: child,
      ),
    );
  }
}

// ── Thin progress bar (always visible when controls are hidden) ───────────────

class _ThinProgress extends StatelessWidget {
  final Player player;
  final bool visible;
  const _ThinProgress({required this.player, required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 0.45 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: StreamBuilder(
        stream: player.stream.position,
        builder: (_, posSnap) {
          return StreamBuilder(
            stream: player.stream.duration,
            builder: (_, durSnap) {
              final pos = posSnap.data ?? Duration.zero;
              final dur = durSnap.data ?? Duration.zero;
              final progress = dur.inMilliseconds > 0
                  ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0;
              return LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Buffering overlay ─────────────────────────────────────────────────────────

class _BufferingOverlay extends StatelessWidget {
  final Player player;
  const _BufferingOverlay({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: player.stream.buffering,
      builder: (_, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Full controls overlay ─────────────────────────────────────────────────────

class _ControlsOverlay extends StatelessWidget {
  final Player player;
  final String title;
  final VoidCallback onBack;
  final void Function(Duration) onSeek;
  final VoidCallback onActivity;
  final VoidCallback onTracks;
  final VoidCallback onBackgroundTap;

  const _ControlsOverlay({
    required this.player,
    required this.title,
    required this.onBack,
    required this.onSeek,
    required this.onActivity,
    required this.onTracks,
    required this.onBackgroundTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBackgroundTap, // Background tap hides controls
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xBB000000),
              Colors.transparent,
              Colors.transparent,
              Color(0xBB000000),
            ],
            stops: [0.0, 0.22, 0.78, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                player: player, title: title,
                onBack: onBack, onTracks: onTracks, onActivity: onActivity,
              ),
              const Spacer(),
              _CenterControls(
                  player: player, onSeek: onSeek, onActivity: onActivity),
              const Spacer(),
              _ProgressSection(player: player, onActivity: onActivity),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Player player;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onTracks;
  final VoidCallback onActivity;

  const _TopBar({
    required this.player, required this.title, required this.onBack,
    required this.onTracks, required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 22),
              tooltip: 'Salir (Esc)',
              onPressed: onBack,
            ),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            // Audio / Subtitles / Speed
            IconButton(
              icon: const Icon(Icons.tune_rounded,
                  color: Colors.white, size: 24),
              tooltip: 'Audio · Subtítulos · Velocidad',
              onPressed: onTracks,
            ),
            // Volume
            StreamBuilder(
              stream: player.stream.volume,
              builder: (_, snap) {
                final vol = snap.data ?? 100.0;
                return IconButton(
                  icon: Icon(
                    vol < 1
                        ? Icons.volume_off_rounded
                        : vol < 50
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                    color: Colors.white, size: 22,
                  ),
                  onPressed: () {
                    player.setVolume(vol < 1 ? 100 : 0);
                    onActivity();
                  },
                );
              },
            ),
            // Fullscreen
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded,
                  color: Colors.white, size: 26),
              onPressed: () {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
                onActivity();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Center play/pause + seek ──────────────────────────────────────────────────

class _CenterControls extends StatelessWidget {
  final Player player;
  final void Function(Duration) onSeek;
  final VoidCallback onActivity;

  const _CenterControls({
    required this.player, required this.onSeek, required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: StreamBuilder(
        stream: player.stream.playing,
        builder: (_, playSnap) {
          final playing = playSnap.data ?? false;
          return StreamBuilder(
            stream: player.stream.buffering,
            builder: (_, bufSnap) {
              final buffering = bufSnap.data ?? false;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SeekIcon(
                    icon: Icons.replay_10_rounded,
                    onTap: () => onSeek(const Duration(seconds: -10)),
                  ),
                  const SizedBox(width: 48),
                  GestureDetector(
                    onTap: () {
                      player.playOrPause();
                      onActivity();
                    },
                    child: Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: Center(
                        child: buffering
                            ? const SizedBox(
                                width: 32, height: 32,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white, size: 44,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                  _SeekIcon(
                    icon: Icons.forward_10_rounded,
                    onTap: () => onSeek(const Duration(seconds: 10)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SeekIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SeekIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 46),
        ),
      );
}

// ── Progress section with buffer bar ─────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final Player player;
  final VoidCallback onActivity;

  const _ProgressSection({required this.player, required this.onActivity});

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: StreamBuilder(
        stream: player.stream.position,
        builder: (_, posSnap) {
          return StreamBuilder(
            stream: player.stream.duration,
            builder: (_, durSnap) {
              final pos = posSnap.data ?? Duration.zero;
              final dur = durSnap.data ?? Duration.zero;
              final progress = dur.inMilliseconds > 0
                  ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Buffer + seek slider
                    StreamBuilder(
                      stream: player.stream.buffer,
                      builder: (_, bufSnap) {
                        final bufPos = bufSnap.data ?? Duration.zero;
                        final bufProgress = dur.inMilliseconds > 0
                            ? (bufPos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;

                        return SizedBox(
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Buffer bar background
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Stack(children: [
                                  Container(
                                    height: 4,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: bufProgress,
                                    child: Container(
                                        height: 4,
                                        color: Colors.white
                                            .withValues(alpha: 0.35)),
                                  ),
                                ]),
                              ),
                              // Seek slider (transparent track, shows thumb)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                  overlayShape:
                                      const RoundSliderOverlayShape(
                                          overlayRadius: 18),
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: Colors.transparent,
                                  thumbColor: Colors.white,
                                  overlayColor: AppColors.primaryGlow,
                                ),
                                child: Slider(
                                  value: progress,
                                  onChangeStart: (_) =>
                                      player.pause(),
                                  onChanged: (v) {
                                    player.seek(Duration(
                                        milliseconds:
                                            (v * dur.inMilliseconds)
                                                .round()));
                                    onActivity();
                                  },
                                  onChangeEnd: (_) => player.play(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Time row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(pos),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70)),
                          Text(_fmt(dur),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Tracks & settings bottom sheet ───────────────────────────────────────────

class _TracksSheet extends StatefulWidget {
  final Player player;
  const _TracksSheet({required this.player});

  @override
  State<_TracksSheet> createState() => _TracksSheetState();
}

class _TracksSheetState extends State<_TracksSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scroll) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: _tab,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.labelLarge,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Icons.record_voice_over_rounded, size: 20),
                  text: 'Audio'),
              Tab(icon: Icon(Icons.subtitles_rounded, size: 20),
                  text: 'Subtítulos'),
              Tab(icon: Icon(Icons.speed_rounded, size: 20),
                  text: 'Velocidad'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _AudioTab(player: widget.player),
                _SubtitleTab(player: widget.player),
                _SpeedTab(player: widget.player),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Audio tab ─────────────────────────────────────────────────────────────────

class _AudioTab extends StatelessWidget {
  final Player player;
  const _AudioTab({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: player.stream.tracks,
      builder: (_, snap) {
        final tracks = (snap.data ?? player.state.tracks).audio;
        final current = player.state.track.audio;
        if (tracks.isEmpty) {
          return const _EmptySlot(msg: 'Pista de audio única');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: tracks.length,
          itemBuilder: (_, i) {
            final t = tracks[i];
            return _Tile(
              label: _label(t.language, t.title, 'Audio ${i + 1}'),
              selected: t.id == current.id,
              onTap: () {
                player.setAudioTrack(t);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  String _label(String? lang, String? title, String fallback) {
    final p = <String>[];
    if (lang != null && lang.isNotEmpty) p.add(lang.toUpperCase());
    if (title != null && title.isNotEmpty && title != lang) p.add(title);
    return p.isEmpty ? fallback : p.join(' · ');
  }
}

// ── Subtitle tab ──────────────────────────────────────────────────────────────

class _SubtitleTab extends StatelessWidget {
  final Player player;
  const _SubtitleTab({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: player.stream.tracks,
      builder: (_, snap) {
        final tracks = (snap.data ?? player.state.tracks).subtitle
            .where((t) => t.id != 'no')
            .toList();
        final current = player.state.track.subtitle;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Tile(
              label: 'Sin subtítulos',
              icon: Icons.subtitles_off_rounded,
              selected: current.id == 'no',
              onTap: () {
                player.setSubtitleTrack(SubtitleTrack.no());
                Navigator.pop(context);
              },
            ),
            if (tracks.isEmpty)
              const _EmptySlot(msg: 'No hay subtítulos en este archivo')
            else
              ...tracks.map((t) => _Tile(
                    label: _label(t.language, t.title, 'Subtítulo'),
                    selected: t.id == current.id,
                    onTap: () {
                      player.setSubtitleTrack(t);
                      Navigator.pop(context);
                    },
                  )),
          ],
        );
      },
    );
  }

  String _label(String? lang, String? title, String fallback) {
    final p = <String>[];
    if (lang != null && lang.isNotEmpty) p.add(lang.toUpperCase());
    if (title != null && title.isNotEmpty && title != lang) p.add(title);
    return p.isEmpty ? fallback : p.join(' · ');
  }
}

// ── Speed tab ─────────────────────────────────────────────────────────────────

class _SpeedTab extends StatelessWidget {
  final Player player;
  const _SpeedTab({required this.player});

  static const _speeds = [
    (0.25, '0.25× — Muy lento'),
    (0.5, '0.5× — Lento'),
    (0.75, '0.75× — Casi normal'),
    (1.0, '1× — Normal'),
    (1.25, '1.25× — Rápido'),
    (1.5, '1.5× — Más rápido'),
    (1.75, '1.75×'),
    (2.0, '2× — Doble velocidad'),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: player.stream.rate,
      builder: (_, snap) {
        final current = snap.data ?? player.state.rate;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: _speeds.map((entry) {
            final (speed, label) = entry;
            return _Tile(
              label: label,
              selected: (current - speed).abs() < 0.05,
              onTap: () {
                player.setRate(speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _Tile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon ?? (selected ? Icons.check_circle_rounded : Icons.circle_outlined),
        color: selected ? AppColors.primary : AppColors.textMuted,
        size: 22,
      ),
      title: Text(
        label,
        style: AppTextStyles.titleMedium.copyWith(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String msg;
  const _EmptySlot({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.info_outline_rounded,
            size: 36, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(msg,
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ]),
    );
  }
}
