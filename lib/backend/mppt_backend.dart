import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/telemetry.dart';

class MpptDevice {
  final String name;
  final String id;
  final int rssi;
  final bool isMppt;

  const MpptDevice({
    required this.name,
    required this.id,
    required this.rssi,
    required this.isMppt,
  });
}

class MpptBackend extends ChangeNotifier {
  bool _connected = true; // default connected for instant demo/display
  bool _connecting = false;
  bool _scanning = false;
  String _statusText = 'Connected to MPPT-ESP32';
  String _lastError = '';
  DateTime? _lastTelemetryAt = DateTime.now();

  Telemetry? _telemetry = const Telemetry();
  HoldingSettings? _holding = const HoldingSettings();

  List<MpptDevice> _devices = [
    const MpptDevice(
      name: 'MPPT-ESP32',
      id: '24:6F:28:B4:9C:12',
      rssi: -54,
      isMppt: true,
    ),
    const MpptDevice(
      name: 'ESP32_BLE_Sensor',
      id: 'A0:B1:C2:D3:E4:F5',
      rssi: -78,
      isMppt: false,
    ),
  ];

  Timer? _telemetryTimer;

  MpptBackend() {
    _startSimulatedTelemetry();
  }

  bool get connected => _connected;
  bool get connecting => _connecting;
  bool get scanning => _scanning;
  String get statusText => _statusText;
  String get lastError => _lastError;
  DateTime? get lastTelemetryAt => _lastTelemetryAt;
  Telemetry? get telemetry => _telemetry;
  HoldingSettings? get holding => _holding;
  List<MpptDevice> get devices => _devices;

  void _startSimulatedTelemetry() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_connected) {
        _lastTelemetryAt = DateTime.now();
        final current = _telemetry ?? const Telemetry();
        // Gentle realistic variation
        final deltaP = (DateTime.now().second % 5 - 2) * 1.5;
        _telemetry = Telemetry(
          pvV: 36.2 + (DateTime.now().second % 3) * 0.1,
          pvP: (current.pvP + deltaP).clamp(280.0, 420.0),
          batV: (current.batV + (DateTime.now().second % 2 == 0 ? 0.01 : -0.01)).clamp(13.6, 14.4),
          batI: (current.batI + (deltaP / 14.0)).clamp(10.0, 25.0),
          batP: current.batP,
          energyWh: current.energyWh + 0.25,
          chargeAh: current.chargeAh + 0.02,
          peakP: current.peakP,
          stateName: current.stateName,
          fw: current.fw,
          actIlim: current.actIlim,
          actVcv: current.actVcv,
          actVhold: current.actVhold,
          actVrecharge: current.actVrecharge,
          actVlow: current.actVlow,
          chargerOn: current.chargerOn,
          converterOn: current.converterOn,
          tracking: current.tracking,
          fault: current.fault,
          faultName: current.faultName,
          faultCount: current.faultCount,
          lastFault: current.lastFault,
          sweepStateName: current.sweepStateName,
        );
        notifyListeners();
      }
    });
  }

  Future<void> startScan() async {
    _scanning = true;
    _lastError = '';
    _statusText = 'Scanning for BLE devices...';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _devices = [
      const MpptDevice(
        name: 'MPPT-ESP32',
        id: '24:6F:28:B4:9C:12',
        rssi: -54,
        isMppt: true,
      ),
      const MpptDevice(
        name: 'ESP32_BLE_Sensor',
        id: 'A0:B1:C2:D3:E4:F5',
        rssi: -78,
        isMppt: false,
      ),
    ];
    _scanning = false;
    _statusText = 'Scan complete. Found ${_devices.length} devices.';
    notifyListeners();
  }

  void stopScan() {
    _scanning = false;
    notifyListeners();
  }

  Future<void> connectById(String id) async {
    _connecting = true;
    _statusText = 'Connecting to $id...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    _connected = true;
    _connecting = false;
    _statusText = 'Connected to MPPT-ESP32';
    _lastTelemetryAt = DateTime.now();
    notifyListeners();
  }

  Future<void> disconnect() async {
    _connected = false;
    _statusText = 'Disconnected';
    notifyListeners();
  }

  Future<void> refresh() async {
    _statusText = 'Refreshing telemetry...';
    _lastTelemetryAt = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 400));
    _statusText = 'Connected to MPPT-ESP32';
    notifyListeners();
  }

  void sendCommand(Map<String, dynamic> cmd) {
    final command = cmd['cmd']?.toString();
    if (command == 'chargeron') {
      _telemetry = const Telemetry(
        chargerOn: true,
        converterOn: true,
        tracking: true,
        stateName: 'MPPT Bulk Charging',
      );
    } else if (command == 'chargeroff') {
      _telemetry = const Telemetry(
        chargerOn: false,
        converterOn: false,
        tracking: false,
        stateName: 'Standby',
      );
    } else if (command == 'clearfault') {
      _telemetry = const Telemetry(
        fault: 0,
        faultName: 'None',
        faultCount: 0,
        lastFault: 'None',
      );
    } else if (command == 'sweep') {
      _telemetry = const Telemetry(
        sweepStateName: 'Sweeping V-I curve...',
      );
      Future.delayed(const Duration(seconds: 3), () {
        _telemetry = const Telemetry(
          sweepStateName: 'Sweep complete',
        );
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<String> applySettings({
    required int chem,
    required int capacity,
    required int ichg,
    required int vcv,
    required int vhold,
    required int vrecharge,
    required int vlow,
  }) async {
    _holding = HoldingSettings(
      chem: chem,
      capacity: capacity,
      ichgA: ichg / 100.0,
      vcvV: vcv / 100.0,
      vholdV: vhold / 100.0,
      vrechargeV: vrecharge / 100.0,
      vlowV: vlow / 100.0,
    );
    notifyListeners();
    return 'Settings successfully applied to MPPT-ESP32!';
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
