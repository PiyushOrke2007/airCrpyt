import 'package:flutter/material.dart';

import '../theme/aircrypt_theme.dart';

/// Dark elevated panel card with thin futuristic glowing borders.
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
    final borderClr = borderColor ?? AirCryptColors.accentCyan.withOpacity(0.2);
    final bgClr = backgroundColor ?? AirCryptColors.cardBg;

    Widget cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr, width: 1.2),
        boxShadow: showGlow ? AirCryptColors.cyberGlow(color: borderClr, opacity: 0.18) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: cardContent,
      );
    }

    return cardContent;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFilled ? color.withOpacity(0.18) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
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
    final Color activeColor = isDanger ? AirCryptColors.accentRed : AirCryptColors.accentCyan;

    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isPrimary ? AirCryptColors.bgDark : activeColor,
          ),
        ),
      );
    } else {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: isPrimary ? AirCryptColors.bgDark : activeColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isPrimary ? AirCryptColors.bgDark : activeColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      );
    }

    Widget btn;
    if (isPrimary) {
      btn = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: onPressed != null
              ? AirCryptColors.cyberGlow(color: activeColor, opacity: 0.3)
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            disabledBackgroundColor: activeColor.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: buttonChild,
        ),
      );
    } else {
      btn = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: activeColor,
          side: BorderSide(
            color: onPressed != null
                ? activeColor.withOpacity(0.6)
                : activeColor.withOpacity(0.2),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
              color: AirCryptColors.accentCyan.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AirCryptColors.accentCyan.withOpacity(0.5),
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
                'AIRCRYPT',
                style: TextStyle(
                  color: AirCryptColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'SECURE • PRIVATE • DIRECT',
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AirCryptColors.accentCyan.withOpacity(0.06),
                border: Border.all(
                  color: AirCryptColors.accentCyan.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: AirCryptColors.cyberGlow(
                  color: AirCryptColors.accentCyan,
                  opacity: 0.2,
                ),
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AirCryptColors.accentCyan.withOpacity(0.12),
                border: Border.all(
                  color: AirCryptColors.accentCyan.withOpacity(0.5),
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
            'AIRCRYPT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AirCryptColors.accentCyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AirCryptColors.accentCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'SECURE  •  PRIVATE  •  DIRECT',
            style: TextStyle(
              color: AirCryptColors.accentCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
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
              Icon(Icons.verified_user_outlined, size: 16, color: AirCryptColors.accentCyan),
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
          Column(
            children: steps.map((step) => _buildStepRow(step)).toList(),
          ),
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
