import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ChangePasswordScreen extends StatefulWidget {
  final AuthController auth;
  const ChangePasswordScreen({super.key, required this.auth});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _cur = TextEditingController(), _new = TextEditingController(), _confirm = TextEditingController();
  bool _busy = false, _hideCur = true, _hideNew = true;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController c, String label, bool hide, VoidCallback toggle, {ValueChanged<String>? onSubmitted}) => TextField(
        controller: c,
        obscureText: hide,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
              icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: toggle),
        ),
      );

  Future<void> _submit() async {
    if (_cur.text.isEmpty || _new.text.isEmpty) return toast(context, 'Fill in all fields', error: true);
    if (_new.text != _confirm.text) return toast(context, 'New passwords do not match', error: true);
    setState(() => _busy = true);
    try {
      await widget.auth.repo.changePassword(_cur.text, _new.text);
      if (!mounted) return;
      toast(context, 'Password changed. Other devices were signed out.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar(context, 'Change password'),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Other devices will be signed out after you change your password.',
                    style: TextStyle(color: context.pal.muted)),
                const SizedBox(height: 18),
                _field(_cur, 'Current password', _hideCur, () => setState(() => _hideCur = !_hideCur)),
                const SizedBox(height: 14),
                _field(_new, 'New password', _hideNew, () => setState(() => _hideNew = !_hideNew)),
                const SizedBox(height: 14),
                _field(_confirm, 'Confirm new password', _hideNew, () => setState(() => _hideNew = !_hideNew),
                    onSubmitted: (_) => _submit()),
                const SizedBox(height: 22),
                GradientButton(label: 'UPDATE PASSWORD', busy: _busy, onPressed: _busy ? null : _submit),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
