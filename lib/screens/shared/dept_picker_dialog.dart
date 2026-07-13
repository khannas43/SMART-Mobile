import 'package:flutter/material.dart';

import '../../i18n/app_locale.dart';
import '../../services/role/department_service.dart';

class DeptPickerDialog extends StatelessWidget {
  const DeptPickerDialog({super.key, required this.departments});

  final List<MappedDepartment> departments;

  static Future<MappedDepartment?> show(
    BuildContext context,
    List<MappedDepartment> departments,
  ) {
    return showDialog<MappedDepartment>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeptPickerDialog(departments: departments),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l('Select Department', 'विभाग चुनें')),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: departments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final dept = departments[i];
            return ListTile(
              title: Text(dept.name),
              subtitle: Text(dept.id),
              onTap: () => Navigator.pop(context, dept),
            );
          },
        ),
      ),
    );
  }
}
