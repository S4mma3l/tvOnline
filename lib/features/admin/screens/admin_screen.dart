import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/providers/profile_provider.dart';

final _pendingPaymentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (_) => SupabaseService.getPendingPayments());

final _allUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (_) => SupabaseService.getAllUsers());

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

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
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile?['role'] != 'admin') {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 56, color: AppColors.error),
              SizedBox(height: 12),
              Text('Acceso restringido', style: AppTextStyles.headlineMedium),
              SizedBox(height: 8),
              Text('Solo administradores', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    final pendingAsync = ref.watch(_pendingPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(_pendingPaymentsProvider);
              ref.invalidate(_allUsersProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.receipt_long_rounded),
                  if (pendingAsync.valueOrNull?.isNotEmpty == true)
                    Positioned(
                      top: -4, right: -6,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(
                            color: AppColors.error, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${pendingAsync.valueOrNull?.length}',
                            style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Pagos',
            ),
            const Tab(icon: Icon(Icons.people_rounded), text: 'Usuarios'),
            const Tab(
                icon: Icon(Icons.bar_chart_rounded), text: 'Resumen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PendingPaymentsTab(adminId: profile?['id'] as String? ?? ''),
          const _UsersTab(),
          const _SummaryTab(),
        ],
      ),
    );
  }
}

// ── Pending payments ──────────────────────────────────────────────────────────

class _PendingPaymentsTab extends ConsumerWidget {
  final String adminId;
  const _PendingPaymentsTab({required this.adminId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_pendingPaymentsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(_pendingPaymentsProvider),
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 56, color: AppColors.success),
                  SizedBox(height: 12),
                  Text('Sin pagos pendientes',
                      style: AppTextStyles.headlineSmall),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PaymentCard(
              payment: payments[i],
              adminId: adminId,
              onAction: () => ref.invalidate(_pendingPaymentsProvider),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends ConsumerWidget {
  final Map<String, dynamic> payment;
  final String adminId;
  final VoidCallback onAction;

  const _PaymentCard({
    required this.payment,
    required this.adminId,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = payment['amount'];
    final currency = payment['currency'] ?? 'CRC';
    final method = payment['method'] ?? 'sinpe_movil';
    final userName = payment['full_name'] ?? 'Usuario';
    final userEmail = payment['email'] ?? '';
    final proofUrl = payment['proof_url'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardHover),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (userName as String)[0].toUpperCase(),
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: AppTextStyles.titleMedium),
                      Text(userEmail, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$currency $amount',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: AppColors.primary)),
                    Text(
                      method == 'sinpe_movil' ? 'SINPE Móvil' : 'Transferencia',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (payment['reference'] != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.tag_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('Ref: ${payment['reference']}',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],

          if (payment['notes'] != null &&
              (payment['notes'] as String).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(payment['notes'] as String,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],

          // Proof link
          if (proofUrl != null) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.image_rounded,
                  color: AppColors.secondary, size: 20),
              title: const Text('Ver comprobante',
                  style: AppTextStyles.titleSmall),
              trailing: const Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppColors.textMuted),
              onTap: () => _viewProof(context, proofUrl),
            ),
          ],

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _reject(context, ref, payment['payment_id'] as String),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _approve(context, ref, payment),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewProof(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Comprobante'),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              automaticallyImplyLeading: false,
            ),
            Image.network(url,
                errorBuilder: (_, __, ___) =>
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(Icons.image_not_supported_rounded,
                          size: 48, color: AppColors.textMuted),
                    )),
          ],
        ),
      ),
    );
  }

  void _approve(
      BuildContext context, WidgetRef ref, Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (ctx) => _ApproveDialog(
        payment: payment,
        adminId: adminId,
        onApproved: () {
          onAction();
          ref.invalidate(_allUsersProvider);
        },
      ),
    );
  }

  void _reject(
      BuildContext context, WidgetRef ref, String paymentId) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar pago'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            hintText: 'Ej: Comprobante ilegible',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.rejectPayment(
                paymentId: paymentId,
                reviewerId: adminId,
                adminNotes: notesCtrl.text,
              );
              onAction();
            },
            child: const Text('Rechazar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ApproveDialog extends StatefulWidget {
  final Map<String, dynamic> payment;
  final String adminId;
  final VoidCallback onApproved;

  const _ApproveDialog({
    required this.payment,
    required this.adminId,
    required this.onApproved,
  });

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  String _plan = 'Mensual';
  int _days = 30;
  bool _loading = false;

  static const _plans = {
    'Semanal': 7,
    'Mensual': 30,
    'Trimestral': 90,
    'Semestral': 180,
    'Anual': 365,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aprobar pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usuario: ${widget.payment['full_name']}',
              style: AppTextStyles.bodyMedium),
          Text(
              'Monto: ${widget.payment['currency']} ${widget.payment['amount']}',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          const Text('Plan a activar:', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _plan,
            dropdownColor: AppColors.card,
            items: _plans.keys
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text('$p (${_plans[p]} días)')))
                .toList(),
            onChanged: (v) => setState(() {
              _plan = v!;
              _days = _plans[v]!;
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  await SupabaseService.approvePayment(
                    paymentId: widget.payment['payment_id'] as String,
                    userId: widget.payment['user_id'] as String,
                    reviewerId: widget.adminId,
                    amount: (widget.payment['amount'] as num).toDouble(),
                    currency: widget.payment['currency'] as String,
                    planName: _plan,
                    durationDays: _days,
                  );
                  if (mounted) Navigator.pop(context);
                  widget.onApproved();
                },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: _loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar activación'),
        ),
      ],
    );
  }
}

