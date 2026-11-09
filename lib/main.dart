import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/police_tactical_theme.dart';
import 'core/services/police_notification_service.dart';
import 'features/command_center/presentation/screens/police_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await PoliceNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Init police notification error: $e');
  }
  runApp(
    const ProviderScope(
      child: SiPelantasPolriApp(),
    ),
  );
}

class SiPelantasPolriApp extends StatelessWidget {
  const SiPelantasPolriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SI-PELANTAS POLRI (POLANTAS & UNIT KAMSEL)',
      debugShowCheckedModeBanner: false,
      theme: PoliceTacticalTheme.darkCommandTheme,
      home: const PoliceSplashScreen(),
    );
  }
}
