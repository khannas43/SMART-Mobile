import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../app_navigation.dart';
import 'api_error_presenter.dart';
import 'api_exception.dart';
import 'auth_messages.dart';
import 'raj_sso_auth_service.dart';
import 'sso_landing_service.dart';

/// Routes Raj SSO deep links / App Links to JWT exchange (activities 3.6–3.7).
class SsoCallbackRouter {
  SsoCallbackRouter._();

  /// Last successful callback awaiting JWT exchange.
  static RajSsoCallback? pendingCallback;

  /// Test override for [SsoLandingService.completeLogin].
  @visibleForTesting
  static SsoLandingExchange? completeLoginOverride;

  /// Handles an incoming [uri] when it matches [RajSsoAuthService.isCallbackUri].
  static Future<void> handleUri(Uri uri) async {
    if (!RajSsoAuthService.isCallbackUri(uri)) return;
    await handleParsed(RajSsoAuthService.parseCallbackUri(uri));
  }

  static Future<void> handleParsed(RajSsoCallback callback) async {
    pendingCallback = callback;

    if (callback.error != null) {
      ApiErrorPresenter.show(
        ApiException(message: AuthMessages.ssoCallbackFailedEn),
      );
      return;
    }

    if (!callback.isSuccess) {
      ApiErrorPresenter.show(
        ApiException(message: AuthMessages.ssoCallbackFailedEn),
      );
      return;
    }

    final messenger = gScaffoldMessengerKey.currentState;
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Completing Raj SSO sign-in…'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 30),
        ),
      );

    try {
      final complete = completeLoginOverride ?? _defaultCompleteLogin;
      await complete(
        userdetails: callback.userdetails!,
        ssoId: callback.ssoId,
      );
      clearPending();
      messenger?.clearSnackBars();
      AppNavigation.replaceWithHome();
    } on ApiException catch (e) {
      messenger?.clearSnackBars();
      ApiErrorPresenter.show(
        ApiException(message: AuthMessages.fromLoginException(e, hindi: false)),
      );
    } catch (e) {
      messenger?.clearSnackBars();
      ApiErrorPresenter.show(
        ApiException(
          message: AuthMessages.ssoCallbackFailedEn,
          cause: e,
        ),
      );
    }
  }

  static Future<void> _defaultCompleteLogin({
    required String userdetails,
    String? ssoId,
  }) {
    return SsoLandingService.instance.completeLogin(
      userdetails: userdetails,
      ssoId: ssoId,
    );
  }

  static void clearPending() {
    pendingCallback = null;
  }
}
