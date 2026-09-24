import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';

final _agentContactProvider = FutureProvider.family<shared.User?, String>((ref, agentId) {
  return ref.watch(userRepositoryProvider).getProfile(agentId);
});

/// Shows the contact details for the assigned technician.
class AgentProfileScreen extends ConsumerWidget {
  const AgentProfileScreen({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentAsync = ref.watch(_agentContactProvider(agentId));

    return agentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Technician Profile')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Could not load technician details.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (agent) {
        final name = agent?.name.trim();
        final phone = agent?.phone.trim();
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
          ),
        );
      },
    );
  }
}
