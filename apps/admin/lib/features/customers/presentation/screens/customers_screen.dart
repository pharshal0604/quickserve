import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'people_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PeopleScreen(role: RoleNames.customer);
}
