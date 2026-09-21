import 'package:cloud_firestore/cloud_firestore.dart';
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

  bool matches(Map<String, dynamic> data) {
    final needle = search.trim().toLowerCase();
    final searchable = [
      data['requestCode'],
      data['customerId'],
      data['agentId'],
      data['serviceType'],
      data['description'],
      data['address'],
    ].join(' ').toLowerCase();
    return (needle.isEmpty || searchable.contains(needle)) &&
        (status == 'all' ||
            StatusNames.values.contains(status) && data['status'] == status) &&
        (priority == 'all' ||
            PriorityNames.values.contains(priority) &&
                data['priority'] == priority) &&
        (serviceType == 'all' || data['serviceType'] == serviceType);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> apply(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> input,
  ) {
    final result = input.where((doc) => matches(doc.data())).toList()
      ..sort((a, b) {
        final aTime =
            (a.data()['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime =
            (b.data()['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
    final start = page * pageSize;
    if (start >= result.length) return const [];
    final end = (start + pageSize).clamp(0, result.length);
    return result.sublist(start, end);
  }
}
