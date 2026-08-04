import 'package:flutter/material.dart';

// ---- IDEIGLENES ADATBÁZIS (Memóriában tárolva a mentés/betöltés elkészültéig) ----
class TorzsadatAdatbazis {
  static Map<String, List<Map<String, dynamic>>> adatok = {
    'Halfaj': [],
    'Bot': [],
    'Horgászmódszer': [],
    'Végszerelék': [],
    'Csali': [],
    'Etetőanyag': [],
    'Helyszín': [], // Itt az elem felépítése: {'nev': '...', 'vizter_kod': '...'}
    'Horgásztársak': [],
    'Időjárás': [],
    'Hal sorsa': [
      {'nev': 'Visszaengedtem'},
      {'nev': 'Elvittem'},
      {'nev': 'Elpusztult'}
    ],
  };
}

// ---- FŐ KÉPERNYŐ: KATEGÓRIÁK LISTÁJA ----
class TorzsadatokScreen extends StatelessWidget {
  const TorzsadatokScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kategoriaKulcsok = TorzsadatAdatbazis.adatok.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Törzsadatok Kezelése'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: kategoriaKulcsok.length,
        itemBuilder: (context, index) {
          final kategoria = kategoriaKulcsok[index];
          final elemszam = TorzsadatAdatbazis.adatok[kategoria]!.length;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Colors.green[900],
                child: Icon(_getIconForCategory(kategoria), color: Colors.green[400]),
              ),
              title: Text(
                kategoria,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text('$elemszam rögzített elem', style: const TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KategoriaReszletekScreen(kategoria: kategoria),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String kategoria) {
    switch (kategoria) {
      case 'Halfaj': return Icons.set_meal;
      case 'Bot': return Icons.hardware;
      case 'Horgászmódszer': return Icons.sync_alt;
      case 'Végszerelék': return Icons.build_circle;
      case 'Csali': return Icons.bug_report;
      case 'Etetőanyag': return Icons.scatter_plot;
      case 'Helyszín': return Icons.map;
      case 'Horgásztársak': return Icons.people;
      case 'Időjárás': return Icons.cloud;
      case 'Hal sorsa': return Icons.compare_arrows;
      default: return Icons.list;
    }
  }
}

// ---- AL-KÉPERNYŐ: EGY ADOTT KATEGÓRIA ELEMEINEK KEZELÉSE ----
class KategoriaReszletekScreen extends StatefulWidget {
  final String kategoria;

  const KategoriaReszletekScreen({super.key, required this.kategoria});

  @override
  State<KategoriaReszletekScreen> createState() => _KategoriaReszletekScreenState();
}

class _KategoriaReszletekScreenState extends State<KategoriaReszletekScreen> {
  late List<Map<String, dynamic>> _elemek;

  @override
  void initState() {
    super.initState();
    _elemek = TorzsadatAdatbazis.adatok[widget.kategoria]!;
  }

  void _hozzaadVagySzerkeszt({int? index}) {
    final bool isHelyszin = widget.kategoria == 'Helyszín';
    final bool isSzerkesztes = index != null;

    final nevController = TextEditingController(text: isSzerkesztes ? _elemek[index]['nev'] : '');
    final vizterKodController = TextEditingController(text: isSzerkesztes && isHelyszin ? _elemek[index]['vizter_kod'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(isSzerkesztes ? '${widget.kategoria} szerkesztése' : 'Új ${widget.kategoria.toLowerCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nevController,
                decoration: InputDecoration(
                  labelText: 'Megnevezés *',
                  labelStyle: TextStyle(color: Colors.green[400]),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green[400]!)),
                ),
                autofocus: true,
              ),
              if (isHelyszin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: vizterKodController,
                  decoration: InputDecoration(
                    labelText: 'Víztér kódja (Opcionális)',
                    labelStyle: TextStyle(color: Colors.green[400]),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green[400]!)),
                  ),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mégsem', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () {
                final nev = nevController.text.trim();
                if (nev.isEmpty) return;

                setState(() {
                  final ujElem = {'nev': nev};
                  if (isHelyszin) {
                    ujElem['vizter_kod'] = vizterKodController.text.trim();
                  }

                  if (isSzerkesztes) {
                    _elemek[index] = ujElem;
                  } else {
                    _elemek.add(ujElem);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Mentés', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _torles(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Törlés megerősítése'),
        content: Text('Biztosan törölni szeretnéd ezt: "${_elemek[index]['nev']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégsem', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              setState(() {
                _elemek.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kategoria} kezelése'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: _elemek.isEmpty
          ? const Center(
              child: Text(
                'Nincs még rögzített adat.\nKattints a + gombra a hozzáadáshoz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Hely a FAB-nak
              itemCount: _elemek.length,
              itemBuilder: (context, index) {
                final elem = _elemek[index];
                final bool isHelyszin = widget.kategoria == 'Helyszín';
                final hasVizterKod = isHelyszin && elem['vizter_kod'] != null && elem['vizter_kod'].toString().isNotEmpty;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    title: Text(elem['nev'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: hasVizterKod ? Text('Víztér kód: ${elem['vizter_kod']}', style: const TextStyle(color: Colors.greenAccent)) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white54),
                          onPressed: () => _hozzaadVagySzerkeszt(index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _torles(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _hozzaadVagySzerkeszt(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
