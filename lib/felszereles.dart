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
  String? _kivalasztottKategoriaId;

  @override
  void initState() {
    super.initState();
    adatokBetoltese();
  }

  Future<void> adatokBetoltese() async {
    final kat = await AdatTarolo.felszerelesKategoriakBetoltese();
    final tet = await AdatTarolo.felszerelesTetelekBetoltese();
    
    setState(() {
      _kategoriak = kat;
      _tetelek = tet;
      if (_kategoriak.isNotEmpty && _kivalasztottKategoriaId == null) {
        _kivalasztottKategoriaId = _kategoriak.first.id;
      }
    });
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

  List<FelszerelesTetel> _getSzurtEsRendezettTetelek() {
    if (_kivalasztottKategoriaId == null) return [];
    
    List<FelszerelesTetel> szurt = _tetelek.where((t) => t.kategoriaId == _kivalasztottKategoriaId).toList();
    
    szurt.sort((a, b) {
      String markaA = a.marka.trim().isEmpty ? '[N/A] - No Name' : a.marka.trim();
      String markaB = b.marka.trim().isEmpty ? '[N/A] - No Name' : b.marka.trim();
      
      int markaCmp = markaA.compareTo(markaB);
      if (markaCmp != 0) return markaCmp;
      return a.nev.compareTo(b.nev);
    });
    
    return szurt;
  }

  @override
  Widget build(BuildContext context) {
    final mutathatoTetelek = _getSzurtEsRendezettTetelek();

    return Scaffold(
      // Belső AppBar törölve, hogy ne duplázódjon a fejléc!
      body: Column(
        children: [
          Container(
            height: 50,
            color: const Color(0xFF161616),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _kategoriak.length,
              itemBuilder: (context, index) {
                final kategoria = _kategoriak[index];
                final isSelected = kategoria.id == _kivalasztottKategoriaId;
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _kivalasztottKategoriaId = kategoria.id);
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
                      kategoria.nev,
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
            child: _kategoriak.isEmpty
              ? const Center(child: Text('Nincsenek kategóriák. Hozz létre egyet!'))
              : mutathatoTetelek.isEmpty
                ? const Center(child: Text('Ebben a kategóriában nincsenek tételek.', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: mutathatoTetelek.length,
                    itemBuilder: (context, index) {
                      final tetel = mutathatoTetelek[index];
                      final markaNev = tetel.marka.trim().isEmpty ? '[N/A] - No Name' : tetel.marka;
                      
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
                                      // Jobb oldal és alja szabadon hagyva a fix gomboknak
                                      padding: const EdgeInsets.only(top: 12, bottom: 32, right: 40),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(markaNev, style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(tetel.nev, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                          if (tetel.jellemzo.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(tetel.jellemzo, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // 3 pontos menü szigorúan a jobb felső sarokban
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
                              // Mennyiség fixen a jobb alsó sarokban
                              if (tetel.mennyiseg != null || tetel.mertekegyseg.isNotEmpty)
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Text(
                                    '${tetel.mennyiseg != null ? tetel.mennyiseg!.toString().replaceAll('.0', '') : ''} ${tetel.mertekegyseg}'.trim(),
                                    style: const TextStyle(fontSize: 13, color: Colors.white54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
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

class TetelReszletekScreen extends StatelessWidget {
  final FelszerelesTetel tetel;

  const TetelReszletekScreen({super.key, required this.tetel});

  @override
  Widget build(BuildContext context) {
    final markaNev = tetel.marka.trim().isEmpty ? '[N/A] - No Name' : tetel.marka;

    return Scaffold(
      appBar: AppBar(title: Text(tetel.nev)),
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
                  Text(tetel.nev, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (tetel.jellemzo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(tetel.jellemzo, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                  const Divider(color: Colors.white24, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mennyiség:', style: TextStyle(fontSize: 16, color: Colors.white54)),
                      Text(
                        '${tetel.mennyiseg != null ? tetel.mennyiseg!.toString().replaceAll('.0', '') : '-'} ${tetel.mertekegyseg}'.trim(),
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (tetel.leiras.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leírás', style: TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(tetel.leiras, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                  ],
                ),
              ),
            ],

            if (tetel.kepek.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Fényképek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: tetel.kepek.length,
                  itemBuilder: (context, i) {
                    final utvonal = tetel.kepek[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (utvonal.startsWith('http'))
                          ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.cover)
                          : (File(utvonal).existsSync() ? Image.file(File(utvonal), fit: BoxFit.cover) : const Icon(Icons.broken_image)),
                      ),
                    );
                  },
                ),
              ),
              if (tetel.kepek.length > 1)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Lapozz a többi képért ↔', style: TextStyle(color: Colors.white38, fontSize: 12)),
                )),
            ],
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
  
  String? _kivalasztottKategoriaId;
  List<String> _kepek = [];

  @override
  void initState() {
    super.initState();
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
    } else if (widget.kategoriak.isNotEmpty && _kivalasztottKategoriaId == null) {
      _kivalasztottKategoriaId = widget.kategoriak.first.id;
    }
  }

  Future<void> _kepHozzaadasa() async {
    if (_kepek.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 3 képet adhatsz hozzá!')));
      return;
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String biztonsagosUtvonal = await AdatTarolo.biztonsagosKepMasolas(image.path);
      setState(() {
        _kepek.add(biztonsagosUtvonal);
      });
    }
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
            const SizedBox(height: 16),
            TextField(controller: _leirasCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Felszerelés leírása (opcionális)', border: OutlineInputBorder())),
            const SizedBox(height: 24),

            const Text('Fényképek (Maximum 3 db)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
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
                if (_kepek.length < 3)
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
