import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/mood.dart';
import '../providers/app_provider.dart';
import 'quote_screen.dart';

class ShakeScreen extends StatefulWidget {
  final Mood mood;

  const ShakeScreen({super.key, required this.mood});

  @override
  State<ShakeScreen> createState() => _ShakeScreenState();
}

class _ShakeScreenState extends State<ShakeScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _pulseController;
  late AnimationController _hintController;
  late Animation<double> _iconBounce;
  late Animation<double> _pulse;
  late Animation<double> _hintFade;

  StreamSubscription? _accelSub;
  bool _shaken = false;
  double _lastMag = 0;
  int _shakeCount = 0;
  DateTime _lastShakeTime = DateTime.now();

  static const double _shakeThreshold = 15.0;
  static const int _shakesNeeded = 2;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconBounce = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _hintFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _hintController.forward();
    });

    _startListening();
  }

  void _startListening() {
    _accelSub = accelerometerEventStream().listen((event) {
      if (_shaken) return;

      final mag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (mag > _shakeThreshold && (mag - _lastMag).abs() > 5) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds > 300) {
          _shakeCount++;
          _lastShakeTime = now;

          if (_shakeCount >= _shakesNeeded) {
            _onShakeDetected();
          }
        }
      }
      _lastMag = mag;
    });
  }

  void _onShakeDetected() {
    if (_shaken) return;
    setState(() => _shaken = true);

    HapticFeedback.heavyImpact();

    _iconController.stop();
    _pulseController.stop();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => QuoteScreen(mood: widget.mood),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _iconController.dispose();
    _pulseController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isPolish = appProvider.currentLanguage == 'pl';
    final moodColor = widget.mood.color;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(const Color(0xFF2D1B4E), moodColor, 0.12)!,
              const Color(0xFF1A0F2E),
              const Color(0xFF120B22),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _ShakeStarsPainter(moodColor)),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, isPolish),
                  const Spacer(flex: 2),
                  _buildShakeArea(context, isPolish, moodColor),
                  const Spacer(flex: 1),
                  _buildTapButton(context, isPolish, moodColor),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isPolish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withOpacity(0.8), size: 18),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.mood.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.mood.color.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.mood.icon, color: Colors.white.withOpacity(0.9), size: 18),
                const SizedBox(width: 6),
                Text(
                  isPolish ? widget.mood.displayName : widget.mood.displayNameEn,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildShakeArea(BuildContext context, bool isPolish, Color moodColor) {
    return FadeTransition(
      opacity: _hintFade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Transform.scale(
              scale: _pulse.value,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      moodColor.withOpacity(0.3),
                      moodColor.withOpacity(0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: moodColor.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _iconBounce,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(_iconBounce.value, 0),
                    child: Center(
                      child: Icon(
                        Icons.phone_android_rounded,
                        size: 64,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, moodColor.withOpacity(0.9)],
            ).createShader(bounds),
            child: Text(
              isPolish ? 'Potrząśnij telefonem' : 'Shake your phone',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isPolish ? 'aby wylosować cytat' : 'to reveal a quote',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),
          _AnimatedShakeArrows(color: moodColor),
        ],
      ),
    );
  }

  Widget _buildTapButton(BuildContext context, bool isPolish, Color moodColor) {
    return FadeTransition(
      opacity: _hintFade,
      child: GestureDetector(
        onTap: _onShakeDetected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            isPolish ? 'lub dotknij tutaj' : 'or tap here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedShakeArrows extends StatefulWidget {
  final Color color;
  const _AnimatedShakeArrows({required this.color});

  @override
  State<_AnimatedShakeArrows> createState() => _AnimatedShakeArrowsState();
}

class _AnimatedShakeArrowsState extends State<_AnimatedShakeArrows>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final offset = _ctrl.value * 10;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(-offset, 0),
              child: Icon(Icons.chevron_left_rounded,
                  color: widget.color.withOpacity(0.4), size: 28),
            ),
            Transform.translate(
              offset: Offset(-offset * 0.5, 0),
              child: Icon(Icons.chevron_left_rounded,
                  color: widget.color.withOpacity(0.25), size: 28),
            ),
            const SizedBox(width: 20),
            Transform.translate(
              offset: Offset(offset * 0.5, 0),
              child: Icon(Icons.chevron_right_rounded,
                  color: widget.color.withOpacity(0.25), size: 28),
            ),
            Transform.translate(
              offset: Offset(offset, 0),
              child: Icon(Icons.chevron_right_rounded,
                  color: widget.color.withOpacity(0.4), size: 28),
            ),
          ],
        );
      },
    );
  }
}

class _ShakeStarsPainter extends CustomPainter {
  final Color accentColor;
  final Random _rng = Random(42);

  _ShakeStarsPainter(this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 50; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = _rng.nextDouble() * 1.5 + 0.3;
      final isAccent = i % 5 == 0;
      final color = isAccent ? accentColor : Colors.white;
      final o = _rng.nextDouble() * (isAccent ? 0.3 : 0.4) + 0.1;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = color.withOpacity(o)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isAccent ? 2.0 : 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
