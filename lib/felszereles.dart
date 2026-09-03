import 'dart:io';
import 'dart:ui' as ui; 
import 'dart:typed_data'; 
import 'package:flutter/rendering.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'adattarolo.dart';
import 'modellek.dart';

class FelszerelesScreen extends StatefulWidget {
  const FelszerelesScreen({super.key});

  @override
  State<FelszerelesScreen> createState() => FelszerelesScreenState();
}

class FelszerelesScreenState extends State<FelszerelesScreen> {
  List<FelszerelesKategoria> _kategoriak = [];
  List<FelszerelesTetel> _tetelek = [];
  List<String> _taskak = [];
  List<GlobalKey> _kategoriaKeys = [];
  List<GlobalKey> _taskaKeys = [];
  
  String? _kivalasztottKategoriaId;
  String? _kivalasztottTaska;
  bool _isTaskaNezet = false;
  
  bool _isKeresoMod = false;
  String _keresoKifejezes = '';
  bool _rendezesMarkaSzerint = false;
  
  // JAVÍTVA: Két külön PageController, hogy ne húzzák el egymást!
  final PageController _kategoriaPageCtrl = PageController();
  final PageController _taskaPageCtrl = PageController();

  int _utolsoKategoriaIndex = 0;
  int _utolsoTaskaIndex = 0;
  bool get isTaskaNezet => _isTaskaNezet;

  @override
  void initState() {
    super.initState();
    adatokBetoltese();
  }

  @override
  void dispose() {
    _kategoriaPageCtrl.dispose();
    _taskaPageCtrl.dispose();
    super.dispose();
  }

  Future<void> adatokBetoltese() async {
    final kat = await AdatTarolo.felszerelesKategoriakBetoltese();
    final tet = await AdatTarolo.felszerelesTetelekBetoltese();
    final taskak = await AdatTarolo.taskakBetoltese();
    
    setState(() {
      _kategoriak = kat;
      _tetelek = tet;
      _taskak = taskak;
      
      _kategoriaKeys = List.generate(kat.length, (index) => GlobalKey());
      _taskaKeys = List.generate(taskak.length, (index) => GlobalKey());
      
      if (_utolsoKategoriaIndex >= _kategoriak.length) _utolsoKategoriaIndex = 0;
      if (_utolsoTaskaIndex >= _taskak.length) _utolsoTaskaIndex = 0;
      
      if (_kategoriak.isNotEmpty) {
        _kivalasztottKategoriaId = _kategoriak[_utolsoKategoriaIndex].id;
      } else {
        _kivalasztottKategoriaId = null;
      }
      
      if (_taskak.isNotEmpty) {
        _kivalasztottTaska = _taskak[_utolsoTaskaIndex];
      } else {
        _kivalasztottTaska = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isKeresoMod && (_kategoriak.isNotEmpty || _taskak.isNotEmpty)) {
        int aktIndex = _isTaskaNezet ? _utolsoTaskaIndex : _utolsoKategoriaIndex;
        _KozepreGorget(aktIndex);
      }
    });
  }

  void _KozepreGorget(int index) {
    if (_isKeresoMod) return;
    
    final keys = _isTaskaNezet ? _taskaKeys : _kategoriaKeys;
    if (keys.isEmpty || index >= keys.length) return;
    
    final key = keys[index];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void toggleNezet() {
    if (_isKeresoMod) {
      toggleKereso();
    }
    setState(() {
      _isTaskaNezet = !_isTaskaNezet;
    });
    
    // JAVÍTVA: Csak a releváns adatokat frissítjük, de a kontrollerek külön vannak
    int celIndex = _isTaskaNezet ? _utolsoTaskaIndex : _utolsoKategoriaIndex;
    if (_isTaskaNezet && _taskak.isNotEmpty && celIndex >= _taskak.length) celIndex = 0;
    if (!_isTaskaNezet && _kategoriak.isNotEmpty && celIndex >= _kategoriak.length) celIndex = 0;

    PageController aktCtrl = _isTaskaNezet ? _taskaPageCtrl : _kategoriaPageCtrl;
    
    if (aktCtrl.hasClients) {
      aktCtrl.jumpToPage(celIndex);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _KozepreGorget(celIndex);
    });
  }

