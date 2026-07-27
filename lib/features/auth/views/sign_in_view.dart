import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:emam_admin_web_app/features/auth/views/widgets/sign_in_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  static const _defaultEmail = 'safaandsafa4@gmail.com';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: _defaultEmail);
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;

  void _clearError() {
    ref.read(signInErrorProvider.notifier).clear();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tokenStorage = ref.read(tokenStorageProvider);
      setState(() {
        _rememberMe = tokenStorage.rememberMe;
        if (_rememberMe && tokenStorage.savedEmail != null) {
          _emailController.text = tokenStorage.savedEmail!;
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await ref.read(authProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(signInErrorProvider);

    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SignInBackdrop(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
                vertical: 24,
              ),
              child: SignInCard(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                rememberMe: _rememberMe,
                isSubmitting: _isSubmitting,
                errorMessage: errorMessage,
                logoPath: AppConstants.emamLogo,
                onTogglePassword: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                onRememberMeChanged: (value) {
                  setState(() => _rememberMe = value);
                },
                onSignIn: _onSignIn,
                onFieldChanged: _clearError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative, non-interactive glow behind the sign-in card. Purely visual —
/// ignored for hit-testing so it never intercepts input.
class _SignInBackdrop extends StatelessWidget {
  const _SignInBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -160,
            right: -120,
            child: _glowCircle(420, AppConstants.primary.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -180,
            left: -140,
            child: _glowCircle(460, AppConstants.primary.withValues(alpha: 0.06)),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
