import 'package:flutter/material.dart';

import '../theme/aircrypt_theme.dart';

const _identityColorMatrix = <double>[
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

const _invertColorMatrix = <double>[
  -1,
  0,
  0,
  0,
  255,
  0,
  -1,
  0,
  0,
  255,
  0,
  0,
  -1,
  0,
  255,
  0,
  0,
  0,
  1,
  0,
];

class PressInvert extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;

  const PressInvert({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor = AirCryptColors.bgSurface,
  });

  @override
  State<PressInvert> createState() => _PressInvertState();
}

class _PressInvertState extends State<PressInvert> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(
          _isPressed ? _invertColorMatrix : _identityColorMatrix,
        ),
        child: ColoredBox(color: widget.backgroundColor, child: widget.child),
      ),
    );
  }
}

/// Monochrome, hard-edged panel used by the terminal screens.
class CyberCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool showGlow;
  final VoidCallback? onTap;

  const CyberCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderColor,
    this.backgroundColor,
    this.showGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderClr = borderColor ?? AirCryptColors.cardBorder;
    final bgClr = backgroundColor ?? AirCryptColors.cardBg;
    final cardTap = onTap;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: borderClr, width: 1.2),
    );

    return Container(
      margin: margin,
      child: Material(
        color: bgClr,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: Colors.transparent,
        child: cardTap == null
            ? Padding(padding: padding, child: child)
            : PressInvert(
                onTap: cardTap,
                backgroundColor: bgClr,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

class PageIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PageIntro({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[ ${title.toUpperCase()} ]',
                  style: const TextStyle(
                    color: AirCryptColors.textPrimary,
                    fontFamily: 'Silkscreen',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AirCryptColors.textSecondary,
                    fontFamily: 'Silkscreen',
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: AirCryptColors.textPrimary),
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: AirCryptColors.textPrimary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AirCryptColors.textPrimary,
                fontFamily: 'Silkscreen',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AirCryptColors.textSecondary,
                fontFamily: 'Silkscreen',
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cyber status badge tag.
class CyberBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isFilled;

  const CyberBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = AirCryptColors.accentCyan,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled ? color : AirCryptColors.bgSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isFilled ? AirCryptColors.bgSurface : color,
              fontFamily: 'Silkscreen',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cyber Action Button with glow and technical typography.
class CyberButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDanger;
  final bool isLoading;
  final double? width;

  const CyberButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isDanger = false,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isDanger
        ? AirCryptColors.accentRed
        : AirCryptColors.accentCyan;

    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isPrimary ? AirCryptColors.bgSurface : activeColor,
          ),
        ),
      );
    } else {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );
    }

    Widget btn;
    if (isPrimary) {
      btn = Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.zero),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                disabledBackgroundColor: activeColor.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 4,
                shadowColor: AirCryptColors.textPrimary.withValues(alpha: 0.28),
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return activeColor.withValues(alpha: 0.3);
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return AirCryptColors.bgSurface;
                  }
                  return activeColor;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return AirCryptColors.textMuted;
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return activeColor;
                  }
                  return AirCryptColors.bgSurface;
                }),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                elevation: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled) ||
                      states.contains(WidgetState.pressed)) {
                    return 0;
                  }
                  return 4;
                }),
              ),
          child: buttonChild,
        ),
      );
    } else {
      btn = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style:
            OutlinedButton.styleFrom(
              foregroundColor: activeColor,
              side: BorderSide(
                color: onPressed != null
                    ? AirCryptColors.cardBorder
                    : AirCryptColors.cardBorder.withValues(alpha: 0.5),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 3,
              shadowColor: AirCryptColors.textPrimary.withValues(alpha: 0.24),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) return activeColor;
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AirCryptColors.bgSurface;
                }
                return activeColor;
              }),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled) ||
                    states.contains(WidgetState.pressed)) {
                  return 0;
                }
                return 3;
              }),
            ),
        child: buttonChild,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: btn);
    }
    return btn;
  }
}

/// Central AirCrypt Visual Identity Banner
class AirCryptHeader extends StatelessWidget {
  final bool compact;

  const AirCryptHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AirCryptColors.accentCyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AirCryptColors.accentCyan.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 20,
              color: AirCryptColors.accentCyan,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'AirCrypt',
                style: TextStyle(
                  color: AirCryptColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Secure  •  Private  •  Direct',
                style: TextStyle(
                  color: AirCryptColors.accentCyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AirCryptColors.accentCyan.withValues(alpha: 0.06),
                border: Border.all(
                  color: AirCryptColors.accentCyan.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: AirCryptColors.cyberGlow(
                  color: AirCryptColors.accentCyan,
                  opacity: 0.1,
                ),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AirCryptColors.accentCyan.withValues(alpha: 0.12),
                border: Border.all(
                  color: AirCryptColors.accentCyan.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 38,
                color: AirCryptColors.accentCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AirCryptColors.textPrimary, AirCryptColors.accentCyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'AirCrypt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AirCryptColors.accentCyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AirCryptColors.accentCyan.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'Secure  •  Private  •  Direct',
            style: TextStyle(
              color: AirCryptColors.accentCyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

/// Security Pipeline Step Status Widget
class SecurityPipelineWidget extends StatelessWidget {
  final List<SecurityStepItem> steps;

  const SecurityPipelineWidget({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: AirCryptColors.accentCyan,
              ),
              SizedBox(width: 8),
              Text(
                'CRYPTOGRAPHIC PIPELINE',
                style: TextStyle(
                  color: AirCryptColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(children: steps.map((step) => _buildStepRow(step)).toList()),
        ],
      ),
    );
  }

  Widget _buildStepRow(SecurityStepItem step) {
    Color iconColor;
    IconData iconData;

    switch (step.state) {
      case SecurityStepState.completed:
        iconColor = AirCryptColors.accentGreen;
        iconData = Icons.check_circle_outline;
        break;
      case SecurityStepState.active:
        iconColor = AirCryptColors.accentCyan;
        iconData = Icons.motion_photos_on;
        break;
      case SecurityStepState.pending:
        iconColor = AirCryptColors.textMuted;
        iconData = Icons.radio_button_unchecked;
        break;
      case SecurityStepState.failed:
        iconColor = AirCryptColors.accentRed;
        iconData = Icons.error_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(iconData, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                color: step.state == SecurityStepState.pending
                    ? AirCryptColors.textMuted
                    : AirCryptColors.textPrimary,
                fontSize: 13,
                fontWeight: step.state == SecurityStepState.active
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (step.subtext != null)
            Text(
              step.subtext!,
              style: TextStyle(
                color: iconColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

enum SecurityStepState { pending, active, completed, failed }

class SecurityStepItem {
  final String label;
  final SecurityStepState state;
  final String? subtext;

  const SecurityStepItem({
    required this.label,
    required this.state,
    this.subtext,
  });
}
