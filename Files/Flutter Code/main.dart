import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:palay_detector_v3/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/theme_notifier.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/settings_screen.dart';

const _supabaseUrl = 'https://hxmgeijqxelaooperbve.supabase.co';
const _supabaseAnonKey = 'sb_publishable_ImTBQWGV56ArdcWdxV32mw_TZUzWGUv';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  final cameras = await availableCameras();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: PalayApp(cameras: cameras),
    ),
  );
}

class PalayApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const PalayApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      title: 'Palay Detector',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: MainShell(cameras: cameras),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1505),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7CB342),
        secondary: Color(0xFFAED581),
        surface: Color(0xFF141E09),
        onSurface: Colors.white,
      ),
      cardColor: const Color(0xFF1A2810),
      dividerColor: Colors.white12,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1505),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111A08),
        selectedItemColor: Color(0xFF7CB342),
        unselectedItemColor: Colors.white38,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F8EE),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5D8A3C),
        secondary: Color(0xFF7CB342),
        surface: Colors.white,
        onSurface: Color(0xFF1A2810),
      ),
      cardColor: Colors.white,
      dividerColor: Colors.black12,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F8EE),
        foregroundColor: Color(0xFF1A2810),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF5D8A3C),
        unselectedItemColor: Colors.black38,
      ),
    );
  }
}


class MainShell extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MainShell({super.key, required this.cameras});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const HistoryScreen(),
      CameraScreen(cameras: widget.cameras),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt_rounded),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
