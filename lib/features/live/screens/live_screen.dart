import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/live_channel.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

final _liveChannelsProvider = FutureProvider<List<LiveChannel>>((ref) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) return [];
  return api.getLiveStreams();
});

final _liveCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.watch(xtreamApiProvider);
  if (api == null) return [];
  return api.getLiveCategories();
});

final _selectedLiveCatProvider = StateProvider<String?>((ref) => null);

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(_liveChannelsProvider);
    final categoriesAsync = ref.watch(_liveCategoriesProvider);
    final selectedCat = ref.watch(_selectedLiveCatProvider);
    final config = ref.watch(serverConfigProvider).valueOrNull;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            title: const Text('TV en vivo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.invalidate(_liveChannelsProvider);
                  ref.invalidate(_liveCategoriesProvider);
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: categoriesAsync.when(
                data: (cats) => SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cats.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _CatChip(
                          label: 'Todos',
                          selected: selectedCat == null,
                          onTap: () => ref
                              .read(_selectedLiveCatProvider.notifier)
                              .state = null,
                        );
                      }
                      final cat = cats[i - 1];
                      return _CatChip(
                        label: cat.categoryName,
                        selected: selectedCat == cat.categoryId,
                        onTap: () => ref
                            .read(_selectedLiveCatProvider.notifier)
                            .state = cat.categoryId,
                      );
                    },
                  ),
                ),
                loading: () => const SizedBox(height: 44),
                error: (_, __) => const SizedBox(height: 44),
              ),
            ),
          ),
        ],
        body: channelsAsync.when(
          loading: () => const ShimmerGrid(childAspectRatio: 1.6),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (channels) {
            final filtered = selectedCat == null
                ? channels
                : channels
                    .where((c) => c.categoryId == selectedCat)
                    .toList();

            if (filtered.isEmpty) {
              return const Center(
                child: Text('Sin canales', style: AppTextStyles.headlineSmall),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols(MediaQuery.of(context).size.width),
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final ch = filtered[i];
                final url = config != null
                    ? '${config.serverUrl}/live/${config.username}/${config.password}/${ch.streamId}.m3u8'
                    : '';
                return _ChannelCard(
                  channel: ch,
                  onTap: () => context.push('/player', extra: {
                    'url': url,
                    'title': ch.name,
                    'watchKey': 'live_${ch.streamId}',
                    'poster': ch.streamIcon,
                    'type': 'live',
                    'streamId': ch.streamId,
                  }),
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _cols(double w) {
    if (w >= 1000) return 5;
    if (w >= 700) return 4;
    if (w >= 500) return 3;
    return 2;
  }
}

class _ChannelCard extends StatelessWidget {
  final LiveChannel channel;
  final VoidCallback onTap;

  const _ChannelCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardHover, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (channel.streamIcon != null && channel.streamIcon!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: channel.streamIcon!,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _fallback(),
              )
            else
              _fallback(),

            // Live badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.white),
                    SizedBox(width: 4),
                    Text('EN VIVO', style: AppTextStyles.badge),
                  ],
                ),
              ),
            ),

            // Channel name bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD000000)],
                  ),
                ),
                child: Text(
                  channel.name,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.live_tv_rounded, size: 36, color: AppColors.textMuted),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
