import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'torzsadatok.dart';
import 'turak.dart'; // Hogy elérjük a TuraModel-t

// ---- FOGÁS ADATMODELL ÉS ADATBÁZIS ----
class FogasModel {
  String id;
  String turaId;
  DateTime datum;
  TimeOfDay idopont;
  String halfaj;
  double suly;
  int hossz;
  String sors;
  List<String> csali;
  List<String> etetoanyag;
  String etetesGyakorisag;
  String bot;
  String modszer;
  String szerelek;
  String idojaras;
  String homerseklet;
  String? kepUtvonal;
  String megjegyzes;
  bool isKedvenc;

  FogasModel({
    required this.id,
    required this.turaId,
    required this.datum,
    required this.idopont,
    required this.halfaj,
    required this.suly,
    required this.hossz,
    required this.sors,
    required this.csali,
    required this.etetoanyag,
    required this.etetesGyakorisag,
    required this.bot,
    required this.modszer,
    required this.szerelek,
    required this.idojaras,
    required this.homerseklet,
    this.kepUtvonal,
    required this.megjegyzes,
    this.isKedvenc = false,
  });
}

class FogasAdatbazis {
  static List<FogasModel> fogasok = [];
}

// ---- FOGÁSOK LISTÁJA EGY ADOTT TÚRÁN ----
class FogasokScreen extends StatefulWidget {
  final TuraModel tura;

  const FogasokScreen({super.key, required this.tura});

  @override
  State<FogasokScreen> createState() => _FogasokScreenState();
}

class _FogasokScreenState extends State<FogasokScreen> {
  
  List<FogasModel> _getTuraFogasai() {
    List<FogasModel> lista = FogasAdatbazis.fogasok.where((f) => f.turaId == widget.tura.id).toList();
    // Rendezés: Legfrissebb legelöl (Dátum, majd idő alapján)
    lista.sort((a, b) {
      final aDT = DateTime(a.datum.year, a.datum.month, a.datum.day, a.idopont.hour, a.idopont.minute);
      final bDT = DateTime(b.datum.year, b.datum.month, b.datum.day, b.idopont.hour, b.idopont.minute);
      return bDT.compareTo(aDT);
    });
    return lista;
  }

