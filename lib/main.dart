import 'package:flutter/material.dart';
import 'torzsadatok.dart';
import 'turak.dart';
import 'kedvencek.dart';
import 'lexikon.dart';
import 'statisztika.dart';
import 'adatkezeles.dart';
import 'adattarolo.dart'; // <-- ÚJ IMPORT AZ ADATBÁZISHOZ

void main() {
  runApp(const HorgaszApp());
}

class HorgaszApp extends StatelessWidget {
  const HorgaszApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horgásznapló & Halhatározó',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.green[600]!,
          secondary: Colors.greenAccent,
          surface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          selectedItemColor: Colors.green[500],
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}

// ---- BEJELENTKEZŐ (SPLASH) KÉPERNYŐ ----
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _adatokBetolteseEsInditas(); // <-- ITT INDUL A BETÖLTÉS
  }

  Future<void> _adatokBetolteseEsInditas() async {
    // Később ide jön a tényleges adatok memóriába olvasása
    
    // 4 másodperc várakozás a dizájn kedvéért
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: size.height / 2,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/2825.png',
                width: size.width * 0.5,
              ),
            ),
          ),
          Positioned(
            top: (size.height / 2) + 20,
            left: 0,
            right: 0,
            child: const Text(
              'Horgásznapló',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- FŐ KÉPERNYŐ ----
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TurakScreen(),
    const KedvencekScreen(),
    const LexikonScreen(),
    const StatisztikaScreen(),
  ];

  final List<String> _appBarTitles = [
    'Horgásztúráim',
    'Kedvenc fogások',
    'Halfajok Lexikon',
    'Statisztika',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onDrawerItemTapped(int index) {
    Navigator.pop(context);
    
    if (index < 4) {
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text('Névjegy'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Készítette:', style: TextStyle(color: Colors.white54, fontSize: 14)),
              SizedBox(height: 4),
              Text('Google Gemini & B2', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Verzió:', style: TextStyle(color: Colors.white54, fontSize: 14)),
              SizedBox(height: 4),
              Text('1.0.0', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bezárás', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => index == 4
              ? const TorzsadatokScreen()
              : const AdatkezelesScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.quiz, color: Colors.greenAccent),
              tooltip: 'Hal Felismerő Kvíz',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KvizScreen()),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white70),
              onPressed: () {},
            )
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[900],
                border: const Border(bottom: BorderSide(color: Colors.green, width: 2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.phishing, size: 48, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Horgásznapló', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('& Halhatározó', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.sailing, 'Horgásztúráim', 0),
            _buildDrawerItem(Icons.favorite, 'Kedvenc fogások', 1),
            _buildDrawerItem(Icons.set_meal, 'Halfajok', 2),
            _buildDrawerItem(Icons.bar_chart, 'Statisztika', 3),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(color: Colors.white24),
            ),
            _buildDrawerItem(Icons.storage, 'Törzsadatok', 4),
            _buildDrawerItem(Icons.import_export, 'Adatkezelés', 5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(color: Colors.white24),
            ),
            _buildDrawerItem(Icons.info_outline, 'Névjegy', 6),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sailing), label: 'Túrák'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Kedvencek'),
          BottomNavigationBarItem(icon: Icon(Icons.set_meal), label: 'Halfajok'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statisztika'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index && index < 4;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.green[400] : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green[400] : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _onDrawerItemTapped(index),
    );
  }
}
