import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'branded_loader.dart';

// ── Gradient Button ───────────────────────────────────────────────
class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final List<Color>? colors;
  final Color? textColor;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 54,
    this.colors,
    this.textColor,
    this.fontSize = 15,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (!widget.isLoading) widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors ??
                  [AppTheme.primary, const Color(0xFF00A37A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: widget.onTap != null ? AppTheme.glowShadow : [],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon,
                          color: widget.textColor ?? Colors.black,
                          size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.textColor ?? Colors.black,
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Outlined Button ───────────────────────────────────────────────
class OutlinedAppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool isFullWidth;
  final double height;

  const OutlinedAppButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.isFullWidth = false,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          border: Border.all(color: c.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: c, size: 18),
              const SizedBox(width: 7),
            ],
            Text(label,
                style: TextStyle(
                    color: c, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool large;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Data Row ──────────────────────────────────────────────────────
class DataField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool isMono;
  final bool copyable;

  const DataField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.isMono = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 5),
              ],
              Text(label.toUpperCase(),
                  style: AppTheme.label),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: isMono
                      ? TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? AppTheme.textPrimary,
                          letterSpacing: 1.2,
                        )
                      : AppTheme.heading4.copyWith(
                          color: valueColor ?? AppTheme.textPrimary),
                ),
              ),
              if (copyable)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied: $value'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppTheme.bgElevated,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 14, color: AppTheme.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.heading3),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: AppTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppTheme.border, thickness: 0.5, height: 1);
}

// ── Skeleton Loader ───────────────────────────────────────────────
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgCard,
      highlightColor: AppTheme.bgElevated,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: AppTheme.bgSurface,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 180,
                      color: AppTheme.bgSurface,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Amount Display ────────────────────────────────────────────────
class AmountCard extends StatelessWidget {
  final double amount;
  final double ratePerHour;
  final String duration;
  final bool isPaid;

  const AmountCard({
    super.key,
    required this.amount,
    required this.ratePerHour,
    required this.duration,
    this.isPaid = false,
  });

  static String _formatRwf(double v) =>
      NumberFormat('#,###', 'en_US').format(v.toInt());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaid
              ? [AppTheme.bgSurface, AppTheme.bgSurface]
              : [
                  AppTheme.primary.withOpacity(0.08),
                  AppTheme.accent.withOpacity(0.06),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isPaid
              ? AppTheme.border
              : AppTheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Amount Paid' : 'Total Amount Due',
                  style: AppTheme.label,
                ),
                const SizedBox(height: 6),
                isPaid
                    ? Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'RWF ${_formatRwf(amount)}',
                            style: AppTheme.heading2.copyWith(
                                color: AppTheme.textSecond),
                          ),
                        ],
                      )
                    : ShaderMask(
                        shaderCallback: (b) =>
                            AppTheme.primaryGrad.createShader(b),
                        child: Text(
                          'RWF ${_formatRwf(amount)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'monospace',
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_formatRwf(ratePerHour)} RWF/hr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecond,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                duration,
                style: const TextStyle(
                    color: AppTheme.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progress Steps ────────────────────────────────────────────────
class ProgressSteps extends StatelessWidget {
  final List<String> steps;
  final int current;

  const ProgressSteps({
    super.key,
    required this.steps,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: done || active
                            ? AppTheme.primaryGrad
                            : null,
                        color: done || active ? null : AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: active
                            ? AppTheme.primary
                            : done
                                ? AppTheme.textSecond
                                : AppTheme.textMuted,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Vehicle Status helpers ────────────────────────────────────────
extension VehicleStatusExt on String {
  Color get statusColor {
    switch (toLowerCase()) {
      case 'parked': return AppTheme.primary;
      case 'paid':   return AppTheme.accent;
      case 'exited': return AppTheme.textMuted;
      default:       return AppTheme.textMuted;
    }
  }

  IconData get statusIcon {
    switch (toLowerCase()) {
      case 'parked': return Icons.local_parking_rounded;
      case 'paid':   return Icons.check_circle_rounded;
      case 'exited': return Icons.exit_to_app_rounded;
      default:       return Icons.info_rounded;
    }
  }

  String get statusLabel {
    switch (toLowerCase()) {
      case 'parked': return 'Currently Parked';
      case 'paid':   return 'Paid & Cleared';
      case 'exited': return 'Exited';
      default:       return 'Unknown';
    }
  }
}

// ── Animated counter ──────────────────────────────────────────────
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCounter({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, v, __) => Text(
        v.toString(),
        style: style ??
            AppTheme.heading1.copyWith(color: AppTheme.primary),
      ),
    );
  }
}

// ── Top custom app bar ────────────────────────────────────────────
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgDeep,
        border: const Border(
            bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: onBack ?? () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textPrimary, size: 16),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.heading3),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.primary)),
              ],
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}

// ── Active Session Card ───────────────────────────────────────────
class ActiveSessionCard extends StatefulWidget {
  final VehicleRecord record;
  final VoidCallback onTap;

  const ActiveSessionCard({super.key, required this.record, required this.onTap});

  @override
  State<ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<ActiveSessionCard> {
  late Duration _duration;
  late double _amount;
  late String _durationStr;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() => _update());
    });
  }

  void _update() {
    _duration = DateTime.now().difference(widget.record.entryTime);
    _amount = ( _duration.inMinutes / 60.0 * widget.record.ratePerHour).ceilToDouble();
    _durationStr = _formatDuration(_duration);
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A34), Color(0xFF0D1F1B)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.timer_outlined, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ACTIVE SESSION', style: AppTheme.label.copyWith(color: AppTheme.primary, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                      Text(widget.record.plateNumber, style: AppTheme.heading4.copyWith(color: Colors.white, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                StatusBadge(label: 'LIVE', color: AppTheme.warning, icon: Icons.sensors_rounded),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DURATION', style: AppTheme.label.copyWith(fontSize: 9, color: Colors.white60)),
                    Text(_durationStr, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ESTIMATED FEE', style: AppTheme.label.copyWith(fontSize: 9, color: Colors.white60)),
                    Text('RWF ${NumberFormat('#,###').format(_amount)}', style: const TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppTheme.danger, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(widget.record.parkingName, style: AppTheme.bodySmall.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('TAP TO PAY', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(icon, color: AppTheme.textMuted, size: 36),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTheme.heading3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTheme.body, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
