import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backend/mppt_backend.dart';
import '../theme/app_theme.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<MpptBackend>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Look for device: MPPT-ESP32',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Do NOT pair from phone Bluetooth settings.\n'
              'Use only this app Scan → tap the device.\n'
              'If Serial shows "[BLE] client connected" but the app cannot see it, '
              'type blekick in Serial Monitor, then Scan again.',
              style: TextStyle(fontSize: 12, color: AppColors.onVariant),
            ),
            const SizedBox(height: 8),
            Text(ble.statusText),
            if (ble.lastError.isNotEmpty)
              Text(ble.lastError,
                  style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: ble.scanning ? null : () => ble.startScan(),
              icon: ble.scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bluetooth_searching),
              label: Text(ble.scanning ? 'Scanning…' : 'Scan'),
            ),
            if (ble.lastError.toLowerCase().contains('permission'))
              OutlinedButton.icon(
                onPressed: () => ble.startScan(),
                icon: const Icon(Icons.settings),
                label: const Text('Retry / Open permission settings'),
              ),
            if (ble.connected)
              OutlinedButton(
                onPressed: () => ble.disconnect(),
                child: const Text('Disconnect'),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: ble.devices.length,
                itemBuilder: (ctx, i) {
                  final d = ble.devices[i];
                  return Card(
                    color: d.isMppt ? AppColors.badgeOkBg : null,
                    child: ListTile(
                      leading: Icon(
                        Icons.bluetooth,
                        color: d.isMppt ? AppColors.primary : null,
                      ),
                      title: Text(
                        d.isMppt ? '${d.name}  ← tap this' : d.name,
                        style: TextStyle(
                          fontWeight:
                              d.isMppt ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(d.id),
                      trailing: Text('${d.rssi} dBm'),
                      onTap: ble.connecting
                          ? null
                          : () async {
                              await ble.connectById(d.id);
                              if (context.mounted && ble.connected) {
                                Navigator.pop(context);
                              }
                            },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
