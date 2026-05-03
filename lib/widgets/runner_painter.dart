import 'dart:math';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart' show PlayerState;

/// Drives per-frame limb angles for the runner character.
/// All angles in radians. Positive = clockwise.
class RunnerLimbState {
  final double headTilt;
  final double torsoLean;
  final double upperArmLAngle;
  final double lowerArmLAngle;
  final double upperArmRAngle;
  final double lowerArmRAngle;
  final double upperLegLAngle;
  final double lowerLegLAngle;
  final double upperLegRAngle;
  final double lowerLegRAngle;
  final double bodyOffsetY; // vertical bob
  final bool squash; // landing squash frame

  const RunnerLimbState({
    this.headTilt = 0,
    this.torsoLean = 0,
    this.upperArmLAngle = 0,
    this.lowerArmLAngle = 0,
    this.upperArmRAngle = 0,
    this.lowerArmRAngle = 0,
    this.upperLegLAngle = 0,
    this.lowerLegLAngle = 0,
    this.upperLegRAngle = 0,
    this.lowerLegRAngle = 0,
    this.bodyOffsetY = 0,
    this.squash = false,
  });

  /// Compute limb state from game parameters each frame.
  factory RunnerLimbState.compute({
    required PlayerState state,
    required double distance,
    required double gameSpeed,
    required double jumpProgress,
    required double slideProgress,
    required bool hasJetpack,
    required double jetpackTime,
  }) {
    // Run cycle frequency scales with speed — faster run = quicker legs
    final freq = 0.12 + (gameSpeed / 35.0) * 0.10;
    final t = distance * freq; // cycles continuously

    switch (state) {
      case PlayerState.running:
        if (hasJetpack) return _jetpackState(jetpackTime, t);
        return _runState(t);

      case PlayerState.jumping:
        return _jumpState(jumpProgress);

      case PlayerState.sliding:
        return _slideState(slideProgress);

      case PlayerState.dead:
        return const RunnerLimbState(
          torsoLean: 0.4,
          upperLegLAngle: 0.6,
          upperLegRAngle: -0.3,
          lowerLegLAngle: 0.8,
          upperArmLAngle: -0.9,
          upperArmRAngle: 0.5,
        );
    }
  }

  static RunnerLimbState _runState(double t) {
    // Legs alternate — left leads when right lags, driven by sin
    final legSwing = 0.55;
    final kneeFlexMax = 0.7;
    final armSwing = 0.45;

    final leftLegPhase = sin(t);
    final rightLegPhase = sin(t + pi); // opposite
    final leftArmPhase = sin(t + pi); // arm opposite to same-side leg
    final rightArmPhase = sin(t);

    // Body bobs slightly up/down twice per stride
    final bob = sin(t * 2) * 2.5;

    // Knee bends on the back-swinging leg
    final lowerLegL = leftLegPhase < 0 ? -leftLegPhase * kneeFlexMax : 0.0;
    final lowerLegR = rightLegPhase < 0 ? -rightLegPhase * kneeFlexMax : 0.0;

    return RunnerLimbState(
      headTilt: sin(t) * 0.04,
      torsoLean: 0.12, // constant forward lean while running
      upperArmLAngle: leftArmPhase * armSwing,
      lowerArmLAngle: leftArmPhase < 0 ? -leftArmPhase * 0.5 : 0.1,
      upperArmRAngle: rightArmPhase * armSwing,
      lowerArmRAngle: rightArmPhase < 0 ? -rightArmPhase * 0.5 : 0.1,
      upperLegLAngle: leftLegPhase * legSwing,
      lowerLegLAngle: lowerLegL,
      upperLegRAngle: rightLegPhase * legSwing,
      lowerLegRAngle: lowerLegR,
      bodyOffsetY: bob,
    );
  }

