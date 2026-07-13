import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';

/// UAT `/citizen/viewConsent` table columns: SNO, User, Consent, Department, Date.
class ConsentListTable extends StatelessWidget {
  const ConsentListTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPrev,
    required this.onNext,
    this.loading = false,
  });

  final List<Map<String, dynamic>> rows;
  final int page;
  final int pageSize;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final pageCount = total == 0 ? 1 : ((total + pageSize - 1) / pageSize).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            context.l('Total records: $total', 'कुल रिकॉर्ड: $total'),
            style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(kBg),
            columns: [
              DataColumn(label: Text(context.l('SNO', 'क्रम'))),
              DataColumn(label: Text(context.l('User', 'उपयोगकर्ता'))),
              DataColumn(label: Text(context.l('Consent', 'सहमति'))),
              DataColumn(label: Text(context.l('Department', 'विभाग'))),
              DataColumn(label: Text(context.l('Date', 'तिथि'))),
            ],
            rows: [
              for (var i = 0; i < rows.length; i++)
                DataRow(
                  cells: [
                    DataCell(Text('${(page - 1) * pageSize + i + 1}')),
                    DataCell(Text(_str(rows[i]['consenterMemberName']))),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          _str(rows[i]['consentSubject']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_str(rows[i]['consentDepartmentName']))),
                    DataCell(Text(_formatDate(rows[i]['createDate']))),
                  ],
                ),
            ],
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(color: kCitizenOrange)),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: page > 1 && !loading ? onPrev : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              context.l('Page $page of $pageCount', 'पृष्ठ $page / $pageCount'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: page < pageCount && !loading ? onNext : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  static String _str(dynamic v) {
    final text = v?.toString().trim();
    if (text == null || text.isEmpty) return '—';
    return text;
  }

  static String _formatDate(dynamic v) {
    if (v == null) return '—';
    DateTime? dt;
    if (v is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(v).toLocal();
    } else if (v is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(v.toInt()).toLocal();
    } else {
      final parsed = int.tryParse(v.toString());
      if (parsed != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(parsed).toLocal();
      }
    }
    if (dt == null) return v.toString();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }
}
