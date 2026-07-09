import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class _SignInLayout {
  const _SignInLayout({
    required this.cardWidth,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.logoHeight,
    required this.titleSize,
    required this.subtitleSize,
    required this.borderRadius,
    required this.fieldSpacing,
    required this.buttonHeight,
  });

  factory _SignInLayout.fromWidth(double width) {
    if (width < 600) {
      return _SignInLayout(
        cardWidth: width - 40,
        horizontalPadding: 20,
        verticalPadding: 28,
        logoHeight: 80,
        titleSize: 24,
        subtitleSize: 13,
        borderRadius: 16,
        fieldSpacing: 14,
        buttonHeight: 48,
      );
    }

    final progress = ((width - 600) / 800).clamp(0.0, 1.0);

    return _SignInLayout(
      cardWidth: 440 + (200 * progress),
      horizontalPadding: 32 + (24 * progress),
      verticalPadding: 40 + (20 * progress),
      logoHeight: 100 + (40 * progress),
      titleSize: 28 + (8 * progress),
      subtitleSize: 14 + (2 * progress),
      borderRadius: 20 + (4 * progress),
      fieldSpacing: 16 + (4 * progress),
      buttonHeight: 52 + (6 * progress),
    );
  }

  final double cardWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final double logoHeight;
  final double titleSize;
  final double subtitleSize;
  final double borderRadius;
  final double fieldSpacing;
  final double buttonHeight;
}

class SignInCard extends StatelessWidget {
  const SignInCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isSubmitting,
    required this.logoPath,
    required this.onTogglePassword,
    required this.onRememberMeChanged,
    required this.onSignIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isSubmitting;
  final String logoPath;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onSignIn;

  InputDecoration _inputDecoration(double borderRadius) {
    return InputDecoration(
      filled: true,
      fillColor: AppConstants.inputFillColor,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIconColor: AppConstants.primary,
      suffixIconColor: AppConstants.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: AppConstants.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = _SignInLayout.fromWidth(MediaQuery.sizeOf(context).width);
    final inputDecoration = _inputDecoration(layout.borderRadius - 4);

    return Align(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.cardWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primary.withValues(alpha: 0.15),
                blurRadius: 48,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: AppConstants.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(layout.borderRadius),
              side: BorderSide(
                color: AppConstants.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout.horizontalPadding,
                vertical: layout.verticalPadding,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(logoPath, height: layout.logoHeight),
                    SizedBox(height: layout.fieldSpacing + 8),
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: layout.titleSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage your admin panel.',
                      style: TextStyle(
                        fontSize: layout.subtitleSize,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    SizedBox(height: layout.fieldSpacing + 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppConstants.primary,
                      decoration: inputDecoration.copyWith(
                        labelText: 'E-Mail',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: layout.fieldSpacing),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onSignIn(),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppConstants.primary,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: onTogglePassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: layout.fieldSpacing),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: rememberMe,
                            activeColor: AppConstants.primary,
                            checkColor: Colors.black,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            onChanged: (value) =>
                                onRememberMeChanged(value ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember Me',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: layout.fieldSpacing + 8),
                    SizedBox(
                      height: layout.buttonHeight,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : onSignIn,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
