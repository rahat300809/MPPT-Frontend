import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'backend/mppt_backend.dart';
import 'backend/weather/weather_service.dart';
import 'frontend/screens/connect_page.dart';
import 'frontend/screens/shell.dart';
import 'frontend/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MpptBackend()),
        ChangeNotifierProvider(create: (_) => WeatherService()),
      ],
      child: const InnoMpptApp(),
    ),
  );
}

class InnoMpptApp extends StatelessWidget {
  const InnoMpptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InnoMPPT',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
      routes: {
        '/connect': (context) => const ConnectPage(),
      },
    );
  }
}
