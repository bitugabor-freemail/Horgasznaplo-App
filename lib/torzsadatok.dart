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
  List<Helyszin> _helyszinek = [];
  List<Halfaj> _halfajok = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final helyszinAdatok = await AdatTarolo.betoltes('helyszinek_adatok');
    final halfajAdatok = await AdatTarolo.betoltes('halfajok_adatok');

    setState(() {
      _helyszinek = helyszinAdatok.map((e) => Helyszin.fromJson(e)).toList();
      _halfajok = halfajAdatok.map((e) => Halfaj.fromJson(e)).toList();
    });
  }

  Future<void> _helyszinMentes() async {
    await AdatTarolo.helyszinekMentes(_helyszinek);
  }

  Future<void> _halfajMentes() async {
    await AdatTarolo.halfajokMentes(_halfajok);
  }

  void _ujHelyszin() {
    final vezarlo = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új Helyszín', style: TextStyle(color: Colors.greenAccent)),
        content: TextField(
          controller: vezarlo,
          decoration: const InputDecoration(labelText: 'Helyszín neve'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              if (vezarlo.text.isNotEmpty) {
                setState(() {
                  _helyszinek.add(Helyszin(id: DateTime.now().toString(), nev: vezarlo.text));
                });
                _helyszinMentes();
                Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ujHalfaj() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HalfajSzerkesztoScreen(
          mentesCallback: (ujHal) {
            setState(() {
              _halfajok.add(ujHal);
            });
            _halfajMentes();
          },
        ),
      ),
    );
  }

  void _torlesHelyszin(int index) {
    setState(() => _helyszinek.removeAt(index));
    _helyszinMentes();
  }

  void _torlesHalfaj(int index) {
    setState(() => _halfajok.removeAt(index));
    _halfajMentes();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Törzsadatok'),
          bottom: const TabBar(
            indicatorColor: Colors.greenAccent,
            tabs: [
              Tab(icon: Icon(Icons.location_on), text: 'Helyszínek'),
              Tab(icon: Icon(Icons.set_meal), text: 'Halfajok'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // HELYSZÍNEK TAB
            _helyszinek.isEmpty
                ? const Center(child: Text('Nincs rögzített helyszín.'))
                : ListView.builder(
                    itemCount: _helyszinek.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(_helyszinek[i].nev),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _torlesHelyszin(i),
                      ),
                    ),
                  ),
            // HALFAJOK TAB
            _halfajok.isEmpty
                ? const Center(child: Text('Nincs rögzített halfaj.'))
                : ListView.builder(
                    itemCount: _halfajok.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(_halfajok[i].nev, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_halfajok[i].kategoria),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _torlesHalfaj(i),
                      ),
                    ),
                  ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              backgroundColor: Colors.green[600],
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;
                if (tabIndex == 0) _ujHelyszin();
                if (tabIndex == 1) _ujHalfaj();
              },
            );
          },
        ),
      ),
    );
  }
}

// ---- HALFAJ SZERKESZTŐ / HOZZÁADÓ KÉPERNYŐ ----
class HalfajSzerkesztoScreen extends StatefulWidget {
  final Function(Halfaj) mentesCallback;

  const HalfajSzerkesztoScreen({super.key, required this.mentesCallback});

  @override
  State<HalfajSzerkesztoScreen> createState() => _HalfajSzerkesztoScreenState();
}

class _HalfajSzerkesztoScreenState extends State<HalfajSzerkesztoScreen> {
  final _nevCtrl = TextEditingController();
  final _meretCtrl = TextEditingController();
  final _elvihetoCtrl = TextEditingController();
  final _korlatCtrl = TextEditingController();
  final _tilalomCtrl = TextEditingController();
  final _elohelyCtrl = TextEditingController();
  final _taplalekCtrl = TextEditingController();
  final _forrasCtrl = TextEditingController();
  
  String _kategoria = 'Békés halak';
  List<String> _kepUtvonalak = [];

  Future<void> _kepHozzaadasa() async {
    final picker = ImagePicker();
    final List<XFile> kepek = await picker.pickMultiImage();
    if (kepek.isNotEmpty) {
      setState(() {
        _kepUtvonalak.addAll(kepek.map((k) => k.path));
      });
    }
  }

  void _mentes() {
    if (_nevCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A hal neve kötelező!')));
      return;
    }

    final ujHal = Halfaj(
      id: DateTime.now().toString(),
      nev: _nevCtrl.text,
      kategoria: _kategoria,
      altalanosMeret: _meretCtrl.text,
      elvihetoMennyiseg: _elvihetoCtrl.text,
      meretKorlatozas: _korlatCtrl.text,
      tilalmiIdoszak: _tilalomCtrl.text,
      elohely: _elohelyCtrl.text,
      taplalek: _taplalekCtrl.text,
      szabalyzatForras: _forrasCtrl.text,
      kepek: _kepUtvonalak,
    );

    widget.mentesCallback(ujHal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Új Halfaj Felvitele')),
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
              items: ['Békés halak', 'Ragadozó halak', 'Egyéb'].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (val) => setState(() => _kategoria = val!),
            ),
            TextField(controller: _meretCtrl, decoration: const InputDecoration(labelText: 'Általános méret (pl. 30-50 cm)')),
            TextField(controller: _elvihetoCtrl, decoration: const InputDecoration(labelText: 'Elvihető mennyiség (pl. napi 3 db)')),
            TextField(controller: _korlatCtrl, decoration: const InputDecoration(labelText: 'Méretkorlátozás (pl. min. 30 cm)')),
            TextField(controller: _tilalomCtrl, decoration: const InputDecoration(labelText: 'Tilalmi időszak (pl. márc 1 - ápr 30)')),
            TextField(controller: _elohelyCtrl, decoration: const InputDecoration(labelText: 'Élőhely / Hol találkozhatunk vele?')),
            TextField(controller: _taplalekCtrl, decoration: const InputDecoration(labelText: 'Természetes táplálék / Kedvelt csali')),
            TextField(controller: _forrasCtrl, decoration: const InputDecoration(labelText: 'Szabályzat forrása (pl. MOHOSZ 2024)')),
            
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
