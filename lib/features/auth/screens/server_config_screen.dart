import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(serverConfigProvider.notifier).connect(
          url: _urlCtrl.text,
          username: _userCtrl.text,
          password: _passCtrl.text,
        );

    if (mounted) {
      final state = ref.read(serverConfigProvider);
      state.whenOrNull(
        data: (cfg) {
          if (cfg != null) context.go('/');
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(serverConfigProvider).isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF0D0D0D),
              Color(0xFF150A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildForm(),
                        const SizedBox(height: 28),
                        _buildConnectButton(isLoading),
                        const SizedBox(height: 32),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha:0.4),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 44),
        ),
        const SizedBox(height: 20),
        const Text('tvOnline', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        const Text(
          'Tu plataforma de streaming premium',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Servidor'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'https://servidor.com:8080',
              prefixIcon: const Icon(Icons.dns_rounded, size: 20),
              prefixIconColor: AppColors.textMuted,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa la URL del servidor';
              if (!v.trim().startsWith('http')) {
                return 'La URL debe comenzar con http:// o https://';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _label('Usuario'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userCtrl,
            keyboardType: TextInputType.text,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Tu nombre de usuario',
              prefixIcon: Icon(Icons.person_rounded, size: 20),
              prefixIconColor: AppColors.textMuted,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Ingresa tu usuario'
                : null,
          ),
          const SizedBox(height: 18),
          _label('Contraseña'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tu contraseña',
              prefixIcon: const Icon(Icons.lock_rounded, size: 20),
              prefixIconColor: AppColors.textMuted,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Ingresa tu contraseña'
                : null,
            onFieldSubmitted: (_) => _connect(),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: AppTextStyles.titleSmall
            .copyWith(color: AppColors.textSecondary));
  }

  Widget _buildConnectButton(bool isLoading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        gradient: isLoading ? null : AppColors.primaryGradient,
        color: isLoading ? AppColors.card : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha:0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _connect,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Conectar', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha:0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardHover),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tus credenciales se almacenan localmente y nunca salen de tu dispositivo.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
