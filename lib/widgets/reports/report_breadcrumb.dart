import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';
import '../../models/report_models.dart';

class ReportBreadcrumb extends StatelessWidget {
  const ReportBreadcrumb({
    super.key,
    required this.filters,
    required this.onResetAll,
    required this.onResetToService,
    required this.onResetToDistrict,
    this.servicesById = const {},
  });

  final ReportFilterState filters;
  final VoidCallback onResetAll;
  final VoidCallback onResetToService;
  final VoidCallback onResetToDistrict;
  final Map<String, ServiceOption> servicesById;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final serviceLabel = localizedServiceLabel(
      context,
      serviceId: filters.serviceId,
      fallbackEn: filters.serviceName,
      fallbackHi: filters.serviceNameHi,
      byId: servicesById,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        _Link(context.l('Reports', 'रिपोर्ट'), onResetAll),
        if (filters.hasService) ...[
          const Text('/', style: TextStyle(color: kMuted)),
          _Link(serviceLabel, onResetToService),
        ],
        if (filters.hasDistrict) ...[
          const Text('/', style: TextStyle(color: kMuted)),
          _Link(filters.localizedDistrictName(context), onResetToDistrict),
        ],
        if (filters.selectedRural != null) ...[
          const Text('/', style: TextStyle(color: kMuted)),
          Text(
            filters.localizedSelectedRural(context),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        if (filters.hasBlock) ...[
          const Text('/', style: TextStyle(color: kMuted)),
          Text(
            filters.localizedBlockName(context),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kPrimaryRoyal,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