  static RunnerLimbState _jumpState(double progress) {
    // 0→0.3: launch — legs push down, arms fly up
    // 0.3→0.7: air — tuck knees, arms spread
    // 0.7→1.0: land — extend legs, arms cushion down
    double upperLegL, lowerLegL, upperLegR, lowerLegR;
    double upperArmL, upperArmR;
    double torso, headTilt, bob;

    if (progress < 0.3) {
      final p = progress / 0.3;
      upperLegL = -0.3 * p;
      lowerLegL = 0.4 * p;
      upperLegR = -0.3 * p;
      lowerLegR = 0.4 * p;
      upperArmL = -0.8 * p;
      upperArmR = -0.8 * p;
      torso = -0.15 * p;
      headTilt = -0.05 * p;
      bob = -5 * p;
    } else if (progress < 0.7) {
      final p = (progress - 0.3) / 0.4;
      upperLegL = -0.3 + (-0.5 * p); // tuck
      lowerLegL = 0.4 + (0.9 * p);
      upperLegR = -0.3 + (-0.5 * p);
      lowerLegR = 0.4 + (0.9 * p);
      upperArmL = -0.8;
      upperArmR = -0.8;
      torso = -0.15;
      headTilt = 0;
      bob = -5 + (sin(p * pi) * 3);
    } else {
      final p = (progress - 0.7) / 0.3;
      upperLegL = -0.8 + (0.9 * p); // extend for landing
      lowerLegL = 1.3 - (1.1 * p);
      upperLegR = -0.8 + (0.9 * p);
      lowerLegR = 1.3 - (1.1 * p);
      upperArmL = -0.8 + (0.8 * p);
      upperArmR = -0.8 + (0.8 * p);
      torso = -0.15 + (0.28 * p);
      headTilt = 0.05 * p;
      bob = p > 0.8 ? sin(p * pi * 4) * 2.5 : 0; // landing bounce
    }

    return RunnerLimbState(
      headTilt: headTilt,
      torsoLean: torso,
      upperArmLAngle: upperArmL,
      lowerArmLAngle: 0.2,
      upperArmRAngle: upperArmR,
      lowerArmRAngle: 0.2,
      upperLegLAngle: upperLegL,
      lowerLegLAngle: lowerLegL,
      upperLegRAngle: upperLegR,
      lowerLegRAngle: lowerLegR,
      bodyOffsetY: bob,
      squash: progress > 0.9,
    );
  }

  static RunnerLimbState _slideState(double progress) {
    // Body goes from upright → fully crouched forward → recover
    final lean = progress < 0.5
        ? 0.12 + (progress / 0.5) * 0.55
        : 0.67 - ((progress - 0.5) / 0.5) * 0.55;

    return RunnerLimbState(
      headTilt: 0.2,
      torsoLean: lean,
      upperArmLAngle: 0.3,
      lowerArmLAngle: -0.3,
      upperArmRAngle: -0.6,
      lowerArmRAngle: 0.4,
      upperLegLAngle: -0.4,
      lowerLegLAngle: 1.1,
      upperLegRAngle: 0.6,
      lowerLegRAngle: 0.3,
      bodyOffsetY: 15,
    );
  }

  static RunnerLimbState _jetpackState(double jetpackTime, double t) {
    // Hover: gentle leg dangle + slow arm sway
    return RunnerLimbState(
      headTilt: sin(t * 0.5) * 0.05,
      torsoLean: -0.05,
      upperArmLAngle: sin(t * 0.5) * 0.2 - 0.1,
      lowerArmLAngle: 0.3,
      upperArmRAngle: -sin(t * 0.5) * 0.2 - 0.1,
      lowerArmRAngle: 0.3,
      upperLegLAngle: sin(t * 0.5) * 0.15 + 0.2,
      lowerLegLAngle: 0.5,
      upperLegRAngle: -sin(t * 0.5) * 0.15 + 0.2,
      lowerLegRAngle: 0.5,
      bodyOffsetY: sin(jetpackTime * 3) * 4,
    );
  }
}

/// Draws the runner character using Canvas — each body part is a separate
/// segment that rotates independently from its joint pivot point.
class RunnerPainter extends CustomPainter {
  final RunnerLimbState limbs;

  RunnerPainter({required this.limbs});

  // ── Neon cyberpunk palette ──────────────────────────────────────────────
  static const _bodyColor   = Color(0xFF1A1A2E);
  static const _suitColor   = Color(0xFF0D2137);
  static const _cyanGlow    = Color(0xFF00F0FF);
  static const _pinkGlow    = Color(0xFFFF00A0);
  static const _white       = Colors.white;
  static const _jointColor  = Color(0xFF00C8D4);
  static const _glowAlpha   = 0.35;

  Paint get _bodyPaint => Paint()
    ..color = _bodyColor
    ..style = PaintingStyle.fill;

  Paint get _suitPaint => Paint()
    ..color = _suitColor
    ..style = PaintingStyle.fill;

  Paint get _outlinePaint => Paint()
    ..color = _cyanGlow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;

