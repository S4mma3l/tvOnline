import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/profile_model.dart';
import '../../home/providers/home_provider.dart';
import '../providers/profiles_provider.dart';

const int _maxProfiles = 5;

class ProfileSelectorScreen extends ConsumerWidget {
  const ProfileSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('tv',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(width: 8),
                const Text('Online',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 48),
            Text('¿Quién está viendo?', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 40),

            // Profile grid
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 28,
                  alignment: WrapAlignment.center,
                  children: [
                    ...profiles.map((p) => _ProfileCard(
                          profile: p,
                          canDelete: profiles.length > 1,
                          onTap: () => _selectProfile(context, ref, p),
                          onEdit: () => _showEditDialog(context, ref, p, profiles.length),
                          onDelete: () => _confirmDelete(context, ref, p),
                        )),
                    if (profiles.length < _maxProfiles)
                      _AddProfileCard(
                        onTap: () => _showCreateDialog(context, ref, profiles.length),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _selectProfile(BuildContext context, WidgetRef ref, ProfileModel profile) {
    AppStorage.setActiveProfile(profile.id);
    ref.read(profileSelectedProvider.notifier).state = true;
    ref.read(profilesRefreshProvider.notifier).state++;
    // Rebuild history/continue watching for this profile
    ref.read(historyRefreshProvider.notifier).state++;
    context.go('/');
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, int profileCount) {
    showDialog(
      context: context,
      builder: (_) => ProfileFormDialog(
        title: 'Nuevo perfil',
        initialColorIndex: profileCount % ProfileModel.avatarColors.length,
        onSave: (name, colorIndex) async {
          final id = 'profile_${DateTime.now().millisecondsSinceEpoch}';
          await AppStorage.saveProfile(
              ProfileModel(id: id, name: name, colorIndex: colorIndex));
          ref.read(profilesRefreshProvider.notifier).state++;
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ProfileModel profile, int count) {
    showDialog(
      context: context,
      builder: (_) => ProfileFormDialog(
        title: 'Editar perfil',
        initialName: profile.name,
        initialColorIndex: profile.colorIndex,
        onSave: (name, colorIndex) async {
          await AppStorage.saveProfile(profile.copyWith(name: name, colorIndex: colorIndex));
          ref.read(profilesRefreshProvider.notifier).state++;
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProfileModel profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar "${profile.name}"'),
        content: const Text(
            'Se eliminará el historial, lista y progreso de este perfil. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStorage.deleteProfile(profile.id);
              ref.read(profilesRefreshProvider.notifier).state++;
            },
            child: Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final ProfileModel profile;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: profile.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  profile.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              profile.name,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: profile.color,
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(profile.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(profile.name, style: AppTextStyles.headlineSmall),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar nombre y color'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            if (canDelete)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: AppColors.error),
                title: Text('Eliminar perfil',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Add profile card ──────────────────────────────────────────────────────────

class _AddProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Text('Agregar',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Profile create/edit dialog ────────────────────────────────────────────────

class ProfileFormDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final int initialColorIndex;
  final Future<void> Function(String name, int colorIndex) onSave;

  const ProfileFormDialog({
    super.key,
    required this.title,
    this.initialName,
    required this.initialColorIndex,
    required this.onSave,
  });

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  late TextEditingController _nameCtrl;
  late int _colorIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _colorIndex = widget.initialColorIndex;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              counterText: '',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          const Text('Color', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(ProfileModel.avatarColors.length, (i) {
              final selected = i == _colorIndex;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(ProfileModel.avatarColors[i]),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: selected
                        ? [BoxShadow(
                            color: Color(ProfileModel.avatarColors[i])
                                .withValues(alpha: 0.6),
                            blurRadius: 8)]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  setState(() => _saving = true);
                  await widget.onSave(name, _colorIndex);
                  if (context.mounted) Navigator.pop(context);
                },
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
