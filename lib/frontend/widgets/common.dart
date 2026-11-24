import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/mppt_backend.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String? subtitle;
  const AppHeader({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<MpptBackend>();
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 8,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.92),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/emblem.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('InnoMPPT',
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700, fontSize: 18)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!,
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: AppColors.onVariant)),
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
    );
  }
}

/// Simple page title (Battery / Settings / Analytics) — no Innosphere branding.
class PageTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const PageTitleBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<MpptBackend>();
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700, fontSize: 22)),
          ),
          if (trailing != null) trailing!,
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
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const SoftCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;
  const MetricChip({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.manrope(
                  fontSize: 10, color: AppColors.onVariant)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: valueColor ?? AppColors.onSurface,
                  )),
              const SizedBox(width: 2),
              Text(unit,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: valueColor ?? AppColors.onVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool ok;
  const StatusPill({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.ok = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: ok ? AppColors.primary : AppColors.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, fontWeight: FontWeight.w700)),
                Text(title.toUpperCase(),
                    style: GoogleFonts.manrope(
                        fontSize: 9, color: AppColors.onVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback? onTap;

  const ConfirmActionButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.foreground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: foreground)),
            Text(subtitle,
                style: GoogleFonts.manrope(
                    fontSize: 10, color: foreground.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmAction(
    BuildContext context, String title, String body) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES')),
      ],
    ),
  );
  return r == true;
}
