import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'adattarolo.dart';
import 'modellek.dart';
import 'fogasok.dart';

class TurakScreen extends StatefulWidget {
  const TurakScreen({super.key});

  @override
  State<TurakScreen> createState() => _TurakScreenState();
}

class _TurakScreenState extends State<TurakScreen> {
  List<Tura> _osszesTura = [];
  List<FogasModel> _osszesFogas = [];
  List<Helyszin> _helyszinek = [];
  
  String _kivalasztottEv = DateTime.now().year.toString();
  List<String> _elerhetoEvek = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final turak = await AdatTarolo.turakBetoltese();
    final fogasok = await AdatTarolo.fogasokBetoltese();
    final helyszinek = await AdatTarolo.helyszinekBetoltese();

    // Elérhető évek kigyűjtése
    Set<String> evek = {DateTime.now().year.toString()};
    for (var t in turak) {
      evek.add(t.kezdoDatum.year.toString());
    }
    List<String> rendezettEvek = evek.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _osszesTura = turak;
      _osszesFogas = fogasok;
      _helyszinek = helyszinek;
      _elerhetoEvek = ['Összes', ...rendezettEvek];
    });
  }

  List<Tura> _getSzurtTurak() {
    List<Tura> szurt = _osszesTura.where((t) {
      if (_kivalasztottEv == 'Összes') return true;
      return t.kezdoDatum.year.toString() == _kivalasztottEv;
    }).toList();

    // Időben visszafelé rendezve
    szurt.sort((a, b) => b.kezdoDatum.compareTo(a.kezdoDatum));
    return szurt;
  }

  void _turaSzerkesztes(Tura? tura) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UjTuraScreen(
          szerkeszthetoTura: tura,
          mentesCallback: () => _adatokBetoltese(), // Frissítünk, ha végzett
        ),
      ),
    );
  }

  void _turaTorles(Tura tura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Túra törlése'),
        content: const Text('Biztosan törlöd ezt a túrát?\nFIGYELEM: A túrához tartozó összes fogás is törlődik!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              // Túra törlése
              _osszesTura.removeWhere((t) => t.id == tura.id);
              await AdatTarolo.turakMentes(_osszesTura);
              
              // Hozzá tartozó fogások törlése
              _osszesFogas.removeWhere((f) => f.turaId == tura.id);
              await AdatTarolo.fogasokMentes(_osszesFogas);

              if (mounted) Navigator.pop(context);
              _adatokBetoltese();
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _megjegyzesMegjelenitese(String megjegyzes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Túra Megjegyzés', style: TextStyle(color: Colors.greenAccent)),
        content: Text(megjegyzes, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bezárás', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _teljesKepernyosKep(String kepUtvonal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: 'Mentés vízjellel',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kép sikeresen letöltve vízjellel a Galériába! (Szimulálva)')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(kepUtvonal)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mutatottTurak = _getSzurtTurak();

    return Scaffold(
      body: Column(
        children: [
          // Év szűrő
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161616),
            child: DropdownButton<String>(
              value: _kivalasztottEv,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
              underline: const SizedBox(),
              items: _elerhetoEvek.map((ev) => DropdownMenuItem(value: ev, child: Text(ev == 'Összes' ? 'Összes Túra' : '$ev. év'))).toList(),
              onChanged: (val) => setState(() => _kivalasztottEv = val!),
            ),
          ),
          
          Expanded(
            child: mutatottTurak.isEmpty
                ? const Center(
                    child: Text('Nincs túra ebben az évben.\nKattints a + gombra egy új indításához!', 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: mutatottTurak.length,
                    itemBuilder: (context, index) {
                      final tura = mutatottTurak[index];
                      
                      // Helyszín keresése
                      String helyszinNev = 'Nincs helyszín megadva';
                      if (tura.helyszinId != null) {
                        final h = _helyszinek.where((x) => x.id == tura.helyszinId).toList();
                        if (h.isNotEmpty) helyszinNev = h.first.nev;
                      }

                      // Statisztika számítása ehhez a túrához
                      final turaFogasai = _osszesFogas.where((f) => f.turaId == tura.id).toList();
                      int darab = turaFogasai.length;
                      double osszsuly = turaFogasai.fold(0.0, (s, f) => s + (f.suly ?? 0.0));
                      double atlagsuly = darab > 0 ? osszsuly / darab : 0.0;
                      
                      FogasModel? bigFish;
                      if (darab > 0) {
                        bigFish = turaFogasai.reduce((a, b) => (a.suly ?? 0) > (b.suly ?? 0) ? a : b);
                      }

                      // Dátum felirat
                      String datumFelirat = DateFormat('yyyy.MM.dd.').format(tura.kezdoDatum);
                      int napok = tura.befejezoDatum.difference(tura.kezdoDatum).inDays + 1;
                      if (napok > 1) {
                        datumFelirat += ' ($napok nap)';
                      }

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // DÁTUM FEJLÉC
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.green[900]?.withOpacity(0.4),
                              child: Text(datumFelirat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            ),
                            
                            // BORÍTÓKÉP
                            if (tura.boritoKep != null && File(tura.boritoKep!).existsSync())
                              GestureDetector(
                                onTap: () => _teljesKepernyosKep(tura.boritoKep!),
                                child: Image.file(File(tura.boritoKep!), height: 200, fit: BoxFit.cover),
                              )
                            else
                              Container(height: 120, color: Colors.black26, child: const Icon(Icons.sailing, size: 50, color: Colors.white12)),
                            
                            // HELYSZÍN ÉS STATISZTIKA
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(helyszinNev, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                  if (tura.horgaszhely.isNotEmpty)
                                    Text(tura.horgaszhely, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                                  
                                  const Divider(height: 24, color: Colors.white24),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _StatMezo(cim: 'Darab', ertek: '$darab db'),
                                      _StatMezo(cim: 'Összsúly', ertek: '${osszsuly.toStringAsFixed(1)} kg'),
                                      _StatMezo(cim: 'Átlag', ertek: '${atlagsuly.toStringAsFixed(1)} kg'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  if (bigFish != null && bigFish.suly != null && bigFish.suly! > 0)
                                    Text('🏆 Big Fish: ${bigFish.halfaj} (${bigFish.suly} kg)', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                  
                                  if (tura.horgasztarsak.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text('👥 Társak: ${tura.horgasztarsak.join(', ')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ]
                                ],
                              ),
                            ),
                            
                            // AKCIÓSÁV
                            Container(
                              color: const Color(0xFF161616),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _turaTorles(tura)),
                                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white70), onPressed: () => _turaSzerkesztes(tura)),
                                      IconButton(
                                        icon: Icon(Icons.note_alt_outlined, color: tura.megjegyzes.isNotEmpty ? Colors.greenAccent : Colors.white38),
                                        onPressed: () {
                                          if (tura.megjegyzes.isNotEmpty) {
                                            _megjegyzesMegjelenitese(tura.megjegyzes);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nincs megjegyzés ehhez a túrához.')));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility, color: Colors.greenAccent),
                                    label: const Text('FOGÁSOK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => FogasokScreen(tura: tura)),
                                      ).then((_) => _adatokBetoltese()); // Visszatéréskor frissítjük a statisztikákat
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _turaSzerkesztes(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StatMezo extends StatelessWidget {
  final String cim;
  final String ertek;
  const _StatMezo({required this.cim, required this.ertek});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(cim, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(ertek, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ],
    );
  }
}

// ---- ÚJ TÚRA RÖGZÍTÉSE ŰRLAP ----
class UjTuraScreen extends StatefulWidget {
  final Tura? szerkeszthetoTura;
  final VoidCallback mentesCallback;

  const UjTuraScreen({super.key, this.szerkeszthetoTura, required this.mentesCallback});

  @override
  State<UjTuraScreen> createState() => _UjTuraScreenState();
}

class _UjTuraScreenState extends State<UjTuraScreen> {
  DateTime _kezdoDatum = DateTime.now();
  DateTime _befejezoDatum = DateTime.now();
  
  String? _kivalasztottHelyszinId;
  List<Helyszin> _helyszinek = [];
  
  List<String> _elerhetoTarsak = [];
  List<String> _kivalasztottTarsak = [];
  
  final _horgaszhelyCtrl = TextEditingController();
  final _megjegyzesCtrl = TextEditingController();
  String? _kepUtvonal;

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();

    if (widget.szerkeszthetoTura != null) {
      final t = widget.szerkeszthetoTura!;
      _kezdoDatum = t.kezdoDatum;
      _befejezoDatum = t.befejezoDatum;
      _kivalasztottHelyszinId = t.helyszinId;
      _horgaszhelyCtrl.text = t.horgaszhely;
      _kivalasztottTarsak = List.from(t.horgasztarsak);
      _megjegyzesCtrl.text = t.megjegyzes;
      _kepUtvonal = t.boritoKep;
    }
  }

  Future<void> _adatokBetoltese() async {
    final helyek = await AdatTarolo.helyszinekBetoltese();
    final tarsak = await AdatTarolo.tarsakBetoltese();
    setState(() {
      _helyszinek = helyek;
      _elerhetoTarsak = tarsak;
    });
  }

  void _ujHelyszinFelvitele() {
    final nevCtrl = TextEditingController();
    final kodCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új Helyszín hozzáadása'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nevCtrl, decoration: const InputDecoration(labelText: 'Helyszín neve *'), autofocus: true),
            TextField(controller: kodCtrl, decoration: const InputDecoration(labelText: 'Víztér kódja')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (nevCtrl.text.isNotEmpty) {
                final uj = Helyszin(id: DateTime.now().toString(), nev: nevCtrl.text.trim(), vizterKod: kodCtrl.text.trim());
                _helyszinek.add(uj);
                await AdatTarolo.helyszinekMentes(_helyszinek);
                setState(() => _kivalasztottHelyszinId = uj.id);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Hozzáadás', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ujTarsFelvitele() {
    final nevCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új Horgásztárs'),
        content: TextField(controller: nevCtrl, decoration: const InputDecoration(labelText: 'Társ neve'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (nevCtrl.text.isNotEmpty) {
                final nev = nevCtrl.text.trim();
                _elerhetoTarsak.add(nev);
                await AdatTarolo.tarsakMentes(_elerhetoTarsak);
                setState(() => _kivalasztottTarsak.add(nev));
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Hozzáadás', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mentes() async {
    final turaId = widget.szerkeszthetoTura?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final ujTura = Tura(
      id: turaId,
      kezdoDatum: _kezdoDatum,
      befejezoDatum: _befejezoDatum,
      helyszinId: _kivalasztottHelyszinId,
      horgaszhely: _horgaszhelyCtrl.text.trim(),
      horgasztarsak: _kivalasztottTarsak,
      boritoKep: _kepUtvonal,
      megjegyzes: _megjegyzesCtrl.text.trim(),
    );

    final osszes = await AdatTarolo.turakBetoltese();
    if (widget.szerkeszthetoTura != null) {
      final idx = osszes.indexWhere((t) => t.id == turaId);
      if (idx != -1) osszes[idx] = ujTura;
    } else {
      osszes.add(ujTura);
    }

    await AdatTarolo.turakMentes(osszes);
    widget.mentesCallback();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.szerkeszthetoTura == null ? 'Új Túra Rögzítése' : 'Túra Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DÁTUMOK
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, color: Colors.greenAccent),
                    label: Text('Kezd: ${DateFormat('yyyy.MM.dd').format(_kezdoDatum)}'),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: _kezdoDatum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (p != null) setState(() => _kezdoDatum = p);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_available, color: Colors.greenAccent),
                    label: Text('Vége: ${DateFormat('yyyy.MM.dd').format(_befejezoDatum)}'),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: _befejezoDatum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (p != null) setState(() => _befejezoDatum = p);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // HELYSZÍN
            DropdownButtonFormField<String>(
              value: _kivalasztottHelyszinId,
              decoration: const InputDecoration(labelText: 'Helyszín (Opcionális)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Nincs megadva --')),
                ..._helyszinek.map((h) => DropdownMenuItem(value: h.id, child: Text('${h.nev} ${h.vizterKod.isNotEmpty ? "(${h.vizterKod})" : ""}'))),
                const DropdownMenuItem(value: 'UJ', child: Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val == 'UJ') {
                  setState(() => _kivalasztottHelyszinId = _kivalasztottHelyszinId);
                  _ujHelyszinFelvitele();
                } else {
                  setState(() => _kivalasztottHelyszinId = val);
                }
              },
            ),
            const SizedBox(height: 16),

            TextField(controller: _horgaszhelyCtrl, decoration: const InputDecoration(labelText: 'Horgászhely / Állás', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            // TÁRSAK
            const Text('Horgásztársak:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                ..._elerhetoTarsak.map((t) {
                  final isSelected = _kivalasztottTarsak.contains(t);
                  return FilterChip(
                    label: Text(t),
                    selected: isSelected,
                    selectedColor: Colors.green[800],
                    onSelected: (selected) => setState(() => selected ? _kivalasztottTarsak.add(t) : _kivalasztottTarsak.remove(t)),
                  );
                }),
                ActionChip(
                  label: const Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent)),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onPressed: _ujTarsFelvitele,
                )
              ],
            ),
            const SizedBox(height: 16),

            // KÉP
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(12)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Borítókép kiválasztása'),
              onPressed: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) setState(() => _kepUtvonal = image.path);
              },
            ),
            if (_kepUtvonal != null) ...[
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_kepUtvonal!), height: 150, width: double.infinity, fit: BoxFit.cover)),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => _kepUtvonal = null)),
                ],
              )
            ],
            const SizedBox(height: 16),

            TextField(controller: _megjegyzesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Megjegyzés', border: OutlineInputBorder())),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _mentes,
              child: const Text('TÚRA MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
