import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'adattarolo.dart';
import 'modellek.dart';
import 'fogasok.dart';

class KedvencekScreen extends StatefulWidget {
  const KedvencekScreen({super.key});

  @override
  State<KedvencekScreen> createState() => _KedvencekScreenState();
}

class _KedvencekScreenState extends State<KedvencekScreen> {
  List<FogasModel> _kedvencFogasok = [];
  List<Tura> _osszesTura = [];
  List<Helyszin> _osszesHelyszin = [];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final fogasok = await AdatTarolo.fogasokBetoltese();
    final turak = await AdatTarolo.turakBetoltese();
    final helyszinek = await AdatTarolo.helyszinekBetoltese();

    List<FogasModel> kedvencek = fogasok.where((f) => f.isKedvenc).toList();
    
    kedvencek.sort((a, b) {
      String aKomp = "${DateFormat('yyyy-MM-dd').format(a.datum)} ${a.idopont}";
      String bKomp = "${DateFormat('yyyy-MM-dd').format(b.datum)} ${b.idopont}";
      return bKomp.compareTo(aKomp);
    });

    setState(() {
      _kedvencFogasok = kedvencek;
      _osszesTura = turak;
      _osszesHelyszin = helyszinek;
    });
  }

  void _fogasTorles(FogasModel fogas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Fogás törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a fogást a teljes rendszerből?'),
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

  Future<void> _kedvencEltavolitas(FogasModel fogas) async {
    final osszes = await AdatTarolo.fogasokBetoltese();
    final idx = osszes.indexWhere((f) => f.id == fogas.id);
    if (idx != -1) {
      osszes[idx].isKedvenc = false;
      await AdatTarolo.fogasokMentes(osszes);
      _adatokBetoltese();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eltávolítva a kedvencek közül.')));
      }
    }
  }

  Map<String, String> _getTuraHelyszinEsHorgaszhely(String turaId) {
    final tura = _osszesTura.cast<Tura?>().firstWhere((t) => t?.id == turaId, orElse: () => null);
    if (tura != null) {
      String helyszinNev = 'Ismeretlen helyszín';
      if (tura.helyszinId != null) {
        final h = _osszesHelyszin.cast<Helyszin?>().firstWhere((x) => x?.id == tura.helyszinId, orElse: () => null);
        if (h != null) helyszinNev = h.nev;
      }
      return {'helyszin': helyszinNev, 'horgaszhely': tura.horgaszhely};
    }
    return {'helyszin': 'Ismeretlen helyszín', 'horgaszhely': ''};
  }

  void _reszletekMegnyitasa(FogasModel fogas, String helyszinNev, String horgaszhely) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FogasReszletekScreen(
          fogas: fogas,
          helyszinNev: helyszinNev,
          horgaszhely: horgaszhely,
        ),
      ),
    );
  }

  void _szerkesztesMegnyitasa(FogasModel fogas) {
    // --- JAVÍTVA: Megkeressük a teljes Túra objektumot a fogáshoz, és azt adjuk át ---
    final tura = _osszesTura.cast<Tura?>().firstWhere((t) => t?.id == fogas.turaId, orElse: () => null);
    
    if (tura != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FogasSzerkesztoScreen(
            tura: tura, // Itt már a tura objektumot adjuk át a turaId helyett!
            szerkeszthetoFogas: fogas,
            mentesCallback: () => _adatokBetoltese(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hiba: A túra nem található!'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _kedvencFogasok.isEmpty
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
              itemCount: _kedvencFogasok.length,
              itemBuilder: (context, index) {
                final fogas = _kedvencFogasok[index];
                final turaAdatok = _getTuraHelyszinEsHorgaszhely(fogas.turaId);
                final turaHelyszin = turaAdatok['helyszin']!;
                final turaHorgaszhely = turaAdatok['horgaszhely']!;

                Color keretSzin = Colors.transparent;
                if (fogas.sors == 'Elvittem') keretSzin = Colors.orangeAccent;
                if (fogas.sors == 'Elpusztult') keretSzin = Colors.redAccent;

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: keretSzin, width: keretSzin == Colors.transparent ? 0 : 2),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _reszletekMegnyitasa(fogas, turaHelyszin, turaHorgaszhely),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('yyyy.MM.dd.').format(fogas.datum)} ${fogas.idopont}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                                clipBehavior: Clip.antiAlias,
                                child: (fogas.fenykep != null && File(fogas.fenykep!).existsSync())
                                    ? Image.file(File(fogas.fenykep!), fit: BoxFit.cover)
                                    : const Icon(Icons.set_meal, color: Colors.white24, size: 40),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fogas.halfaj.isEmpty ? 'Ismeretlen halfaj' : fogas.halfaj, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${fogas.suly != null ? "${fogas.suly} kg" : "- kg"} • ${fogas.hossz != null ? "${fogas.hossz} cm" : "- cm"}',
                                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(turaHelyszin, style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _fogasTorles(fogas)),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                    onPressed: () => _szerkesztesMegnyitasa(fogas),
                                  ),
                                  IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: () => _kedvencEltavolitas(fogas)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility, color: Colors.greenAccent),
                                onPressed: () => _reszletekMegnyitasa(fogas, turaHelyszin, turaHorgaszhely),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
