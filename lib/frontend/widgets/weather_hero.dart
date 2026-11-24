import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/models/telemetry.dart';
import '../../backend/weather/weather_models.dart';
import '../../backend/weather/weather_service.dart';
import '../theme/app_theme.dart';

/// HelioGlass-identical home hero: 3D house + weather sky + dashed callouts.
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
    with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _drift;
  late final AnimationController _rain;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // Slow shimmer so drifting clouds feel real (weather-app pace)
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(seconds: 48))
      ..repeat();
    _drift = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 9000))
      ..repeat(reverse: true);
    _rain = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 780))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherService>().refresh();
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _drift.dispose();
    _rain.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherService>();
    final kind = weather.displayKind;
    final night = kind.isNight;
    final t = widget.telemetry;
    // Night: deep blue-grey sky, house still readable (not crushed black)
    final canvas = night ? const Color(0xFF2A2E38) : const Color(0xFFF7F4EE);
    final energyKwh = ((t?.energyWh ?? 0) / 1000);
    final pvKw = (t?.pvP ?? 0) / 1000;
    // Same day house for every weather; night only darkens the scene
    const houseAsset = 'assets/helioglass_house_day.jpg';

    return SizedBox(
      height: 360,
      width: double.infinity,
      child: ColoredBox(
        color: canvas,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-width day house (night = softer dim only — no window lights)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: night
                          ? const ColorFilter.matrix(<double>[
                              // Lighter night: keep house shape + roof visible
                              0.55, 0.05, 0.08, 0, -6,
                              0.04, 0.52, 0.10, 0, -4,
                              0.06, 0.08, 0.62, 0, 4,
                              0, 0, 0, 1, 0,
                            ])
                          : const ColorFilter.matrix(<double>[
                              1, 0, 0, 0, 0,
                              0, 1, 0, 0, 0,
                              0, 0, 1, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: Image.asset(
                        houseAsset,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, 0.15),
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: canvas),
                      ),
                    ),
                    ColoredBox(color: _atmosphereTint(kind)),
                    if (night)
                      ColoredBox(
                        color: const Color(0xFF1A1F2A).withOpacity(0.22),
                      ),
                    // Soft top fade into same canvas color only
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            canvas,
                            canvas.withOpacity(0.55),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.14, 0.38],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cute sun only (Sunny / Afternoon / Dusk) — no temp under it
            if (kind.showsCuteSun)
              Positioned(
                right: kind == WeatherKind.afternoon ? 36 : 18,
                top: kind == WeatherKind.afternoon ? 28 : 10,
                child: AnimatedBuilder(
                  animation: _shimmer,
                  builder: (_, __) {
                    final bob = math.sin(_shimmer.value * math.pi * 2) * 2;
                    final sunSize =
                        kind == WeatherKind.afternoon ? 48.0 : 56.0;
                    return Transform.translate(
                      offset: Offset(0, bob),
                      child: Image.asset(
                        'assets/cute_sun.png',
                        width: sunSize,
                        height: sunSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        color: kind == WeatherKind.dusk
                            ? const Color(0xFFFF9F6B)
                            : null,
                        colorBlendMode: kind == WeatherKind.dusk
                            ? BlendMode.modulate
                            : null,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.wb_sunny,
                          size: sunSize,
                          color: Colors.amber.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Temp + humidity beside house (above Bat. V)
            Positioned(
              right: 12,
              bottom: 168,
              child: _HouseSideWeatherBadge(
                night: night,
                temperatureC: weather.live?.temperatureC,
                humidityPercent: weather.live?.humidityPercent,
              ),
            ),

            // Sky effects / clouds (drawn above cute sun for Afternoon tuck)
            AnimatedBuilder(
              animation: Listenable.merge([_shimmer, _drift, _rain]),
              builder: (_, __) => CustomPaint(
                painter: _HelioWeatherPainter(
                  kind: kind,
                  shimmer: _shimmer.value,
                  drift: _drift.value,
                  rain: _rain.value,
                  pulse: _pulse.value,
                  paintSun: false,
                ),
              ),
            ),

            // Same Rainy-style dotted lines for EVERY weather (drawn above sky/sun)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => CustomPaint(
                painter: _CalloutPainter(
                  night: night,
                  pulse: _pulse.value,
                  animateBeads: true,
                ),
              ),
            ),

            // Top-left Energy Produced (red)
            Positioned(
              left: 18,
              top: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Energy Produced',
                      style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626))),
                  Text(
                    '${energyKwh.toStringAsFixed(1)} kWh',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  Text(
                    '${pvKw.toStringAsFixed(2)} kW · ${kind.label}',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),

            // Bat. Voltage — plain red text (no card)
            Positioned(
              right: 14,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bat. Voltage',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  Text(
                    '${(t?.batV ?? 0).toStringAsFixed(2)} V',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _atmosphereTint(WeatherKind kind) {
    switch (kind) {
      case WeatherKind.sunny:
        return const Color(0x08FFE4A0);
      case WeatherKind.afternoon:
        return const Color(0x14F59E0B);
      case WeatherKind.cloudy:
        return const Color(0x1C64748B);
      case WeatherKind.rainy:
        return const Color(0x38334155);
      case WeatherKind.dusk:
        return const Color(0x28C25934);
      case WeatherKind.night:
        return const Color(0x281A2438);
    }
  }
}

/// Temperature + humidity in the empty space beside the house.
class _HouseSideWeatherBadge extends StatelessWidget {
  final bool night;
  final double? temperatureC;
  final double? humidityPercent;

  const _HouseSideWeatherBadge({
    required this.night,
    required this.temperatureC,
    required this.humidityPercent,
  });

  @override
  Widget build(BuildContext context) {
    final temp = temperatureC;
    final hum = humidityPercent;
    final fg = night ? Colors.white : const Color(0xFF44403C);
    final muted = night ? Colors.white70 : const Color(0xFF78716C);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          temp != null ? '${temp.toStringAsFixed(0)}°C' : '--°C',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.05,
            color: fg,
          ),
        ),
        Text(
          hum != null ? '${hum.toStringAsFixed(0)}% humidity' : '--% humidity',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
      ],
    );
  }
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

