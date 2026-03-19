import 'package:flutter/material.dart';

import '../../collect/presentation/collect_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: CollectScreen()));
  }
}
