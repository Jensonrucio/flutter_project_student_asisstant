import 'package:flutter/material.dart';

import '../../../../core/theme/glass_theme.dart';
import '../../data/auth_api.dart';
import '../../domain/auth_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.authApi,
    required this.onAuthenticated,
    super.key,
  });

  final AuthApi authApi;
  final ValueChanged<AuthSession> onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegistering = false;
  bool _isForgotPassword = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? GlassTheme.cyanAccent
        : const Color(0xFF087F73);

    return Scaffold(
      backgroundColor: GlassTheme.background(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: GlassTheme.glassContainer(
                context: context,
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 17, 54, 66),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'web/icons/SBL.png',
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isForgotPassword
                            ? 'Reset your password'
                            : _isRegistering
                            ? 'Create your account'
                            : 'Welcome To Study Buddy',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _isForgotPassword
                            ? 'We’ll email you a secure link to choose a new password.'
                            : _isRegistering
                            ? 'Start organizing your study time.'
                            : 'Sign in to continue your study space.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 26),
                      if (_isRegistering && !_isForgotPassword) ...[
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('Name', Icons.person_outline),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) return 'Enter your name';
                            if (name.length > 100) return 'Name is too long';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: _isForgotPassword
                            ? TextInputAction.done
                            : TextInputAction.next,
                        autocorrect: false,
                        onFieldSubmitted: (_) =>
                            _isForgotPassword ? _submit() : null,
                        decoration: _decoration('Email', Icons.mail_outline),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Enter your email';
                          if (email.length > 254 ||
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      if (!_isForgotPassword) const SizedBox(height: 14),
                      if (!_isForgotPassword)
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: _isRegistering
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _isRegistering ? null : _submit(),
                          decoration:
                              _decoration(
                                'Password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) return 'Enter your password';
                            if (_isRegistering && password.length < 12) {
                              return 'Use at least 12 characters';
                            }
                            if (password.length > 72) {
                              return 'Password is too long';
                            }
                            return null;
                          },
                        ),
                      if (_isRegistering && !_isForgotPassword) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: _decoration(
                            'Confirm password',
                            Icons.lock_reset_outlined,
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                      ],
                      if (!_isRegistering && !_isForgotPassword)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _isForgotPassword = true;
                                    _errorMessage = null;
                                    _infoMessage = null;
                                    _formKey.currentState?.reset();
                                  }),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(color: accentColor),
                            ),
                          ),
                        ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFFF5B68)
                                      .withValues(alpha: 0.12)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFFF5B68)
                                        .withValues(alpha: 0.4)
                                  : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFFFB7BD)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                      if (_infoMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? GlassTheme.cyanAccent.withValues(alpha: 0.1)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? GlassTheme.cyanAccent.withValues(
                                      alpha: 0.35,
                                    )
                                  : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Text(
                            _infoMessage!,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF9DF0E5)
                                  : const Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isForgotPassword
                                      ? 'Send reset link'
                                      : _isRegistering
                                      ? 'Create account'
                                      : 'Sign in',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() {
                                if (_isForgotPassword) {
                                  _isForgotPassword = false;
                                } else {
                                  _isRegistering = !_isRegistering;
                                }
                                _errorMessage = null;
                                _infoMessage = null;
                                _formKey.currentState?.reset();
                              }),
                        child: Text(
                          _isForgotPassword
                              ? 'Back to sign in'
                              : _isRegistering
                              ? 'Sign in'
                              : 'Create an account',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    prefixIcon: Icon(
      icon,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.045)
        : const Color.fromARGB(255, 57, 72, 94),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.outlineVariant
            : const Color(0xFFCBD5E1),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.outlineVariant
            : const Color.fromARGB(255, 67, 116, 177),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? GlassTheme.cyanAccent
            : const Color(0xFF087F73),
        width: 1.6,
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      if (_isForgotPassword) {
        final message = await widget.authApi.requestPasswordReset(
          email: _emailController.text.trim(),
        );
        if (mounted) setState(() => _infoMessage = message);
        return;
      }
      final session = _isRegistering
          ? await widget.authApi.register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await widget.authApi.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      if (mounted) widget.onAuthenticated(session);
    } on AuthApiException catch (exception) {
      if (mounted) setState(() => _errorMessage = exception.message);
    } on Object {
      if (mounted) {
        setState(() => _errorMessage = 'Sign in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
