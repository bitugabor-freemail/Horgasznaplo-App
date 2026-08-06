import 'dart:math';
import 'package:flutter/material.dart';
import 'fogasok.dart';
import 'modellek.dart'; // <--- Ezt be kellett hívni a Tura miatt
import 'adattarolo.dart'; // <--- Ezt be kellett hívni az adatbázis betöltéséhez

class StatisztikaScreen extends StatefulWidget {
  const StatisztikaScreen({super.key});

  @override
  State<StatisztikaScreen> createState() => _StatisztikaScreenState();
}

class _StatisztikaScreenState extends State<StatisztikaScreen> {
  // Szűrő feltételek
  String _kivalasztottEv = '2026';
  String? _szuroHalfaj;
  String? _szuroHelyszin;
  String? _szuroSors;
  
  // Valódi adatbázis listák a memóriában
  List<Tura> _osszesTura = [];
  List<Helyszin> _osszesHelyszin = [];
  List<Halfaj> _osszesHalfaj = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  // --- VALÓDI ADATOK BETÖLTÉSE ---
  Future<void> _adatokBetoltese() async {
    final turakAdat = await AdatTarolo.betoltes('turak_adatok');
    final helyszinekAdat = await AdatTarolo.betoltes('helyszinek_adatok');
    final halfajokAdat = await AdatTarolo.betoltes('halfajok_adatok');

    setState(() {
      _osszesTura = turakAdat.map((e) => Tura.fromJson(e)).toList();
      _osszesHelyszin = helyszinekAdat.map((e) => Helyszin.fromJson(e)).toList();
      _osszesHalfaj = halfajokAdat.map((e) => Halfaj.fromJson(e)).toList();
    });
  }
  
  // A szűrt adatok lekérése (Már a memóriába betöltött valódi túrákból)
  List<FogasModel> _getSzurtFogasok() {
    return FogasAdatbazis.fogasok.where((f) {
      // 1. Év szűrés (Alapértelmezett)
      bool evMatch = _kivalasztottEv == 'Összes' || f.datum.year.toString() == _kivalasztottEv;
      // 2. Részletes szűrők
      bool halfajMatch = _szuroHalfaj == null || f.halfaj == _szuroHalfaj;
      bool sorsMatch = _szuroSors == null || f.sors == _szuroSors;
      
      // Helyszín szűréséhez meg kell keresnünk a túrát
      bool helyszinMatch = true;
      if (_szuroHelyszin != null) {
        // Megkeressük a túrát az új memórialistából (ha nincs meg, null-t adunk vissza biztonságból)
        final keresettTura = _osszesTura.cast<Tura?>().firstWhere(
            (t) => t?.id == f.turaId, 
            orElse: () => null
        );

        if (keresettTura != null && keresettTura.helyszinId != null) {
          // Ha van túra és van helyszín ID, megkeressük a helyszín nevét
          final helyszin = _osszesHelyszin.cast<Helyszin?>().firstWhere(
            (h) => h?.id == keresettTura.helyszinId,
            orElse: () => null
          );
          
          helyszinMatch = helyszin?.nev == _szuroHelyszin;
        } else {
          helyszinMatch = false; // Ha nincs túra vagy nincs helyszín a túrában, akkor biztos nem egyezik
        }
      }

      return evMatch && halfajMatch && sorsMatch && helyszinMatch;
    }).toList();
  }

