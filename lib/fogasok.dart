import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'adattarolo.dart';
import 'modellek.dart';
import 'torzsadatok.dart'; // A HalfajSzerkesztoScreen miatt

class FogasokScreen extends StatefulWidget {
  final Tura tura;

  const FogasokScreen({super.key, required this.tura});

  @override
  State<FogasokScreen> createState() => _FogasokScreenState();
}

class _FogasokScreenState extends State<FogasokScreen> {
  List<FogasModel> _osszesFogas = [];
  List<Helyszin> _helyszinek = []; // A túra helyszínének feloldásához

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final fogasok = await AdatTarolo.fogasokBetoltese();
    final helyek = await AdatTarolo.helyszinekBetoltese();
    setState(() {
      _osszesFogas = fogasok;
      _helyszinek = helyek;
    });
  }

  List<FogasModel> _getTuraFogasai() {
    List<FogasModel> szurt = _osszesFogas.where((f) => f.turaId == widget.tura.id).toList();
    
    // Időben visszafelé rendezve (Dátum + Időpont együttes vizsgálata)
    szurt.sort((a, b) {
      String aKomp = "${DateFormat('yyyy-MM-dd').format(a.datum)} ${a.idopontString}";
      String bKomp = "${DateFormat('yyyy-MM-dd').format(b.datum)} ${b.idopontString}";
      return bKomp.compareTo(aKomp);
    });
    return szurt;
  }

  void _ujFogas([FogasModel? szerkeszthetoFogas]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FogasSzerkesztoScreen(
          turaId: widget.tura.id,
          szerkeszthetoFogas: szerkeszthetoFogas,
          mentesCallback: () => _adatokBetoltese(),
        ),
      ),
    );
  }

  void _fogasTorlese(FogasModel fogas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Fogás törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a fogást?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              _osszesFogas.removeWhere((f) => f.id == fogas.id);
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

  Future<void> _kedvencValtas(FogasModel fogas) async {
    final idx = _osszesFogas.indexWhere((f) => f.id == fogas.id);
    if (idx != -1) {
      _osszesFogas[idx].isKedvenc = !_osszesFogas[idx].isKedvenc;
      await AdatTarolo.fogasokMentes(_osszesFogas);
      setState(() {});
    }
  }

  String _getTuraHelyszinNeve() {
    if (widget.tura.helyszinId != null) {
      final h = _helyszinek.where((x) => x.id == widget.tura.helyszinId).toList();
      if (h.isNotEmpty) return h.first.nev;
    }
    return 'Ismeretlen helyszín';
  }

  @override
  Widget build(BuildContext context) {
    final mutatottFogasok = _getTuraFogasai();

    return Scaffold(
      appBar: AppBar(title: const Text('Túra Fogásai')),
      body: mutatottFogasok.isEmpty
          ? const Center(child: Text('Még nincs rögzített fogás ezen a túrán.\nKattints a + gombra!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: mutatottFogasok.length,
              itemBuilder: (context, index) {
                final fogas = mutatottFogasok[index];
                
                // Színkódolás a kártya keretén
                Color keretSzin = Colors.transparent;
                if (fogas.sors == 'Elvittem') keretSzin = Colors.orangeAccent;
                if (fogas.sors == 'Elpusztult') keretSzin = Colors.redAccent;

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: keretSzin, width: keretSzin == Colors.transparent ? 0 : 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DÁTUM/IDŐ MINT CÍM LEGFELÜL
                        Text(
                          '${DateFormat('yyyy.MM.dd.').format(fogas.datum)} ${fogas.idopontString}',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        
                        // KÉP ÉS ADATOK
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kép miniatűr
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                              clipBehavior: Clip.antiAlias,
                              child: (fogas.kepUtvonal != null && File(fogas.kepUtvonal!).existsSync())
                                  ? Image.file(File(fogas.kepUtvonal!), fit: BoxFit.cover)
                                  : const Icon(Icons.set_meal, color: Colors.white24, size: 40),
                            ),
                            const SizedBox(width: 12),
                            // Fő adatok
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fogas.halfaj, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${fogas.suly != null ? "${fogas.suly} kg" : "- kg"} • ${fogas.hossz != null ? "${fogas.hossz} cm" : "- cm"}',
                                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white12),
                        
                        // AKCIÓSÁV
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _fogasTorlese(fogas)),
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white70), onPressed: () => _ujFogas(fogas)),
                                IconButton(
                                  icon: Icon(fogas.isKedvenc ? Icons.favorite : Icons.favorite_border, color: fogas.isKedvenc ? Colors.red : Colors.white70),
                                  onPressed: () => _kedvencValtas(fogas),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.greenAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FogasReszletekScreen(
                                      fogas: fogas,
                                      turaHelyszinNev: _getTuraHelyszinNeve(),
                                      turaHorgaszhely: widget.tura.horgaszhely,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _ujFogas(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---- FOGÁS SZERKESZTŐ ŰRLAP ----
class FogasSzerkesztoScreen extends StatefulWidget {
  final String turaId;
  final FogasModel? szerkeszthetoFogas;
  final VoidCallback mentesCallback;

  const FogasSzerkesztoScreen({super.key, required this.turaId, this.szerkeszthetoFogas, required this.mentesCallback});

  @override
  State<FogasSzerkesztoScreen> createState() => _FogasSzerkesztoScreenState();
}

class _FogasSzerkesztoScreenState extends State<FogasSzerkesztoScreen> {
  DateTime _datum = DateTime.now();
  TimeOfDay _idopont = TimeOfDay.now();

  String? _kivalasztottHalfaj;
  String _kivalasztottSors = 'Visszaengedtem';
  String? _kivalasztottBot, _kivalasztottModszer, _kivalasztottSzerelek, _kivalasztottIdojaras;
  
  List<String> _kivalasztottCsalik = [];
  List<String> _kivalasztottEtetoanyagok = [];

  final _sulyCtrl = TextEditingController();
  final _hosszCtrl = TextEditingController();
  final _etetesGyakCtrl = TextEditingController();
  final _homersekletCtrl = TextEditingController();
  final _megjegyzesCtrl = TextEditingController();
  String? _kepUtvonal;

  // Törzsadat listák
  List<Halfaj> _halfajok = [];
  List<String> _sorsok = [];
  List<String> _botok = [];
  List<String> _modszerek = [];
  List<String> _szerelekek = [];
  List<String> _csalik = [];
  List<String> _etetoanyagok = [];
  List<String> _idojarasok = [];

  @override
  void initState() {
    super.initState();
    _torzsadatokBetoltese();

    if (widget.szerkeszthetoFogas != null) {
      final f = widget.szerkeszthetoFogas!;
      _datum = f.datum;
      final tParts = f.idopontString.split(':');
      if (tParts.length == 2) _idopont = TimeOfDay(hour: int.parse(tParts[0]), minute: int.parse(tParts[1]));
      
      _kivalasztottHalfaj = f.halfaj;
      _kivalasztottSors = f.sors;
      _sulyCtrl.text = f.suly?.toString() ?? '';
      _hosszCtrl.text = f.hossz?.toString() ?? '';
      _kivalasztottCsalik = List.from(f.csali);
      _kivalasztottEtetoanyagok = List.from(f.etetoanyag);
      _etetesGyakCtrl.text = f.etetesGyakorisag;
      _kivalasztottBot = f.bot.isEmpty ? null : f.bot;
      _kivalasztottModszer = f.modszer.isEmpty ? null : f.modszer;
      _kivalasztottSzerelek = f.szerelek.isEmpty ? null : f.szerelek;
      _kivalasztottIdojaras = f.idojaras.isEmpty ? null : f.idojaras;
      _homersekletCtrl.text = f.homerseklet;
      _megjegyzesCtrl.text = f.megjegyzes;
      _kepUtvonal = f.kepUtvonal;
    }
  }

  Future<void> _torzsadatokBetoltese() async {
    _halfajok = await AdatTarolo.halfajokBetoltese();
    _sorsok = await AdatTarolo.sorsBetoltese();
    if (_sorsok.isEmpty) _sorsok = ['Visszaengedtem', 'Elvittem', 'Elpusztult'];
    
    _botok = await AdatTarolo.botokBetoltese();
    _modszerek = await AdatTarolo.modszerekBetoltese();
    _szerelekek = await AdatTarolo.szerelekekBetoltese();
    _csalik = await AdatTarolo.csalikBetoltese();
    _etetoanyagok = await AdatTarolo.etetoanyagokBetoltese();
    _idojarasok = await AdatTarolo.idojarasBetoltese();
    setState(() {});
  }

  // --- ÚJ TÖRZSDAT HOZZÁADÁSA MENET KÖZBEN ---
  void _ujSimaTorzsadat(String kategoria, Function(String) onHozzaadva) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Új $kategoria hozzáadása'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Megnevezés')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                final nev = ctrl.text.trim();
                onHozzaadva(nev);
                Navigator.pop(context);
              }
            },
            child: const Text('Hozzáadás', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mentes() async {
    if (_kivalasztottHalfaj == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A Halfaj kiválasztása kötelező!')));
      return;
    }

    final idopontStr = "${_idopont.hour.toString().padLeft(2, '0')}:${_idopont.minute.toString().padLeft(2, '0')}";
    final ujFogas = FogasModel(
      id: widget.szerkeszthetoFogas?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      turaId: widget.turaId,
      datum: _datum,
      idopontString: idopontStr,
      halfaj: _kivalasztottHalfaj!,
      suly: double.tryParse(_sulyCtrl.text.replaceAll(',', '.')),
      hossz: int.tryParse(_hosszCtrl.text),
      sors: _kivalasztottSors,
      csali: _kivalasztottCsalik,
      etetoanyag: _kivalasztottEtetoanyagok,
      etetesGyakorisag: _etetesGyakCtrl.text.trim(),
      bot: _kivalasztottBot ?? '',
      modszer: _kivalasztottModszer ?? '',
      szerelek: _kivalasztottSzerelek ?? '',
      idojaras: _kivalasztottIdojaras ?? '',
      homerseklet: _homersekletCtrl.text.trim(),
      kepUtvonal: _kepUtvonal,
      megjegyzes: _megjegyzesCtrl.text.trim(),
      isKedvenc: widget.szerkeszthetoFogas?.isKedvenc ?? false,
    );

    final osszesFogas = await AdatTarolo.fogasokBetoltese();
    if (widget.szerkeszthetoFogas != null) {
      final idx = osszesFogas.indexWhere((f) => f.id == ujFogas.id);
      if (idx != -1) osszesFogas[idx] = ujFogas;
    } else {
      osszesFogas.add(ujFogas);
    }

    await AdatTarolo.fogasokMentes(osszesFogas);
    widget.mentesCallback();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.szerkeszthetoFogas == null ? 'Új Fogás Rögzítése' : 'Fogás Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DÁTUM & IDŐ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                    label: Text(DateFormat('yyyy.MM.dd').format(_datum)),
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: _datum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (p != null) setState(() => _datum = p);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, color: Colors.greenAccent),
                    label: Text(_idopont.format(context)),
                    onPressed: () async {
                      final p = await showTimePicker(context: context, initialTime: _idopont);
                      if (p != null) setState(() => _idopont = p);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // HALFAJ (KÖTELEZŐ)
            DropdownButtonFormField<String>(
              value: _kivalasztottHalfaj,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Halfaj * (Kötelező)', border: OutlineInputBorder()),
              items: [
                ..._halfajok.map((h) => DropdownMenuItem(value: h.nev, child: Text(h.nev))),
                const DropdownMenuItem(value: 'UJ', child: Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val == 'UJ') {
                  setState(() => _kivalasztottHalfaj = _kivalasztottHalfaj); // Visszaállítjuk
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HalfajSzerkesztoScreen(
                    mentesCallback: (ujHal) async {
                      _halfajok.add(ujHal);
                      await AdatTarolo.halfajokMentes(_halfajok);
                      setState(() => _kivalasztottHalfaj = ujHal.nev);
                    }
                  )));
                } else {
                  setState(() => _kivalasztottHalfaj = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // SÚLY & HOSSZ
            Row(
              children: [
                Expanded(child: TextField(controller: _sulyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Súly (kg)', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _hosszCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hossz (cm)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),

            // HAL SORSA
            DropdownButtonFormField<String>(
              value: _kivalasztottSors,
              decoration: const InputDecoration(labelText: 'Hal sorsa', border: OutlineInputBorder()),
              items: _sorsok.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _kivalasztottSors = val!),
            ),
            const SizedBox(height: 24),

            // CSALI TÖBBSZÖRÖS VÁLASZTÓ
            const Text('Csali:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                ..._csalik.map((c) {
                  final isSelected = _kivalasztottCsalik.contains(c);
                  return FilterChip(
                    label: Text(c),
                    selected: isSelected,
                    selectedColor: Colors.green[800],
                    onSelected: (val) => setState(() => val ? _kivalasztottCsalik.add(c) : _kivalasztottCsalik.remove(c)),
                  );
                }),
                ActionChip(
                  label: const Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent)),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onPressed: () => _ujSimaTorzsadat('Csali', (nev) async {
                    _csalik.add(nev);
                    await AdatTarolo.csalikMentes(_csalik);
                    setState(() => _kivalasztottCsalik.add(nev));
                  }),
                )
              ],
            ),
            const SizedBox(height: 16),

            // ETETŐANYAG TÖBBSZÖRÖS VÁLASZTÓ
            const Text('Etetőanyag:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                ..._etetoanyagok.map((e) {
                  final isSelected = _kivalasztottEtetoanyagok.contains(e);
                  return FilterChip(
                    label: Text(e),
                    selected: isSelected,
                    selectedColor: Colors.green[800],
                    onSelected: (val) => setState(() => val ? _kivalasztottEtetoanyagok.add(e) : _kivalasztottEtetoanyagok.remove(e)),
                  );
                }),
                ActionChip(
                  label: const Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent)),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onPressed: () => _ujSimaTorzsadat('Etetőanyag', (nev) async {
                    _etetoanyagok.add(nev);
                    await AdatTarolo.etetoanyagokMentes(_etetoanyagok);
                    setState(() => _kivalasztottEtetoanyagok.add(nev));
                  }),
                )
              ],
            ),
            const SizedBox(height: 16),

            TextField(controller: _etetesGyakCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Etetés gyakorisága (perc)', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            // BOT, MÓDSZER, SZERELÉK (Legördülők új hozzáadásával)
            DropdownButtonFormField<String>(
              value: _kivalasztottBot,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Horgászbot', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Nincs megadva --')),
                ..._botok.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                const DropdownMenuItem(value: 'UJ', child: Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val == 'UJ') {
                  setState(() => _kivalasztottBot = _kivalasztottBot);
                  _ujSimaTorzsadat('Horgászbot', (nev) async { _botok.add(nev); await AdatTarolo.botokMentes(_botok); setState(() => _kivalasztottBot = nev); });
                } else { setState(() => _kivalasztottBot = val); }
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _kivalasztottModszer,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Horgászmódszer', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Nincs megadva --')),
                ..._modszerek.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                const DropdownMenuItem(value: 'UJ', child: Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val == 'UJ') {
                  setState(() => _kivalasztottModszer = _kivalasztottModszer);
                  _ujSimaTorzsadat('Horgászmódszer', (nev) async { _modszerek.add(nev); await AdatTarolo.modszerekMentes(_modszerek); setState(() => _kivalasztottModszer = nev); });
                } else { setState(() => _kivalasztottModszer = val); }
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _kivalasztottSzerelek,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Végszerelék', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Nincs megadva --')),
                ..._szerelekek.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                const DropdownMenuItem(value: 'UJ', child: Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val == 'UJ') {
                  setState(() => _kivalasztottSzerelek = _kivalasztottSzerelek);
                  _ujSimaTorzsadat('Végszerelék', (nev) async { _szerelekek.add(nev); await AdatTarolo.szerelekekMentes(_szerelekek); setState(() => _kivalasztottSzerelek = nev); });
                } else { setState(() => _kivalasztottSzerelek = val); }
              },
            ),
            const SizedBox(height: 16),

            // IDŐJÁRÁS (Nincs új hozzáadása a kérés szerint)
            DropdownButtonFormField<String>(
              value: _kivalasztottIdojaras,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Időjárás', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Nincs megadva --')),
                ..._idojarasok.map((i) => DropdownMenuItem(value: i, child: Text(i))),
              ],
              onChanged: (val) => setState(() => _kivalasztottIdojaras = val),
            ),
            const SizedBox(height: 16),

            // HŐMÉRSÉKLET + GPS GOMB
            Row(
              children: [
                Expanded(child: TextField(controller: _homersekletCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hőmérséklet (°C)', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _homersekletCtrl.text = "18"); // GPS Mock
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hőmérséklet lekérve (Szimulált)')));
                  },
                  icon: const Icon(Icons.cloud_sync, color: Colors.white),
                  label: const Text('Online'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KÉP
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(12)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Fotó kiválasztása'),
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
              child: const Text('FOGÁS MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- FOGÁS RÉSZLETES NÉZETE ----
class FogasReszletekScreen extends StatelessWidget {
  final FogasModel fogas;
  final String turaHelyszinNev;
  final String turaHorgaszhely;

  const FogasReszletekScreen({super.key, required this.fogas, required this.turaHelyszinNev, required this.turaHorgaszhely});

  void _teljesKepernyosKep(BuildContext context) {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kép letöltve a Galériába!\nVízjel: Helyszín, Dátum, Halfaj, Súly/Hossz')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(fogas.kepUtvonal!)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fogás Részletei')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dátum és Idő (Szigorú sorrend eleje)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${DateFormat('yyyy.MM.dd.').format(fogas.datum)} - ${fogas.idopontString}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ),
            ),
            
            // 2. Nagy, statikus fotó
            if (fogas.kepUtvonal != null && File(fogas.kepUtvonal!).existsSync())
              GestureDetector(
                onTap: () => _teljesKepernyosKep(context),
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(image: FileImage(File(fogas.kepUtvonal!)), fit: BoxFit.cover),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.zoom_out_map, color: Colors.white54)),
                  ),
                ),
              )
            else
              Container(width: double.infinity, height: 200, color: Colors.black26, child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white24)),

            // 3. Fő adatok (Helyszín, Halfaj, Méretek)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFF161616),
              child: Column(
                children: [
                  Text(turaHelyszinNev, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  if (turaHorgaszhely.isNotEmpty) Text(turaHorgaszhely, style: const TextStyle(fontSize: 14, color: Colors.white54, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Text(fogas.halfaj, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${fogas.suly != null ? "${fogas.suly} kg" : "-"}  |  ${fogas.hossz != null ? "${fogas.hossz} cm" : "-"}', style: const TextStyle(fontSize: 20, color: Colors.greenAccent)),
                ],
              ),
            ),

            // 4. Többi részletes adat
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _AdatSor(cim: 'Hal sorsa', ertek: fogas.sors),
                  const Divider(color: Colors.white24),
                  _AdatSor(cim: 'Csali', ertek: fogas.csali.isEmpty ? '-' : fogas.csali.join(', ')),
                  _AdatSor(cim: 'Etetőanyag', ertek: fogas.etetoanyag.isEmpty ? '-' : fogas.etetoanyag.join(', ')),
                  _AdatSor(cim: 'Etetés üteme', ertek: fogas.etetesGyakorisag.isEmpty ? '-' : '${fogas.etetesGyakorisag} perc'),
                  const Divider(color: Colors.white24),
                  _AdatSor(cim: 'Bot', ertek: fogas.bot.isEmpty ? '-' : fogas.bot),
                  _AdatSor(cim: 'Módszer', ertek: fogas.modszer.isEmpty ? '-' : fogas.modszer),
                  _AdatSor(cim: 'Szerelék', ertek: fogas.szerelek.isEmpty ? '-' : fogas.szerelek),
                  const Divider(color: Colors.white24),
                  _AdatSor(cim: 'Időjárás', ertek: fogas.idojaras.isEmpty ? '-' : fogas.idojaras),
                  _AdatSor(cim: 'Hőmérséklet', ertek: fogas.homerseklet.isEmpty ? '-' : '${fogas.homerseklet} °C'),
                ],
              ),
            ),

            // 5. Megjegyzés
            if (fogas.megjegyzes.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Megjegyzés', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    const SizedBox(height: 8),
                    Text(fogas.megjegyzes, style: const TextStyle(fontSize: 16, height: 1.4)),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AdatSor extends StatelessWidget {
  final String cim;
  final String ertek;
  const _AdatSor({required this.cim, required this.ertek});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(cim, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          Expanded(child: Text(ertek, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }
}
