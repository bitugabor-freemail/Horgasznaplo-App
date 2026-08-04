import 'package:flutter/material.dart';
import 'torzsadatok.dart';
import 'turak.dart';
import 'kedvencek.dart'; // <-- Hozzáadva a Kedvencek importja

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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Most már a második képernyő is éles!
  final List<Widget> _screens = [
    const TurakScreen(),
    const KedvencekScreen(), // <-- Bekötve!
    const PlaceholderScreen(title: 'Halfajok Lexikon\n(Hamarosan a lexikon.dart-ból)'),
    const PlaceholderScreen(title: 'Statisztika\n(Hamarosan a statisztika.dart-ból)'),
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
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => index == 4
              ? const TorzsadatokScreen()
              : const PlaceholderScreen(title: 'Adatkezelés: Import/Export\n(adatkezeles.dart)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horgásznapló', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
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

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.green[800]),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
