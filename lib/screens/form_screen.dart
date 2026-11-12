import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../util.dart';
import '../widgets/ui.dart';

/// Shows a Google Form inside the app (WebView) under the app's branded header.
class FormScreen extends StatefulWidget {
  final String title;
  final String url;
  final int durationSeconds; // 0 = no limit: timer counts up from 0
  const FormScreen({super.key, required this.title, required this.url, this.durationSeconds = 0});
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  late final WebViewController _web;
  int _progress = 0;
  String? _error;
  Timer? _timer;
  late int _left = widget.durationSeconds;
  int _elapsed = 0;
  bool get _countUp => widget.durationSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _error = e.description);
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_countUp) {
        setState(() => _elapsed++);
        return;
      }
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        _timeUp();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _timeUp() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Time's up"),
        content: const Text('The time limit for this form has ended.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _reload() {
    setState(() => _error = null);
    _web.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar(context, widget.title, actions: [
        Center(
          child: Text(clock(_countUp ? _elapsed : (_left < 0 ? 0 : _left)),
              style: TextStyle(color: !_countUp && _left <= 60 ? AppColors.danger : context.pal.text, fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        IconButton(icon: Icon(Icons.refresh, color: context.pal.text), tooltip: 'Reload', onPressed: _reload),
        const SizedBox(width: 4),
      ]),
      body: Column(children: [
        if (_progress < 100 && _error == null) LinearProgressIndicator(value: _progress / 100, minHeight: 3),
        Expanded(
          child: _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.cloud_off, size: 48, color: context.pal.muted),
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: context.pal.muted)),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _reload, child: const Text('Retry')),
                  ]),
                )
              : WebViewWidget(controller: _web),
        ),
      ]),
    );
  }
}
