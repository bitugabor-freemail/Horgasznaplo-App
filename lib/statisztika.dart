import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'adattarolo.dart';
import 'modellek.dart';

class StatisztikaScreen extends StatefulWidget {
  const StatisztikaScreen({super.key});

  @override
  State<StatisztikaScreen> createState() => StatisztikaScreenState();
}

class StatisztikaScreenState extends State<StatisztikaScreen> {
  // --- ADATBÁZISOK ---
  List<Tura> _osszesTura = [];
  List<FogasModel> _osszesFogas = [];
  List<Helyszin> _helyszinek = [];
  
  List<Halfaj> _halfajok = [];
  List<String> _botok = [], _modszerek = [], _szerelekek = [], _csalik = [], _etetoanyagok = [], _tarsak = [], _idojarasok = [], _sorsok = [];

  // --- SZŰRŐ FELTÉTELEK ---
  late DateTime _kezdoDatum;
  late DateTime _vegDatum;
  TimeOfDay _kezdoIdo = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _vegIdo = const TimeOfDay(hour: 23, minute: 59);
  
  String? _szuroHalfaj, _szuroHelyszin, _szuroBot, _szuroModszer, _szuroSzerelek;
  String? _szuroCsali, _szuroEtetoanyag, _szuroTars, _szuroIdojaras, _szuroSors;
  
