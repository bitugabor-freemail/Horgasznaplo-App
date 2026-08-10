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

  void _mutassInfot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Státuszok Jelentése', style: TextStyle(color: Colors.greenAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSor(Colors.green, 'Fogható (Őshonos)', 'Megtartható a méret-, tilalmi idő- és darabszám-korlátozások betartásával.'),
              _buildInfoSor(Colors.lightGreenAccent, 'Fogható (Idegenhonos)', 'Szabadon fogható, betelepített halak. Országos méret-, és darabkorlátozás, valamint tilalmi idő nem vonatkozik rájuk (helyi horgászrend ettől eltérhet).'),
              _buildInfoSor(Colors.blue, 'Védett', 'Nem tartható meg, azonnal és kíméletesen vissza kell engedni.'),
              _buildInfoSor(Colors.red, 'Inváziós', 'Nem szabad visszaengedni, el kell távolítani a víztérből.'),
              _buildInfoSor(Colors.white70, 'Nem fogható', 'Nem védett és nem inváziós, de jogszabály alapján nem tartható meg; kifogása esetén vissza kell engedni.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bezárás', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSor(Color szin, String cim, String leiras) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: szin, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(cim, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(leiras, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3)),
        ],
      ),
    );
  }

  Color _getStatuszSzin(String statusz) {
    // A régi "Fogható" is zöld marad, amíg át nem írod a szerkesztőben
    if (statusz == 'Fogható' || statusz == 'Fogható (Őshonos)') return Colors.green;
    if (statusz == 'Fogható (Idegenhonos)') return Colors.lightGreenAccent; 
    if (statusz == 'Védett') return Colors.blue;
    if (statusz == 'Inváziós') return Colors.red;
    return Colors.white70; 
  }

  @override
  Widget build(BuildContext context) {
    final szurtLista = _osszesHal.where((h) {
      return h.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase()) ||
             h.kategoria.toLowerCase().contains(_keresesSzoveg.toLowerCase()) ||
             h.statusz.toLowerCase().contains(_keresesSzoveg.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halhatározó'),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.greenAccent), onPressed: _mutassInfot),
        ],
      ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: szurtLista.length,
                        itemBuilder: (context, index) {
                          final hal = szurtLista[index];
                          
                          Widget kepIkon = const Icon(Icons.set_meal, size: 40, color: Colors.white24);
                          
                          if (hal.kepek.isNotEmpty) {
                            String utvonal = hal.kepek.first;
                            kepIkon = ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: utvonal.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: utvonal,
                                    width: 50, height: 50, fit: BoxFit.cover,
                                    placeholder: (context, url) => const SizedBox(width: 50, height: 50, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))),
                                    errorWidget: (context, url, error) => const Icon(Icons.set_meal, size: 40, color: Colors.white24),
                                  )
                                : (File(utvonal).existsSync() 
                                    ? Image.file(File(utvonal), width: 50, height: 50, fit: BoxFit.cover)
                                    : const Icon(Icons.set_meal, size: 40, color: Colors.white24)),
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
    );
  }
}

class HalReszletekScreen extends StatelessWidget {
  final Halfaj hal;

  const HalReszletekScreen({super.key, required this.hal});

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
                child: PageView.builder(
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

  void _ujKerdes() {
    final random = Random();
    
    List<Halfaj> elerhetoHalak = _osszesHal;
    if (_kepesMod) {
      elerhetoHalak = _osszesHal.where((h) => h.kepek.isNotEmpty && (h.kepek.first.startsWith('http') || File(h.kepek.first).existsSync())).toList();
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
                onChanged: (val) {
                  setState(() { _kepesMod = val; _pontszam = 0; });
                  _ujKerdes();
                },
              ),
            ],
          )
        ],
      ),
      body: _valaszolva && _opciok.isEmpty
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
                                child: _aktualisKerdes.kepek.first.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: _aktualisKerdes.kepek.first,
                                        fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.white24),
                                      )
                                    : Image.file(File(_aktualisKerdes.kepek.first), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Státusz: ${_aktualisKerdes.statusz}\n\nKategória: ${_aktualisKerdes.kategoria}\n\n${_aktualisKerdes.megjegyzes}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
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
