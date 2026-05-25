import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _quality = AppStorage.videoQuality;
  String _subtitle = AppStorage.subtitleLanguage;
  String _audio = AppStorage.audioLanguage;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(serverConfigProvider).valueOrNull;
    final version = ref.watch(_appVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mi cuenta
          const _SectionHeader(title: 'Mi cuenta'),
          _OptionTile(
            icon: Icons.manage_accounts_rounded,
            label: 'Perfil y suscripción',
            value: 'Ver estado',
            onTap: () => context.push('/profile'),
          ),
          _OptionTile(
            icon: Icons.lightbulb_rounded,
            label: 'Sugerir película o serie',
            value: 'Buzón',
            onTap: () => context.push('/suggestions'),
          ),
          _OptionTile(
            icon: Icons.bookmark_rounded,
            label: 'Mi lista',
            value: 'Ver guardados',
            onTap: () => context.push('/watchlist'),
          ),
          _OptionTile(
            icon: Icons.history_rounded,
            label: 'Historial',
            value: 'Ver todo',
            onTap: () => context.push('/history'),
          ),

          const SizedBox(height: 24),

          // Servidor IPTV
          const _SectionHeader(title: 'Servidor IPTV'),
          _InfoTile(
            icon: Icons.person_rounded,
            label: 'Usuario',
            value: config?.displayName ?? '—',
          ),
          _InfoTile(
            icon: Icons.calendar_month_rounded,
            label: 'Vencimiento',
            value: config?.expirationDate ?? '—',
          ),
          _InfoTile(
            icon: Icons.devices_rounded,
            label: 'Conexiones máx.',
            value: config?.maxConnections?.toString() ?? '—',
          ),
          _InfoTile(
            icon: Icons.dns_rounded,
            label: 'Servidor',
            value: AppStorage.serverUrl ?? '—',
          ),

          const SizedBox(height: 24),

          // Reproducción
          const _SectionHeader(title: 'Reproducción'),
          _OptionTile(
            icon: Icons.hd_rounded,
            label: 'Calidad de video',
            value: _qualityLabel(_quality),
            onTap: () => _showPicker(
              context,
              title: 'Calidad de video',
              options: const {
                'auto': 'Automática',
                '1080': '1080p Full HD',
                '720': '720p HD',
                '480': '480p SD',
                '360': '360p',
              },
              selected: _quality,
              onSelected: (v) async {
                await AppStorage.setVideoQuality(v);
                setState(() => _quality = v);
              },
            ),
          ),
          _OptionTile(
            icon: Icons.subtitles_rounded,
            label: 'Subtítulos',
            value: _subtitle == 'off' ? 'Desactivados' : _subtitle,
            onTap: () => _showPicker(
              context,
              title: 'Subtítulos',
              options: const {
                'off': 'Desactivados',
                'es': 'Español',
                'en': 'Inglés',
                'pt': 'Portugués',
                'fr': 'Francés',
              },
              selected: _subtitle,
              onSelected: (v) async {
                await AppStorage.setSubtitleLanguage(v);
                setState(() => _subtitle = v);
              },
            ),
          ),
          _OptionTile(
            icon: Icons.record_voice_over_rounded,
            label: 'Idioma de audio',
            value: _audio == 'original' ? 'Original' : _audio,
            onTap: () => _showPicker(
              context,
              title: 'Idioma de audio',
              options: const {
                'original': 'Original',
                'es': 'Español',
                'en': 'Inglés',
                'pt': 'Portugués',
                'fr': 'Francés',
              },
              selected: _audio,
              onSelected: (v) async {
                await AppStorage.setAudioLanguage(v);
                setState(() => _audio = v);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Almacenamiento
          const _SectionHeader(title: 'Almacenamiento'),
          _ActionTile(
            icon: Icons.cleaning_services_rounded,
            label: 'Limpiar caché de imágenes',
            onTap: () => _clearImageCache(context),
          ),
          _ActionTile(
            icon: Icons.delete_sweep_rounded,
            label: 'Borrar historial de reproducción',
            onTap: () => _clearHistory(context),
          ),

          const SizedBox(height: 24),

          // Acerca de
          const _SectionHeader(title: 'Acerca de'),
          _InfoTile(
            icon: Icons.info_rounded,
            label: 'Versión',
            value: version.when(
              data: (v) => v,
              loading: () => '...',
              error: (_, __) => '1.0.0',
            ),
          ),

          const SizedBox(height: 32),

          // Cerrar sesión
          ElevatedButton.icon(
            onPressed: () => _showLogoutConfirm(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha:0.15),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _qualityLabel(String q) {
    const map = {
      'auto': 'Automática',
      '1080': '1080p Full HD',
      '720': '720p HD',
      '480': '480p SD',
      '360': '360p',
    };
    return map[q] ?? q;
  }

  void _showPicker(
    BuildContext context, {
    required String title,
    required Map<String, String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title, style: AppTextStyles.headlineSmall),
          ),
          const SizedBox(height: 12),
          ...options.entries.map((e) => ListTile(
                title: Text(e.value, style: AppTextStyles.titleMedium),
                trailing: e.key == selected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(e.key);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _clearImageCache(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text(
            'Se eliminarán las imágenes en caché. Se volverán a descargar cuando las necesites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpiar',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await CachedNetworkImage.evictFromCache('');
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Caché de imágenes limpiada'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
            '¿Eliminar todo el historial de reproducción? No podrás recuperarlo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Borrar todo',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AppStorage.clearHistory();
    ref.read(historyRefreshProvider.notifier).state++;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Historial borrado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    final router = GoRouter.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
            '¿Seguro que quieres cerrar sesión? Perderás el acceso al contenido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(serverConfigProvider.notifier).disconnect().then((_) {
                if (mounted) router.go('/setup');
              });
            },
            child: Text('Cerrar sesión',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Info tile (read-only) ─────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
          Flexible(
            child: Text(value,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Option tile (tappable with chevron) ───────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardHover, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
            Text(value, style: AppTextStyles.bodyMedium),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Action tile (destructive action) ─────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardHover, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