  final _horgaszhelyCtrl = TextEditingController();
  final _sulyMinCtrl = TextEditingController();
  final _sulyMaxCtrl = TextEditingController();
  final _hosszMinCtrl = TextEditingController();
  final _hosszMaxCtrl = TextEditingController();
  final _hoMinCtrl = TextEditingController();
  final _hoMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final most = DateTime.now();
    _kezdoDatum = DateTime(most.year, 1, 1); 
    _vegDatum = DateTime(most.year, 12, 31);
    adatokBetoltese();
  }

  Future<void> adatokBetoltese() async {
    _osszesTura = await AdatTarolo.turakBetoltese();
    
    if (_osszesTura.isNotEmpty) {
      _osszesTura.sort((a, b) => a.kezdoDatum.compareTo(b.kezdoDatum));
      _kezdoDatum = DateTime(_osszesTura.first.kezdoDatum.year, _osszesTura.first.kezdoDatum.month, _osszesTura.first.kezdoDatum.day);
    }
    
    _osszesFogas = await AdatTarolo.fogasokBetoltese();
    _helyszinek = await AdatTarolo.helyszinekBetoltese();
    _halfajok = await AdatTarolo.halfajokBetoltese();
    _botok = await AdatTarolo.botokBetoltese();
    _modszerek = await AdatTarolo.modszerekBetoltese();
    _szerelekek = await AdatTarolo.szerelekekBetoltese();
    _csalik = await AdatTarolo.csalikBetoltese();
    _etetoanyagok = await AdatTarolo.etetoanyagokBetoltese();
    _tarsak = await AdatTarolo.tarsakBetoltese();
    _idojarasok = await AdatTarolo.idojarasBetoltese();
    _sorsok = await AdatTarolo.sorsBetoltese();
    setState(() {});
  }

  bool _isSzuresAktiv() {
    final most = DateTime.now();
    final alapKezdo = _osszesTura.isNotEmpty ? DateTime(_osszesTura.first.kezdoDatum.year, _osszesTura.first.kezdoDatum.month, _osszesTura.first.kezdoDatum.day) : DateTime(most.year, 1, 1);
    final alapVeg = DateTime(most.year, 12, 31);
    
    if (_kezdoDatum != alapKezdo || _vegDatum != alapVeg) return true;
    if (_kezdoIdo.hour != 0 || _kezdoIdo.minute != 0) return true;
    if (_vegIdo.hour != 23 || _vegIdo.minute != 59) return true;
    
    if (_szuroHalfaj != null || _szuroHelyszin != null || _szuroBot != null || _szuroModszer != null || 
        _szuroSzerelek != null || _szuroCsali != null || _szuroEtetoanyag != null || _szuroTars != null || 
        _szuroIdojaras != null || _szuroSors != null) return true;

    if (_horgaszhelyCtrl.text.isNotEmpty || _sulyMinCtrl.text.isNotEmpty || _sulyMaxCtrl.text.isNotEmpty ||
        _hosszMinCtrl.text.isNotEmpty || _hosszMaxCtrl.text.isNotEmpty || _hoMinCtrl.text.isNotEmpty || _hoMaxCtrl.text.isNotEmpty) return true;

    return false;
  }

  void _szurokAlaphelyzetbe() {
    final most = DateTime.now();
    setState(() {
      _kezdoDatum = _osszesTura.isNotEmpty ? DateTime(_osszesTura.first.kezdoDatum.year, _osszesTura.first.kezdoDatum.month, _osszesTura.first.kezdoDatum.day) : DateTime(most.year, 1, 1);
      _vegDatum = DateTime(most.year, 12, 31);
      _kezdoIdo = const TimeOfDay(hour: 0, minute: 0);
      _vegIdo = const TimeOfDay(hour: 23, minute: 59);
      
      _szuroHalfaj = _szuroHelyszin = _szuroBot = _szuroModszer = _szuroSzerelek = null;
      _szuroCsali = _szuroEtetoanyag = _szuroTars = _szuroIdojaras = _szuroSors = null;
      
      _horgaszhelyCtrl.clear(); _sulyMinCtrl.clear(); _sulyMaxCtrl.clear();
      _hosszMinCtrl.clear(); _hosszMaxCtrl.clear(); _hoMinCtrl.clear(); _hoMaxCtrl.clear();
    });
  }

  List<Tura> _getSzurtTurak() {
    return _osszesTura.where((t) {
      DateTime tKezd = DateTime(t.kezdoDatum.year, t.kezdoDatum.month, t.kezdoDatum.day);
      if (tKezd.isBefore(_kezdoDatum) || tKezd.isAfter(_vegDatum)) return false;

      if (_szuroHelyszin != null) {
        final h = _helyszinek.cast<Helyszin?>().firstWhere((h) => h?.id == t.helyszinId, orElse: () => null);
        if (h?.nev != _szuroHelyszin) return false;
      }
      
      if (_szuroTars != null && !t.horgasztarsak.contains(_szuroTars)) return false;
      if (_horgaszhelyCtrl.text.isNotEmpty && !t.horgaszhely.toLowerCase().contains(_horgaszhelyCtrl.text.toLowerCase())) return false;
      
      return true;
    }).toList();
  }

  List<FogasModel> _getSzurtFogasok() {
    return _osszesFogas.where((f) {
      final fDatum = DateTime(f.datum.year, f.datum.month, f.datum.day);
      if (fDatum.isBefore(_kezdoDatum) || fDatum.isAfter(_vegDatum)) return false;

      final tParts = f.idopont.split(':');
      if (tParts.length == 2) {
        int fMin = int.parse(tParts[0]) * 60 + int.parse(tParts[1]);
        int startMin = _kezdoIdo.hour * 60 + _kezdoIdo.minute;
        int endMin = _vegIdo.hour * 60 + _vegIdo.minute;
        if (fMin < startMin || fMin > endMin) return false;
      }

      if (_szuroHalfaj != null && f.halfaj != _szuroHalfaj) return false;
      if (_szuroSors != null && f.sors != _szuroSors) return false;
      if (_szuroBot != null && f.bot != _szuroBot) return false;
      if (_szuroModszer != null && f.modszer != _szuroModszer) return false;
      if (_szuroSzerelek != null && f.vegszerelek != _szuroSzerelek) return false;
      if (_szuroIdojaras != null && f.idojaras != _szuroIdojaras) return false;
      if (_szuroCsali != null && !f.csali.contains(_szuroCsali)) return false;
      if (_szuroEtetoanyag != null && !f.etetoanyag.contains(_szuroEtetoanyag)) return false;

      if (_sulyMinCtrl.text.isNotEmpty && (f.suly == null || f.suly! < double.parse(_sulyMinCtrl.text.replaceAll(',', '.')))) return false;
      if (_sulyMaxCtrl.text.isNotEmpty && (f.suly != null && f.suly! > double.parse(_sulyMaxCtrl.text.replaceAll(',', '.')))) return false;
      
      if (_hosszMinCtrl.text.isNotEmpty && (f.hossz == null || f.hossz! < int.parse(_hosszMinCtrl.text))) return false;
      if (_hosszMaxCtrl.text.isNotEmpty && (f.hossz != null && f.hossz! > int.parse(_hosszMaxCtrl.text))) return false;

      if (_hoMinCtrl.text.isNotEmpty || _hoMaxCtrl.text.isNotEmpty) {
        double? homerseklet = f.homerseklet;
        if (homerseklet == null) return false;
        if (_hoMinCtrl.text.isNotEmpty && homerseklet < double.parse(_hoMinCtrl.text.replaceAll(',', '.'))) return false;
        if (_hoMaxCtrl.text.isNotEmpty && homerseklet > double.parse(_hoMaxCtrl.text.replaceAll(',', '.'))) return false;
      }

      if (_szuroHelyszin != null || _szuroTars != null || _horgaszhelyCtrl.text.isNotEmpty) {
        final tura = _osszesTura.cast<Tura?>().firstWhere((t) => t?.id == f.turaId, orElse: () => null);
        if (tura == null) return false; 
        
        if (_szuroTars != null && !tura.horgasztarsak.contains(_szuroTars)) return false;
        if (_horgaszhelyCtrl.text.isNotEmpty && !tura.horgaszhely.toLowerCase().contains(_horgaszhelyCtrl.text.toLowerCase())) return false;
        
        if (_szuroHelyszin != null) {
          final helyszin = _helyszinek.cast<Helyszin?>().firstWhere((h) => h?.id == tura.helyszinId, orElse: () => null);
          if (helyszin?.nev != _szuroHelyszin) return false;
        }
      }

      return true; 
    }).toList();
  }

  void _nyitReszletesSzurok() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Részletes Szűrők', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      TextButton(
                        onPressed: () {
                          _szurokAlaphelyzetbe();
                          setModalState(() {});
                        },
                        child: const Text('Alaphelyzet', style: TextStyle(color: Colors.redAccent)),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(
                                onPressed: () async {
                                  final d = await showDatePicker(context: context, initialDate: _kezdoDatum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                  if (d != null) setModalState(() => _kezdoDatum = d);
                                },
                                child: Text('Tól: ${DateFormat('yyyy.MM.dd').format(_kezdoDatum)}', style: const TextStyle(color: Colors.white)),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton(
                                onPressed: () async {
                                  final d = await showDatePicker(context: context, initialDate: _vegDatum, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                  if (d != null) setModalState(() => _vegDatum = d);
                                },
                                child: Text('Ig: ${DateFormat('yyyy.MM.dd').format(_vegDatum)}', style: const TextStyle(color: Colors.white)),
                              )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(
                                onPressed: () async {
                                  final t = await showTimePicker(context: context, initialTime: _kezdoIdo);
                                  if (t != null) setModalState(() => _kezdoIdo = t);
                                },
                                child: Text('Tól: ${_kezdoIdo.format(context)}', style: const TextStyle(color: Colors.white)),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton(
                                onPressed: () async {
                                  final t = await showTimePicker(context: context, initialTime: _vegIdo);
                                  if (t != null) setModalState(() => _vegIdo = t);
                                },
                                child: Text('Ig: ${_vegIdo.format(context)}', style: const TextStyle(color: Colors.white)),
                              )),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _szuroDropdown(setModalState, 'Halfaj', _szuroHalfaj, _halfajok.map((e) => e.nev).toList(), (val) => _szuroHalfaj = val),
                          _szuroDropdown(setModalState, 'Helyszín', _szuroHelyszin, _helyszinek.map((e) => e.nev).toList(), (val) => _szuroHelyszin = val),
                          _szuroDropdown(setModalState, 'Hal sorsa', _szuroSors, _sorsok, (val) => _szuroSors = val),
                          
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _sulyMinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Súly (kg)', border: OutlineInputBorder()))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: _sulyMaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Súly (kg)', border: OutlineInputBorder()))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _hosszMinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Hossz (cm)', border: OutlineInputBorder()))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: _hosszMaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Hossz (cm)', border: OutlineInputBorder()))),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextField(controller: _horgaszhelyCtrl, decoration: const InputDecoration(labelText: 'Horgászhely (Szöveg)', border: OutlineInputBorder())),
                          const SizedBox(height: 12),

                          _szuroDropdown(setModalState, 'Horgászbot', _szuroBot, _botok, (val) => _szuroBot = val),
                          _szuroDropdown(setModalState, 'Módszer', _szuroModszer, _modszerek, (val) => _szuroModszer = val),
                          _szuroDropdown(setModalState, 'Végszerelék', _szuroSzerelek, _szerelekek, (val) => _szuroSzerelek = val),
                          _szuroDropdown(setModalState, 'Csali', _szuroCsali, _csalik, (val) => _szuroCsali = val),
                          _szuroDropdown(setModalState, 'Etetőanyag', _szuroEtetoanyag, _etetoanyagok, (val) => _szuroEtetoanyag = val),
                          _szuroDropdown(setModalState, 'Horgásztárs', _szuroTars, _tarsak, (val) => _szuroTars = val),
                          _szuroDropdown(setModalState, 'Időjárás', _szuroIdojaras, _idojarasok, (val) => _szuroIdojaras = val),
                          
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _hoMinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Hőfok (°C)', border: OutlineInputBorder()))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: _hoMaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Hőfok (°C)', border: OutlineInputBorder()))),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                        setState(() {}); 
                        Navigator.pop(context);
                      },
                      child: const Text('Szűrés Alkalmazása', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _szuroDropdown(StateSetter setModalState, String label, String? currentVal, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: currentVal,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Összes $label')),
          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: (val) => setModalState(() => onChanged(val)),
      ),
    );
  }

  String _legjobbIdosav(List<FogasModel> fogasok) {
    if (fogasok.isEmpty) return '-';
    Map<int, int> idosavok = {};
    for (var f in fogasok) {
      final tParts = f.idopont.split(':');
      if (tParts.length == 2) {
        int ora = int.parse(tParts[0]);
        int sav = (ora / 3).floor() * 3; 
        idosavok[sav] = (idosavok[sav] ?? 0) + 1;
      }
    }
    if (idosavok.isEmpty) return '-';
    var legjobb = idosavok.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${legjobb.key.toString().padLeft(2, '0')}:00 - ${(legjobb.key + 3).toString().padLeft(2, '0')}:00 (${legjobb.value} db)';
  }

  String _legjobbKombo(List<FogasModel> fogasok, String Function(FogasModel) selector) {
    if (fogasok.isEmpty) return '-';
    Map<String, int> gyakorisag = {};
    for (var f in fogasok) {
      String kulcs = selector(f);
      if (kulcs.trim().isNotEmpty && kulcs != '-' && kulcs != '- / -' && kulcs != '- / -°C' && kulcs != '- + -') {
        gyakorisag[kulcs] = (gyakorisag[kulcs] ?? 0) + 1;
      }
    }
    if (gyakorisag.isEmpty) return '-';
    var legjobb = gyakorisag.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${legjobb.key} (${legjobb.value} db)';
  }

  String _legjobbHelyszin(List<FogasModel> fogasok) {
    if (fogasok.isEmpty) return '-';
    Map<String, int> gyak = {};
    for (var f in fogasok) {
      final tura = _osszesTura.cast<Tura?>().firstWhere((t) => t?.id == f.turaId, orElse: () => null);
      if (tura != null && tura.helyszinId != null) {
        final h = _helyszinek.cast<Helyszin?>().firstWhere((h) => h?.id == tura.helyszinId, orElse: () => null);
        if (h != null) gyak[h.nev] = (gyak[h.nev] ?? 0) + 1;
      }
    }
    if (gyak.isEmpty) return '-';
    var legjobb = gyak.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${legjobb.key} (${legjobb.value} db)';
  }

  // --- TOP 3 ---
  Map<String, _TagStat> _getCsaliStats(List<FogasModel> fogasok) {
    Map<String, _TagStat> stats = {};
    for (var f in fogasok) {
      for (var csali in f.csali) {
        if (!stats.containsKey(csali)) stats[csali] = _TagStat();
        stats[csali]!.darab += 1;
        stats[csali]!.osszsuly += (f.suly ?? 0.0);
      }
    }
    return stats;
  }

  Map<String, _TagStat> _getEtetoStats(List<FogasModel> fogasok) {
    Map<String, _TagStat> stats = {};
    for (var f in fogasok) {
      for (var eteto in f.etetoanyag) {
        if (!stats.containsKey(eteto)) stats[eteto] = _TagStat();
        stats[eteto]!.darab += 1;
        stats[eteto]!.osszsuly += (f.suly ?? 0.0);
      }
    }
    return stats;
  }

  Widget _buildTop3Blokk(String cim, Map<String, _TagStat> stats) {
    if (stats.isEmpty) return const SizedBox();

    var darabLista = stats.entries.toList()
      ..sort((a, b) {
        int cmp = b.value.darab.compareTo(a.value.darab);
        if (cmp == 0) return b.value.atlag.compareTo(a.value.atlag);
        return cmp;
      });
    var topDarab = darabLista.take(3).toList();

    var sulyLista = stats.entries.where((e) => e.value.atlag > 0).toList()
      ..sort((a, b) {
        int cmp = b.value.atlag.compareTo(a.value.atlag);
        if (cmp == 0) return b.value.darab.compareTo(a.value.darab);
        return cmp;
      });
    var topSuly = sulyLista.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text('🏆 $cim', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
        ),
        
        if (topDarab.isNotEmpty) ...[
          const Text('Legtöbb halat adó (Darab)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...topDarab.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('${e.key + 1}. ${e.value.key} (${e.value.value.darab} db)', style: const TextStyle(color: Colors.white, fontSize: 14)),
          )),
          const SizedBox(height: 12),
        ],

        if (topSuly.isNotEmpty) ...[
          const Text('Legnagyobb halat adó (Átlagsúly)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...topSuly.asMap().entries.map((e) {
            final val = e.value.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  children: [
                    TextSpan(text: '${e.key + 1}. ${e.value.key}: '),
                    TextSpan(text: '${val.atlag.toStringAsFixed(2)} kg/hal', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' (${val.darab} db)', style: const TextStyle(color: Colors.white54)),
                  ]
                )
              ),
            );
          }),
        ],
      ],
    );
  }

  _HoldfazisAdat _getHoldfazisInfo(DateTime date) {
    final double newMoon = DateTime.utc(2000, 1, 6, 18, 14).millisecondsSinceEpoch.toDouble();
    const double msInDay = 86400000.0;
    const double synodicMonth = 29.53058867;
    
    double diffDays = (date.millisecondsSinceEpoch - newMoon) / msInDay;
    double phase = diffDays % synodicMonth;
    if (phase < 0) phase += synodicMonth;
    
    if (phase < 1.84) return _HoldfazisAdat('Újhold', '🌑', 5, 'Kiváló esély! A Föld, a Hold és a Nap egy vonalban van. A gravitációs húzóerő a legnagyobb, a halak rendkívül aktívak.');
    if (phase < 5.53) return _HoldfazisAdat('Növő holdsarló', '🌒', 4, 'Jó esély! Erősödő gravitációs hatás, egyre aktívabb táplálkozási kedv.');
    if (phase < 9.22) return _HoldfazisAdat('Első negyed', '🌓', 3, 'Közepes esély. A gravitációs hatás a legkisebb, a halak visszaállnak a normál, megszokott ritmusukra.');
    if (phase < 12.91) return _HoldfazisAdat('Növő telihold', '🌔', 4, 'Jó esély! Közeleg a csúcspont. A ragadozók az éjszakai fényben egyre aktívabbak a felszín közelében.');
    if (phase < 16.61) return _HoldfazisAdat('Telihold', '🌕', 5, 'Kiváló esély! Az éjszakai vízfelszín nagyon világos, a felszíni ragadozók kiemelten aktívak, de a békéshalak óvatosabbak lehetnek.');
    if (phase < 20.30) return _HoldfazisAdat('Fogyó telihold', '🌖', 4, 'Jó esély! Még kitart az erős aktivitás, érdemes az éjszakai és a hajnali órákat is kihasználni.');
    if (phase < 24.00) return _HoldfazisAdat('Utolsó negyed', '🌗', 3, 'Közepes esély. Átlagos, kiszámítható táplálkozási ütem várható.');
    if (phase < 27.68) return _HoldfazisAdat('Fogyó holdsarló', '🌘', 2, 'Gyenge esély. Átmeneti, nyugalmi időszak. Ilyenkor érdemes finomítani a szereléken és a csalin!');
    return _HoldfazisAdat('Újhold', '🌑', 5, 'Kiváló esély! A Föld, a Hold és a Nap egy vonalban van. A gravitációs húzóerő a legnagyobb, a halak rendkívül aktívak.');
  }

  String _getMagyarNap(DateTime date) {
    const days = ['Hétfő', 'Kedd', 'Szerda', 'Csütörtök', 'Péntek', 'Szombat', 'Vasárnap'];
    return days[date.weekday - 1];
  }

  void mutassHoldnaptar() {
    final szurt = _getSzurtFogasok();
    Map<String, int> phaseCounts = {};
    int total = szurt.length;
    
    for(var f in szurt) {
      final phase = _getHoldfazisInfo(f.datum);
      String key = '${phase.ikon} ${phase.nev}';
      phaseCounts[key] = (phaseCounts[key] ?? 0) + 1;
    }
    var sortedPhases = phaseCounts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));

    final today = DateTime.now();
    final todayPhase = _getHoldfazisInfo(today);
    
    List<DateTime> naptarNapok = List.generate(380, (i) => today.add(Duration(days: i - 14))); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, 
                  margin: const EdgeInsets.only(bottom: 16), 
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.brightness_2, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text('Holdnaptár & Elemzés', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                ],
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aktuális Holdfázis (Ma)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${todayPhase.ikon} ${todayPhase.nev}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Row(
                          children: List.generate(5, (index) => Icon(
                            Icons.phishing, 
                            size: 18, 
                            color: index < todayPhase.kapasIndex ? Colors.greenAccent : Colors.white24
                          )),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(todayPhase.leiras, style: const TextStyle(color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (total > 0) ...[
                const Text('Saját Statisztikád', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('A szűrt $total db fogásod alapján a legeredményesebb holdfázisaid:', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                ...sortedPhases.take(3).map((e) {
                  double percent = (e.value / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(color: Colors.white)),
                        Text('${e.value} db (${percent.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    )
                  );
                }),
                const SizedBox(height: 16),
              ],

              const Text('Előrejelzés (Naptár)', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: ScrollController(initialScrollOffset: 13 * 76.0), 
                  itemExtent: 76.0,
                  itemCount: naptarNapok.length,
                  itemBuilder: (context, idx) {
                    DateTime date = naptarNapok[idx];
                    _HoldfazisAdat phase = _getHoldfazisInfo(date);
                    bool isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                    
                    return SizedBox(
                      height: 76.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.green[900]?.withOpacity(0.3) : const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday ? Border.all(color: Colors.greenAccent) : null,
                        ),
                        child: ListTile(
                          leading: Text(phase.ikon, style: const TextStyle(fontSize: 24)),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${DateFormat('MM.dd.').format(date)} (${_getMagyarNap(date)})', style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                              Row(
                                children: List.generate(5, (index) => Icon(
                                  Icons.phishing, 
                                  size: 14, 
                                  color: index < phase.kapasIndex ? (phase.kapasIndex >= 4 ? Colors.greenAccent : Colors.orangeAccent) : Colors.white24
                                )),
                              )
                            ],
                          ),
                          subtitle: Text(phase.nev, style: const TextStyle(color: Colors.white70)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final szurtTurak = _getSzurtTurak(); 
    final szurtFogasok = _getSzurtFogasok();
    final isSzurt = _isSzuresAktiv();
    
    int turakSzama = szurtTurak.length; 
    int darab = szurtFogasok.length;
    double osszsuly = szurtFogasok.fold(0.0, (sum, f) => sum + (f.suly ?? 0.0));
    
    double atlagsulyHal = darab > 0 ? osszsuly / darab : 0.0;
    double atlagHalPerTura = turakSzama > 0 ? darab / turakSzama : 0.0;
    double atlagSulyPerTura = turakSzama > 0 ? osszsuly / turakSzama : 0.0;
    
    FogasModel? maxSulyHal;
    FogasModel? maxHosszHal;
    if (darab > 0) {
      maxSulyHal = szurtFogasok.reduce((a, b) => (a.suly ?? 0) > (b.suly ?? 0) ? a : b);
      maxHosszHal = szurtFogasok.reduce((a, b) => (a.hossz ?? 0) > (b.hossz ?? 0) ? a : b);
    }

    int visszaDb = szurtFogasok.where((f) => f.sors == 'Visszaengedtem').length;
    int elvittDb = szurtFogasok.where((f) => f.sors == 'Elvittem').length;
    int elajandekozottDb = szurtFogasok.where((f) => f.sors == 'Elajándékoztam').length; // ÚJ KÓD
    int elpusztultDb = szurtFogasok.where((f) => f.sors == 'Elpusztult').length;

    double visszaSuly = szurtFogasok.where((f) => f.sors == 'Visszaengedtem').fold(0.0, (s, f) => s + (f.suly ?? 0.0));
    double elvittSuly = szurtFogasok.where((f) => f.sors == 'Elvittem').fold(0.0, (s, f) => s + (f.suly ?? 0.0));
    double elajandekozottSuly = szurtFogasok.where((f) => f.sors == 'Elajándékoztam').fold(0.0, (s, f) => s + (f.suly ?? 0.0)); // ÚJ KÓD
    double elpusztultSuly = szurtFogasok.where((f) => f.sors == 'Elpusztult').fold(0.0, (s, f) => s + (f.suly ?? 0.0));

    Map<String, int> halfajDb = {};
    for (var f in szurtFogasok) {
      halfajDb[f.halfaj] = (halfajDb[f.halfaj] ?? 0) + 1;
    }

    Map<String, _TagStat> csaliStats = _getCsaliStats(szurtFogasok);
    Map<String, _TagStat> etetoStats = _getEtetoStats(szurtFogasok);

    Map<String, FogasModel> rekordok = {};
    for (var f in szurtFogasok) {
      if (f.suly != null && f.suly! > 0) {
        if (!rekordok.containsKey(f.halfaj)) {
          rekordok[f.halfaj] = f;
        } else {
          if (f.suly! > (rekordok[f.halfaj]!.suly ?? 0)) {
            rekordok[f.halfaj] = f;
          }
        }
      }
    }
    
    var rekordLista = rekordok.values.toList();
    rekordLista.sort((a, b) => (b.suly ?? 0).compareTo(a.suly ?? 0));

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161616),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Adatok Elemzése', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSzurt ? Colors.green[800] : Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Szűrők'),
                  onPressed: _nyitReszletesSzurok,
                ),
              ],
            ),
          ),
          
          if (isSzurt)
            Container(
              width: double.infinity,
              color: Colors.green[900]?.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Center(child: Text('Aktív szűrés van érvényben! Az elemzés csak a szűrt adatokat mutatja.', textAlign: TextAlign.center, style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))),
            ),

          Expanded(
            child: (szurtTurak.isEmpty && szurtFogasok.isEmpty)
                ? const Center(child: Text('Nincs adat a megadott szűrések alapján.', style: TextStyle(color: Colors.white54)))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _Kartya(
                        cim: 'Alap statisztika',
                        ikon: Icons.analytics,
                        tartalom: Column(
                          children: [
                            _StatisztikaSor(cim: 'Érintett túrák száma', ertek: '$turakSzama alkalom'),
                            _StatisztikaSor(cim: 'Kifogott halak (Összesen)', ertek: '$darab db'),
                            _StatisztikaSor(cim: 'Összsúly', ertek: '${osszsuly.toStringAsFixed(2)} kg'),
                            _StatisztikaSor(cim: 'Átlagsúly / hal', ertek: '${atlagsulyHal.toStringAsFixed(2)} kg'),
                            const Divider(color: Colors.white24),
                            _StatisztikaSor(cim: 'Átlag hal / túra', ertek: '${atlagHalPerTura.toStringAsFixed(1)} db'),
                            _StatisztikaSor(cim: 'Átlag súly / túra', ertek: '${atlagSulyPerTura.toStringAsFixed(2)} kg'),
                            const Divider(color: Colors.white24),
                            _StatisztikaSor(cim: 'Legnagyobb hal', ertek: (maxSulyHal != null && maxSulyHal.suly != null) ? '${maxSulyHal.suly} kg (${maxSulyHal.halfaj})' : '-'),
                            _StatisztikaSor(cim: 'Leghosszabb hal', ertek: (maxHosszHal != null && maxHosszHal.hossz != null) ? '${maxHosszHal.hossz} cm (${maxHosszHal.halfaj})' : '-'),
                          ],
                        ),
                      ),
                      
                      if (darab > 0)
                        _Kartya(
                          cim: 'Halak sorsa',
                          ikon: Icons.compare_arrows,
                          tartalom: Column(
                            children: [
                              _SorsSor(nev: 'Visszaengedett', db: visszaDb, osszes: darab, suly: visszaSuly, szin: Colors.greenAccent),
                              const SizedBox(height: 12),
                              _SorsSor(nev: 'Elvitt', db: elvittDb, osszes: darab, suly: elvittSuly, szin: Colors.orangeAccent),
                              const SizedBox(height: 12),
                              // ÚJ KÓD: Elajándékozott sor hozzáadása
                              _SorsSor(nev: 'Elajándékozott', db: elajandekozottDb, osszes: darab, suly: elajandekozottSuly, szin: Colors.blueAccent),
                              const SizedBox(height: 12),
                              _SorsSor(nev: 'Elpusztult', db: elpusztultDb, osszes: darab, suly: elpusztultSuly, szin: Colors.redAccent),
                            ],
                          ),
                        ),

                      if (halfajDb.isNotEmpty)
                        _Kartya(
                          cim: 'Halfajok megoszlása',
                          ikon: Icons.pie_chart,
                          tartalom: _TortadiagramNezet(adatok: halfajDb, osszesDb: darab),
                        ),

                      if (darab > 0)
                        _Kartya(
                          cim: 'Taktikai érdekességek',
                          ikon: Icons.lightbulb_outline,
                          tartalom: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StatisztikaSor(cim: 'Legjobb 3 órás idősáv', ertek: _legjobbIdosav(szurtFogasok)),
                              const Divider(color: Colors.white12),
                              _StatisztikaSor(cim: 'Legaktívabb Időjárás+Hőfok', ertek: _legjobbKombo(szurtFogasok, (f) {
                                if ((f.idojaras == null || f.idojaras!.isEmpty) && f.homerseklet == null) return '-';
                                String idoj = (f.idojaras != null && f.idojaras!.isNotEmpty) ? f.idojaras! : '-';
                                String ho = f.homerseklet != null ? '${f.homerseklet}°C' : '-';
                                return '$idoj / $ho';
                              })),
                              const Divider(color: Colors.white12),
                              _StatisztikaSor(cim: 'Legnyerőbb módszer', ertek: _legjobbKombo(szurtFogasok, (f) => f.modszer ?? '-')),
                              const Divider(color: Colors.white12),
                              _StatisztikaSor(cim: 'Legjobb horgászhely', ertek: _legjobbHelyszin(szurtFogasok)),
                              const Divider(color: Colors.white12),
                              
                              _StatisztikaSor(cim: 'Legjobb Kombináció (Koktél)', ertek: _legjobbKombo(szurtFogasok, (f) {
                                if (f.csali.isEmpty && f.etetoanyag.isEmpty) return '-';
                                String cs = f.csali.isNotEmpty ? f.csali.join(' & ') : '-';
                                String et = f.etetoanyag.isNotEmpty ? f.etetoanyag.join(' & ') : '-';
                                return '$cs + $et';
                              })),
                              
                              if (csaliStats.isNotEmpty) ...[
                                const Divider(color: Colors.white24, height: 32),
                                _buildTop3Blokk('TOP 3 CSALI', csaliStats),
                              ],
                              
                              if (etetoStats.isNotEmpty) ...[
                                const Divider(color: Colors.white24, height: 32),
                                _buildTop3Blokk('TOP 3 ETETŐANYAG', etetoStats),
                              ],
                            ],
                          ),
                        ),
                        
                      if (rekordLista.isNotEmpty)
                        _Kartya(
                          cim: 'Személyes Rekordok (Fajonként)',
                          ikon: Icons.emoji_events,
                          tartalom: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: rekordLista.map((f) {
                              String hosszSzoveg = (f.hossz != null && f.hossz! > 0) ? ' (${f.hossz} cm)' : '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(f.halfaj, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('${f.suly} kg$hosszSzoveg', style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HoldfazisAdat {
  final String nev;
  final String ikon;
  final int kapasIndex; 
  final String leiras;
  _HoldfazisAdat(this.nev, this.ikon, this.kapasIndex, this.leiras);
}

class _TagStat {
  int darab = 0;
  double osszsuly = 0.0;
  double get atlag => darab > 0 ? osszsuly / darab : 0.0;
}

class _Kartya extends StatelessWidget {
  final String cim;
  final IconData ikon;
  final Widget tartalom;
  const _Kartya({required this.cim, required this.ikon, required this.tartalom});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text(cim, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            tartalom,
          ],
        ),
      ),
    );
  }
}

