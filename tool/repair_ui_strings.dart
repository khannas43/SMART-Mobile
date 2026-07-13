// One-off repair for main.dart Hindi strings (activity 4.0b).
// Run: dart run tool/repair_ui_strings.dart
import 'dart:io';

const _hindiByEnglish = <String, String>{
  'Government of Rajasthan': 'राजस्थान सरकार',
  'Service Management with Artificial Intelligence and Real-Time System':
      'कृत्रिम बुद्धिमत्ता एवं रियल-टाइम प्रणाली के साथ सेवा प्रबंधन',
  'Dashboard': 'डैशबोर्ड',
  'Schemes': 'योजनाएं',
  'Consents': 'सहमति',
  'Alerts': 'सूचना',
  'Profile': 'प्रोफ़ाइल',
  'Your Scheme & Services': 'आपकी योजनाएं एवं सेवाएं',
  'Consent Management': 'सहमति प्रबंधन',
  'Notifications': 'सूचनाएं',
  'Your Profile': 'आपकी प्रोफ़ाइल',
  'Citizen Dashboard': 'नागरिक डैशबोर्ड',
  'CONSENT MANAGEMENT': 'सहमति प्रबंधन',
  'Welcome': 'स्वागत है',
  'Here is your benefits & consent summary.': 'यह आपके लाभ एवं सहमति का सारांश है।',
  'Retry': 'पुनः प्रयास',
  'Status of Services': 'सेवाओं की स्थिति',
  'Eligible Services': 'पात्र सेवाएं',
  'Total Services Availed': 'कुल प्राप्त सेवाएं',
  'Services In Process': 'प्रक्रियाधीन सेवाएं',
  'Opt-Out Services': 'ऑप्ट-आउट सेवाएं',
  'Status of Consents': 'सहमति की स्थिति',
  'Total Consent Submitted': 'कुल सहमति जमा',
  'Approved': 'स्वीकृत',
  'Pending': 'लंबित',
  'Quick Actions': 'त्वरित कार्य',
  'Check\nEligibility': 'पात्रता\nजांचें',
  'View\nDocuments': 'दस्तावेज़\nदेखें',
  'View\nReports': 'रिपोर्ट\nदेखें',
  'Reports': 'रिपोर्ट',
  'Your Reports': 'आपकी रिपोर्ट',
  'View Details': 'विवरण',
  'Sort by:': 'क्रमबद्ध:',
  'Date': 'तिथि',
  'Name': 'नाम',
  'No availed services yet.': 'अभी कोई प्राप्त सेवा नहीं है।',
  'No eligible services right now.': 'अभी कोई पात्र सेवा नहीं है।',
  'Check Eligibility': 'पात्रता जांचें',
  'Availed Benefits': 'प्राप्त लाभ',
  'View details': 'विवरण देखें',
  'Provide Consent': 'सहमति दें',
  'Benefit Type': 'लाभ प्रकार',
  'Availed Date': 'प्राप्ति तिथि',
  'Status': 'स्थिति',
  'Availed on': 'प्राप्ति तिथि',
  'District': 'ज़िला',
  'Block': 'ब्लॉक',
  "Father's name": 'पिता का नाम',
  "Mother's name": 'माता का नाम',
  'Service ID': 'सेवा ID',
  'Department': 'विभाग',
  'Enter the 6-digit OTP.': '6 अंकों का OTP दर्ज करें।',
  'Invalid OTP. Use 654321 in demo mode.': 'अमान्य OTP। डेमो में 654321 उपयोग करें।',
  'Session expired. Send OTP again.': 'सत्र समाप्त। OTP पुनः भेजें।',
  'Please accept the declaration to continue.': 'जारी रखने हेतु घोषणा स्वीकार करें।',
  'Session expired. Start again.': 'सत्र समाप्त। पुनः प्रारंभ करें।',
  'Send OTP': 'OTP भेजें',
  'Verify OTP': 'OTP सत्यापित',
  'Enter the OTP we sent to your registered mobile number':
      'पंजीकृत मोबाइल पर भेजा OTP दर्ज करें',
  "Didn't receive code?": 'कोड नहीं मिला?',
  'Resend OTP after': 'OTP पुनः भेजें',
  'Resend OTP': 'OTP पुनः भेजें',
  'Submit Consent': 'सहमति जमा करें',
  'Consent': 'सहमति',
  'Consent Submitted': 'सहमति जमा हुई',
  'Reference': 'संदर्भ',
  'Back to Services': 'सेवाओं पर वापस',
  'No consents submitted yet.': 'अभी तक कोई सहमति जमा नहीं की गई।',
  'Consent date': 'सहमति तिथि',
  'View Documents': 'दस्तावेज़ देखें',
  'No documents available yet.': 'अभी कोई दस्तावेज़ उपलब्ध नहीं है।',
  'PDF certificate': 'PDF प्रमाण पत्र',
  'Access level': 'पहुँच स्तर',
  'Available Reports': 'उपलब्ध रिपोर्ट',
  'No records for this report yet.': 'इस रिपोर्ट के लिए अभी कोई रिकॉर्ड नहीं है।',
  'Generating PDF…': 'PDF बन रही है…',
  'Download Report (PDF)': 'रिपोर्ट डाउनलोड करें (PDF)',
  'This is a system-generated report. No signature required.':
      'यह सिस्टम-जनित रिपोर्ट है। हस्ताक्षर आवश्यक नहीं।',
  'Beneficiary': 'लाभार्थी',
  'Submitted': 'जमा',
  'No notifications yet.': 'अभी तक कोई सूचना नहीं है।',
  'Full Name': 'पूरा नाम',
  'Jan Aadhaar ID': 'जन आधार ID',
  'Mobile Number': 'मोबाइल नंबर',
  'Date of Birth': 'जन्म तिथि',
  'Gender': 'लिंग',
  'CITIZEN': 'नागरिक',
  'Personal Details': 'व्यक्तिगत विवरण',
  'Linked IDs': 'लिंक ID',
  'Download is not available for this document yet.':
      'इस दस्तावेज़ के लिए डाउनलोड अभी उपलब्ध नहीं है।',
  'Schemes & Services': 'योजनाएं एवं सेवाएं',
  'View Consent': 'सहमति देखें',
  'Logout': 'लॉग आउट',
  'Email': 'ईमेल',
  'Jan Member ID': 'जन सदस्य ID',
  'Raj SSO ID': 'राज SSO ID',
  'Processing': 'प्रक्रियाधीन',
  'Rejected': 'अस्वीकृत',

};

