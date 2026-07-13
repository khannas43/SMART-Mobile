import 'next_query_client.dart';

/// Eligible schemes for Provide Consent (`/citizen/eligibleSchemes`).
class EligibleService {
  EligibleService._();

  static final EligibleService instance = EligibleService._();

  final NextQueryClient _nextQuery = NextQueryClient.instance;

  static const _fields =
      'id,serviceId,nameHi,nameEn,fatherNameHi,fatherNameEn,motherNameHi,'
      'motherNameEn,districtNameHi,districtNameEn,blockNameHi,blockNameEn,'
      'spouceNameHi,spouceNameEn,status,isActive,createDate,refMemberId,memberId';

  Future<NextQueryResult> fetchEligibleServices({
    int page = 1,
    int size = 10,
  }) {
    return _nextQuery.listCount(
      model: 'EligibleServices',
      fields: _fields,
      filters: const {
        'executeActionName': 'CitizenEligibleServiceList',
      },
      page: page,
      size: size,
      roleHeader: 'CITIZEN',
    );
  }
}