class _StatisztikaSor extends StatelessWidget {
  final String cim;
  final String ertek;
  const _StatisztikaSor({required this.cim, required this.ertek});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(cim, style: const TextStyle(color: Colors.white54, fontSize: 14))),
          Expanded(flex: 3, child: Text(ertek, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _SorsSor extends StatelessWidget {
  final String nev;
  final int db;
  final int osszes;
  final double suly;
  final Color szin;
  const _SorsSor({required this.nev, required this.db, required this.osszes, required this.suly, required this.szin});

  @override
  Widget build(BuildContext context) {
    double szazalek = osszes > 0 ? (db / osszes) * 100 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nev, style: TextStyle(color: szin, fontWeight: FontWeight.bold)),
            Text('${szazalek.toStringAsFixed(1)}%  |  $db db  |  ${suly.toStringAsFixed(2)} kg', style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: osszes > 0 ? db / osszes : 0,
            backgroundColor: Colors.black26,
            color: szin,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

class _TortadiagramNezet extends StatelessWidget {
  final Map<String, int> adatok;
  final int osszesDb;
  const _TortadiagramNezet({required this.adatok, required this.osszesDb});

  @override
  Widget build(BuildContext context) {
    if (osszesDb == 0) return const SizedBox();
    final List<Color> szinek = [Colors.greenAccent, Colors.blueAccent, Colors.amber, Colors.pinkAccent, Colors.purpleAccent, Colors.cyan, Colors.orange, Colors.teal];
    int szinIndex = 0;
    List<Widget> jelmagyarazat = [];
    List<_PieSlice> szeletek = [];

    adatok.forEach((halfaj, db) {
      Color c = szinek[szinIndex % szinek.length];
      double szazalek = (db / osszesDb) * 100;
      szeletek.add(_PieSlice(value: db.toDouble(), color: c));
      jelmagyarazat.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(halfaj, style: const TextStyle(color: Colors.white70, fontSize: 13))),
              Text('${szazalek.toStringAsFixed(1)}% ($db db)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      );
      szinIndex++;
    });

    return Row(
      children: [
        SizedBox(width: 120, height: 120, child: CustomPaint(painter: _PieChartPainter(szeletek: szeletek, total: osszesDb.toDouble()))),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: jelmagyarazat)),
      ],
    );
  }
}

class _PieSlice {
  final double value;
  final Color color;
  _PieSlice({required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> szeletek;
  final double total;
  _PieChartPainter({required this.szeletek, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -pi / 2;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (var szelet in szeletek) {
      final sweepAngle = (szelet.value / total) * 2 * pi;
      final paint = Paint()..color = szelet.color..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
