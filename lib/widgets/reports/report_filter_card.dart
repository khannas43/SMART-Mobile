import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/report_models.dart';

class ReportFilterCard extends StatelessWidget {
  const ReportFilterCard({
    super.key,
    required this.services,
    required this.filters,
    required this.tempFrom,
    required this.tempTo,
    required this.onServiceChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSubmit,
    required this.onReset,
    this.loadingServices = false,
    this.servicesError,
  });

  final List<ServiceOption> services;
  final ReportFilterState filters;
  final DateTime? tempFrom;
  final DateTime? tempTo;
  final ValueChanged<ServiceOption?> onServiceChanged;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;
  final VoidCallback onSubmit;
  final VoidCallback onReset;
  final bool loadingServices;
  final String? servicesError;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    String? fmt(DateTime? d) {
      if (d == null) return null;
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              menuMaxHeight: 280,
              value: services.any((s) => s.serviceId == filters.serviceId)
                  ? filters.serviceId
                  : (services.isNotEmpty ? services.first.serviceId : null),
              decoration: InputDecoration(
                labelText: context.l('Service Name', 'सेवा का नाम'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: servicesError,
              ),
              selectedItemBuilder: (context) {
                return services.map((s) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  );
                }).toList();
              },
              items: services
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.serviceId,
                      child: Text(
                        s.serviceName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: loadingServices
                  ? null
                  : (id) {
                      if (id == null) return;
                      final svc = services.firstWhere(
                        (s) => s.serviceId == id,
                        orElse: () => ServiceOption(
                          serviceId: id,
                          serviceName: id,
                        ),
                      );
                      onServiceChanged(svc);
                    },
            ),
            const SizedBox(height: 12),
            _DateField(
              label: context.l('From Date', 'प्रारंभ तिथि'),
              value: tempFrom,
              onPick: onFromChanged,
              maxDate: tempTo,
              display: fmt(tempFrom),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: context.l('To Date', 'समाप्ति तिथि'),
              value: tempTo,
              onPick: onToChanged,
              minDate: tempFrom,
              display: fmt(tempTo),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onSubmit,
                    child: Text(context.l('Submit', 'जमा करें')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReset,
                    child: Text(context.l('Reset', 'रीसेट')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.display,
    this.minDate,
    this.maxDate,
  });

  final String label;
  final DateTime? value;
  final String? display;
  final DateTime? minDate;
  final DateTime? maxDate;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked == null) return;
        if (minDate != null && picked.isBefore(minDate!)) return;
        if (maxDate != null && picked.isAfter(maxDate!)) return;
        onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(display ?? 'DD-MM-YYYY'),
      ),
    );
  }
}