  void toggleKereso() {
    setState(() {
      _isKeresoMod = !_isKeresoMod;
      if (!_isKeresoMod) {
        _keresoKifejezes = ''; 
      }
    });
    if (!_isKeresoMod) {
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        int celIndex = _isTaskaNezet ? _utolsoTaskaIndex : _utolsoKategoriaIndex;
        if (celIndex == -1) celIndex = 0;

        PageController aktCtrl = _isTaskaNezet ? _taskaPageCtrl : _kategoriaPageCtrl;
        if (aktCtrl.hasClients) {
          aktCtrl.jumpToPage(celIndex);
        }
        _KozepreGorget(celIndex);
      });
    }
  }

  void _tetelSzerkesztokMegnyitasa([FelszerelesTetel? tetel]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TetelSzerkesztoScreen(
          kategoriak: _kategoriak,
          alapertelmezettKategoriaId: _kivalasztottKategoriaId,
          szerkeszthetoTetel: tetel,
          mentesCallback: () => adatokBetoltese(),
        ),
      ),
    );
  }

  void _tetelMasolasa(FelszerelesTetel eredeti) {
    final ujTetel = FelszerelesTetel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      kategoriaId: eredeti.kategoriaId,
      marka: eredeti.marka,
      nev: 'Másolat - ${eredeti.nev}', 
      jellemzo: eredeti.jellemzo,
      mertekegyseg: eredeti.mertekegyseg,
      leiras: eredeti.leiras,
      kepek: List.from(eredeti.kepek),
      elhelyezesek: eredeti.elhelyezesek.map((e) => FelszerelesElhelyezes(
        taska: e.taska,
        pozicio: e.pozicio,
        mennyiseg: e.mennyiseg,
      )).toList(),
      indexKep: eredeti.indexKep,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TetelSzerkesztoScreen(
          kategoriak: _kategoriak,
          szerkeszthetoTetel: ujTetel,
          isMasolat: true, 
          mentesCallback: () {
            adatokBetoltese();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tétel sikeresen lemásolva és mentve!'), backgroundColor: Colors.green),
              );
            }
          },
        ),
      ),
    );
  }

  void _tetelTorlese(FelszerelesTetel tetel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Tétel törlése'),
        content: Text('Biztosan törölni szeretnéd ezt a tételt: ${tetel.nev}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              _tetelek.removeWhere((t) => t.id == tetel.id);
              await AdatTarolo.felszerelesTetelekMentes(_tetelek);
              if (mounted) Navigator.pop(context);
              adatokBetoltese();
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _huSort(String text) {
    return text.toLowerCase()
      .replaceAll('á', 'a~')
      .replaceAll('é', 'e~')
      .replaceAll('í', 'i~')
      .replaceAll('ó', 'o~')
      .replaceAll('ö', 'o~~')
      .replaceAll('ő', 'o~~~')
      .replaceAll('ú', 'u~')
      .replaceAll('ü', 'u~~')
      .replaceAll('ű', 'u~~~');
  }

  int _naturalHuCompare(String a, String b) {
    String aHu = _huSort(a);
    String bHu = _huSort(b);
    final RegExp regExp = RegExp(r'(\d+)|([^\d]+)');
    final List<String> partsA = regExp.allMatches(aHu).map((m) => m.group(0)!).toList();
    final List<String> partsB = regExp.allMatches(bHu).map((m) => m.group(0)!).toList();
    int minLen = partsA.length < partsB.length ? partsA.length : partsB.length;
    for (int i = 0; i < minLen; i++) {
      String pA = partsA[i];
      String pB = partsB[i];
      
      bool isNumA = RegExp(r'^\d+$').hasMatch(pA);
      bool isNumB = RegExp(r'^\d+$').hasMatch(pB);
      if (isNumA && isNumB) {
        int numA = int.parse(pA);
        int numB = int.parse(pB);
        int cmp = numA.compareTo(numB);
        if (cmp != 0) return cmp;
      } else {
        int cmp = pA.compareTo(pB);
        if (cmp != 0) return cmp;
      }
    }
    return partsA.length.compareTo(partsB.length);
  }

  Widget _buildTetelKartya(FelszerelesTetel tetel, String? aktivTaskaNezet) {
    final markaNev = tetel.marka.trim();
    List<Widget> helyWidgetek = [];
    double osszesen = 0;
    int darabosHelyek = 0;

    List<FelszerelesElhelyezes> megjelenitendoHelyek = aktivTaskaNezet != null 
        ? tetel.elhelyezesek.where((e) => e.taska == aktivTaskaNezet).toList() 
        : tetel.elhelyezesek;
    for (var hely in megjelenitendoHelyek) {
      if (hely.taska == null && hely.pozicio == null && hely.mennyiseg == null) continue;
      List<String> tp = [];
      if (hely.taska != null && hely.taska!.isNotEmpty) tp.add(hely.taska!);
      if (hely.pozicio != null && hely.pozicio!.isNotEmpty) tp.add(hely.pozicio!);
      String balSzoveg = tp.join(' - ');
      String jobbSzoveg = '';
      if (hely.mennyiseg != null) {
        jobbSzoveg = '${hely.mennyiseg.toString().replaceAll('.0', '')} ${tetel.mertekegyseg}'.trim();
        osszesen += hely.mennyiseg!;
        darabosHelyek++;
      }

      if (balSzoveg.isEmpty && jobbSzoveg.isEmpty) continue;
      helyWidgetek.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (balSzoveg.isNotEmpty) ...[
                Expanded(child: Text(balSzoveg, style: const TextStyle(fontSize: 13, color: Colors.amber), overflow: TextOverflow.ellipsis)),
                if (jobbSzoveg.isNotEmpty) Text(jobbSzoveg, style: const TextStyle(fontSize: 13, color: Colors.white)),
              ] else ...[
                Expanded(child: Text(jobbSzoveg, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: Colors.white))),
              ]
            ],
          ),
        )
      );
    }

    if (aktivTaskaNezet == null && darabosHelyek > 1) {
      helyWidgetek.add(const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(color: Colors.white24, height: 1)));
      helyWidgetek.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Összesen:', style: TextStyle(fontSize: 13, color: Colors.white54, fontStyle: FontStyle.italic)),
            Text('${osszesen.toString().replaceAll('.0', '')} ${tetel.mertekegyseg}'.trim(), style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
          ]
        )
      );
    }

    Widget kepWidget = const Icon(Icons.image_not_supported, color: Colors.white24, size: 30);
    if (tetel.indexKep != null) {
      if (tetel.indexKep!.startsWith('http')) {
        kepWidget = CachedNetworkImage(imageUrl: tetel.indexKep!, fit: BoxFit.cover);
      } else if (File(tetel.indexKep!).existsSync()) {
        kepWidget = Image.file(File(tetel.indexKep!), fit: BoxFit.cover);
      }
    } else if (tetel.kepek.isNotEmpty) {
      if (tetel.kepek.first.startsWith('http')) {
        kepWidget = CachedNetworkImage(imageUrl: tetel.kepek.first, fit: BoxFit.cover);
      } else if (File(tetel.kepek.first).existsSync()) {
        kepWidget = Image.file(File(tetel.kepek.first), fit: BoxFit.cover);
      }
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TetelReszletekScreen(
              tetel: tetel,
              onEdit: () {
                Navigator.pop(context);
                _tetelSzerkesztokMegnyitasa(tetel);
              },
            )),
          );
        },
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: kepWidget,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12, right: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (markaNev.isNotEmpty) ...[
                          Text(markaNev, style: const TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                        ],
                        Text(tetel.nev, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (tetel.jellemzo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(tetel.jellemzo, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ],
                        const SizedBox(height: 8),
                        if (helyWidgetek.isNotEmpty)
                          Column(children: helyWidgetek)
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                color: const Color(0xFF1E1E1E),
                onSelected: (value) {
                  if (value == 'edit') _tetelSzerkesztokMegnyitasa(tetel);
                  if (value == 'copy') _tetelMasolasa(tetel); 
                  if (value == 'delete') _tetelTorlese(tetel);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Szerkesztés')),
                  const PopupMenuItem(value: 'copy', child: Text('Másolás')), 
                  const PopupMenuItem(value: 'delete', child: Text('Törlés', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rendezesLogika(List<FelszerelesTetel> lista) {
    lista.sort((a, b) {
      if (_rendezesMarkaSzerint) {
        int markaCmp = _naturalHuCompare(a.marka.trim(), b.marka.trim());
        if (markaCmp != 0) return markaCmp;
        
        int katA = _kategoriak.firstWhere((k) => k.id == a.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;
        int katB = _kategoriak.firstWhere((k) => k.id == b.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;
        if (katA != katB) return katA.compareTo(katB);
        
        int nevCmp = _naturalHuCompare(a.nev.trim(), b.nev.trim());
        if (nevCmp != 0) return nevCmp;
        
        return _naturalHuCompare(a.jellemzo.trim(), b.jellemzo.trim());
      } else {
        int katA = _kategoriak.firstWhere((k) => k.id == a.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;
        int katB = _kategoriak.firstWhere((k) => k.id == b.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;
        if (katA != katB) return katA.compareTo(katB);

        int markaCmp = _naturalHuCompare(a.marka.trim(), b.marka.trim());
        if (markaCmp != 0) return markaCmp;
        
        int nevCmp = _naturalHuCompare(a.nev.trim(), b.nev.trim());
        if (nevCmp != 0) return nevCmp;
        
        return _naturalHuCompare(a.jellemzo.trim(), b.jellemzo.trim());
      }
    });
  }

  Widget _buildKeresoEredmenyek() {
    List<FelszerelesTetel> eredmeny = List.from(_tetelek);
    if (_keresoKifejezes.trim().isNotEmpty) {
      List<String> kulcsszavak = _keresoKifejezes.toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();
      eredmeny = eredmeny.where((tetel) {
        String fullSzoveg = '${tetel.marka} ${tetel.nev} ${tetel.jellemzo} ${tetel.leiras}'.toLowerCase();
        for (String szo in kulcsszavak) {
          if (!fullSzoveg.contains(szo)) return false; 
        }
        return true;
      }).toList();
    }

    _rendezesLogika(eredmeny);
    
    if (eredmeny.isEmpty) {
      return const Center(child: Text('Nincs találat a keresésre.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100),
      itemCount: eredmeny.length,
      itemBuilder: (context, idx) {
        return _buildTetelKartya(eredmeny[idx], null); 
      },
    );
  }

  Widget _buildListaOldal(int index) {
    List<FelszerelesTetel> mutathato;
    String? aktTaska;
    if (_isTaskaNezet) {
      if (_taskak.isEmpty) return const Center(child: Text('Nincsenek rögzített táskák.', style: TextStyle(color: Colors.white54)));
      aktTaska = _taskak[index];
      mutathato = _tetelek.where((t) => t.elhelyezesek.any((e) => e.taska == aktTaska)).toList();
      _rendezesLogika(mutathato);
    } else {
      if (_kategoriak.isEmpty) return const Center(child: Text('Nincsenek kategóriák. Hozz létre egyet!'));
      String aktKat = _kategoriak[index].id;
      mutathato = _tetelek.where((t) => t.kategoriaId == aktKat).toList();
      _rendezesLogika(mutathato);
    }

    if (mutathato.isEmpty) {
      return Center(child: Text('Ebben a ${_isTaskaNezet ? 'táskában' : 'kategóriában'} nincsenek tételek.', style: const TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100),
      itemCount: mutathato.length,
      itemBuilder: (context, idx) {
        return _buildTetelKartya(mutathato[idx], aktTaska);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int oldalszam = _isTaskaNezet ? _taskak.length : _kategoriak.length;
    Color aktivSzin = _isTaskaNezet ? Colors.orangeAccent : Colors.greenAccent;

    return Scaffold(
      backgroundColor: _isTaskaNezet && !_isKeresoMod ? Colors.amber.withOpacity(0.12) : Colors.transparent,
      body: Column(
        children: [
          if (_isKeresoMod)
            Container(
              height: 55,
              color: const Color(0xFF161616),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                autofocus: true,
                textCapitalization: TextCapitalization.sentences, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Keresés márka, név, jellemző...',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.search, color: aktivSzin),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.sort, color: _rendezesMarkaSzerint ? Colors.amber : Colors.white54),
                        tooltip: 'Rendezés váltása (Kategória / Márka)',
                        onPressed: () {
                          setState(() {
                            _rendezesMarkaSzerint = !_rendezesMarkaSzerint;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(_rendezesMarkaSzerint ? 'Rendezés: Márka -> Kategória -> Név' : 'Rendezés: Kategória -> Márka -> Név'),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => setState(() => _keresoKifejezes = ''),
                      ),
                    ],
                  ),
                ),
                onChanged: (val) => setState(() => _keresoKifejezes = val),
              ),
            )
          else
            Container(
              height: 50,
              color: const Color(0xFF161616),
              child: oldalszam == 0 
                  ? const SizedBox() 
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(oldalszam, (index) {
                          String nev;
                          bool isSelected;
                          GlobalKey? gKey;
                         
                          if (_isTaskaNezet) {
                            nev = _taskak[index];
                            isSelected = nev == _kivalasztottTaska;
                            if (index < _taskaKeys.length) gKey = _taskaKeys[index];
                          } else {
                            nev = _kategoriak[index].nev;
                            isSelected = _kategoriak[index].id == _kivalasztottKategoriaId;
                            if (index < _kategoriaKeys.length) gKey = _kategoriaKeys[index];
                          }
                         
                          return GestureDetector(
                            onTap: () {
                              PageController aktCtrl = _isTaskaNezet ? _taskaPageCtrl : _kategoriaPageCtrl;
                              if (aktCtrl.hasClients) {
                                aktCtrl.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            },
                            child: Container(
                              key: gKey,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isSelected ? aktivSzin : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    nev,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.transparent,   
                                    ),
                                  ),
                                  Text(
                                    nev,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? aktivSzin : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
            ),
          
          Expanded(
            child: _isKeresoMod
              ? _buildKeresoEredmenyek()
              : oldalszam == 0 
                ? Center(child: Text(_isTaskaNezet ? 'Nincsenek rögzített táskák.' : 'Nincsenek kategóriák. Hozz létre egyet!'))
                : PageView.builder(
                    controller: _isTaskaNezet ? _taskaPageCtrl : _kategoriaPageCtrl, // JAVÍTVA
                    itemCount: oldalszam,
                    onPageChanged: (index) {
                      setState(() {
                        if (_isTaskaNezet) {
                          _kivalasztottTaska = _taskak[index];
                          _utolsoTaskaIndex = index;
                        } else {
                          _kivalasztottKategoriaId = _kategoriak[index].id;
                          _utolsoKategoriaIndex = index;
                        }
                      });
                      _KozepreGorget(index);
                    },
                    itemBuilder: (context, index) {
                      return _buildListaOldal(index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _tetelSzerkesztokMegnyitasa(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ... AZ ALATTA LÉVŐ OSZTÁLYOK (TetelReszletekScreen, TetelSzerkesztoScreen, KategoriakSzerkesztoScreen, TaskakSzerkesztoScreen) 
// TELJESEN VÁLTOZATLANOK MARADTAK AZ ELŐZŐ VERZIÓHOZ KÉPEST!
// Csak ezt az első ~500 sort másold be a fájl elejére a régi FelszerelesScreen helyett!
