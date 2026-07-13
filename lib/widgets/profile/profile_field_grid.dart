import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';

class ProfileField {
  const ProfileField({
    required this.labelEn,
    required this.labelHi,
    required this.value,
    this.masked = false,
  });

  final String labelEn;
  final String labelHi;
  final String value;
  final bool masked;
}

class ProfileFieldGrid extends StatelessWidget {
  const ProfileFieldGrid({super.key, required this.fields});

  final List<ProfileField> fields;

  static String maskValue(BuildContext context, String? value, {int visible = 4}) {
    if (value == null || value.isEmpty) {
      return context.l('Not Available', 'उपलब्ध नहीं');
    }
    if (value.length <= visible) return value;
    return '${'X' * (value.length - visible)}${value.substring(value.length - visible)}';
  }

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 600 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.5 : 2.8,
              ),
              itemCount: fields.length,
              itemBuilder: (_, i) {
                final field = fields[i];
                final display = field.masked
                    ? maskValue(context, field.value)
                    : (field.value.isEmpty
                        ? context.l('Not Available', 'उपलब्ध नहीं')
                        : field.value);
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.l(field.labelEn, field.labelHi),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    display,
                    style: const TextStyle(fontSize: 13, color: kText),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
