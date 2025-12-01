// BACKGROUND ANIMADO HECHO CON IA PARA EVITAR PROGRAMAR DE MAS

import 'dart:math';
import 'package:flutter/material.dart';

class SoundWavePainter extends CustomPainter {
  final Animation<double> animation;
  final int waveCount;
  final Color waveColor;
  final double maxAmplitude;

  SoundWavePainter({
    required this.animation,
    this.waveCount = 1,
    this.waveColor = Colors.white,
    this.maxAmplitude = 50.0,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    for (int i = 0; i < waveCount; i++) {
      _drawSingleWave(canvas, size, paint, i);
    }
  }

  void _drawSingleWave(Canvas canvas, Size size, Paint paint, int waveIndex) {
    final path = Path();
    final time = animation.value * 2 * pi;
    final verticalOffset = size.height / 2;

    final baseAmplitude = maxAmplitude * (0.7 + sin(time * 0.5) * 0.3);
    final baseFrequency = 0.03 + (sin(time * 0.3) * 0.02);

    path.moveTo(0, verticalOffset);

    for (double x = 0; x < size.width; x += 2) {
      final distanceRatio = x / size.width;
      final amplitudeMod = 1.0 + sin(distanceRatio * 8 * pi + time * 2) * 0.4;
      final freqMod = 1.0 + sin(distanceRatio * 6 * pi + time * 1.5) * 0.3;

      final y1 =
          sin(x * baseFrequency * freqMod + time * 3) *
          baseAmplitude *
          amplitudeMod;
      final y2 =
          sin(x * baseFrequency * 2.7 * freqMod + time * 4.2) *
          baseAmplitude *
          0.3 *
          amplitudeMod;
      final y3 =
          sin(x * baseFrequency * 0.7 * freqMod + time * 1.8) *
          baseAmplitude *
          0.5 *
          amplitudeMod;

      final y = (y1 + y2 + y3) / 3;
      path.lineTo(x, verticalOffset + y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SoundWavePainter oldDelegate) {
    return true;
  }
}

class AnimatedSoundWaveBackground extends StatefulWidget {
  const AnimatedSoundWaveBackground({super.key});

  @override
  State<AnimatedSoundWaveBackground> createState() =>
      _AnimatedSoundWaveBackgroundState();
}

class _AnimatedSoundWaveBackgroundState
    extends State<AnimatedSoundWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: SoundWavePainter(
            animation: _controller,
            waveCount: 1,
            waveColor: Colors.white,
            maxAmplitude: 600.0,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
