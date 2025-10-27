import 'package:flutter/material.dart';
import 'package:tiq_service_mob/screens/inspection_list_screen.dart';
import 'package:tiq_service_mob/screens/profile_screen.dart';
import 'package:tiq_service_mob/screens/station_form_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/login_screen.dart';
import 'screens/station_list_screen.dart';
import 'controllers/inspection_api_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions before launching the app
  await _requestPermissions();

  runApp(const MyApp());
}

/// Request storage and photos permission
Future<void> _requestPermissions() async {
  final statuses = await [
    Permission.storage,
    Permission.photos,
    Permission.videos,
  ].request();

  if (statuses[Permission.storage]?.isGranted ?? false) {
    // ignore: avoid_print
    print('Storage permission granted');
  } else {
    // ignore: avoid_print
    print('Storage permission denied');
  }

  if (statuses[Permission.photos]?.isGranted ?? false) {
    // ignore: avoid_print
    print('Photos permission granted');
  } else {
    // ignore: avoid_print
    print('Photos permission denied');
  }
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
          Padding(
            padding: const EdgeInsets.only(),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await _logout();
                } else if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 4,
              offset: const Offset(0, 50),
              constraints: const BoxConstraints(minWidth: 130, maxWidth: 220),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'profile',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: Color(0xFF37A8C0)),
                      SizedBox(width: 8), // smaller spacing
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: Color(0xFF404040),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFF404040),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              icon: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF37A8C0)),
              ),
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
                  'TankIQ Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _drawerItem(Icons.local_gas_station, 'Station List', '/stations'),
            _drawerItem(
              Icons.add_circle_outline,
              'New Inspection',
              null,
              builder: (_) =>
                  const InspectionFormScreen(title: 'Inspection Form'),
            ),
            _drawerItem(
              Icons.list,
              'Inspection list',
              null,
              builder: (_) => const InspectionListScreen(),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(24),
                child: Icon(
                  Icons.local_gas_station,
                  size: 80,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Station Inspection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Manage and conduct inspections effortlessly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Start New Inspection',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const InspectionFormScreen(title: "New Inspection"),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text(
                    'View All Inspections',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(
                      // ignore: deprecated_member_use
                      color: primaryColor.withOpacity(0.8),
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InspectionListScreen(),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
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
