import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/mppt_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/weather_hero.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _askedHolding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ble = context.read<MpptBackend>();
    if (ble.connected && ble.holding == null && !_askedHolding) {
      _askedHolding = true;
      ble.refresh();
    }
    if (!ble.connected) {
      _askedHolding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<MpptBackend>();
    final t = ble.telemetry;
    final h = ble.holding;
    final chemLabel = (h?.chemName.isNotEmpty ?? false) && h!.chemName != '-'
        ? h.chemName
        : '—';
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ble.refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              children: [
                // HelioGlass-same house + weather hero
                WeatherHero(telemetry: t),
                const SizedBox(height: 14),

                // 4 metric blocks — uneven widths (solar/current smaller, bat V / today larger)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 10.0;
                      final w = constraints.maxWidth;
                      final rowH = (w - gap) * 0.42;
                      // Row1: solar ~42%, bat V ~58%
                      final solarW = (w - gap) * 0.42;
                      final batVW = (w - gap) * 0.58;
                      // Row2: today ~58%, bat I ~42%
                      final todayW = (w - gap) * 0.58;
                      final batIW = (w - gap) * 0.42;
                      return Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: solarW,
                                height: rowH,
                                child: _MetricSquare(
                                  icon: Icons.solar_power,
                                  title: 'Solar Power',
                                  primaryValue:
                                      (t?.pvP ?? 0).toStringAsFixed(1),
                                  primaryUnit: 'W',
                                  secondaryLabel: 'Voltage',
                                  secondaryValue:
                                      '${(t?.pvV ?? 0).toStringAsFixed(2)} V',
                                  emphasize: true,
                                ),
                              ),
                              const SizedBox(width: gap),
                              SizedBox(
                                width: batVW,
                                height: rowH,
                                child: _MetricSquare(
                                  icon: Icons.battery_charging_full,
                                  title: 'Bat. Voltage',
                                  primaryValue:
                                      (t?.batV ?? 0).toStringAsFixed(2),
                                  primaryUnit: 'V',
                                  secondaryLabel: 'Battery',
                                  secondaryValue: h == null
                                      ? '—'
                                      : '$chemLabel · ${h.capacity}Ah',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: gap),
                          Row(
                            children: [
                              SizedBox(
                                width: todayW,
                                height: rowH,
                                child: _MetricSquare(
                                  icon: Icons.bolt,
                                  title: 'Today Produced',
                                  primaryValue: ((t?.energyWh ?? 0) / 1000)
                                      .toStringAsFixed(3),
                                  primaryUnit: 'kWh',
                                  secondaryLabel: 'Energy',
                                ),
                              ),
                              const SizedBox(width: gap),
                              SizedBox(
                                width: batIW,
                                height: rowH,
                                child: _MetricSquare(
                                  icon: Icons.electric_meter,
                                  title: 'Bat. Current',
                                  primaryValue:
                                      (t?.batI ?? 0).toStringAsFixed(2),
                                  primaryUnit: 'A',
                                  secondaryLabel: 'Charge',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Status + charger controls (under the 4 blocks)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SoftCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: StatusPill(
                                    title: 'State',
                                    value: t?.stateName ?? '--',
                                    icon: Icons.check_circle)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: StatusPill(
                                    title: 'Battery',
                                    value: chemLabel,
                                    icon: Icons.battery_full)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: StatusPill(
                                    title: 'Charger',
                                    value: t == null
                                        ? '--'
                                        : (t.chargerOn ? 'ON' : 'OFF'),
                                    icon: Icons.power_settings_new)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                                child: StatusPill(
                                    title: 'Converter',
                                    value: t == null
                                        ? '--'
                                        : (t.converterOn ? 'RUNNING' : 'OFF'),
                                    icon: Icons.sync)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: StatusPill(
                                    title: 'MPPT Mode',
                                    value: t == null
                                        ? '--'
                                        : (t.tracking ? 'YES' : 'NO'),
                                    icon: Icons.bolt)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: StatusPill(
                                    title: 'System Fault',
                                    value: t?.faultName ?? '--',
                                    icon: Icons.shield,
                                    ok: (t?.fault ?? 0) == 0)),
                          ],
                        ),
                        if (ble.connected && (t?.fault ?? 0) != 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.badgeErrBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.error.withOpacity(0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fault detected',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        t?.faultName ?? 'Unknown fault',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      if ((t?.faultCount ?? 0) > 0)
                                        Text(
                                          'Count ${t!.faultCount} · last ${t.lastFault}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            color: AppColors.onVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => ble.sendCommand(
                                      {'cmd': 'clearfault'}),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Charger ON/OFF + MPPT Sweep (BLE live state)
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: !ble.connected
                                    ? null
                                    : () {
                                        final on = t?.chargerOn ?? false;
                                        ble.sendCommand({
                                          'cmd':
                                              on ? 'chargeroff' : 'chargeron',
                                        });
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: (t?.chargerOn ?? false)
                                      ? AppColors.secondary
                                      : AppColors.onVariant,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Icon(
                                  (t?.chargerOn ?? false)
                                      ? Icons.power_settings_new
                                      : Icons.power_off,
                                  size: 18,
                                ),
                                label: Text(
                                  (t?.chargerOn ?? false)
                                      ? 'Charger ON'
                                      : 'Charger OFF',
                                  style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: !ble.connected
                                    ? null
                                    : () =>
                                        ble.sendCommand({'cmd': 'sweep'}),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.mpptAccent,
                                  side: const BorderSide(
                                      color: AppColors.mpptAccent),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.timeline, size: 18),
                                label: Text(
                                  'MPPT Sweep',
                                  style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (ble.connected &&
                            (t?.sweepStateName.isNotEmpty ?? false) &&
                            t!.sweepStateName != '-') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Sweep: ${t.sweepStateName} · V ${t.sweepV.toStringAsFixed(1)} · P ${t.sweepP.toStringAsFixed(1)}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppColors.mpptAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (ble.lastError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(ble.lastError,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricSquare extends StatelessWidget {
  final IconData icon;
  final String title;
  final String primaryValue;
  final String primaryUnit;
  final String secondaryLabel;
  final String? secondaryValue;
  final bool emphasize;

  const _MetricSquare({
    required this.icon,
    required this.title,
    required this.primaryValue,
    required this.primaryUnit,
    required this.secondaryLabel,
    this.secondaryValue,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onVariant,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(flex: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              primaryValue,
              style: GoogleFonts.spaceGrotesk(
                fontSize: secondaryValue != null ? 24 : 28,
                fontWeight: FontWeight.w700,
                color: emphasize ? AppColors.primary : AppColors.onSurface,
                height: 1.0,
              ),
            ),
          ),
          Text(
            primaryUnit,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.primary : AppColors.onVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondaryLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppColors.onVariant,
            ),
          ),
          if (secondaryValue != null)
            Text(
              secondaryValue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
