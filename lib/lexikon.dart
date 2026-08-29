import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'adattarolo.dart';
import 'modellek.dart';

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
    final adatok = await AdatTarolo.halfajokBetoltese();
    setState(() {
      _osszesHal = adatok;
    });
  }

  Color _getStatuszSzin(String statusz) {
    if (statusz == 'Fogható' || statusz == 'Fogható (Őshonos)') return Colors.green;
    if (statusz == 'Fogható (Idegenhonos)') return Colors.lightGreenAccent; 
    if (statusz == 'Védett') return Colors.blue;
    if (statusz == 'Inváziós') return Colors.red;
    return Colors.white70; 
  }

  int _getStatuszSuly(String statusz) {
    if (statusz == 'Fogható' || statusz == 'Fogható (Őshonos)') return 1;
    if (statusz == 'Fogható (Idegenhonos)') return 2;
    if (statusz == 'Inváziós') return 3;
    if (statusz == 'Nem fogható') return 4;
    if (statusz == 'Védett') return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final szurtLista = _osszesHal.where((h) {
      return h.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase()) ||
             h.kategoria.toLowerCase().contains(_keresesSzoveg.toLowerCase()) ||
             h.statusz.toLowerCase().contains(_keresesSzoveg.toLowerCase());
    }).toList();

    szurtLista.sort((a, b) {
      int sulyA = _getStatuszSuly(a.statusz);
      int sulyB = _getStatuszSuly(b.statusz);
      
      if (sulyA != sulyB) {
        return sulyA.compareTo(sulyB);
      } else {
        return a.nev.compareTo(b.nev);
      }
    });

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Keresés halfaj vagy státusz szerint...',
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
                        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                        itemCount: szurtLista.length,
                        itemBuilder: (context, index) {
                          final hal = szurtLista[index];
                          
                          Widget kepIkon = const Icon(Icons.set_meal, size: 40, color: Colors.white24);
                          
                          String? megjelenitendoUtvonal;
                          if (hal.indexKep != null && (hal.indexKep!.startsWith('http') || File(hal.indexKep!).existsSync())) {
                            megjelenitendoUtvonal = hal.indexKep;
                          } else if (hal.kepek.isNotEmpty && (hal.kepek.first.startsWith('http') || File(hal.kepek.first).existsSync())) {
                            megjelenitendoUtvonal = hal.kepek.first;
                          }

                          if (megjelenitendoUtvonal != null) {
                            kepIkon = ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: megjelenitendoUtvonal.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: megjelenitendoUtvonal,
                                    width: 50, height: 50, fit: BoxFit.cover,
                                    placeholder: (context, url) => const SizedBox(width: 50, height: 50, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))),
                                    errorWidget: (context, url, error) => const Icon(Icons.set_meal, size: 40, color: Colors.white24),
                                  )
                                : Image.file(File(megjelenitendoUtvonal), width: 50, height: 50, fit: BoxFit.cover),
                            );
                          }

                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: kepIkon,
                              title: Text(hal.nev, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: '${hal.kategoria} • ', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                      TextSpan(text: hal.statusz, style: TextStyle(color: _getStatuszSzin(hal.statusz), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HalReszletekScreen(hal: hal))),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange[800],
        icon: const Icon(Icons.sports_esports, color: Colors.white),
        label: const Text('KVÍZ INDÍTÁSA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const KvizScreen()));
        },
      ),
    );
  }
}

class HalReszletekScreen extends StatefulWidget {
  final Halfaj hal;

  const HalReszletekScreen({super.key, required this.hal});

  @override
  State<HalReszletekScreen> createState() => _HalReszletekScreenState();
}

class _HalReszletekScreenState extends State<HalReszletekScreen> {
  final PageController _pageCtrl = PageController();

