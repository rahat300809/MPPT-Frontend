import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/models/telemetry.dart';
import '../../backend/weather/weather_models.dart';
import '../../backend/weather/weather_service.dart';
import '../theme/app_theme.dart';

/// Architectural sketch home hero layout with live telemetry overlays and animated power circuit
class WeatherHero extends StatefulWidget {
  final Telemetry? telemetry;

  const WeatherHero({
    super.key,
    required this.telemetry,
  });

  @override
  State<WeatherHero> createState() => _WeatherHeroState();
}

class _WeatherHeroState extends State<WeatherHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherService>().refresh();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherService>();
    final t = widget.telemetry;

    final energyWh = (t?.energyWh != null && (t?.energyWh ?? 0) > 0)
        ? (t!.energyWh)
        : 17.9;
    final loadWatts = (t?.loadP != null) ? t!.loadP : 17.9;
    final batVoltage = (t?.batV != null && (t?.batV ?? 0) > 0)
        ? t!.batV
        : 17.9;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardW = constraints.maxWidth;
          const cardH = 430.0;
          const imgAspect = 819.0 / 1024.0;
          var renderW = cardH * imgAspect;
          var renderH = cardH;
          if (renderW > cardW) {
            renderW = cardW;
            renderH = renderW / imgAspect;
          }
          final offsetX = (cardW - renderW) / 2;
          final offsetY = (cardH - renderH) / 2;

          return SizedBox(
            width: cardW,
            height: cardH,
            child: Stack(
              children: [
                // Centered Image + Overlays in exact image coordinate space
                Positioned(
                  left: offsetX,
                  top: offsetY,
                  width: renderW,
                  height: renderH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base clean illustration (exact artwork matching user's design)
                      Image.asset(
                        'assets/home_sketch_scene.png',
                        width: renderW,
                        height: renderH,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),

                      // 1. Bulb Glow Pulse (behind bulb in L 💡 A D)
                      Positioned(
                        left: renderW * (82.0 / 819.0) - 20,
                        top: renderH * (578.0 / 1024.0) - 20,
                        width: 40,
                        height: 40,
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFBBF24).withOpacity(
                                    (loadWatts > 0.5 ? 0.45 : 0.15) +
                                        0.15 * math.sin(_pulse.value * math.pi * 2),
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. Animated Circuit Beads Painter (traveling along the dashed lines)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => CustomPaint(
                          painter: _SketchBeadsPainter(
                            pulse: _pulse.value,
                            charging: (t?.batI ?? 0) > 0.05,
                            hasLoad: loadWatts > 0.5,
                          ),
                        ),
                      ),

                      // 3. Top Energy Produced Text (e.g. 17.9 Wh)
                      Positioned(
                        left: renderW * (60.0 / 819.0),
                        top: renderH * (96.0 / 1024.0),
                        width: renderW * (195.0 / 819.0),
                        height: renderH * (66.0 / 1024.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            energyWh >= 1000
                                ? '${(energyWh / 1000).toStringAsFixed(1)} kWh'
                                : '${energyWh.toStringAsFixed(1)} Wh',
                            style: GoogleFonts.bebasNeue(
                              fontSize: renderW * 0.072,
                              letterSpacing: 0.8,
                              height: 0.95,
                              color: const Color(0xFF1C1917),
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),

                      // 4. LOAD Value (under L 💡 A D)
                      Positioned(
                        left: renderW * (24.0 / 819.0),
                        top: renderH * (648.0 / 1024.0),
                        width: renderW * (145.0 / 819.0),
                        height: renderH * (66.0 / 1024.0),
                        child: Center(
                          child: Text(
                            loadWatts.toStringAsFixed(1),
                            style: GoogleFonts.orbitron(
                              fontSize: renderW * 0.054,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              height: 1.0,
                              color: const Color(0xFF1C1917),
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),

                      // 5. BATTERY Voltage Value (inside Battery box between + - and ⚡)
                      Positioned(
                        left: renderW * (616.0 / 819.0),
                        top: renderH * (726.0 / 1024.0),
                        width: renderW * (66.0 / 819.0),
                        height: renderH * (48.0 / 1024.0),
                        child: Center(
                          child: Text(
                            batVoltage.toStringAsFixed(1),
                            style: GoogleFonts.orbitron(
                              fontSize: renderW * 0.026,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              height: 1.0,
                              color: const Color(0xFF1C1917),
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Temperature / weather pill in top corner
                if (weather.live?.temperatureC != null)
                  Positioned(
                    right: 16,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${weather.live!.temperatureC.toStringAsFixed(0)}°C',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          if (weather.live?.humidityPercent != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '· ${weather.live!.humidityPercent.toStringAsFixed(0)}%',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Animated beads traveling along the dashed power flow lines of the sketch
class _SketchBeadsPainter extends CustomPainter {
  final double pulse;
  final bool charging;
  final bool hasLoad;

  _SketchBeadsPainter({
    required this.pulse,
    required this.charging,
    required this.hasLoad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Path 1: Top line -> elbow -> roof panel dot
    final path1 = [
      Offset(w * (261.0 / 819.0), h * (122.0 / 1024.0)),
      Offset(w * (335.0 / 819.0), h * (122.0 / 1024.0)),
      Offset(w * (335.0 / 819.0), h * (396.0 / 1024.0)),
    ];

    // 2. Path 2: Roof collector -> MPPT box top
    final path2 = [
      Offset(w * (405.0 / 819.0), h * (532.0 / 1024.0)),
      Offset(w * (405.0 / 819.0), h * (610.0 / 1024.0)),
    ];

    // 3. Path 3: MPPT left -> wall turn -> Load wire
    final path3 = [
      Offset(w * (380.0 / 819.0), h * (672.0 / 1024.0)),
      Offset(w * (275.0 / 819.0), h * (672.0 / 1024.0)),
      Offset(w * (220.0 / 819.0), h * (665.0 / 1024.0)),
    ];

    // 4. Path 4: MPPT right -> horizontal -> down into battery top
    final path4 = [
      Offset(w * (432.0 / 819.0), h * (628.0 / 1024.0)),
      Offset(w * (638.0 / 819.0), h * (628.0 / 1024.0)),
      Offset(w * (638.0 / 819.0), h * (665.0 / 1024.0)),
    ];

    // Pulsing dot on solar roof panel
    final roofDot = Offset(w * (335.0 / 819.0), h * (396.0 / 1024.0));
    final haloR = 4.0 + pulse * 3.5;
    canvas.drawCircle(
      roofDot,
      haloR,
      Paint()..color = const Color(0xFFF59E0B).withOpacity((1 - pulse) * 0.45),
    );
    canvas.drawCircle(roofDot, 3.2, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawCircle(roofDot, 1.8, Paint()..color = Colors.white);

    // Beads along paths
    _bead(canvas, path1, pulse, const Color(0xFFEA8C2E));
    _bead(canvas, path2, pulse, const Color(0xFFF59E0B));

    if (hasLoad) {
      _bead(canvas, path3, pulse, const Color(0xFFD97706));
    }
    if (charging) {
      _bead(canvas, path4, pulse, const Color(0xFF16A34A));
    } else {
      _bead(canvas, path4, pulse, const Color(0xFF38BDF8));
    }
  }

  void _bead(Canvas canvas, List<Offset> pts, double frac, Color color) {
    if (pts.length < 2) return;
    final lens = <double>[];
    var total = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      final d = (pts[i + 1] - pts[i]).distance;
      lens.add(d);
      total += d;
    }
    if (total < 1) return;

    final t = Curves.easeInOut.transform(frac.clamp(0.0, 1.0));
    var dist = total * t;
    var pos = pts.last;
    for (var i = 0; i < lens.length; i++) {
      final seg = lens[i];
      if (seg < 0.001) continue;
      if (dist <= seg) {
        pos = Offset.lerp(pts[i], pts[i + 1], dist / seg)!;
        break;
      }
      dist -= seg;
      if (i == lens.length - 1) pos = pts.last;
    }

    // Outer glow
    canvas.drawCircle(
      pos,
      5.0,
      Paint()..color = color.withOpacity(0.35),
    );
    // Core bead
    canvas.drawCircle(
      pos,
      3.0,
      Paint()..color = color,
    );
    // Center white spark
    canvas.drawCircle(
      pos,
      1.4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchBeadsPainter old) =>
      old.pulse != pulse ||
      old.charging != charging ||
      old.hasLoad != hasLoad;
}

/// Open weather chip grid (HelioGlass-style) kept visible under the blocks.
class WeatherOptionsCard extends StatelessWidget {
  const WeatherOptionsCard({super.key});

  IconData _icon(WeatherKind k) {
    switch (k) {
      case WeatherKind.sunny:
        return Icons.wb_sunny_outlined;
      case WeatherKind.afternoon:
        return Icons.wb_twilight;
      case WeatherKind.cloudy:
        return Icons.cloud_outlined;
      case WeatherKind.rainy:
        return Icons.water_drop_outlined;
      case WeatherKind.dusk:
        return Icons.nights_stay_outlined;
      case WeatherKind.night:
        return Icons.dark_mode_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherService>();
    final selected = weather.displayKind;
    final rows = [
      [WeatherKind.sunny, WeatherKind.afternoon, WeatherKind.cloudy],
      [WeatherKind.rainy, WeatherKind.dusk, WeatherKind.night],
    ];

    return SoftishCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weather & Light Effects',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      weather.isPreviewing
                          ? 'Preview mode · tap Live to use API'
                          : 'Live sky from your location',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.onVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (weather.loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    weather.setPreview(null);
                    weather.refresh();
                  },
                  icon: const Icon(Icons.my_location, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Live API',
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _WeatherChip(
                      kind: row[i],
                      icon: _icon(row[i]),
                      selected: selected == row[i] &&
                          (weather.isPreviewing ||
                              weather.live?.kind == row[i]),
                      onTap: () => weather.setPreview(row[i]),
                    ),
                  ),
                ],
              ],
            ),
            if (row != rows.last) const SizedBox(height: 8),
          ],
          if (weather.lastError.isNotEmpty && weather.live == null) ...[
            const SizedBox(height: 8),
            Text(weather.lastError,
                style: GoogleFonts.manrope(
                    fontSize: 11, color: AppColors.error)),
          ],
        ],
      ),
    );
  }
}

class SoftishCard extends StatelessWidget {
  final Widget child;
  const SoftishCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final WeatherKind kind;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _WeatherChip({
    required this.kind,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFEA8C2E);
    return Material(
      color: selected ? accent : AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? accent : AppColors.surfaceHigh,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15, color: selected ? Colors.white : accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  kind.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
