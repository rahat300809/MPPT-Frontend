import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/mppt_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class BatteryPage extends StatelessWidget {
  const BatteryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<MpptBackend>();
    final t = ble.telemetry;
    final h = ble.holding;
    final charging = (t?.batI ?? 0) > 0.05;
    return Column(
      children: [
        const PageTitleBar(title: 'Battery'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              SoftCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _GlossyBatteryBadge(
                        voltageText: t == null
                            ? '--'
                            : t.batV.toStringAsFixed(2),
                        charging: charging,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t?.stateName ?? '—',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: MetricChip(
                                label: 'Current',
                                value: (t?.batI ?? 0).toStringAsFixed(2),
                                unit: 'A')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: MetricChip(
                                label: 'Power',
                                value: (t?.batP ?? 0).toStringAsFixed(1),
                                unit: 'W')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w600, fontSize: 18)),
                    const SizedBox(height: 10),
                    _kv('Chemistry', h?.chemName ?? t?.fw ?? '—'),
                    _kv('Capacity', '${h?.capacity ?? '—'} Ah'),
                    _kv('Charge limit',
                        '${(h?.ichgA ?? t?.actIlim ?? 0).toStringAsFixed(2)} A'),
                    _kv('Active CV',
                        '${(t?.actVcv ?? 0).toStringAsFixed(2)} V'),
                    _kv('Active Hold',
                        '${(t?.actVhold ?? 0).toStringAsFixed(2)} V'),
                    _kv('Active Recharge',
                        '${(t?.actVrecharge ?? 0).toStringAsFixed(2)} V'),
                    _kv('Active Low',
                        '${(t?.actVlow ?? 0).toStringAsFixed(2)} V'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: GoogleFonts.manrope(fontSize: 14))),
          Text(v,
              style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Glossy green battery (like ref image) — center shows voltage, not SOC %.
class _GlossyBatteryBadge extends StatefulWidget {
  final String voltageText;
  final bool charging;

  const _GlossyBatteryBadge({
    required this.voltageText,
    required this.charging,
  });

  @override
  State<_GlossyBatteryBadge> createState() => _GlossyBatteryBadgeState();
}

class _GlossyBatteryBadgeState extends State<_GlossyBatteryBadge>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shimmer]),
      builder: (_, __) {
        final glow = 0.4 + 0.35 * _pulse.value;
        final scale = 1.0 + 0.04 * _pulse.value;
        final boltBob = (widget.charging ? 1 : 0.4) *
            (2.0 * (_pulse.value - 0.5)).abs();
        return Transform.scale(
          scale: scale,
          child: CustomPaint(
            painter: _BatteryShellPainter(
              glow: glow,
              shimmer: _shimmer.value,
            ),
            child: SizedBox(
              width: 200,
              height: 118,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -boltBob),
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 28,
                        color: Colors.white.withOpacity(
                            (0.75 + 0.25 * _pulse.value).clamp(0.0, 1.0)),
                      ),
                    ),
                    Text(
                      widget.voltageText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.65),
                            blurRadius: 12 + 6 * _pulse.value,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'V',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BatteryShellPainter extends CustomPainter {
  final double glow;
  final double shimmer;

  _BatteryShellPainter({required this.glow, required this.shimmer});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyW = size.width - 16;
    final bodyH = size.height;
    final r = Radius.circular(bodyH * 0.28);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyW, bodyH),
      r,
    );

    // Soft outer glow (animated)
    canvas.drawRRect(
      body.inflate(6),
      Paint()
        ..color = const Color(0xFF3F8F5A).withOpacity(0.18 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + 8 * glow),
    );

    // Body fill — glossy green gradient
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF7DDB9A),
          Color(0xFF3F8F5A),
          Color(0xFF2F6E45),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, bodyW, bodyH));
    canvas.drawRRect(body, fill);

    // Top gloss highlight
    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.38),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, bodyW, bodyH * 0.45));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, bodyW - 8, bodyH * 0.38),
        Radius.circular(bodyH * 0.22),
      ),
      gloss,
    );

    // Moving shine sweep
    final sx = (shimmer * 1.6 - 0.3) * bodyW;
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(sx, 0, bodyW * 0.28, bodyH),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(sx, 0, bodyW * 0.28, bodyH)),
    );
    canvas.restore();

    // Border
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF2A5F3C).withOpacity(0.85),
    );

    // Battery tip (positive terminal)
    final tipH = bodyH * 0.38;
    final tip = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyW - 1, (bodyH - tipH) / 2, 14, tipH),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      tip,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7DDB9A), Color(0xFF3F8F5A)],
        ).createShader(tip.outerRect),
    );
    canvas.drawRRect(
      tip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF2A5F3C).withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryShellPainter oldDelegate) =>
      oldDelegate.glow != glow || oldDelegate.shimmer != shimmer;
}
