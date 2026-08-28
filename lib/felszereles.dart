import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  
  final PageController _pageController = PageController();

  bool get isTaskaNezet => _isTaskaNezet;

  @override
  void initState() {
    super.initState();
    adatokBetoltese();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      
      if (_kategoriak.isNotEmpty && _kivalasztottKategoriaId == null) {
        _kivalasztottKategoriaId = _kategoriak.first.id;
      }
      if (_taskak.isNotEmpty && _kivalasztottTaska == null) {
        _kivalasztottTaska = _taskak.first;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isKeresoMod && (_kategoriak.isNotEmpty || _taskak.isNotEmpty)) {
        _KozepreGorget(_pageController.hasClients ? _pageController.page?.round() ?? 0 : 0);
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
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _KozepreGorget(0);
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
        int celIndex = 0;
        if (_isTaskaNezet) {
          celIndex = _taskak.indexOf(_kivalasztottTaska ?? '');
        } else {
          celIndex = _kategoriak.indexWhere((k) => k.id == _kivalasztottKategoriaId);
        }
        
        if (celIndex == -1) celIndex = 0;

        if (_pageController.hasClients) {
          _pageController.jumpToPage(celIndex);
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
                  child: tetel.kepek.isNotEmpty && File(tetel.kepek.first).existsSync()
                      ? Image.file(File(tetel.kepek.first), fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, color: Colors.white24, size: 30),
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
                  if (value == 'delete') _tetelTorlese(tetel);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Szerkesztés')),
                  const PopupMenuItem(value: 'delete', child: Text('Törlés', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    eredmeny.sort((a, b) {
      int katA = _kategoriak.firstWhere((k) => k.id == a.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;
      int katB = _kategoriak.firstWhere((k) => k.id == b.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;
      
      if (katA != katB) return katA.compareTo(katB);

      int markaCmp = _huSort(a.marka.trim()).compareTo(_huSort(b.marka.trim()));
      if (markaCmp != 0) return markaCmp;
      
      int nevCmp = _huSort(a.nev.trim()).compareTo(_huSort(b.nev.trim()));
      if (nevCmp != 0) return nevCmp;
      
      return _huSort(a.jellemzo.trim()).compareTo(_huSort(b.jellemzo.trim()));
    });

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
      
      mutathato.sort((a, b) {
        int katA = _kategoriak.firstWhere((k) => k.id == a.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;
        int katB = _kategoriak.firstWhere((k) => k.id == b.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: '', sorrend: 999)).sorrend;

        if (katA != katB) return katA.compareTo(katB);

        int markaCmp = _huSort(a.marka.trim()).compareTo(_huSort(b.marka.trim()));
        if (markaCmp != 0) return markaCmp;
        
        int nevCmp = _huSort(a.nev.trim()).compareTo(_huSort(b.nev.trim()));
        if (nevCmp != 0) return nevCmp;

        return _huSort(a.jellemzo.trim()).compareTo(_huSort(b.jellemzo.trim()));
      });
    } else {
      if (_kategoriak.isEmpty) return const Center(child: Text('Nincsenek kategóriák. Hozz létre egyet!'));
      String aktKat = _kategoriak[index].id;
      mutathato = _tetelek.where((t) => t.kategoriaId == aktKat).toList();
      
      mutathato.sort((a, b) {
        int markaCmp = _huSort(a.marka.trim()).compareTo(_huSort(b.marka.trim()));
        if (markaCmp != 0) return markaCmp;
        
        int nevCmp = _huSort(a.nev.trim()).compareTo(_huSort(b.nev.trim()));
        if (nevCmp != 0) return nevCmp;

        return _huSort(a.jellemzo.trim()).compareTo(_huSort(b.jellemzo.trim()));
      });
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Keresés márka, név, jellemző, leírás alapján...',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.search, color: aktivSzin),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => setState(() => _keresoKifejezes = ''),
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
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: oldalszam,
                itemBuilder: (context, index) {
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
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                },
              ),
            ),
          
          Expanded(
            child: _isKeresoMod
              ? _buildKeresoEredmenyek()
              : oldalszam == 0 
                ? Center(child: Text(_isTaskaNezet ? 'Nincsenek rögzített táskák.' : 'Nincsenek kategóriák. Hozz létre egyet!'))
                : PageView.builder(
                    controller: _pageController,
                    itemCount: oldalszam,
                    onPageChanged: (index) {
                      setState(() {
                        if (_isTaskaNezet) {
                          _kivalasztottTaska = _taskak[index];
                        } else {
                          _kivalasztottKategoriaId = _kategoriak[index].id;
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

class TetelReszletekScreen extends StatefulWidget {
  final FelszerelesTetel tetel;
  final VoidCallback? onEdit; 

  const TetelReszletekScreen({super.key, required this.tetel, this.onEdit});

  @override
  State<TetelReszletekScreen> createState() => _TetelReszletekScreenState();
}

class _TetelReszletekScreenState extends State<TetelReszletekScreen> {
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
            itemCount: widget.tetel.kepek.length,
            itemBuilder: (context, i) {
              final utvonal = widget.tetel.kepek[i];
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

  @override
  Widget build(BuildContext context) {
    final markaNev = widget.tetel.marka.trim();
    
    List<Widget> helyWidgetekReszletes = [];
    double osszesen = 0;
    int darabosHelyek = 0;

    for (var hely in widget.tetel.elhelyezesek) {
      if (hely.taska == null && hely.pozicio == null && hely.mennyiseg == null) continue;
      
      List<String> tp = [];
      if (hely.taska != null && hely.taska!.isNotEmpty) tp.add(hely.taska!);
      if (hely.pozicio != null && hely.pozicio!.isNotEmpty) tp.add(hely.pozicio!);
      String balSzoveg = tp.join(' - ');
      String jobbSzoveg = '';
      
      if (hely.mennyiseg != null) {
        jobbSzoveg = '${hely.mennyiseg.toString().replaceAll('.0', '')} ${widget.tetel.mertekegyseg}'.trim();
        osszesen += hely.mennyiseg!;
        darabosHelyek++;
      }

      if (balSzoveg.isEmpty && jobbSzoveg.isEmpty) continue;

      helyWidgetekReszletes.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (balSzoveg.isNotEmpty) ...[
                const Icon(Icons.location_on, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(balSzoveg, style: const TextStyle(fontSize: 15, color: Colors.amber))),
                if (jobbSzoveg.isNotEmpty) Text(jobbSzoveg, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ] else ...[
                const Icon(Icons.inventory_2, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(jobbSzoveg, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold))),
              ]
            ],
          ),
        )
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.tetel.nev)),
      floatingActionButton: widget.onEdit != null 
        ? FloatingActionButton(
            backgroundColor: Colors.green[600],
            onPressed: widget.onEdit,
            child: const Icon(Icons.edit, color: Colors.white),
          )
        : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (markaNev.isNotEmpty) ...[
                    Text(markaNev, style: const TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                  Text(widget.tetel.nev, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (widget.tetel.jellemzo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.tetel.jellemzo, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                  
                  if (helyWidgetekReszletes.isNotEmpty) ...[
                    const Divider(color: Colors.white24, height: 32),
                    const Text('Tárolási helyek', style: TextStyle(fontSize: 14, color: Colors.white54, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    ...helyWidgetekReszletes,
                    if (darabosHelyek > 1) ...[
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Összesen:', style: TextStyle(fontSize: 16, color: Colors.white54)),
                          Text(
                            '${osszesen.toString().replaceAll('.0', '')} ${widget.tetel.mertekegyseg}'.trim(),
                            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ]
                  ],
                ],
              ),
            ),
            
            if (widget.tetel.kepek.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Fényképek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: widget.tetel.kepek.length,
                      itemBuilder: (context, i) {
                        final utvonal = widget.tetel.kepek[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => _teljesKepernyosGaleria(context, i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (utvonal.startsWith('http'))
                                ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.cover)
                                : (File(utvonal).existsSync() ? Image.file(File(utvonal), fit: BoxFit.cover) : const Icon(Icons.broken_image, size: 50, color: Colors.white24)),
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.tetel.kepek.length > 1) ...[
                      Positioned(
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () {
                              _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () {
                              _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (widget.tetel.kepek.length > 1)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Lapozz a többi képért ↔', style: TextStyle(color: Colors.white38, fontSize: 12)),
                )),
            ],

            if (widget.tetel.leiras.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leírás', style: TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.tetel.leiras, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class ElhelyezesVezerlo {
  String? taska;
  TextEditingController pozicioCtrl = TextEditingController();
  TextEditingController mennyisegCtrl = TextEditingController();
  
  void dispose() {
    pozicioCtrl.dispose();
    mennyisegCtrl.dispose();
  }
}

class TetelSzerkesztoScreen extends StatefulWidget {
  final List<FelszerelesKategoria> kategoriak;
  final String? alapertelmezettKategoriaId;
  final FelszerelesTetel? szerkeszthetoTetel;
  final VoidCallback mentesCallback;

  const TetelSzerkesztoScreen({
    super.key,
    required this.kategoriak,
    this.alapertelmezettKategoriaId,
    this.szerkeszthetoTetel,
    required this.mentesCallback,
  });

  @override
  State<TetelSzerkesztoScreen> createState() => _TetelSzerkesztoScreenState();
}

class _TetelSzerkesztoScreenState extends State<TetelSzerkesztoScreen> {
  final _markaCtrl = TextEditingController();
  final _nevCtrl = TextEditingController();
  final _jellemzoCtrl = TextEditingController();
  final _mertekegysegCtrl = TextEditingController();
  final _leirasCtrl = TextEditingController();
  
  String? _kivalasztottKategoriaId;
  List<String> _kepek = [];
  List<String> _elerhetoTaskak = []; 
  
  List<ElhelyezesVezerlo> _helyek = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();

    _kivalasztottKategoriaId = widget.alapertelmezettKategoriaId;
    
    _mertekegysegCtrl.addListener(() {
      setState(() {});
    });
    
    if (widget.szerkeszthetoTetel != null) {
      final t = widget.szerkeszthetoTetel!;
      _kivalasztottKategoriaId = t.kategoriaId;
      _markaCtrl.text = t.marka;
      _nevCtrl.text = t.nev;
      _jellemzoCtrl.text = t.jellemzo;
      _mertekegysegCtrl.text = t.mertekegyseg;
      _leirasCtrl.text = t.leiras;
      _kepek = List.from(t.kepek);
      
      if (t.elhelyezesek.isNotEmpty) {
        for (var e in t.elhelyezesek) {
          var v = ElhelyezesVezerlo();
          v.taska = e.taska;
          if (e.pozicio != null) v.pozicioCtrl.text = e.pozicio!;
          if (e.mennyiseg != null) v.mennyisegCtrl.text = e.mennyiseg.toString().replaceAll('.0', '');
          _helyek.add(v);
        }
      } else {
        _helyek.add(ElhelyezesVezerlo()); 
      }
    } else {
      if (widget.kategoriak.isNotEmpty && _kivalasztottKategoriaId == null) {
        _kivalasztottKategoriaId = widget.kategoriak.first.id;
      }
      _helyek.add(ElhelyezesVezerlo()); 
    }
  }

  @override
  void dispose() {
    for (var v in _helyek) {
      v.dispose();
    }
    _mertekegysegCtrl.dispose();
    super.dispose();
  }

  Future<void> _adatokBetoltese() async {
    final taskak = await AdatTarolo.taskakBetoltese();
    setState(() {
      _elerhetoTaskak = taskak;
      for (var v in _helyek) {
        if (v.taska != null && v.taska!.isNotEmpty && !_elerhetoTaskak.contains(v.taska)) {
          v.taska = null;
        }
      }
    });
  }

  Future<void> _kepHozzaadasa() async {
    if (_kepek.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 képet adhatsz hozzá!')));
      return;
    }
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      int szabadHely = 5 - _kepek.length;
      int hozzaadandoSzam = images.length > szabadHely ? szabadHely : images.length;
      
      for (int i = 0; i < hozzaadandoSzam; i++) {
        String biztonsagosUtvonal = await AdatTarolo.biztonsagosKepMasolas(images[i].path);
        setState(() {
          _kepek.add(biztonsagosUtvonal);
        });
      }
      
      if (images.length > szabadHely && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Csak $szabadHely képet lehetett még hozzáadni a limit miatt!'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }
  
  void _ujTaskaHozzaadaskor(int index) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új Táska / Doboz hozzáadása'),
        content: TextField(
          controller: ctrl, 
          autofocus: true, 
          onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: const InputDecoration(labelText: 'Táska megnevezése')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final nev = ctrl.text.trim();
                if (!_elerhetoTaskak.contains(nev)) {
                  _elerhetoTaskak.add(nev);
                  await AdatTarolo.taskakMentes(_elerhetoTaskak);
                }
                setState(() => _helyek[index].taska = nev);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mutasTaskaKereso(int index) async {
    String kereses = '';
    final keresoCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final szurt = _elerhetoTaskak.where((e) => e.toLowerCase().contains(kereses.toLowerCase())).toList();
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Táska / Doboz kiválasztása', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: keresoCtrl,
                        autofocus: true,
                        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: InputDecoration(
                          hintText: 'Keresés...',
                          prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.redAccent),
                            onPressed: () {
                              keresoCtrl.clear();
                              setModalState(() => kereses = '');
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) => setModalState(() => kereses = val),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.greenAccent),
                      title: const Text('Új Táska/Doboz hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        _ujTaskaHozzaadaskor(index);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear, color: Colors.redAccent),
                      title: const Text('-- Nincs megadva --', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        setState(() => _helyek[index].taska = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: szurt.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            title: Text(szurt[i]),
                            onTap: () {
                              setState(() => _helyek[index].taska = szurt[i]);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mentes() async {
    if (_kivalasztottKategoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Válassz kategóriát!')));
      return;
    }
    if (_nevCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A név megadása kötelező!')));
      return;
    }

    List<FelszerelesElhelyezes> ujElhelyezesek = [];
    for (var v in _helyek) {
      double? menny = double.tryParse(v.mennyisegCtrl.text.replaceAll(',', '.'));
      String? poz = v.pozicioCtrl.text.trim();
      if (poz.isEmpty) poz = null;
      
      if (v.taska != null || poz != null || menny != null) {
        ujElhelyezesek.add(FelszerelesElhelyezes(taska: v.taska, pozicio: poz, mennyiseg: menny));
      }
    }

    final ujTetel = FelszerelesTetel(
      id: widget.szerkeszthetoTetel?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      kategoriaId: _kivalasztottKategoriaId!,
      marka: _markaCtrl.text.trim(),
      nev: _nevCtrl.text.trim(),
      jellemzo: _jellemzoCtrl.text.trim(),
      mertekegyseg: _mertekegysegCtrl.text.trim(),
      leiras: _leirasCtrl.text.trim(),
      kepek: _kepek,
      elhelyezesek: ujElhelyezesek, 
    );

    final osszesTetel = await AdatTarolo.felszerelesTetelekBetoltese();
    if (widget.szerkeszthetoTetel != null) {
      final idx = osszesTetel.indexWhere((t) => t.id == ujTetel.id);
      if (idx != -1) osszesTetel[idx] = ujTetel;
    } else {
      osszesTetel.add(ujTetel);
    }

    await AdatTarolo.felszerelesTetelekMentes(osszesTetel);
    widget.mentesCallback();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.szerkeszthetoTetel == null ? 'Új Tétel Hozzáadása' : 'Tétel Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _kivalasztottKategoriaId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategória *', border: OutlineInputBorder()),
              items: widget.kategoriak.map((k) => DropdownMenuItem(value: k.id, child: Text(k.nev))).toList(),
              onChanged: (val) => setState(() => _kivalasztottKategoriaId = val),
            ),
            const SizedBox(height: 16),
            
            TextField(controller: _markaCtrl, decoration: const InputDecoration(labelText: 'Márka (opcionális)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _nevCtrl, decoration: const InputDecoration(labelText: 'Név *', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _jellemzoCtrl, decoration: const InputDecoration(labelText: 'Jellemző (opcionális)', border: OutlineInputBorder())),
            const Divider(height: 40, color: Colors.white24),

            const Text('Tárolási helyek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
            const SizedBox(height: 12),
            
            Column(
              children: List.generate(_helyek.length, (index) {
                var v = _helyek[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${index + 1}. Tárolási hely', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                          if (index > 0)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _helyek.removeAt(index)),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _mutasTaskaKereso(index),
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Táska / Doboz (opcionális)', border: OutlineInputBorder()),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(v.taska ?? '-- Nincs megadva --', style: TextStyle(color: v.taska == null ? Colors.white54 : Colors.white))),
                              const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: v.pozicioCtrl, decoration: const InputDecoration(labelText: 'Pozíció / Rekesz (opcionális)', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 1, 
                            child: TextField(controller: v.mennyisegCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mennyiség', border: OutlineInputBorder()))
                          ),
                          const SizedBox(width: 12),
                          if (index == 0)
                            Expanded(
                              flex: 1, 
                              child: TextField(controller: _mertekegysegCtrl, decoration: const InputDecoration(labelText: 'Mértékegység', border: OutlineInputBorder()))
                            )
                          else
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(_mertekegysegCtrl.text.isNotEmpty ? _mertekegysegCtrl.text : '', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                              )
                            )
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
            
            TextButton.icon(
              onPressed: () {
                setState(() => _helyek.add(ElhelyezesVezerlo()));
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
              label: const Text('ÚJ TÁROLÁSI HELY', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const Divider(height: 40, color: Colors.white24),

            TextField(controller: _leirasCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Felszerelés leírása (opcionális)', border: OutlineInputBorder())),
            const SizedBox(height: 24),

            const Text('Fényképek (Maximum 5 db)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._kepek.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String utvonal = entry.value;
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                        clipBehavior: Clip.antiAlias,
                        child: utvonal.startsWith('http')
                            ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.cover)
                            : Image.file(File(utvonal), fit: BoxFit.cover),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _kepek.removeAt(idx)),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                          child: const Icon(Icons.close, color: Colors.redAccent, size: 24),
                        ),
                      ),
                    ],
                  );
                }),
                if (_kepek.length < 5)
                  GestureDetector(
                    onTap: _kepHozzaadasa,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),
                      child: const Center(child: Icon(Icons.add_a_photo, color: Colors.greenAccent, size: 30)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _mentes,
              child: const Text('TÉTEL MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class KategoriakSzerkesztoScreen extends StatefulWidget {
  final List<FelszerelesKategoria> kategoriak;
  final VoidCallback mentesCallback;

  const KategoriakSzerkesztoScreen({super.key, required this.kategoriak, required this.mentesCallback});

  @override
  State<KategoriakSzerkesztoScreen> createState() => _KategoriakSzerkesztoScreenState();
}

class _KategoriakSzerkesztoScreenState extends State<KategoriakSzerkesztoScreen> {
  late List<FelszerelesKategoria> _helyiKategoriak;

  @override
  void initState() {
    super.initState();
    _helyiKategoriak = List.from(widget.kategoriak);
    _helyiKategoriak.sort((a, b) => a.sorrend.compareTo(b.sorrend));
  }

  Future<void> _mentes() async {
    for (int i = 0; i < _helyiKategoriak.length; i++) {
      _helyiKategoriak[i].sorrend = i;
    }
    await AdatTarolo.felszerelesKategoriakMentes(_helyiKategoriak);
    widget.mentesCallback();
  }

  void _kategoriaSzerkesztes(int index) {
    final ctrl = TextEditingController(text: _helyiKategoriak[index].nev);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Kategória szerkesztése'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Név')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _helyiKategoriak[index] = FelszerelesKategoria(
                    id: _helyiKategoriak[index].id,
                    nev: ctrl.text.trim(),
                    sorrend: _helyiKategoriak[index].sorrend,
                  );
                });
                _mentes();
                Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _kategoriaTorles(int index) async {
    final tet = await AdatTarolo.felszerelesTetelekBetoltese();
    bool vanBenneTetel = tet.any((t) => t.kategoriaId == _helyiKategoriak[index].id);

    if (vanBenneTetel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ez a kategória nem törölhető, mert vannak benne tételek!'), backgroundColor: Colors.redAccent));
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Törlés'),
        content: const Text('Biztosan törölni szeretnéd ezt a kategóriát?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              setState(() => _helyiKategoriak.removeAt(index));
              _mentes();
              Navigator.pop(context);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ujKategoria() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új Kategória'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Név')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _helyiKategoriak.add(FelszerelesKategoria(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nev: ctrl.text.trim(),
                    sorrend: _helyiKategoriak.length,
                  ));
                });
                _mentes();
                Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategóriák Szerkesztése')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Tartsd lenyomva a jobb oldali ikont a kategóriák sorrendjének átrendezéséhez!', style: TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: ReorderableListView(
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _helyiKategoriak.removeAt(oldIndex);
                  _helyiKategoriak.insert(newIndex, item);
                });
                _mentes();
              },
              children: [
                for (int i = 0; i < _helyiKategoriak.length; i++)
                  Card(
                    key: ValueKey(_helyiKategoriak[i].id),
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(_helyiKategoriak[i].nev, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () => _kategoriaSzerkesztes(i)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _kategoriaTorles(i)),
                          const SizedBox(width: 16),
                          const Icon(Icons.drag_handle, color: Colors.greenAccent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: _ujKategoria,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class TaskakSzerkesztoScreen extends StatefulWidget {
  final List<String> taskak;
  final VoidCallback mentesCallback;

  const TaskakSzerkesztoScreen({super.key, required this.taskak, required this.mentesCallback});

  @override
  State<TaskakSzerkesztoScreen> createState() => _TaskakSzerkesztoScreenState();
}

class _TaskakSzerkesztoScreenState extends State<TaskakSzerkesztoScreen> {
  late List<String> _helyiTaskak;

  @override
  void initState() {
    super.initState();
    _helyiTaskak = List.from(widget.taskak);
  }

  Future<void> _mentes() async {
    await AdatTarolo.taskakMentes(_helyiTaskak);
    widget.mentesCallback();
  }

  void _taskaSzerkesztes(int index) {
    final ctrl = TextEditingController(text: _helyiTaskak[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Táska szerkesztése'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Név')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _helyiTaskak[index] = ctrl.text.trim();
                });
                _mentes();
                Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _taskaTorles(int index) async {
    final tet = await AdatTarolo.felszerelesTetelekBetoltese();
    bool vanBenneTetel = tet.any((t) => t.elhelyezesek.any((e) => e.taska == _helyiTaskak[index]));

    if (vanBenneTetel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ez a táska nem törölhető, mert vannak benne tételek!'), backgroundColor: Colors.redAccent));
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Törlés'),
        content: const Text('Biztosan törölni szeretnéd ezt a táskát?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              setState(() => _helyiTaskak.removeAt(index));
              _mentes();
              Navigator.pop(context);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ujTaska() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új Táska / Doboz'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Név')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _helyiTaskak.add(ctrl.text.trim());
                });
                _mentes();
                Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Táskák Szerkesztése')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Tartsd lenyomva a jobb oldali ikont a táskák sorrendjének átrendezéséhez!', style: TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: ReorderableListView(
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _helyiTaskak.removeAt(oldIndex);
                  _helyiTaskak.insert(newIndex, item);
                });
                _mentes();
              },
              children: [
                for (int i = 0; i < _helyiTaskak.length; i++)
                  Card(
                    key: ValueKey(_helyiTaskak[i]),
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(_helyiTaskak[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () => _taskaSzerkesztes(i)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _taskaTorles(i)),
                          const SizedBox(width: 16),
                          const Icon(Icons.drag_handle, color: Colors.greenAccent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: _ujTaska,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
