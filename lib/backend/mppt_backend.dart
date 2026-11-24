import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/ble_device.dart';
import 'models/telemetry.dart';

abstract class MpptBackend extends ChangeNotifier {
  bool get scanning;
  bool get connecting;
  bool get connected;
  String get statusText;
  String get lastError;

  Telemetry? get telemetry;
  HoldingSettings? get holding;
  List<BleDeviceInfo> get devices;

  DateTime? get lastTelemetryAt;

  Future<void> startScan();
  Future<void> connectById(String deviceId);
  Future<void> disconnect();
  Future<void> refresh();
  Future<void> sendCommand(Map<String, dynamic> cmd);
  Future<String> applySettings({
    required int chem,
    required int capacity,
    required int ichg,
    required int vcv,
    required int vhold,
    required int vrecharge,
    required int vlow,
  });
}

class InnoMpptBackend extends MpptBackend {
  bool _connected = true;
  bool _connecting = false;
  bool _scanning = false;
  String _statusText = 'Connected to MPPT-ESP32';
  String _lastError = '';
  DateTime? _lastTelemetryAt = DateTime.now();

  Telemetry? _telemetry;
  HoldingSettings? _holding;
  List<BleDeviceInfo> _devices = [
    const BleDeviceInfo(
      id: '24:6F:28:B4:9C:12',
      name: 'MPPT-ESP32',
      rssi: -54,
      isMppt: true,
    ),
    const BleDeviceInfo(
      id: 'A0:B1:C2:D3:E4:F5',
      name: 'ESP32_BLE_Sensor',
      rssi: -78,
      isMppt: false,
    ),
  ];

  Timer? _telemetryTimer;

  InnoMpptBackend() {
    _telemetry = Telemetry.fromJson({
      'status': 1,
      'state': 3,
      'stateName': 'MPPT Bulk Charging',
      'fault': 0,
      'faultName': 'None',
      'pvV': 36.4,
      'pvI': 8.8,
      'pvP': 320.5,
      'batV': 13.82,
      'batI': 15.2,
      'batP': 210.0,
      'soc': 85,
      'duty': 0.65,
      'vset': 14.4,
      'iset': 20.0,
      'mpptV': 35.8,
      'voc': 42.1,
      'energyWh': 1450.0,
      'chargeAh': 98.4,
      'chgTimeS': 14400,
      'peakP': 450.0,
      'batVmin': 12.4,
      'batVmax': 14.4,
      'day': 1,
      'uptimeS': 28800,
      'faultCount': 0,
      'lastFault': 0,
      'pvLost': 0,
      'mpptRestarts': 0,
      'sweepCount': 12,
      'sweepState': 0,
      'sweepStateName': 'Ready',
      'sweepV': 35.8,
      'sweepP': 318.0,
      'actVcv': 14.40,
      'actVhold': 13.50,
      'actVrecharge': 13.20,
      'actVlow': 10.50,
      'actIlim': 25.0,
      'actIstop': 0.5,
      'imax': 40.0,
      'lastCmd': 0,
      'lastCmdName': 'None',
      'cmdResult': 0,
      'cmdResultName': 'OK',
      'fw': 'v1.4.2',
      'fwNum': 10402,
      'map': 1,
      'serial': 1001,
      'chargerOn': true,
      'converterOn': true,
      'tracking': true,
      'ccLoop': false,
      'pending': false,
      'menuOpen': false,
      'batPresent': true,
    });

    _holding = const HoldingSettings(
      chem: 0,
      chemName: 'Lead-acid',
      capacity: 100,
      ichg: 1000,
      ichgA: 10.0,
      vcv: 1440,
      vcvV: 14.40,
      vhold: 1350,
      vholdV: 13.50,
      vrecharge: 1320,
      vrechargeV: 13.20,
      vlow: 1050,
      vlowV: 10.50,
    );

    _startSimulatedTelemetry();
  }