void main() {
  final path = 'lib/main.dart';
  var content = File(path).readAsStringSync();
  var count = 0;

  // Common mojibake / emoji fixes
  const literalFixes = {
    '�?"': '—',
    '�?�': '•',
    '�Y\'<': '👋',
    '�YZ�': '🎯',
    '�Y"<': '📋',
    '�Y",': '📂',
    '�Y"S': '📊',
    '�Y""': '🔔',
    '�Y�>': '🏛',
  };
  for (final entry in literalFixes.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
    }
  }

  for (final entry in _hindiByEnglish.entries) {
    final en = RegExp.escape(entry.key);
    final pattern = RegExp("L\\('$en',\\s*'(?:[^'\\\\]|\\\\.)*'\\)");
    content = content.replaceAllMapped(pattern, (match) {
      count++;
      final hi = entry.value.replaceAll("'", "\\'");
      return "L('${entry.key}', '$hi')";
    });
  }

  // Nav tuple Hindi labels
  const navFixes = {
    "'Dashboard', '": "'Dashboard', 'डैशबोर्ड'",
    "'Schemes', '": "'Schemes', 'योजनाएं'",
    "'Consents', '": "'Consents', 'सहमति'",
    "'Alerts', '": "'Alerts', 'सूचना'",
    "'Profile', '": "'Profile', 'प्रोफ़ाइल'",
  };
  for (final entry in navFixes.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceFirst(
        RegExp("${RegExp.escape(entry.key)}[^']*'"),
        entry.value,
      );
    }
  }

  // Drawer / leftover labels (exact English → Hindi)
  const drawerFixes = <String, String>{
    'Schemes & Services': 'योजनाएं एवं सेवाएं',
    'View Consent': 'सहमति देखें',
    'Check Eligibility': 'पात्रता जांचें',
  };
  for (final entry in drawerFixes.entries) {
    final en = RegExp.escape(entry.key);
    final pattern = RegExp("L\\('$en',\\s*'(?:[^'\\\\]|\\\\.)*'\\)");
    content = content.replaceAllMapped(pattern, (match) {
      count++;
      return "L('${entry.key}', '${entry.value}')";
    });
  }

  File(path).writeAsStringSync(content, flush: true);
  stdout.writeln('Repaired $count L() strings in $path');
}
