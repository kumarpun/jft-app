import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class SignupScreen extends StatefulWidget {
  final AuthController auth;
  const SignupScreen({super.key, required this.auth});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController();
  bool _busy = false, _hide = true, _gBusy = false;

  Future<void> _google() async {
    setState(() => _gBusy = true);
    try {
      if (await widget.auth.googleLogin() && mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _gBusy = false);
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _pw.text.isEmpty) {
      return toast(context, 'Fill in all fields', error: true);
    }
    setState(() => _busy = true);
    try {
      await widget.auth.signup(_name.text.trim(), _email.text.trim(), _pw.text);
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      back: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FadeSlide(child: BrandLogo(size: 64)),
        const SizedBox(height: 28),
        Text('Create account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: context.pal.text)),
        const SizedBox(height: 28),
        AuthField(controller: _name, label: 'Full name', icon: Icons.person_outline_rounded, capitalization: TextCapitalization.words),
        const SizedBox(height: 16),
        AuthField(controller: _email, label: 'Email address', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
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
        const SizedBox(height: 36),
        Align(alignment: Alignment.centerRight, child: AuthPillButton(label: 'Sign up', icon: Icons.arrow_forward_rounded, busy: _busy, onPressed: _busy ? null : _submit)),
        const SizedBox(height: 32),
        GoogleAuthButton(label: 'Sign up with Google', busy: _gBusy, onPressed: _google),
        const SizedBox(height: 24),
        AuthSwitchLink(text: 'Already have an account?', action: 'Sign In', onTap: () => Navigator.maybePop(context)),
      ]),
    );
  }
}
