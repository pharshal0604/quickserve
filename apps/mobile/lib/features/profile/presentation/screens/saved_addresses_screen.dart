import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  bool _saving = false;

  Future<void> _addAddress(String address) async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;

    setState(() => _saving = true);
    try {
      final updatedAddresses = List<String>.from(profile.addresses)
        ..add(address);
      await ref
          .read(userRepositoryProvider)
          .updateAddresses(
            ref.read(authStateProvider).value!.uid,
            updatedAddresses,
          );
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add address')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeAddress(String address) async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;

    setState(() => _saving = true);
    try {
      final updatedAddresses = List<String>.from(profile.addresses)
        ..remove(address);
      await ref
          .read(userRepositoryProvider)
          .updateAddresses(
            ref.read(authStateProvider).value!.uid,
            updatedAddresses,
          );
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove address')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Address'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your full address',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _addAddress(text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

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
          title: const Text('Saved Addresses'),
        ),
        body: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading addresses: $e')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Profile not found'));
            }
            final addresses = user.addresses;

            if (addresses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 48,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No saved addresses yet',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 16),
                    if (_saving)
                      const CircularProgressIndicator()
                    else
                      FilledButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Address'),
                      ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(address),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: _saving ? null : () => _removeAddress(address),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: profile.value?.addresses.isNotEmpty == true
            ? FloatingActionButton(
                onPressed: _saving ? null : _showAddDialog,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
