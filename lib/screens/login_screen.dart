import 'dart:async';
import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController auth;
  const LoginScreen({super.key, required this.auth});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController(), _pw = TextEditingController();
  bool _busy = false, _hide = true, _gBusy = false;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    // Forced-logout notice disappears after 7 seconds.
    if (widget.auth.notice != null) {
      _noticeTimer = Timer(const Duration(seconds: 7), () {
        widget.auth.notice = null;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  Future<void> _google() async {
    setState(() => _gBusy = true);
    try {
      await widget.auth.googleLogin();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _gBusy = false);
    }
  }

  Future<void> _submit() async {
    if (_id.text.trim().isEmpty || _pw.text.isEmpty) return toast(context, 'Enter email and password', error: true);
    setState(() => _busy = true);
    try {
      await widget.auth.login(_id.text.trim(), _pw.text);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AuthPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FadeSlide(child: BrandLogo(size: 78)),
        const SizedBox(height: 34),
        Text('Login', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: context.pal.text)),
        if (widget.auth.notice != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.pal.primarySoft, borderRadius: BorderRadius.circular(16)),
            child: Text(widget.auth.notice!, style: TextStyle(color: primary)),
          ),
        ],
        const SizedBox(height: 28),
        AuthField(controller: _id, label: 'Email address', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email]),
        const SizedBox(height: 16),
        AuthField(
          controller: _pw,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: _hide,
          suffix: IconButton(
              icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19),
              color: context.pal.muted,
              onPressed: () => setState(() => _hide = !_hide)),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen(auth: widget.auth, email: _id.text.trim()))),
            child: Padding(
              padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
              child: Text('Forgot Password?', style: TextStyle(color: primary, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Align(alignment: Alignment.centerRight, child: AuthPillButton(label: 'Login', busy: _busy, onPressed: _busy ? null : _submit)),
        const SizedBox(height: 32),
        GoogleAuthButton(busy: _gBusy, onPressed: _google),
        const SizedBox(height: 24),
        AuthSwitchLink(
          text: "Don't have an account?",
          action: 'Sign Up',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen(auth: widget.auth))),
        ),
      ]),
    );
  }
}
