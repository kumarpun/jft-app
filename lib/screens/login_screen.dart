import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController auth;
  const LoginScreen({super.key, required this.auth});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController(), _pw = TextEditingController();
  bool _busy = false, _hide = true;

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
    return Scaffold(
      body: CrimsonBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Center(child: FadeSlide(child: BrandLogo(size: 104))),
                  const SizedBox(height: 18),
                  const Text('JFT Sensei',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text('Master JFT-Basic with confidence',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .8), letterSpacing: .3)),
                  const SizedBox(height: 28),
                  FadeSlide(child: AuthCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Welcome back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
                      const SizedBox(height: 4),
                      const Text('Sign in to continue', style: TextStyle(color: AppColors.muted)),
                      if (widget.auth.notice != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                          child: Text(widget.auth.notice!, style: const TextStyle(color: AppColors.primary)),
                        ),
                      ],
                      const SizedBox(height: 22),
                      TextField(
                          controller: _id,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _pw,
                        obscureText: _hide,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _hide = !_hide)),
                        ),
                      ),
                      const SizedBox(height: 22),
                      GradientButton(label: 'SIGN IN', busy: _busy, onPressed: _busy ? null : _submit),
                    ]),
                  )),
                  const SizedBox(height: 14),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen(auth: widget.auth))),
                    child: const Text("New here? Create an account", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
