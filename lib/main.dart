import 'package:flutter/material.dart';
import 'dart:async';

// Képernyők importálása
import 'turak.dart';
import 'kedvencek.dart';
import 'lexikon.dart';
import 'statisztika.dart';
import 'torzsadatok.dart';
import 'adatkezeles.dart';

void main() {
  runApp(const HorgasznaploApp());
}

class HorgasznaploApp extends StatelessWidget {
  const HorgasznaploApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horgásznapló & Halhatározó',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.green[700],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161616),
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.green,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---- SPLASH SCREEN (INDÍTÓKÉPERNYŐ) ----
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 4 másodperces várakozás, majd irány a Főképernyő
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FoKepernyo()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ide jön majd a saját logód, addig egy elegáns ikon
            Icon(Icons.sailing, size: 100, color: Colors.green[700]),
            const SizedBox(height: 24),
            const Text(
              'HORGÁOZNAPLÓ\n& HALHATÁROZÓ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.greenAccent),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}

// ---- FŐKÉPERNYŐ (HIBRID NAVIGÁCIÓ) ----
class FoKepernyo extends StatefulWidget {
  const FoKepernyo({super.key});

  @override
  State<FoKepernyo> createState() => _FoKepernyoState();
}

class _FoKepernyoState extends State<FoKepernyo> {
  int _aktualisIndex = 0;

  // Az alsó menü 4 képernyője
  final List<Widget> _kepernyok = [
    const TurakScreen(),
    const KedvencekScreen(),
    const LexikonScreen(),
    const StatisztikaScreen(),
  ];

  final List<String> _cimek = [
    'Horgásztúráim',
    'Kedvenc Fogások',
    'Halfajok & Kvíz',
    'Statisztika',
  ];

  void _navigalas(int index) {
    setState(() {
      _aktualisIndex = index;
    });
    Navigator.pop(context); // Bezárja a drawert, ha onnan kattintottak
  }

  void _ujAblak(Widget kepernyo) {
    Navigator.pop(context); // Drawer bezárása
    Navigator.push(context, MaterialPageRoute(builder: (context) => kepernyo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cimek[_aktualisIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green[900]),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.sailing, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Horgásznapló 1.0', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sailing, color: Colors.greenAccent),
              title: const Text('1. Horgásztúráim'),
              selected: _aktualisIndex == 0,
              onTap: () => _navigalas(0),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.redAccent),
              title: const Text('2. Kedvenc fogások'),
              selected: _aktualisIndex == 1,
              onTap: () => _navigalas(1),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.blueAccent),
              title: const Text('3. Halfajok (Lexikon)'),
              selected: _aktualisIndex == 2,
              onTap: () => _navigalas(2),
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.orangeAccent),
              title: const Text('4. Statisztika'),
              selected: _aktualisIndex == 3,
              onTap: () => _navigalas(3),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white70),
              title: const Text('5. Törzsadatok'),
              onTap: () => _ujAblak(const TorzsadatokScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.white70),
              title: const Text('6. Adatkezelés (Export)'),
              onTap: () => _ujAblak(const AdatkezelesScreen()),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white54),
              title: const Text('7. Névjegy'),
              onTap: () => _ujAblak(const NevjegyScreen()),
            ),
          ],
        ),
      ),
      body: _kepernyok[_aktualisIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _aktualisIndex,
        onTap: (idx) => setState(() => _aktualisIndex = idx),
        backgroundColor: const Color(0xFF161616),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sailing), label: 'Túrák'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Kedvencek'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Halfajok'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Statisztika'),
        ],
      ),
    );
  }
}

// ---- NÉVJEGY KÉPERNYŐ ----
class NevjegyScreen extends StatelessWidget {
  const NevjegyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Névjegy')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sailing, size: 80, color: Colors.green[700]),
              const SizedBox(height: 24),
              const Text('Horgásznapló & Halhatározó', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              const SizedBox(height: 8),
              const Text('Verzió: 1.0 (Végleges kiadás)', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 32),
              const Text('Ez az alkalmazás szenvedéllyel készült horgászok számára. Offline működik, minden adatot a telefonodon tárol.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
