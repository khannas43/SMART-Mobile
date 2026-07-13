import 'api_exception.dart';

/// Uniform login / SSO messages (VAPT — no user enumeration).
class AuthMessages {
  AuthMessages._();

  static const invalidCredentialsEn =
      'Invalid SSO ID or password. Please try again.';
  static const invalidCredentialsHi =
      'अमान्य SSO ID या पासवर्ड। कृपया पुनः प्रयास करें।';

  static const networkEn =
      'Unable to reach the server. Check your internet connection and try again.';
  static const networkHi =
      'सर्वर तक पहुँच नहीं हो सकी। अपना इंटरनेट कनेक्शन जाँचें और पुनः प्रयास करें।';

  static const serviceUnavailableEn =
      'Sign-in is temporarily unavailable. Please try again later.';
  static const serviceUnavailableHi =
      'साइन-इन अस्थायी रूप से उपलब्ध नहीं है। कृपया बाद में पुनः प्रयास करें।';

  /// Production: Raj SSO REST succeeded but SMART JWT could not be minted.
  static const jwtMintFailedEn =
      'Sign-in verified but server session could not be created. Please try again later.';
  static const jwtMintFailedHi =
      'साइन-इन सत्यापित हुआ, पर सर्वर सत्र नहीं बन सका। कृपया बाद में पुनः प्रयास करें।';

  static const ssoCallbackFailedEn =
      'Sign-in could not be completed. Please try again.';
  static const ssoCallbackFailedHi =
      'साइन-इन पूरा नहीं हो सका। कृपया पुनः प्रयास करें।';

  static String invalidCredentials({required bool hindi}) =>
      hindi ? invalidCredentialsHi : invalidCredentialsEn;

  static String network({required bool hindi}) =>
      hindi ? networkHi : networkEn;

  static String serviceUnavailable({required bool hindi}) =>
      hindi ? serviceUnavailableHi : serviceUnavailableEn;

  static String jwtMintFailed({required bool hindi}) =>
      hindi ? jwtMintFailedHi : jwtMintFailedEn;

  static String ssoCallbackFailed({required bool hindi}) =>
      hindi ? ssoCallbackFailedHi : ssoCallbackFailedEn;

  /// Maps login-path [ApiException]s to user-safe text (no enumeration).
  static String fromLoginException(ApiException e, {required bool hindi}) {
    if (e.isNetworkError) return network(hindi: hindi);
    final code = e.statusCode;
    if (code != null && code >= 500) {
      return serviceUnavailable(hindi: hindi);
    }
    if (e.message == jwtMintFailedEn || e.message == jwtMintFailedHi) {
      return jwtMintFailed(hindi: hindi);
    }
    return invalidCredentials(hindi: hindi);
  }
}
