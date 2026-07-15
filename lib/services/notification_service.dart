import '../services/next_query_client.dart';

/// Citizen notifications — mirrors web `NotificationList.tsx`.
class NotificationService {
  NotificationService._([NextQueryClient? client])
      : _client = client ?? NextQueryClient.instance;

  static final NotificationService instance = NotificationService._();

  final NextQueryClient _client;

  static const _fields =
      'id,notificationMemberName,notificationMemberId,notificationMessage,'
      'notificationLanguage,notificationTimeStamp,notificationServiceName,'
      'notificationHofMobile';

  Future<NextQueryResult> fetchNotifications({
    int page = 1,
    int size = 20,
  }) {
    return _client.listCount(
      model: 'NotificationRequest',
      fields: _fields,
      filters: const {'executeActionName': 'CitizenNotification'},
      page: page,
      size: size,
    );
  }
}
