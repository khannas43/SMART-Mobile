import 'next_query_client.dart';

/// Availed schemes for citizen panel (`/citizen/availedSchemes`).
class AvailedService {
  AvailedService._();

  static final AvailedService instance = AvailedService._();

  final NextQueryClient _nextQuery = NextQueryClient.instance;

  static const _fields =
      'id,serviceId,nameHi,nameEn,fatherNameHi,fatherNameEn,motherNameHi,'
      'motherNameEn,districtNameHi,districtNameEn,blockNameHi,blockNameEn,'
      'spouceNameHi,spouceNameEn,status,isActive,createDate,refMemberId,memberId';

  Future<NextQueryResult> fetchAvailedServices({
    int page = 1,
    int size = 10,
    String? memberId,
  }) {
    final filters = <String, dynamic>{
      'executeActionName': 'CitizenAvailedServiceList',
    };
    if (memberId != null && memberId.trim().isNotEmpty) {
      filters['memberId'] = memberId.trim();
    }
    return _nextQuery.listCount(
      model: 'EligibleServices',
      fields: _fields,
      filters: filters,
      page: page,
      size: size,
      roleHeader: 'CITIZEN',
    );
  }
}
