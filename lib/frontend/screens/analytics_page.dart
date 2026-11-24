import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/mppt_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _updatedLabel(DateTime? at) {
    if (at == null) return 'No data yet';
    final sec = DateTime.now().difference(at).inSeconds;
    if (sec <= 0) return 'Updated just now';
    if (sec < 60) return 'Updated ${sec}s ago';
    final m = sec ~/ 60;
    if (m < 60) return 'Updated ${m}m ago';
    return 'Updated ${m ~/ 60}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<MpptBackend>();
    final t = ble.telemetry;
    final energyKwh = (t?.energyWh ?? 0) / 1000;
    final peak = t?.peakP ?? 0;
    final updated = _updatedLabel(ble.lastTelemetryAt);

    return Column(
      children: [
        // Analytics-only header (no Innosphere / BLE connected strip)
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              Text('Analytics',
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700, fontSize: 22)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.badgeOkBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: ble.connected
                            ? AppColors.primary
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(updated,
                        style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ble.connected
                                ? AppColors.primary
                                : AppColors.error)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pushNamed('/connect'),
                icon: Icon(
                  ble.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: ble.connected ? AppColors.primary : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ble.refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        Icons.bolt,
                        'Energy',
                        energyKwh.toStringAsFixed(3),
                        'kWh',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        Icons.autorenew,
                        'Charge',
                        (t?.chargeAh ?? 0).toStringAsFixed(1),
                        'Ah',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        Icons.bar_chart_rounded,
                        'Peak Power',
                        peak.toStringAsFixed(1),
                        'W',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        Icons.schedule,
                        'Charge Time',
                        t?.chargeTimeLabel ?? '--',
                        '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Battery (Today)',
                              style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.battery_full,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text('Nominal 12V',
                                    style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _minmaxCard(
                              Icons.arrow_downward,
                              'Vmin',
                              '${(t?.batVmin ?? 0).toStringAsFixed(2)} V',
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _minmaxCard(
                              Icons.arrow_upward,
                              'Vmax',
                              '${(t?.batVmax ?? 0).toStringAsFixed(2)} V',
                              AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, String unit) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 12, color: AppColors.onVariant)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700, fontSize: 20)),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(unit,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, color: AppColors.onVariant)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _minmaxCard(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.manrope(
                        fontSize: 11, color: AppColors.onVariant)),
                Text(value,
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
