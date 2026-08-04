import 'dart:math';
import 'package:flutter/material.dart';

// ---- HALFAJ ADATMODELL ÉS DEMO ADATBÁZIS ----
class HalfajModel {
  String nev;
  String kategoria;
  String meretKorlat;
  String tilalmiIdo;
  String leiras;
  String rekordSuly;
  String rekordHelyszin;

  HalfajModel({
    required this.nev,
    required this.kategoria,
    required this.meretKorlat,
    required this.tilalmiIdo,
    required this.leiras,
    required this.rekordSuly,
    required this.rekordHelyszin,
  });
}

class LexikonAdatbazis {
  // Demo adatok a teszteléshez (később a JSON import írja felül)
  static List<HalfajModel> halfajok = [
    HalfajModel(
      nev: 'Ponty',
      kategoria: 'Békés halak',
      meretKorlat: '30 cm - 50 cm között (Vízterületenként eltérő lehet)',
      tilalmiIdo: 'Május 1. - May 31. (A fogási tilalom csak a kíméleti területeken/állományra vonatkozhat)',
      leiras: 'A legnépszerűbb sporthal Magyarországon. Teste robusztus, vastag pikkelyes vagy tőponty változatban is létezik.',
      rekordSuly: '44,15 kg (2018)',
      rekordHelyszin: 'Merenyei horgásztó',
    ),
    HalfajModel(
      nev: 'Csuka',
      kategoria: 'Ragadozó halak',
      meretKorlat: 'Minimum 50 cm',
      tilalmiIdo: 'Február 1. - Március 31.',
      leiras: 'Magyarország vizeinek agresszív ragadozója. Hosszú, megnyúlt testfelépítés és kacsacsőrszerű fej jellemzi.',
      rekordSuly: '20,47 kg (1994)',
      rekordHelyszin: 'Gyékényesi kavicsbánya-tó',
    ),
    HalfajModel(
      nev: 'Süllő',
      kategoria: 'Ragadozó halak',
      meretKorlat: 'Minimum 30 cm',
      tilalmiIdo: 'Március 1. - Április 30.',
      leiras: 'Éjszakai ragadozó, amely a tiszta, oxigéndús vizeket kedveli. Szúrós hátúszója és jellegzetes "ebfogai" vannak.',
      rekordSuly: '14,96 kg (2007)',
      rekordHelyszin: 'Pilismaróti-öböl',
    ),
    HalfajModel(
      nev: 'Amur',
      kategoria: 'Békés halak',
      meretKorlat: 'Nincs méretkorlátozás (vagy helyi szabályzat szerint)',
      tilalmiIdo: 'Nincs tilalmi idő',
      leiras: 'Kelet-Ázsiából származó növényevő hal. Falánkságáról ismert, hatalmas méreteket érhet el.',
      rekordSuly: '40,50 kg (1993)',
      rekordHelyszin: 'Ráckevei-Duna-ág',
    ),
  ];
}

// ---- HALFajok KÉPERNYŐ ----
class LexikonScreen extends StatefulWidget {
  const LexikonScreen({super.key});

  @override
  State<LexikonScreen> createState() => _LexikonScreenState();
}

class _LexikonScreenState extends State<LexikonScreen> {
  String _keresesSzoveg = '';

  @override
  Widget build(BuildContext context) {
    final szurtLista = LexikonAdatbazis.halfajok.where((h) {
      return h.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase()) ||
             h.kategoria.toLowerCase().contains(_keresesSzoveg.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halfajok Lexikon'),
        backgroundColor: const Color(0xFF121212),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz, color: Colors.greenAccent),
            tooltip: 'Hal Felismerő Kvíz',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KvizScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Keresőmező
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Keresés halfaj vagy kategória szerint...',
                prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _keresesSzoveg = val;
                });
              },
            ),
          ),
          Expanded(
            child: szurtLista.isEmpty
                ? const Center(
                    child: Text('Nincs találat a keresésre.', style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: szurtLista.length,
                    itemBuilder: (context, index) {
                      final hal = szurtLista[index];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(hal.nev, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(hal.kategoria, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HalReszletekScreen(hal: hal)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---- RÉSZLETES HAL ADATLAP ----
class HalReszletekScreen extends StatelessWidget {
  final HalfajModel hal;

  const HalReszletekScreen({super.key, required this.hal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hal.nev),
        backgroundColor: const Color(0xFF121212),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hal.kategoria, style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(hal.nev, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSzekcio('Méretkorlátozás', hal.meretKorlat, Icons.straighten),
            _buildSzekcio('Tilalmi idő', hal.tilalmiIdo, Icons.block),
            _buildSzekcio('Mohaosz Rekord', '${hal.rekordSuly} (${hal.rekordHelyszin})', Icons.emoji_events),
            _buildSzekcio('Leírás', hal.leiras, Icons.info_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildSzekcio(String cim, String tartalom, IconData ikon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                Text(cim, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(tartalom, style: const TextStyle(fontSize: 16, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ---- KVÍZ MODUL ----
class KvizScreen extends StatefulWidget {
  const KvizScreen({super.key});

  @override
  State<KvizScreen> createState() => _KvizScreenState();
}

class _KvizScreenState extends State<KvizScreen> {
  late HalfajModel _aktualisKerdes;
  List<String> _opciok = [];
  int _pontszam = 0;
  bool _valaszolva = false;
  String? _kivalasztottValasz;

  @bodyInit // ignore: annotate_overrides
  void initState() {
    super.initState();
    _ujKerdes();
  }

  void _ujKerdes() {
    final random = Random();
    if (LexikonAdatbazis.halfajok.length < 2) return;

    List<HalfajModel> osszes = List.from(LexikonAdatbazis.halfajok);
    osszes.shuffle(random);

    _aktualisKerdes = osszes[0];

    List<String> valaszok = [_aktualisKerdes.nev];
    for (var h in osszes) {
      if (h.nev != _aktualisKerdes.nev && valaszok.length < 4) {
        valaszok.add(h.nev);
      }
    }
    valaszok.shuffle(random);

    setState(() {
      _opciok = valaszok;
      _valaszolva = false;
      _kivalasztottValasz = null;
    });
  }

  void _valasztas(String valasz) {
    if (_valaszolva) return;

    setState(() {
      _valaszolva = true;
      _kivalasztottValasz = valasz;
      if (valasz == _aktualisKerdes.nev) {
        _pontszam++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _ujKerdes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hal Felismerő Kvíz'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Melyik halfaj ez?', style: TextStyle(fontSize: 18, color: Colors.white54)),
                Text('Pontszám: $_pontszam', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
            const SizedBox(height: 24),
            // Kép helye / Információs kártya a kvízhez
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[800]!),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Rekord: ${_aktualisKerdes.rekordSuly}\nHelyszín: ${_aktualisKerdes.rekordHelyszin}\n\nLeírás: ${_aktualisKerdes.leiras}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Válaszlehetőségek
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: _opciok.length,
                itemBuilder: (context, index) {
                  String opcio = _opciok[index];
                  Color gombSzin = const Color(0xFF1E1E1E);

                  if (_valaszolva) {
                    if (opcio == _aktualisKerdes.nev) {
                      gombSzin = Colors.green[800]!;
                    } else if (opcio == _kivalasztottValasz) {
                      gombSzin = Colors.red[800]!;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gombSzin,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _valasztas(opcio),
                      child: Text(opcio, style: const TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
