import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_router.dart';
import '../controller/settings_controller.dart';
import '../models/network_device.dart';
import '../state/settings_state.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final initialUrl =
        ref.read(settingsControllerProvider.select((s) => s.targetUrl));
    _urlController = TextEditingController(text: initialUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
        if (next.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              style: Theme.of(context).textTheme.titleMedium,
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
                  'Network devices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.icon(
                  onPressed: settings.isScanning
                      ? null
                      : () => notifier.scanForDevices(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (settings.isScanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (settings.devices.isEmpty)
              const Text(
                'Start a scan to discover Wi-Fi networks and Bluetooth printers.',
              )
            else
              _DeviceDropdown(
                devices: settings.devices,
                selected: settings.selectedDevice,
                onChanged: notifier.selectDevice,
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.webView,
              ),
              child: const Text('Open Web View'),
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
    return DropdownButtonFormField<NetworkDevice>(
      value: selected,
      items: devices
          .map(
            (device) => DropdownMenuItem(
              value: device,
              child: Text('${device.name} • ${device.type.name}'),
            ),
          )
          .toList(),
      decoration: const InputDecoration(
        labelText: 'Detected devices',
      ),
      onChanged: onChanged,
    );
  }
}
