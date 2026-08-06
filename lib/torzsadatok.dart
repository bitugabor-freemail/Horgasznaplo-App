import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'adattarolo.dart';
import 'modellek.dart';

class TorzsadatokScreen extends StatefulWidget {
  const TorzsadatokScreen({super.key});

  @override
  State<TorzsadatokScreen> createState() => _TorzsadatokScreenState();
}

class _TorzsadatokScreenState extends State<TorzsadatokScreen> {
  // A 10 fix kategória neve
  final List<String> _kategoriak = [
    'Halfaj', 'Horgászbot', 'Horgászmódszer', 'Végszerelék', 
    'Csali', 'Etetőanyag', 'Helyszín', 'Horgásztársak', 'Időjárás', 'Hal sorsa'
  ];
  String _aktivKategoria = 'Halfaj';

  // Adatbázisok a memóriában
  List<Halfaj> _halfajok = [];
  List<Helyszin> _helyszinek = [];
  Map<String, List<String>> _szovegesAdatok = {};
  
  // A frissítésekhez szükséges teljes adatbázis
  List<Tura> _turak = [];
  List<FogasModel> _fogasok = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    _halfajok = await AdatTarolo.halfajokBetoltese();
    _helyszinek = await AdatTarolo.helyszinekBetoltese();
    _turak = await AdatTarolo.turakBetoltese();
    _fogasok = await AdatTarolo.fogasokBetoltese();

    _szovegesAdatok['Horgászbot'] = await AdatTarolo.botokBetoltese();
    _szovegesAdatok['Horgászmódszer'] = await AdatTarolo.modszerekBetoltese();
    _szovegesAdatok['Végszerelék'] = await AdatTarolo.szerelekekBetoltese();
    _szovegesAdatok['Csali'] = await AdatTarolo.csalikBetoltese();
    _szovegesAdatok['Etetőanyag'] = await AdatTarolo.etetoanyagokBetoltese();
    _szovegesAdatok['Horgásztársak'] = await AdatTarolo.tarsakBetoltese();
    _szovegesAdatok['Időjárás'] = await AdatTarolo.idojarasBetoltese();
    _szovegesAdatok['Hal sorsa'] = await AdatTarolo.sorsBetoltese();

    // Ha üres a Hal sorsa, adunk neki alapértelmezettet
    if (_szovegesAdatok['Hal sorsa']!.isEmpty) {
      _szovegesAdatok['Hal sorsa'] = ['Visszaengedtem', 'Elvittem', 'Elpusztult'];
      AdatTarolo.sorsMentes(_szovegesAdatok['Hal sorsa']!);
    }

