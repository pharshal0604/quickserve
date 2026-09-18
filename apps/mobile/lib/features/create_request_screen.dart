import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';
import '../utils/app_exceptions.dart';

/// Provides the Customer request-creation flow.
class CreateRequestScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const CreateRequestScreen({super.key, this.initialService});

  /// An optional service selected from the Services screen.
  final String? initialService;

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _preferredDateTime;
  String? _serviceType;
  shared.RequestPriority _priority = shared.RequestPriority.medium;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialService;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _chooseDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _preferredDateTime ?? DateTime.now(),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _preferredDateTime == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_preferredDateTime!),
    );
    if (!mounted || time == null) return;
    setState(() {
      _preferredDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_preferredDateTime == null) {
      setState(() => _errorMessage = 'Choose a preferred date and time.');
      return;
    }
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) {
      setState(
        () => _errorMessage = 'Your session has expired. Please sign in again.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final requestId = await ref
          .read(requestRepositoryProvider)
          .createRequest(
            customerId: authUser.uid,
            serviceType: _serviceType!,
            description: _descriptionController.text,
            preferredDateTime: Timestamp.fromDate(_preferredDateTime!),
            address: _addressController.text,
            priority: _priority,
          );
      if (!mounted) return;
      context.go('/requests/$requestId');
    } on RequestRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Could not create the request. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Request')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _serviceType,
                decoration: const InputDecoration(labelText: 'Service type'),
                items:
                    const [
                      'AC servicing',
                      'Plumbing',
                      'Electrical',
                      'Cleaning',
                    ].map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                validator: (value) =>
                    value == null ? 'Service is required.' : null,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _serviceType = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final result = shared.validateDescription(value ?? '');
                  return result.isValid ? null : result.reason;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _chooseDateTime,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _preferredDateTime == null
                      ? 'Choose preferred date and time'
                      : '${MaterialLocalizations.of(context).formatFullDate(_preferredDateTime!)} ${TimeOfDay.fromDateTime(_preferredDateTime!).format(context)}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final result = shared.validateAddress(value ?? '');
                  return result.isValid ? null : result.reason;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<shared.RequestPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: shared.RequestPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _priority = value);
                      },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Create Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
