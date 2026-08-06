import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _statisztikakFrissitese();
  }

  Future<void> _statisztikakFrissitese() async {
    final turak = await AdatTarolo.turakBetoltese();
    final fogasok = await AdatTarolo.fogasokBetoltese();
    final halfajok = await AdatTarolo.halfajokBetoltese();

    setState(() {
      _turakSzama = turak.length;
      _fogasokSzama = fogasok.length;
      _halfajokSzama = halfajok.length;
    });
  }

  Future<void> _osszesAdatTorlese() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Minden mentett adat törlése a telefonról
    
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
        content: const Text('Biztosan törölni szeretnél minden rögzített túrát, fogást és törzsadatot?\n\nEz a művelet nem vonható vissza!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adatkezelés')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STATISZTIKA
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
                    _StatRow(cim: 'Mentett halfajok:', ertek: '$_halfajokSzama db'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // EXPORT / IMPORT
            const Text('Biztonsági Mentés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.all(16)),
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text('Teljes Adatbázis Exportálása (JSON)', style: TextStyle(color: Colors.white)),
              onPressed: () => _mutassUzenetet('Adatbázis és képek exportálva a Letöltések mappába! (Szimuláció)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(16)),
              icon: const Icon(Icons.file_upload, color: Colors.white),
              label: const Text('Adatbázis Importálása (JSON)', style: TextStyle(color: Colors.white)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text('Figyelem!'),
                    content: const Text('Az importálás felülírja a jelenlegi adatokat. Folytatod?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                        onPressed: () {
                          Navigator.pop(context);
                          _mutassUzenetet('Adatbázis sikeresen betöltve! (Szimuláció)');
                        },
                        child: const Text('Importálás', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // EXCEL EXPORT
            const Text('Asztali Elemzés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], padding: const EdgeInsets.all(16)),
              icon: const Icon(Icons.table_chart, color: Colors.white),
              label: const Text('Túrák és Fogások Exportálása (.CSV)', style: TextStyle(color: Colors.white)),
              onPressed: () => _mutassUzenetet('CSV fájl elmentve a Dokumentumok közé! (Szimuláció)'),
            ),
            const SizedBox(height: 48),

            // VESZÉLYES ZÓNA
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