    setState(() {});
  }

  // --- VISSZAMENŐLEGES FRISSÍTÉS LOGIKÁJA ---
  Future<void> _visszamenolegesFrissites(String kategoria, String regiNev, String? ujNev) async {
    bool turakValtoztak = false;
    bool fogasokValtoztak = false;

    // 1. Túrák frissítése (Társak érintettek)
    if (kategoria == 'Horgásztársak') {
      for (var t in _turak) {
        if (t.horgasztarsak.contains(regiNev)) {
          t.horgasztarsak.remove(regiNev);
          if (ujNev != null) t.horgasztarsak.add(ujNev);
          turakValtoztak = true;
        }
      }
    }

    // 2. Fogások frissítése
    for (var f in _fogasok) {
      if (kategoria == 'Halfaj' && f.halfaj == regiNev) {
        f.halfaj = ujNev ?? ''; 
        fogasokValtoztak = true;
      } else if (kategoria == 'Hal sorsa' && f.sors == regiNev) {
        f.sors = ujNev ?? 'Visszaengedtem'; 
        fogasokValtoztak = true;
      } else if (kategoria == 'Horgászbot' && f.bot == regiNev) {
        f.bot = ujNev ?? ''; 
        fogasokValtoztak = true;
      } else if (kategoria == 'Horgászmódszer' && f.modszer == regiNev) {
        f.modszer = ujNev ?? ''; 
        fogasokValtoztak = true;
      } else if (kategoria == 'Végszerelék' && f.szerelek == regiNev) {
        f.szerelek = ujNev ?? ''; 
        fogasokValtoztak = true;
      } else if (kategoria == 'Időjárás' && f.idojaras == regiNev) {
        f.idojaras = ujNev ?? ''; 
        fogasokValtoztak = true;
      } else if (kategoria == 'Csali' && f.csali.contains(regiNev)) {
        f.csali.remove(regiNev);
        if (ujNev != null) f.csali.add(ujNev);
        fogasokValtoztak = true;
      } else if (kategoria == 'Etetőanyag' && f.etetoanyag.contains(regiNev)) {
        f.etetoanyag.remove(regiNev);
        if (ujNev != null) f.etetoanyag.add(ujNev);
        fogasokValtoztak = true;
      }
    }

    if (turakValtoztak) await AdatTarolo.turakMentes(_turak);
    if (fogasokValtoztak) await AdatTarolo.fogasokMentes(_fogasok);
  }

  // --- MENTÉSEK ÉS ABLAKOK ---
  void _ujSzovegesAdat([String? szerkeszthetoNev, int? index]) {
    final vezerlo = TextEditingController(text: szerkeszthetoNev);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(szerkeszthetoNev == null ? 'Új $_aktivKategoria' : '$_aktivKategoria Szerkesztése'),
        content: TextField(
          controller: vezerlo,
          decoration: InputDecoration(labelText: '$_aktivKategoria megnevezése'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (vezerlo.text.trim().isNotEmpty) {
                final ujNev = vezerlo.text.trim();
                setState(() {
                  if (szerkeszthetoNev == null) {
                    _szovegesAdatok[_aktivKategoria]!.add(ujNev);
                  } else {
                    _szovegesAdatok[_aktivKategoria]![index!] = ujNev;
                  }
                });
                
                // Mentsük le a megfelelő kategóriába
                switch (_aktivKategoria) {
                  case 'Horgászbot': await AdatTarolo.botokMentes(_szovegesAdatok[_aktivKategoria]!); break;
                  case 'Horgászmódszer': await AdatTarolo.modszerekMentes(_szovegesAdatok[_aktivKategoria]!); break;
                  case 'Végszerelék': await AdatTarolo.szerelekekMentes(_szovegesAdatok[_aktivKategoria]!); break;
                  case 'Csali': await AdatTarolo.csalikMentes(_szovegesAdatok[_aktivKategoria]!); break;
                  case 'Etetőanyag': await AdatTarolo.etetoanyagokMentes(_szovegesAdatok[_aktivKategoria]!); break;
                  case 'Horgásztársak': await AdatTarolo.tarsakMentes(_szovegesAdatok[_aktivKategoria]!); break;
                  case 'Időjárás': await AdatTarolo.idojarasMentes(_szovegesAdatok[_aktivKategoria]!); break;
                  case 'Hal sorsa': await AdatTarolo.sorsMentes(_szovegesAdatok[_aktivKategoria]!); break;
                }

                // Ha szerkesztettünk, frissítsük a múltat!
                if (szerkeszthetoNev != null && szerkeszthetoNev != ujNev) {
                  await _visszamenolegesFrissites(_aktivKategoria, szerkeszthetoNev, ujNev);
                }
                
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ujHelyszin([Helyszin? szerkeszthetoHelyszin, int? index]) {
    final nevVezerlo = TextEditingController(text: szerkeszthetoHelyszin?.nev);
    final kodVezerlo = TextEditingController(text: szerkeszthetoHelyszin?.vizterKod);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(szerkeszthetoHelyszin == null ? 'Új Helyszín' : 'Helyszín Szerkesztése'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nevVezerlo, decoration: const InputDecoration(labelText: 'Helyszín neve * (kötelező)')),
            TextField(controller: kodVezerlo, decoration: const InputDecoration(labelText: 'Víztér kódja (opcionális)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (nevVezerlo.text.trim().isNotEmpty) {
                final ujHelyszin = Helyszin(
                  id: szerkeszthetoHelyszin?.id ?? DateTime.now().toString(),
                  nev: nevVezerlo.text.trim(),
                  vizterKod: kodVezerlo.text.trim(),
                );

                setState(() {
                  if (szerkeszthetoHelyszin == null) {
                    _helyszinek.add(ujHelyszin);
                  } else {
                    _helyszinek[index!] = ujHelyszin;
                  }
                });
                
                await AdatTarolo.helyszinekMentes(_helyszinek);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ujHalfaj([Halfaj? szerkeszthetoHal, int? index]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HalfajSzerkesztoScreen(
          meglevoHal: szerkeszthetoHal,
          mentesCallback: (ujHal) async {
            setState(() {
              if (szerkeszthetoHal == null) {
                _halfajok.add(ujHal);
              } else {
                _halfajok[index!] = ujHal;
              }
            });
            await AdatTarolo.halfajokMentes(_halfajok);

            if (szerkeszthetoHal != null && szerkeszthetoHal.nev != ujHal.nev) {
              await _visszamenolegesFrissites('Halfaj', szerkeszthetoHal.nev, ujHal.nev);
            }
          },
        ),
      ),
    );
  }

  void _torlesJovahagyas(String megnevezes, VoidCallback torlesFuggveny) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Törlés megerősítése'),
        content: Text('Biztosan törlöd a következőt: $megnevezes?\n\nEz eltávolítja az eddigi túrákból és fogásokból is!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              torlesFuggveny();
              Navigator.pop(context);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Törzsadatok Kezelése')),
      body: Column(
        children: [
          // Kategória választó
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161616),
            child: DropdownButton<String>(
              value: _aktivKategoria,
              isExpanded: true,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              underline: const SizedBox(),
              items: _kategoriak.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (val) => setState(() => _aktivKategoria = val!),
            ),
          ),
          
          // Lista megjelenítése a kategória alapján
          Expanded(
            child: Builder(
              builder: (context) {
                if (_aktivKategoria == 'Halfaj') {
                  return ListView.builder(
                    itemCount: _halfajok.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(_halfajok[i].nev, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _ujHalfaj(_halfajok[i], i)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _torlesJovahagyas(_halfajok[i].nev, () async {
                              final nev = _halfajok[i].nev;
                              setState(() => _halfajok.removeAt(i));
                              await AdatTarolo.halfajokMentes(_halfajok);
                              await _visszamenolegesFrissites('Halfaj', nev, null);
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (_aktivKategoria == 'Helyszín') {
                  return ListView.builder(
                    itemCount: _helyszinek.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(_helyszinek[i].nev, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _ujHelyszin(_helyszinek[i], i)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _torlesJovahagyas(_helyszinek[i].nev, () async {
                              final id = _helyszinek[i].id;
                              setState(() => _helyszinek.removeAt(i));
                              await AdatTarolo.helyszinekMentes(_helyszinek);
                              // Helyszín ID törlése a túrákból
                              for (var t in _turak) { if (t.helyszinId == id) t.helyszinId = null; }
                              await AdatTarolo.turakMentes(_turak);
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final adatok = _szovegesAdatok[_aktivKategoria] ?? [];
                  return ListView.builder(
                    itemCount: adatok.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(adatok[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _ujSzovegesAdat(adatok[i], i)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _torlesJovahagyas(adatok[i], () async {
                              final nev = adatok[i];
                              setState(() => adatok.removeAt(i));
                              // Mentés a megfelelő kategóriába (itt rövidítve)
                              await _visszamenolegesFrissites(_aktivKategoria, nev, null);
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () {
          if (_aktivKategoria == 'Halfaj') {
            _ujHalfaj();
          } else if (_aktivKategoria == 'Helyszín') {
            _ujHelyszin();
          } else {
            _ujSzovegesAdat();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---- HALFAJ SZERKESZTŐ / HOZZÁADÓ KÉPERNYŐ (Specifikáció alapján) ----
class HalfajSzerkesztoScreen extends StatefulWidget {
  final Halfaj? meglevoHal;
  final Function(Halfaj) mentesCallback;

  const HalfajSzerkesztoScreen({super.key, this.meglevoHal, required this.mentesCallback});

  @override
  State<HalfajSzerkesztoScreen> createState() => _HalfajSzerkesztoScreenState();
}

class _HalfajSzerkesztoScreenState extends State<HalfajSzerkesztoScreen> {
  late TextEditingController _nevCtrl, _meretCtrl, _darabCtrl, _tilalomCtrl, _evCtrl, _megjegyzesCtrl;
  String _kategoria = 'Békés';
  String _statusz = 'Fogható';
  List<String> _kepUtvonalak = [];

  @override
  void initState() {
    super.initState();
    _nevCtrl = TextEditingController(text: widget.meglevoHal?.nev);
    _meretCtrl = TextEditingController(text: widget.meglevoHal?.meretKorlatozas);
    _darabCtrl = TextEditingController(text: widget.meglevoHal?.darabKorlatozas);
    _tilalomCtrl = TextEditingController(text: widget.meglevoHal?.tilalmiIdoszak);
    _evCtrl = TextEditingController(text: widget.meglevoHal?.szabalyozasEve);
    _megjegyzesCtrl = TextEditingController(text: widget.meglevoHal?.megjegyzes);
    _kategoria = widget.meglevoHal?.kategoria ?? 'Békés';
    _statusz = widget.meglevoHal?.statusz ?? 'Fogható';
    _kepUtvonalak = List.from(widget.meglevoHal?.kepek ?? []);
  }

  Future<void> _kepHozzaadasa() async {
    final picker = ImagePicker();
    final List<XFile> kepek = await picker.pickMultiImage();
    if (kepek.isNotEmpty) {
      setState(() => _kepUtvonalak.addAll(kepek.map((k) => k.path)));
    }
  }

  void _mentes() {
    if (_nevCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A hal neve kötelező!')));
      return;
    }

    final ujHal = Halfaj(
      id: widget.meglevoHal?.id ?? DateTime.now().toString(),
      nev: _nevCtrl.text.trim(),
      kategoria: _kategoria,
      statusz: _statusz,
      meretKorlatozas: _meretCtrl.text.trim(),
      darabKorlatozas: _darabCtrl.text.trim(),
      tilalmiIdoszak: _tilalomCtrl.text.trim(),
      szabalyozasEve: _evCtrl.text.trim(),
      megjegyzes: _megjegyzesCtrl.text.trim(),
      kepek: _kepUtvonalak,
    );

    widget.mentesCallback(ujHal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.meglevoHal == null ? 'Új Halfaj' : 'Halfaj Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nevCtrl, decoration: const InputDecoration(labelText: 'Hal neve * (kötelező)')),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _kategoria,
              decoration: const InputDecoration(labelText: 'Kategória'),
              items: ['Békés', 'Ragadozó'].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (val) => setState(() => _kategoria = val!),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _statusz,
              decoration: const InputDecoration(labelText: 'Státusz'),
              items: ['Fogható', 'Védett', 'Inváziós', 'Nem fogható'].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (val) => setState(() => _statusz = val!),
            ),

            TextField(controller: _meretCtrl, decoration: const InputDecoration(labelText: 'Méretkorlátozás (cm)')),
            TextField(controller: _darabCtrl, decoration: const InputDecoration(labelText: 'Napi darabszámkorlátozás')),
            TextField(controller: _tilalomCtrl, decoration: const InputDecoration(labelText: 'Tilalmi időszak')),
            TextField(controller: _evCtrl, decoration: const InputDecoration(labelText: 'Szabályozás éve')),
            TextField(
              controller: _megjegyzesCtrl, 
              maxLines: 3, 
              decoration: const InputDecoration(labelText: 'Megjegyzés / Leírás (Élőhely, táplálék, stb.)')
            ),
            
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Képek hozzáadása'),
              onPressed: _kepHozzaadasa,
            ),
            if (_kepUtvonalak.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _kepUtvonalak.map((path) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() => _kepUtvonalak.remove(path)),
                    )
                  ],
                )).toList(),
              )
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.all(16)),
              onPressed: _mentes,
              child: const Text('HALFAJ MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
