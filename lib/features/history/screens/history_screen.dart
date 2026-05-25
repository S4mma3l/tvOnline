import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/providers/home_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(historyRefreshProvider);

    final history = AppStorage.watchHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (history.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, ref),
              child: const Text('Limpiar todo',
                  style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: history.isEmpty
          ? const _EmptyHistory()
          : _HistoryList(history: history, ref: ref),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Eliminar todo el historial de reproducción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStorage.clearHistory();
              ref.read(historyRefreshProvider.notifier).state++;
            },
            child: Text('Limpiar todo',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── History list grouped by date ──────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<WatchHistoryEntry> history;
  final WidgetRef ref;

  const _HistoryList({required this.history, required this.ref});

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(history);

    return CustomScrollView(
      slivers: [
        for (final group in groups) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(group.label, style: AppTextStyles.sectionTitle),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final entry = group.entries[i];
                  return _HistoryTile(
                    entry: entry,
                    onRemove: () async {
                      await AppStorage.removeFromHistory(entry.watchKey);
                      ref.read(historyRefreshProvider.notifier).state++;
                    },
                    onTap: () => _navigateTo(context, entry),
                  );
                },
                childCount: group.entries.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  void _navigateTo(BuildContext context, WatchHistoryEntry entry) {
    if (entry.type == 'vod') {
      context.push('/movie/${entry.streamId}');
    } else if (entry.type == 'series') {
      context.push('/series/${entry.streamId}');
    }
  }

  List<_HistoryGroup> _groupByDate(List<WatchHistoryEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final groups = <String, List<WatchHistoryEntry>>{};

    for (final e in entries) {
      final d = DateTime(e.updatedAt.year, e.updatedAt.month, e.updatedAt.day);
      String label;
      if (!d.isBefore(today)) {
        label = 'Hoy';
      } else if (!d.isBefore(yesterday)) {
        label = 'Ayer';
      } else if (!d.isBefore(thisWeek)) {
        label = 'Esta semana';
      } else {
        label = 'Antes';
      }
      groups.putIfAbsent(label, () => []).add(e);
    }

    const order = ['Hoy', 'Ayer', 'Esta semana', 'Antes'];
    return order
        .where((k) => groups.containsKey(k))
        .map((k) => _HistoryGroup(label: k, entries: groups[k]!))
        .toList();
  }
}

class _HistoryGroup {
  final String label;
  final List<WatchHistoryEntry> entries;
  const _HistoryGroup({required this.label, required this.entries});
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 72, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          const Text('Sin historial', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Las películas y series que veas aparecerán aquí.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History tile ──────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final WatchHistoryEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.entry,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = entry.progress.clamp(0.0, 1.0);
    final remaining = entry.durationSeconds > 0
        ? entry.durationSeconds - entry.positionSeconds
        : 0;
    final remainingStr = remaining > 0 ? _formatTime(remaining) : null;

    return Dismissible(
      key: ValueKey(entry.watchKey),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Quitar',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardHover, width: 0.5),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 90,
                        child: entry.poster != null && entry.poster!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: entry.poster!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(Icons.movie_rounded,
                                      color: AppColors.textMuted),
                                ),
                              )
                            : Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.movie_rounded,
                                    color: AppColors.textMuted),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.title,
                              style: AppTextStyles.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                entry.type == 'series'
                                    ? Icons.tv_rounded
                                    : Icons.movie_rounded,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.type == 'series' ? 'Serie' : 'Película',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                          if (remainingStr != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Faltan $remainingStr',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
              // Progress bar
              if (progress > 0)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.surface,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
