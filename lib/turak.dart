import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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

  void _teljesKepernyosKep(BuildContext context, Tura tura, String kepUtvonal, String helyszinNev) {
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
                onPressed: () {
                  VizjelKeszito.turaLetoltes(context, tura, kepUtvonal, helyszinNev);
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
                    padding: const EdgeInsets.all(12),
                    itemCount: mutatottTurak.length,
                    itemBuilder: (context, index) {
                      final tura = mutatottTurak[index];
                      final stat = _getStatisztika(tura.id);
                      final helyszinNev = _getHelyszinNeve(tura.helyszinId);
                      final vanMegjegyzes = tura.megjegyzes.isNotEmpty;

                      final kezdo = DateTime(tura.kezdoDatum.year, tura.kezdoDatum.month, tura.kezdoDatum.day);
                      final befejezo = DateTime(tura.befejezoDatum.year, tura.befejezoDatum.month, tura.befejezoDatum.day);
                      final int diffDays = befejezo.difference(kezdo).inDays;
                      final String extraNapok = diffDays > 0 ? ' (${diffDays + 1} nap)' : '';
                      final String fejlecCim = '${DateFormat('yyyy.MM.dd.').format(tura.kezdoDatum)}$extraNapok';

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
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.greenAccent
                                ),
                              ),
                            ),
                            
                            if (tura.boritoKep != null && File(tura.boritoKep!).existsSync())
                              GestureDetector(
                                onTap: () => _teljesKepernyosKep(context, tura, tura.boritoKep!, helyszinNev),
                                child: Image.file(File(tura.boritoKep!), height: 180, width: double.infinity, fit: BoxFit.cover),
                              ),

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
                                            onPressed: () => _turaTorlese(tura),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                            tooltip: 'Túra szerkesztése',
                                            onPressed: () => _turaSzerkesztes(tura),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              vanMegjegyzes ? Icons.note_alt : Icons.note_alt_outlined,
                                              color: vanMegjegyzes ? Colors.greenAccent : Colors.white38,
                                            ),
                                            tooltip: vanMegjegyzes ? 'Megjegyzés megtekintése' : 'Nincs megjegyzés',
                                            onPressed: () => _megjegyzresMutatasa(context, tura),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => FogasokScreen(tura: tura)),
                                          ).then((_) => _adatokBetoltese());
                                        },
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
  List<String> _elerhetoTarsak = [];

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
      _boritokepUtvonal = t.boritoKep;
    }
  }

  Future<void> _adatokBetoltese() async {
    _helyszinek = await AdatTarolo.helyszinekBetoltese();
    _elerhetoTarsak = await AdatTarolo.tarsakBetoltese();
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
            TextField(controller: nevCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Helyszín neve *')),
            const SizedBox(height: 12),
            TextField(controller: kodCtrl, decoration: const InputDecoration(labelText: 'Víztér kód (opcionális)')),
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

  Future<void> _mentes() async {
    final ujTura = Tura(
      id: widget.szerkeszthetoTura?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      kezdoDatum: _kezdDatum,
      befejezoDatum: _vegDatum,
      helyszinId: _kivalasztottHelyszinId,
      horgaszhely: _horgaszhelyCtrl.text.trim(),
      horgasztarsak: _kivalasztottTarsak,
      boritoKep: _boritokepUtvonal,
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

            DropdownButtonFormField<String?>(
              value: _kivalasztottHelyszinId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Helyszín (Opcionális)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('-- Nincs megadva --')),
                ..._helyszinek.map((h) => DropdownMenuItem<String?>(value: h.id, child: Text(h.nev))),
                const DropdownMenuItem<String?>(value: 'UJ_HELYSZIN', child: Text('➕ Új helyszín hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val == 'UJ_HELYSZIN') {
                  _ujHelyszinHozzaadaskor();
                } else {
                  setState(() => _kivalasztottHelyszinId = val);
                }
              },
            ),
            const SizedBox(height: 16),

            TextField(controller: _horgaszhelyCtrl, decoration: const InputDecoration(labelText: 'Horgászhely / Állás', border: OutlineInputBorder())),
            const SizedBox(height: 20),

            const Text('Horgásztársak hozzáadása:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: null,
                    isExpanded: true,
                    hint: const Text('Válassz horgásztársat...'),
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('-- Válassz társat --')),
                      ..._elerhetoTarsak.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))),
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

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(12)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Borítókép kiválasztása'),
              onPressed: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  // ITT TÖRTÉNIK A VARÁZSLAT: Biztonságos másolás
                  String biztonsagosUtvonal = await AdatTarolo.biztonsagosKepMasolas(image.path);
                  setState(() => _boritokepUtvonal = biztonsagosUtvonal);
                }
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