  Paint get _accentPaint => Paint()
    ..color = _pinkGlow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  Paint get _glowPaint => Paint()
    ..color = _cyanGlow.withOpacity(_glowAlpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  Paint get _jointPaint => Paint()
    ..color = _jointColor
    ..style = PaintingStyle.fill;

  Paint get _visorPaint => Paint()
    ..color = _pinkGlow.withOpacity(0.85)
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // Origin at center-top of the 70×100 canvas
    final cx = size.width / 2;
    final cy = size.height * 0.08 + limbs.bodyOffsetY;

    canvas.save();
    canvas.translate(cx, cy);

    // Global torso lean (all body parts lean together)
    canvas.rotate(limbs.torsoLean);

    // ── Draw order: back limbs → torso/head → front limbs ──────────────

    // Back arm (right arm — appears behind torso)
    _drawArm(canvas,
      shoulderX: 6, shoulderY: 14,
      upperAngle: limbs.upperArmRAngle,
      lowerAngle: limbs.lowerArmRAngle,
      isRight: true,
      isBack: true,
    );

    // Back leg (right leg)
    _drawLeg(canvas,
      hipX: 4, hipY: 30,
      upperAngle: limbs.upperLegRAngle,
      lowerAngle: limbs.lowerLegRAngle,
      isRight: true,
      isBack: true,
    );

    // ── Torso ──────────────────────────────────────────────────────────
    _drawTorso(canvas, limbs.squash);

    // ── Head ───────────────────────────────────────────────────────────
    _drawHead(canvas, limbs.headTilt);

    // Front leg (left leg)
    _drawLeg(canvas,
      hipX: -4, hipY: 30,
      upperAngle: limbs.upperLegLAngle,
      lowerAngle: limbs.lowerLegLAngle,
      isRight: false,
      isBack: false,
    );

    // Front arm (left arm)
    _drawArm(canvas,
      shoulderX: -6, shoulderY: 14,
      upperAngle: limbs.upperArmLAngle,
      lowerAngle: limbs.lowerArmLAngle,
      isRight: false,
      isBack: false,
    );

    canvas.restore();
  }

