/// Active SMART panel after SSO login (matches web `X-Current-Role`).
enum SmartPanel {
  citizen,
  department;

  String get headerValue => switch (this) {
        SmartPanel.citizen => 'CITIZEN',
        SmartPanel.department => 'DEPARTMENT',
      };

  String labelEn() => switch (this) {
        SmartPanel.citizen => 'Citizen',
        SmartPanel.department => 'Department',
      };

  String labelHi() => switch (this) {
        SmartPanel.citizen => 'नागरिक',
        SmartPanel.department => 'विभाग',
      };
}
