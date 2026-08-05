import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'adattarolo.dart';
import 'modellek.dart';

class TurakScreen extends StatefulWidget {
  const TurakScreen({super.key});

  @override
  State<TurakScreen> createState() => _TurakScreenState();
}

class _TurakScreenState extends State<TurakScreen> {
  List<Tura> _turak = [];
  List<Helyszin> _helyszinek = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final turakAdatok = await AdatTarolo.betoltes('turak_adatok');
    final helyszinAdatok = await AdatTarolo.betoltes('helyszinek_adatok');

    setState(() {
      _turak = turakAdatok.map((e) => Tura.fromJson(e)).toList();
      _helyszinek = helyszinAdatok.map((e) => Helyszin.fromJson(e)).toList();
    });
  }

  Future<void> _turakMentes() async {
    await AdatTarolo.turakMentes(_turak);
  }

  void _ujTuraHozzaadasa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UjTuraScreen(
          meglevoHelyszinek: _helyszinek,
          mentesCallback: (ujTura, frissitettHelyszinek) {
            setState(() {
              _turak.add(ujTura);
              _helyszinek = frissitettHelyszinek;
            });
            _turakMentes();
            AdatTarolo.helyszinekMentes(_helyszinek);
          },
        ),
      ),
    );
  }

  void _turaTorlese(int index) {
    setState(() => _turak.removeAt(index));
    _turakMentes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _turak.isEmpty
          ? const Center(
              child: Text(
                'Még nincs rögzített túrád.\nKattints a + gombra egy új túra indításához!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _turak.length,
              itemBuilder: (context, index) {
                final tura = _turak[index];
                // Kikeressük a helyszín nevét, ha van
                String helyszinNev = 'Nincs helyszín megadva';
                if (tura.helyszinId != null) {
                  final h = _helyszinek.where((x) => x.id == tura.helyszinId).toList();
                  if (h.isNotEmpty) helyszinNev = h.first.nev;
                }

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.sailing, color: Colors.greenAccent, size: 36),
                    title: Text(tura.nev, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('$helyszinNev\n${DateFormat('yyyy. MM. dd.').format(tura.datum)}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _turaTorlese(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: _ujTuraHozzaadasa,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---- ÚJ TÚRA ŰRLAP ----
class UjTuraScreen extends StatefulWidget {
  final List<Helyszin> meglevoHelyszinek;
  final Function(Tura, List<Helyszin>) mentesCallback;

  const UjTuraScreen({super.key, required this.meglevoHelyszinek, required this.mentesCallback});

  @override
  State<UjTuraScreen> createState() => _UjTuraScreenState();
}

class _UjTuraScreenState extends State<UjTuraScreen> {
  final _nevCtrl = TextEditingController();
  final _megjegyzesCtrl = TextEditingController();
  DateTime _datum = DateTime.now();
  String? _kivalasztottHelyszinId; // Lehet null (üres)!
  late List<Helyszin> _helyszinek;

  @override
  void initState() {
    super.initState();
    _helyszinek = List.from(widget.meglevoHelyszinek);
  }

  void _ujHelyszinFelvitele() {
    final ujHelyszinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Új helyszín gyors hozzáadása'),
        content: TextField(
          controller: ujHelyszinCtrl,
          decoration: const InputDecoration(labelText: 'Helyszín neve'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              if (ujHelyszinCtrl.text.isNotEmpty) {
                final ujHelyszin = Helyszin(id: DateTime.now().toString(), nev: ujHelyszinCtrl.text);
                setState(() {
                  _helyszinek.add(ujHelyszin);
                  _kivalasztottHelyszinId = ujHelyszin.id; // Automatikusan kiválasztjuk!
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

  void _mentes() {
    if (_nevCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A túra neve kötelező!')));
      return;
    }

    final ujTura = Tura(
      id: DateTime.now().toString(),
      nev: _nevCtrl.text,
      helyszinId: _kivalasztottHelyszinId,
      datum: _datum,
      megjegyzes: _megjegyzesCtrl.text,
    );

    widget.mentesCallback(ujTura, _helyszinek);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Új Túra Indítása')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nevCtrl, decoration: const InputDecoration(labelText: 'Túra neve (pl. Pontyozás)')),
            const SizedBox(height: 16),
            
            // Helyszín választó okos legördülő
            DropdownButtonFormField<String>(
              value: _kivalasztottHelyszinId,
              decoration: const InputDecoration(labelText: 'Helyszín (Opcionális)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Nincs megadva --')), // Üres opció
                ..._helyszinek.map((h) => DropdownMenuItem(value: h.id, child: Text(h.nev))),
                const DropdownMenuItem(
                  value: 'UJ_HELYSZIN',
                  child: Text('➕ Új helyszín hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ],
              onChanged: (val) {
                if (val == 'UJ_HELYSZIN') {
                  // Visszaállítjuk az előző állapotra, majd megnyitjuk az ablakot
                  setState(() => _kivalasztottHelyszinId = _kivalasztottHelyszinId); 
                  _ujHelyszinFelvitele();
                } else {
                  setState(() => _kivalasztottHelyszinId = val);
                }
              },
            ),
            
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dátum'),
              subtitle: Text(DateFormat('yyyy. MM. dd.').format(_datum), style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final valasztott = await showDatePicker(
                  context: context,
                  initialDate: _datum,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (valasztott != null) setState(() => _datum = valasztott);
              },
            ),
            
            TextField(controller: _megjegyzesCtrl, decoration: const InputDecoration(labelText: 'Megjegyzés'), maxLines: 3),
            
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.all(16)),
              onPressed: _mentes,
              child: const Text('TÚRA INDÍTÁSA', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
