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

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final osszesFogas = await AdatTarolo.fogasokBetoltese();
    _halfajok = await AdatTarolo.halfajokBetoltese();
    
    setState(() {
      _fogasok = osszesFogas.where((f) => f.turaId == widget.tura.id).toList();
      _fogasok.sort((a, b) => b.datum.compareTo(a.datum));
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

  Color _getSorsSzin(String sors) {
    if (sors.toLowerCase().contains('elvitt')) return Colors.orange;
    if (sors.toLowerCase().contains('elpusztult')) return Colors.red;
    return Colors.transparent; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fogások'),
        backgroundColor: const Color(0xFF161616),
      ),
      body: _fogasok.isEmpty
          ? const Center(child: Text('Nincs még rögzített fogás ehhez a túrához.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _fogasok.length,
              itemBuilder: (context, index) {
                final fogas = _fogasok[index];
                final keretSzin = _getSorsSzin(fogas.sors ?? ''); // Itt igazítottuk az eredeti modellnévhez

                return Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: keretSzin, width: keretSzin == Colors.transparent ? 0 : 2),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('yyyy.MM.dd.').format(fogas.datum)} ${fogas.idopont}',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                        ),
                        const Divider(color: Colors.white12),
                        
                        Row(
                          children: [
                            if (fogas.fenykep != null && File(fogas.fenykep!).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(fogas.fenykep!), width: 70, height: 70, fit: BoxFit.cover),
                              )
                            else
                              Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.phishing, color: Colors.white38, size: 30),
                              ),
                            const SizedBox(width: 16),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fogas.halfaj, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${fogas.suly != null ? '${fogas.suly} kg' : '-'} • ${fogas.hossz != null ? '${fogas.hossz} cm' : '-'}',
                                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _fogasTorlese(fogas),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                  onPressed: () => _fogasSzerkesztes(fogas),
                                ),
                                IconButton(
                                  icon: Icon(fogas.isKedvenc ? Icons.favorite : Icons.favorite_outline, color: fogas.isKedvenc ? Colors.redAccent : Colors.white70),
                                  onPressed: () => _kedvencValtoztatas(fogas),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                              icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                              label: const Text('RÉSZLETEK', style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                // Ide jön majd a Részletes Fogás Nézet megnyitása
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
        onPressed: () => _fogasSzerkesztes(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

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
  final _homersekletCtrl = TextEditingController();
  final _megjegyzesCtrl = TextEditingController();
  String? _fenykepUtvonal;

  bool _isIdojarasLekeresFolyamatban = false; 

  List<Halfaj> _elerhetoHalfajok = [];
  List<String> _elerhetoSorsok = ['Visszaengedtem', 'Elvittem', 'Elpusztult']; 

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    _elerhetoHalfajok = await AdatTarolo.halfajokBetoltese();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hiba a lekérés során. Ellenőrizd a GPS-t és az internetet!'), backgroundColor: Colors.redAccent));
      }
    });
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
                      final t = await showTimePicker(context: context, initialTime: _idopont);
                      if (t != null) setState(() => _idopont = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String?>(
              value: _kivalasztottHalfaj,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Halfaj *', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('-- Válassz halfajt --')),
                ..._elerhetoHalfajok.map((h) => DropdownMenuItem<String?>(value: h.nev, child: Text(h.nev))),
                const DropdownMenuItem<String?>(value: 'UJ_HALFAJ', child: Text('➕ Új hozzáadása', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
              ],
              onChanged: (val) {
                if (val == 'UJ_HALFAJ') {
                  // _ujHalfajHozzaadasa();
                } else {
                  setState(() => _kivalasztottHalfaj = val);
                }
              },
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

            TextField(
              controller: _homersekletCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hőmérséklet (°C)',
                border: const OutlineInputBorder(),
                suffixIcon: _isIdojarasLekeresFolyamatban
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                    : IconButton(
                        icon: const Icon(Icons.cloud_sync, color: Colors.greenAccent, size: 28),
                        tooltip: 'Online lekérés GPS alapján',
                        onPressed: _homersekletLekeres,
                      ),
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
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                // Mentés logika...
              },
              child: const Text('FOGÁS MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
