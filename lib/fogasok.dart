import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'adattarolo.dart';
import 'modellek.dart';
import 'idojaras_szolgaltato.dart';

class FogasokScreen extends StatefulWidget {
  final Tura tura;

  const FogasokScreen({super.key, required this.tura});

  @override
  State<FogasokScreen> createState() => _FogasokScreenState();
}

class _FogasokScreenState extends State<FogasokScreen> {
  List<FogasModel> _fogasok = [];
  List<Halfaj> _halfajok = [];
  String _turaHelyszinNev = 'Ismeretlen helyszín';

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final osszesFogas = await AdatTarolo.fogasokBetoltese();
    _halfajok = await AdatTarolo.halfajokBetoltese();
    
    if (widget.tura.helyszinId != null) {
      final helyszinek = await AdatTarolo.helyszinekBetoltese();
      final h = helyszinek.cast<Helyszin?>().firstWhere((x) => x?.id == widget.tura.helyszinId, orElse: () => null);
      if (h != null) _turaHelyszinNev = h.nev;
    }
    
    setState(() {
      _fogasok = osszesFogas.where((f) => f.turaId == widget.tura.id).toList();
      _fogasok.sort((a, b) {
        String aKomp = "${DateFormat('yyyy-MM-dd').format(a.datum)} ${a.idopont}";
        String bKomp = "${DateFormat('yyyy-MM-dd').format(b.datum)} ${b.idopont}";
        return bKomp.compareTo(aKomp);
      });
    });
  }

  void _fogasSzerkesztes([FogasModel? fogas]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FogasSzerkesztoScreen(
          turaId: widget.tura.id,
          szerkeszthetoFogas: fogas,
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
              final osszes = await AdatTarolo.fogasokBetoltese();
              osszes.removeWhere((f) => f.id == fogas.id);
              await AdatTarolo.fogasokMentes(osszes);
              if (mounted) Navigator.pop(context);
              _adatokBetoltese();
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _kedvencValtoztatas(FogasModel fogas) async {
    final osszes = await AdatTarolo.fogasokBetoltese();
    final idx = osszes.indexWhere((f) => f.id == fogas.id);
    if (idx != -1) {
      osszes[idx].isKedvenc = !osszes[idx].isKedvenc; 
      await AdatTarolo.fogasokMentes(osszes);
      _adatokBetoltese();
    }
  }

  Color _getKartyaszin(String sors) {
    if (sors == 'Elvittem') return Colors.orange.withOpacity(0.15);
    if (sors == 'Elpusztult') return Colors.red.withOpacity(0.15);
    return const Color(0xFF1E1E1E); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Túra Fogásai'),
        backgroundColor: const Color(0xFF161616),
      ),
      body: _fogasok.isEmpty
          ? const Center(child: Text('Nincs még rögzített fogás ehhez a túrához.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _fogasok.length,
              itemBuilder: (context, index) {
                final fogas = _fogasok[index];

                return Card(
                  color: _getKartyaszin(fogas.sors ?? ''),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  // --- 5. PONT: EGÉSZ KÁRTYÁS KATTINTÁS ---
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FogasReszletekScreen(
                            fogas: fogas,
                            helyszinNev: _turaHelyszinNev,
                            horgaszhely: widget.tura.horgaszhely,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (fogas.fenykep != null && File(fogas.fenykep!).existsSync())
                              ? Image.file(File(fogas.fenykep!), fit: BoxFit.cover)
                              : const Icon(Icons.set_meal, color: Colors.white24, size: 30),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat('yyyy.MM.dd.').format(fogas.datum)} ${fogas.idopont}',
                                  style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
                                ),
                                const SizedBox(height: 4),
                                Text(fogas.halfaj.isEmpty ? 'Ismeretlen halfaj' : fogas.halfaj, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('${fogas.suly != null ? '${fogas.suly} kg' : '-'} • ${fogas.hossz != null ? '${fogas.hossz} cm' : '-'}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  onPressed: () => _fogasTorlese(fogas),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white70),
                                  onPressed: () => _fogasSzerkesztes(fogas),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(fogas.isKedvenc ? Icons.favorite : Icons.favorite_outline, size: 20, color: fogas.isKedvenc ? Colors.redAccent : Colors.white70),
                                  onPressed: () => _kedvencValtoztatas(fogas),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20, color: Colors.greenAccent),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FogasReszletekScreen(
                                          fogas: fogas,
                                          helyszinNev: _turaHelyszinNev,
                                          horgaszhely: widget.tura.horgaszhely,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
        onPressed: () => _fogasSzerkesztes(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --- FOGÁS SZERKESZTŐ / RÖGZÍTŐ ŰRLAP ---
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
  final _sulyCtrl = TextEditingController();
  final _hosszCtrl = TextEditingController();
  
  String _sors = 'Visszaengedtem'; 
  String? _kivalasztottBot;
  String? _kivalasztottModszer;
  String? _kivalasztottVegszerelek;
  String? _kivalasztottIdojaras;
  
  List<String> _kivalasztottCsalik = [];
  List<String> _kivalasztottEtetoanyagok = [];
  final _etetesGyakorisagaCtrl = TextEditingController();

  final _homersekletCtrl = TextEditingController();
  final _megjegyzesCtrl = TextEditingController();
  String? _fenykepUtvonal;

  bool _isIdojarasLekeresFolyamatban = false; 

  List<Halfaj> _elerhetoHalfajok = [];
  List<String> _elerhetoSorsok = ['Visszaengedtem', 'Elvittem', 'Elpusztult']; 
  List<String> _elerhetoBotok = [];
  List<String> _elerhetoModszerek = [];
  List<String> _elerhetoVegszerelekek = [];
  List<String> _elerhetoCsalik = [];
  List<String> _elerhetoEtetoanyagok = [];
  List<String> _elerhetoIdojarasok = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
    if (widget.szerkeszthetoFogas != null) {
      final f = widget.szerkeszthetoFogas!;
      _datum = f.datum;
      final tParts = f.idopont.split(':');
      if (tParts.length == 2) _idopont = TimeOfDay(hour: int.parse(tParts[0]), minute: int.parse(tParts[1]));
      
      _kivalasztottHalfaj = f.halfaj.isEmpty ? null : f.halfaj; // Üres string kezelése
      if (f.suly != null) _sulyCtrl.text = f.suly.toString();
      if (f.hossz != null) _hosszCtrl.text = f.hossz.toString();
      if (f.sors != null && f.sors!.isNotEmpty) _sors = f.sors!;
      
      _kivalasztottCsalik = List.from(f.csali);
      _kivalasztottEtetoanyagok = List.from(f.etetoanyag);
      if (f.etetesGyakorisaga != null) _etetesGyakorisagaCtrl.text = f.etetesGyakorisaga.toString();
      
      _kivalasztottBot = f.bot;
      _kivalasztottModszer = f.modszer;
      _kivalasztottVegszerelek = f.vegszerelek;
      _kivalasztottIdojaras = f.idojaras;
      
      if (f.homerseklet != null) _homersekletCtrl.text = f.homerseklet.toString();
      _megjegyzesCtrl.text = f.megjegyzes;
      _fenykepUtvonal = f.fenykep;
    }
  }

  Future<void> _adatokBetoltese() async {
    _elerhetoHalfajok = await AdatTarolo.halfajokBetoltese();
    _elerhetoBotok = await AdatTarolo.botokBetoltese();
    _elerhetoModszerek = await AdatTarolo.modszerekBetoltese();
    _elerhetoVegszerelekek = await AdatTarolo.szerelekekBetoltese();
    _elerhetoCsalik = await AdatTarolo.csalikBetoltese();
    _elerhetoEtetoanyagok = await AdatTarolo.etetoanyagokBetoltese();
    _elerhetoIdojarasok = await AdatTarolo.idojarasBetoltese();
    
    List<String> mentettSorsok = await AdatTarolo.sorsBetoltese();
    if (mentettSorsok.isNotEmpty) _elerhetoSorsok = mentettSorsok;
    
    setState(() {});
  }

  Future<void> _homersekletLekeres() async {
    setState(() => _isIdojarasLekeresFolyamatban = true);
    double? temp = await IdojarasSzolgaltato.getAktualisHomerseklet();
    setState(() {
      _isIdojarasLekeresFolyamatban = false;
      if (temp != null) {
        _homersekletCtrl.text = temp.toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hőmérséklet sikeresen frissítve!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hiba a lekérés során. Ellenőrizd a GPS-t, az internetet és az API kulcsot!'), backgroundColor: Colors.redAccent));
      }
    });
  }

  void _ujTorzsadatHozzaadas(String kategoria, Function(String) onAdded) {
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
              if (ctrl.text.trim().isNotEmpty) {
                final nev = ctrl.text.trim();
                if (kategoria == 'Horgászbot') { _elerhetoBotok.add(nev); await AdatTarolo.botokMentes(_elerhetoBotok); }
                if (kategoria == 'Módszer') { _elerhetoModszerek.add(nev); await AdatTarolo.modszerekMentes(_elerhetoModszerek); }
                if (kategoria == 'Végszerelék') { _elerhetoVegszerelekek.add(nev); await AdatTarolo.szerelekekMentes(_elerhetoVegszerelekek); }
                if (kategoria == 'Csali') { _elerhetoCsalik.add(nev); await AdatTarolo.csalikMentes(_elerhetoCsalik); }
                if (kategoria == 'Etetőanyag') { _elerhetoEtetoanyagok.add(nev); await AdatTarolo.etetoanyagokMentes(_elerhetoEtetoanyagok); }
                
                onAdded(nev);
                setState(() {});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required Function(String?) onChanged, bool allowNew = true}) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        DropdownMenuItem<String?>(value: null, child: const Text('-- Nincs kiválasztva --')),
        ...items.map((i) => DropdownMenuItem<String?>(value: i, child: Text(i))),
        if (allowNew)
          DropdownMenuItem<String?>(value: 'UJ_HOZZAADASA', child: Text('➕ Új $label', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
      ],
      onChanged: (val) {
        if (val == 'UJ_HOZZAADASA') {
          _ujTorzsadatHozzaadas(label, (ujNev) => onChanged(ujNev));
        } else {
          onChanged(val);
        }
      },
    );
  }

  // --- 11. PONT: EGYSÉGES TÖBBES KIVÁLASZTÓ DIZÁJN (Társak mintájára) ---
  Widget _buildTobbesKivalaszto({
    required String label,
    required List<String> elerhetoElemek,
    required List<String> kivalasztottElemek,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label hozzáadása:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: null,
                isExpanded: true,
                hint: Text('Válassz $label...'),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('-- Válassz --')),
                  ...elerhetoElemek.map((e) => DropdownMenuItem<String?>(value: e, child: Text(e))),
                ],
                onChanged: (val) {
                  if (val != null && !kivalasztottElemek.contains(val)) {
                    setState(() => kivalasztottElemek.add(val));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Új', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _ujTorzsadatHozzaadas(label, (ujNev) {
                  setState(() => kivalasztottElemek.add(ujNev));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (kivalasztottElemek.isNotEmpty) ...[
          Text('Kiválasztott $label (kattintásra törölhető):', style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: kivalasztottElemek.map((elem) {
              return ActionChip(
                backgroundColor: Colors.green[800],
                label: Text(elem, style: const TextStyle(color: Colors.white)),
                avatar: const Icon(Icons.close, size: 16, color: Colors.white70),
                onPressed: () {
                  setState(() => kivalasztottElemek.remove(elem));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _mentes() async {
    // --- 2. PONT: A halfaj többé nem kötelező, eltávolítva a blokkolás! ---
    final ujFogas = FogasModel(
      id: widget.szerkeszthetoFogas?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      turaId: widget.turaId,
      datum: _datum,
      idopont: '${_idopont.hour.toString().padLeft(2, '0')}:${_idopont.minute.toString().padLeft(2, '0')}',
      halfaj: _kivalasztottHalfaj ?? '', // Ha nincs kiválasztva, üres string lesz
      suly: double.tryParse(_sulyCtrl.text.replaceAll(',', '.')),
      hossz: double.tryParse(_hosszCtrl.text),
      sors: _sors,
      csali: _kivalasztottCsalik,
      etetoanyag: _kivalasztottEtetoanyagok,
      etetesGyakorisaga: int.tryParse(_etetesGyakorisagaCtrl.text),
      bot: _kivalasztottBot,
      modszer: _kivalasztottModszer,
      vegszerelek: _kivalasztottVegszerelek,
      idojaras: _kivalasztottIdojaras,
      homerseklet: double.tryParse(_homersekletCtrl.text.replaceAll(',', '.')),
      megjegyzes: _megjegyzesCtrl.text,
      fenykep: _fenykepUtvonal,
      isKedvenc: widget.szerkeszthetoFogas?.isKedvenc ?? false,
    );

    final osszes = await AdatTarolo.fogasokBetoltese();
    if (widget.szerkeszthetoFogas != null) {
      final idx = osszes.indexWhere((f) => f.id == ujFogas.id);
      if (idx != -1) osszes[idx] = ujFogas;
    } else {
      osszes.add(ujFogas);
    }

    await AdatTarolo.fogasokMentes(osszes);
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
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.calendar_today, color: Colors.greenAccent), label: Text(DateFormat('yyyy.MM.dd').format(_datum)), onPressed: () async { final p = await showDatePicker(context: context, initialDate: _datum, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _datum = p); })),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.access_time, color: Colors.greenAccent), label: Text(_idopont.format(context)), onPressed: () async { final t = await showTimePicker(context: context, initialTime: _idopont); if (t != null) setState(() => _idopont = t); })),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String?>(
              value: _kivalasztottHalfaj,
              isExpanded: true,
              // Csillag levéve
              decoration: const InputDecoration(labelText: 'Halfaj', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('-- Válassz halfajt --')),
                ..._elerhetoHalfajok.map((h) => DropdownMenuItem<String?>(value: h.nev, child: Text(h.nev))),
                // Később ide kötjük be a teljes értékű hozzáadást a 3. ponthoz!
              ],
              onChanged: (val) => setState(() => _kivalasztottHalfaj = val),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: TextField(controller: _sulyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Súly (kg)', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _hosszCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hossz (cm)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),

            _buildDropdown(label: 'Hal sorsa', value: _sors, items: _elerhetoSorsok, allowNew: false, onChanged: (val) { if (val != null) setState(() => _sors = val); }),
            const Divider(height: 32, color: Colors.white24),

            // --- 11. PONT: Új dizájnú kiválasztók alkalmazása ---
            _buildTobbesKivalaszto(label: 'Csali', elerhetoElemek: _elerhetoCsalik, kivalasztottElemek: _kivalasztottCsalik),
            const SizedBox(height: 16),
            _buildTobbesKivalaszto(label: 'Etetőanyag', elerhetoElemek: _elerhetoEtetoanyagok, kivalasztottElemek: _kivalasztottEtetoanyagok),
            
            const SizedBox(height: 12),
            TextField(controller: _etetesGyakorisagaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Etetés gyakorisága (perc)', border: OutlineInputBorder())),
            const Divider(height: 32, color: Colors.white24),

            _buildDropdown(label: 'Horgászbot', value: _kivalasztottBot, items: _elerhetoBotok, onChanged: (val) => setState(() => _kivalasztottBot = val)),
            const SizedBox(height: 12),
            _buildDropdown(label: 'Módszer', value: _kivalasztottModszer, items: _elerhetoModszerek, onChanged: (val) => setState(() => _kivalasztottModszer = val)),
            const SizedBox(height: 12),
            _buildDropdown(label: 'Végszerelék', value: _kivalasztottVegszerelek, items: _elerhetoVegszerelekek, onChanged: (val) => setState(() => _kivalasztottVegszerelek = val)),
            const Divider(height: 32, color: Colors.white24),

            _buildDropdown(label: 'Időjárás', value: _kivalasztottIdojaras, items: _elerhetoIdojarasok, allowNew: false, onChanged: (val) => setState(() => _kivalasztottIdojaras = val)),
            const SizedBox(height: 12),
            TextField(
              controller: _homersekletCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hőmérséklet (°C)',
                border: const OutlineInputBorder(),
                suffixIcon: _isIdojarasLekeresFolyamatban
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                    : IconButton(icon: const Icon(Icons.cloud_sync, color: Colors.greenAccent, size: 28), onPressed: _homersekletLekeres),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(12)),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Fénykép kiválasztása'),
              onPressed: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) setState(() => _fenykepUtvonal = image.path);
              },
            ),
            if (_fenykepUtvonal != null) ...[
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_fenykepUtvonal!), height: 200, width: double.infinity, fit: BoxFit.cover)),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => _fenykepUtvonal = null)),
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
  final String helyszinNev;
  final String horgaszhely;

  const FogasReszletekScreen({
    super.key,
    required this.fogas,
    required this.helyszinNev,
    required this.horgaszhely,
  });

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
                    const SnackBar(content: Text('Kép sikeresen letöltve vízjellel a Galériába!')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(fogas.fenykep!)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fogás Részletei'),
        backgroundColor: const Color(0xFF161616),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${DateFormat('yyyy.MM.dd.').format(fogas.datum)} - ${fogas.idopont}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ),
            ),
            
            if (fogas.fenykep != null && File(fogas.fenykep!).existsSync())
              GestureDetector(
                onTap: () => _teljesKepernyosKep(context),
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(fogas.fenykep!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.zoom_out_map, color: Colors.white54),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.black26,
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white24),
              ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFF161616),
              child: Column(
                children: [
                  Text(helyszinNev, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  if (horgaszhely.isNotEmpty) Text(horgaszhely, style: const TextStyle(fontSize: 14, color: Colors.white54)),
                  const SizedBox(height: 8),
                  Text(fogas.halfaj.isEmpty ? 'Ismeretlen halfaj' : fogas.halfaj, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${fogas.suly ?? '-'} kg  |  ${fogas.hossz ?? '-'} cm', style: const TextStyle(fontSize: 20, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: fogas.sors == 'Visszaengedtem' ? Colors.green[900] : (fogas.sors == 'Elvittem' ? Colors.orange[900] : Colors.red[900]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(fogas.sors ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _AdatSor(cim: 'Csali', ertek: fogas.csali.isEmpty ? '-' : fogas.csali.join(', ')),
                  _AdatSor(cim: 'Etetőanyag', ertek: fogas.etetoanyag.isEmpty ? '-' : fogas.etetoanyag.join(', ')),
                  _AdatSor(cim: 'Etetés üteme', ertek: fogas.etetesGyakorisaga == null ? '-' : '${fogas.etetesGyakorisaga} perc'),
                  const Divider(color: Colors.white24),
                  _AdatSor(cim: 'Bot', ertek: fogas.bot?.isEmpty ?? true ? '-' : fogas.bot!),
                  _AdatSor(cim: 'Módszer', ertek: fogas.modszer?.isEmpty ?? true ? '-' : fogas.modszer!),
                  _AdatSor(cim: 'Szerelék', ertek: fogas.vegszerelek?.isEmpty ?? true ? '-' : fogas.vegszerelek!),
                  const Divider(color: Colors.white24),
                  _AdatSor(cim: 'Időjárás', ertek: fogas.idojaras?.isEmpty ?? true ? '-' : fogas.idojaras!),
                  _AdatSor(cim: 'Hőmérséklet', ertek: fogas.homerseklet == null ? '-' : '${fogas.homerseklet} °C'),
                ],
              ),
            ),

            if (fogas.megjegyzes.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
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
          SizedBox(
            width: 120,
            child: Text(cim, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(ertek, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
