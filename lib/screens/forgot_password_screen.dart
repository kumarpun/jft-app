import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Requests a reset email. The emailed link opens the web reset page.
class ForgotPasswordScreen extends StatefulWidget {
  final AuthController auth;
  final String email;
  const ForgotPasswordScreen({super.key, required this.auth, this.email = ''});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.email.contains('@') ? widget.email : '');
  bool _busy = false;
  String? _sent;

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!email.contains('@')) return toast(context, 'Enter a valid email', error: true);
    setState(() => _busy = true);
    try {
      final msg = await widget.auth.repo.forgotPassword(email);
      if (mounted) setState(() => _sent = msg);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AuthPage(
      back: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FadeSlide(child: BrandLogo(size: 64)),
        const SizedBox(height: 28),
        if (_sent != null) ...[
          Icon(Icons.mark_email_read_outlined, size: 44, color: primary),
          const SizedBox(height: 14),
          Text('Check your email', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: context.pal.text)),
          const SizedBox(height: 10),
          Text(_sent!, style: TextStyle(color: context.pal.text, fontSize: 14.5, height: 1.4)),
          const SizedBox(height: 8),
          Text('Open the link in the email to choose a new password, then sign in here.', style: TextStyle(color: context.pal.muted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 36),
          Align(alignment: Alignment.centerRight, child: AuthPillButton(label: 'Back to login', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.maybePop(context))),
        ] else ...[
          Text('Forgot password', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: context.pal.text)),
          const SizedBox(height: 10),
          Text("Enter your account email and we'll send you a reset link.", style: TextStyle(color: context.pal.muted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 28),
          AuthField(controller: _email, label: 'Email address', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email]),
          const SizedBox(height: 36),
          Align(alignment: Alignment.centerRight, child: AuthPillButton(label: 'Send link', icon: Icons.send_rounded, busy: _busy, onPressed: _busy ? null : _submit)),
        ],
      ]),
    );
  }
}
