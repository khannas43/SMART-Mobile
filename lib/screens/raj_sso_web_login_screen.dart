import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/raj_sso_auth_service.dart';

/// In-app WebView fallback when Chrome Custom Tab is unavailable (activity 3.5).
///
/// Intercepts navigation to the registered SSO callback URI and pops with it
/// for JWT exchange (activity 3.7).
class RajSsoWebLoginScreen extends StatefulWidget {
  const RajSsoWebLoginScreen({
    super.key,
    required this.signInUri,
  });

  final Uri signInUri;

  @override
  State<RajSsoWebLoginScreen> createState() => _RajSsoWebLoginScreenState();
}

class _RajSsoWebLoginScreenState extends State<RajSsoWebLoginScreen> {
  late final WebViewController _controller;
  var _progress = 0.0;
  var _pageTitle = 'Rajasthan SSO';

  static const _brandBlue = Color(0xFF2B4673);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onPageFinished: (url) async {
            final title = await _controller.getTitle();
            if (mounted && title != null && title.isNotEmpty) {
              setState(() => _pageTitle = title);
            }
          },
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (target != null && RajSsoAuthService.isCallbackUri(target)) {
              Navigator.of(context).pop(target);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.signInUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        title: Text(
          _pageTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2,
              color: _brandBlue,
              backgroundColor: _brandBlue.withOpacity(0.12),
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
