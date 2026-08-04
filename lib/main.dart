import 'package:flutter/material.dart';
import 'halak.dart';

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
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
      ),
      home: const HomeScreen(),
    );
  }
}

class Fogas {
  final String halfaj;
  final double suly;
  final double hossz;
  final String csali;
  final String datum;
  final String megjegyzes;

  Fogas({
    required this.halfaj,
    required this.suly,
    required this.hossz,
    required this.csali,
    required this.datum,
    required this.megjegyzes,
  });
}

class Horgasztura {
  final String nev;
  final String helyszin;
  final String kezdetDatum;
  final List<Fogas> fogasok;

  Horgasztura({
    required this.nev,
    required this.helyszin,
    required this.kezdetDatum,
    List<Fogas>? fogasok,
  }) : fogasok = fogasok ?? [];
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final List<Horgasztura> _turak = [];

  final _turaNevController = TextEditingController();
  final _turaHelyszinController = TextEditingController();

  final _halfajController = TextEditingController();
  final _sulyController = TextEditingController();
  final _hosszController = TextEditingController();
  final _csaliController = TextEditingController();
  final _megjegyzesController = TextEditingController();

  void _ujTuraParbeszed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Új Horgásztúra Indítása'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _turaNevController,
                decoration: const InputDecoration(labelText: 'Túra neve *', hintText: 'pl. Balatoni Hétvége'),
              ),
              TextField(
                controller: _turaHelyszinController,
                decoration: const InputDecoration(labelText: 'Helyszín / Vízterület *', hintText: 'pl. Ráckevei-Duna'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: () {
              if (_turaNevController.text.isNotEmpty && _turaHelyszinController.text.isNotEmpty) {
                setState(() {
                  _turak.add(
                    Horgasztura(
                      nev: _turaNevController.text,
                      helyszin: _turaHelyszinController.text,
                      kezdetDatum: DateTime.now().toString().split(' ')[0],
                    ),
                  );
                });
                _turaNevController.clear();
                _turaHelyszinController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Túra Indítása'),
          ),
        ],
      ),
    );
  }

  void _ujFogasParbeszed(Horgasztura tura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Új fogás: ${tura.nev}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _halfajController,
                decoration: const InputDecoration(labelText: 'Hal fajtája * (pl. Ponty)'),
              ),
              TextField(
                controller: _sulyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Súly (kg) * (pl. 3.5)'),
              ),
              TextField(
                controller: _hosszController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Hossz (cm) (pl. 55)'),
              ),
              TextField(
                controller: _csaliController,
                decoration: const InputDecoration(labelText: 'Csali / Módszer (pl. Boilie / Feeder)'),
              ),
              TextField(
                controller: _megjegyzesController,
                decoration: const InputDecoration(labelText: 'Megjegyzés / Időjárás'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: () {
              if (_halfajController.text.isNotEmpty && _sulyController.text.isNotEmpty) {
                setState(() {
                  tura.fogasok.add(
                    Fogas(
                      halfaj: _halfajController.text,
                      suly: double.tryParse(_sulyController.text) ?? 0.0,
                      hossz: double.tryParse(_hosszController.text) ?? 0.0,
                      csali: _csaliController.text.isEmpty ? 'Nincs megadva' : _csaliController.text,
                      datum: DateTime.now().toString().split(' ')[0],
                      megjegyzes: _megjegyzesController.text,
                    ),
                  );
                });
                _halfajController.clear();
                _sulyController.clear();
                _hosszController.clear();
                _csaliController.clear();
                _megjegyzesController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Fogás Mentése'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppbarTitle()),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.green[900]),
              accountName: const Text('Horgásznapló & Határozó', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail: const Text('Professzionális vízparti kísérő'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.phishing, color: Colors.green, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cabin, color: Colors.green),
              title: const Text('Horgásztúrák'),
              selected: _selectedNavIndex == 0,
              onTap: () {
                setState(() => _selectedNavIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.green),
              title: const Text('Összes Fogási Napló'),
              selected: _selectedNavIndex == 1,
              onTap: () {
                setState(() => _selectedNavIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.green),
              title: const Text('Statisztikák'),
              selected: _selectedNavIndex == 2,
              onTap: () {
                setState(() => _selectedNavIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.set_meal, color: Colors.blue),
              title: const Text('Magyar Halhatározó (20+ faj)'),
              selected: _selectedNavIndex == 3,
              onTap: () {
                setState(() => _selectedNavIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel, color: Colors.orange),
              title: const Text('Szabályzat & Kíméletes Kezelés'),
              selected: _selectedNavIndex == 4,
              onTap: () {
                setState(() => _selectedNavIndex = 4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _buildSelectedBody(),
      floatingActionButton: _selectedNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _ujTuraParbeszed,
              backgroundColor: Colors.green[800],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Új Túra Indítása', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  String _getAppbarTitle() {
    switch (_selectedNavIndex) {
      case 0:
        return 'Horgásztúrák';
      case 1:
        return 'Összesített Fogási Napló';
      case 2:
        return 'Fogási Statisztikák';
      case 3:
        return 'Magyar Halhatározó';
      case 4:
        return 'Szabályzat és Védelem';
      default:
        return 'Horgásznapló';
    }
  }

  Widget _buildSelectedBody() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildTurakView();
      case 1:
        return _buildOsszesFogasView();
      case 2:
        return _buildStatisztikaView();
      case 3:
        return const HalhatarozoView();
      case 4:
        return const SzabalyzatView();
      default:
        return _buildTurakView();
    }
  }

  Widget _buildTurakView() {
    if (_turak.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phishing, size: 80, color: Colors.green[300]),
              const SizedBox(height: 16),
              const Text('Még nincs rögzített horgásztúrád.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Kattints az "Új Túra Indítása" gombra alul a túra és a fogások rögzítéséhez!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _turak.length,
      itemBuilder: (context, index) {
        final tura = _turak[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.cabin, color: Colors.white),
            ),
            title: Text(tura.nev, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            subtitle: Text('Helyszín: ${tura.helyszin} • ${tura.kezdetDatum}\nFogások: ${tura.fogasok.length} db'),
            children: [
              if (tura.fogasok.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Még nincs fogás rögzítve ehhez a túrához.', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
              ...tura.fogasok.map((f) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.set_meal, color: Colors.green),
                    title: Text('${f.halfaj} - ${f.suly} kg (${f.hossz > 0 ? "${f.hossz} cm" : "n/a"})'),
                    subtitle: Text('Csali: ${f.csali} ${f.megjegyzes.isNotEmpty ? "• ${f.megjegyzes}" : ""}'),
                    trailing: Text(f.datum),
                  )),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                    onPressed: () => _ujFogasParbeszed(tura),
                    icon: const Icon(Icons.add),
                    label: const Text('Fogás hozzáadása ehhez a túrához'),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildOsszesFogasView() {
    final List<Map<String, dynamic>> osszes = [];
    for (var tura in _turak) {
      for (var f in tura.fogasok) {
        osszes.add({'tura': tura.nev, 'hely': tura.helyszin, 'fogas': f});
      }
    }

    if (osszes.isEmpty) {
      return const Center(child: Text('Még egyetlen túrához sem rögzítettél fogást.', style: TextStyle(color: Colors.grey, fontSize: 16)));
    }

    return ListView.builder(
      itemCount: osszes.length,
      itemBuilder: (context, index) {
        final item = osszes[index];
        final Fogas f = item['fogas'];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green[100], child: Icon(Icons.phishing, color: Colors.green[800])),
            title: Text('${f.halfaj} - ${f.suly} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Túra: ${item['tura']} (${item['hely']})\nCsali: ${f.csali}'),
            trailing: Text(f.datum, style: const TextStyle(color: Colors.grey)),
          ),
        );
      },
    );
  }

  Widget _buildStatisztikaView() {
    int totalFogas = 0;
    double totalSuly = 0;
    double legnagyobbSuly = 0;
    String legnagyobbHal = 'Nincs';

    for (var tura in _turak) {
      for (var f in tura.fogasok) {
        totalFogas++;
        totalSuly += f.suly;
        if (f.suly > legnagyobbSuly) {
          legnagyobbSuly = f.suly;
          legnagyobbHal = '${f.halfaj} (${f.suly} kg)';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatCard('Összes Horgásztúra', '${_turak.length} alkalom', Icons.cabin, Colors.brown),
          _buildStatCard('Összes Rögzített Fogás', '$totalFogas db', Icons.phishing, Colors.green),
          _buildStatCard('Összsúly', '${totalSuly.toStringAsFixed(1)} kg', Icons.scale, Colors.blue),
          _buildStatCard('Legnagyobb Hal', legnagyobbHal, Icons.emoji_events, Colors.amber[800]!),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