  @override
  bool get connected => _connected;
  @override
  bool get connecting => _connecting;
  @override
  bool get scanning => _scanning;
  @override
  String get statusText => _statusText;
  @override
  String get lastError => _lastError;
  @override
  DateTime? get lastTelemetryAt => _lastTelemetryAt;
  @override
  Telemetry? get telemetry => _telemetry;
  @override
  HoldingSettings? get holding => _holding;
  @override
  List<BleDeviceInfo> get devices => _devices;

  void _startSimulatedTelemetry() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_connected && _telemetry != null) {
        _lastTelemetryAt = DateTime.now();
        final current = _telemetry!;
        final deltaP = (DateTime.now().second % 5 - 2) * 1.5;
        final newPvP = (current.pvP + deltaP).clamp(280.0, 420.0);
        final newBatV = (current.batV + (DateTime.now().second % 2 == 0 ? 0.01 : -0.01)).clamp(13.6, 14.4);
        final newBatI = (current.batI + (deltaP / 14.0)).clamp(10.0, 25.0);

        _telemetry = Telemetry(
          status: current.status,
          state: current.state,
          stateName: current.stateName,
          fault: current.fault,
          faultName: current.faultName,
          pvV: 36.2 + (DateTime.now().second % 3) * 0.1,
          pvI: newPvP / 36.2,
          pvP: newPvP,
          batV: newBatV,
          batI: newBatI,
          batP: newBatV * newBatI,
          soc: current.soc,
          duty: current.duty,
          vset: current.vset,
          iset: current.iset,
          mpptV: current.mpptV,
          voc: current.voc,
          energyWh: current.energyWh + 0.35,
          chargeAh: current.chargeAh + 0.02,
          chgTimeS: current.chgTimeS + 3,
          peakP: current.peakP,
          batVmin: current.batVmin,
          batVmax: current.batVmax,
          day: current.day,
          uptimeS: current.uptimeS + 3,
          faultCount: current.faultCount,
          lastFault: current.lastFault,
          pvLost: current.pvLost,
          mpptRestarts: current.mpptRestarts,
          sweepCount: current.sweepCount,
          sweepState: current.sweepState,
          sweepStateName: current.sweepStateName,
          sweepV: current.sweepV,
          sweepP: current.sweepP,
          actVcv: current.actVcv,
          actVhold: current.actVhold,
          actVrecharge: current.actVrecharge,
          actVlow: current.actVlow,
          actIlim: current.actIlim,
          actIstop: current.actIstop,
          imax: current.imax,
          lastCmd: current.lastCmd,
          lastCmdName: current.lastCmdName,
          cmdResult: current.cmdResult,
          cmdResultName: current.cmdResultName,
          fw: current.fw,
          fwNum: current.fwNum,
          map: current.map,
          serial: current.serial,
          chargerOn: current.chargerOn,
          converterOn: current.converterOn,
          tracking: current.tracking,
          ccLoop: current.ccLoop,
          pending: current.pending,
          menuOpen: current.menuOpen,
          batPresent: current.batPresent,
        );
        notifyListeners();
      }
    });
  }

  @override
  Future<void> startScan() async {
    _scanning = true;
    _lastError = '';
    _statusText = 'Scanning for BLE devices...';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _devices = [
      const BleDeviceInfo(
        id: '24:6F:28:B4:9C:12',
        name: 'MPPT-ESP32',
        rssi: -54,
        isMppt: true,
      ),
      const BleDeviceInfo(
        id: 'A0:B1:C2:D3:E4:F5',
        name: 'ESP32_BLE_Sensor',
        rssi: -78,
        isMppt: false,
      ),
    ];
    _scanning = false;
    _statusText = 'Scan complete. Found ${_devices.length} devices.';
    notifyListeners();
  }

  @override
  Future<void> connectById(String deviceId) async {
    _connecting = true;
    _statusText = 'Connecting to $deviceId...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    _connected = true;
    _connecting = false;
    _statusText = 'Connected to MPPT-ESP32';
    _lastTelemetryAt = DateTime.now();
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _statusText = 'Disconnected';
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    _statusText = 'Refreshing telemetry...';
    _lastTelemetryAt = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 300));
    _statusText = 'Connected to MPPT-ESP32';
    notifyListeners();
  }

  @override
  Future<void> sendCommand(Map<String, dynamic> cmd) async {
    final command = cmd['cmd']?.toString();
    if (_telemetry == null) return;
    final current = _telemetry!;

    if (command == 'chargeron') {
      _telemetry = _cloneTelemetry(current, chargerOn: true, converterOn: true, tracking: true);
    } else if (command == 'chargeroff') {
      _telemetry = _cloneTelemetry(current, chargerOn: false, converterOn: false, tracking: false);
    } else if (command == 'clearfault') {
      _telemetry = _cloneTelemetry(current, fault: 0, faultName: 'None', faultCount: 0);
    } else if (command == 'sweep') {
      _telemetry = _cloneTelemetry(current, sweepStateName: 'Sweeping...');
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      if (_telemetry != null) {
        _telemetry = _cloneTelemetry(_telemetry!, sweepStateName: 'Complete');
      }
    }
    notifyListeners();
  }

  @override
  Future<String> applySettings({
    required int chem,
    required int capacity,
    required int ichg,
    required int vcv,
    required int vhold,
    required int vrecharge,
    required int vlow,
  }) async {
    final chemNames = ['Lead-acid', 'Li-ion 3S', 'LiPo 3S', 'LiFePO4 4S', 'Custom'];
    _holding = HoldingSettings(
      chem: chem,
      chemName: chem < chemNames.length ? chemNames[chem] : 'Custom',
      capacity: capacity,
      ichg: ichg,
      ichgA: ichg / 100.0,
      vcv: vcv,
      vcvV: vcv / 100.0,
      vhold: vhold,
      vholdV: vhold / 100.0,
      vrecharge: vrecharge,
      vrechargeV: vrecharge / 100.0,
      vlow: vlow,
      vlowV: vlow / 100.0,
    );
    notifyListeners();
    return 'Settings successfully applied to MPPT-ESP32!';
  }

  Telemetry _cloneTelemetry(Telemetry c, {
    bool? chargerOn,
    bool? converterOn,
    bool? tracking,
    int? fault,
    String? faultName,
    int? faultCount,
    String? sweepStateName,
  }) {
    return Telemetry(
      status: c.status,
      state: c.state,
      stateName: c.stateName,
      fault: fault ?? c.fault,
      faultName: faultName ?? c.faultName,
      pvV: c.pvV,
      pvI: c.pvI,
      pvP: c.pvP,
      batV: c.batV,
      batI: c.batI,
      batP: c.batP,
      soc: c.soc,
      duty: c.duty,
      vset: c.vset,
      iset: c.iset,
      mpptV: c.mpptV,
      voc: c.voc,
      energyWh: c.energyWh,
      chargeAh: c.chargeAh,
      chgTimeS: c.chgTimeS,
      peakP: c.peakP,
      batVmin: c.batVmin,
      batVmax: c.batVmax,
      day: c.day,
      uptimeS: c.uptimeS,
      faultCount: faultCount ?? c.faultCount,
      lastFault: c.lastFault,
      pvLost: c.pvLost,
      mpptRestarts: c.mpptRestarts,
      sweepCount: c.sweepCount,
      sweepState: c.sweepState,
      sweepStateName: sweepStateName ?? c.sweepStateName,
      sweepV: c.sweepV,
      sweepP: c.sweepP,
      actVcv: c.actVcv,
      actVhold: c.actVhold,
      actVrecharge: c.actVrecharge,
      actVlow: c.actVlow,
      actIlim: c.actIlim,
      actIstop: c.actIstop,
      imax: c.imax,
      lastCmd: c.lastCmd,
      lastCmdName: c.lastCmdName,
      cmdResult: c.cmdResult,
      cmdResultName: c.cmdResultName,
      fw: c.fw,
      fwNum: c.fwNum,
      map: c.map,
      serial: c.serial,
      chargerOn: chargerOn ?? c.chargerOn,
      converterOn: converterOn ?? c.converterOn,
      tracking: tracking ?? c.tracking,
      ccLoop: c.ccLoop,
      pending: c.pending,
      menuOpen: c.menuOpen,
      batPresent: c.batPresent,
    );
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
