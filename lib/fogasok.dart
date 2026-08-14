import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'adattarolo.dart';
import 'modellek.dart';
import 'idojaras_szolgaltato.dart';
import 'torzsadatok.dart'; 
import 'vizjel_keszito.dart';

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
          tura: widget.tura,
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

  Color _getKartyaszin(String? sors) {
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
                  color: _getKartyaszin(fogas.sors),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
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

class FogasSzerkesztoScreen extends StatefulWidget {
  final Tura tura;
  final FogasModel? szerkeszthetoFogas;
  final VoidCallback mentesCallback;

  const FogasSzerkesztoScreen({super.key, required this.tura, this.szerkeszthetoFogas, required this.mentesCallback});

  @override
  State<FogasSzerkesztoScreen> createState() => _FogasSzerkesztoScreenState();
}

class _FogasSzerkesztoScreenState extends State<FogasSzerkesztoScreen> {
  DateTime _datum = DateTime.now();
  TimeOfDay _idopont = TimeOfDay.now();
  
  String? _kivalasztottHalfaj;
  final _sulyCtrl = TextEditingController();
  final _hosszCtrl = TextEditingController();
  
  String? _sors; 
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
  List<String> _elerhetoSorsok = []; 
  List<String> _elerhetoBotok = [];
  List<String> _elerhetoModszerek = [];
  List<String> _elerhetoVegszerelekek = [];
  List<String> _elerhetoCsalik = [];
  List<String> _elerhetoEtetoanyagok = [];
  List<String> _elerhetoIdojarasok = [];

  @override
  void initState() {
    super.initState();
    if (widget.szerkeszthetoFogas != null) {
      final f = widget.szerkeszthetoFogas!;
      _datum = f.datum;
      final tParts = f.idopont.split(':');
      if (tParts.length == 2) _idopont = TimeOfDay(hour: int.parse(tParts[0]), minute: int.parse(tParts[1]));
      
      _kivalasztottHalfaj = f.halfaj.isEmpty ? null : f.halfaj; 
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
    } else {
      // ÚJ LOGIKA: Okos dátum beállítás új fogásnál
      final most = DateTime.now();
      final maiNap = DateTime(most.year, most.month, most.day);
      final tKezd = DateTime(widget.tura.kezdoDatum.year, widget.tura.kezdoDatum.month, widget.tura.kezdoDatum.day);
      final tVeg = DateTime(widget.tura.befejezoDatum.year, widget.tura.befejezoDatum.month, widget.tura.befejezoDatum.day);

      if (maiNap.isBefore(tKezd) || maiNap.isAfter(tVeg)) {
        _datum = tKezd; // Kívül esik, ráugrunk a túra első napjára
      } else {
        _datum = maiNap; // Belül van, jöhet az "élő" mai nap
      }
    }
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    _elerhetoHalfajok = await AdatTarolo.halfajokBetoltese();
    _elerhetoHalfajok.sort((a, b) => a.nev.toLowerCase().compareTo(b.nev.toLowerCase()));
    
    _elerhetoBotok = await AdatTarolo.botokBetoltese();
    _elerhetoBotok.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    _elerhetoModszerek = await AdatTarolo.modszerekBetoltese();
    _elerhetoModszerek.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    _elerhetoVegszerelekek = await AdatTarolo.szerelekekBetoltese();
    _elerhetoVegszerelekek.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    _elerhetoCsalik = await AdatTarolo.csalikBetoltese();
    _elerhetoCsalik.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    _elerhetoEtetoanyagok = await AdatTarolo.etetoanyagokBetoltese();
    _elerhetoEtetoanyagok.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    _elerhetoIdojarasok = await AdatTarolo.idojarasBetoltese();
    
    List<String> mentettSorsok = await AdatTarolo.sorsBetoltese();
    _elerhetoSorsok = mentettSorsok;
    
    if (_sors != null && !_elerhetoSorsok.contains(_sors)) {
      _sors = null;
    }
    
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
                if (kategoria == 'Horgászbot') { _elerhetoBotok.add(nev); _elerhetoBotok.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())); await AdatTarolo.botokMentes(_elerhetoBotok); }
                if (kategoria == 'Módszer') { _elerhetoModszerek.add(nev); _elerhetoModszerek.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())); await AdatTarolo.modszerekMentes(_elerhetoModszerek); }
                if (kategoria == 'Végszerelék') { _elerhetoVegszerelekek.add(nev); _elerhetoVegszerelekek.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())); await AdatTarolo.szerelekekMentes(_elerhetoVegszerelekek); }
                if (kategoria == 'Csali') { _elerhetoCsalik.add(nev); _elerhetoCsalik.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())); await AdatTarolo.csalikMentes(_elerhetoCsalik); }
                if (kategoria == 'Etetőanyag') { _elerhetoEtetoanyagok.add(nev); _elerhetoEtetoanyagok.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())); await AdatTarolo.etetoanyagokMentes(_elerhetoEtetoanyagok); }
                
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

  Future<void> _mutasKereshetoAblak(String cim, List<String> elemek, Function(String?) onKivalasztva, bool allowNew) async {
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
            final szurt = elemek.where((e) => e.toLowerCase().contains(kereses.toLowerCase())).toList();
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('$cim kiválasztása', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: keresoCtrl,
                        autofocus: true,
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
                    if (allowNew)
                      ListTile(
                        leading: const Icon(Icons.add_circle, color: Colors.greenAccent),
                        title: Text('Új $cim hozzáadása', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.pop(context);
                          if (cim == 'Halfaj') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HalfajSzerkesztoScreen(
                                  mentesCallback: (ujHal) async {
                                    _elerhetoHalfajok.add(ujHal);
                                    _elerhetoHalfajok.sort((a, b) => a.nev.toLowerCase().compareTo(b.nev.toLowerCase()));
                                    await AdatTarolo.halfajokMentes(_elerhetoHalfajok);
                                    onKivalasztva(ujHal.nev);
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          } else {
                            _ujTorzsadatHozzaadas(cim, (ujNev) => onKivalasztva(ujNev));
                          }
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.clear, color: Colors.redAccent),
                      title: const Text('-- Nincs kiválasztva --', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        onKivalasztva(null);
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
                              onKivalasztva(szurt[index]);
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

  Widget _buildKereshetoDropdown({required String label, required String targyEset, required String? value, required List<String> items, required Function(String?) onChanged, bool allowNew = true}) {
    return InkWell(
      onTap: () => _mutasKereshetoAblak(label, items, onChanged, allowNew),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(value ?? '-- Nincs kiválasztva --', style: TextStyle(color: value == null ? Colors.white54 : Colors.white))),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildTobbesKivalaszto({required String label, required String targyEset, required List<String> elerhetoElemek, required List<String> kivalasztottElemek}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label hozzáadása:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _mutasKereshetoAblak(label, elerhetoElemek, (val) {
                  if (val != null && !kivalasztottElemek.contains(val)) {
                    setState(() => kivalasztottElemek.add(val));
                  }
                }, true),
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Válassz $targyEset...', style: const TextStyle(color: Colors.white54)),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    ],
                  ),
                ),
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
            runSpacing: 8,
            children: kivalasztottElemek.map((elem) {
              return ActionChip(
                backgroundColor: Colors.green[800],
                label: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  child: Text(
                    elem, 
                    style: const TextStyle(color: Colors.white),
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
    DateTime tKeze = DateTime(widget.tura.kezdoDatum.year, widget.tura.kezdoDatum.month, widget.tura.kezdoDatum.day);
    DateTime tVege = DateTime(widget.tura.befejezoDatum.year, widget.tura.befejezoDatum.month, widget.tura.befejezoDatum.day);
    DateTime fDatum = DateTime(_datum.year, _datum.month, _datum.day);

    if (fDatum.isBefore(tKeze) || fDatum.isAfter(tVege)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fogás dátuma (${DateFormat('yyyy.MM.dd').format(fDatum)}) kívül esik a túra időtartamán!'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        )
      );
      return; 
    }

    final ujFogas = FogasModel(
      id: widget.szerkeszthetoFogas?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      turaId: widget.tura.id,
      datum: _datum,
      idopont: '${_idopont.hour.toString().padLeft(2, '0')}:${_idopont.minute.toString().padLeft(2, '0')}',
      halfaj: _kivalasztottHalfaj ?? '', 
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

            _buildKereshetoDropdown(
              label: 'Halfaj',
              targyEset: 'Halfajt',
              value: _kivalasztottHalfaj,
              items: _elerhetoHalfajok.map((h) => h.nev).toList(),
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

            DropdownButtonFormField<String?>(
              value: _sors,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hal sorsa', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('-- Nincs kiválasztva --')),
                ..._elerhetoSorsok.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
              ],
              onChanged: (val) { if (val != null) setState(() => _sors = val); },
            ),
            const Divider(height: 32, color: Colors.white24),

            _buildTobbesKivalaszto(label: 'Csali', targyEset: 'Csalit', elerhetoElemek: _elerhetoCsalik, kivalasztottElemek: _kivalasztottCsalik),
            const SizedBox(height: 16),
            _buildTobbesKivalaszto(label: 'Etetőanyag', targyEset: 'Etetőanyagot', elerhetoElemek: _elerhetoEtetoanyagok, kivalasztottElemek: _kivalasztottEtetoanyagok),
            
            const SizedBox(height: 12),
            TextField(controller: _etetesGyakorisagaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Etetés gyakorisága (perc)', border: OutlineInputBorder())),
            const Divider(height: 32, color: Colors.white24),

            _buildKereshetoDropdown(label: 'Horgászbot', targyEset: 'Horgászbotot', value: _kivalasztottBot, items: _elerhetoBotok, onChanged: (val) => setState(() => _kivalasztottBot = val)),
            const SizedBox(height: 12),
            _buildKereshetoDropdown(label: 'Módszer', targyEset: 'Módszert', value: _kivalasztottModszer, items: _elerhetoModszerek, onChanged: (val) => setState(() => _kivalasztottModszer = val)),
            const SizedBox(height: 12),
            _buildKereshetoDropdown(label: 'Végszerelék', targyEset: 'Végszereléket', value: _kivalasztottVegszerelek, items: _elerhetoVegszerelekek, onChanged: (val) => setState(() => _kivalasztottVegszerelek = val)),
            const Divider(height: 32, color: Colors.white24),

            _buildKereshetoDropdown(label: 'Időjárás', targyEset: 'Időjárást', value: _kivalasztottIdojaras, items: _elerhetoIdojarasok, allowNew: false, onChanged: (val) => setState(() => _kivalasztottIdojaras = val)),
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
                if (image != null) {
                  String biztonsagosUtvonal = await AdatTarolo.biztonsagosKepMasolas(image.path);
                  setState(() => _fenykepUtvonal = biztonsagosUtvonal);
                }
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
                  VizjelKeszito.fogasLetoltes(context, fogas, fogas.fenykep!, helyszinNev);
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
                  if (horgaszhely.isNotEmpty) 
                    Text('Horgászhely: $horgaszhely', style: const TextStyle(fontSize: 14, color: Colors.white54)),
                  
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
                  _AdatSor(cim: 'Csali', ertek: fogas.csali.isEmpty ? '-' : fogas.csali.map((c) => '• $c').join('\n')),
                  _AdatSor(cim: 'Etetőanyag', ertek: fogas.etetoanyag.isEmpty ? '-' : fogas.etetoanyag.map((e) => '• $e').join('\n')),
                  
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
            child: Text(ertek, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
