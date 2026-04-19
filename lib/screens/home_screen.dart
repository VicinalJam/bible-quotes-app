import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/mood.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import 'shake_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _crossRotation;
  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _entranceFade;
  late Animation<double> _entranceScale;

  double _carouselAngle = 0;
  double _velocity = 0;
  int _selectedIndex = 0;

  static const int _cardCount = 6;
  static const double _anglePerCard = 2 * pi / _cardCount;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _crossRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic));

    _entranceFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _entranceScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.elasticOut)),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _crossRotation.dispose();
    _entranceController.dispose();
    _snapController?.dispose();
    super.dispose();
  }

  AnimationController? _snapController;

  void _onPanUpdate(DragUpdateDetails details) {
    _snapController?.stop();
    _snapController?.dispose();
    _snapController = null;
    setState(() {
      _carouselAngle += details.delta.dx * 0.012;
      _velocity = details.delta.dx * 0.012;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final flingVelocity = details.velocity.pixelsPerSecond.dx * 0.004;
    _animateWithMomentum(flingVelocity);
  }

  void _animateWithMomentum(double flingVelocity) {
    final targetAngle = _carouselAngle + flingVelocity * 0.5;
    final snappedIndex = (-targetAngle / _anglePerCard).round() % _cardCount;
    final snappedAngle = -snappedIndex * _anglePerCard;

    final duration = (flingVelocity.abs() * 200 + 300).clamp(300, 800).toInt();

    _snapController?.dispose();
    _snapController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );
    final curve = CurvedAnimation(parent: _snapController!, curve: Curves.easeOutQuart);
    final startAngle = _carouselAngle;

    _snapController!.addListener(() {
      setState(() {
        _carouselAngle = startAngle + (snappedAngle - startAngle) * curve.value;
      });
    });
    _snapController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _selectedIndex = snappedIndex % _cardCount);
      }
    });
    _snapController!.forward();
  }

  void _onCardTap(int index) {
    HapticFeedback.lightImpact();
    final mood = Mood.all[index % _cardCount];
    Navigator.push(context, _fadeScaleRoute(ShakeScreen(mood: mood)));
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isPolish = appProvider.currentLanguage == 'pl';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final carouselRadius = screenSize.width * 0.44;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B4E),
              Color(0xFF1A0F2E),
              Color(0xFF120B22),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _StarsPainter()),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isPolish, isDark),
                  const SizedBox(height: 8),
                  _buildTitle(context, isPolish),
                  Expanded(
                    child: FadeTransition(
                      opacity: _entranceFade,
                      child: ScaleTransition(
                        scale: _entranceScale,
                        child: GestureDetector(
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          behavior: HitTestBehavior.translucent,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final areaW = constraints.maxWidth;
                              final areaH = constraints.maxHeight;
                              return Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  _buildCross(),
                                  ..._buildCarouselCards(
                                    context, isPolish, carouselRadius,
                                    areaW, areaH,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomHint(context, isPolish),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, bool isPolish) {
    return FadeTransition(
      opacity: _headerFade,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          isPolish ? 'Jak się czujesz?' : 'How are you feeling?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
        ),
      ),
    );
  }

  Widget _buildCross() {
    return AnimatedBuilder(
      animation: _crossRotation,
      builder: (_, __) {
        final t = _crossRotation.value * 2 * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(t * 0.3 + _carouselAngle * 0.5)
            ..rotateX(0.15),
          child: CustomPaint(
            size: const Size(120, 170),
            painter: _CrossPainter(rotationY: t * 0.3 + _carouselAngle * 0.5),
          ),
        );
      },
    );
  }

  List<Widget> _buildCarouselCards(
    BuildContext context, bool isPolish, double radius,
    double areaW, double areaH,
  ) {
    final List<_CardData> cards = [];
    final centerX = areaW / 2;
    final centerY = areaH / 2;

    for (int i = 0; i < _cardCount; i++) {
      final angle = _carouselAngle + i * _anglePerCard;
      final x = sin(angle) * radius;
      final z = cos(angle);
      final scale = 0.5 + 0.5 * ((z + 1) / 2);
      final opacity = 0.25 + 0.75 * ((z + 1) / 2);

      cards.add(_CardData(
        index: i,
        x: x,
        z: z,
        scale: scale,
        opacity: opacity,
        angle: angle,
      ));
    }

    cards.sort((a, b) => a.z.compareTo(b.z));

    const baseW = 160.0;
    const baseH = 200.0;

    return cards.map((card) {
      final mood = Mood.all[card.index];
      final verticalOffset = -card.z * 30;

      return Positioned(
        left: centerX + card.x - baseW / 2,
        top: centerY + verticalOffset - baseH / 2,
        child: GestureDetector(
          onTap: () => _onCardTap(card.index),
          child: Opacity(
            opacity: card.opacity.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(-card.angle * 0.15)
                ..scale(card.scale),
              child: _CarouselCard(
                mood: mood,
                isPolish: isPolish,
                width: baseW,
                height: baseH,
                isFront: card.z > 0.5,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomHint(BuildContext context, bool isPolish) {
    return FadeTransition(
      opacity: _entranceFade,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 8),
            Text(
              isPolish ? 'Przewiń palcem' : 'Swipe to explore',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPolish, bool isDark) {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B5EA7), Color(0xFFB794D6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B5EA7).withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPolish ? 'Witaj ✨' : 'Hello ✨',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB794D6),
                          ),
                    ),
                    Text(
                      isPolish ? 'Znajdź inspirację' : 'Find inspiration',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
              _SettingsButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardData {
  final int index;
  final double x, z, scale, opacity, angle;
  _CardData({
    required this.index,
    required this.x,
    required this.z,
    required this.scale,
    required this.opacity,
    required this.angle,
  });
}

class _CarouselCard extends StatelessWidget {
  final Mood mood;
  final bool isPolish;
  final double width;
  final double height;
  final bool isFront;

  const _CarouselCard({
    required this.mood,
    required this.isPolish,
    required this.width,
    required this.height,
    required this.isFront,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mood.color.withOpacity(isFront ? 0.35 : 0.15),
            const Color(0xFF2A1545).withOpacity(0.9),
          ],
        ),
        border: Border.all(
          color: mood.color.withOpacity(isFront ? 0.45 : 0.15),
          width: isFront ? 1.5 : 0.5,
        ),
        boxShadow: isFront
            ? [
                BoxShadow(
                  color: mood.color.withOpacity(0.45),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF7B5EA7).withOpacity(0.2),
                  blurRadius: 50,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mood.color.withOpacity(0.2),
                      mood.color.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            mood.color.withOpacity(0.5),
                            mood.color.withOpacity(0.08),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: mood.color.withOpacity(isFront ? 0.6 : 0.2),
                            blurRadius: isFront ? 24 : 10,
                            spreadRadius: isFront ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          mood.icon,
                          size: 34,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isPolish ? mood.displayName : mood.displayNameEn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(isFront ? 0.95 : 0.6),
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: mood.color.withOpacity(isFront ? 0.6 : 0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  final double rotationY;
  _CrossPainter({required this.rotationY});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final cosY = cos(rotationY);
    final depth = cosY.abs();

    final hW = size.width * 0.12 * (0.4 + 0.6 * depth);
    final vH = size.height * 0.48;
    final hH = size.height * 0.12;
    final crossTop = cy - vH / 2;
    final armY = crossTop + vH * 0.28;

    final glowPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: hW * 4, height: vH * 0.8),
      glowPaint,
    );

    final mainGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFD700).withOpacity(0.9),
        const Color(0xFFD4AF37).withOpacity(0.85),
        const Color(0xFFB8941F).withOpacity(0.7),
      ],
    );

    final vertRect = Rect.fromLTWH(cx - hW, crossTop, hW * 2, vH);
    final vertPaint = Paint()
      ..shader = mainGrad.createShader(vertRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(vertRect, const Radius.circular(4)),
      vertPaint,
    );

    final armW = size.width * 0.45;
    final armRect = Rect.fromLTWH(cx - armW, armY, armW * 2, hH);
    final armPaint = Paint()
      ..shader = mainGrad.createShader(armRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(armRect, const Radius.circular(4)),
      armPaint,
    );

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25 * depth);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hW * 0.3, crossTop + 4, hW * 0.6, vH - 8),
        const Radius.circular(3),
      ),
      highlightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - armW + 4, armY + 2, armW * 2 - 8, hH * 0.35),
        const Radius.circular(2),
      ),
      highlightPaint,
    );

    final centerGlow = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, armY + hH / 2), 8, centerGlow);
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) =>
      oldDelegate.rotationY != rotationY;
}

class _SettingsButton extends StatefulWidget {
  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _rotation = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        Navigator.push(context, _slideRoute(const SettingsScreen()));
      },
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (_, __) => RotationTransition(
          turns: _rotation,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(Icons.settings_rounded, size: 22, color: Colors.white.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }
}

PageRoute _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

PageRoute _fadeScaleRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

class _StarsPainter extends CustomPainter {
  final Random _rng = Random(77);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 80; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = _rng.nextDouble() * 1.5 + 0.3;
      final o = _rng.nextDouble() * 0.5 + 0.1;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white.withOpacity(o)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
