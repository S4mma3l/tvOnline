import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/profile_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final subAsync = ref.watch(activeSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded), text: 'Perfil'),
            Tab(icon: Icon(Icons.credit_card_rounded), text: 'Suscripción'),
            Tab(icon: Icon(Icons.upload_rounded), text: 'Pagar'),
          ],
        ),
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(userProfileProvider)),
        data: (profile) {
          if (profile == null) {
            return _RegisterForm(onRegistered: () => ref.invalidate(userProfileProvider));
          }
          if (_nameCtrl.text.isEmpty) {
            _nameCtrl.text = profile['full_name'] ?? '';
            _emailCtrl.text = profile['email'] ?? '';
            _phoneCtrl.text = profile['phone'] ?? '';
          }
          return TabBarView(
            controller: _tab,
            children: [
              _ProfileTab(profile: profile, nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl, ref: ref),
              _SubscriptionTab(subAsync: subAsync),
              _PaymentTab(userId: profile['id'] as String, ref: ref),
            ],
          );
        },
      ),
    );
  }
}

// ── Tab 1: Profile info ──────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic> profile;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final WidgetRef ref;

  const _ProfileTab({
    required this.profile,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile['role'] == 'admin';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              child: Text(
                (profile['full_name'] as String? ?? 'U')[0].toUpperCase(),
                style: AppTextStyles.headlineLarge,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isAdmin)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ratingGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.ratingGold),
                ),
                child: const Text('ADMINISTRADOR',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ratingGold,
                        letterSpacing: 1.2)),
              ),
            ),
          const SizedBox(height: 28),

          _FieldLabel('Nombre completo'),
          const SizedBox(height: 8),
          TextField(
            controller: nameCtrl,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Correo electrónico'),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: profile['email'] ?? ''),
            enabled: false,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Teléfono (SINPE Móvil)'),
          const SizedBox(height: 8),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_rounded, size: 20),
              hintText: '8888-8888',
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await ref.read(userProfileProvider.notifier).updateProfile({
                  'full_name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil actualizado'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Guardar cambios'),
            ),
          ),

          if (isAdmin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed('/admin'),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                label: const Text('Panel de administración'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab 2: Subscription status ───────────────────────────────────────────────

class _SubscriptionTab extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> subAsync;
  const _SubscriptionTab({required this.subAsync});

  @override
  Widget build(BuildContext context) {
    return subAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (sub) {
        if (sub == null) {
          return const _NoSubscription();
        }
        final endDate = DateTime.tryParse(sub['end_date'] ?? '');
        final daysLeft = endDate != null
            ? endDate.difference(DateTime.now()).inDays
            : 0;
        final status = sub['status'] as String? ?? 'unknown';
        final isActive = status == 'active' || status == 'trial';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [AppColors.primary, AppColors.primaryDark]
                        : [AppColors.card, AppColors.surface],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isActive ? 'Suscripción activa' : 'Suscripción vencida',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sub['plan_name'] ?? 'Plan mensual',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Days remaining meter
              if (isActive) ...[
                _StatRow('Días restantes',
                    '$daysLeft día${daysLeft == 1 ? '' : 's'}',
                    icon: Icons.calendar_today_rounded,
                    color: daysLeft <= 3 ? AppColors.error : AppColors.success),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: daysLeft > 30 ? 1.0 : daysLeft / 30,
                  minHeight: 6,
                  backgroundColor: AppColors.card,
                  valueColor: AlwaysStoppedAnimation(
                      daysLeft <= 3 ? AppColors.error : AppColors.primary),
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 24),
              ],

              _StatRow('Plan', sub['plan_name'] ?? '-',
                  icon: Icons.star_rounded),
              const Divider(height: 24),
              _StatRow('Inicio',
                  _formatDate(sub['start_date']),
                  icon: Icons.play_arrow_rounded),
              const Divider(height: 24),
              _StatRow('Vencimiento',
                  _formatDate(sub['end_date']),
                  icon: Icons.event_busy_rounded,
                  color: daysLeft <= 3 ? AppColors.error : null),
              const Divider(height: 24),
              _StatRow('Precio',
                  '${sub['currency'] ?? 'CRC'} ${sub['plan_price'] ?? '-'}',
                  icon: Icons.payments_rounded),

              if (daysLeft <= 3 && isActive) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          daysLeft == 0
                              ? 'Tu suscripción vence HOY. Realiza tu pago para continuar.'
                              : 'Tu suscripción vence en $daysLeft día${daysLeft == 1 ? '' : 's'}.',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(dynamic d) {
    if (d == null) return '-';
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d.toString();
    }
  }
}

// ── Tab 3: Submit payment ────────────────────────────────────────────────────

class _PaymentTab extends ConsumerStatefulWidget {
  final String userId;
  final WidgetRef ref;
  const _PaymentTab({required this.userId, required this.ref});

  @override
  ConsumerState<_PaymentTab> createState() => _PaymentTabState();
}

class _PaymentTabState extends ConsumerState<_PaymentTab> {
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = 'sinpe_movil';
  String _currency = 'CRC';
  dynamic _proofFile;
  String? _proofFilename;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result != null) {
        setState(() {
          _proofFile = result.files.first.bytes;
          _proofFilename = result.files.first.name;
        });
      }
    } catch (_) {
      // Try image picker as fallback
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img != null) {
        setState(() {
          _proofFile = File(img.path);
          _proofFilename = img.name;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el monto y adjunta el comprobante'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await SupabaseService.submitPayment(
        userId: widget.userId,
        amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        currency: _currency,
        method: _method,
        reference: _referenceCtrl.text,
        notes: _notesCtrl.text,
        proofBytes:
            _proofFile is List<int> ? Uint8List.fromList(_proofFile) : null,
        proofFile: _proofFile is File ? _proofFile : null,
        proofFilename: _proofFilename,
      );

      if (mounted) {
        setState(() {
          _amountCtrl.clear();
          _referenceCtrl.clear();
          _notesCtrl.clear();
          _proofFile = null;
          _proofFilename = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Comprobante enviado! El admin lo revisará pronto.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(paymentHistoryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardHover),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Datos para el pago',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _PaymentInfoRow(
                    Icons.phone_android_rounded, 'SINPE Móvil', '8888-8888'),
                const SizedBox(height: 8),
                _PaymentInfoRow(Icons.account_balance_rounded,
                    'Transferencia', 'CR21 0152 0000 1234 5678 90'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _FieldLabel('Método de pago'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'sinpe_movil',
                  label: Text('SINPE Móvil'),
                  icon: Icon(Icons.phone_android_rounded, size: 16)),
              ButtonSegment(
                  value: 'bank_transfer',
                  label: Text('Transferencia'),
                  icon: Icon(Icons.account_balance_rounded, size: 16)),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected))
                  return AppColors.primary;
                return AppColors.card;
              }),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Monto'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: '0.00'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Moneda'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _currency,
                      dropdownColor: AppColors.card,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14)),
                      items: const [
                        DropdownMenuItem(value: 'CRC', child: Text('CRC ₡')),
                        DropdownMenuItem(value: 'USD', child: Text('USD \$')),
                      ],
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _FieldLabel('Número de referencia (opcional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceCtrl,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ej: 202605180001',
              prefixIcon: Icon(Icons.tag_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Notas (opcional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ej: Pago plan mensual mayo 2026',
            ),
          ),
          const SizedBox(height: 20),

          // Proof uploader
          _FieldLabel('Comprobante de pago *'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proofFile != null
                      ? AppColors.success
                      : AppColors.textMuted,
                  width: _proofFile != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _proofFile != null
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 36,
                    color: _proofFile != null
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _proofFile != null
                        ? _proofFilename ?? 'Archivo seleccionado'
                        : 'Toca para adjuntar foto o PDF',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _proofFile != null
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                  if (_proofFile == null)
                    const Text('JPG, PNG o PDF — máx 10MB',
                        style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(_loading ? 'Enviando...' : 'Enviar comprobante'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Register form (first time) ───────────────────────────────────────────────

class _RegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onRegistered;
  const _RegisterForm({required this.onRegistered});

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registra tu cuenta', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Para gestionar tu suscripción y realizar pagos necesitamos tus datos de contacto.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_rounded, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (SINPE Móvil)',
                prefixIcon: Icon(Icons.phone_rounded, size: 20),
                hintText: '8888-8888',
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (!_form.currentState!.validate()) return;
                        setState(() => _loading = true);
                        try {
                          await ref
                              .read(userProfileProvider.notifier)
                              .ensureRegistered(
                                email: _emailCtrl.text,
                                fullName: _nameCtrl.text,
                                phone: _phoneCtrl.text,
                              );
                          widget.onRegistered();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.titleSmall
          .copyWith(color: AppColors.textSecondary));
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatRow(this.label, this.value,
      {required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Text(value,
            style: AppTextStyles.titleMedium
                .copyWith(color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  final IconData icon;
  final String method;
  final String value;
  const _PaymentInfoRow(this.icon, this.method, this.value);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$method:', style: AppTextStyles.titleSmall
              .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(value,
                style: AppTextStyles.titleMedium,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

class _NoSubscription extends StatelessWidget {
  const _NoSubscription();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.subscriptions_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('Sin suscripción activa',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          const Text('Realiza tu pago en la pestaña "Pagar"',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('Error al cargar el perfil',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

