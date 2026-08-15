import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'adattarolo.dart';
import 'modellek.dart';

class DokumentumokScreen extends StatefulWidget {
  const DokumentumokScreen({super.key});

  @override
  State<DokumentumokScreen> createState() => _DokumentumokScreenState();
}

class _DokumentumokScreenState extends State<DokumentumokScreen> {
  List<DokumentumMappa> _mappak = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final mappak = await AdatTarolo.dokMappakBetoltese();
    mappak.sort((a, b) => a.nev.toLowerCase().compareTo(b.nev.toLowerCase()));
    setState(() {
      _mappak = mappak;
    });
  }

  void _mappaKezeles([DokumentumMappa? szerkeszthetoMappa]) {
    final ctrl = TextEditingController(text: szerkeszthetoMappa?.nev ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(szerkeszthetoMappa == null ? 'Új Mappa Hozzáadása' : 'Mappa Átnevezése'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Mappa neve'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                if (szerkeszthetoMappa == null) {
                  _mappak.add(DokumentumMappa(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nev: ctrl.text.trim(),
                  ));
                } else {
                  final idx = _mappak.indexWhere((m) => m.id == szerkeszthetoMappa.id);
                  if (idx != -1) _mappak[idx].nev = ctrl.text.trim();
                }
                await AdatTarolo.dokMappakMentes(_mappak);
                _adatokBetoltese();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mappaTorles(DokumentumMappa mappa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Mappa Törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a mappát? A benne lévő összes dokumentum is véglegesen törlődik!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              await AdatTarolo.mappaTorles(mappa);
              _adatokBetoltese();
              if (context.mounted) Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Dokumentumok'),
        backgroundColor: const Color(0xFF161616),
      ),
      body: _mappak.isEmpty
          ? const Center(
              child: Text(
                'Még nincsenek mappáid.\nHozz létre egyet a + gombbal!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _mappak.length,
              itemBuilder: (context, index) {
                final mappa = _mappak[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MappaTartalomScreen(mappa: mappa)),
                    );
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1E1E1E),
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit, color: Colors.white70),
                            title: const Text('Átnevezés'),
                            onTap: () {
                              Navigator.pop(context);
                              _mappaKezeles(mappa);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.redAccent),
                            title: const Text('Törlés'),
                            onTap: () {
                              Navigator.pop(context);
                              _mappaTorles(mappa);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder, size: 60, color: Colors.greenAccent),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            mappa.nev,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _mappaKezeles(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class MappaTartalomScreen extends StatefulWidget {
  final DokumentumMappa mappa;
  const MappaTartalomScreen({super.key, required this.mappa});

  @override
  State<MappaTartalomScreen> createState() => _MappaTartalomScreenState();
}

class _MappaTartalomScreenState extends State<MappaTartalomScreen> {
  List<DokumentumFajl> _fajlok = [];
  bool _toltesFolyamatban = false;

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final osszesFajl = await AdatTarolo.dokFajlokBetoltese();
    final mappaFajljai = osszesFajl.where((f) => f.mappaId == widget.mappa.id).toList();
    mappaFajljai.sort((a, b) => a.nev.toLowerCase().compareTo(b.nev.toLowerCase()));
    
    setState(() {
      _fajlok = mappaFajljai;
    });
  }

  Future<void> _pdfHozzaadasa() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _toltesFolyamatban = true);
      
      try {
        final eredetiUtvonal = result.files.single.path!;
        final alapNev = result.files.single.name;
        
        final ujUtvonal = await AdatTarolo.biztonsagosDokumentumMasolas(eredetiUtvonal);
        
        final ujFajl = DokumentumFajl(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          mappaId: widget.mappa.id,
          nev: alapNev,
          utvonal: ujUtvonal,
        );

        final osszesFajl = await AdatTarolo.dokFajlokBetoltese();
        osszesFajl.add(ujFajl);
        await AdatTarolo.dokFajlokMentes(osszesFajl);
        
        await _adatokBetoltese();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hiba a másoláskor: $e')));
      } finally {
        setState(() => _toltesFolyamatban = false);
      }
    }
  }

  // ITT NYÍLIK MEG KÖZVETLENÜL A FÁJL A TELEFON PDF OLVASÓJÁVAL
  void _fajlMegnyitasa(DokumentumFajl fajl) async {
    final result = await OpenFile.open(fajl.utvonal);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nem sikerült megnyitni a PDF-et: ${result.message}')),
      );
    }
  }

  void _fajlKezeles(DokumentumFajl fajl) {
    final ctrl = TextEditingController(text: fajl.nev);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Fájl Átnevezése'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Fájl neve'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final osszes = await AdatTarolo.dokFajlokBetoltese();
                final idx = osszes.indexWhere((f) => f.id == fajl.id);
                if (idx != -1) {
                  osszes[idx].nev = ctrl.text.trim();
                  if (!osszes[idx].nev.toLowerCase().endsWith('.pdf')) {
                    osszes[idx].nev += '.pdf';
                  }
                  await AdatTarolo.dokFajlokMentes(osszes);
                  _adatokBetoltese();
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _fajlTorles(DokumentumFajl fajl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Fájl Törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a dokumentumot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              await AdatTarolo.dokumentumTorles(fajl);
              _adatokBetoltese();
              if (context.mounted) Navigator.pop(context);
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
      appBar: AppBar(
        title: Text(widget.mappa.nev),
        backgroundColor: const Color(0xFF161616),
      ),
      body: Stack(
        children: [
          _fajlok.isEmpty
              ? const Center(
                  child: Text(
                    'Ez a mappa üres.\nTölts fel egy PDF-et a + gombbal!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _fajlok.length,
                  itemBuilder: (context, index) {
                    final fajl = _fajlok[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40),
                        title: Text(fajl.nev, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Kattints a megnyitáshoz', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        onTap: () => _fajlMegnyitasa(fajl),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70),
                              onPressed: () => _fajlKezeles(fajl),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _fajlTorles(fajl),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          if (_toltesFolyamatban)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: _pdfHozzaadasa,
        tooltip: 'PDF Hozzáadása',
        child: const Icon(Icons.add_chart, color: Colors.white),
      ),
    );
  }
}
