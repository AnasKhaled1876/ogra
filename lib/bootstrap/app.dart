import 'package:flutter/material.dart';

import '../core/ui/app_theme.dart';
import '../features/splash/presentation/splash_screen.dart';

class OgraApp extends StatelessWidget {
  const OgraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2ogra',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
