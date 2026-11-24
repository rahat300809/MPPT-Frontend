import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/models/telemetry.dart';
import '../../backend/mppt_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int chem = 0;
  double capacityAh = 100;
  double maxCurrentA = 10;
  final vcvCtrl = TextEditingController(text: '14.40');
  final vholdCtrl = TextEditingController(text: '13.50');
  final vrchCtrl = TextEditingController(text: '13.20');
  final vlowCtrl = TextEditingController(text: '10.50');
  bool dirty = false;
  bool synced = false;
  bool syncing = false;

  static const chems = [
    'Lead-acid',
    'Li-ion 3S',
    'LiPo 3S',
    'LiFePO4 4S',
    'Custom',
  ];

  // Match STM32 Settings.h / Modbus hold limits (so Apply won't return Invalid).
  static const double _capMin = 5;
  static const double _capMax = 500;
  static const double _iMin = 1.0;
  static const double _iHwMax = 40.0;
  static const double _vCvMin = 6.0;
  static const double _vCvMax = 16.0;
  static const double _vLowMin = 3.0;
  static const double _vGapMin = 0.50;
  static const double _vHoldGap = 0.30;
  static const double _vRechGap = 0.20;

  /// Chemistry max C-rate % (Lead-acid 0.2C; others 1.0C).
  static int _cRatePct(int chem) => chem == 0 ? 20 : 100;

  double _chemMaxA(int c, double ah) {
    final a = ah * _cRatePct(c) / 100.0;
    return a.clamp(_iMin, _iHwMax);
  }

  double _snapHalfAmp(double a) => (a * 2).round() / 2.0;

  void _clampCurrentForChem() {
    final imax = _chemMaxA(chem, capacityAh);
    maxCurrentA = _snapHalfAmp(maxCurrentA.clamp(_iMin, imax));
  }

  void _applyHolding(HoldingSettings h) {
    chem = h.chem.clamp(0, 4);
    capacityAh = h.capacity.toDouble().clamp(_capMin, _capMax);
    final imax = _chemMaxA(chem, capacityAh);
    maxCurrentA = _snapHalfAmp(h.ichgA.clamp(_iMin, imax));
    vcvCtrl.text = h.vcvV.toStringAsFixed(2);
    vholdCtrl.text = h.vholdV.toStringAsFixed(2);
    vrchCtrl.text = h.vrechargeV.toStringAsFixed(2);
    vlowCtrl.text = h.vlowV.toStringAsFixed(2);
  }

  /// Same relative rules as STM32 Settings_Sanitize (custom_* voltages).
  void _sanitizeVoltagesInFields() {
    var vcv = (double.tryParse(vcvCtrl.text) ?? 14.4).clamp(_vCvMin, _vCvMax);
    var vlow = double.tryParse(vlowCtrl.text) ?? 10.5;
    if (vlow < _vLowMin || vlow + _vGapMin > vcv) {
      vlow = (vcv - _vGapMin).clamp(_vLowMin, vcv - _vGapMin);
    }
    var vhold = double.tryParse(vholdCtrl.text) ?? 0;
    if (vhold != 0 &&
        (vhold < vlow + _vHoldGap || vhold > vcv)) {
      vhold = 0;
    }
    final vrchMax =
        vhold > 0 ? vhold - _vRechGap : vcv - _vGapMin;
    var vrch = double.tryParse(vrchCtrl.text) ?? 13.2;
    if (vrch > vrchMax) vrch = vrchMax;
    if (vrch < vlow) vrch = vlow;
    vcvCtrl.text = vcv.toStringAsFixed(2);
    vholdCtrl.text = vhold.toStringAsFixed(2);
    vrchCtrl.text = vrch.toStringAsFixed(2);
    vlowCtrl.text = vlow.toStringAsFixed(2);
  }

  Future<void> _syncNow(MpptBackend ble) async {
    if (!ble.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to MPPT-ESP32 first')),
      );
      return;
    }
    setState(() => syncing = true);
    await ble.refresh();
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (ble.holding != null) break;
    }
    if (!mounted) return;
    if (ble.holding != null) {
      setState(() {
        _applyHolding(ble.holding!);
        dirty = false;
        synced = true;
        syncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synced — you can edit settings now')),
      );
    } else {
      setState(() => syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No holding data yet — try again')),
      );
    }
  }

  @override
  void dispose() {
    vcvCtrl.dispose();
    vholdCtrl.dispose();
    vrchCtrl.dispose();
    vlowCtrl.dispose();
    super.dispose();
  }

  int _voltRaw(TextEditingController c) =>
      ((double.tryParse(c.text) ?? 0) * 100).round();

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<MpptBackend>();
    final custom = chem == 4;
    final optionsOn = synced;
    final iMax = _chemMaxA(chem, capacityAh);

    return Column(
      children: [
        PageTitleBar(
          title: 'Settings',
          trailing: dirty
              ? Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Changed',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary)),
                )
              : null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: syncing ? null : () => _syncNow(ble),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.sync),
                  label: Text(
                    syncing ? 'Syncing…' : 'Sync Now',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                synced
                    ? 'Synced from MPPT. Edit below, then tap Apply.'
                    : 'Tap Sync Now first to load battery settings. Options stay locked until then.',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.onVariant),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: optionsOn ? 1 : 0.45,
                child: IgnorePointer(
                  ignoring: !optionsOn,
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chemistry & Limits',
                            style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Battery Type',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.surfaceLow,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: chem,
                              items: [
                                for (var i = 0; i < chems.length; i++)
                                  DropdownMenuItem(
                                      value: i, child: Text(chems[i])),
                              ],
                              onChanged: optionsOn
                                  ? (v) => setState(() {
                                        chem = v ?? 0;
                                        _clampCurrentForChem();
                                        dirty = true;
                                      })
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sliderRow(
                          label: 'Capacity',
                          valueLabel: '${capacityAh.round()} Ah',
                          value: capacityAh,
                          min: _capMin,
                          max: _capMax,
                          divisions: (_capMax - _capMin).round(),
                          enabled: optionsOn,
                          onChanged: (v) => setState(() {
                            capacityAh = v.roundToDouble();
                            _clampCurrentForChem();
                            dirty = true;
                          }),
                        ),
                        const SizedBox(height: 8),
                        _sliderRow(
                          label: 'Max Current',
                          valueLabel: '${maxCurrentA.toStringAsFixed(1)} A',
                          value: maxCurrentA.clamp(_iMin, iMax),
                          min: _iMin,
                          max: iMax,
                          divisions: ((iMax - _iMin) * 2).round().clamp(1, 1000),
                          enabled: optionsOn,
                          onChanged: (v) => setState(() {
                            maxCurrentA = _snapHalfAmp(v);
                            dirty = true;
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            chem == 0
                                ? 'Lead-acid max ${iMax.toStringAsFixed(1)} A (0.2C). Close LCD Setup before Apply.'
                                : 'Max ${iMax.toStringAsFixed(1)} A for this pack. Close LCD Setup before Apply.',
                            style: GoogleFonts.manrope(
                                fontSize: 11, color: AppColors.onVariant),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Target Voltages',
                            style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600)),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            custom
                                ? 'Custom: voltages editable, then Apply.'
                                : 'Preset: voltages locked (gray). Only Capacity & Max Current.',
                            style: GoogleFonts.manrope(
                                fontSize: 11, color: AppColors.onVariant),
                          ),
                        ),
                        _numField('CV Voltage (V)', vcvCtrl,
                            enabled: optionsOn && custom),
                        _numField('Hold Voltage (V)', vholdCtrl,
                            enabled: optionsOn && custom),
                        _numField('Recharge Voltage (V)', vrchCtrl,
                            enabled: optionsOn && custom),
                        _numField('Low Voltage (V)', vlowCtrl,
                            enabled: optionsOn && custom),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: optionsOn
                                ? () async {
                                    if (!await confirmAction(
                                        context,
                                        'Apply settings',
                                        'Write values to MPPT flash? Charger may restart.')) {
                                      return;
                                    }
                                    setState(() {
                                      capacityAh =
                                          capacityAh.clamp(_capMin, _capMax);
                                      _clampCurrentForChem();
                                      _sanitizeVoltagesInFields();
                                    });
                                    final msg = await ble.applySettings(
                                      chem: chem,
                                      capacity: capacityAh.round(),
                                      ichg: (maxCurrentA * 100).round(),
                                      vcv: _voltRaw(vcvCtrl),
                                      vhold: _voltRaw(vholdCtrl),
                                      vrecharge: _voltRaw(vrchCtrl),
                                      vlow: _voltRaw(vlowCtrl),
                                    );
                                    dirty = false;
                                    setState(() {});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(msg)),
                                      );
                                    }
                                  }
                                : null,
                            child: Text('Apply',
                                style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            Text(valueLabel,
                style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceHigh,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.12),
            disabledActiveTrackColor: Colors.grey.shade400,
            disabledInactiveTrackColor: Colors.grey.shade300,
            disabledThumbColor: Colors.grey.shade500,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  Widget _numField(String label, TextEditingController c,
      {required bool enabled}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: enabled ? (_) => setState(() => dirty = true) : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: enabled ? AppColors.surfaceLow : const Color(0xFFE8E8EE),
          labelStyle: TextStyle(
            color: enabled ? AppColors.onVariant : AppColors.outline,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        style: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w700,
          color: enabled ? AppColors.onSurface : Colors.grey.shade600,
        ),
      ),
    );
  }
}
