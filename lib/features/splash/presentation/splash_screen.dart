import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/ui/app_colors.dart';
import '../../shell/presentation/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _loadingAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _loadingAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const AppShell(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Optional map background at 5% opacity
          Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/images/map_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Central branding
                Column(
                  children: [
                    // Minibus icon in amber circle
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryAccent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/minibus_icon.svg',
                          width: 55,
                          height: 35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'أجرة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 60,
                        height: 1.0,
                        letterSpacing: -1.5,
                        color: AppColors.primaryAccent,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'رفيق المشوار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                        height: 1.4,
                        color: AppColors.primaryAccent.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 4),

                // Footer
                Column(
                  children: [
                    // Loading bar
                    AnimatedBuilder(
                      animation: _loadingAnim,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 4,
                            width: double.infinity,
                            color: AppColors.primaryAccent.withValues(alpha: 0.2),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _loadingAnim.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Brand mark
                    Opacity(
                      opacity: 0.4,
                      child: Text(
                        '2OGRA',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          letterSpacing: 1.2,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
