import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'adattarolo.dart';
import 'modellek.dart';

// ---- HALFAJOK KÉPERNYŐ (LEXIKON) ----
class LexikonScreen extends StatefulWidget {
  const LexikonScreen({super.key});

  @override
  State<LexikonScreen> createState() => _LexikonScreenState();
}

class _LexikonScreenState extends State<LexikonScreen> {
  String _keresesSzoveg = '';
  List<Halfaj> _osszesHal = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final adatok = await AdatTarolo.betoltes('halfajok_adatok');
    setState(() {
      _osszesHal = adatok.map((e) => Halfaj.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final szurtLista = _osszesHal.where((h) {
      return h.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase()) ||
             h.kategoria.toLowerCase().contains(_keresesSzoveg.toLowerCase());
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Keresés halfaj vagy kategória szerint...',
                prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _keresesSzoveg = val),
            ),
          ),
          Expanded(
            child: _osszesHal.isEmpty
                ? const Center(child: Text('A Lexikon üres. Kérlek vegyél fel halfajokat a Törzsadatok menüben!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
                : szurtLista.isEmpty
                    ? const Center(child: Text('Nincs találat a keresésre.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: szurtLista.length,
                        itemBuilder: (context, index) {
                          final hal = szurtLista[index];
                          // Ha van kép, mutatjuk az elsőt bélyegképként
                          Widget? kepIkon;
                          if (hal.kepek.isNotEmpty && File(hal.kepek.first).existsSync()) {
                            kepIkon = ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(File(hal.kepek.first), width: 50, height: 50, fit: BoxFit.cover),
                            );
                          } else {
                            kepIkon = const Icon(Icons.set_meal, size: 40, color: Colors.white24);
                          }

                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: kepIkon,
                              title: Text(hal.nev, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(hal.kategoria, style: const TextStyle(color: Colors.greenAccent)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HalReszletekScreen(hal: hal))),
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
  final Halfaj hal;

  const HalReszletekScreen({super.key, required this.hal});

  Widget _buildSor(String cim, String tartalom) {
    if (tartalom.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text('$cim:', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(tartalom, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hal.nev)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Képek megjelenítése (ha vannak)
            if (hal.kepek.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: hal.kepek.length,
                  itemBuilder: (context, i) {
                    final utvonal = hal.kepek[i];
                    if (!File(utvonal).existsSync()) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(utvonal), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hal.nev, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  const SizedBox(height: 16),
                  _buildSor('Kategória', hal.kategoria),
                  _buildSor('Általános méret', hal.altalanosMeret),
                  _buildSor('Méretkorlátozás', hal.meretKorlatozas),
                  _buildSor('Elvihető mennyiség', hal.elvihetoMennyiseg),
                  _buildSor('Tilalmi időszak', hal.tilalmiIdoszak),
                  const Divider(color: Colors.white24, height: 24),
                  _buildSor('Élőhely', hal.elohely),
                  _buildSor('Táplálék/Csali', hal.taplalek),
                  const Divider(color: Colors.white24, height: 24),
                  _buildSor('Forrás', hal.szabalyzatForras),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- KVÍZ MODUL (Képes és Szöveges) ----
class KvizScreen extends StatefulWidget {
  const KvizScreen({super.key});

  @override
  State<KvizScreen> createState() => _KvizScreenState();
}

class _KvizScreenState extends State<KvizScreen> {
  List<Halfaj> _osszesHal = [];
  late Halfaj _aktualisKerdes;
  List<String> _opciok = [];
  int _pontszam = 0;
  bool _valaszolva = false;
  String? _kivalasztottValasz;
  bool _kepesMod = false; // Kapcsoló a két játékmódhoz

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final adatok = await AdatTarolo.betoltes('halfajok_adatok');
    setState(() {
      _osszesHal = adatok.map((e) => Halfaj.fromJson(e)).toList();
    });
    if (_osszesHal.length >= 2) {
      _ujKerdes();
    }
  }

  void _ujKerdes() {
    final random = Random();
    
    // Ha képes mód van, csak azokat a halakat vesszük, amikhez van kép feltöltve!
    List<Halfaj> elerhetoHalak = _osszesHal;
    if (_kepesMod) {
      elerhetoHalak = _osszesHal.where((h) => h.kepek.isNotEmpty && File(h.kepek.first).existsSync()).toList();
    }

    // Ha nincs elég hal a kvízhez az adott módban
    if (elerhetoHalak.isEmpty) {
      setState(() {
        _valaszolva = true; 
        // Hack: így jelezzük a UI-nak, hogy nincs kérdés
      });
      return;
    }

    elerhetoHalak.shuffle(random);
    _aktualisKerdes = elerhetoHalak[0];

    // A válaszlehetőségekhez (a 4 gombhoz) az összes halból sorsolunk
    List<String> valaszok = [_aktualisKerdes.nev];
    List<Halfaj> opcioHalak = List.from(_osszesHal);
    opcioHalak.shuffle(random);
    
    for (var h in opcioHalak) {
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
    if (_osszesHal.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kvíz')),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('A kvíz indításához legalább 2 halfajt fel kell venned a Törzsadatokban!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hal Felismerő Kvíz'),
        actions: [
          Row(
            children: [
              const Text('Képes', style: TextStyle(fontSize: 12)),
              Switch(
                value: _kepesMod,
                activeColor: Colors.greenAccent,
                onChanged: (val) {
                  setState(() {
                    _kepesMod = val;
                    _pontszam = 0;
                  });
                  _ujKerdes();
                },
              ),
            ],
          )
        ],
      ),
      body: _valaszolva && _opciok.isEmpty // Nincs elég kép a képes kvízhez
          ? const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nincs elég olyan halfajod, amelyikhez feltöltöttél volna képet! Válts vissza szöveges módra.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.orangeAccent)),
            ))
          : Padding(
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
                  
                  // FELADVÁNY (Kép vagy Szöveg)
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[800]!),
                      ),
                      child: Center(
                        child: _kepesMod
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(File(_aktualisKerdes.kepek.first), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Méret: ${_aktualisKerdes.altalanosMeret}\nÉlőhely: ${_aktualisKerdes.elohely}\nTáplálék: ${_aktualisKerdes.taplalek}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // VÁLASZGOMBOK
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
