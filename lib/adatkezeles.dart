import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'adattarolo.dart';

class AdatkezelesScreen extends StatefulWidget {
  const AdatkezelesScreen({super.key});

  @override
  State<AdatkezelesScreen> createState() => _AdatkezelesScreenState();
}

class _AdatkezelesScreenState extends State<AdatkezelesScreen> {
  int _turakSzama = 0;
  int _fogasokSzama = 0;
  int _halfajokSzama = 0;
  int _felszerelesSzama = 0;
  int _dokumentumokSzama = 0;
  
  bool _toltesFolyamatban = false;
  String _toltesSzoveg = 'Művelet folyamatban...\nKérlek, várj!'; // ÚJ: Dinamikus töltőszöveg

  @override
  void initState() {
    super.initState();
    _statisztikakFrissitese();
  }

  Future<void> _statisztikakFrissitese() async {
    final turak = await AdatTarolo.turakBetoltese();
    final fogasok = await AdatTarolo.fogasokBetoltese();
    final halfajok = await AdatTarolo.halfajokBetoltese();
    final felszerelesek = await AdatTarolo.felszerelesTetelekBetoltese();
    final dokumentumok = await AdatTarolo.dokFajlokBetoltese();

    setState(() {
      _turakSzama = turak.length;
      _fogasokSzama = fogasok.length;
      _halfajokSzama = halfajok.length;
      _felszerelesSzama = felszerelesek.length;
      _dokumentumokSzama = dokumentumok.length;
    });
  }

  Future<void> _osszesAdatTorlese() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minden adat sikeresen törölve! Tiszta lappal indulsz.'), backgroundColor: Colors.redAccent),
      );
      _statisztikakFrissitese();
    }
  }

  void _torlesMegerosite() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Minden adat törlése', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Biztosan törölni szeretnél minden rögzített túrát, fogást, felszerelést és törzsadatot?\n\nEz a művelet nem vonható vissza!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(context);
              _osszesAdatTorlese();
            },
            child: const Text('Igen, mindent törlök', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mutassUzenetet(String uzenet, {bool hiba = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(uzenet),
        backgroundColor: hiba ? Colors.redAccent : Colors.green[700],
      ),
    );
  }

  Future<void> _fajlMenteseLetoltesekbe(String eredetiPath) async {
    try {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory(); 
      }
      
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      final fileName = eredetiPath.split('/').last;
      final newPath = '${downloadsDir.path}/$fileName';
      await File(eredetiPath).copy(newPath);
      
      _mutassUzenetet('Mentve a Letöltések (Download) könyvtárba!\n$fileName');
    } catch (e) {
      _mutassUzenetet('Hiba a fájl mentésekor: $e', hiba: true);
    }
  }

  void _exportalasMegnyitasa() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Exportálás típusa', style: TextStyle(color: Colors.blueAccent)),
        content: const Text('Kérlek válaszd ki, milyen formátumban szeretnéd lementeni az adataidat:'),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _toltesFolyamatban = true;
                _toltesSzoveg = 'A fotók és adatok becsomagolása eltarthat pár másodpercig...\n\nKérlek, ne zárd be az alkalmazást!';
              });
              
              // Hagyunk egy pillanatot a Flutternek, hogy kirajzolja a töltőképernyőt, mielőtt nekiáll a kemény munkának
              await Future.delayed(const Duration(milliseconds: 300));
              
              try {
                final path = await AdatTarolo.letrehozTeljesExportZIPFajl();
                await _fajlMenteseLetoltesekbe(path);
              } catch (e) {
                _mutassUzenetet('Hiba a ZIP mentés során: $e', hiba: true);
              } finally {
                if (mounted) setState(() => _toltesFolyamatban = false);
              }
            },
            child: const Text('Teljes Mentés (.zip)\n(Szöveges adatok + Fotók)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _toltesFolyamatban = true;
                _toltesSzoveg = 'Fájl generálása...';
              });
              
              await Future.delayed(const Duration(milliseconds: 300));
              
              try {
                final path = await AdatTarolo.letrehozGyorsExportJSONFajl();
                await _fajlMenteseLetoltesekbe(path);
              } catch (e) {
                _mutassUzenetet('Hiba a JSON mentés során: $e', hiba: true);
              } finally {
                if (mounted) setState(() => _toltesFolyamatban = false);
              }
            },
            child: const Text('Gyors Mentés (.json)\n(Csak szöveges adatok)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _importalasInditasa() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      String fajlUtvonal = result.files.single.path!;
      if (!fajlUtvonal.toLowerCase().endsWith('.zip') && !fajlUtvonal.toLowerCase().endsWith('.json')) {
        _mutassUzenetet('Kérlek csak .zip vagy .json kiterjesztésű fájlt válassz!', hiba: true);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Figyelem!'),
          content: const Text('Az importálás lenullázza és felülírja a jelenlegi adatokat. Biztosan folytatod?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _toltesFolyamatban = true;
                  _toltesSzoveg = 'Adatok betöltése és kicsomagolása...\n\nKérlek, várj!';
                });
                
                await Future.delayed(const Duration(milliseconds: 300));
                
                try {
                  await AdatTarolo.importalas(fajlUtvonal);
                  await _statisztikakFrissitese();
                  _mutassUzenetet('Adatbázis sikeresen betöltve és visszaállítva!');
                } catch (e) {
                  _mutassUzenetet('Hiba az importálás során: $e', hiba: true);
                } finally {
                  if (mounted) setState(() => _toltesFolyamatban = false);
                }
              },
              child: const Text('Importálás indítása', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adatkezelés')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Adatbázis állapota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _StatRow(cim: 'Rögzített túrák:', ertek: '$_turakSzama db'),
                        const Divider(color: Colors.white24),
                        _StatRow(cim: 'Rögzített fogások:', ertek: '$_fogasokSzama db'),
                        const Divider(color: Colors.white24),
                        _StatRow(cim: 'Felszerelés tételek:', ertek: '$_felszerelesSzama db'),
                        const Divider(color: Colors.white24),
                        _StatRow(cim: 'Mentett halfajok:', ertek: '$_halfajokSzama db'),
                        const Divider(color: Colors.white24),
                        _StatRow(cim: 'Mentett dokumentumok:', ertek: '$_dokumentumokSzama db'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text('Biztonsági Mentés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.all(16)),
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  label: const Text('Adatbázis Exportálása', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: _exportalasMegnyitasa,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(16)),
                  icon: const Icon(Icons.file_upload, color: Colors.white),
                  label: const Text('Adatbázis Importálása (.zip / .json)', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: _importalasInditasa,
                ),
                const SizedBox(height: 48),

                const Text('Veszélyes zóna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], padding: const EdgeInsets.all(16)),
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text('ÖSSZES ADAT TÖRLÉSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  onPressed: _torlesMegerosite,
                ),
              ],
            ),
          ),
          
          if (_toltesFolyamatban)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.greenAccent),
                    const SizedBox(height: 24),
                    Text(_toltesSzoveg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String cim;
  final String ertek;
  
  const _StatRow({required this.cim, required this.ertek});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(cim, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        Text(ertek, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
