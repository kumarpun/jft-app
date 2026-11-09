import 'package:flutter/material.dart';
import '../models.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../util.dart';
import '../widgets/load_view.dart';
import '../widgets/net_image.dart';
import '../widgets/ui.dart';

class AnnouncementsTab extends StatelessWidget {
  final AuthController auth;
  const AnnouncementsTab({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return LoadView<List<Announcement>>(
      load: auth.repo.announcements,
      isEmpty: (l) => l.isEmpty,
      emptyText: 'No announcements.',
      builder: (c, list) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (c, i) {
          final a = list[i];
          return FadeSlide(index: i, child: LuxCard(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NetImage(api: auth.api, url: a.imageUrl),
                Row(children: [
                  Expanded(child: Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  if (a.featured)
                    const Pill('★ Featured', color: Colors.white, bg: Color(0xFF3D6BEA))
                  else
                    Pill(timeLeft(a.secondsLeft), icon: Icons.timer_outlined),
                ]),
                if (a.body.isNotEmpty) ...[const SizedBox(height: 8), Text(a.body)],
              ]),
            ),
          ));
        },
      ),
    );
  }
}
