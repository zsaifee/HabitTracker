// lib/login.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_style.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authSvc = AuthService();

  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  String? _err;
  String? _info; // success/info message

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
      _info = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final pw = _pwCtrl.text;

      if (email.isEmpty || pw.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password required.',
        );
      }

      if (_isLogin) {
        await _authSvc.signIn(email, pw);

        if (!mounted) return;
        FocusScope.of(context).unfocus();
      } else {
        await _authSvc.signUp(email, pw);

        if (!mounted) return;
        FocusScope.of(context).unfocus();

        setState(() {
          _info = 'Verification email sent to $email. Check inbox, then log in.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent to $email.')),
        );

        return; // stop here so we don’t “continue” as logged-in
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _err = _prettyAuthError(e));
    } catch (_) {
      setState(() => _err = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    setState(() {
      _err = null;
      _info = null;
      _busy = true;
    });

    try {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        setState(() => _err = 'Type your email first, then tap “Forgot password?”');
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _err = _prettyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _err = null;
      _info = null;
      _busy = true;
    });

    try {
      final email = _emailCtrl.text.trim();
      final pw = _pwCtrl.text;

      if (email.isEmpty || pw.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Type your email and password first.',
        );
      }

      await _authSvc.resendVerificationEmailWithPassword(email: email, password: pw);

      if (!mounted) return;
      setState(() => _info = 'Verification email resent to $email.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email resent to $email.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _err = _prettyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _prettyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email looks invalid.';
      case 'user-disabled':
        return 'This account was disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'That email already has an account. Try logging in.';
      case 'weak-password':
        return 'Password is too weak (try 6+ characters).';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-input':
        return e.message ?? 'Missing email/password.';
      case 'email-not-verified':
        return 'Please verify your email (check inbox/spam) before logging in.';
      case 'no-user':
        return 'No signed-in user.';
      case 'already-verified':
        return 'That email is already verified. Try logging in.';
      default:
        return e.message ?? 'Auth error: ${e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(isLogin: _isLogin),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min, // nice inside scroll
                        children: [
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pwCtrl,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _busy ? null : _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ✅ fixed: no Expanded inside scroll view
                          Row(
                            children: [
                              if (_isLogin)
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: _busy ? null : _forgotPassword,
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),
                              const SizedBox(width: 8),
                              _ModeChip(
                                isLogin: _isLogin,
                                onTap: _busy
                                    ? null
                                    : () => setState(() {
                                          _isLogin = !_isLogin;
                                          _err = null;
                                          _info = null;
                                        }),
                              ),
                            ],
                          ),

                          if (_info != null) ...[
                            const SizedBox(height: 6),
                            _InfoPill(message: _info!),
                          ],

                          if (_err != null) ...[
                            const SizedBox(height: 6),
                            _ErrorPill(message: _err!),
                          ],

                          const SizedBox(height: 12),

                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_isLogin ? 'Log in' : 'Create account'),
                          ),

                          if (!_isLogin) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _busy ? null : _resendVerification,
                              child: const Text('Resend verification email'),
                            ),
                          ],

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tip: use the same email/password on web + phone so your “habit bank” stays synced.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
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
}

class _Header extends StatelessWidget {
  final bool isLogin;
  const _Header({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 76,
          width: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppStyle.headerGradient(context),
          ),
          child: const Icon(Icons.savings_outlined, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          'pockt change',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          isLogin ? 'Log in to keep your streaks safe ' : 'Create an account to start saving points ',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final bool isLogin;
  final VoidCallback? onTap;

  const _ModeChip({required this.isLogin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = isLogin ? 'Need an account?' : 'Have an account?';
    final action = isLogin ? 'Sign up' : 'Log in';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(width: 6),
            Text(
              action,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppStyle.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String message;
  const _InfoPill({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB6DAFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_read_outlined, color: Color(0xFF0B57D0)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B57D0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  final String message;
  const _ErrorPill({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC6C6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
