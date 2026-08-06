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
  int _halfajokSzama = 0;
  int _helyszinekSzama = 0;

  @override
  void initState() {
    super.initState();
    _statisztikakFrissitese();
  }

  // Lekérdezzük a valódi adatbázisból, hogy mennyi adatunk van
  Future<void> _statisztikakFrissitese() async {
    final turak = await AdatTarolo.betoltes('turak_adatok');
    final halfajok = await AdatTarolo.betoltes('halfajok_adatok');
    final helyszinek = await AdatTarolo.betoltes('helyszinek_adatok');

    setState(() {
      _turakSzama = turak.length;
      _halfajokSzama = halfajok.length;
      _helyszinekSzama = helyszinek.length;
    });
  }

  // Törli a telefonra mentett összes adatot
  Future<void> _osszesAdatTorlese() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minden adat sikeresen törölve!'),
          backgroundColor: Colors.redAccent,
        ),
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
        content: const Text('Biztosan törölni szeretnél minden rögzített túrát, fogást és törzsadatot? Ez a művelet nem vonható vissza!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégsem', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(context); // Ablak bezárása
              _osszesAdatTorlese();   // Törlés indítása
            },
            child: const Text('Igen, törlöm', style: TextStyle(color: Colors.white)),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Adatbázis statisztika', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _StatRow(cim: 'Rögzített túrák:', ertek: _turakSzama.toString()),
                    const Divider(color: Colors.white24),
                    _StatRow(cim: 'Mentett halfajok:', ertek: _halfajokSzama.toString()),
                    const Divider(color: Colors.white24),
                    _StatRow(cim: 'Mentett helyszínek:', ertek: _helyszinekSzama.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Veszélyes zóna', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding: const EdgeInsets.all(16),
              ),
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
