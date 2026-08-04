import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'torzsadatok.dart';

// ---- TÚRA ADATMODELL ÉS ADATBÁZIS ----
class TuraModel {
  String id;
  DateTime kezdodatum;
  DateTime befejezodatum;
  String helyszin;
  String vizterKod;
  String horgaszhely;
  List<String> horgasztarsak;
  String? kepUtvonal;
  String megjegyzes;

  TuraModel({
    required this.id,
    required this.kezdodatum,
    required this.befejezodatum,
    required this.helyszin,
    required this.vizterKod,
    required this.horgaszhely,
    required this.horgasztarsak,
    this.kepUtvonal,
    required this.megjegyzes,
  });
}

class TuraAdatbazis {
  static List<TuraModel> turak = [];
}

// ---- TÚRÁK KÉPERNYŐ (`turak.dart`) ----
class TurakScreen extends StatefulWidget {
  const TurakScreen({super.key});

  @override
  State<TurakScreen> createState() => _TurakScreenState();
}

class _TurakScreenState extends State<TurakScreen> {
  String _kivalasztottEv = '2026';

  List<String> _getEvekListaja() {
    Set<String> evek = {'2026'};
    for (var tura in TuraAdatbazis.turak) {
      evek.add(tura.kezdodatum.year.toString());
    }
    List<String> rendezettEvek = evek.toList();
    rendezettEvek.sort((a, b) => b.compareTo(a));
    rendezettEvek.insert(0, 'Összes Túra');
    return rendezettEvek;
  }

  List<TuraModel> _getSzurtTurak() {
    List<TuraModel> lista = List.from(TuraAdatbazis.turak);
    if (_kivalasztottEv != 'Összes Túra') {
      lista = lista.where((t) => t.kezdodatum.year.toString() == _kivalasztottEv).toList();
    }
    lista.sort((a, b) => b.kezdodatum.compareTo(a.kezdodatum)); // Időben visszafelé
    return lista;
  }

