import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'polri_home_shell.dart';

class PoliceSplashScreen extends ConsumerStatefulWidget {
  const PoliceSplashScreen({super.key});

  @override
  ConsumerState<PoliceSplashScreen> createState() => _PoliceSplashScreenState();
}

class _PoliceSplashScreenState extends ConsumerState<PoliceSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _animController.forward();

    // Transisi mulus ke HomeShell (Shell otomatis mengontrol login vs dashboard dengan AnimatedSwitcher)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const PolriHomeShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: Stack(
        children: [
          // Ambient background glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF8A3D).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central content: Logo & Title
          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Official Korlantas Lalu Lintas Shield
                        Container(
                          width: 140,
                          height: 140,
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/korlantas_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Application Name
                        const Text(
                          'SI-PELANTAS POLRI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle Satlantas
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF8A3D).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF8A3D)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'SATLANTAS POLRES MOJOKERTO KOTA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFFFF9E44),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Sistem Penindakan & Monitoring Pelanggaran Siswa',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Loading Indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFFF8A3D),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memuat Sistem Otoritas Presisi...',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
