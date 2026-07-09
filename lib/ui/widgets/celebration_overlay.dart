import 'dart:math';
import 'package:flutter/material.dart';

class CelebrationOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  late AnimationController _particleController;
  final _random = Random();
  final _particles = <_Particle>[];
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _scaleController.forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 8 + _random.nextDouble() * 16,
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        speed: 0.3 + _random.nextDouble() * 0.7,
        angle: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenSize == Size.zero) {
      _screenSize = MediaQuery.of(context).size;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _particleController]),
        builder: (context, child) {
          return Container(
            color: Colors.black54,
            child: Stack(
              children: [
                ..._particles.map((p) => Positioned(
                  left: (p.x + sin(_particleController.value * p.speed * 10 + p.angle) * 0.1) * _screenSize.width,
                  top: (p.y + cos(_particleController.value * p.speed * 10 + p.angle) * 0.1) * _screenSize.height,
                  child: Container(
                    width: p.size * (1 + sin(_particleController.value * 3 + p.angle) * 0.3),
                    height: p.size * (1 + sin(_particleController.value * 3 + p.angle) * 0.3),
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )),
                Center(
                  child: Transform.scale(
                    scale: 0.5 + _scaleAnim.value * 0.5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎉', style: TextStyle(fontSize: 64 + _scaleAnim.value * 16)),
                        const SizedBox(height: 16),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                        const SizedBox(height: 32),
                        const Text('Touchez pour continuer', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x, y, size, speed, angle;
  final Color color;
  _Particle({required this.x, required this.y, required this.size, required this.color, required this.speed, required this.angle});
}
