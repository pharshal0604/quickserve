import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';

import 'people_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({required this.repository, super.key});
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) =>
      PeopleScreen(repository: repository, role: RoleNames.customer);
}
