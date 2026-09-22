import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/core/error/app_exceptions.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key, this.initialService});
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
  List<shared.Service> _availableServices = const [];
  shared.RequestPriority _priority = shared.RequestPriority.medium;
  int _step = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<String> get _serviceOptions {
    if (_availableServices.isNotEmpty) {
      return _availableServices.map((service) => service.name).toList();
    }
    return shared.ServiceNames.values;
  }

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialService;
    _loadActiveServices();
  }

  Future<void> _loadActiveServices() async {
    try {
      final services = await ref.read(serviceRepositoryProvider).getServices();
      if (!mounted) return;
      final requestedService = widget.initialService;
      setState(() {
        _availableServices = services;
        _serviceType =
            requestedService != null &&
                services.any((service) => service.name == requestedService)
            ? requestedService
            : null;
      });
    } on RequestRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load services. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _chooseDateTime() async {
    final now = DateTime.now();
    final firstAvailableDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final selectedDate = _preferredDateTime;
    final initialDate =
        selectedDate != null && !selectedDate.isBefore(firstAvailableDate)
        ? selectedDate
        : firstAvailableDate;
    final date = await showDatePicker(
      context: context,
      firstDate: firstAvailableDate,
      lastDate: firstAvailableDate.add(const Duration(days: 365)),
      initialDate: initialDate,
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _preferredDateTime == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_preferredDateTime!),
    );
    if (!mounted || time == null) return;
    setState(
      () => _preferredDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  bool _validateStep() {
    if (_step == 0) return _formKey.currentState!.validate();
    if (_step == 1) {
      final valid = _formKey.currentState!.validate();
      if (_preferredDateTime == null) {
        setState(() => _errorMessage = 'Choose a preferred date and time.');
      }
      return valid && _preferredDateTime != null;
    }
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    setState(() {
      _errorMessage = null;
      _step = (_step + 1).clamp(0, 2);
    });
  }

  Future<void> _submit() async {
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
            preferredDateTime: _preferredDateTime!,
            address: _addressController.text,
            priority: _priority,
          );
      if (mounted) context.go('/request-success/$requestId');
    } on RequestRepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = error.userMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Could not create the request. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _step == 0 || _isSubmitting) return;
        setState(() {
          _step--;
          _errorMessage = null;
        });
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Request')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Step ${_step + 1} of 3',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_step == 0)
                  _detailsStep()
                else if (_step == 1)
                  _scheduleStep()
                else
                  _reviewStep(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                  _step--;
                                  _errorMessage = null;
                                }),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting
                            ? null
                            : (_step == 2 ? _submit : _next),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                              )
                            : Text(
                                _step == 2 ? 'Submit request' : 'Continue  →',
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'What do you need help with?',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Give us a few details so we can find the right professional.',
        style: TextStyle(color: AppColors.mutedText),
      ),
      const SizedBox(height: AppSpacing.xl),
      DropdownButtonFormField<String>(
        initialValue: _serviceOptions.contains(_serviceType)
            ? _serviceType
            : null,
        decoration: quickServeInputDecoration(
          'Service type',
          icon: Icons.home_repair_service_outlined,
        ),
        items: _serviceOptions
            .map(
              (service) =>
                  DropdownMenuItem(value: service, child: Text(service)),
            )
            .toList(),
        validator: (value) => value == null ? 'Service is required.' : null,
        onChanged: _isSubmitting
            ? null
            : (value) => setState(() => _serviceType = value),
      ),
      SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        decoration: quickServeInputDecoration(
          'Describe the issue',
          icon: Icons.notes_outlined,
        ),
        validator: (value) {
          final result = shared.validateDescription(value ?? '');
          return result.isValid ? null : result.reason;
        },
      ),
    ],
  );

  Widget _scheduleStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'When and where?',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Choose a convenient time and tell the agent where to come.',
        style: TextStyle(color: AppColors.mutedText),
      ),
      const SizedBox(height: AppSpacing.xl),
      OutlinedButton.icon(
        onPressed: _isSubmitting ? null : _chooseDateTime,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(
          _preferredDateTime == null
              ? 'Choose date and time'
              : '${MaterialLocalizations.of(context).formatFullDate(_preferredDateTime!)} · ${TimeOfDay.fromDateTime(_preferredDateTime!).format(context)}',
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _addressController,
        maxLines: 4,
        decoration: quickServeInputDecoration(
          'Service address',
          icon: Icons.location_on_outlined,
        ),
        validator: (value) {
          final result = shared.validateAddress(value ?? '');
          return result.isValid ? null : result.reason;
        },
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<shared.RequestPriority>(
        initialValue: _priority,
        decoration: quickServeInputDecoration(
          'Priority',
          icon: Icons.flag_outlined,
        ),
        items: shared.RequestPriority.values
            .map(
              (priority) =>
                  DropdownMenuItem(value: priority, child: Text(priority.name)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _priority = value);
        },
      ),
    ],
  );

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Review your request',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Check the details before sending. There is no payment step.',
        style: TextStyle(color: AppColors.mutedText),
      ),
      const SizedBox(height: AppSpacing.xl),
      _ReviewRow(label: 'Service', value: _serviceType ?? 'Not selected'),
      _ReviewRow(label: 'Description', value: _descriptionController.text),
      _ReviewRow(
        label: 'Preferred time',
        value: _preferredDateTime == null
            ? 'Not selected'
            : '${MaterialLocalizations.of(context).formatFullDate(_preferredDateTime!)} · ${TimeOfDay.fromDateTime(_preferredDateTime!).format(context)}',
      ),
      _ReviewRow(label: 'Address', value: _addressController.text),
      _ReviewRow(label: 'Priority', value: _priority.name),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.mintSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'QuickServe will confirm the request and keep you updated in the app.',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
