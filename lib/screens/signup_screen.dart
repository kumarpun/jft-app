import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../widgets/ui.dart';

class SignupScreen extends StatefulWidget {
  final AuthController auth;
  const SignupScreen({super.key, required this.auth});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController();
  bool _busy = false;

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
    return Scaffold(
      body: CrimsonBackdrop(
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.maybePop(context)),
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
                      const Text('Create account',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 22),
                      FadeSlide(child: AuthCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
                          const SizedBox(height: 14),
                          TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
                          const SizedBox(height: 14),
                          TextField(
                              controller: _pw,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
                          const SizedBox(height: 22),
                          GradientButton(label: 'SIGN UP', busy: _busy, onPressed: _busy ? null : _submit),
                        ]),
                      )),
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
