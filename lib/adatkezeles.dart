import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'adattarolo.dart';

// EXPORTÁLÁS FOLYAMATJELZŐ - Logó alatt a százalék, logó lentről felfelé töltődik
class _ExportProgressWidget extends StatelessWidget {
  final double progress;
  const _ExportProgressWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240, 
          height: 240,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Opacity(
                opacity: 0.2,
                child: Image.asset('assets/small_logo.png', width: 240, height: 240, fit: BoxFit.contain),
              ),
              ClipRect(
                clipper: _BottomUpClipper(progress),
                child: Image.asset('assets/small_logo.png', width: 240, height: 240, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 48, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 12)],
          ),
        ),
      ],
    );
  }
}

// IMPORTÁLÁS FOLYAMATJELZŐ - Logó felett a százalék, logó fentről lefelé töltődik
class _ImportProgressWidget extends StatelessWidget {
  final double progress;
  const _ImportProgressWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 48, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 240, 
          height: 240,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Opacity(
                opacity: 0.2,
                child: Image.asset('assets/small_logo.png', width: 240, height: 240, fit: BoxFit.contain),
              ),
              ClipRect(
                clipper: _TopDownClipper(progress), 
                child: Image.asset('assets/small_logo.png', width: 240, height: 240, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomUpClipper extends CustomClipper<Rect> {
  final double progress;
  _BottomUpClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, size.height * (1 - progress), size.width, size.height);
  }

  @override
  bool shouldReclip(_BottomUpClipper oldClipper) => progress != oldClipper.progress;
}

class _TopDownClipper extends CustomClipper<Rect> {
  final double progress;
  _TopDownClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height * progress);
  }

  @override
  bool shouldReclip(_TopDownClipper oldClipper) => progress != oldClipper.progress;
}


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
  int _jegyzetEsListaSzama = 0; 
  int _dokumentumokSzama = 0;

  bool _toltesFolyamatban = false;
  bool _mentesMegszakititva = false; 
  double _mentesProgress = -1.0; 
  bool _isImportFolyamat = false; 
  String _toltesSzoveg = 'Művelet folyamatban...\nKérlek, várj!'; 

  @override
  void initState() {
    super.initState();
    _statisztikakFrissitese();
  }

  Future<void> _statisztikakFrissitese() async {
    try {
      final turak = await AdatTarolo.turakBetoltese();
      final fogasok = await AdatTarolo.fogasokBetoltese();
      final halfajok = await AdatTarolo.halfajokBetoltese();
      final felszerelesek = await AdatTarolo.felszerelesTetelekBetoltese();
      final jegyzetek = await AdatTarolo.jegyzetekBetoltese(); 
      final listak = await AdatTarolo.listakBetoltese();       
      final dokumentumok = await AdatTarolo.dokFajlokBetoltese();

      if (mounted) {
        setState(() {
          _turakSzama = turak.length;
          _fogasokSzama = fogasok.length;
          _halfajokSzama = halfajok.length;
          _felszerelesSzama = felszerelesek.length;
          _jegyzetEsListaSzama = jegyzetek.length + listak.length; 
          _dokumentumokSzama = dokumentumok.length;
        });
      }
    } catch (e) {
      if (mounted) {
        _mutassUzenetet('Hiba a statisztikák betöltésekor: $e', hiba: true);
      }
    }
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
                _isImportFolyamat = false; 
                _toltesFolyamatban = true;
                _mentesMegszakititva = false;
                _mentesProgress = 0.0;
                _toltesSzoveg = 'Fotók és adatok csomagolása...\n\nKérlek, ne zárd be az alkalmazást!';
              });
              
              await Future.delayed(const Duration(milliseconds: 300));
              
              try {
                final path = await AdatTarolo.letrehozTeljesExportZIPFajl(
                  (progress) {
                    if (mounted) setState(() => _mentesProgress = progress);
                  },
                  isCancelled: () => _mentesMegszakititva,
                );

                if (_mentesMegszakititva) {
                  _mutassUzenetet('A mentés megszakítva!', hiba: true);
                } else if (path != null) {
                  if (mounted) setState(() => _mentesProgress = 1.0);
                  await Future.delayed(const Duration(seconds: 2));
                  await _fajlMenteseLetoltesekbe(path);
                }
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
                _isImportFolyamat = false;
                _toltesFolyamatban = true;
                _mentesProgress = -1.0; 
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
                  _isImportFolyamat = true; 
                  _toltesFolyamatban = true;
                  _mentesProgress = 0.0; 
                  _toltesSzoveg = 'Adatok betöltése és kicsomagolása...\n\nKérlek, várj!';
                });
                
                await Future.delayed(const Duration(milliseconds: 300));
                
                try {
                  await AdatTarolo.importalas(fajlUtvonal, onProgress: (progress) {
                    if (mounted) setState(() => _mentesProgress = progress);
                  });
                  await _statisztikakFrissitese();
                  
                  if (mounted) setState(() => _mentesProgress = 1.0);
                  await Future.delayed(const Duration(seconds: 2));
                  
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
      appBar: AppBar(
        title: const Text('Adatkezelés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.greenAccent),
            tooltip: 'Statisztikák frissítése',
            onPressed: _statisztikakFrissitese,
          ),
        ],
      ),
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
                        _StatRow(cim: 'Jegyzetek és listák:', ertek: '$_jegyzetEsListaSzama db'),
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
                    if (_mentesProgress >= 0)
                      _isImportFolyamat 
                          ? _ImportProgressWidget(progress: _mentesProgress)
                          : _ExportProgressWidget(progress: _mentesProgress)
                    else
                      const CircularProgressIndicator(color: Colors.greenAccent),
                    
                    const SizedBox(height: 24),
                    Text(_toltesSzoveg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                    
                    if (!_isImportFolyamat && _mentesProgress >= 0 && _mentesProgress < 1.0) ...[
                      const SizedBox(height: 24),
                      TextButton.icon(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        label: const Text('Mégsem', style: TextStyle(color: Colors.redAccent, fontSize: 18)),
                        onPressed: () {
                          setState(() {
                            _mentesMegszakititva = true;
                            _toltesSzoveg = 'Megszakítás folyamatban...\nKérlek, várj!';
                          });
                        },
                      )
                    ]
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
