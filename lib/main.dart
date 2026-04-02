import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/database/database_initializer.dart';
import 'navigation/main_navigation.dart';
import 'services/notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseInitializer.initialize();
  await NotificationService.instance.initialize();
  await NotificationService.instance.scheduleDailyMedicationReminder();
  runApp(const MedControlApp());
}

class MedControlApp extends StatelessWidget {
  const MedControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med Control',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE77070),
          primary: const Color(0xFFE77070),
          surface: const Color(0xFFF6F7FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F8),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}
