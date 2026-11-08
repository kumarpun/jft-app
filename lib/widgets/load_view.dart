import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Loads data via [load], shows spinner/error/empty, pull-to-refresh.
class LoadView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  final bool Function(T)? isEmpty;
  final String emptyText;
  const LoadView({super.key, required this.load, required this.builder, this.isEmpty, this.emptyText = 'Nothing here yet.'});
  @override
  State<LoadView<T>> createState() => _LoadViewState<T>();
}

class _LoadViewState<T> extends State<LoadView<T>> {
  late Future<T> _f = widget.load();

  Future<void> _refresh() async {
    final f = widget.load();
    setState(() => _f = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(children: [
              const SizedBox(height: 120),
              const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              ),
              const SizedBox(height: 16),
              Center(child: OutlinedButton(onPressed: _refresh, child: const Text('Retry'))),
            ]),
          );
        }
        final data = snap.data as T;
        if (widget.isEmpty?.call(data) ?? false) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(children: [
              const SizedBox(height: 140),
              Center(child: Text(widget.emptyText, style: const TextStyle(color: AppColors.muted))),
            ]),
          );
        }
        return RefreshIndicator(onRefresh: _refresh, child: widget.builder(context, data));
      },
    );
  }
}
