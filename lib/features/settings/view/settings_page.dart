import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/permissions/permissions_controller.dart';
import '../../auth/controller/auth_controller.dart';

import '../../../core/routing/app_router.dart';
import '../controller/settings_controller.dart';
import '../models/network_device.dart';
import '../state/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  late final TextEditingController _urlController;
  bool _isRequestingPermissions = false;
  bool _didInitUrl = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _urlController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitUrl) {
      final initialUrl = context.read<SettingsCubit>().state.targetUrl;
      _urlController.text = initialUrl;
      _didInitUrl = true;
    }
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
      context.read<PermissionsCubit>().recheckPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final permissionsCubit = context.read<PermissionsCubit>();
    final authCubit = context.read<AuthCubit>();

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, next) => previous.error != next.error,
      listener: (context, state) {
        if (state.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'An error occurred')),
          );
        }
      },
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
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
                      helperText:
                          'This URL will be rendered in the WebView page.',
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: settingsCubit.updateTargetUrl,
                    onChanged: settingsCubit.updateTargetUrl,
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
                                    final has = await permissionsCubit
                                        .checkPermissions();
                                    if (!has) {
                                      await permissionsCubit
                                          .requestPermissions();
                                      final hasAfterRequest =
                                          await permissionsCubit
                                              .checkPermissions();
                                      if (!hasAfterRequest) {
                                        if (!context.mounted) return;
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Permissions are required to scan for devices. Please grant all permissions.'),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    await settingsCubit.scanForDevices();
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              settings.error ?? 'An error occurred',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
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
                      onChanged: settingsCubit.selectDevice,
                    ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _isRequestingPermissions
                        ? null
                        : () async {
                            setState(() {
                              _isRequestingPermissions = true;
                            });
                            try {
                              final results = await permissionsCubit
                                  .requestAllPermissions();

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
                              if (!context.mounted) return;
                              if (!mounted) return;
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Permission results'),
                                  content: SingleChildScrollView(
                                      child: Text(message)),
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
                                          permissionsCubit.openSettings();
                                        },
                                        child: const Text('Open App Settings'),
                                      ),
                                  ],
                                ),
                              );

                              if (results.values
                                  .any((s) => s.isPermanentlyDenied)) {
                                await Future<void>.delayed(
                                    const Duration(milliseconds: 200));
                                await permissionsCubit.openSettings();
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
                      await authCubit.signOut();
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
        },
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
