import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../routing/app_router.dart';
import 'permissions_controller.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionsCubit>().recheckPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PermissionsCubit>().recheckPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PermissionsCubit, PermissionsState>(
      listenWhen: (previous, current) =>
          previous.hasAllPermissions != current.hasAllPermissions ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.hasAllPermissions && !state.isChecking && mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.settings);
        }
        if (state.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'An error occurred')),
          );
        }
      },
      builder: (context, permissionsState) {
        final controller = context.read<PermissionsCubit>();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.settings);
                }
              },
            ),
            title: const Text('Permissions'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Permissions Required',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This app needs the following permissions to function:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const _PermissionItem(
                    icon: Icons.location_on,
                    title: 'Location',
                    description:
                        'Required by Android to discover nearby Bluetooth devices',
                  ),
                  const SizedBox(height: 16),
                  const _PermissionItem(
                    icon: Icons.bluetooth,
                    title: 'Bluetooth',
                    description:
                        'Needed to scan for printers, earbuds, and other accessories',
                  ),
                  const Spacer(),
                  if (permissionsState.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              permissionsState.error ?? 'An error occurred',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (permissionsState.isChecking)
                    const CircularProgressIndicator()
                  else
                    FilledButton(
                      onPressed: controller.requestPermissions,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Grant Permissions'),
                    ),
                  if (permissionsState.error != null &&
                      (permissionsState.error?.contains('permanently denied') ??
                          false))
                    const SizedBox(height: 12),
                  if (permissionsState.error != null &&
                      (permissionsState.error?.contains('permanently denied') ??
                          false))
                    OutlinedButton(
                      onPressed: controller.openSettings,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Open App Settings'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