  void _nyitFogasKezeles({FogasModel? szerkeszthetoFogas, int? index}) async {
    final bool isSzerkesztes = szerkeszthetoFogas != null;

    DateTime datum = szerkeszthetoFogas?.datum ?? DateTime.now();
    TimeOfDay idopont = szerkeszthetoFogas?.idopont ?? TimeOfDay.now();
    
    // Törzsadat listák
    final halfajok = TorzsadatAdatbazis.adatok['Halfaj'] ?? [];
    final sorsok = TorzsadatAdatbazis.adatok['Hal sorsa'] ?? [];
    final botok = TorzsadatAdatbazis.adatok['Bot'] ?? [];
    final modszerek = TorzsadatAdatbazis.adatok['Horgászmódszer'] ?? [];
    final szerelekek = TorzsadatAdatbazis.adatok['Végszerelék'] ?? [];
    final idojarasok = TorzsadatAdatbazis.adatok['Időjárás'] ?? [];

    String? kivalasztottHalfaj = szerkeszthetoFogas?.halfaj ?? (halfajok.isNotEmpty ? halfajok[0]['nev'] : null);
    String kivalasztottSors = szerkeszthetoFogas?.sors ?? 'Visszaengedtem';
    String? kivalasztottBot = szerkeszthetoFogas?.bot ?? (botok.isNotEmpty ? botok[0]['nev'] : null);
    String? kivalasztottModszer = szerkeszthetoFogas?.modszer ?? (modszerek.isNotEmpty ? modszerek[0]['nev'] : null);
    String? kivalasztottSzerelek = szerkeszthetoFogas?.szerelek ?? (szerelekek.isNotEmpty ? szerelekek[0]['nev'] : null);
    String? kivalasztottIdojaras = szerkeszthetoFogas?.idojaras ?? (idojarasok.isNotEmpty ? idojarasok[0]['nev'] : null);

    List<String> kivalasztottCsalik = List.from(szerkeszthetoFogas?.csali ?? []);
    List<String> kivalasztottEtetoanyagok = List.from(szerkeszthetoFogas?.etetoanyag ?? []);

    final sulyController = TextEditingController(text: szerkeszthetoFogas?.suly.toString() ?? '');
    final hosszController = TextEditingController(text: szerkeszthetoFogas?.hossz.toString() ?? '');
    final etetesGyakController = TextEditingController(text: szerkeszthetoFogas?.etetesGyakorisag ?? '');
    final homersekletController = TextEditingController(text: szerkeszthetoFogas?.homerseklet ?? '');
    final megjegyzesController = TextEditingController(text: szerkeszthetoFogas?.megjegyzes ?? '');

    String? kepUtvonal = szerkeszthetoFogas?.kepUtvonal;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSzerkesztes ? 'Fogás szerkesztése' : 'Új fogás rögzítése',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, color: Colors.green),
                            label: Text(datum.toLocal().toString().split(' ')[0]),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context, initialDate: datum,
                                firstDate: DateTime(2000), lastDate: DateTime(2100),
                              );
                              if (picked != null) setModalState(() => datum = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, color: Colors.green),
                            label: Text(idopont.format(context)),
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: idopont);
                              if (picked != null) setModalState(() => idopont = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: kivalasztottHalfaj,
                      decoration: const InputDecoration(labelText: 'Halfaj (Törzsadat)', border: OutlineInputBorder()),
                      items: halfajok.map<DropdownMenuItem<String>>((h) => DropdownMenuItem(value: h['nev'], child: Text(h['nev']))).toList(),
                      onChanged: (val) => setModalState(() => kivalasztottHalfaj = val),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sulyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Súly (kg)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: hosszController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Hossz (cm)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: kivalasztottSors,
                      decoration: const InputDecoration(labelText: 'Hal sorsa', border: OutlineInputBorder()),
                      items: sorsok.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s['nev'], child: Text(s['nev']))).toList(),
                      onChanged: (val) => setModalState(() => kivalasztottSors = val!),
                    ),
                    const SizedBox(height: 16),

                    // Csali kiválasztó (Több is lehet)
                    const Text('Csali:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: (TorzsadatAdatbazis.adatok['Csali'] ?? []).map((cs) {
                        final isSelected = kivalasztottCsalik.contains(cs['nev']);
                        return FilterChip(
                          label: Text(cs['nev']),
                          selected: isSelected,
                          selectedColor: Colors.green[800],
                          onSelected: (selected) {
                            setModalState(() {
                              selected ? kivalasztottCsalik.add(cs['nev']) : kivalasztottCsalik.remove(cs['nev']);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Etetőanyag kiválasztó
                    const Text('Etetőanyag:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: (TorzsadatAdatbazis.adatok['Etetőanyag'] ?? []).map((e) {
                        final isSelected = kivalasztottEtetoanyagok.contains(e['nev']);
                        return FilterChip(
                          label: Text(e['nev']),
                          selected: isSelected,
                          selectedColor: Colors.green[800],
                          onSelected: (selected) {
                            setModalState(() {
                              selected ? kivalasztottEtetoanyagok.add(e['nev']) : kivalasztottEtetoanyagok.remove(e['nev']);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: etetesGyakController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Etetés gyakorisága (perc)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: kivalasztottBot,
                      decoration: const InputDecoration(labelText: 'Bot (Törzsadat)', border: OutlineInputBorder()),
                      items: botok.map<DropdownMenuItem<String>>((b) => DropdownMenuItem(value: b['nev'], child: Text(b['nev']))).toList(),
                      onChanged: (val) => setModalState(() => kivalasztottBot = val),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: kivalasztottModszer,
                      decoration: const InputDecoration(labelText: 'Módszer (Törzsadat)', border: OutlineInputBorder()),
                      items: modszerek.map<DropdownMenuItem<String>>((m) => DropdownMenuItem(value: m['nev'], child: Text(m['nev']))).toList(),
                      onChanged: (val) => setModalState(() => kivalasztottModszer = val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: kivalasztottSzerelek,
                      decoration: const InputDecoration(labelText: 'Végszerelék (Törzsadat)', border: OutlineInputBorder()),
                      items: szerelekek.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s['nev'], child: Text(s['nev']))).toList(),
                      onChanged: (val) => setModalState(() => kivalasztottSzerelek = val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: kivalasztottIdojaras,
                      decoration: const InputDecoration(labelText: 'Időjárás (Törzsadat)', border: OutlineInputBorder()),
                      items: idojarasok.map<DropdownMenuItem<String>>((i) => DropdownMenuItem(value: i['nev'], child: Text(i['nev']))).toList(),
                      onChanged: (val) => setModalState(() => kivalasztottIdojaras = val),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: homersekletController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Hőmérséklet (°C)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              homersekletController.text = "18"; // Szimulált GPS lekérés
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hőmérséklet lekérve (Szimulált)')));
                          },
                          icon: const Icon(Icons.cloud_sync, color: Colors.white),
                          label: const Text('Online', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Fotó'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) setModalState(() => kepUtvonal = image.path);
                          },
                        ),
                        const SizedBox(width: 12),
                        if (kepUtvonal != null)
                          const Text('Kép kiválasztva ✓', style: TextStyle(color: Colors.greenAccent))
                        else
                          const Text('Nincs kép', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: megjegyzesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Megjegyzés', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          if (kivalasztottHalfaj == null) return;
                          
                          final ujFogas = FogasModel(
                            id: isSzerkesztes ? szerkeszthetoFogas.id : DateTime.now().millisecondsSinceEpoch.toString(),
                            turaId: widget.tura.id,
                            datum: datum,
                            idopont: idopont,
                            halfaj: kivalasztottHalfaj!,
                            suly: double.tryParse(sulyController.text.trim()) ?? 0.0,
                            hossz: int.tryParse(hosszController.text.trim()) ?? 0,
                            sors: kivalasztottSors,
                            csali: kivalasztottCsalik,
                            etetoanyag: kivalasztottEtetoanyagok,
                            etetesGyakorisag: etetesGyakController.text.trim(),
                            bot: kivalasztottBot ?? '',
                            modszer: kivalasztottModszer ?? '',
                            szerelek: kivalasztottSzerelek ?? '',
                            idojaras: kivalasztottIdojaras ?? '',
                            homerseklet: homersekletController.text.trim(),
                            kepUtvonal: kepUtvonal,
                            megjegyzes: megjegyzesController.text.trim(),
                            isKedvenc: isSzerkesztes ? szerkeszthetoFogas.isKedvenc : false,
                          );

                          setState(() {
                            if (isSzerkesztes) {
                              FogasAdatbazis.fogasok[index!] = ujFogas;
                            } else {
                              FogasAdatbazis.fogasok.add(ujFogas);
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Fogás mentése', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _fogasTorles(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Fogás törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a fogást?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              setState(() => FogasAdatbazis.fogasok.removeAt(index));
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
    return const Color(0xFF1E1E1E); // Visszaengedtem (Alapértelmezett sötét kártya)
  }

  @override
  Widget build(BuildContext context) {
    final fogasokListaja = _getTuraFogasai();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Túra Fogásai'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: fogasokListaja.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.set_meal, size: 70, color: Colors.green[800]),
                  const SizedBox(height: 16),
                  const Text('Még nincs rögzített fogás ezen a túrán.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: fogasokListaja.length,
              itemBuilder: (context, index) {
                final fogas = fogasokListaja[index];
                final valodiIndex = FogasAdatbazis.fogasok.indexWhere((f) => f.id == fogas.id);

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
                            ],
                          ),
                        ),
                      ),
                      // Akciósáv (Függőlegesen)
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
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white70),
                                onPressed: () => _nyitFogasKezeles(szerkeszthetoFogas: fogas, index: valodiIndex),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  fogas.isKedvenc ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: fogas.isKedvenc ? Colors.red : Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() => FogasAdatbazis.fogasok[valodiIndex].isKedvenc = !fogas.isKedvenc);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20, color: Colors.greenAccent),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FogasReszletekScreen(fogas: fogas, helyszin: widget.tura.helyszin)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _nyitFogasKezeles(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---- FOGÁS RÉSZLETES NÉZETE ----
class FogasReszletekScreen extends StatelessWidget {
  final FogasModel fogas;
  final String helyszin; // Letöltéshez kell a vízjelbe

  const FogasReszletekScreen({super.key, required this.fogas, required this.helyszin});

  void _teljesKepernyosKep(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kép sikeresen letöltve vízjellel a Galériába!')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(fogas.kepUtvonal!)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fogás Részletei'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dátum és Idő
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${fogas.datum.year}.${fogas.datum.month.toString().padLeft(2, '0')}.${fogas.datum.day.toString().padLeft(2, '0')}. - ${fogas.idopont.format(context)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ),
            ),
            
            // 2. Nagy méretű fotó (Stabil, nem zoomolható)
            if (fogas.kepUtvonal != null && File(fogas.kepUtvonal!).existsSync())
              GestureDetector(
                onTap: () => _teljesKepernyosKep(context),
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(fogas.kepUtvonal!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.zoom_out_map, color: Colors.white54),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.black26,
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white24),
              ),

            // 3. Halfaj, Súly és Hossz
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFF161616),
              child: Column(
                children: [
                  Text(fogas.halfaj, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${fogas.suly} kg  |  ${fogas.hossz} cm', style: const TextStyle(fontSize: 20, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: fogas.sors == 'Visszaengedtem' ? Colors.green[900] : (fogas.sors == 'Elvittem' ? Colors.orange[900] : Colors.red[900]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(fogas.sors, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 4. Többi részletes adat blokkja
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _AdatSor(cim: 'Csali', ertek: fogas.csali.isEmpty ? '-' : fogas.csali.join(', ')),
                  _AdatSor(cim: 'Etetőanyag', ertek: fogas.etetoanyag.isEmpty ? '-' : fogas.etetoanyag.join(', ')),
                  _AdatSor(cim: 'Etetés üteme', ertek: fogas.etetesGyakorisag.isEmpty ? '-' : '${fogas.etetesGyakorisag} perc'),
                  const Divider(color: Colors.white24),
                  _AdatSor(cim: 'Bot', ertek: fogas.bot.isEmpty ? '-' : fogas.bot),
                  _AdatSor(cim: 'Módszer', ertek: fogas.modszer.isEmpty ? '-' : fogas.modszer),
                  _AdatSor(cim: 'Szerelék', ertek: fogas.szerelek.isEmpty ? '-' : fogas.szerelek),
                  const Divider(color: Colors.white24),
                  _AdatSor(cim: 'Időjárás', ertek: fogas.idojaras.isEmpty ? '-' : fogas.idojaras),
                  _AdatSor(cim: 'Hőmérséklet', ertek: fogas.homerseklet.isEmpty ? '-' : '${fogas.homerseklet} °C'),
                ],
              ),
            ),

            // 5. Megjegyzés
            if (fogas.megjegyzes.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Megjegyzés', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    const SizedBox(height: 8),
                    Text(fogas.megjegyzes, style: const TextStyle(fontSize: 16, height: 1.4)),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AdatSor extends StatelessWidget {
  final String cim;
  final String ertek;
  const _AdatSor({required this.cim, required this.ertek});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(cim, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(ertek, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
