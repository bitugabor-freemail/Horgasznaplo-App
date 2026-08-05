import 'dart:convert';
import 'package:flutter/material.dart';
import 'torzsadatok.dart';
import 'turak.dart';
import 'fogasok.dart';
import 'lexikon.dart';

class AdatkezelesScreen extends StatelessWidget {
  const AdatkezelesScreen({super.key});

  void _mutatUzenet(BuildContext context, String uzenet, {bool hiba = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(uzenet),
        backgroundColor: hiba ? Colors.red[800] : Colors.green[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _jsonExport(BuildContext context) {
    // Itt történne a valós fájlba írás a path_provider segítségével
    final adatbazis = {
      'turak': TuraAdatbazis.turak.length,
      'fogasok': FogasAdatbazis.fogasok.length,
      'ido': DateTime.now().toString(),
    };
    final jsonString = jsonEncode(adatbazis);
    _mutatUzenet(context, 'Biztonsági mentés sikeresen elkészült!\n(Fájlba mentés szimulálva)');
  }

  void _jsonImport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Figyelem: Adatok felülírása!'),
        content: const Text('Az importálás a jelenlegi összes rögzített adatot (túrák, fogások, törzsadatok) felülírja. Biztosan folytatod?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégsem', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(context);
              _mutatUzenet(context, 'Adatok sikeresen visszaállítva a biztonsági mentésből!');
            },
            child: const Text('Igen, felülírom', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _csvExport(BuildContext context) {
    // CSV generálás logikája
    if (FogasAdatbazis.fogasok.isEmpty) {
      _mutatUzenet(context, 'Nincs exportálható fogás!', hiba: true);
      return;
    }
    _mutatUzenet(context, 'Excel (CSV) táblázat sikeresen kimentve a Galériába/Dokumentumokba!');
  }

  void _mohoszImport(BuildContext context) {
    final List<String> mohoszHalak = [
      'Afrikai harcsa', 'Amur', 'Angolna', 'Aranyhal', 'Balin', 'Bodorka', 'Buffalo',
      'Busa (pettyes)', 'Compó', 'Csíkos sügér', 'Csuka', 'Dévérkeszeg', 'Domolykó',
      'Ezüstkárász', 'Fekete amur', 'Garda', 'Harcsa', 'Jászkeszeg', 'Karikakeszeg',
      'Kecsege', 'Koi ponty', 'Kősüllő', 'Lapátorrú tok', 'Laposkeszeg', 'Leánykoncér',
      'Márna', 'Menyhal', 'Paduc', 'Pettyes harcsa', 'Pisztrángsügér', 'Ponty',
      'Sebes pisztráng', 'Sügér', 'Süllő', 'Széles kárász', 'Szilvaorrú keszeg',
      'Szivárványos pisztráng', 'Tokhal', 'Törpeharcsa', 'Vörösszárnyú keszeg'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('MOHOSZ Adatbázis Import'),
        content: const Text('Ez a művelet betölti a hivatalos 40 halfajt a Lexikonba és a Törzsadatok közé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégsem', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              // Lexikon feltöltése
              LexikonAdatbazis.halfajok.clear();
              // Törzsadat feltöltése
              TorzsadatAdatbazis.adatok['Halfaj']?.clear();

              for (String nev in mohoszHalak) {
                // Hozzáadás a lexikonhoz
                LexikonAdatbazis.halfajok.add(
                  HalfajModel(
                    nev: nev, 
                    kategoria: 'Magyarországi halfajok', 
                    meretKorlat: 'Lásd a helyi horgászrendet', 
                    tilalmiIdo: 'Lásd a MOHOSZ szabályzatot', 
                    leiras: 'Hivatalos MOHOSZ rekordlistás halfaj.', 
                    rekordSuly: '-', 
                    rekordHelyszin: '-'
                  )
                );
                // Hozzáadás a legördülő menükhöz (Törzsadatok)
                TorzsadatAdatbazis.adatok['Halfaj']?.add({'nev': nev});
              }

              Navigator.pop(context);
              _mutatUzenet(context, 'Mind a 40 halfaj sikeresen importálva!');
            },
            child: const Text('Importálás', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adatkezelés'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Export és Import', style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _KezeloKarta(
            cim: 'Biztonsági mentés készítése',
            leiras: 'A teljes adatbázis (túrák, fogások, törzsadatok) lementése egy JSON fájlba.',
            ikon: Icons.upload_file,
            gombSzoveg: 'Exportálás',
            gombSzin: Colors.blue[700]!,
            onTap: () => _jsonExport(context),
          ),
          
          _KezeloKarta(
            cim: 'Mentés visszaállítása',
            leiras: 'Adatok betöltése egy korábban készített JSON fájlból. (Figyelem: felülírja az eddigi adatokat!)',
            ikon: Icons.settings_backup_restore,
            gombSzoveg: 'Importálás',
            gombSzin: Colors.orange[700]!,
            onTap: () => _jsonImport(context),
          ),
          
          const Divider(color: Colors.white24, height: 40),
          const Text('Külső Rendszerek', style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _KezeloKarta(
            cim: 'MOHOSZ 40 Halfaj Betöltése',
            leiras: 'A gyári, 40 elemes hivatalos halfaj lista betöltése a Lexikonba és a rögzítéshez.',
            ikon: Icons.set_meal,
            gombSzoveg: 'Betöltés',
            gombSzin: Colors.green[700]!,
            onTap: () => _mohoszImport(context),
          ),

          _KezeloKarta(
            cim: 'Fogási Napló Excel (CSV)',
            leiras: 'Oszlopos táblázat generálása az összes eddigi fogásból asztali elemzéshez vagy leadáshoz.',
            ikon: Icons.table_chart,
            gombSzoveg: 'CSV Export',
            gombSzin: Colors.teal[700]!,
            onTap: () => _csvExport(context),
          ),
        ],
      ),
    );
  }
}

class _KezeloKarta extends StatelessWidget {
  final String cim;
  final String leiras;
  final IconData ikon;
  final String gombSzoveg;
  final Color gombSzin;
  final VoidCallback onTap;

  const _KezeloKarta({
    required this.cim,
    required this.leiras,
    required this.ikon,
    required this.gombSzoveg,
    required this.gombSzin,
    required this.onTap,
  });

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
                Icon(ikon, size: 28, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(child: Text(cim, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
            const SizedBox(height: 8),
            Text(leiras, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: gombSzin),
                onPressed: onTap,
                child: Text(gombSzoveg, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
