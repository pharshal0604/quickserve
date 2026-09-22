import 'package:flutter/material.dart';

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';

/// The approved technician contact fields captured for one assigned request.
class AgentContactSnapshot {
  const AgentContactSnapshot({this.name, this.phone});

  final String? name;
  final String? phone;
}

/// Shows only the contact details captured for the assigned request.
class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({super.key, required this.snapshot});

  final AgentContactSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final name = snapshot?.name?.trim();
    final phone = snapshot?.phone?.trim();
    final hasContact =
        (name?.isNotEmpty ?? false) || (phone?.isNotEmpty ?? false);
    if (!hasContact) {
      return Scaffold(
        appBar: AppBar(title: const Text('Technician Profile')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Technician contact details are unavailable for this request.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final displayName = name?.isNotEmpty == true
        ? name!
        : 'Assigned technician';
    final initial = displayName[0].toUpperCase();
    final displayPhone = phone?.isNotEmpty == true ? phone! : 'Not provided';

    return Scaffold(
      appBar: AppBar(title: const Text('Technician Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.statusAssigned,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Assigned Service Technician',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Contact Details',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone'),
              subtitle: Text(displayPhone),
            ),
          ),
        ],
      ),
    );
  }
}
