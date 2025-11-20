import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../settings/controller/settings_controller.dart';

class WebViewPage extends ConsumerStatefulWidget {
  const WebViewPage({super.key});

  @override
  ConsumerState<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends ConsumerState<WebViewPage> {
  late final WebViewController _controller;
  String? _lastLoadedUrl;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.description)),
            );
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final url = ref.watch(
      settingsControllerProvider.select((state) => state.targetUrl),
    );

    if (_lastLoadedUrl != url) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUrl(url);
      });
      _lastLoadedUrl = url;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
        actions: [
          IconButton(
            onPressed: () => _loadUrl(url),
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }

  void _loadUrl(String url) {
    final normalizedUrl = url.startsWith('http') ? url : 'https://$url';
    _controller.loadRequest(Uri.parse(normalizedUrl));
  }
}
