import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// iOS has no FLAG_SECURE equivalent to block screenshots outright (VAPT parity with Android
  /// is best-effort here): we blur the window on backgrounding (hides content from the app
  /// switcher snapshot) and re-blur for the duration of an active screen recording.
  private let screenSecurityChannel = "gov.rajasthan.smart/screen_security"
  private var screenSecurityEnabled = false
  private var privacyBlurView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NotificationCenter.default.addObserver(
      self, selector: #selector(applyBlurIfNeeded),
      name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(removeBlur),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(screenCaptureDidChange),
      name: UIScreen.capturedDidChangeNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: screenSecurityChannel, binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable":
        self?.screenSecurityEnabled = true
        result(nil)
      case "disable":
        self?.screenSecurityEnabled = false
        self?.removeBlur()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @objc private func applyBlurIfNeeded() {
    guard screenSecurityEnabled, let window = keyWindowForBlur(), privacyBlurView == nil else { return }
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blur.tag = 0xBEEF
    window.addSubview(blur)
    privacyBlurView = blur
  }

  @objc private func removeBlur() {
    privacyBlurView?.removeFromSuperview()
    privacyBlurView = nil
  }

  @objc private func screenCaptureDidChange() {
    guard screenSecurityEnabled else { return }
    if UIScreen.main.isCaptured {
      applyBlurIfNeeded()
    } else if UIApplication.shared.applicationState == .active {
      removeBlur()
    }
  }

  private func keyWindowForBlur() -> UIWindow? {
    if #available(iOS 15.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first
    }
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