  void _drawTorso(Canvas canvas, bool squash) {
    final scaleY = squash ? 0.88 : 1.0;
    final scaleX = squash ? 1.08 : 1.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Main body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 20), width: 22, height: 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, _suitPaint);

    // Glow outline
    canvas.drawRRect(bodyRect, _glowPaint);
    canvas.drawRRect(bodyRect, _outlinePaint);

    // Chest accent stripe
    final chestStripe = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 17), width: 10, height: 3),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(chestStripe, Paint()..color = _cyanGlow..style = PaintingStyle.fill);

    // Belt line
    canvas.drawLine(
      const Offset(-10, 29),
      const Offset(10, 29),
      Paint()..color = _pinkGlow..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  void _drawHead(Canvas canvas, double tilt) {
    canvas.save();
    canvas.translate(0, 4);
    canvas.rotate(tilt);

    // Head sphere
    canvas.drawCircle(const Offset(0, 0), 11, _bodyPaint);
    canvas.drawCircle(const Offset(0, 0), 11, _glowPaint);
    canvas.drawCircle(const Offset(0, 0), 11, _outlinePaint);

    // Visor (eye band)
    final visorPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -3, 14, 5),
        const Radius.circular(2),
      ));
    canvas.drawPath(visorPath, _visorPaint);

    // Visor glow
    canvas.drawPath(visorPath, Paint()
      ..color = _pinkGlow.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..style = PaintingStyle.fill);

    // Helmet top ridge
    canvas.drawArc(
      const Rect.fromLTWH(-10, -11, 20, 14),
      pi, pi, false,
      Paint()..color = _cyanGlow..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );

    // Antenna nub
    canvas.drawCircle(const Offset(0, -11), 2, Paint()..color = _pinkGlow..style = PaintingStyle.fill);

    canvas.restore();
  }

  void _drawArm(Canvas canvas, {
    required double shoulderX,
    required double shoulderY,
    required double upperAngle,
    required double lowerAngle,
    required bool isRight,
    required bool isBack,
  }) {
    const upperLen = 14.0;
    const lowerLen = 12.0;
    const thickness = 5.0;

    final alpha = isBack ? 0.55 : 1.0;
    final segPaint = Paint()
      ..color = _suitColor.withOpacity(alpha)
      ..style = PaintingStyle.fill;
    final outPaint = Paint()
      ..color = _cyanGlow.withOpacity(alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.save();
    canvas.translate(shoulderX, shoulderY);

    // Shoulder joint
    canvas.drawCircle(Offset.zero, thickness / 2 + 1, _jointPaint..color = _jointColor.withOpacity(alpha));

    // Upper arm
    canvas.rotate(upperAngle);
    _drawSegment(canvas, upperLen, thickness, segPaint, outPaint);

    canvas.translate(0, upperLen);

    // Elbow joint
    canvas.drawCircle(Offset.zero, thickness / 2, _jointPaint..color = _jointColor.withOpacity(alpha));

    // Lower arm
    canvas.rotate(lowerAngle);
    _drawSegment(canvas, lowerLen, thickness - 1, segPaint, outPaint);

    // Fist
    canvas.translate(0, lowerLen);
    canvas.drawCircle(Offset.zero, 3.5,
      Paint()..color = _bodyColor.withOpacity(alpha)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset.zero, 3.5, outPaint);

    canvas.restore();
  }

  void _drawLeg(Canvas canvas, {
    required double hipX,
    required double hipY,
    required double upperAngle,
    required double lowerAngle,
    required bool isRight,
    required bool isBack,
  }) {
    const upperLen = 18.0;
    const lowerLen = 16.0;
    const thickness = 7.0;

    final alpha = isBack ? 0.5 : 1.0;
    final segPaint = Paint()
      ..color = _bodyColor.withOpacity(alpha)
      ..style = PaintingStyle.fill;
    final suitAccent = Paint()
      ..color = _suitColor.withOpacity(alpha)
      ..style = PaintingStyle.fill;
    final outPaint = Paint()
      ..color = _cyanGlow.withOpacity(alpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.save();
    canvas.translate(hipX, hipY);

    // Hip joint
    canvas.drawCircle(Offset.zero, thickness / 2 + 1,
      Paint()..color = _jointColor.withOpacity(alpha)..style = PaintingStyle.fill);

    // Upper leg
    canvas.rotate(upperAngle);

    // Outer suit shell
    _drawSegment(canvas, upperLen, thickness, suitAccent, outPaint);
    // Inner body
    _drawSegment(canvas, upperLen, thickness - 2.5, segPaint, Paint()..style = PaintingStyle.fill);

    canvas.translate(0, upperLen);

    // Knee joint
    canvas.drawCircle(Offset.zero, thickness / 2,
      Paint()..color = _jointColor.withOpacity(alpha)..style = PaintingStyle.fill);

    // Lower leg
    canvas.rotate(lowerAngle);
    _drawSegment(canvas, lowerLen, thickness - 1, suitAccent, outPaint);
    _drawSegment(canvas, lowerLen, thickness - 3.5, segPaint, Paint()..style = PaintingStyle.fill);

    // Foot/boot
    canvas.translate(0, lowerLen);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(isRight ? 2 : -2, 2), width: 12, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = _suitColor.withOpacity(alpha)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(isRight ? 2 : -2, 2), width: 12, height: 6),
        const Radius.circular(3),
      ),
      outPaint,
    );

    // Boot sole neon line
    canvas.drawLine(
      Offset(isRight ? -3 : -7, 5),
      Offset(isRight ? 7 : 3, 5),
      Paint()..color = _pinkGlow.withOpacity(alpha)..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  void _drawSegment(Canvas canvas, double length, double width,
      Paint fillPaint, Paint strokePaint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-width / 2, 0, width, length),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, strokePaint);
  }

  @override
  bool shouldRepaint(RunnerPainter old) =>
      old.limbs.headTilt != limbs.headTilt ||
      old.limbs.upperLegLAngle != limbs.upperLegLAngle ||
      old.limbs.upperLegRAngle != limbs.upperLegRAngle ||
      old.limbs.bodyOffsetY != limbs.bodyOffsetY;
}

/// Widget wrapper — call this wherever the player sprite is rendered.
class RunnerWidget extends StatelessWidget {
  final PlayerState playerState;
  final double distance;
  final double gameSpeed;
  final double jumpProgress;
  final double slideProgress;
  final bool hasJetpack;
  final double jetpackTime;
  final double width;
  final double height;

  const RunnerWidget({
    super.key,
    required this.playerState,
    required this.distance,
    required this.gameSpeed,
    required this.jumpProgress,
    required this.slideProgress,
    required this.hasJetpack,
    required this.jetpackTime,
    this.width = 70,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    final limbs = RunnerLimbState.compute(
      state: playerState,
      distance: distance,
      gameSpeed: gameSpeed,
      jumpProgress: jumpProgress,
      slideProgress: slideProgress,
      hasJetpack: hasJetpack,
      jetpackTime: jetpackTime,
    );

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: RunnerPainter(limbs: limbs),
      ),
    );
  }
}