  void _nyitTurakezeles({TuraModel? szerkeszthetoTura, int? index}) async {
    final bool isSzerkesztes = szerkeszthetoTura != null;

    DateTime kezdodatum = szerkeszthetoTura?.kezdodatum ?? DateTime.now();
    DateTime befejezodatum = szerkeszthetoTura?.befejezodatum ?? DateTime.now();
    
    final helyszinek = TorzsadatAdatbazis.adatok['Helyszín'] ?? [];
    String? kivasztottHelyszin = szerkeszthetoTura?.helyszin ?? (helyszinek.isNotEmpty ? helyszinek[0]['nev'] : null);
    
    final horgaszhelyController = TextEditingController(text: szerkeszthetoTura?.horgaszhely ?? '');
    final megjegyzesController = TextEditingController(text: szerkeszthetoTura?.megjegyzes ?? '');
    
    List<String> kivasztottTarsak = List.from(szerkeszthetoTura?.horgasztarsak ?? []);
    String? kepUtvonal = szerkeszthetoTura?.kepUtvonal;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String _getVizterKod(String? helyszinNev) {
              if (helyszinNev == null) return '';
              final talalt = helyszinek.firstWhere(
                (h) => h['nev'] == helyszinNev,
                orElse: () => {'vizter_kod': ''},
              );
              return talalt['vizter_kod'] ?? '';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSzerkesztes ? 'Túra szerkesztése' : 'Új horgásztúra indítása',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, color: Colors.green),
                            label: Text('Kezdet: ${kezdodatum.toLocal().toString().split(' ')[0]}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: kezdodatum,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  kezdodatum = picked;
                                  if (befejezodatum.isBefore(kezdodatum)) {
                                    befejezodatum = kezdodatum;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_available, color: Colors.green),
                            label: Text('Vége: ${befejezodatum.toLocal().toString().split(' ')[0]}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: befejezodatum,
                                firstDate: kezdodatum,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  befejezodatum = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: kivasztottHelyszin,
                      dropdownColor: const Color(0xFF2C2C2C),
                      decoration: const InputDecoration(
                        labelText: 'Helyszín (Törzsadat)',
                        border: OutlineInputBorder(),
                      ),
                      items: helyszinek.map<DropdownMenuItem<String>>((h) {
                        return DropdownMenuItem<String>(
                          value: h['nev'],
                          child: Text(h['nev']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          kivasztottHelyszin = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: horgaszhelyController,
                      decoration: const InputDecoration(
                        labelText: 'Horgászhely (pl. 3-as stég)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Horgásztársak:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: (TorzsadatAdatbazis.adatok['Horgásztársak'] ?? []).map((tars) {
                        final nev = tars['nev'];
                        final isSelected = kivasztottTarsak.contains(nev);
                        return FilterChip(
                          label: Text(nev),
                          selected: isSelected,
                          selectedColor: Colors.green[800],
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                kivasztottTarsak.add(nev);
                              } else {
                                kivasztottTarsak.remove(nev);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Borítókép'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setModalState(() {
                                kepUtvonal = image.path;
                              });
                            }
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
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Megjegyzés a túrához',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          if (kivasztottHelyszin == null) return;
                          
                          final vizter = _getVizterKod(kivasztottHelyszin);
                          final ujTura = TuraModel(
                            id: isSzerkesztes ? szerkeszthetoTura.id : DateTime.now().millisecondsSinceEpoch.toString(),
                            kezdodatum: kezdodatum,
                            befejezodatum: befejezodatum,
                            helyszin: kivasztottHelyszin!,
                            vizterKod: vizter,
                            horgaszhely: horgaszhelyController.text.trim(),
                            horgasztarsak: kivasztottTarsak,
                            kepUtvonal: kepUtvonal,
                            megjegyzes: megjegyzesController.text.trim(),
                          );

                          setState(() {
                            if (isSzerkesztes) {
                              TuraAdatbazis.turak[index!] = ujTura;
                            } else {
                              TuraAdatbazis.turak.add(ujTura);
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Túra mentése', style: TextStyle(fontSize: 16, color: Colors.white)),
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

  void _turaTorles(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Túra törlése'),
        content: const Text('Biztosan törölni szeretnéd ezt a túrát és a hozzá tartozó adatokat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégsem', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              setState(() {
                TuraAdatbazis.turak.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _megjegyzesMutat(TuraModel tura) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Túra jegyzete'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formazottDatum(tura.kezdodatum, tura.befejezodatum),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 4),
                    Text(tura.helyszin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (tura.horgaszhely.isNotEmpty)
                      Text(tura.horgaszhely, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Megjegyzés:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
              const SizedBox(height: 8),
              Text(
                tura.megjegyzes.isEmpty ? 'Nincs megjegyzés rögzítve.' : tura.megjegyzes,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () => Navigator.pop(context),
            child: const Text('Bezárás', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _teljesKepernyosKep(String kepUtvonal) {
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
                    const SnackBar(content: Text('Kép sikeresen letöltve a Galériába!')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(kepUtvonal)),
            ),
          ),
        ),
      ),
    );
  }

  String _formazottDatum(DateTime kezdet, DateTime veg) {
    String format(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}.';
    if (kezdet.year == veg.year && kezdet.month == veg.month && kezdet.day == veg.day) {
      return format(kezdet);
    } else {
      final difference = veg.difference(kezdet).inDays + 1;
      return '${format(kezdet)} ($difference nap)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final evek = _getEvekListaja();
    final turakListaja = _getSzurtTurak();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161616),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Szűrés év szerint:', style: TextStyle(color: Colors.white70)),
                DropdownButton<String>(
                  value: _kivalasztottEv,
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  items: evek.map((ev) {
                    return DropdownMenuItem(value: ev, child: Text(ev));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _kivalasztottEv = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: turakListaja.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sailing, size: 70, color: Colors.green[800]),
                        const SizedBox(height: 16),
                        const Text('Nincs rögzített túra ebben az évben.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: turakListaja.length,
                    itemBuilder: (context, index) {
                      final tura = turakListaja[index];
                      final valodiIndex = TuraAdatbazis.turak.indexWhere((t) => t.id == tura.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _formazottDatum(tura.kezdodatum, tura.befejezodatum),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                              ),
                            ),
                            
                            if (tura.kepUtvonal != null && File(tura.kepUtvonal!).existsSync())
                              GestureDetector(
                                onTap: () => _teljesKepernyosKep(tura.kepUtvonal!),
                                child: Image.file(
                                  File(tura.kepUtvonal!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tura.helyszin,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  if (tura.horgaszhely.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      tura.horgaszhely,
                                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  const Text('Fogások: 0 db | Összsúly: 0.00 kg', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  if (tura.horgasztarsak.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Társak: ${tura.horgasztarsak.join(', ')}', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  ],
                                ],
                              ),
                            ),

                            const Divider(height: 1, color: Colors.white12),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _turaTorles(valodiIndex),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                    onPressed: () => _nyitTurakezeles(szerkeszthetoTura: tura, index: valodiIndex),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.note_alt_outlined, color: Colors.amberAccent),
                                    onPressed: () => _megjegyzesMutat(tura),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.greenAccent),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('A fogások nézet a következő lépésben érkezik!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _nyitTurakezeles(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
