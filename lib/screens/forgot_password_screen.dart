import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
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
    return Scaffold(
      body: CrimsonBackdrop(
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.maybePop(context)),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Center(child: BrandLogo(size: 72)),
                      const SizedBox(height: 14),
                      const Text('Forgot password',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 22),
                      FadeSlide(
                        child: AuthCard(
                          child: _sent != null
                              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  const Icon(Icons.mark_email_read_outlined, size: 48),
                                  const SizedBox(height: 12),
                                  Text(_sent!, textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  const Text('Open the link in the email to choose a new password, then sign in here.',
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 20),
                                  GradientButton(label: 'BACK TO SIGN IN', onPressed: () => Navigator.maybePop(context)),
                                ])
                              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  const Text("Enter your account email and we'll send you a reset link."),
                                  const SizedBox(height: 18),
                                  TextField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    onSubmitted: (_) => _submit(),
                                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                                  ),
                                  const SizedBox(height: 22),
                                  GradientButton(label: 'SEND RESET LINK', busy: _busy, onPressed: _busy ? null : _submit),
                                ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