  void _nyitReszletesSzurok() {
    // Alap hal sorsok, ahogy eddig
    final sorsok = ['Visszaengedtem', 'Elvittem', 'Elpusztult'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Részletes Szűrők', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  const SizedBox(height: 16),
                  
                  // HALFAJOK AZ ÚJ ADATBÁZISBÓL (JAVÍTVA A STRING/OBJECT HIBA)
                  DropdownButtonFormField<String>(
                    value: _szuroHalfaj,
                    decoration: const InputDecoration(labelText: 'Halfaj', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Összes halfaj')),
                      ..._osszesHalfaj.map((h) => DropdownMenuItem<String>(value: h.nev, child: Text(h.nev))),
                    ],
                    onChanged: (val) => setModalState(() => _szuroHalfaj = val),
                  ),
                  const SizedBox(height: 16),
                  
                  // HELYSZÍNEK AZ ÚJ ADATBÁZISBÓL (JAVÍTVA A STRING/OBJECT HIBA)
                  DropdownButtonFormField<String>(
                    value: _szuroHelyszin,
                    decoration: const InputDecoration(labelText: 'Helyszín', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Összes helyszín')),
                      ..._osszesHelyszin.map((h) => DropdownMenuItem<String>(value: h.nev, child: Text(h.nev))),
                    ],
                    onChanged: (val) => setModalState(() => _szuroHelyszin = val),
                  ),
                  const SizedBox(height: 16),

                  // SORSOK (JAVÍTVA A STRING/OBJECT HIBA)
                  DropdownButtonFormField<String>(
                    value: _szuroSors,
                    decoration: const InputDecoration(labelText: 'Hal sorsa', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Összes')),
                      ...sorsok.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))),
                    ],
                    onChanged: (val) => setModalState(() => _szuroSors = val),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () {
                        setState(() {}); // Főképernyő frissítése
                        Navigator.pop(context);
                      },
                      child: const Text('Szűrés Alkalmazása', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- TAKTIKAI ELEMZŐ ALGORITMUSOK ---
  String _legjobbIdosav(List<FogasModel> fogasok) {
    if (fogasok.isEmpty) return '-';
    Map<int, int> idosavok = {};
    for (var f in fogasok) {
      int sav = (f.idopont.hour / 3).floor() * 3; // 0, 3, 6, 9...
      idosavok[sav] = (idosavok[sav] ?? 0) + 1;
    }
    var legjobb = idosavok.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${legjobb.key}:00 - ${legjobb.key + 3}:00 (${legjobb.value} db)';
  }

  String _legjobbKombo(List<FogasModel> fogasok, String Function(FogasModel) selector) {
    if (fogasok.isEmpty) return '-';
    Map<String, int> gyakorisag = {};
    for (var f in fogasok) {
      String kulcs = selector(f);
      if (kulcs.trim().isNotEmpty && kulcs != '-') {
        gyakorisag[kulcs] = (gyakorisag[kulcs] ?? 0) + 1;
      }
    }
    if (gyakorisag.isEmpty) return '-';
    var legjobb = gyakorisag.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${legjobb.key} (${legjobb.value} db)';
  }

  @override
  Widget build(BuildContext context) {
    final szurtFogasok = _getSzurtFogasok();
    
    // Alap statisztikák
    int darab = szurtFogasok.length;
    double osszsuly = szurtFogasok.fold(0.0, (sum, f) => sum + f.suly);
    double atlagsuly = darab > 0 ? osszsuly / darab : 0.0;
    
    FogasModel? maxSulyHal;
    FogasModel? maxHosszHal;
    if (darab > 0) {
      maxSulyHal = szurtFogasok.reduce((a, b) => a.suly > b.suly ? a : b);
      maxHosszHal = szurtFogasok.reduce((a, b) => a.hossz > b.hossz ? a : b);
    }

    // Túrák száma (egyedi túra ID-k a szűrt fogások alapján)
    int turakSzama = szurtFogasok.map((f) => f.turaId).toSet().length;

    // Sors arányok
    int visszaDb = szurtFogasok.where((f) => f.sors == 'Visszaengedtem').length;
    int elvittDb = szurtFogasok.where((f) => f.sors == 'Elvittem').length;
    int elpusztultDb = szurtFogasok.where((f) => f.sors == 'Elpusztult').length;

    double visszaSuly = szurtFogasok.where((f) => f.sors == 'Visszaengedtem').fold(0.0, (s, f) => s + f.suly);
    double elvittSuly = szurtFogasok.where((f) => f.sors == 'Elvittem').fold(0.0, (s, f) => s + f.suly);
    double elpusztultSuly = szurtFogasok.where((f) => f.sors == 'Elpusztult').fold(0.0, (s, f) => s + f.suly);

    // Halfaj tortadiagram adatok
    Map<String, int> halfajDb = {};
    for (var f in szurtFogasok) {
      halfajDb[f.halfaj] = (halfajDb[f.halfaj] ?? 0) + 1;
    }
    
    bool isSzurt = _szuroHalfaj != null || _szuroHelyszin != null || _szuroSors != null;

    return Scaffold(
      body: Column(
        children: [
          // Felső szűrő sáv
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161616),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _kivalasztottEv,
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  items: ['Összes', '2025', '2026'].map((ev) => DropdownMenuItem(value: ev, child: Text('$ev. év'))).toList(),
                  onChanged: (val) => setState(() => _kivalasztottEv = val!),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSzurt ? Colors.green[800] : Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Részletes szűrők'),
                  onPressed: _nyitReszletesSzurok,
                ),
              ],
            ),
          ),
          
          if (isSzurt)
            Container(
              width: double.infinity,
              color: Colors.green[900]?.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Center(child: Text('Aktív szűrés van érvényben!', style: TextStyle(color: Colors.greenAccent, fontSize: 12))),
            ),

