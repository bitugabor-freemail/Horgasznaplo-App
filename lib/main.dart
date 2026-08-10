// lib/main.dart
import 'package:flutter/material.dart';
import 'turak.dart';
import 'kedvencek.dart';
import 'lexikon.dart';
import 'statisztika.dart';
import 'adatkezeles.dart';
import 'torzsadatok.dart';

void main() {
  runApp(const HorgaszNaploApp());
}

class HorgaszNaploApp extends StatelessWidget {
  const HorgaszNaploApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horgásznapló',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primarySwatch: Colors.green,
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.green,
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigalas();
  }

  Future<void> _navigalas() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FomenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/2825.png', height: 180, fit: BoxFit.contain),
            const SizedBox(height: 28),
            const Text(
              'Horgásznapló',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}

// --- FŐMENÜ / ALSÓ NAVIGÁCIÓS KERET & HAMBURGER MENÜ (DRAWER) ---
class FomenuScreen extends StatefulWidget {
  const FomenuScreen({super.key});

  @override
  State<FomenuScreen> createState() => _FomenuScreenState();
}

class _FomenuScreenState extends State<FomenuScreen> {
  int _currentIndex = 0;

  final List<Widget> _kepernyok = [
    const TurakScreen(),
    const KedvencekScreen(),
    const LexikonScreen(),
    const StatisztikaScreen(),
  ];

  final List<String> _cimek = [
    'Horgásztúráim',
    'Kedvenc fogások',
    'Halfajok / Lexikon',
    'Statisztika',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        title: Text(_cimek[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF161616),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green[900]?.withOpacity(0.5)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Horgásznapló', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Verzió 1.0.0', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined, color: Colors.greenAccent),
              title: const Text('1. Horgásztúráim'),
              onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.greenAccent),
              title: const Text('2. Kedvenc fogások'),
              onTap: () { setState(() => _currentIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.library_books_outlined, color: Colors.greenAccent),
              title: const Text('3. Halfajok'),
              onTap: () { setState(() => _currentIndex = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.greenAccent),
              title: const Text('4. Statisztika'),
              onTap: () { setState(() => _currentIndex = 3); Navigator.pop(context); },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.greenAccent),
              title: const Text('5. Törzsadatok'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TorzsadatokScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.greenAccent),
              title: const Text('6. Adatkezelés'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdatkezelesScreen()));
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white54),
              title: const Text('7. Névjegy'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text('Névjegy', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Készítette: Google Gemini & B2', style: TextStyle(color: Colors.white, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Verzió: 1.0.0', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Bezár', style: TextStyle(color: Colors.greenAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _kepernyok[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 3 ? 0 : _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF161616),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Túrák'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Kedvencek'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Halfajok'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statisztika'),
        ],
      ),
    );
  }
}
