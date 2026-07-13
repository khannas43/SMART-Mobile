import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'raj_sso_auth_service.dart';
import 'sso_callback_router.dart';

/// Listens for Android deep links / App Links (activity 3.6).
class SsoDeepLinkService {
  SsoDeepLinkService._({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  static final SsoDeepLinkService instance = SsoDeepLinkService._();

  @visibleForTesting
  factory SsoDeepLinkService.forTest() => SsoDeepLinkService._(appLinks: null);

  final AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;
  Uri? _lastHandledUri;

  /// Register platform link listener. Call once before [runApp].
  Future<void> initialize() async {
    final appLinks = _appLinks;
    if (appLinks == null) return;

    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      await handleIncomingUri(initialUri);
    }

    await _subscription?.cancel();
    _subscription = appLinks.uriLinkStream.listen(handleIncomingUri);
  }

  /// Processes a URI from the platform or from tests.
  Future<void> handleIncomingUri(Uri uri) async {
    if (!RajSsoAuthService.isCallbackUri(uri)) return;
    if (_lastHandledUri == uri) return;
    _lastHandledUri = uri;
    await SsoCallbackRouter.handleUri(uri);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
