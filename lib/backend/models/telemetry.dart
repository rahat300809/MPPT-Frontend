class Telemetry {
  final int status;
  final int state;
  final String stateName;
  final int fault;
  final String faultName;
  final double pvV, pvI, pvP;
  final double batV, batI, batP;
  final int soc;
  final double duty, vset, iset, mpptV, voc;
  final double energyWh, chargeAh, peakP;
  final int chgTimeS;
  final double batVmin, batVmax;
  final int day, uptimeS;
  final int faultCount, lastFault, pvLost, mpptRestarts;
  final int sweepCount, sweepState;
  final String sweepStateName;
  final double sweepV, sweepP;
  final double actVcv, actVhold, actVrecharge, actVlow;
  final double actIlim, actIstop, imax;
  final int lastCmd, cmdResult;
  final String lastCmdName, cmdResultName;
  final String fw;
  final int fwNum, map;
  final int serial;
  final bool chargerOn, converterOn, tracking, ccLoop;
  final bool pending, menuOpen, batPresent;

  const Telemetry({
    required this.status,
    required this.state,
    required this.stateName,
    required this.fault,
    required this.faultName,
    required this.pvV,
    required this.pvI,
    required this.pvP,
    required this.batV,
    required this.batI,
    required this.batP,
    required this.soc,
    required this.duty,
    required this.vset,
    required this.iset,
    required this.mpptV,
    required this.voc,
    required this.energyWh,
    required this.chargeAh,
    required this.chgTimeS,
    required this.peakP,
    required this.batVmin,
    required this.batVmax,
    required this.day,
    required this.uptimeS,
    required this.faultCount,
    required this.lastFault,
    required this.pvLost,
    required this.mpptRestarts,
    required this.sweepCount,
    required this.sweepState,
    required this.sweepStateName,
    required this.sweepV,
    required this.sweepP,
    required this.actVcv,
    required this.actVhold,
    required this.actVrecharge,
    required this.actVlow,
    required this.actIlim,
    required this.actIstop,
    required this.imax,
    required this.lastCmd,
    required this.lastCmdName,
    required this.cmdResult,
    required this.cmdResultName,
    required this.fw,
    required this.fwNum,
    required this.map,
    required this.serial,
    required this.chargerOn,
    required this.converterOn,
    required this.tracking,
    required this.ccLoop,
    required this.pending,
    required this.menuOpen,
    required this.batPresent,
  });

  factory Telemetry.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    int i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    bool b(dynamic v) => v == true || v == 1 || v == 'true';
    return Telemetry(
      status: i(j['status']),
      state: i(j['state']),
      stateName: '${j['stateName'] ?? '-'}',
      fault: i(j['fault']),
      faultName: '${j['faultName'] ?? '-'}',
      pvV: d(j['pvV']),
      pvI: d(j['pvI']),
      pvP: d(j['pvP']),
      batV: d(j['batV']),
      batI: d(j['batI']),
      batP: d(j['batP']),
      soc: i(j['soc']),
      duty: d(j['duty']),
      vset: d(j['vset']),
      iset: d(j['iset']),
      mpptV: d(j['mpptV']),
      voc: d(j['voc']),
      energyWh: d(j['energyWh']),
      chargeAh: d(j['chargeAh']),
      chgTimeS: i(j['chgTimeS']),
      peakP: d(j['peakP']),
      batVmin: d(j['batVmin']),
      batVmax: d(j['batVmax']),
      day: i(j['day']),
      uptimeS: i(j['uptimeS']),
      faultCount: i(j['faultCount']),
      lastFault: i(j['lastFault']),
      pvLost: i(j['pvLost']),
      mpptRestarts: i(j['mpptRestarts']),
      sweepCount: i(j['sweepCount']),
      sweepState: i(j['sweepState']),
      sweepStateName: '${j['sweepStateName'] ?? '-'}',
      sweepV: d(j['sweepV']),
      sweepP: d(j['sweepP']),
      actVcv: d(j['actVcv']),
      actVhold: d(j['actVhold']),
      actVrecharge: d(j['actVrecharge']),
      actVlow: d(j['actVlow']),
      actIlim: d(j['actIlim']),
      actIstop: d(j['actIstop']),
      imax: d(j['imax']),
      lastCmd: i(j['lastCmd']),
      lastCmdName: '${j['lastCmdName'] ?? '-'}',
      cmdResult: i(j['cmdResult']),
      cmdResultName: '${j['cmdResultName'] ?? '-'}',
      fw: '${j['fw'] ?? '-'}',
      fwNum: i(j['fwNum']),
      map: i(j['map']),
      serial: i(j['serial']),
      chargerOn: b(j['chargerOn']),
      converterOn: b(j['converterOn']),
      tracking: b(j['tracking']),
      ccLoop: b(j['ccLoop']),
      pending: b(j['pending']),
      menuOpen: b(j['menuOpen']),
      batPresent: b(j['batPresent']),
    );
  }

  String get loopLabel {
    if (tracking) return 'MPPT';
    if (ccLoop) return 'CC';
    if (converterOn) return 'CV';
    return '-';
  }

  String get chargeTimeLabel {
    final h = chgTimeS ~/ 3600;
    final m = (chgTimeS % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class HoldingSettings {
  final int chem;
  final String chemName;
  final int capacity;
  final int ichg;
  final double ichgA;
  final int vcv, vhold, vrecharge, vlow;
  final double vcvV, vholdV, vrechargeV, vlowV;

  const HoldingSettings({
    required this.chem,
    required this.chemName,
    required this.capacity,
    required this.ichg,
    required this.ichgA,
    required this.vcv,
    required this.vcvV,
    required this.vhold,
    required this.vholdV,
    required this.vrecharge,
    required this.vrechargeV,
    required this.vlow,
    required this.vlowV,
  });

  factory HoldingSettings.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    int i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    return HoldingSettings(
      chem: i(j['chem']),
      chemName: '${j['chemName'] ?? '-'}',
      capacity: i(j['capacity']),
      ichg: i(j['ichg']),
      ichgA: d(j['ichgA']),
      vcv: i(j['vcv']),
      vcvV: d(j['vcvV']),
      vhold: i(j['vhold']),
      vholdV: d(j['vholdV']),
      vrecharge: i(j['vrecharge']),
      vrechargeV: d(j['vrechargeV']),
      vlow: i(j['vlow']),
      vlowV: d(j['vlowV']),
    );
  }
}
