import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'image_picker/image_picker.dart'; // Ha image_picker-t használsz, ez a standard importsor: 'package:image_picker/image_picker.dart';
import 'adattarolo.dart';
import 'modellek.dart';
import 'fogasok.dart';

// --- HOGY BIZTOSAN JÓ LEGYEN A KÉPKIVÁLASZTÓ IMPORT ---
// (Ha a fentivel hiba lenne, az alábbi standard image_picker importot használd a fájl tetején:)
// import 'package:image_picker/image_picker.dart';

class TurakScreen extends StatefulWidget {
  const TurakScreen({super.key});

  @override
  State<TurakScreen> createState() => _TurakScreenState();
}

class _TurakScreenState extends State<TurakScreen> {
  List<Tura> _turak = [];
  List<FogasModel> _fogasok = [];
  List<Helyszin> _helyszinek = [];
  int _kivEv = DateTime.now().year;

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

  List<int> _getEvekListaja() {
    Set<int> evek = {_kivEv};
    for (var t in _turak) {
      evek.add(t.kezdDatum.year);
    }
    List<int> lista = evek.toList();
    lista.sort((a, b) => b.compareTo(a));
    return lista;
  }

  List<Tura> _getSzurtTurak() {
    List<Tura> szurt = _turak.where((t) => t.kezdDatum.year == _kivEv).toList();
    szurt.sort((a, b) => b.kezdDatum.compareTo(a.kezdDatum)); // Legfrissebb elöl
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
              
              // Hozzá tartozó fogások törlése is
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

  String _getHelyszinNeve(String? helyszinId) {
    if (helyszinId == null) return 'Ismeretlen helyszín';
    final h = _helyszinek.where((x) => x.id == helyszinId).toList();
    if (h.isNotEmpty) return h.first.nev;
    return 'Ismeretlen helyszín';
  }

  Map<String, dynamic> _getStatisztika(String turaId) {
    final turaFogasai = _fogasok.where((f) => f.turaId == turaId).toList();
    int darab = turaFogasai.length;
    double osszsuly = 0;
    for (var f in turaFogasai) {
      if (f.suly != null) osszsuly += f.suly!;
    }
    double atlag = darab > 0 ? osszsuly / darab : 0;
    return {'darab': darab, 'osszsuly': osszsuly, 'atlag': atlag};
  }

  @override
  Widget build(BuildContext context) {
    final evek = _getEvekListaja();
    final mutatottTurak = _getSzurtTurak();

    return Scaffold(
      body: Column(
        children: [
          // ÉV SZŰRŐ SÁV
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161616),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Szűrés év szerint:', style: TextStyle(color: Colors.white70)),
                DropdownButton<int>(
                  value: _kivEv,
                  dropdownColor: const Color(0xFF1E1E1E),
                  items: evek.map((e) => DropdownMenuItem(value: e, child: Text('$e. év', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _kivEv = val); },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: mutatottTurak.isEmpty
                ? const Center(child: Text('Nincs rögzített túra ebben az évben.\nKattints a + gombra!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: mutatottTurak.length,
                    itemBuilder: (context, index) {
                      final tura = mutatottTurak[index];
                      final stat = _getStatisztika(tura.id);
                      final helyszinNev = _getHelyszinNeve(tura.helyszinId);

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dátum sáv felül
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: Colors.green[900]?.withOpacity(0.4),
                              child: Text(
                                '${DateFormat('yyyy.MM.dd.').format(tura.kezdDatum)} - ${DateFormat('yyyy.MM.dd.').format(tura.vegDatum)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                              ),
                            ),
                            
                            // Borítókép (ha van)
                            if (tura.boritokepUtvonal != null && File(tura.boritokepUtvonal!).existsSync())
                              Image.file(File(tura.boritokepUtvonal!), height: 180, width: double.infinity, fit: BoxFit.cover),

                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(helyszinNev, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (tura.horgaszhely.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(tura.horgaszhely, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                                  ],
                                  const Divider(height: 20, color: Colors.white12),
                                  
                                  // Statisztika sor
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _StatisztikaElem(cim: 'Darab', ertek: '${stat['darab']} db'),
                                      _StatisztikaElem(cim: 'Összsúly', ertek: '${(stat['osszsuly'] as double).toStringAsFixed(1)} kg'),
                                      _StatisztikaElem(cim: 'Átlag', ertek: '${(stat['atlag'] as double).toStringAsFixed(1)} kg'),
                                    ],
                                  ),
                                  
                                  // Horgásztársak (MEGNÖVELT BETŰMÉRET - 3. pont)
                                  if (tura.horgasztarsak.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 18, color: Colors.greenAccent),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Társak: ${tura.horgasztarsak.join(', ')}',
                                            style: const TextStyle(fontSize: 16, color: Colors.white), // Megnövelve!
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const Divider(height: 20, color: Colors.white12),

                                  // Gombok sávja
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _turaTorlese(tura)),
                                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white70), onPressed: () => _turaSzerkesztes(tura)),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                                        icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                                        label: const Text('FOGÁSOK', style: TextStyle(color: Colors.white)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => FogasokScreen(tura: tura)),
                                          ).then((_) => _adatokBetoltese());
                                        },
                                      ),
                                    ],
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
        onPressed: () => _turaSzerkesztes(),
        child: const Icon(Icons.add, color: Colors.white),
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

// --- TÚRA SZERKESZTŐ (Legördülő horgásztársak + Zöld címke törlés funkcióval - 2. pont) ---
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
  String? _boritokepUtvonal;

  List<String> _kivalasztottTarsak = [];
  List<Helyszin> _helyszinek = [];
  List<String> _elerhetoTarsak = []; // Törzsadatból betöltve

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();

    if (widget.szerkeszthetoTura != null) {
      final t = widget.szerkeszthetoTura!;
      _kezdDatum = t.kezdDatum;
      _vegDatum = t.vegDatum;
      _kivalasztottHelyszinId = t.helyszinId;
      _horgaszhelyCtrl.text = t.horgaszhely;
      _kivalasztottTarsak = List.from(t.horgasztarsak);
      _megjegyzesCtrl.text = t.megjegyzes;
      _boritokepUtvonal = t.boritokepUtvonal;
    }
  }

  Future<void> _adatokBetoltese() async {
    _helyszinek = await AdatTarolo.helyszinekBetoltese();
    _elerhetoTarsak = await AdatTarolo.horgasztarsakBetoltese();
    setState(() {});
  }

  void _ujTarsHozzaadaskor() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új horgásztárs hozzáadása'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Név')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                final nev = ctrl.text.trim();
                if (!_elerhetoTarsak.contains(nev)) {
                  _elerhetoTarsak.add(nev);
                  await AdatTarolo.horgasztarsakMentes(_elerhetoTarsak);
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

  Future<void> _mentes() async {
    final ujTura = Tura(
      id: widget.szerkeszthetoTura?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      kezdDatum: _kezdDatum,
      vegDatum: _vegDatum,
      helyszinId: _kivalasztottHelyszinId,
      horgaszhely: _horgaszhelyCtrl.text.trim(),
      horgasztarsak: _kivalasztottTarsak,
      boritokepUtvonal: _boritokepUtvonal,
      megjegyzes: _megjegyzesCtrl.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.szerkeszthetoTura == null ? 'Új Túra Rögzítése' : 'Túra Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dátumok sáv
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                    label: Text('Kezd: ${DateFormat('yyyy.MM.dd').format(_kezdDatum)}'),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: _kezdDatum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (p != null) setState(() => _kezdDatum = p);
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

            // Helyszín legördülő
            DropdownButtonFormField<String>(
              value: _kivalasztottHelyszinId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Helyszín (Opcionális)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Nincs megadva --')),
                ..._helyszinek.map((h) => DropdownMenuItem(value: h.id, child: Text(h.nev))),
              ],
              onChanged: (val) => setState(() => _kivalasztottHelyszinId = val),
            ),
            const SizedBox(height: 16),

            TextField(controller: _horgaszhelyCtrl, decoration: const InputDecoration(labelText: 'Horgászhely / Állás', border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // --- HORGÁSZTÁRSAK (Legördülő választás + zöld címkék törlés opcióval - 2. pont) ---
            const Text('Horgásztársak hozzáadása:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: null,
                    isExpanded: true,
                    hint: const Text('Válassz horgásztársat...'),
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: [
                      ..._elerhetoTarsak
                          .where((t) => !_kivalasztottTarsak.contains(t))
                          .map((t) => DropdownMenuItem(value: t, child: Text(t))),
                    ],
                    onChanged: (val) {
                      if (val != null && !_kivalasztottTarsak.contains(val)) {
                        setState(() => _kivalasztottTarsak.add(val));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Új', style: TextStyle(color: Colors.white)),
                  onPressed: _ujTarsHozzaadaskor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Kiválasztott társak zöld címkeként (Kattintásra eltűnnek!)
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
            const SizedBox(height: 20),

            // Borítókép
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(12)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Borítókép kiválasztása'),
              onPressed: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) setState(() => _boritokepUtvonal = image.path);
              },
            ),
            if (_boritokepUtvonal != null) ...[
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_boritokepUtvonal!), height: 150, width: double.infinity, fit: BoxFit.cover)),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => _boritokepUtvonal = null)),
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
