import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/permissions/permissions_controller.dart';
import '../../auth/controller/auth_controller.dart';

import '../../../core/routing/app_router.dart';
import '../controller/settings_controller.dart';
import '../models/network_device.dart';
import '../state/settings_state.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  late TextEditingController _urlController;
  bool _isRequestingPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialUrl =
        ref.read(settingsControllerProvider.select((s) => s.targetUrl));
    _urlController = TextEditingController(text: initialUrl);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when returning from App Settings
      ref.read(permissionsControllerProvider.notifier).recheckPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state errors and show a SnackBar. ref.listen must be called
    // inside the build method (ConsumerWidget/ConsumerState build).
    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error ?? 'An error occurred')),
        );
      }
    });

    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Open web view',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.webView);
            },
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Website source',
              style: Theme.of(context).textTheme.titleMedium ??
                  Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Web URL',
                helperText: 'This URL will be rendered in the WebView page.',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: notifier.updateTargetUrl,
              onChanged: notifier.updateTargetUrl,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Bluetooth devices',
                  style: Theme.of(context).textTheme.titleMedium ??
                      Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: settings.isScanning
                          ? null
                          : () async {
                              final permController = ref
                                  .read(permissionsControllerProvider.notifier);
                              final has =
                                  await permController.checkPermissions();
                              if (!has) {
                                // Request permissions directly instead of navigating to permissions page
                                await permController.requestPermissions();
                                // Re-check after requesting
                                final hasAfterRequest =
                                    await permController.checkPermissions();
                                if (!hasAfterRequest && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Permissions are required to scan for devices. Please grant all permissions.'),
                                    ),
                                  );
                                  return;
                                }
                              }

                              await notifier.scanForDevices();
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (settings.isScanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (settings.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        settings.error ?? 'An error occurred',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (settings.devices.isEmpty)
              const Text(
                'Start a scan to discover nearby Bluetooth printers or earbuds.',
              )
            else
              _DeviceDropdown(
                devices: settings.devices,
                selected: settings.selectedDevice,
                onChanged: notifier.selectDevice,
              ),
            const SizedBox(height: 32),
            // Request permissions button moved here (below device dropdown)
            OutlinedButton.icon(
              onPressed: _isRequestingPermissions
                  ? null
                  : () async {
                      setState(() {
                        _isRequestingPermissions = true;
                      });
                      try {
                        final controller =
                            ref.read(permissionsControllerProvider.notifier);
                        final results =
                            await controller.requestAllPermissions();

                        final lines = results.entries.map((e) {
                          final status = e.value;
                          final stateText = status.isGranted
                              ? 'granted'
                              : status.isPermanentlyDenied
                                  ? 'permanently denied'
                                  : status.isDenied
                                      ? 'denied'
                                      : status.toString();
                          return '${e.key}: $stateText';
                        }).toList();

                        final message = lines.join('\n');
                        if (!mounted) return;
                        // Show results and await for the user to dismiss the dialog.
                        await showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Permission results'),
                            content:
                                SingleChildScrollView(child: Text(message)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              ),
                              if (results.values
                                  .any((s) => s.isPermanentlyDenied))
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    controller.openSettings();
                                  },
                                  child: const Text('Open App Settings'),
                                ),
                            ],
                          ),
                        );

                        // If any permission is permanently denied, open App Settings
                        // automatically after the user dismisses the results dialog.
                        if (results.values.any((s) => s.isPermanentlyDenied)) {
                          // Small delay so the dialog fully dismisses before opening
                          // system settings (avoids UI race conditions).
                          await Future<void>.delayed(
                              const Duration(milliseconds: 200));
                          await controller.openSettings();
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isRequestingPermissions = false;
                          });
                        }
                      }
                    },
              icon: _isRequestingPermissions
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_open),
              label: const Text('Request permissions'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.webView,
              ),
              child: const Text('Open Web View'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final authController =
                    ref.read(authControllerProvider.notifier);
                await authController.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({
    required this.devices,
    required this.onChanged,
    required this.selected,
  });

  final List<NetworkDevice> devices;
  final NetworkDevice? selected;
  final ValueChanged<NetworkDevice?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return DropdownButtonFormField<NetworkDevice>(
        value: null,
        items: const [],
        decoration: const InputDecoration(
          labelText: 'No devices found',
        ),
        onChanged: (_) {},
      );
    }

    return DropdownButtonFormField<NetworkDevice>(
      value: selected,
      items: devices.map(
        (device) {
          try {
            final deviceName =
                device.name.isNotEmpty ? device.name : 'Unknown device';
            final typeName = device.type.label;
            return DropdownMenuItem(
              value: device,
              child: Text('$deviceName • $typeName'),
            );
          } catch (e) {
            return DropdownMenuItem(
              value: device,
              child: const Text('Unknown device'),
            );
          }
        },
      ).toList(),
      decoration: const InputDecoration(
        labelText: 'Detected devices',
      ),
      onChanged: onChanged,
    );
  }
}
