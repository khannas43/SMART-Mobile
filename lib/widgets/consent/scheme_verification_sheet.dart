import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../platform/screen_security.dart';
import '../../services/api_error_presenter.dart';
import '../../services/api_error_util.dart';
import '../../services/api_exception.dart';
import '../../services/consent_otp_service.dart';
import '../../services/consent_submit_service.dart';

/// 3-step Provide Consent flow (web `SchemeVerificationModal`).
/// Steps: Send OTP → Verify OTP → Submit Consent.
class SchemeVerificationSheet extends StatefulWidget {
  const SchemeVerificationSheet({
    super.key,
    required this.eligibleRow,
    required this.onSuccess,
  });

  final Map<String, dynamic> eligibleRow;
  final VoidCallback onSuccess;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> eligibleRow,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SchemeVerificationSheet(
            eligibleRow: eligibleRow,
            onSuccess: onSuccess,
          ),
        );
      },
    );
  }

  @override
  State<SchemeVerificationSheet> createState() => _SchemeVerificationSheetState();
}

class _SchemeVerificationSheetState extends State<SchemeVerificationSheet> {
  var _step = 1;
  var _loading = false;
  String? _otpError;
  final _otpController = TextEditingController();
  final _scrollController = ScrollController();
  String? _tid;
  String? _otpPrefix;
  String? _maskedMobile;
  String? _prefixWarning;
  Map<String, dynamic>? _validationResponse;
  var _resendCounter = 0;
  Timer? _resendTimer;

  static const _stepLabelsEn = ['Send OTP', 'Verify OTP', 'Consent'];
  static const _stepLabelsHi = ['OTP भेजें', 'OTP सत्यापित', 'सहमति'];

