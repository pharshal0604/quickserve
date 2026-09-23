import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/features/agent/presentation/widgets/agent_common/agent_bottom_nav.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

final _notificationsStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return const Stream.empty();

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    });

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final isAgent = profile?.role == shared.UserRole.agent;
    final notificationsAsync = ref.watch(_notificationsStreamProvider);

    return Scaffold(
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
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (notifications) {
                final filtered = notifications;

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications found.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.mutedText),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline
                        .withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final note = filtered[index];
                    final isRead = note['isRead'] == true;

                    return ListTile(
                      tileColor: isRead
                          ? null
                          : Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.05),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Icon(
                          Icons.notifications,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        note['title'] ?? 'Notification',
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(note['body'] ?? ''),
                      onTap: () async {
                        final user = ref.read(authStateProvider).value;
                        if (user != null && !isRead) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('notifications')
                              .doc(note['id'])
                              .update({'isRead': true});
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isAgent
          ? const AgentBottomNav(currentIndex: 0, showSelection: false)
          : const CustomerBottomNav(currentIndex: 3),
    );
  }
}

