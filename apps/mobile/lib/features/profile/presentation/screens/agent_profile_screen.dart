import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';

/// Shows the contact details for the assigned technician.
class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({
    super.key,
    required this.agentId,
    this.name,
    this.phone,
  });

  final String agentId;
  final String? name;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final cleanName = name?.trim();
    final cleanPhone = phone?.trim();
    final hasContact =
        (cleanName?.isNotEmpty ?? false) || (cleanPhone?.isNotEmpty ?? false);

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

    final displayName = cleanName?.isNotEmpty == true ? cleanName! : 'Assigned technician';
    final initial = displayName[0].toUpperCase();
    final displayPhone = cleanPhone?.isNotEmpty == true ? cleanPhone! : 'Not provided';

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: const Text('Technician Profile'),
        ),
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
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
      ),
    );
  }
}
