import 'package:flutter/material.dart';
import 'package:tiq_service_mob/screens/profile_screen.dart';

import 'screens/login_screen.dart';
import 'screens/station_list_screen.dart';
import 'controllers/inspection_api_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryTeal = Color(0xFF37A8C0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Station Inspection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryTeal),
        scaffoldBackgroundColor: const Color(0xFFF5FBFC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: primaryTeal, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: primaryTeal,
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const _RootDecider(),
        '/home': (ctx) => const HomeScreen(),
        '/stations': (ctx) => const StationListScreen(),
        '/login': (ctx) => const LoginScreen(),
      },
    );
  }
}

class _RootDecider extends StatefulWidget {
  const _RootDecider();

  @override
  State<_RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<_RootDecider> {
  final _api = InspectionApiController();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    const maxWait = Duration(seconds: 2);
    final deadline = DateTime.now().add(maxWait);
    while (DateTime.now().isBefore(deadline)) {
      final inProgress = prefs.getBool('auth_sync_in_progress') ?? false;
      if (!inProgress) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final token = await _api.getToken();
    if (mounted) {
      setState(() => _checking = false);
      if (token == null || token.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF37A8C0),
        child: Center(
          child: _checking
              ? const CircularProgressIndicator(color: Colors.white)
              : const SizedBox(),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InspectionApiController _api = InspectionApiController();

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF37A8C0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'TankIQ Service',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') await _logout();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: primaryColor),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Center(
                child: Text(
                  'TIQ Station System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _drawerItem(Icons.local_gas_station, 'Stations', '/stations'),
            _drawerItem(
              Icons.add_circle_outline,
              'New Inspection',
              null,
              // builder: (_) => const StationFormScreen(),
            ),
            _drawerItem(
              Icons.list,
              'View Inspections',
              null,
              // builder: (_) => const InspectionListScreen(),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Icon(Icons.local_gas_station, size: 90, color: primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Station Inspection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage and conduct inspections easily and efficiently.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'New Inspection',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text(
                'All Inspections',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    String? route, {
    WidgetBuilder? builder,
  }) {
    const primaryColor = Color(0xFF37A8C0);

    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      onTap: () {
        Navigator.of(context).pop();
        if (route != null) {
          Navigator.of(context).pushNamed(route);
        } else if (builder != null) {
          Navigator.push(context, MaterialPageRoute(builder: builder));
        }
      },
    );
  }
}
