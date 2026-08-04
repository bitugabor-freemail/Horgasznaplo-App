import 'package:flutter/material.dart';

void main() {
  runApp(const HorgaszApp());
}

class HorgaszApp extends StatelessWidget {
  const HorgaszApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horgásznapló',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    NaploPage(),
    HalhatarozoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green[800],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Fogási Napló',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phishing),
            label: 'Halhatározó',
          ),
        ],
      ),
    );
  }
}

// ------------------- FOGÁSI NAPLÓ -------------------
class NaploPage extends StatefulWidget {
  const NaploPage({super.key});

  @override
  State<NaploPage> createState() => _NaploPageState();
}

class _NaploPageState extends State<NaploPage> {
  final List<Map<String, String>> _fogasok = [];

  final _halfajController = TextEditingController();
  final _sulyController = TextEditingController();

  void _ujFogasPárbeszéd() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Új fogás rögzítése'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _halfajController,
              decoration: const InputDecoration(labelText: 'Hal fajtája (pl. Ponty)'),
            ),
            TextField(
              controller: _sulyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Súly (kg)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégse'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_halfajController.text.isNotEmpty) {
                setState(() {
                  _fogasok.add({
                    'hal': _halfajController.text,
                    'suly': '${_sulyController.text} kg',
                    'datum': DateTime.now().toString().split(' ')[0],
                  });
                });
                _halfajController.clear();
                _sulyController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Mentés'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horgásznapló'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _fogasok.isEmpty
          ? const Center(
              child: Text(
                'Még nincs rögzített fogásod.\nKattints a + gombra!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _fogasok.length,
              itemBuilder: (context, index) {
                final item = _fogasok[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.set_meal, color: Colors.white),
                    ),
                    title: Text(item['hal']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Dátum: ${item['datum']}'),
                    trailing: Text(
                      item['suly']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ujFogasPárbeszéd,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ------------------- HALHATÁROZÓ -------------------
class HalhatarozoPage extends StatelessWidget {
  const HalhatarozoPage({super.key});

  final List<Map<String, String>> _halak = const [
    {
      'nev': 'Ponty',
      'leiras': 'Legelterjedtebb békés halunk. Hátúszója hosszú, száján 4 bajuszszál található.',
      'meret': 'Legkisebb megtartható méret: 30 cm'
    },
    {
      'nev': 'Süllő',
      'leiras': 'Népszerű ragadozó hal. Hátúszója osztott, szájában ebefogak találhatók.',
      'meret': 'Legkisebb megtartható méret: 30 cm'
    },
    {
      'nev': 'Csuka',
      'leiras': 'Kiváló látású, agresszív ragadozó. Hosszúkás test, kacsa-csőrre emlékeztető fej.',
      'meret': 'Legkisebb megtartható méret: 40 cm'
    },
    {
      'nev': 'Harcsa',
      'leiras': 'Legnagyobb édesvízi ragadozónk. Hosszú pofaszakáll, apró szemek.',
      'meret': 'Legkisebb megtartható méret: 60 cm'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halhatározó'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _halak.length,
        itemBuilder: (context, index) {
          final hal = _halak[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.water, color: Colors.blue),
              title: Text(hal['nev']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text(hal['leiras']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        hal['meret']!,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