          Expanded(
            child: szurtFogasok.isEmpty
                ? const Center(child: Text('Nincs adat a megadott szűrések alapján.', style: TextStyle(color: Colors.white54)))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // 1. ÖSSZESÍTÉS KÁRTYA
                      _Kartya(
                        cim: 'Alap statisztika',
                        ikon: Icons.analytics,
                        tartalom: Column(
                          children: [
                            _StatisztikaSor(cim: 'Érintett túrák száma', ertek: '$turakSzama alkalom'),
                            _StatisztikaSor(cim: 'Kifogott halak', ertek: '$darab db'),
                            _StatisztikaSor(cim: 'Összsúly', ertek: '${osszsuly.toStringAsFixed(2)} kg'),
                            _StatisztikaSor(cim: 'Átlagsúly', ertek: '${atlagsuly.toStringAsFixed(2)} kg'),
                            const Divider(color: Colors.white24),
                            _StatisztikaSor(cim: 'Legnagyobb hal', ertek: maxSulyHal != null ? '${maxSulyHal.suly} kg (${maxSulyHal.halfaj})' : '-'),
                            _StatisztikaSor(cim: 'Leghosszabb hal', ertek: maxHosszHal != null ? '${maxHosszHal.hossz} cm (${maxHosszHal.halfaj})' : '-'),
                          ],
                        ),
                      ),
                      
                      // 2. SORS ARÁNYOK (KÖTELEZŐ DB SZÁMMAL)
                      _Kartya(
                        cim: 'Halak sorsa',
                        ikon: Icons.compare_arrows,
                        tartalom: Column(
                          children: [
                            _SorsSor(nev: 'Visszaengedett', db: visszaDb, osszes: darab, suly: visszaSuly, szin: Colors.greenAccent),
                            const SizedBox(height: 8),
                            _SorsSor(nev: 'Elvitt', db: elvittDb, osszes: darab, suly: elvittSuly, szin: Colors.orangeAccent),
                            const SizedBox(height: 8),
                            _SorsSor(nev: 'Elpusztult', db: elpusztultDb, osszes: darab, suly: elpusztultSuly, szin: Colors.redAccent),
                          ],
                        ),
                      ),

                      // 3. TORTADIAGRAM
                      _Kartya(
                        cim: 'Halfajok megoszlása',
                        ikon: Icons.pie_chart,
                        tartalom: _TortadiagramNezet(adatok: halfajDb, osszesDb: darab),
                      ),

                      // 4. TAKTIKAI ÉRDEKESSÉGEK (Algoritmusok alapján)
                      _Kartya(
                        cim: 'Taktikai érdekességek',
                        ikon: Icons.lightbulb_outline,
                        tartalom: Column(
                          children: [
                            _StatisztikaSor(cim: 'Legjobb 3 órás idősáv', ertek: _legjobbIdosav(szurtFogasok)),
                            _StatisztikaSor(cim: 'Legjobb csali', ertek: _legjobbKombo(szurtFogasok, (f) => f.csali.isNotEmpty ? f.csali.first : '-')),
                            _StatisztikaSor(cim: 'Legjobb módszer', ertek: _legjobbKombo(szurtFogasok, (f) => f.modszer)),
                            _StatisztikaSor(cim: 'Legjobb időjárás', ertek: _legjobbKombo(szurtFogasok, (f) => f.idojaras)),
                          ],
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

// --- SEGÉD WIDGETEK A STATISZTIKÁHOZ ---

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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(cim, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(ertek, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
            Text('${szazalek.toStringAsFixed(1)}%  |  $db db  |  ${suly.toStringAsFixed(2)} kg', style: const TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: osszes > 0 ? db / osszes : 0,
          backgroundColor: Colors.black26,
          color: szin,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

// --- EGYEDI TORTADIAGRAM RAJZOLÓ ---
class _TortadiagramNezet extends StatelessWidget {
  final Map<String, int> adatok;
  final int osszesDb;

  const _TortadiagramNezet({required this.adatok, required this.osszesDb});

  @override
  Widget build(BuildContext context) {
    if (osszesDb == 0) return const SizedBox();

    final List<Color> szinek = [
      Colors.greenAccent, Colors.blueAccent, Colors.amber, 
      Colors.pinkAccent, Colors.purpleAccent, Colors.cyan, 
      Colors.orange, Colors.teal
    ];

    int szinIndex = 0;
    List<Widget> jelmagyarazat = [];
    List<_PieSlice> szeletek = [];

    adatok.forEach((halfaj, db) {
      Color c = szinek[szinIndex % szinek.length];
      double szazalek = (db / osszesDb) * 100;
      
      szeletek.add(_PieSlice(value: db.toDouble(), color: c));
      jelmagyarazat.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(halfaj, style: const TextStyle(color: Colors.white70))),
              Text('${szazalek.toStringAsFixed(1)}% ($db db)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
      szinIndex++;
    });

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _PieChartPainter(szeletek: szeletek, total: osszesDb.toDouble()),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: jelmagyarazat,
          ),
        ),
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
    double startAngle = -pi / 2; // Felülről indul
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (var szelet in szeletek) {
      final sweepAngle = (szelet.value / total) * 2 * pi;
      final paint = Paint()
        ..color = szelet.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
