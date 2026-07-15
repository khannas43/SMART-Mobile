import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/user_role.dart';
import '../../services/role/role_context.dart';

/// Citizen / Department user manual — in-app asset PDF + download.
class CitizenUserManualScreen extends StatefulWidget {
  const CitizenUserManualScreen({super.key});

  static const assetPath =
      'assets/SMART_Mobile_Application_User_Manual_V1.0.pdf';
  static const fileName = 'SMART_Mobile_Application_User_Manual_V1.0.pdf';

  @override
  State<CitizenUserManualScreen> createState() =>
      _CitizenUserManualScreenState();
}

class _CitizenUserManualScreenState extends State<CitizenUserManualScreen> {
  var _downloading = false;

  Color get _accent {
    final panel = RoleContext.instance.activePanel ?? SmartPanel.citizen;
    return panel == SmartPanel.department ? kDeptNavyMid : kCitizenOrange;
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await rootBundle.load(CitizenUserManualScreen.assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${CitizenUserManualScreen.fileName}');
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          text: 'SMART Mobile Application User Manual V1.0',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l(
              'Unable to download the user manual. Please try again.',
              'उपयोगकर्ता मैनुअल डाउनलोड नहीं हो सका। कृपया पुनः प्रयास करें।',
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l('User Manual', 'उपयोगकर्ता मैनुअल'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l(
                        'SMART Mobile Application User Manual · Version 1.0',
                        'SMART मोबाइल एप्लिकेशन उपयोगकर्ता मैनुअल · संस्करण 1.0',
                      ),
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _downloading ? null : _download,
                style: FilledButton.styleFrom(backgroundColor: _accent),
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(context.l('Download', 'डाउनलोड')),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF1F5F9),
            child: PdfViewer.asset(
              CitizenUserManualScreen.assetPath,
              params: const PdfViewerParams(
                margin: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
