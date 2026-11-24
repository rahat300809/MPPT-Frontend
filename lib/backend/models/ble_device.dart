/// UI-safe BLE scan row (no flutter_blue_plus types).
class BleDeviceInfo {
  final String id;
  final String name;
  final int rssi;
  final bool isMppt;

  const BleDeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isMppt,
  });
}
