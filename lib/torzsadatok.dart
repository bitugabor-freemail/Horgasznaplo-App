import 'package:flutter/material.dart';
import 'adattarolo.dart';
import 'modellek.dart';

// --- 1. A HIÁNYZÓ FŐKÉPERNYŐ (Kategóriák listázása és kezelése) ---
class TorzsadatokScreen extends StatefulWidget {
  const TorzsadatokScreen({super.key});

  @override
  State<TorzsadatokScreen> createState() => _TorzsadatokScreenState();
}

class _TorzsadatokScreenState extends State<TorzsadatokScreen> {
  final List<String> _kategoriak = [
    'Halfaj',
    'Horgászbot',
    'Horgászmódszer',
    'Végszerelék',
    'Csali',
    'Etetőanyag',
    'Helyszín',
    'Horgásztársak',
    'Időjárás',
    'Hal sorsa'
  ];
  
  String _kivKategoria = 'Halfaj';
  
  List<Halfaj> _halfajok = [];
  List<Helyszin> _helyszinek = [];
  List<String> _simaLista = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    if (_kivKategoria == 'Halfaj') {
      _halfajok = await AdatTarolo.halfajokBetoltese();
    } else if (_kivKategoria == 'Helyszín') {
      _helyszinek = await AdatTarolo.helyszinekBetoltese();
    } else {
      switch (_kivKategoria) {
        case 'Horgászbot': _simaLista = await AdatTarolo.botokBetoltese(); break;
        case 'Horgászmódszer': _simaLista = await AdatTarolo.modszerekBetoltese(); break;
        case 'Végszerelék': _simaLista = await AdatTarolo.szerelekekBetoltese(); break;
        case 'Csali': _simaLista = await AdatTarolo.csalikBetoltese(); break;
        case 'Etetőanyag': _simaLista = await AdatTarolo.etetoanyagokBetoltese(); break;
        case 'Horgásztársak': _simaLista = await AdatTarolo.tarsakBetoltese(); break;
        case 'Időjárás': _simaLista = await AdatTarolo.idojarasBetoltese(); break;
        case 'Hal sorsa': _simaLista = await AdatTarolo.sorsBetoltese(); break;
      }
    }
    setState(() {});
  }

  Future<void> _simaAdatMentes() async {
    switch (_kivKategoria) {
      case 'Horgászbot': await AdatTarolo.botokMentes(_simaLista); break;
      case 'Horgászmódszer': await AdatTarolo.modszerekMentes(_simaLista); break;
      case 'Végszerelék': await AdatTarolo.szerelekekMentes(_simaLista); break;
      case 'Csali': await AdatTarolo.csalikMentes(_simaLista); break;
      case 'Etetőanyag': await AdatTarolo.etetoanyagokMentes(_simaLista); break;
      case 'Horgásztársak': await AdatTarolo.tarsakMentes(_simaLista); break;
      case 'Időjárás': await AdatTarolo.idojarasMentes(_simaLista); break;
      case 'Hal sorsa': await AdatTarolo.sorsMentes(_simaLista); break;
    }
  }

  void _simaAdatHozzaadasVagySzerkesztes([String? regiNev, int? index]) {
    final ctrl = TextEditingController(text: regiNev ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(regiNev == null ? 'Új $_kivKategoria hozzáadása' : '$_kivKategoria szerkesztése'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Megnevezés')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final nev = ctrl.text.trim();
                if (regiNev == null) {
                  _simaLista.add(nev);
                } else if (index != null) {
                  _simaLista[index] = nev;
                }
                await _simaAdatMentes();
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

  void _helyszinHozzaadasVagySzerkesztes([Helyszin? regiHelyszin, int? index]) {
    final nevCtrl = TextEditingController(text: regiHelyszin?.nev ?? '');
    final kodCtrl = TextEditingController(text: regiHelyszin?.vizterKod ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(regiHelyszin == null ? 'Új Helyszín hozzáadása' : 'Helyszín szerkesztése'),
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
                  id: regiHelyszin?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  nev: nevCtrl.text.trim(),
                  vizterKod: kodCtrl.text.trim(),
                );
                if (regiHelyszin == null) {
                  _helyszinek.add(ujHelyszin);
                } else if (index != null) {
                  _helyszinek[index] = ujHelyszin;
                }
                await AdatTarolo.helyszinekMentes(_helyszinek);
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

  void _adatTorlese(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Törlés'),
        content: const Text('Biztosan törölni szeretnéd ezt a törzsadatot? (A már rögzített túráknál és fogásoknál a megfelelő rublika üres marad, amíg nem választasz másikat.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              if (_kivKategoria == 'Halfaj') {
                _halfajok.removeAt(index);
                await AdatTarolo.halfajokMentes(_halfajok);
              } else if (_kivKategoria == 'Helyszín') {
                _helyszinek.removeAt(index);
                await AdatTarolo.helyszinekMentes(_helyszinek);
              } else {
                _simaLista.removeAt(index);
                await _simaAdatMentes();
              }
              setState(() {});
              if (mounted) Navigator.pop(context);
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF161616),
            child: Row(
              children: [
                const Text('Kategória:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _kivKategoria,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    items: _kategoriak.map((k) => DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _kivKategoria = val);
                        _adatokBetoltese();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _kivKategoria == 'Halfaj' ? _halfajok.length : (_kivKategoria == 'Helyszín' ? _helyszinek.length : _simaLista.length),
              itemBuilder: (context, index) {
                String megjelenitettNev = '';
                if (_kivKategoria == 'Halfaj') {
                  megjelenitettNev = _halfajok[index].nev;
                } else if (_kivKategoria == 'Helyszín') {
                  megjelenitettNev = _helyszinek[index].nev;
                } else {
                  megjelenitettNev = _simaLista[index];
                }

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(megjelenitettNev, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () {
                            if (_kivKategoria == 'Halfaj') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => HalfajSzerkesztoScreen(
                                szerkeszthetoHalfaj: _halfajok[index],
                                mentesCallback: (modositottHal) async {
                                  _halfajok[index] = modositottHal;
                                  await AdatTarolo.halfajokMentes(_halfajok);
                                  setState(() {});
                                },
                              )));
                            } else if (_kivKategoria == 'Helyszín') {
                              _helyszinHozzaadasVagySzerkesztes(_helyszinek[index], index);
                            } else {
                              _simaAdatHozzaadasVagySzerkesztes(_simaLista[index], index);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _adatTorlese(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (_kivKategoria == 'Halfaj') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HalfajSzerkesztoScreen(
              mentesCallback: (ujHal) async {
                _halfajok.add(ujHal);
                await AdatTarolo.halfajokMentes(_halfajok);
                setState(() {});
              },
            )));
          } else if (_kivKategoria == 'Helyszín') {
            _helyszinHozzaadasVagySzerkesztes();
          } else {
            _simaAdatHozzaadasVagySzerkesztes();
          }
        },
      ),
    );
  }
}

// --- 2. A TE EREDETI ŰRLAPOD (Felokosítva a szerkesztéshez) ---
class HalfajSzerkesztoScreen extends StatefulWidget {
  final Halfaj? szerkeszthetoHalfaj;
  final Function(Halfaj) mentesCallback;

  const HalfajSzerkesztoScreen({super.key, this.szerkeszthetoHalfaj, required this.mentesCallback});

  @override
  State<HalfajSzerkesztoScreen> createState() => _HalfajSzerkesztoScreenState();
}

class _HalfajSzerkesztoScreenState extends State<HalfajSzerkesztoScreen> {
  final _nevCtrl = TextEditingController();
  final _meretCtrl = TextEditingController();
  final _darabCtrl = TextEditingController();
  final _tilalomCtrl = TextEditingController();
  final _evCtrl = TextEditingController(text: '2024');
  final _megjegyzesCtrl = TextEditingController();

  String? _kivalasztottKategoria;
  String? _kivalasztottStatusz;

  final List<String> _kategoriak = ['Békés', 'Ragadozó'];
  final List<String> _statuszok = ['Fogható', 'Nem fogható', 'Védett', 'Inváziós'];

  @override
  void initState() {
    super.initState();
    // Ha szerkesztünk egy meglévő halat, itt betöltjük az adatait
    if (widget.szerkeszthetoHalfaj != null) {
      final h = widget.szerkeszthetoHalfaj!;
      _nevCtrl.text = h.nev;
      _kivalasztottKategoria = h.kategoria.isNotEmpty ? h.kategoria : null;
      _kivalasztottStatusz = h.statusz.isNotEmpty ? h.statusz : null;
      _meretCtrl.text = h.meretKorlatozas;
      _darabCtrl.text = h.darabKorlatozas;
      _tilalomCtrl.text = h.tilalmiIdoszak;
      _evCtrl.text = h.szabalyozasEve;
      _megjegyzesCtrl.text = h.megjegyzes;
    }
  }

  void _mentes() {
    if (_nevCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A hal neve kötelező!')));
      return;
    }

    final ujHalfaj = Halfaj(
      id: widget.szerkeszthetoHalfaj?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nev: _nevCtrl.text.trim(),
      kategoria: _kivalasztottKategoria ?? '',
      statusz: _kivalasztottStatusz ?? '',
      meretKorlatozas: _meretCtrl.text.trim(),
      darabKorlatozas: _darabCtrl.text.trim(),
      tilalmiIdoszak: _tilalomCtrl.text.trim(),
      szabalyozasEve: _evCtrl.text.trim(),
      megjegyzes: _megjegyzesCtrl.text.trim(),
      kepek: widget.szerkeszthetoHalfaj?.kepek ?? [],
    );

    widget.mentesCallback(ujHalfaj);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.szerkeszthetoHalfaj == null ? 'Új Halfaj Hozzáadása' : 'Halfaj Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nevCtrl, autofocus: widget.szerkeszthetoHalfaj == null, decoration: const InputDecoration(labelText: 'Halfaj neve *', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kivalasztottKategoria,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategória', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Válassz kategóriát --')),
                ..._kategoriak.map((k) => DropdownMenuItem(value: k, child: Text(k))),
              ],
              onChanged: (val) => setState(() => _kivalasztottKategoria = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kivalasztottStatusz,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Státusz', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Válassz státuszt --')),
                ..._statuszok.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (val) => setState(() => _kivalasztottStatusz = val),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _meretCtrl, decoration: const InputDecoration(labelText: 'Méretkorlátozás (pl. 30 cm)', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _darabCtrl, decoration: const InputDecoration(labelText: 'Darabkorlát (pl. 3 db)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _tilalomCtrl, decoration: const InputDecoration(labelText: 'Tilalmi időszak (pl. 05.02 - 05.31)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _evCtrl, decoration: const InputDecoration(labelText: 'Szabályozás éve', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _megjegyzesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Leírás / Megjegyzés', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _mentes,
              child: const Text('HALFAJ MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
