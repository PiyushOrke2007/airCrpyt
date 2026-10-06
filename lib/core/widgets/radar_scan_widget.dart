import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/aircrypt_theme.dart';

class RadarScanWidget extends StatefulWidget {
  final double size;
  final String statusText;
  final String helpText;
  final bool isScanning;

  const RadarScanWidget({
    super.key,
    this.size = 200,
    this.statusText = 'SCANNING FOR NEARBY AIRCRYPT PEERS...',
    this.helpText = 'Ensure both devices are connected to the same Wi-Fi network.',
    this.isScanning = true,
  });

  @override
  State<RadarScanWidget> createState() => _RadarScanWidgetState();
}

class _RadarScanWidgetState extends State<RadarScanWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RadarScanWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarPainter(
                  angle: _controller.value * 2 * math.pi,
                  pulse: math.sin(_controller.value * math.pi),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AirCryptColors.accentCyan.withOpacity(0.12),
                      border: Border.all(
                        color: AirCryptColors.accentCyan,
                        width: 1.5,
                      ),
                      boxShadow: AirCryptColors.cyberGlow(
                        color: AirCryptColors.accentCyan,
                        opacity: 0.3,
                      ),
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_outlined,
                      size: 32,
                      color: AirCryptColors.accentCyan,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.statusText.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AirCryptColors.accentCyan,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.helpText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AirCryptColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final double pulse;

  _RadarPainter({required this.angle, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Outer grid rings
    final ringPaint = Paint()
      ..color = AirCryptColors.accentCyan.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxRadius, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.66, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.33, ringPaint);

    // Crosshairs
    final linePaint = Paint()
      ..color = AirCryptColors.accentCyan.withOpacity(0.12)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      linePaint,
    );

    // Radar beam scan cone
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi / 2,
      colors: [
        AirCryptColors.accentCyan.withOpacity(0.0),
        AirCryptColors.accentCyan.withOpacity(0.35),
      ],
      transform: GradientRotation(angle),
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: maxRadius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Scanning line tip
    final lineX = center.dx + maxRadius * math.cos(angle + math.pi / 2);
    final lineY = center.dy + maxRadius * math.sin(angle + math.pi / 2);

    final tipPaint = Paint()
      ..color = AirCryptColors.accentCyan
      ..strokeWidth = 1.8;

    canvas.drawLine(center, Offset(lineX, lineY), tipPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.pulse != pulse;
  }
}