  Widget _buildSor(String cim, String tartalom) {
    if (tartalom.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(cim, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          Expanded(child: Text(tartalom, style: const TextStyle(color: Colors.white, fontSize: 15))),
        ],
      ),
    );
  }

  Color _getStatuszSzin(String statusz) {
    if (statusz == 'Fogható' || statusz == 'Fogható (Őshonos)') return Colors.green;
    if (statusz == 'Fogható (Idegenhonos)') return Colors.lightGreenAccent; 
    if (statusz == 'Védett') return Colors.blue;
    if (statusz == 'Inváziós') return Colors.red;
    return Colors.grey; 
  }

  @override
  Widget build(BuildContext context) {
    final hal = widget.hal;
    return Scaffold(
      appBar: AppBar(title: Text(hal.nev)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hal.kepek.isNotEmpty) ...[
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: hal.kepek.length,
                      itemBuilder: (context, i) {
                        final utvonal = hal.kepek[i];
                        Widget megjelenito;
                        
                        if (utvonal.startsWith('http')) {
                          megjelenito = CachedNetworkImage(
                            imageUrl: utvonal,
                            fit: BoxFit.cover, width: double.infinity,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white24)),
                          );
                        } else if (File(utvonal).existsSync()) {
                          megjelenito = Image.file(File(utvonal), fit: BoxFit.cover, width: double.infinity);
                        } else {
                          return const Center(child: Icon(Icons.error));
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: megjelenito,
                          ),
                        );
                      },
                    ),
                    if (hal.kepek.length > 1) ...[
                      Positioned(
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () => _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (hal.kepek.length > 1)
                const Center(child: Text('Lapozz a többi képért ↔', style: TextStyle(color: Colors.white38, fontSize: 12))),
              const SizedBox(height: 20),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(hal.nev, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _getStatuszSzin(hal.statusz), borderRadius: BorderRadius.circular(20)),
                        child: Text(hal.statusz, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSor('Kategória', hal.kategoria),
                  _buildSor('Méretkorlátozás', hal.meretKorlatozas.isNotEmpty ? hal.meretKorlatozas : '-'),
                  _buildSor('Napi darabszám', hal.darabKorlatozas.isNotEmpty ? hal.darabKorlatozas : '-'),
                  _buildSor('Tilalmi időszak', hal.tilalmiIdoszak.isNotEmpty ? hal.tilalmiIdoszak : '-'),
                  _buildSor('Szabályozás éve', hal.szabalyozasEve.isNotEmpty ? hal.szabalyozasEve : '-'),
                  
                  if (hal.megjegyzes.isNotEmpty) ...[
                    const Divider(color: Colors.white24, height: 32),
                    const Text('Leírás / Élőhely / Táplálék', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(hal.megjegyzes, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  bool _kepesMod = false; 

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final adatok = await AdatTarolo.halfajokBetoltese();
    setState(() => _osszesHal = adatok);
    if (_osszesHal.length >= 2) _ujKerdes();
  }

  bool _ervenyestKep(String kep) {
    if (kep.isEmpty) return false;
    if (kep.startsWith('http')) return false; 
    return File(kep).existsSync();
  }

  void _onKepesModValtas(bool ujErtek) {
    if (ujErtek) {
      int kepesHalakSzama = _osszesHal.where((h) => h.kepek.any((k) => _ervenyestKep(k))).length;
      
      if (kepesHalakSzama < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nincs elég fotóval rendelkező halfaj (min. 4 kell)! Kérlek, tölts fel saját képeket a Törzsadatoknál!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() { _kepesMod = false; });
        return;
      }
    }
    
    setState(() { 
      _kepesMod = ujErtek; 
      _pontszam = 0; 
    });
    _ujKerdes();
  }

  void _ujKerdes() {
    final random = Random();
    
    List<Halfaj> elerhetoHalak = List.from(_osszesHal);
    
    if (_kepesMod) {
      elerhetoHalak = elerhetoHalak.where((h) {
        return h.kepek.any((kep) => _ervenyestKep(kep));
      }).toList();
    }

    if (elerhetoHalak.isEmpty) {
      setState(() => _valaszolva = true); 
      return;
    }

    elerhetoHalak.shuffle(random);
    _aktualisKerdes = elerhetoHalak[0];

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
      if (valasz == _aktualisKerdes.nev) _pontszam++;
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
          child: Text('A kvíz indításához legalább 2 halfajt fel kell venned!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kvíz'),
        actions: [
          Row(
            children: [
              const Text('Képes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Switch(
                value: _kepesMod,
                activeColor: Colors.greenAccent,
                onChanged: _onKepesModValtas, 
              ),
            ],
          )
        ],
      ),
      body: _valaszolva && _opciok.isEmpty
          ? const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nincs elég olyan halfajod, amelyikhez hivatalos vagy saját képet töltöttél volna fel! Válts vissza szöveges módra.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.orangeAccent)),
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
                            ? Builder(
                                builder: (context) {
                                  List<String> validKepek = _aktualisKerdes.kepek.where((kep) => _ervenyestKep(kep)).toList();
                                  validKepek.shuffle();
                                  
                                  if (validKepek.isEmpty) {
                                     return const Icon(Icons.error, color: Colors.red, size: 50);
                                  }

                                  String kivalasztottKep = validKepek.first;
                                  
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      File(kivalasztottKep), 
                                      fit: BoxFit.cover, 
                                      width: double.infinity, 
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.phishing, size: 64, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text('Kép nem található', style: TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              )
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Builder(
                                  builder: (context) {
                                    String alapNev = _aktualisKerdes.nev.split(' (').first;
                                    String cenzurazottLeiras = _aktualisKerdes.megjegyzes
                                        .replaceAll(RegExp(RegExp.escape(_aktualisKerdes.nev), caseSensitive: false), '[***]')
                                        .replaceAll(RegExp(RegExp.escape(alapNev), caseSensitive: false), '[***]');
                                    
                                    return Text(
                                      'Státusz: ${_aktualisKerdes.statusz}\n\nKategória: ${_aktualisKerdes.kategoria}\n\n$cenzurazottLeiras',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                                    );
                                  }
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
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
