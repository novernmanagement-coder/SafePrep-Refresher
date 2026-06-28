import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';
import 'mixpanel_service.dart';
import 'intro_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStatePersistence.load();
  try {
    await MixpanelService.instance.init();
  } catch (_) {}
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final unlocked = AppState().hasUnlockedApp;
  runApp(SafePrepRefresherApp(unlocked: unlocked));
}

class SafePrepRefresherApp extends StatelessWidget {
  final bool unlocked;
  const SafePrepRefresherApp({super.key, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePrep Refresher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A3A5C)),
        useMaterial3: true,
      ),
      home: unlocked ? const HomePage() : const IntroPage(),
    );
  }
}
