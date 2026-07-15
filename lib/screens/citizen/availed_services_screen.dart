import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../services/api_error_util.dart';
import '../../services/availed_service.dart';
import '../../widgets/data_screen_states.dart';

/// Citizen "Availed Schemes & Services" list (web `/citizen/availedSchemes`).
class AvailedServicesScreen extends StatefulWidget {
  const AvailedServicesScreen({super.key});

  @override
  State<AvailedServicesScreen> createState() => _AvailedServicesScreenState();
}

class _AvailedServicesScreenState extends State<AvailedServicesScreen> {
  var _page = 1;
  static const _pageSize = 10;
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];
  var _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AvailedService.instance.fetchAvailedServices(
        page: _page,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _rows = result.rows;
        _total = result.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorUtil.friendlyMessage(e);
        _loading = false;
      });
    }
  }

  String _name(Map<String, dynamic> row) {
    return row['serviceName']?.toString() ??
        row['nameEn']?.toString() ??
        row['nameHi']?.toString() ??
        '—';
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kText,
        elevation: 0,
        title: Text(
          context.l('Availed Services', 'प्राप्त सेवाएं'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: kCitizenOrange),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          await _load();
        },
        color: kCitizenOrange,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.l(
                'View Schemes & Services you availed',
                'आपके द्वारा प्राप्त योजनाएं और सेवाएं देखें',
              ),
              style: const TextStyle(fontSize: 13, color: kMuted),
            ),
            const SizedBox(height: 12),
            if (_loading && _rows.isEmpty)
              DataScreenStates.loading()
            else if (_error != null)
              DataScreenStates.error(
                context: context,
                message: _error!,
                onRetry: _load,
              )
            else if (_rows.isEmpty)
              DataScreenStates.empty(
                message: context.l(
                  'No availed services found.',
                  'कोई प्राप्त सेवा नहीं मिली।',
                ),
              )
            else ...[
              for (final row in _rows)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: kBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name(row),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l(
                            'Status: ${row['status'] ?? '—'}',
                            'स्थिति: ${row['status'] ?? '—'}',
                          ),
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                        if (row['createDate'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.l(
                              'Date: ${row['createDate']}',
                              'तिथि: ${row['createDate']}',
                            ),
                            style: const TextStyle(fontSize: 12, color: kMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (_total > _pageSize) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _page > 1 && !_loading
                          ? () {
                              setState(() => _page--);
                              _load();
                            }
                          : null,
                      child: Text(context.l('Previous', 'पिछला')),
                    ),
                    Text(
                      '$_page / ${(_total / _pageSize).ceil().clamp(1, 9999)}',
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                    TextButton(
                      onPressed:
                          _page * _pageSize < _total && !_loading
                              ? () {
                                  setState(() => _page++);
                                  _load();
                                }
                              : null,
                      child: Text(context.l('Next', 'अगला')),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
