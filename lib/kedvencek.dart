import 'dart:io';
import 'package:flutter/material.dart';
import 'fogasok.dart';
import 'modellek.dart'; // <--- A Tura és Helyszin modellek miatt kell
import 'adattarolo.dart'; // <--- A valódi adatbázis miatt kell

class KedvencekScreen extends StatefulWidget {
  const KedvencekScreen({super.key});

  @override
  State<KedvencekScreen> createState() => _KedvencekScreenState();
}

class _KedvencekScreenState extends State<KedvencekScreen> {
  // A valódi túrákat és helyszíneket ide töltjük be, hogy ki tudjuk írni a neveket
  List<Tura> _osszesTura = [];
  List<Helyszin> _osszesHelyszin = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  // --- VALÓDI ADATOK BETÖLTÉSE ---
  Future<void> _adatokBetoltese() async {
    final turakAdat = await AdatTarolo.betoltes('turak_adatok');
    final helyszinekAdat = await AdatTarolo.betoltes('helyszinek_adatok');

    setState(() {
      _osszesTura = turakAdat.map((e) => Tura.fromJson(e)).toList();
      _osszesHelyszin = helyszinekAdat.map((e) => Helyszin.fromJson(e)).toList();
    });
  }
  
  // Lekérjük az összes kedvenc fogást a globális memóriából
  List<FogasModel> _getKedvencFogasok() {
    List<FogasModel> lista = FogasAdatbazis.fogasok.where((f) => f.isKedvenc).toList();
    // Rendezés: Legfrissebb legelöl
    lista.sort((a, b) {
      final aDT = DateTime(a.datum.year, a.datum.month, a.datum.day, a.idopont.hour, a.idopont.minute);
      final bDT = DateTime(b.datum.year, b.datum.month, b.datum.day, b.idopont.hour, b.idopont.minute);
      return bDT.compareTo(aDT);
    });
    return lista;
  }

  void _fogasTorles(int valodiIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Fogás törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a fogást a teljes rendszerből?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Mégsem', style: TextStyle(color: Colors.white54))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              setState(() {
                FogasAdatbazis.fogasok.removeAt(valodiIndex);
              });
              Navigator.pop(context);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getKartyaszin(String sors) {
    if (sors == 'Elvittem') return Colors.orange.withOpacity(0.15);
    if (sors == 'Elpusztult') return Colors.red.withOpacity(0.15);
    return const Color(0xFF1E1E1E);
  }

  // --- ÚJ HELYSZÍN KERESŐ LOGIKA (VALÓDI ADATOKBÓL) ---
  String _getTuraHelyszin(String turaId) {
    // 1. Megkeressük a túrát az ID alapján (ha nem találja, null-t ad)
    final keresettTura = _osszesTura.cast<Tura?>().firstWhere(
      (t) => t?.id == turaId, 
      orElse: () => null
    );

    // 2. Ha megvan a túra, és van is benne helyszín ID, megkeressük a helyszínt
    if (keresettTura != null && keresettTura.helyszinId != null) {
      final helyszin = _osszesHelyszin.cast<Helyszin?>().firstWhere(
        (h) => h?.id == keresettTura.helyszinId,
        orElse: () => null
      );
      
      // Ha a helyszín is megvan, visszaadjuk a nevét
      if (helyszin != null) {
        return helyszin.nev;
      }
    }
    
    // Ha bármelyik ponton elakadunk, ezt írjuk ki
    return 'Ismeretlen helyszín';
  }

  @override
  Widget build(BuildContext context) {
    final kedvencekListaja = _getKedvencFogasok();

    return Scaffold(
      body: kedvencekListaja.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 70, color: Colors.green[800]),
                  const SizedBox(height: 16),
                  const Text('Még nincs kedvencnek jelölt fogásod.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Kattints a szívecskére a túrák fogásainál!', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: kedvencekListaja.length,
              itemBuilder: (context, index) {
                final fogas = kedvencekListaja[index];
                final valodiIndex = FogasAdatbazis.fogasok.indexWhere((f) => f.id == fogas.id);
                final turaHelyszin = _getTuraHelyszin(fogas.turaId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: _getKartyaszin(fogas.sors),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      // Miniatűr kép
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (fogas.kepUtvonal != null && File(fogas.kepUtvonal!).existsSync())
                            ? Image.file(File(fogas.kepUtvonal!), fit: BoxFit.cover)
                            : const Icon(Icons.image, color: Colors.white24),
                      ),
                      // Adatok
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${fogas.datum.year}.${fogas.datum.month.toString().padLeft(2, '0')}.${fogas.datum.day.toString().padLeft(2, '0')}. ${fogas.idopont.format(context)}',
                                style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
                              ),
                              const SizedBox(height: 4),
                              Text(fogas.halfaj, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${fogas.suly} kg • ${fogas.hossz} cm', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(turaHelyszin, style: const TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                      // Akciósáv
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () => _fogasTorles(valodiIndex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white38),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Szerkeszteni az eredeti túra nézetben tudod!')),
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite, size: 20, color: Colors.red),
                                onPressed: () {
                                  // Kedvencből való eltávolítás
                                  setState(() {
                                    FogasAdatbazis.fogasok[valodiIndex].isKedvenc = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Eltávolítva a kedvencek közül.')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20, color: Colors.greenAccent),
                                onPressed: () {
                                  // Megnyitjuk a Részletes Nézetet, ami a fogasok.dart-ban van!
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FogasReszletekScreen(
                                        fogas: fogas, 
                                        helyszin: turaHelyszin
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
