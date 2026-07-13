import 'package:flutter/material.dart';

import '../../app_theme.dart';

class ReportDataList extends StatelessWidget {
  const ReportDataList({
    super.key,
    required this.rows,
    required this.columns,
  });

  final List<Map<String, dynamic>> rows;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final row = rows[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final col in columns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatLabel(col),
                            style: const TextStyle(
                              fontSize: 11,
                              color: kMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${row[col] ?? row[_findKey(row, col)] ?? '—'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: kText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _findKey(Map<String, dynamic> row, String col) {
    for (final key in row.keys) {
      if (key.toLowerCase() == col.toLowerCase()) return key;
    }
    return null;
  }

  String _formatLabel(String key) {
    if (key == 'totalSum') return 'Total';
    if (key == 'serviceName') return 'Service';
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
  }
}
