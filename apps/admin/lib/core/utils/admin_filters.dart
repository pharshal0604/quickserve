import 'package:shared/shared.dart';

class AdminRequestFilters {
  const AdminRequestFilters({
    this.search = '',
    this.status = 'all',
    this.priority = 'all',
    this.serviceType = 'all',
    this.pageSize = 25,
    this.page = 0,
  });

  final String search;
  final String status;
  final String priority;
  final String serviceType;
  final int pageSize;
  final int page;

  AdminRequestFilters copyWith({
    String? search,
    String? status,
    String? priority,
    String? serviceType,
    int? pageSize,
    int? page,
  }) => AdminRequestFilters(
    search: search ?? this.search,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    serviceType: serviceType ?? this.serviceType,
    pageSize: (pageSize ?? this.pageSize).clamp(1, 50),
    page: (page ?? this.page).clamp(0, 1000000),
  );

  bool matches(RequestEntity request) {
    final needle = search.trim().toLowerCase();
    final searchable = [
      request.requestCode,
      request.customerId,
      request.agentId,
      request.serviceType,
      request.description,
      request.address,
    ].join(' ').toLowerCase();
    return (needle.isEmpty || searchable.contains(needle)) &&
        (status == 'all' ||
            StatusNames.values.contains(status) &&
                request.status.toStoredValue() == status) &&
        (priority == 'all' ||
            PriorityNames.values.contains(priority) &&
                request.priority.name == priority) &&
        (serviceType == 'all' || request.serviceType == serviceType);
  }

  List<({String id, RequestEntity request})> apply(
    Iterable<({String id, RequestEntity request})> input,
  ) {
    final result = input.where((doc) => matches(doc.request)).toList()
      ..sort((a, b) {
        final aTime = a.request.updatedAt.millisecondsSinceEpoch;
        final bTime = b.request.updatedAt.millisecondsSinceEpoch;
        return bTime.compareTo(aTime);
      });
    final start = page * pageSize;
    if (start >= result.length) return const [];
    final end = (start + pageSize).clamp(0, result.length);
    return result.sublist(start, end);
  }
}