/// Rainy-style dashed energy/battery callouts — always high contrast.
class _CalloutPainter extends CustomPainter {
  final bool night;
  final double pulse;
  final bool animateBeads;

  _CalloutPainter({
    required this.night,
    required this.pulse,
    this.animateBeads = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Same day-house anchors (night no longer swaps image)
    final leftDot = Offset(w * 0.36, h * 0.54);
    final topElbow = Offset(leftDot.dx, h * 0.135);
    final topEnd = Offset(w * 0.31, h * 0.135);
    final topPts = [leftDot, topElbow, topEnd];

    final rightDot = Offset(w * 0.48, h * 0.58);
    final bottomTip = Offset(w * 0.72, h * 0.88);
    final bottomPts = [
      rightDot,
      Offset(rightDot.dx, h * 0.88),
      bottomTip,
    ];

    // Halo + core so lines stay visible on sunny sand AND rainy dark roof
    final halo = Paint()
      ..color = night
          ? const Color(0xCC000000)
          : const Color(0xCCFFFFFF)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final core = Paint()
      ..color = night
          ? const Color(0xF5F5F1E8)
          : const Color(0xF21C1917)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    _dashedPolyline(canvas, topPts, halo);
    _dashedPolyline(canvas, topPts, core);
    _dashedPolyline(canvas, bottomPts, halo);
    _dashedPolyline(canvas, bottomPts, core);

    // Arrows: top toward Energy label (left), bottom toward Bat. Voltage (right)
    _arrow(canvas, topEnd, const Offset(-1, 0), core.color);
    _arrow(canvas, bottomTip, const Offset(1, 0), core.color);

    for (final pt in [leftDot, rightDot]) {
      final haloR = 5.5 + pulse * 4.5;
      canvas.drawCircle(
        pt,
        haloR,
        Paint()
          ..color =
              const Color(0xFFEA8C2E).withOpacity((1 - pulse) * 0.45),
      );
      canvas.drawCircle(pt, 5.2, Paint()..color = core.color);
      canvas.drawCircle(pt, 4, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 2.3, Paint()..color = const Color(0xFFEA8C2E));
    }

    if (animateBeads) {
      // Two beads per path so flow clearly reaches the tip every cycle
      _bead(canvas, topPts, pulse, const Color(0xFFEA8C2E));
      _bead(canvas, topPts, (pulse + 0.5) % 1.0, const Color(0xFFEA8C2E));
      _bead(canvas, bottomPts, pulse, const Color(0xFF22C55E));
      _bead(
          canvas, bottomPts, (pulse + 0.5) % 1.0, const Color(0xFF22C55E));
    }
  }

  void _arrow(Canvas canvas, Offset tip, Offset dir, Color color) {
    final n = Offset(-dir.dy, dir.dx);
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip, tip + dir * -1 + n * 3.5 + dir * 5, p);
    canvas.drawLine(tip, tip + dir * -1 - n * 3.5 + dir * 5, p);
  }

