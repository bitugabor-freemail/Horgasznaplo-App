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
  
  String? _kivalasztottKategoriaId;
  String? _kivalasztottTaska;
  bool _isTaskaNezet = false;
  
  final PageController _pageController = PageController();

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
    // Itt kivettük a taskak.sort() részt, hogy maradjon a Drag & Drop sorrend!
    
    setState(() {
      _kategoriak = kat;
      _tetelek = tet;
      _taskak = taskak;
      
      if (_kategoriak.isNotEmpty && _kivalasztottKategoriaId == null) {
        _kivalasztottKategoriaId = _kategoriak.first.id;
      }
      if (_taskak.isNotEmpty && _kivalasztottTaska == null) {
        _kivalasztottTaska = _taskak.first;
      }
    });
  }

  // Ezt a függvényt hívja meg a main.dart a nyíl ikonra kattintva
  void toggleNezet() {
    setState(() {
      _isTaskaNezet = !_isTaskaNezet;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
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

  Widget _buildListaOldal(int index) {
    List<FelszerelesTetel> mutathato;
    
    if (_isTaskaNezet) {
      if (_taskak.isEmpty) return const Center(child: Text('Nincsenek rögzített táskák.', style: TextStyle(color: Colors.white54)));
      String aktTaska = _taskak[index];
      mutathato = _tetelek.where((t) => t.taska == aktTaska).toList();
      
      mutathato.sort((a, b) {
        int pozCmp = (a.pozicio ?? '').compareTo(b.pozicio ?? '');
        if (pozCmp != 0) return pozCmp;
        return a.nev.compareTo(b.nev);
      });
    } else {
      if (_kategoriak.isEmpty) return const Center(child: Text('Nincsenek kategóriák. Hozz létre egyet!'));
      String aktKat = _kategoriak[index].id;
      mutathato = _tetelek.where((t) => t.kategoriaId == aktKat).toList();
      
      mutathato.sort((a, b) {
        String markaA = a.marka.trim().isEmpty ? '[N/A] - No Name' : a.marka.trim();
        String markaB = b.marka.trim().isEmpty ? '[N/A] - No Name' : b.marka.trim();
        int markaCmp = markaA.compareTo(markaB);
        if (markaCmp != 0) return markaCmp;
        return a.nev.compareTo(b.nev);
      });
    }

    if (mutathato.isEmpty) {
      return Center(child: Text('Ebben a ${_isTaskaNezet ? 'táskában' : 'kategóriában'} nincsenek tételek.', style: const TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: mutathato.length,
      itemBuilder: (context, idx) {
        final tetel = mutathato[idx];
        final markaNev = tetel.marka.trim().isEmpty ? '[N/A] - No Name' : tetel.marka;
        
        List<String> taskaPozicioReszek = [];
        if (tetel.taska != null && tetel.taska!.isNotEmpty) taskaPozicioReszek.add(tetel.taska!);
        if (tetel.pozicio != null && tetel.pozicio!.isNotEmpty) taskaPozicioReszek.add(tetel.pozicio!);
        final taskaPozicioSzoveg = taskaPozicioReszek.join(' - ');

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TetelReszletekScreen(tetel: tetel)),
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
                            Text(markaNev, style: const TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(tetel.nev, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            if (tetel.jellemzo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(tetel.jellemzo, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                            ],
                            
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    taskaPozicioSzoveg,
                                    style: const TextStyle(fontSize: 13, color: Colors.amber),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (tetel.mennyiseg != null || tetel.mertekegyseg.isNotEmpty)
                                  Text(
                                    '${tetel.mennyiseg != null ? tetel.mennyiseg!.toString().replaceAll('.0', '') : ''} ${tetel.mertekegyseg}'.trim(),
                                    style: const TextStyle(fontSize: 13, color: Colors.white54),
                                  ),
                              ],
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int oldalszam = _isTaskaNezet ? _taskak.length : _kategoriak.length;

    return Scaffold(
      // A belső (dupla) fejléc teljesen eltávolítva!
      body: Column(
        children: [
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
                
                if (_isTaskaNezet) {
                  nev = _taskak[index];
                  isSelected = nev == _kivalasztottTaska;
                } else {
                  nev = _kategoriak[index].nev;
                  isSelected = _kategoriak[index].id == _kivalasztottKategoriaId;
                }
                
                return GestureDetector(
                  onTap: () {
                    if (_pageController.hasClients) {
                      _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Colors.greenAccent : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      nev,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.greenAccent : Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: oldalszam == 0 
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

  const TetelReszletekScreen({super.key, required this.tetel});

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
    final markaNev = widget.tetel.marka.trim().isEmpty ? '[N/A] - No Name' : widget.tetel.marka;
    
    List<String> taskaPozicioReszek = [];
    if (widget.tetel.taska != null && widget.tetel.taska!.isNotEmpty) taskaPozicioReszek.add(widget.tetel.taska!);
    if (widget.tetel.pozicio != null && widget.tetel.pozicio!.isNotEmpty) taskaPozicioReszek.add(widget.tetel.pozicio!);
    final taskaPozicioSzoveg = taskaPozicioReszek.join(' - ');

    return Scaffold(
      appBar: AppBar(title: Text(widget.tetel.nev)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                  Text(markaNev, style: const TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.tetel.nev, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (widget.tetel.jellemzo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.tetel.jellemzo, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                  if (taskaPozicioSzoveg.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.business_center, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(taskaPozicioSzoveg, style: const TextStyle(fontSize: 16, color: Colors.amber))),
                      ],
                    )
                  ],
                  const Divider(color: Colors.white24, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mennyiség:', style: TextStyle(fontSize: 16, color: Colors.white54)),
                      Text(
                        '${widget.tetel.mennyiseg != null ? widget.tetel.mennyiseg!.toString().replaceAll('.0', '') : '-'} ${widget.tetel.mertekegyseg}'.trim(),
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
  final _mennyisegCtrl = TextEditingController();
  final _mertekegysegCtrl = TextEditingController();
  final _leirasCtrl = TextEditingController();
  final _pozicioCtrl = TextEditingController(); 
  
  String? _kivalasztottKategoriaId;
  String? _kivalasztottTaska; 
  List<String> _kepek = [];
  List<String> _elerhetoTaskak = []; 

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();

    _kivalasztottKategoriaId = widget.alapertelmezettKategoriaId;
    
    if (widget.szerkeszthetoTetel != null) {
      final t = widget.szerkeszthetoTetel!;
      _kivalasztottKategoriaId = t.kategoriaId;
      _markaCtrl.text = t.marka;
      _nevCtrl.text = t.nev;
      _jellemzoCtrl.text = t.jellemzo;
      if (t.mennyiseg != null) _mennyisegCtrl.text = t.mennyiseg.toString().replaceAll('.0', '');
      _mertekegysegCtrl.text = t.mertekegyseg;
      _leirasCtrl.text = t.leiras;
      _kepek = List.from(t.kepek);
      
      _kivalasztottTaska = t.taska;
      if (t.pozicio != null) _pozicioCtrl.text = t.pozicio!;
    } else if (widget.kategoriak.isNotEmpty && _kivalasztottKategoriaId == null) {
      _kivalasztottKategoriaId = widget.kategoriak.first.id;
    }
  }

  Future<void> _adatokBetoltese() async {
    final taskak = await AdatTarolo.taskakBetoltese();
    // Itt is kivettük a sort()-ot!
    setState(() {
      _elerhetoTaskak = taskak;
      if (_kivalasztottTaska != null && _kivalasztottTaska!.isNotEmpty && !_elerhetoTaskak.contains(_kivalasztottTaska)) {
        _kivalasztottTaska = null;
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
  
  void _ujTaskaHozzaadaskor() {
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
                setState(() => _kivalasztottTaska = nev);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mutasTaskaKereso() async {
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
                        _ujTaskaHozzaadaskor();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear, color: Colors.redAccent),
                      title: const Text('-- Nincs megadva --', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        setState(() => _kivalasztottTaska = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: szurt.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(szurt[index]),
                            onTap: () {
                              setState(() => _kivalasztottTaska = szurt[index]);
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

    final ujTetel = FelszerelesTetel(
      id: widget.szerkeszthetoTetel?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      kategoriaId: _kivalasztottKategoriaId!,
      marka: _markaCtrl.text.trim(),
      nev: _nevCtrl.text.trim(),
      jellemzo: _jellemzoCtrl.text.trim(),
      mennyiseg: double.tryParse(_mennyisegCtrl.text.replaceAll(',', '.')),
      mertekegyseg: _mertekegysegCtrl.text.trim(),
      leiras: _leirasCtrl.text.trim(),
      kepek: _kepek,
      taska: _kivalasztottTaska, 
      pozicio: _pozicioCtrl.text.trim(), 
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
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: TextField(controller: _mennyisegCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mennyiség', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _mertekegysegCtrl, decoration: const InputDecoration(labelText: 'Mértékegység (pl. db, csomag)', border: OutlineInputBorder()))),
              ],
            ),
            const Divider(height: 32, color: Colors.white24),

            const Text('Táska és Pozíció', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _mutasTaskaKereso,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Táska / Doboz (opcionális)', border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(_kivalasztottTaska ?? '-- Nincs megadva --', style: TextStyle(color: _kivalasztottTaska == null ? Colors.white54 : Colors.white))),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            TextField(controller: _pozicioCtrl, decoration: const InputDecoration(labelText: 'Pozíció / Rekesz (opcionális)', border: OutlineInputBorder())),
            const Divider(height: 32, color: Colors.white24),

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

// --- ÚJ: TÁSKÁK SZERKESZTÉSE KÉPERNYŐ (DRAG & DROP) ---
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
    bool vanBenneTetel = tet.any((t) => t.taska == _helyiTaskak[index]);

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