  String get _serviceName =>
      widget.eligibleRow['serviceName']?.toString() ??
      widget.eligibleRow['nameEn']?.toString() ??
      'Service';

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    ScreenSecurity.disable();
    _otpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCounter = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCounter <= 1) {
        timer.cancel();
        setState(() => _resendCounter = 0);
      } else {
        setState(() => _resendCounter--);
      }
    });
  }

  void _showError(Object error) {
    ApiErrorPresenter.show(ApiErrorUtil.asApiException(error));
  }

  String? _validateOtpInput(String otp) {
    if (otp.isEmpty) {
      return AppLocaleController.instance.isHindi
          ? 'कृपया OTP दर्ज करें।'
          : 'Please enter the OTP.';
    }
    if (otp.length != 6) {
      return AppLocaleController.instance.isHindi
          ? 'कृपया 6-अंकीय OTP दर्ज करें।'
          : 'Please enter the 6-digit OTP.';
    }
    if (_tid == null || _tid!.isEmpty) {
      return AppLocaleController.instance.isHindi
          ? 'OTP सत्र समाप्त हो गया। कृपया OTP पुनः भेजें।'
          : 'OTP session expired. Please resend OTP.';
    }
    if (_otpPrefix == null || _otpPrefix!.trim().isEmpty) {
      return AppLocaleController.instance.isHindi
          ? 'OTP सत्र अधूरा है। कृपया OTP पुनः भेजें।'
          : 'OTP session incomplete. Please resend OTP.';
    }
    return null;
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final profileBlock = await ConsentOtpService.consentProfileBlockReason();
    if (profileBlock != null) {
      _showError(ApiException(message: profileBlock));
      return;
    }

    setState(() {
      _loading = true;
      _otpError = null;
      if (isResend) {
        _otpController.clear();
      }
    });
    try {
      final id = widget.eligibleRow['id']?.toString() ?? '';
      final result = await ConsentOtpService.instance.sendOtp(consentId: id);
      _tid = result.transactionId;
      _otpPrefix = result.otpPrefix;
      _maskedMobile = result.maskedMobile;
      _prefixWarning = (result.otpPrefix == null || result.otpPrefix!.trim().isEmpty)
          ? (AppLocaleController.instance.isHindi
              ? 'OTP प्रीफ़िक्स प्राप्त नहीं हुआ। सत्यापन से पहले OTP पुनः भेजें।'
              : 'OTP prefix was not received. Resend OTP before verifying.')
          : null;
      if (!mounted) return;
      setState(() => _step = 2);
      _startResendTimer();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    final validationError = _validateOtpInput(otp);
    if (validationError != null) {
      setState(() => _otpError = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _otpError = null;
    });
    try {
      final result = await ConsentOtpService.instance.validateOtp(
        tid: _tid!,
        otp: otp,
        otpPrefix: _otpPrefix,
      );
      _validationResponse = {
        ...result.raw,
        'status': true,
        'isvalidate': true,
        if (result.message != null && result.message!.isNotEmpty)
          'message': result.message,
      };
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      _resendTimer?.cancel();
      setState(() => _step = 3);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitConsent() async {
    setState(() => _loading = true);
    try {
      await ConsentSubmitService.instance.availServiceAndCreateConsent(
        eligibleRow: widget.eligibleRow,
        otpTxnId: _tid,
        otpValidationResponse: _validationResponse,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocaleController.instance.isHindi
                ? 'OTP सत्यापित और सहमति सफलतापूर्वक जमा की गई।'
                : 'OTP verified and consent submitted successfully.',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSuccess();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _loadingButtonChild(String label) {
    if (!_loading) return Text(label);
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final hindi = AppLocaleController.instance.isHindi;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 1; i <= 3; i++) ...[
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: _step >= i ? kCitizenOrange : kBorder,
                          child: Text(
                            '$i',
                            style: TextStyle(
                              color: _step >= i ? Colors.white : kMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hindi ? _stepLabelsHi[i - 1] : _stepLabelsEn[i - 1],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _step >= i ? kText : kMuted,
                          ),
                        ),
                      ],
                    ),
                    if (i < 3)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            height: 2,
                            color: _step > i ? kCitizenOrange : kBorder,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              if (_step == 1) ...[
                Text(
                  context.l(
                    'To Opt-in for the $_serviceName service, an OTP will be sent to your registered mobile number for verification.',
                    '$_serviceName सेवा के लिए ऑप्ट-इन करने हेतु, सत्यापन के लिए आपके पंजीकृत मोबाइल पर OTP भेजा जाएगा।',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loadingButtonChild(context.l('Send OTP', 'OTP भेजें')),
                ),
              ],
              if (_step == 2) ...[
                if (_maskedMobile != null && _maskedMobile!.isNotEmpty) ...[
                  Text(
                    context.l(
                      'OTP sent to $_maskedMobile',
                      'OTP $_maskedMobile पर भेजा गया',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: kMuted),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_otpPrefix != null && _otpPrefix!.isNotEmpty) ...[
                  Text(
                    context.l(
                      'Enter the 6-digit code from SMS (prefix: $_otpPrefix).',
                      'SMS से 6-अंकीय कोड दर्ज करें (प्रीफ़िक्स: $_otpPrefix)।',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_prefixWarning != null) ...[
                  Text(
                    _prefixWarning!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  obscureText: true,
                  enableInteractiveSelection: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  contextMenuBuilder: (context, editableTextState) =>
                      const SizedBox.shrink(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_otpError != null) {
                      setState(() => _otpError = null);
                    }
                  },
                  onSubmitted: (_) {
                    if (!_loading) _verifyOtp();
                  },
                  decoration: InputDecoration(
                    labelText: context.l('Enter OTP', 'OTP दर्ज करें'),
                    border: const OutlineInputBorder(),
                    errorText: _otpError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _verifyOtp,
                  child: _loadingButtonChild(
                    context.l('Verify OTP', 'OTP सत्यापित करें'),
                  ),
                ),
                if (_resendCounter > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.l(
                        'Resend OTP in $_resendCounter s',
                        'OTP पुनः भेजें $_resendCounter सेकंड में',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _loading ? null : () => _sendOtp(isResend: true),
                    child: Text(context.l('Resend OTP', 'OTP पुनः भेजें')),
                  ),
              ],
              if (_step == 3) ...[
                Icon(Icons.check_circle, size: 48, color: Colors.green.shade600),
                const SizedBox(height: 12),
                Text(
                  context.l(
                    'OTP verified. Confirm consent to avail $_serviceName.',
                    'OTP सत्यापित। $_serviceName सेवा प्राप्त करने के लिए सहमति की पुष्टि करें।',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submitConsent,
                  child: _loadingButtonChild(
                    context.l('Submit Consent', 'सहमति जमा करें'),
                  ),
                ),
              ],
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: Text(context.l('Cancel', 'रद्द करें')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
