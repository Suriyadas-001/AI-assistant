// orb_widget.dart — Robot HUD Face design
import 'dart:math';
import 'package:flutter/material.dart';

class JarvisOrb extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final double size;

  const JarvisOrb({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.size = 200,
  });

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb> with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _scanController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _rippleController, curve: Curves.easeOut));
    _scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _scanController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    final Color activeColor = widget.isListening
        ? const Color(0xFF00E5FF)
        : widget.isSpeaking
            ? const Color(0xFF29B6F6)
            : const Color(0xFF0288D1);

    return SizedBox(
      width: s * 1.6,
      height: s * 1.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // HUD bracket corners
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) => CustomPaint(
              size: Size(s * 1.5, s * 1.5),
              painter: _HudBracketPainter(activeColor, _rotateController.value),
            ),
          ),

          // Ripple rings when active
          if (widget.isListening || widget.isSpeaking)
            ...List.generate(3, (i) => AnimatedBuilder(
              animation: _rippleController,
              builder: (_, __) {
                final progress = (_rippleAnim.value + i * 0.33) % 1.0;
                return Opacity(
                  opacity: (1 - progress) * 0.55,
                  child: Container(
                    width: s * (1.05 + progress * 0.7),
                    height: s * (1.05 + progress * 0.7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: activeColor, width: 1.2),
                    ),
                  ),
                );
              },
            )),

          // Glow halo
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: s * 1.08, height: s * 1.08,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: activeColor.withOpacity(0.28), blurRadius: 35, spreadRadius: 8),
                    BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.4), blurRadius: 60, spreadRadius: 15),
                  ],
                ),
              ),
            ),
          ),

          // Outer segmented ring (rotating)
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) => Transform.rotate(
              angle: _rotateController.value * 2 * pi,
              child: CustomPaint(size: Size(s * 1.04, s * 1.04), painter: _SegmentRingPainter(activeColor, 12)),
            ),
          ),

          // Inner counter-rotating ring
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) => Transform.rotate(
              angle: -_rotateController.value * 2 * pi * 0.6,
              child: CustomPaint(size: Size(s * 0.86, s * 0.86), painter: _SegmentRingPainter(const Color(0xFF4FC3F7).withOpacity(0.5), 8)),
            ),
          ),

          // Main robot face sphere
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: widget.isListening ? 1.0 + (_pulseAnim.value - 1.0) * 2.5 : _pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: s, height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.35),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF4FC3F7).withOpacity(0.25),
                    const Color(0xFF0277BD).withOpacity(0.7),
                    const Color(0xFF01579B).withOpacity(0.92),
                    const Color(0xFF002171),
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(color: activeColor.withOpacity(0.45), blurRadius: 22, spreadRadius: 2),
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 18, spreadRadius: -4, offset: const Offset(4, 8)),
                ],
                border: Border.all(color: activeColor.withOpacity(0.5), width: 1.5),
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    // Robot face
                    CustomPaint(
                      size: Size(s, s),
                      painter: _RobotFacePainter(
                        activeColor: activeColor,
                        isListening: widget.isListening,
                        isSpeaking: widget.isSpeaking,
                      ),
                    ),
                    // Scan line
                    AnimatedBuilder(
                      animation: _scanAnim,
                      builder: (_, __) {
                        final y = (s / 2) + (_scanAnim.value * s * 0.45);
                        return Positioned(
                          top: y, left: 0, right: 0,
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                activeColor.withOpacity(0.5),
                                activeColor.withOpacity(0.7),
                                activeColor.withOpacity(0.5),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                    // Top shine
                    Positioned(
                      top: s * 0.08, left: s * 0.2,
                      child: Container(
                        width: s * 0.28, height: s * 0.14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.white.withOpacity(0.32), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotFacePainter extends CustomPainter {
  final Color activeColor;
  final bool isListening;
  final bool isSpeaking;
  _RobotFacePainter({required this.activeColor, required this.isListening, required this.isSpeaking});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final glowPaint = Paint()..color = activeColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final fillPaint = Paint()..color = activeColor;
    final linePaint = Paint()..color = activeColor.withOpacity(0.4)..strokeWidth = 0.9..style = PaintingStyle.stroke;

    // Eyes
    final eyeY = cy - r * 0.12;
    final eyeW = r * 0.22; final eyeH = r * 0.10; final eyeGap = r * 0.28;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - eyeGap, eyeY), width: eyeW + 8, height: eyeH + 8), glowPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + eyeGap, eyeY), width: eyeW + 8, height: eyeH + 8), glowPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - eyeGap, eyeY), width: eyeW, height: eyeH), fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + eyeGap, eyeY), width: eyeW, height: eyeH), fillPaint);
    canvas.drawCircle(Offset(cx - eyeGap, eyeY), eyeH * 0.35, Paint()..color = Colors.white.withOpacity(0.9));
    canvas.drawCircle(Offset(cx + eyeGap, eyeY), eyeH * 0.35, Paint()..color = Colors.white.withOpacity(0.9));

    // Nose bridge
    canvas.drawLine(Offset(cx, eyeY + eyeH), Offset(cx, cy + r * 0.05), linePaint);

    // Mouth grille
    final mouthY = cy + r * 0.22;
    final grillePaint = Paint()
      ..color = activeColor.withOpacity(isSpeaking ? 0.9 : 0.5)
      ..strokeWidth = isSpeaking ? 2.0 : 1.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final mouthW = r * 0.55; final lineSpacing = r * 0.065;
    for (int i = -1; i <= 2; i++) {
      final lw = mouthW * (1.0 - i.abs() * 0.1);
      canvas.drawLine(Offset(cx - lw / 2, mouthY + i * lineSpacing), Offset(cx + lw / 2, mouthY + i * lineSpacing), grillePaint);
    }

    // Cheek panels
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(Offset(cx - r * 0.72, cy - r * 0.05 + i * r * 0.1), Offset(cx - r * 0.45, cy - r * 0.02 + i * r * 0.08), linePaint);
      canvas.drawLine(Offset(cx + r * 0.72, cy - r * 0.05 + i * r * 0.1), Offset(cx + r * 0.45, cy - r * 0.02 + i * r * 0.08), linePaint);
    }

    // Forehead panel
    final fhPaint = Paint()..color = activeColor.withOpacity(0.22)..strokeWidth = 0.9..style = PaintingStyle.stroke;
    final fhPath = Path()
      ..moveTo(cx - r * 0.3, cy - r * 0.55)..lineTo(cx + r * 0.3, cy - r * 0.55)
      ..lineTo(cx + r * 0.25, cy - r * 0.38)..lineTo(cx - r * 0.25, cy - r * 0.38)..close();
    canvas.drawPath(fhPath, fhPaint);

    // Reactor dot
    canvas.drawCircle(Offset(cx, cy - r * 0.47), 4.5, Paint()..color = activeColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset(cx, cy - r * 0.47), 2.2, Paint()..color = Colors.white);

    // Chin panel
    final chinPath = Path()
      ..moveTo(cx - r * 0.28, cy + r * 0.55)..lineTo(cx + r * 0.28, cy + r * 0.55)
      ..lineTo(cx + r * 0.18, cy + r * 0.72)..lineTo(cx - r * 0.18, cy + r * 0.72)..close();
    canvas.drawPath(chinPath, fhPaint);

    // Listening bars
    if (isListening) {
      final barPaint = Paint()..color = activeColor..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      final barY = mouthY + r * 0.22;
      final barHeights = [0.06, 0.10, 0.15, 0.10, 0.06];
      for (int i = 0; i < 5; i++) {
        final x = cx - r * 0.16 + i * r * 0.08;
        final h = r * barHeights[i];
        canvas.drawLine(Offset(x, barY - h), Offset(x, barY + h), barPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RobotFacePainter old) => old.isListening != isListening || old.isSpeaking != isSpeaking;
}

class _SegmentRingPainter extends CustomPainter {
  final Color color; final int segments;
  _SegmentRingPainter(this.color, this.segments);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2; final radius = size.width / 2;
    final gap = 0.15; final segAngle = 2 * pi / segments;
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: radius), i * segAngle + gap / 2, segAngle - gap, false, paint);
    }
  }
  @override
  bool shouldRepaint(_SegmentRingPainter old) => false;
}

class _HudBracketPainter extends CustomPainter {
  final Color color; final double t;
  _HudBracketPainter(this.color, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.5)..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.square;
    final len = size.width * 0.12;
    final corners = [
      [Offset(0, len), Offset(0, 0), Offset(len, 0)],
      [Offset(size.width - len, 0), Offset(size.width, 0), Offset(size.width, len)],
      [Offset(size.width, size.height - len), Offset(size.width, size.height), Offset(size.width - len, size.height)],
      [Offset(len, size.height), Offset(0, size.height), Offset(0, size.height - len)],
    ];
    for (final pts in corners) {
      canvas.drawPath(Path()..moveTo(pts[0].dx, pts[0].dy)..lineTo(pts[1].dx, pts[1].dy)..lineTo(pts[2].dx, pts[2].dy), paint);
    }
    final cx = size.width / 2; final cy = size.height / 2; final outerR = size.width / 2;
    final angle = t * 2 * pi;
    canvas.drawCircle(
      Offset(cx + cos(angle) * outerR, cy + sin(angle) * outerR), 3,
      Paint()..color = color.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }
  @override
  bool shouldRepaint(_HudBracketPainter old) => old.t != t;
}