import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
              textCapitalization: TextCapitalization.sentences,
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
                                    placeholder: (context, url) => const Icon(Icons.set_meal, size: 40, color: Colors.white24),
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

  void _teljesKepernyosGaleria(BuildContext context, int kezdoIndex) {
    final PageController fullPageCtrl = PageController(initialPage: kezdoIndex);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: fullPageCtrl,
            itemCount: widget.hal.kepek.length,
            itemBuilder: (context, i) {
              final utvonal = widget.hal.kepek[i];
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: utvonal.startsWith('http')
                    ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.contain)
                    : Image.file(File(utvonal), fit: BoxFit.contain),
                ),
              );
            }
          ),
        ),
      ),
    );
  }

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
                            placeholder: (context, url) => const Center(child: Icon(Icons.set_meal, size: 50, color: Colors.white24)),
                            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white24)),
                          );
                        } else if (File(utvonal).existsSync()) {
                          megjelenito = Image.file(File(utvonal), fit: BoxFit.cover, width: double.infinity);
                        } else {
                          return const Center(child: Icon(Icons.error));
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => _teljesKepernyosGaleria(context, i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: megjelenito,
                            ),
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

// --- ÚJ KVÍZ MODELL ---
class QuizFeladvany {
  final Halfaj hal;
  final bool isKepes;
  final String tartalom; 
  QuizFeladvany({required this.hal, required this.isKepes, required this.tartalom});
}

class KvizScreen extends StatefulWidget {
  const KvizScreen({super.key});

  @override
  State<KvizScreen> createState() => _KvizScreenState();
}

class _KvizScreenState extends State<KvizScreen> {
  List<Halfaj> _osszesHal = [];
  
  List<QuizFeladvany> _szovegesMedence = [];
  List<QuizFeladvany> _kepesMedence = [];
  
  QuizFeladvany? _aktualisKerdes;
  List<String> _opciok = [];
  
  int _pontszam = 0;
  int _hibakSzama = 0; // Max 3
  bool _valaszolva = false;
  String? _kivalasztottValasz;
  
  bool _kepesMod = false; 
  bool _isJatekVege = false;
  bool _isVillog = false;
  
  List<Map<String, dynamic>> _rekordok = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final adatok = await AdatTarolo.halfajokBetoltese();
    final prefs = await SharedPreferences.getInstance();
    final String? rekordJson = prefs.getString('kviz_rekordok');
    
    if (rekordJson != null) {
      List<dynamic> dekodolt = jsonDecode(rekordJson);
      _rekordok = dekodolt.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    setState(() => _osszesHal = adatok);
    if (_osszesHal.length >= 2) {
      _jatekInicializalasa();
    }
  }

  bool _ervenyestKep(String kep) {
    if (kep.isEmpty) return false;
    if (kep.startsWith('http')) return false; 
    return File(kep).existsSync();
  }

  void _jatekInicializalasa() {
    _szovegesMedence.clear();
    _kepesMedence.clear();
    _pontszam = 0;
    _hibakSzama = 0;
    _isJatekVege = false;
    _valaszolva = false;

    for (var hal in _osszesHal) {
      if (hal.megjegyzes.trim().isNotEmpty) {
        _szovegesMedence.add(QuizFeladvany(hal: hal, isKepes: false, tartalom: hal.megjegyzes));
      }
      for (var kep in hal.kepek) {
        if (_ervenyestKep(kep)) {
          _kepesMedence.add(QuizFeladvany(hal: hal, isKepes: true, tartalom: kep));
        }
      }
    }
    
    _szovegesMedence.shuffle();
    _kepesMedence.shuffle();
    
    // Ha eleve nincs kép, kikényszerítjük a szövegest
    if (_kepesMod && _kepesMedence.isEmpty) {
      _kepesMod = false;
    }

    _ujKerdes();
  }

  void _onKepesModValtas(bool ujErtek) {
    if (ujErtek && _kepesMedence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elfogyott az összes képes kérdés!'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!ujErtek && _szovegesMedence.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elfogyott az összes szöveges kérdés!'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() { 
      _kepesMod = ujErtek; 
      // Visszatesszük a jelenlegi kérdést a medencébe, hogy ne vesszen el a váltás miatt
      if (_aktualisKerdes != null) {
        if (_aktualisKerdes!.isKepes) {
          _kepesMedence.add(_aktualisKerdes!);
          _kepesMedence.shuffle();
        } else {
          _szovegesMedence.add(_aktualisKerdes!);
          _szovegesMedence.shuffle();
        }
      }
    });
    _ujKerdes();
  }

  void _ujKerdes() {
    if (_isJatekVege) return;

    // Automata váltó, ha kifogyott a medence
    if (_kepesMod && _kepesMedence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A képek elfogytak! Automatikus váltás szöveges módra...')));
      setState(() => _kepesMod = false);
    } else if (!_kepesMod && _szovegesMedence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A szöveges kérdések elfogytak! Automatikus váltás képes módra...')));
      setState(() => _kepesMod = true);
    }

    // Ha MINDEN elfogyott -> GYŐZELEM!
    if (_kepesMedence.isEmpty && _szovegesMedence.isEmpty) {
      _jatekVegeFolyamat(isGyozelem: true);
      return;
    }

    final random = Random();
    
    // Kivesszük a következőt
    _aktualisKerdes = _kepesMod ? _kepesMedence.removeLast() : _szovegesMedence.removeLast();

    List<String> valaszok = [_aktualisKerdes!.hal.nev];
    List<Halfaj> opcioHalak = List.from(_osszesHal);
    opcioHalak.shuffle(random);
    
    for (var h in opcioHalak) {
      if (h.nev != _aktualisKerdes!.hal.nev && valaszok.length < 4) {
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

  void _valasztas(String valasz) async {
    if (_valaszolva || _isJatekVege) return;
    
    setState(() {
      _valaszolva = true;
      _kivalasztottValasz = valasz;
    });

    if (valasz == _aktualisKerdes!.hal.nev) {
      setState(() => _pontszam++);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _ujKerdes();
    } else {
      setState(() => _hibakSzama++);
      
      if (_hibakSzama >= 4) {
        _jatekVegeFolyamat(); // Villogás és halál
      } else {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _ujKerdes();
      }
    }
  }

  Future<void> _jatekVegeFolyamat({bool isGyozelem = false}) async {
    setState(() => _isJatekVege = true);

    if (!isGyozelem) {
      // 3x villogás a halál előtt
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() => _isVillog = !_isVillog);
      }
      if (mounted) setState(() => _isVillog = false);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Rekord ellenőrzés
    bool isUjRekord = false;
    if (_pontszam > 0) {
      if (_rekordok.length < 10) {
        isUjRekord = true;
      } else {
        final legkisebb = _rekordok.last['pont'] as int;
        if (_pontszam > legkisebb) isUjRekord = true;
      }
    }

    if (isUjRekord) {
      _ujRekordNevezes();
    } else {
      _mutasdEredmenyek(null);
    }
  }

  void _ujRekordNevezes() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('🎉 ÚJ REKORD!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gratulálok! A $_pontszam pontod felkerült a dicsőségtáblára!', style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Írd be a neved', border: OutlineInputBorder()),
            )
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
            onPressed: () async {
              String nev = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : 'Névtelen horgász';
              String ujId = DateTime.now().millisecondsSinceEpoch.toString();
              
              _rekordok.add({'id': ujId, 'nev': nev, 'pont': _pontszam});
              _rekordok.sort((a, b) => (b['pont'] as int).compareTo(a['pont'] as int));
              if (_rekordok.length > 10) _rekordok = _rekordok.sublist(0, 10);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('kviz_rekordok', jsonEncode(_rekordok));
              
              if (mounted) {
                Navigator.pop(context);
                _mutasdEredmenyek(ujId); // Sárgával kiemeljük a táblán
              }
            },
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _mutasdEredmenyek(String? kiemeltId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.all(16),
        title: Column(
          children: [
            Text('A játék véget ért.', style: TextStyle(color: Colors.red[300], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Pontszámod: $_pontszam', style: const TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 32),
            const Text('🏆 TOP 10 REKORD', style: TextStyle(color: Colors.amber)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _rekordok.isEmpty 
              ? const Text('Még nincsenek rekordok.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _rekordok.length,
                  itemBuilder: (context, index) {
                    var r = _rekordok[index];
                    bool isSajat = r['id'] == kiemeltId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${index + 1}. ${r['nev']}', style: TextStyle(color: isSajat ? Colors.amber : Colors.white, fontWeight: isSajat ? FontWeight.bold : FontWeight.normal)),
                          Text('${r['pont']} pont', style: TextStyle(color: isSajat ? Colors.amber : Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog bezárása
              Navigator.pop(context); // Kvíz bezárása -> Vissza a lexikonba
            }, 
            child: const Text('Bezárás', style: TextStyle(color: Colors.white54))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _jatekInicializalasa());
            }, 
            child: const Text('Új Játék', style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }

  void _csakRekordokMegtekintese() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('🏆 Dicsőségtábla', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: _rekordok.isEmpty 
              ? const Text('Még nincsenek rekordok.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _rekordok.length,
                  itemBuilder: (context, index) {
                    var r = _rekordok[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${index + 1}. ${r['nev']}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                          Text('${r['pont']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bezárás', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Widget _buildEletek() {
    // 3 pötty: Ha _hibakSzama == 0 -> mind zöld. _hibakSzama == 1 -> jobb oldali piros, stb.
    List<Widget> pottyok = [];
    for (int i = 0; i < 3; i++) {
      // i = 0 (bal), i = 1 (közép), i = 2 (jobb)
      // Piros lesz, ha (3 - i) <= _hibakSzama
      bool isPiros = (3 - i) <= _hibakSzama;
      
      // Ha villog a halál előtt, és piros, akkor tüntessük el/fel
      Color szin = isPiros ? Colors.redAccent : Colors.greenAccent;
      if (_isVillog) {
        szin = Colors.transparent; 
      }

      pottyok.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: szin, shape: BoxShape.circle),
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: pottyok);
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
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            tooltip: 'Rekordok',
            onPressed: _csakRekordokMegtekintese,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Új játék',
            onPressed: () => setState(() => _jatekInicializalasa()),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              const Text('Képes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Switch(
                value: _kepesMod,
                activeColor: Colors.greenAccent,
                onChanged: _kepesMedence.isEmpty && _szovegesMedence.isEmpty ? null : _onKepesModValtas, 
              ),
            ],
          )
        ],
      ),
      body: _isJatekVege
          ? const Center(child: Text('Játék vége!', style: TextStyle(fontSize: 24, color: Colors.redAccent, fontWeight: FontWeight.bold)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Melyik halfaj ez?', style: TextStyle(fontSize: 16, color: Colors.white54)),
                      _buildEletek(),
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
                        child: _aktualisKerdes == null 
                          ? const CircularProgressIndicator(color: Colors.greenAccent)
                          : (_aktualisKerdes!.isKepes
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    File(_aktualisKerdes!.tartalom), 
                                    fit: BoxFit.contain, 
                                    width: double.infinity, 
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Builder(
                                    builder: (context) {
                                      String alapNev = _aktualisKerdes!.hal.nev.split(' (').first;
                                      String cenzurazottLeiras = _aktualisKerdes!.tartalom
                                          .replaceAll(RegExp(RegExp.escape(_aktualisKerdes!.hal.nev), caseSensitive: false), '[***]')
                                          .replaceAll(RegExp(RegExp.escape(alapNev), caseSensitive: false), '[***]');
                                      
                                      return Text(
                                        'Státusz: ${_aktualisKerdes!.hal.statusz}\n\nKategória: ${_aktualisKerdes!.hal.kategoria}\n\n$cenzurazottLeiras',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                                      );
                                    }
                                  ),
                                )),
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

                        if (_valaszolva && _aktualisKerdes != null) {
                          if (opcio == _aktualisKerdes!.hal.nev) {
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
