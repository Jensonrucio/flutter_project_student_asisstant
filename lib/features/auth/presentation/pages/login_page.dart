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
    final textColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFFAAB4C3)
        : const Color(0xFF64748B);
    final accentColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: isDark
          ? const Color.fromARGB(255, 4, 19, 44)
          : GlassTheme.background(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6558F5), Color(0xFF3785F6)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF536CF4)
                                  .withValues(alpha: isDark ? 0.48 : 0.28),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Transform.scale(
                              scale: 1.8,
                              child: Image.asset(
                                'web/icons/SBL.png',
                                width: 58,
                                height: 58,
                                fit: BoxFit.contain,
                                semanticLabel: 'Study Buddy logo',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _isForgotPassword
                          ? 'Reset Password'
                          : _isRegistering
                          ? 'Create Account'
                          : 'Welcome To Study Buddy!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isForgotPassword
                          ? 'We’ll email you a secure link to choose a new password.'
                          : _isRegistering
                          ? 'Start organizing your study time.'
                          : 'Sign in to track your study journey',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              (isDark ? Colors.white : const Color(0xFF1E293B))
                                  .withValues(alpha: isDark ? 0.035 : 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isRegistering && !_isForgotPassword) ...[
                            _fieldLabel('Name', mutedTextColor),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                'Enter your name',
                                Icons.person_outline,
                              ),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) return 'Enter your name';
                                if (name.length > 100) {
                                  return 'Name is too long';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          _fieldLabel('Email', mutedTextColor),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: _isForgotPassword
                                ? TextInputAction.done
                                : TextInputAction.next,
                            autocorrect: false,
                            onFieldSubmitted: (_) =>
                                _isForgotPassword ? _submit() : null,
                            decoration: _decoration(
                              'Enter your email',
                              Icons.mail_outline,
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'Email is required';
                              if (email.length > 254 ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(email)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          if (!_isForgotPassword) ...[
                            const SizedBox(height: 14),
                            _fieldLabel('Password', mutedTextColor),
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
                                    'Enter your password',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: mutedTextColor,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.isEmpty) {
                                  return 'Password is required';
                                }
                                if (_isRegistering && password.length < 12) {
                                  return 'Use at least 12 characters';
                                }
                                if (password.length > 72) {
                                  return 'Password is too long';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (_isRegistering && !_isForgotPassword) ...[
                            const SizedBox(height: 14),
                            _fieldLabel('Confirm password', mutedTextColor),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: _decoration(
                                'Re-enter your password',
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
                              child: SizedBox(
                                height: 36,
                                child: TextButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => setState(() {
                                          _isForgotPassword = true;
                                          _errorMessage = null;
                                          _infoMessage = null;
                                          _formKey.currentState?.reset();
                                        }),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    foregroundColor: accentColor,
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                            ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _messageBox(
                              _errorMessage!,
                              isDark
                                  ? const Color(0xFFFFB7BD)
                                  : const Color(0xFF991B1B),
                              const Color(0xFFFF5B68),
                            ),
                          ],
                          if (_infoMessage != null) ...[
                            const SizedBox(height: 12),
                            _messageBox(
                              _infoMessage!,
                              isDark
                                  ? const Color(0xFF9DF0E5)
                                  : const Color(0xFF065F46),
                              GlassTheme.cyanAccent,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            _isForgotPassword
                                ? 'Remember your password?'
                                : _isRegistering
                                ? 'Already have an account?'
                                : 'Don’t have an account?',
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
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
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(
                              _isForgotPassword || _isRegistering
                                  ? 'Sign In'
                                  : 'Sign Up',
                            ),
                          ),
                        ],
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

  Widget _fieldLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );

  Widget _messageBox(String message, Color textColor, Color borderColor) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: borderColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        ),
        child: Text(message, style: TextStyle(color: textColor)),
      );

  Widget _buildSubmitButton() {
    final label = _isForgotPassword
        ? 'Send reset link'
        : _isRegistering
        ? 'Create account'
        : 'Login';

    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6558F5), Color(0xFF3785F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF536CF4).withValues(alpha: 0.24),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSubmitting ? null : _submit,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isForgotPassword) const SizedBox(width: 5),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8793A5)
          : const Color(0xFF94A3B8),
      fontSize: 12,
    ),
    prefixIcon: Icon(
      icon,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9AA6B7)
          : const Color(0xFF64748B),
      size: 18,
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 40),
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF818CF8)
            : const Color(0xFF4F46E5),
        width: 1.4,
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
