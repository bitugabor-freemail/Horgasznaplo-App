import 'dart:io';
import 'dart:ui' as ui; 
import 'dart:typed_data'; 
import 'package:flutter/rendering.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart'; 
import 'adattarolo.dart';
import 'modellek.dart';
import 'fogasok.dart';
import 'vizjel_keszito.dart'; 

class TurakScreen extends StatefulWidget {
  const TurakScreen({super.key});

  @override
  State<TurakScreen> createState() => _TurakScreenState();
}

class _TurakScreenState extends State<TurakScreen> {
  List<Tura> _turak = [];
  List<FogasModel> _fogasok = [];
  List<Helyszin> _helyszinek = [];
  
  int? _kivEv = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final t = await AdatTarolo.turakBetoltese();
    final f = await AdatTarolo.fogasokBetoltese();
    final h = await AdatTarolo.helyszinekBetoltese();
    setState(() {
      _turak = t;
      _fogasok = f;
      _helyszinek = h;
    });
  }

  List<dynamic> _getEvekListaja() {
    Set<int> evek = {DateTime.now().year};
    for (var t in _turak) {
      evek.add(t.kezdoDatum.year);
    }
    List<int> rendezettEvek = evek.toList();
    rendezettEvek.sort((a, b) => b.compareTo(a));
    
    return [null, ...rendezettEvek];
  }

  List<Tura> _getSzurtTurak() {
    List<Tura> szurt;
    if (_kivEv == null) {
      szurt = List.from(_turak);
    } else {
      szurt = _turak.where((t) => t.kezdoDatum.year == _kivEv).toList();
    }
    szurt.sort((a, b) => b.kezdoDatum.compareTo(a.kezdoDatum));
    return szurt;
  }

  void _turaSzerkesztes([Tura? tura]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TuraSzerkesztoScreen(
          szerkeszthetoTura: tura,
          mentesCallback: () => _adatokBetoltese(),
        ),
      ),
    );
  }

  void _turaTorlese(Tura tura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Túra törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a túrát? A hozzá tartozó fogások is törlődnek!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              _turak.removeWhere((t) => t.id == tura.id);
              await AdatTarolo.turakMentes(_turak);
              
              final f = await AdatTarolo.fogasokBetoltese();
              f.removeWhere((fogas) => fogas.turaId == tura.id);
              await AdatTarolo.fogasokMentes(f);

              if (mounted) Navigator.pop(context);
              _adatokBetoltese();
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _megjegyzresMutatasa(BuildContext context, Tura tura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: const [
            Icon(Icons.note_alt, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Túra megjegyzése'),
          ],
        ),
        content: Text(
          tura.megjegyzes.isNotEmpty ? tura.megjegyzes : 'Ehhez a túrához nincs rögzített megjegyzés.',
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () => Navigator.pop(context),
            child: const Text('Bezár', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatisztika(String turaId) {
    final turaFogasai = _fogasok.where((f) => f.turaId == turaId).toList();
    int darab = turaFogasai.length;
    double osszsuly = 0;
    
    FogasModel? legnagyobbHal;

    for (var f in turaFogasai) {
      if (f.suly != null) {
        osszsuly += f.suly!;
        if (legnagyobbHal == null || (legnagyobbHal.suly ?? 0) < f.suly!) {
          legnagyobbHal = f;
        }
      }
    }
    double atlag = darab > 0 ? osszsuly / darab : 0;
    
    return {
      'darab': darab, 
      'osszsuly': osszsuly, 
      'atlag': atlag,
      'bigFishNev': legnagyobbHal?.halfaj,
      'bigFishSuly': legnagyobbHal?.suly
    };
  }

  @override
  Widget build(BuildContext context) {
    final evek = _getEvekListaja();
    final mutatottTurak = _getSzurtTurak();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161616),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Szűrés:', style: TextStyle(color: Colors.white70)),
                DropdownButton<int?>(
                  value: _kivEv,
                  dropdownColor: const Color(0xFF1E1E1E),
                  items: evek.map((e) {
                    return DropdownMenuItem<int?>(
                      value: e,
                      child: Text(
                        e == null ? 'Összes Túra' : '$e',
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _kivEv = val);
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: mutatottTurak.isEmpty
                ? const Center(child: Text('Nincs rögzített túra.\nKattints a + gombra!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100),
                    itemCount: mutatottTurak.length,
                    itemBuilder: (context, index) {
                      final tura = mutatottTurak[index];
                      final stat = _getStatisztika(tura.id);
                      final helyszinObj = _helyszinek.cast<Helyszin?>().firstWhere((h) => h?.id == tura.helyszinId, orElse: () => null);
                      
                      return _TuraKartya(
                        tura: tura,
                        stat: stat,
                        helyszinObj: helyszinObj,
                        onSzerkesztes: () => _turaSzerkesztes(tura),
                        onTorles: () => _turaTorlese(tura),
                        onMegjegyzes: () => _megjegyzresMutatasa(context, tura),
                        onFogasok: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FogasokScreen(tura: tura)),
                          ).then((_) => _adatokBetoltese());
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _turaSzerkesztes(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TuraKartya extends StatefulWidget {
  final Tura tura;
  final Map<String, dynamic> stat;
  final Helyszin? helyszinObj;
  final VoidCallback onSzerkesztes;
  final VoidCallback onTorles;
  final VoidCallback onMegjegyzes;
  final VoidCallback onFogasok;

  const _TuraKartya({
    required this.tura,
    required this.stat,
    required this.helyszinObj,
    required this.onSzerkesztes,
    required this.onTorles,
    required this.onMegjegyzes,
    required this.onFogasok,
  });

  @override
  State<_TuraKartya> createState() => _TuraKartyaState();
}

class _TuraKartyaState extends State<_TuraKartya> {
  final PageController _pageCtrl = PageController();

  void _teljesKepernyosGaleria(BuildContext context, int kezdoIndex, String helyszinNev, List<String> kepekLista) {
    int aktIndex = kezdoIndex;
    final PageController fullPageCtrl = PageController(initialPage: kezdoIndex);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setFullState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () {
                      VizjelKeszito.turaLetoltes(context, widget.tura, kepekLista[aktIndex], helyszinNev);
                    },
                  ),
                ],
              ),
              body: PageView.builder(
                controller: fullPageCtrl,
                itemCount: kepekLista.length,
                onPageChanged: (idx) => setFullState(() => aktIndex = idx),
                itemBuilder: (context, i) {
                  final utvonal = kepekLista[i];
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    clipBehavior: Clip.none,
                    child: Center(
                      child: utvonal.startsWith('http')
                          ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.contain)
                          : Image.file(File(utvonal), fit: BoxFit.contain),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tura = widget.tura;
    final stat = widget.stat;
    final helyszinNev = widget.helyszinObj?.nev ?? 'Ismeretlen helyszín';
    final vizterKod = widget.helyszinObj?.vizterKod;
    final vanMegjegyzes = tura.megjegyzes.isNotEmpty;

    final kezdo = DateTime(tura.kezdoDatum.year, tura.kezdoDatum.month, tura.kezdoDatum.day);
    final befejezo = DateTime(tura.befejezoDatum.year, tura.befejezoDatum.month, tura.befejezoDatum.day);
    final int diffDays = befejezo.difference(kezdo).inDays;
    final String extraNapok = diffDays > 0 ? ' (${diffDays + 1} nap)' : '';
    final String fejlecCim = '${DateFormat('yyyy.MM.dd.').format(tura.kezdoDatum)}$extraNapok';

    // Képek összevonása a kártya galériájához
    List<String> cardImages = [];
    if (tura.indexKep != null && (tura.indexKep!.startsWith('http') || File(tura.indexKep!).existsSync())) {
      cardImages.add(tura.indexKep!);
    }
    for (var k in tura.kepek) {
      if (!cardImages.contains(k) && (k.startsWith('http') || File(k).existsSync())) {
        cardImages.add(k);
      }
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.green[900]?.withOpacity(0.4),
            child: Text(
              fejlecCim,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
          ),
          
          if (cardImages.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: cardImages.length,
                      itemBuilder: (context, i) {
                        final utvonal = cardImages[i];
                        return GestureDetector(
                          onTap: () => _teljesKepernyosGaleria(context, i, helyszinNev, cardImages),
                          child: utvonal.startsWith('http')
                              ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.cover)
                              : Image.file(File(utvonal), fit: BoxFit.cover),
                        );
                      },
                    ),
                    if (cardImages.length > 1) ...[
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
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helyszinNev, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                if (vizterKod != null && vizterKod.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Víztérkód: $vizterKod', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                ],
                if (tura.horgaszhely.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Horgászhely: ${tura.horgaszhely}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                ],
                const Divider(height: 20, color: Colors.white12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatisztikaElem(cim: 'Darab', ertek: '${stat['darab']} db'),
                    _StatisztikaElem(cim: 'Összsúly', ertek: '${(stat['osszsuly'] as double).toStringAsFixed(1)} kg'),
                    _StatisztikaElem(cim: 'Átlag', ertek: '${(stat['atlag'] as double).toStringAsFixed(1)} kg'),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (stat['bigFishNev'] != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium, size: 18, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Big Fish: ${stat['bigFishNev']} (${stat['bigFishSuly']} kg)',
                          style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                if (tura.horgasztarsak.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.people, size: 18, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Társak: ${tura.horgasztarsak.join(', ')}',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 20, color: Colors.white12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Túra törlése',
                          onPressed: widget.onTorles,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                          tooltip: 'Túra szerkesztése',
                          onPressed: widget.onSzerkesztes,
                        ),
                        IconButton(
                          icon: Icon(
                            vanMegjegyzes ? Icons.note_alt : Icons.note_alt_outlined,
                            color: vanMegjegyzes ? Colors.greenAccent : Colors.white38,
                          ),
                          tooltip: vanMegjegyzes ? 'Megjegyzés megtekintése' : 'Nincs megjegyzés',
                          onPressed: widget.onMegjegyzes,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      onPressed: widget.onFogasok,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('FOGÁSOK', style: TextStyle(color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.phishing, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisztikaElem extends StatelessWidget {
  final String cim;
  final String ertek;
  const _StatisztikaElem({required this.cim, required this.ertek});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(cim, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 2),
        Text(ertek, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class TuraSzerkesztoScreen extends StatefulWidget {
  final Tura? szerkeszthetoTura;
  final VoidCallback mentesCallback;

  const TuraSzerkesztoScreen({super.key, this.szerkeszthetoTura, required this.mentesCallback});

  @override
  State<TuraSzerkesztoScreen> createState() => _TuraSzerkesztoScreenState();
}

class _TuraSzerkesztoScreenState extends State<TuraSzerkesztoScreen> {
  DateTime _kezdDatum = DateTime.now();
  DateTime _vegDatum = DateTime.now();
  String? _kivalasztottHelyszinId;
  final _horgaszhelyCtrl = TextEditingController();
  final _megjegyzesCtrl = TextEditingController();
  
  List<String> _kepek = []; 
  String? _indexKep; 

  List<String> _kivalasztottTarsak = [];
  List<Helyszin> _helyszinek = [];
  List<String> _elerhetoTarsak = [];

  bool _isThumbnailSzerkesztes = false;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _cropperKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();

    if (widget.szerkeszthetoTura != null) {
      final t = widget.szerkeszthetoTura!;
      _kezdDatum = t.kezdoDatum;
      _vegDatum = t.befejezoDatum;
      _kivalasztottHelyszinId = t.helyszinId;
      _horgaszhelyCtrl.text = t.horgaszhely;
      _kivalasztottTarsak = List.from(t.horgasztarsak);
      _megjegyzesCtrl.text = t.megjegyzes;
      _kepek = List.from(t.kepek);
      _indexKep = t.indexKep;
    }
  }

  @override
  void dispose() {
    _horgaszhelyCtrl.dispose();
    _megjegyzesCtrl.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _adatokBetoltese() async {
    _helyszinek = await AdatTarolo.helyszinekBetoltese();
    _helyszinek.sort((a, b) => a.nev.toLowerCase().compareTo(b.nev.toLowerCase()));
    
    _elerhetoTarsak = await AdatTarolo.tarsakBetoltese();
    _elerhetoTarsak.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    setState(() {});
  }

  void _ujHelyszinHozzaadaskor() {
    final nevCtrl = TextEditingController();
    final kodCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új helyszín hozzáadása'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nevCtrl, 
              autofocus: true, 
              textCapitalization: TextCapitalization.words, // <--- ÚJ: Szavankénti nagybetű (pl. Nagy Duna)
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(labelText: 'Helyszín neve *')
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kodCtrl, 
              textCapitalization: TextCapitalization.characters, // <--- ÚJ: Kódoknál mindent naggyal írjon
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(labelText: 'Víztér kód (opcionális)')
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (nevCtrl.text.trim().isNotEmpty) {
                final ujHelyszin = Helyszin(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nev: nevCtrl.text.trim(),
                  vizterKod: kodCtrl.text.trim(),
                );
                _helyszinek.add(ujHelyszin);
                _helyszinek.sort((a, b) => a.nev.toLowerCase().compareTo(b.nev.toLowerCase()));
                await AdatTarolo.helyszinekMentes(_helyszinek);
                setState(() {
                  _kivalasztottHelyszinId = ujHelyszin.id;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Hozzáadás', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ujTarsHozzaadaskor() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új horgásztárs hozzáadása'),
        content: TextField(
          controller: ctrl, 
          autofocus: true, 
          textCapitalization: TextCapitalization.words, // <--- ÚJ: Neveknél szavankénti nagybetű
          onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: const InputDecoration(labelText: 'Név')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                final nev = ctrl.text.trim();
                if (!_elerhetoTarsak.contains(nev)) {
                  _elerhetoTarsak.add(nev);
                  _elerhetoTarsak.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                  await AdatTarolo.tarsakMentes(_elerhetoTarsak);
                }
                if (!_kivalasztottTarsak.contains(nev)) {
                  _kivalasztottTarsak.add(nev);
                }
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Hozzáadás', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mutasHelyszinKereso() async {
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
            final szurt = _helyszinek.where((h) => h.nev.toLowerCase().contains(kereses.toLowerCase())).toList();
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Helyszín kiválasztása', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
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
                      title: const Text('Új helyszín hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        _ujHelyszinHozzaadaskor();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear, color: Colors.redAccent),
                      title: const Text('-- Nincs megadva --', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        setState(() => _kivalasztottHelyszinId = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: szurt.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(szurt[index].nev),
                            subtitle: (szurt[index].vizterKod != null && szurt[index].vizterKod!.isNotEmpty)
                                ? Text('Víztérkód: ${szurt[index].vizterKod}', style: const TextStyle(fontSize: 16, color: Colors.white70))
                                : null,
                            onTap: () {
                              setState(() => _kivalasztottHelyszinId = szurt[index].id);
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

  Future<void> _mutasTarsKereso() async {
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
            final szurt = _elerhetoTarsak.where((t) => t.toLowerCase().contains(kereses.toLowerCase())).toList();
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Horgásztárs kiválasztása', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
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
                      title: const Text('Új horgásztárs hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        _ujTarsHozzaadaskor();
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
                              if (!_kivalasztottTarsak.contains(szurt[index])) {
                                setState(() => _kivalasztottTarsak.add(szurt[index]));
                              }
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

  Future<void> _kepHozzaadasa() async {
    if (_kepek.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 10 képet adhatsz hozzá!')));
      return;
    }
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      int szabadHely = 10 - _kepek.length;
      int hozzaadandoSzam = images.length > szabadHely ? szabadHely : images.length;
      
      for (int i = 0; i < hozzaadandoSzam; i++) {
        String biztonsagosUtvonal = await AdatTarolo.biztonsagosKepMasolas(images[i].path);
        setState(() {
          _kepek.add(biztonsagosUtvonal);
          if (_kepek.length == 1 && _indexKep == null) {
            _indexKep = biztonsagosUtvonal;
          }
        });
      }
    }
  }

  Future<void> _thumbnailMentese() async {
    try {
      RenderRepaintBoundary? boundary = _cropperKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isThumbnailSzerkesztes = false);
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Nem sikerült a kép konvertálása.');
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final appDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${appDir.path}/kepek');
      if (!await thumbDir.exists()) await thumbDir.create(recursive: true);
      
      final thumbPath = '${thumbDir.path}/thumb_tura_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(thumbPath).writeAsBytes(pngBytes);

      setState(() {
        _indexKep = thumbPath;
        _isThumbnailSzerkesztes = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Túra borítókép sikeresen frissítve!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba a borítókép mentésekor: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _isThumbnailSzerkesztes = false);
      }
    }
  }

  Future<void> _mentes() async {
    if (widget.szerkeszthetoTura != null) {
      final osszesFogas = await AdatTarolo.fogasokBetoltese();
      final turaFogasai = osszesFogas.where((f) => f.turaId == widget.szerkeszthetoTura!.id).toList();
      
      DateTime tKezd = DateTime(_kezdDatum.year, _kezdDatum.month, _kezdDatum.day);
      DateTime tVeg = DateTime(_vegDatum.year, _vegDatum.month, _vegDatum.day);

      for (var f in turaFogasai) {
        DateTime fDatum = DateTime(f.datum.year, f.datum.month, f.datum.day);
        if (fDatum.isBefore(tKezd) || fDatum.isAfter(tVeg)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hiba: A túrához tartozik egy fogás (${DateFormat('yyyy.MM.dd').format(fDatum)}), ami kívül esne a megadott új dátumokon! Előbb módosítsd a fogást.'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
            )
          );
          return; 
        }
      }
    }

    final ujTura = Tura(
      id: widget.szerkeszthetoTura?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      kezdoDatum: _kezdDatum,
      befejezoDatum: _vegDatum,
      helyszinId: _kivalasztottHelyszinId,
      horgaszhely: _horgaszhelyCtrl.text.trim(),
      horgasztarsak: _kivalasztottTarsak,
      boritoKep: _kepek.isNotEmpty ? _kepek.first : null, 
      kepek: _kepek, 
      megjegyzes: _megjegyzesCtrl.text.trim(),
      indexKep: _indexKep, 
    );

    final turak = await AdatTarolo.turakBetoltese();
    if (widget.szerkeszthetoTura != null) {
      final idx = turak.indexWhere((t) => t.id == ujTura.id);
      if (idx != -1) turak[idx] = ujTura;
    } else {
      turak.add(ujTura);
    }

    await AdatTarolo.turakMentes(turak);
    widget.mentesCallback();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String? aktHelyszinNev = _kivalasztottHelyszinId == null 
        ? null 
        : _helyszinek.cast<Helyszin?>().firstWhere((h) => h?.id == _kivalasztottHelyszinId, orElse: () => null)?.nev;

    return Scaffold(
      appBar: AppBar(title: Text(widget.szerkeszthetoTura == null ? 'Új Túra Rögzítése' : 'Túra Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                    label: Text('Kezd: ${DateFormat('yyyy.MM.dd').format(_kezdDatum)}'),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: _kezdDatum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (p != null) {
                        setState(() {
                          final int kulonbseg = _vegDatum.difference(_kezdDatum).inDays;
                          _kezdDatum = p;
                          _vegDatum = _kezdDatum.add(Duration(days: kulonbseg));
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                    label: Text('Vége: ${DateFormat('yyyy.MM.dd').format(_vegDatum)}'),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: _vegDatum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (p != null) setState(() => _vegDatum = p);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _mutasHelyszinKereso,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Helyszín (Opcionális)', border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(aktHelyszinNev ?? '-- Nincs megadva --', style: TextStyle(color: aktHelyszinNev == null ? Colors.white54 : Colors.white))),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // <--- ÚJ: Horgászhely / Állás mező nagybetűsítése mondatonként
            TextField(
              controller: _horgaszhelyCtrl, 
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Horgászhely / Állás', border: OutlineInputBorder())
            ),
            const SizedBox(height: 20),

            const Text('Horgásztársak hozzáadása:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _mutasTarsKereso,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Válassz horgásztársat...', style: TextStyle(color: Colors.white54)),
                    Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            if (_kivalasztottTarsak.isNotEmpty) ...[
              const Text('Kiválasztott társak (kattintásra törölhető):', style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _kivalasztottTarsak.map((tars) {
                  return ActionChip(
                    backgroundColor: Colors.green[800],
                    label: Text(tars, style: const TextStyle(color: Colors.white)),
                    avatar: const Icon(Icons.close, size: 16, color: Colors.white70),
                    onPressed: () {
                      setState(() => _kivalasztottTarsak.remove(tars));
                    },
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 40, color: Colors.white24),

            const Text('Túra Borítókép (Thumbnail)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Állítsd be a borítóképet! Két ujjal nagyíthatod és mozgathatod a fotót a zöld kereten belül. A főképernyőn lévő listákban pontosan az a részlet fog megjelenni, amit most ebben a kockában látsz.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            
            Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent, width: 2), 
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), 
                  child: AspectRatio(
                    aspectRatio: 16 / 9, 
                    child: RepaintBoundary(
                      key: _cropperKey,
                      child: Container(
                        color: Colors.black, 
                        child: _isThumbnailSzerkesztes && _kepek.isNotEmpty
                            ? InteractiveViewer(
                                transformationController: _transformationController,
                                minScale: 1.0, 
                                maxScale: 4.0,
                                boundaryMargin: EdgeInsets.zero, 
                                clipBehavior: Clip.none, 
                                child: SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: _kepek.first.startsWith('http')
                                      ? CachedNetworkImage(imageUrl: _kepek.first, fit: BoxFit.contain)
                                      : Image.file(File(_kepek.first), fit: BoxFit.contain),
                                ),
                              )
                            : (_indexKep != null && (_indexKep!.startsWith('http') || File(_indexKep!).existsSync())
                                ? (_indexKep!.startsWith('http') ? CachedNetworkImage(imageUrl: _indexKep!, fit: BoxFit.cover) : Image.file(File(_indexKep!), fit: BoxFit.cover))
                                : (_kepek.isNotEmpty && (_kepek.first.startsWith('http') || File(_kepek.first).existsSync())
                                    ? (_kepek.first.startsWith('http') ? CachedNetworkImage(imageUrl: _kepek.first, fit: BoxFit.contain) : Image.file(File(_kepek.first), fit: BoxFit.contain))
                                    : const Icon(Icons.image, color: Colors.white24, size: 60))),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _isThumbnailSzerkesztes
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      onPressed: _thumbnailMentese,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('OK (Mentés)', style: TextStyle(color: Colors.white)),
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent)),
                      onPressed: () {
                        if (_kepek.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Előbb tölts fel legalább egy képet!')));
                          return;
                        }
                        setState(() => _isThumbnailSzerkesztes = true);
                      },
                      icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                      label: const Text('Borítókép Frissítése / Beállítása', style: TextStyle(color: Colors.greenAccent)),
                    ),
            ),

            const Divider(height: 40, color: Colors.white24),

            const Text('Túra fotók (Maximum 10 db - Húzd át a sorrendhez!)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 8),
            
            SizedBox(
              height: 100,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _kepek.removeAt(oldIndex);
                    _kepek.insert(newIndex, item);
                  });
                },
                children: [
                  for (int idx = 0; idx < _kepek.length; idx++)
                    Container(
                      key: ValueKey(_kepek[idx]),
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                            clipBehavior: Clip.antiAlias,
                            child: _kepek[idx].startsWith('http')
                                ? CachedNetworkImage(imageUrl: _kepek[idx], fit: BoxFit.cover)
                                : Image.file(File(_kepek[idx]), fit: BoxFit.cover),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _kepek.removeAt(idx)),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                              child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                            ),
                          ),
                          if (idx == 0)
                            Positioned(
                              bottom: 4, left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                child: const Text('thumbnail', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            )
                        ],
                      ),
                    ),
                  if (_kepek.length < 10)
                    GestureDetector(
                      key: const ValueKey('add_button'),
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
            ),
            const SizedBox(height: 16),

            // <--- ÚJ: Megjegyzés mező nagybetűsítése mondatonként
            TextField(
              controller: _megjegyzesCtrl, 
              maxLines: 3, 
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Megjegyzés', border: OutlineInputBorder())
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _mentes,
              child: const Text('TÚRA MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