  void _dashedPolyline(Canvas canvas, List<Offset> pts, Paint paint) {
    const dash = 9.0;
    const gap = 6.0;
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final dist = (b - a).distance;
      if (dist < 0.1) continue;
      final dir = (b - a) / dist;
      var drawn = 0.0;
      var on = true;
      while (drawn < dist) {
        final len = math.min(on ? dash : gap, dist - drawn);
        final p0 = a + dir * drawn;
        final p1 = a + dir * (drawn + len);
        if (on) canvas.drawLine(p0, p1, paint);
        drawn += len;
        on = !on;
      }
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

    // Ease so the bead clearly arrives at the arrow tip (not stuck mid-line)
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

    canvas.drawCircle(
        pos, 6.0, Paint()..color = color.withOpacity(0.30));
    canvas.drawCircle(pos, 3.0, Paint()..color = color);
    canvas.drawCircle(pos, 1.3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CalloutPainter old) =>
      old.night != night ||
      old.pulse != pulse ||
      old.animateBeads != animateBeads;
}

class _HelioWeatherPainter extends CustomPainter {
  final WeatherKind kind;
  final double shimmer;
  final double drift;
  final double rain;
  final double pulse;
  final bool paintSun;

  _HelioWeatherPainter({
    required this.kind,
    required this.shimmer,
    required this.drift,
    required this.rain,
    required this.pulse,
    this.paintSun = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roof = Offset(w * 0.38, h * 0.54);
    final sky = Offset(w * 0.84, h * 0.115);

    switch (kind) {
      case WeatherKind.sunny:
        // Cute sun is a Flutter Image overlay; here only soft rays + white clouds
        if (paintSun) {
          _sunRays(canvas, size, sky, roof, 0.95);
          _sun(canvas, sky, 13, shimmer, 0.95);
        } else {
          _sunRays(canvas, size, sky, roof, 0.45);
        }
        _driftClouds(
          canvas,
          size,
          count: 3,
          yBase: 0.10,
          fill: const Color(0xF2FFFFFF),
          speed: 0.35,
        );
        break;
      case WeatherKind.afternoon:
        // Soft shade + white cloud so cute sun looks tucked under
        final a = Offset(w * 0.80, h * 0.14);
        if (paintSun) {
          _sunRays(canvas, size, a, roof.translate(-w * 0.02, h * 0.02), 0.55,
              gold: const Color(0xFFFBBF68));
          _sun(canvas, a, 12, shimmer, 0.7,
              mid: const Color(0xFFFDE09B), halo: const Color(0xFFF6AD55));
        }
        _driftClouds(
          canvas,
          size,
          count: 2,
          yBase: 0.18,
          fill: const Color(0xB8C4B8A8),
          speed: 0.22,
          scale: 1.05,
        );
        final coverX = a.dx - 6 + math.sin(drift * math.pi * 2) * 10;
        _cloud(canvas, Offset(coverX, a.dy + 10), 1.2, const Color(0xF5FFFFFF));
        _cloud(canvas, Offset(coverX + 18, a.dy + 14), 0.9,
            const Color(0xE8F8F4EE));
        break;
      case WeatherKind.cloudy:
        // White + dark clouds floating across the sky (no clear sun)
        canvas.drawRect(
          Offset.zero & Size(w, h * 0.40),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, h * 0.40),
              [const Color(0x2294A3B8), Colors.transparent],
            ),
        );
        _driftClouds(
          canvas,
          size,
          count: 3,
          yBase: 0.08,
          fill: const Color(0xE63A404B),
          speed: 0.28,
          scale: 1.15,
        );
        _driftClouds(
          canvas,
          size,
          count: 3,
          yBase: 0.14,
          fill: const Color(0xF2FFFFFF),
          speed: 0.38,
          scale: 0.95,
          phase: 0.33,
        );
        break;
      case WeatherKind.rainy:
        canvas.drawRect(
          Offset.zero & Size(w, h * 0.52),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, h * 0.52),
              [const Color(0x2E334155), Colors.transparent],
            ),
        );
        _cloud(canvas, sky.translate(-18 + (drift - 0.5) * 10, 2), 1.02,
            const Color(0xDE64748B));
        _cloud(canvas, sky.translate(-4 - (drift - 0.5) * 5, 8), 0.92,
            const Color(0xEB94A3B8));
        _paintRain(canvas, size);
        break;
      case WeatherKind.dusk:
        // Warm sky only — cute sun overlay; no clouds
        canvas.drawRect(
          Offset.zero & Size(w, h * 0.42),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, h * 0.42),
              [
                const Color(0x28EA580C),
                const Color(0x14F59E0B),
                Colors.transparent,
              ],
              [0, 0.45, 1],
            ),
        );
        if (paintSun) {
          final d = Offset(w * 0.83, h * 0.132);
          _sunRays(canvas, size, d, roof, 0.55,
              gold: const Color(0xFFFDA4AF),
              warmColor: const Color(0xFFFFEDD5));
          _sun(canvas, d, 11.5, shimmer, 0.7,
              mid: const Color(0xFFFDBA74),
              halo: const Color(0xFFFB7185),
              warm: const Color(0xFFEA580C));
        }
        break;
      case WeatherKind.night:
        final moon = Offset(w * 0.84, h * 0.115);
        canvas.drawCircle(
          moon,
          32,
          Paint()
            ..shader = ui.Gradient.radial(
              moon,
              32,
              [const Color(0x32CBD5E1), Colors.transparent],
            ),
        );
        canvas.drawCircle(moon, 10.5, Paint()..color = const Color(0xFFF8FAFC));
        canvas.drawCircle(
          moon.translate(4.8, -2.8),
          9,
          Paint()..color = const Color(0xFF334155),
        );
        final stars = [
          Offset(w * 0.68, h * 0.08),
          Offset(w * 0.74, h * 0.16),
          Offset(w * 0.90, h * 0.07),
          Offset(w * 0.92, h * 0.17),
        ];
        for (var i = 0; i < stars.length; i++) {
          final twinkle =
              0.35 + 0.65 * ((math.sin(pulse * math.pi * 2 + i * 1.6) + 1) / 2);
          canvas.drawCircle(
            stars[i],
            1.4,
            Paint()
              ..color = const Color(0xFFFDE68A).withOpacity(twinkle),
          );
        }
        break;
    }
  }

  void _sun(
    Canvas canvas,
    Offset c,
    double r,
    double phase,
    double intensity, {
    Color mid = const Color(0xFFFFF1B8),
    Color halo = const Color(0xFFFCD34D),
    Color warm = const Color(0xFFF59E0B),
  }) {
    final breathe = 1 + 0.06 * math.sin(phase * math.pi * 2);
    canvas.drawCircle(
      c,
      r * 5.2 * breathe,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r * 5.2 * breathe,
          [
            mid.withOpacity(0.34 * intensity),
            halo.withOpacity(0.14 * intensity),
            warm.withOpacity(0.04 * intensity),
            Colors.transparent,
          ],
          [0.0, 0.35, 0.7, 1.0],
        ),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-r * 0.16, -r * 0.16),
          r * 1.15,
          [Colors.white, mid, halo.withOpacity(0.88)],
          [0.0, 0.55, 1.0],
        ),
    );
  }

  void _sunRays(
    Canvas canvas,
    Size size,
    Offset sun,
    Offset roof,
    double intensity, {
    Color warmColor = const Color(0xFFFFFBF0),
    Color gold = const Color(0xFFFDE08D),
  }) {
    final maxA = 0.14 * intensity.clamp(0.15, 1.0);
    final wave = 0.86 + 0.14 * math.sin(shimmer * math.pi * 2);
    final cone = Path()
      ..moveTo(sun.dx - 10, sun.dy - 2)
      ..lineTo(sun.dx + 8, sun.dy + 12)
      ..lineTo(roof.dx + size.width * 0.24, roof.dy + size.height * 0.1)
      ..lineTo(roof.dx - size.width * 0.18, roof.dy - size.height * 0.04)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = ui.Gradient.linear(
          sun,
          Offset(roof.dx - size.width * 0.05, roof.dy + size.height * 0.08),
          [
            warmColor.withOpacity(maxA * 1.05 * wave),
            gold.withOpacity(maxA * 0.65 * wave),
            warmColor.withOpacity(maxA * 0.24 * wave),
            Colors.transparent,
          ],
          [0, 0.35, 0.72, 1],
        ),
    );
    canvas.drawCircle(
      roof,
      size.width * 0.22,
      Paint()
        ..shader = ui.Gradient.radial(
          roof,
          size.width * 0.22,
          [
            warmColor.withOpacity(maxA * 0.95 * wave),
            gold.withOpacity(maxA * 0.35 * wave),
            Colors.transparent,
          ],
          [0.0, 0.45, 1.0],
        ),
    );
  }

  void _cloud(Canvas canvas, Offset c, double scale, Color fill) {
    final r = 12.0 * scale;
    final p = Paint()..color = fill;
    canvas.drawCircle(c.translate(-r, r * 0.18), r, p);
    canvas.drawCircle(c.translate(-r * 0.1, -r * 0.12), r * 1.25, p);
    canvas.drawCircle(c.translate(r * 0.9, r * 0.15), r, p);
    canvas.drawCircle(c.translate(r * 1.55, r * 0.32), r * 0.75, p);
  }

  /// Clouds that loop across the sky (left → right).
  void _driftClouds(
    Canvas canvas,
    Size size, {
    required int count,
    required double yBase,
    required Color fill,
    double speed = 1.0,
    double scale = 1.0,
    double phase = 0.0,
  }) {
    for (var i = 0; i < count; i++) {
      // Use shimmer (forward loop) so clouds keep flying one way
      final t = (shimmer * speed + phase + i / count) % 1.0;
      final x = -size.width * 0.2 + t * size.width * 1.4;
      final y = size.height * (yBase + (i % 3) * 0.045);
      final s = scale * (0.85 + (i % 3) * 0.12);
      _cloud(canvas, Offset(x, y), s, fill);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    const count = 16;
    for (var i = 0; i < count; i++) {
      final t = (rain + i * 0.17) % 1.0;
      final startX = size.width * (0.20 + (i / count) * 0.72);
      final x = startX - t * 34;
      final y = size.height * (0.16 + t * 0.56);
      final len = 10.0 + (i % 3) * 3;
      paint.color =
          const Color(0x94475569).withOpacity((1 - t * 0.45) * 0.78);
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HelioWeatherPainter old) =>
      old.kind != kind ||
      old.shimmer != shimmer ||
      old.drift != drift ||
      old.rain != rain ||
      old.pulse != pulse ||
      old.paintSun != paintSun;
}
