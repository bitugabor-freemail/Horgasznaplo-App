import 'package:flutter/material.dart';
import 'adattarolo.dart';
import 'modellek.dart';

class HalfajSzerkesztoScreen extends StatefulWidget {
  final Function(Halfaj) mentesCallback;

  const HalfajSzerkesztoScreen({super.key, required this.mentesCallback});

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

  // 5. pont: Alapból semmi sincs kiválasztva (null)
  String? _kivalasztottKategoria;
  String? _kivalasztottStatusz;

  final List<String> _kategoriak = ['Békés', 'Ragadozó'];
  final List<String> _statuszok = ['Fogható', 'Nem fogható', 'Védett', 'Inváziós'];

  void _mentes() {
    if (_nevCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A hal neve kötelező!')));
      return;
    }

    final ujHalfaj = Halfaj(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nev: _nevCtrl.text.trim(),
      kategoria: _kivalasztottKategoria ?? '',
      statusz: _kivalasztottStatusz ?? '',
      meretKorlatozas: _meretCtrl.text.trim(),
      darabKorlatozas: _darabCtrl.text.trim(),
      tilalmiIdoszak: _tilalomCtrl.text.trim(),
      szabalyozasEve: _evCtrl.text.trim(),
      megjegyzes: _megjegyzesCtrl.text.trim(),
      kepek: [],
    );

    widget.mentesCallback(ujHalfaj);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Új Halfaj Hozzáadása')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nevCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Halfaj neve *', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            // Kategória (üresen indul)
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

            // Státusz (üresen indul)
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
              child: const Text('HALFESZ MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
