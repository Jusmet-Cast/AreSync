import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class FitCodexApp extends StatelessWidget {
  const FitCodexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FitCodex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
