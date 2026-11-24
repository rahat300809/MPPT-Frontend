class Telemetry {
  final double pvV;
  final double pvP;
  final double batV;
  final double batI;
  final double batP;
  final double energyWh;
  final double chargeAh;
  final double peakP;
  final String stateName;
  final String fw;
  final double actIlim;
  final double actVcv;
  final double actVhold;
  final double actVrecharge;
  final double actVlow;
  final bool chargerOn;
  final bool converterOn;
  final bool tracking;
  final int fault;
  final String faultName;
  final int faultCount;
  final String lastFault;
  final String sweepStateName;
  final double sweepV;
  final double sweepP;
  final String chargeTimeLabel;
  final double batVmin;
  final double batVmax;

  const Telemetry({
    this.pvV = 36.4,
    this.pvP = 320.5,
    this.batV = 13.8,
    this.batI = 15.2,
    this.batP = 210.0,
    this.energyWh = 1450.0,
    this.chargeAh = 98.4,
    this.peakP = 450.0,
    this.stateName = 'MPPT Bulk Charging',
    this.fw = 'v1.4.2',
    this.actIlim = 25.0,
    this.actVcv = 14.4,
    this.actVhold = 13.6,
    this.actVrecharge = 13.0,
    this.actVlow = 10.8,
    this.chargerOn = true,
    this.converterOn = true,
    this.tracking = true,
    this.fault = 0,
    this.faultName = 'None',
    this.faultCount = 0,
    this.lastFault = 'None',
    this.sweepStateName = 'Ready',
    this.sweepV = 35.8,
    this.sweepP = 318.0,
    this.chargeTimeLabel = '4h 15m',
    this.batVmin = 12.4,
    this.batVmax = 14.4,
  });
}

class HoldingSettings {
  final int chem;
  final int capacity;
  final double ichgA;
  final double vcvV;
  final double vholdV;
  final double vrechargeV;
  final double vlowV;

  const HoldingSettings({
    this.chem = 0,
    this.capacity = 100,
    this.ichgA = 10.0,
    this.vcvV = 14.40,
    this.vholdV = 13.50,
    this.vrechargeV = 13.20,
    this.vlowV = 10.50,
  });

  String get chemName {
    switch (chem) {
      case 0:
        return 'Lead-acid';
      case 1:
        return 'Li-ion 3S';
      case 2:
        return 'LiPo 3S';
      case 3:
        return 'LiFePO4 4S';
      case 4:
        return 'Custom';
      default:
        return 'Custom';
    }
  }

  HoldingSettings copyWith({
    int? chem,
    int? capacity,
    double? ichgA,
    double? vcvV,
    double? vholdV,
    double? vrechargeV,
    double? vlowV,
  }) {
    return HoldingSettings(
      chem: chem ?? this.chem,
      capacity: capacity ?? this.capacity,
      ichgA: ichgA ?? this.ichgA,
      vcvV: vcvV ?? this.vcvV,
      vholdV: vholdV ?? this.vholdV,
      vrechargeV: vrechargeV ?? this.vrechargeV,
      vlowV: vlowV ?? this.vlowV,
    );
  }
}
