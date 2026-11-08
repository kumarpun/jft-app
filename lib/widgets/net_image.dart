import 'package:flutter/material.dart';
import '../api/api_client.dart';

class NetImage extends StatelessWidget {
  final ApiClient api;
  final String? url;
  const NetImage({super.key, required this.api, required this.url});

  @override
  Widget build(BuildContext context) {
    final abs = api.absolute(url);
    if (abs == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          abs,
          headers: api.needsAuth(abs) ? api.authHeaders : null,
          fit: BoxFit.contain,
          loadingBuilder: (c, child, p) => p == null
              ? child
              : const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
