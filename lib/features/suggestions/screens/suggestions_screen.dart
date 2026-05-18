import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/providers/profile_provider.dart';

final _suggestionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getSuggestions();
});

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerencias'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Buzón'),
            Tab(icon: Icon(Icons.add_circle_rounded), text: 'Sugerir'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _SuggestionsList(onRefresh: () => ref.invalidate(_suggestionsProvider)),
          _SuggestForm(onSubmitted: () {
            ref.invalidate(_suggestionsProvider);
            _tab.animateTo(0);
          }),
        ],
      ),
    );
  }
}

class _SuggestionsList extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _SuggestionsList({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_suggestionsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_creation_outlined,
                      size: 56, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('Sé el primero en sugerir',
                      style: AppTextStyles.headlineSmall),
                  SizedBox(height: 6),
                  Text('¿Qué película o serie quieres ver?',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              return _SuggestionCard(
                item: item,
                userId: profile?['id'] as String?,
                onVote: () async {
                  if (profile == null) return;
                  await SupabaseService.voteSuggestion(
                    item['id'] as String,
                    profile['id'] as String,
                  );
                  onRefresh();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? userId;
  final VoidCallback onVote;

  const _SuggestionCard({
    required this.item,
    required this.userId,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String? ?? 'movie';
    final votes = item['votes'] as int? ?? 0;
    final isAdded = item['is_added'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdded
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.cardHover,
        ),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type == 'movie'
                  ? Icons.movie_rounded
                  : type == 'series'
                      ? Icons.tv_rounded
                      : Icons.live_tv_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item['title'] as String? ?? '',
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isAdded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('AGREGADA',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                letterSpacing: 0.8)),
                      ),
                  ],
                ),
                if (item['description'] != null &&
                    (item['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(item['description'] as String,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Vote button
          GestureDetector(
            onTap: userId != null ? onVote : null,
            child: Column(
              children: [
                Icon(
                  Icons.thumb_up_rounded,
                  size: 20,
                  color: userId != null
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                const SizedBox(height: 2),
                Text('$votes',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  const _SuggestForm({required this.onSubmitted});

  @override
  ConsumerState<_SuggestForm> createState() => _SuggestFormState();
}

class _SuggestFormState extends ConsumerState<_SuggestForm> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _type = 'movie';
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    if (profile == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('Regístrate primero para sugerir',
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Qué quieres ver?',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 6),
            const Text(
              'Sugiere una película, serie o canal que quieras que agreguen.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Type selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'movie',
                    label: Text('Película'),
                    icon: Icon(Icons.movie_rounded, size: 16)),
                ButtonSegment(
                    value: 'series',
                    label: Text('Serie'),
                    icon: Icon(Icons.tv_rounded, size: 16)),
                ButtonSegment(
                    value: 'live_channel',
                    label: Text('Canal'),
                    icon: Icon(Icons.live_tv_rounded, size: 16)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleCtrl,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Título *',
                prefixIcon: Icon(Icons.title_rounded, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Año (opcional)',
                prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                hintText: 'Ej: 2024',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Cuenta de qué trata o por qué la recomiendas...',
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        if (!_form.currentState!.validate()) return;
                        setState(() => _loading = true);
                        try {
                          await SupabaseService.submitSuggestion(
                            userId: profile['id'] as String,
                            title: _titleCtrl.text,
                            type: _type,
                            year: int.tryParse(_yearCtrl.text),
                            description: _descCtrl.text,
                          );
                          _titleCtrl.clear();
                          _yearCtrl.clear();
                          _descCtrl.clear();
                          widget.onSubmitted();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                icon: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(_loading ? 'Enviando...' : 'Enviar sugerencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
