import 'package:flutter/material.dart';
import 'turak.dart';
import 'kedvencek.dart';
import 'lexikon.dart';
import 'statisztika.dart';
import 'adatkezeles.dart';

void main() {
  runApp(const HorgaszNaploApp());
}

class HorgaszNaploApp extends StatelessWidget {
  const HorgaszNaploApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horgásznapló & Halhatározó',
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

// --- SPLASH SCREEN (4 másodperces induló képernyő) ---
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
            // Saját logó betöltése az assets könyvtárból
            Image.asset('assets/2825.png', height: 120, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const Text(
              'HORGÁSZNAPLÓ\n& HALHATÁROZÓ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
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

// --- FŐMENÜ / ALSÓ NAVIGÁCIÓS KERET ---
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Horgásznapló & Halhatározó', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Adatkezelés (Export / Import / Törzsadatok) gomb a jobb felső sarokban
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.greenAccent),
            tooltip: 'Adatkezelés és Törzsadatok',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdatKezeletScreen()),
              );
            },
          ),
        ],
      ),
      body: _kepernyok[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF161616),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sailing), label: 'Túrák'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Kedvencek'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Halfajok'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statisztika'),
        ],
      ),
    );
  }
}