// ── Users list ────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allUsersProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(_allUsersProvider),
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (users) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final u = users[i];
            final subs = u['subscriptions'] as List? ?? [];
            final activeSub = subs.isNotEmpty
                ? subs.firstWhere(
                    (s) =>
                        s['status'] == 'active' || s['status'] == 'trial',
                    orElse: () => null)
                : null;

            final endDate = activeSub != null
                ? DateTime.tryParse(activeSub['end_date'] ?? '')
                : null;
            final daysLeft = endDate != null
                ? endDate.difference(DateTime.now()).inDays
                : null;

            return ListTile(
              tileColor: AppColors.card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: CircleAvatar(
                backgroundColor: u['role'] == 'admin'
                    ? AppColors.ratingGold
                    : activeSub != null
                        ? AppColors.primary
                        : AppColors.textMuted,
                child: Text(
                  (u['full_name'] as String? ?? 'U')[0].toUpperCase(),
                  style: AppTextStyles.titleMedium,
                ),
              ),
              title: Text(u['full_name'] as String? ?? '-',
                  style: AppTextStyles.titleMedium),
              subtitle: Text(u['email'] as String? ?? '-',
                  style: AppTextStyles.bodySmall),
              trailing: daysLeft != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (daysLeft <= 3
                                ? AppColors.error
                                : AppColors.success)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$daysLeft d',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: daysLeft <= 3
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    )
                  : const Icon(Icons.block_rounded,
                      size: 18, color: AppColors.textMuted),
            );
          },
        ),
      ),
    );
  }
}

// ── Summary ───────────────────────────────────────────────────────────────────

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_allUsersProvider);
    final paymentsAsync = ref.watch(_pendingPaymentsProvider);

    return usersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (users) {
        final total = users.length;
        final active = users.where((u) {
          final subs = u['subscriptions'] as List? ?? [];
          return subs.any((s) =>
              s['status'] == 'active' || s['status'] == 'trial');
        }).length;
        final expiring = users.where((u) {
          final subs = u['subscriptions'] as List? ?? [];
          for (final s in subs) {
            if (s['status'] == 'active' || s['status'] == 'trial') {
              final end = DateTime.tryParse(s['end_date'] ?? '');
              if (end != null) {
                final d = end.difference(DateTime.now()).inDays;
                if (d <= 3) return true;
              }
            }
          }
          return false;
        }).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard('Total usuarios', '$total',
                        Icons.people_rounded, AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard('Activos', '$active',
                        Icons.check_circle_rounded, AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard('Vencen pronto', '$expiring',
                        Icons.warning_rounded, AppColors.warning),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      'Pagos pendientes',
                      '${paymentsAsync.valueOrNull?.length ?? 0}',
                      Icons.receipt_long_rounded,
                      AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value,
              style: AppTextStyles.displayMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
