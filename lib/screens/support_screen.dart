import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const _supportWhatsapp = '9779714393399';

class SupportScreen extends StatelessWidget {
  final AuthController auth;
  const SupportScreen({super.key, required this.auth});

  Future<void> _wa(BuildContext c, String text) => openUrl(c, 'https://wa.me/$_supportWhatsapp?text=${Uri.encodeComponent(text)}');

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final u = auth.user;
    final who = u == null ? '' : '\n\nAccount: ${u.name} (${u.email})';
    Widget tile(IconData icon, String title, String sub, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: pal.surface,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: pal.border)),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: pal.primarySoft, shape: BoxShape.circle),
                    child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: TextStyle(color: pal.text, fontWeight: FontWeight.w800, fontSize: 15.5)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(color: pal.muted, fontSize: 12.5)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: pal.muted),
                ]),
              ),
            ),
          ),
        );
    return Scaffold(
      backgroundColor: pal.bg,
      appBar: topBar(context, 'Support'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        tile(Icons.bug_report_outlined, 'Report a problem', 'Tell us what went wrong', () => _wa(context, 'Problem report (JFT Sensei app):\n\n[Describe the problem here]$who')),
        tile(Icons.chat_outlined, 'Contact us', 'Chat with us on WhatsApp', () => _wa(context, 'Hello, I need help with JFT Sensei.$who')),
        tile(Icons.privacy_tip_outlined, 'Privacy policy', 'How we handle your data', () => _doc(context, 'Privacy policy', _privacy)),
        tile(Icons.description_outlined, 'Terms of use', 'Rules for using the app', () => _doc(context, 'Terms of use', _terms)),
      ]),
    );
  }

  void _doc(BuildContext c, String title, List<(String, String)> sections) => Navigator.push(
        c,
        MaterialPageRoute(
          builder: (ctx) {
            final pal = ctx.pal;
            return Scaffold(
              backgroundColor: pal.bg,
              appBar: topBar(ctx, title),
              body: ListView(padding: const EdgeInsets.all(20), children: [
                for (final s in sections) ...[
                  Text(s.$1, style: TextStyle(color: pal.text, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(s.$2, style: TextStyle(color: pal.muted, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 18),
                ],
              ]),
            );
          },
        ),
      );
}

const _privacy = [
  ('Information we collect', 'Your name, email address and the test activity and results you create while using the app.'),
  ('How we use it', 'To run your account, grade your tests, show your packages and send you notifications about your requests.'),
  ('Sharing', 'We do not sell your personal data. Payments are arranged with our team over WhatsApp.'),
  ('Your choices', 'You can change your password in the app. To delete your account or data, contact us through Support.'),
];

const _terms = [
  ('Using the app', 'JFT Sensei provides practice tests for personal study. Do not share your account with others.'),
  ('Packages', 'A package unlocks its sets for the listed number of days after approval. Access ends when it expires.'),
  ('Content', 'Tests and materials belong to JFT Sensei. Copying, screenshots or redistribution are not allowed.'),
  ('Changes', 'We may update these terms and the app from time to time.'),
];
