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
      home: const HomeScreen(),
    );
  }
}

class Fogas {
  final String halfaj;
  final String suly;
  final String datum;

  Fogas({required this.halfaj, required this.suly, required this.datum});
}

class Horgasztura {
  final String nev;
  final String helyszin;
  final String datum;
  final List<Fogas> fogasok;

  Horgasztura({
    required this.nev,
    required this.helyszin,
    required this.datum,
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

  void _ujTuraParbeszed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Új Horgásztúra indítása'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _turaNevController,
              decoration: const InputDecoration(labelText: 'Túra neve (pl. Balatoni hétvége)'),
            ),
            TextField(
              controller: _turaHelyszinController,
              decoration: const InputDecoration(labelText: 'Helyszín (pl. Tihany)'),
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
              if (_turaNevController.text.isNotEmpty) {
                setState(() {
                  _turak.add(
                    Horgasztura(
                      nev: _turaNevController.text,
                      helyszin: _turaHelyszinController.text.isEmpty ? 'Ismeretlen hely' : _turaHelyszinController.text,
                      datum: DateTime.now().toString().split(' ')[0],
                    ),
                  );
                });
                _turaNevController.clear();
                _turaHelyszinController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Túra Létrehozása'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _halfajController,
              decoration: const InputDecoration(labelText: 'Hal fajtája (pl. Ponty, Csuka)'),
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
                  tura.fogasok.add(
                    Fogas(
                      halfaj: _halfajController.text,
                      suly: '${_sulyController.text} kg',
                      datum: DateTime.now().toString().split(' ')[0],
                    ),
                  );
                });
                _halfajController.clear();
                _sulyController.clear();
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
        title: Text(_selectedNavIndex == 0
            ? 'Horgásztúrák & Napló'
            : _selectedNavIndex == 1
                ? 'Összes Fogás'
                : 'Magyar Halhatározó'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.green[800]),
              accountName: const Text('Horgásznapló', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              accountEmail: const Text('Saját fogási naplód'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.phishing, color: Colors.green, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: const Text('Horgásztúrák'),
              selected: _selectedNavIndex == 0,
              onTap: () {
                setState(() => _selectedNavIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.green),
              title: const Text('Összes Fogási Napló'),
              selected: _selectedNavIndex == 1,
              onTap: () {
                setState(() => _selectedNavIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.set_meal, color: Colors.blue),
              title: const Text('Halhatározó'),
              selected: _selectedNavIndex == 2,
              onTap: () {
                setState(() => _selectedNavIndex = 2);
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
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Új Túra', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildSelectedBody() {
    if (_selectedNavIndex == 0) {
      // Túrák nézet
      if (_turak.isEmpty) {
        return const Center(
          child: Text(
            'Még nincs létrehozott horgásztúrád.\nKattints az "Új Túra" gombra alul!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }
      return ListView.builder(
        itemCount: _turak.length,
        itemBuilder: (context, index) {
          final tura = _turak[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.cabin, color: Colors.white),
              ),
              title: Text(tura.nev, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${tura.helyszin} • ${tura.datum}\nFogások száma: ${tura.fogasok.length} db'),
              children: [
                ...tura.fogasok.map((fogas) => ListTile(
                      leading: const Icon(Icons.set_meal, color: Colors.green),
                      title: Text(fogas.halfaj),
                      subtitle: Text('Dátum: ${fogas.datum}'),
                      trailing: Text(fogas.suly, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _ujFogasParbeszed(tura),
                    icon: const Icon(Icons.add),
                    label: const Text('Fogás hozzáadása ehhez a túrához'),
                  ),
                )
              ],
            ),
          );
        },
      );
    } else if (_selectedNavIndex == 1) {
      // Összes fogás egyben
      final osszesFogas = <Map<String, String>>[];
      for (var tura in _turak) {
        for (var f in tura.fogasok) {
          osszesFogas.add({
            'tura': tura.nev,
            'hal': f.halfaj,
            'suly': f.suly,
            'datum': f.datum,
          });
        }
      }
      if (osszesFogas.isEmpty) {
        return const Center(
            child: Text('Még egyetlen túrához sincs rögzítve fogás.', style: TextStyle(color: Colors.grey)));
      }
      return ListView.builder(
        itemCount: osszesFogas.length,
        itemBuilder: (context, index) {
          final f = osszesFogas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.phishing, color: Colors.green),
              title: Text('${f['hal']} (${f['suly']})'),
              subtitle: Text('Túra: ${f['tura']}'),
              trailing: Text(f['datum']!),
            ),
          );
        },
      );
    } else {
      // Bővített Halhatározó
      return const HalhatarozoView();
    }
  }
}

class HalhatarozoView extends StatelessWidget {
  const HalhatarozoView({super.key});

  final List<Map<String, String>> _halak = const [
    {
      'nev': 'Ponty',
      'leiras': 'Legelterjedtebb békés halunk. Hátúszója hosszú, száján 4 bajuszszál található.',
      'meret': 'Méretkorlátozás: min. 30 cm | Tilosalmi idő: 05.02 - 05.31.'
    },
    {
      'nev': 'Amur',
      'leiras': 'Növényevő, rendkívül erős harcos hal. Hosszúkás, hengeres testállású.',
      'meret': 'Méretkorlátozás: min. 40 cm'
    },
    {
      'nev': 'Ezüstkárász / Aranykárász',
      'leiras': 'Magas testű, szívós békés hal. Az ezüstkárász inváziós faj, nem védett.',
      'meret': 'Nincs méretkorlátozás'
    },
    {
      'nev': 'Dévérkeszeg',
      'leiras': 'Oldalról erősen lapított, magas testű keszegféle, sötét úszókkal.',
      'meret': 'Méretkorlátozás: min. 20 cm'
    },
    {
      'nev': 'Süllő',
      'leiras': 'Népszerű ragadozó hal. Hátúszója osztott, szájában ebefogak találhatók.',
      'meret': 'Méretkorlátozás: min. 30 cm | Tilosalmi idő: 03.01 - 04.30.'
    },
    {
      'nev': 'Kősüllő',
      'leiras': 'A süllőnél kisebb, sötétebb harántcsíkos ragadozó.',
      'meret': 'Méretkorlátozás: min. 25 cm | Tilosalmi idő: 03.01 - 06.30.'
    },
    {
      'nev': 'Csuka',
      'leiras': 'Kiváló látású, agresszív ragadozó. Hosszúkás test, kacsa-csőrre emlékeztető fej.',
      'meret': 'Méretkorlátozás: min. 40 cm | Tilosalmi idő: 02.01 - 03.31.'
    },
    {
      'nev': 'Harcsa',
      'leiras': 'Legnagyobb édesvízi ragadozónk. Hosszú pofaszakáll, apró szemek.',
      'meret': 'Méretkorlátozás: min. 60 cm | Tilosalmi idő: 05.02 - 06.15.'
    },
    {
      'nev': 'Balin',
      'leiras': 'Gyors úszású ragadozó keszegféle. Fogatlan száj, kemény ragadozó kapás.',
      'meret': 'Méretkorlátozás: min. 40 cm | Tilosalmi idő: 03.01 - 04.30.'
    },
    {
      'nev': 'Márna',
      'leiras': 'Folyóvizek erős, áramvonalas hala. Alsó állású száján 4 bajuszszál van.',
      'meret': 'Méretkorlátozás: min. 40 cm | Tilosalmi idő: 04.15 - 05.31.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
