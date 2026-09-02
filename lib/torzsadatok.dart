import 'dart:io';
import 'dart:ui' as ui; 
import 'dart:typed_data'; 
import 'package:flutter/rendering.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'adattarolo.dart';
import 'modellek.dart';
import 'felszereles.dart';

class TorzsadatokScreen extends StatefulWidget {
  const TorzsadatokScreen({super.key});

  @override
  State<TorzsadatokScreen> createState() => _TorzsadatokScreenState();
}

class _TorzsadatokScreenState extends State<TorzsadatokScreen> {
  final List<String> _kategoriak = [
    'Halfaj',
    'Felszerelés Kategória',
    'Felszerelés Tétel',
    'Horgászbot',
    'Horgászmódszer',
    'Végszerelék',
    'Csali',
    'Etetőanyag',
    'Helyszín',
    'Horgásztársak',
    'Időjárás',
    'Hal sorsa',
    'Táskák' 
  ];
  
  String _kivKategoria = 'Halfaj';
  String _keresesSzoveg = ''; 
  final _keresoCtrl = TextEditingController(); 
  
  List<Halfaj> _halfajok = [];
  List<Helyszin> _helyszinek = [];
  List<FelszerelesKategoria> _felszKategoriak = [];
  List<FelszerelesTetel> _felszTetelek = [];
  List<String> _simaLista = [];
  bool _folyamatban = false;

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    if (_kivKategoria == 'Halfaj') {
      _halfajok = await AdatTarolo.halfajokBetoltese();
      _halfajok.sort((a, b) => a.nev.toLowerCase().compareTo(b.nev.toLowerCase()));
      
    } else if (_kivKategoria == 'Helyszín') {
      _helyszinek = await AdatTarolo.helyszinekBetoltese();
      _helyszinek.sort((a, b) => a.nev.compareTo(b.nev)); 
    } else if (_kivKategoria == 'Felszerelés Kategória') {
      _felszKategoriak = await AdatTarolo.felszerelesKategoriakBetoltese();
    } else if (_kivKategoria == 'Felszerelés Tétel') {
      _felszTetelek = await AdatTarolo.felszerelesTetelekBetoltese();
      _felszTetelek.sort((a, b) => a.nev.compareTo(b.nev));
      _felszKategoriak = await AdatTarolo.felszerelesKategoriakBetoltese(); 
    } else {
      switch (_kivKategoria) {
        case 'Horgászbot': _simaLista = await AdatTarolo.botokBetoltese(); break;
        case 'Horgászmódszer': _simaLista = await AdatTarolo.modszerekBetoltese(); break;
        case 'Végszerelék': _simaLista = await AdatTarolo.szerelekekBetoltese(); break;
        case 'Csali': _simaLista = await AdatTarolo.csalikBetoltese(); break;
        case 'Etetőanyag': _simaLista = await AdatTarolo.etetoanyagokBetoltese(); break;
        case 'Horgásztársak': _simaLista = await AdatTarolo.tarsakBetoltese(); break;
        case 'Időjárás': _simaLista = await AdatTarolo.idojarasBetoltese(); break;
        case 'Hal sorsa': _simaLista = await AdatTarolo.sorsBetoltese(); break;
        case 'Táskák': _simaLista = await AdatTarolo.taskakBetoltese(); break;
      }
      _simaLista.sort(); 
    }
    setState(() {});
  }

  Future<void> _simaAdatMentes() async {
    switch (_kivKategoria) {
      case 'Horgászbot': await AdatTarolo.botokMentes(_simaLista); break;
      case 'Horgászmódszer': await AdatTarolo.modszerekMentes(_simaLista); break;
      case 'Végszerelék': await AdatTarolo.szerelekekMentes(_simaLista); break;
      case 'Csali': await AdatTarolo.csalikMentes(_simaLista); break;
      case 'Etetőanyag': await AdatTarolo.etetoanyagokMentes(_simaLista); break;
      case 'Horgásztársak': await AdatTarolo.tarsakMentes(_simaLista); break;
      case 'Időjárás': await AdatTarolo.idojarasMentes(_simaLista); break;
      case 'Hal sorsa': await AdatTarolo.sorsMentes(_simaLista); break;
      case 'Táskák': await AdatTarolo.taskakMentes(_simaLista); break; 
    }
  }

  void _simaAdatHozzaadasVagySzerkesztes([String? regiNev, int? index]) {
    final ctrl = TextEditingController(text: regiNev ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(regiNev == null ? 'Új $_kivKategoria hozzáadása' : '$_kivKategoria szerkesztése'),
        content: TextField(
          controller: ctrl, 
          autofocus: true, 
          textCapitalization: TextCapitalization.sentences, // ÚJ KÓD
          decoration: const InputDecoration(labelText: 'Megnevezés')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final ujNev = ctrl.text.trim();
                
                if (regiNev == null) {
                  _simaLista.add(ujNev);
                } else if (index != null) {
                  _simaLista[index] = ujNev;
                  if (regiNev != ujNev) {
                    await AdatTarolo.torzsadatNevFrissites(_kivKategoria, regiNev, ujNev);
                  }
                }
                
                await _simaAdatMentes();
                _adatokBetoltese(); 
                if (mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _helyszinHozzaadasVagySzerkesztes([Helyszin? regiHelyszin, int? index]) {
    final nevCtrl = TextEditingController(text: regiHelyszin?.nev ?? '');
    final kodCtrl = TextEditingController(text: regiHelyszin?.vizterKod ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(regiHelyszin == null ? 'Új Helyszín hozzáadása' : 'Helyszín szerkesztése'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nevCtrl, 
              autofocus: true, 
              textCapitalization: TextCapitalization.words, // ÚJ KÓD
              decoration: const InputDecoration(labelText: 'Helyszín neve *')
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kodCtrl, 
              textCapitalization: TextCapitalization.characters, // ÚJ KÓD
              decoration: const InputDecoration(labelText: 'Víztér kód (opcionális)')
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (nevCtrl.text.trim().isNotEmpty) {
                final ujHelyszin = Helyszin(
                  id: regiHelyszin?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  nev: nevCtrl.text.trim(),
                  vizterKod: kodCtrl.text.trim(),
                );
                
                if (regiHelyszin == null) {
                  _helyszinek.add(ujHelyszin);
                } else if (index != null) {
                  _helyszinek[index] = ujHelyszin;
                }
                
                await AdatTarolo.helyszinekMentes(_helyszinek);
                _adatokBetoltese(); 
                if (mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _felszerelesKategoriaHozzaadas([FelszerelesKategoria? kategoria, int? index]) {
    final ctrl = TextEditingController(text: kategoria?.nev ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(kategoria == null ? 'Új Kategória' : 'Kategória szerkesztése'),
        content: TextField(
          controller: ctrl, 
          autofocus: true, 
          textCapitalization: TextCapitalization.sentences, // ÚJ KÓD
          decoration: const InputDecoration(labelText: 'Név')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                if (kategoria == null) {
                  _felszKategoriak.add(FelszerelesKategoria(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nev: ctrl.text.trim(),
                    sorrend: _felszKategoriak.length,
                  ));
                } else if (index != null) {
                  _felszKategoriak[index] = FelszerelesKategoria(
                    id: kategoria.id,
                    nev: ctrl.text.trim(),
                    sorrend: kategoria.sorrend,
                  );
                }
                await AdatTarolo.felszerelesKategoriakMentes(_felszKategoriak);
                _adatokBetoltese();
                if (mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Mentés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _adatTorlese(int valodiIndex) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Törlés'),
        content: const Text('Biztosan törölni szeretnéd ezt a törzsadatot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              if (_kivKategoria == 'Halfaj') {
                String toroltNev = _halfajok[valodiIndex].nev;
                _halfajok.removeAt(valodiIndex);
                await AdatTarolo.halfajokMentes(_halfajok);
                await AdatTarolo.torzsadatTorles(_kivKategoria, toroltNev);
                
              } else if (_kivKategoria == 'Helyszín') {
                String toroltId = _helyszinek[valodiIndex].id;
                _helyszinek.removeAt(valodiIndex);
                await AdatTarolo.helyszinekMentes(_helyszinek);
                await AdatTarolo.torzsadatTorles(_kivKategoria, toroltId); 
                
              } else if (_kivKategoria == 'Felszerelés Kategória') {
                bool inUse = _felszTetelek.any((t) => t.kategoriaId == _felszKategoriak[valodiIndex].id);
                if (inUse) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nem törölhető, mert vannak benne tételek!')));
                  return;
                }
                _felszKategoriak.removeAt(valodiIndex);
                await AdatTarolo.felszerelesKategoriakMentes(_felszKategoriak);
              } else if (_kivKategoria == 'Felszerelés Tétel') {
                _felszTetelek.removeAt(valodiIndex);
                await AdatTarolo.felszerelesTetelekMentes(_felszTetelek);
              } else {
                String toroltNev = _simaLista[valodiIndex];
                _simaLista.removeAt(valodiIndex);
                await _simaAdatMentes();
                await AdatTarolo.torzsadatTorles(_kivKategoria, toroltNev);
              }
              
              setState(() {});
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mutassOkosMenut() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$_kivKategoria Beállítások', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent), textAlign: TextAlign.center),
              const Divider(color: Colors.white24, height: 30),
              
              if (_kivKategoria == 'Halfaj' || _kivKategoria == 'Felszerelés Tétel') ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.all(14)),
                  icon: const Icon(Icons.file_upload, color: Colors.white),
                  label: const Text('Képcsomag feltöltése (.zip)', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _kepCsomagFeltoltese();
                  },
                ),
                const SizedBox(height: 12),
              ],
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], padding: const EdgeInsets.all(14)),
                icon: const Icon(Icons.restore, color: Colors.white),
                label: const Text('Gyári alapértékek visszaállítása', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _gyariVisszaallitas();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _gyariVisszaallitas() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Gyári Visszaállítás', style: TextStyle(color: Colors.orangeAccent)),
        content: const Text('Ez a funkció visszapótolja a hiányzó gyári adatokat.\n\nA saját, egyedi hozzáadott adataidat NEM módosítja és NEM törli! Biztosan folytatod?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _folyamatban = true);
              
              if (_kivKategoria == 'Halfaj') await AdatTarolo.gyariHalfajokVisszaallitas();
              if (_kivKategoria == 'Időjárás') await AdatTarolo.gyariIdojarasVisszaallitas();
              if (_kivKategoria == 'Hal sorsa') await AdatTarolo.gyariSorsVisszaallitas();
              if (_kivKategoria == 'Felszerelés Kategória') await AdatTarolo.gyariFelszerelesKategoriakVisszaallitas();
              
              await _adatokBetoltese();
              setState(() => _folyamatban = false);
              
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gyári adatok sikeresen visszapótolva!')));
            },
            child: const Text('Igen, visszaállítom', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _kepCsomagFeltoltese() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Képcsomag feltöltése', style: TextStyle(color: Colors.blueAccent)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tölts fel egy .zip fájlt a hivatalos képekkel. Fontos, hogy a képek fájlnevei szigorúan a lenti szabályokat kövessék!', style: TextStyle(fontSize: 14)),
              SizedBox(height: 12),
              Text('Névadási szabályok:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              Text('• Csak az angol ábécé kisbetűi (ékezetek nélkül)\n• Szóközök helyett alsóvonal (_)\n• A zárójeleket és a bennük lévő szöveget hagyd el!', style: TextStyle(fontSize: 14)),
              SizedBox(height: 12),
              Text('A fájl végén ott kell lennie a kép sorszámának (_1, _2 vagy _3). Pl.: ponty_1.jpg. Ha egy fajhoz ennél több képet csomagolsz be, a program figyelmen kívül hagyja őket.', style: TextStyle(fontSize: 13, color: Colors.orangeAccent)),
              SizedBox(height: 12),
              Text('Gyakori példák:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Ponty -> ponty_1.jpg\nSzivárványos pisztráng -> szivarvanyos_pisztrang_1.jpg\nSüllő (Fogas) -> sullo_1.jpg\nBuffalo (Nagyszájú buffalo) -> buffalo_1.jpg', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
            onPressed: () async {
              Navigator.pop(dialogContext); // ITT VOLT A HIBA JAVÍTÁSA: A helyes ablakot zárjuk be!
              
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
              if (result != null && result.files.single.path != null) {
                setState(() => _folyamatban = true);
                try {
                  final statisztika = await AdatTarolo.dlcKepCsomagKicsomagolasa(result.files.single.path!);
                  await _adatokBetoltese();
                  setState(() => _folyamatban = false);
                  
                  if (mounted) {
                    showDialog(
                      context: context, // ITT MÁR A FŐKÉPERNYŐ AKTÍV ABLAKÁT HASZNÁLJUK
                      builder: (innerContext) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.greenAccent),
                            SizedBox(width: 8),
                            Text('Sikeres feltöltés!', style: TextStyle(color: Colors.greenAccent)),
                          ],
                        ),
                        content: Text(
                          'A képcsomag feldolgozása befejeződött.\n\n'
                          '• ZIP-ben talált képek: ${statisztika['osszes']} db\n'
                          '• Halfajokhoz illesztve: ${statisztika['hozzaadva']} db',
                          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                            onPressed: () => Navigator.pop(innerContext), 
                            child: const Text('Rendben', style: TextStyle(color: Colors.white))
                          )
                        ]
                      )
                    );
                  }
                } catch (e) {
                  setState(() => _folyamatban = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hiba a kicsomagolás során: $e'), backgroundColor: Colors.redAccent));
                  }
                }
              }
            },
            child: const Text('.ZIP Kiválasztása', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool mutatFogaskereket = ['Halfaj', 'Időjárás', 'Hal sorsa', 'Felszerelés Kategóriák'].contains(_kivKategoria);

    List<dynamic> szurtAdatok = [];
    if (_kivKategoria == 'Halfaj') {
      szurtAdatok = _halfajok.where((h) => h.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase())).toList();
    } else if (_kivKategoria == 'Helyszín') {
      szurtAdatok = _helyszinek.where((h) => h.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase())).toList();
    } else if (_kivKategoria == 'Felszerelés Kategória') {
      szurtAdatok = _felszKategoriak.where((k) => k.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase())).toList();
    } else if (_kivKategoria == 'Felszerelés Tétel') {
      szurtAdatok = _felszTetelek.where((t) => t.nev.toLowerCase().contains(_keresesSzoveg.toLowerCase())).toList();
    } else {
      szurtAdatok = _simaLista.where((s) => s.toLowerCase().contains(_keresesSzoveg.toLowerCase())).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Törzsadatok Kezelése')),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF161616),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Kategória:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _kivKategoria,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E1E1E),
                            items: _kategoriak.map((k) => DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _kivKategoria = val;
                                  _keresesSzoveg = ''; 
                                  _keresoCtrl.clear();
                                });
                                _adatokBetoltese();
                              }
                            },
                          ),
                        ),
                        if (mutatFogaskereket)
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white54),
                            onPressed: _mutassOkosMenut,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _keresoCtrl,
                      textCapitalization: TextCapitalization.sentences, // ÚJ KÓD
                      decoration: InputDecoration(
                        hintText: 'Keresés a listában...',
                        prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.redAccent),
                          onPressed: () {
                            _keresoCtrl.clear();
                            setState(() => _keresesSzoveg = '');
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) => setState(() => _keresesSzoveg = val),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: szurtAdatok.isEmpty 
                  ? const Center(child: Text('Nincs találat a keresésre.', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80),
                  itemCount: szurtAdatok.length,
                  itemBuilder: (context, index) {
                    String megjelenitettNev = '';
                    String alcim = '';
                    int valodiIndex = -1;
                    
                    if (_kivKategoria == 'Halfaj') {
                      valodiIndex = _halfajok.indexOf(szurtAdatok[index] as Halfaj);
                      megjelenitettNev = _halfajok[valodiIndex].nev;
                    } else if (_kivKategoria == 'Helyszín') {
                      valodiIndex = _helyszinek.indexOf(szurtAdatok[index] as Helyszin);
                      final hely = _helyszinek[valodiIndex];
                      megjelenitettNev = hely.nev;
                      if (hely.vizterKod != null && hely.vizterKod!.isNotEmpty) {
                        alcim = 'Víztérkód: ${hely.vizterKod}';
                      }
                    } else if (_kivKategoria == 'Felszerelés Kategória') {
                      valodiIndex = _felszKategoriak.indexOf(szurtAdatok[index] as FelszerelesKategoria);
                      megjelenitettNev = _felszKategoriak[valodiIndex].nev;
                    } else if (_kivKategoria == 'Felszerelés Tétel') {
                      valodiIndex = _felszTetelek.indexOf(szurtAdatok[index] as FelszerelesTetel);
                      final tetel = _felszTetelek[valodiIndex];
                      megjelenitettNev = tetel.nev;
                      final kat = _felszKategoriak.firstWhere((k) => k.id == tetel.kategoriaId, orElse: () => FelszerelesKategoria(id: '', nev: 'Ismeretlen'));
                      alcim = kat.nev;
                    } else {
                      valodiIndex = _simaLista.indexOf(szurtAdatok[index] as String);
                      megjelenitettNev = _simaLista[valodiIndex];
                    }

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(megjelenitettNev, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: alcim.isNotEmpty 
                          ? Text(alcim, style: _kivKategoria == 'Helyszín' ? const TextStyle(fontSize: 16, color: Colors.white70) : const TextStyle(color: Colors.greenAccent, fontSize: 12)) 
                          : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70),
                              onPressed: () {
                                if (_kivKategoria == 'Halfaj') {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => HalfajSzerkesztoScreen(
                                    szerkeszthetoHalfaj: _halfajok[valodiIndex],
                                    mentesCallback: (modositottHal) async {
                                      String regiNev = _halfajok[valodiIndex].nev;
                                      _halfajok[valodiIndex] = modositottHal;
                                      await AdatTarolo.halfajokMentes(_halfajok);
                                      if (regiNev != modositottHal.nev) {
                                        await AdatTarolo.torzsadatNevFrissites('Halfaj', regiNev, modositottHal.nev);
                                      }
                                      _adatokBetoltese(); 
                                    },
                                  )));
                                } else if (_kivKategoria == 'Felszerelés Tétel') {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => TetelSzerkesztoScreen(
                                    kategoriak: _felszKategoriak,
                                    szerkeszthetoTetel: _felszTetelek[valodiIndex],
                                    mentesCallback: () => _adatokBetoltese(),
                                  )));
                                } else if (_kivKategoria == 'Felszerelés Kategória') {
                                  _felszerelesKategoriaHozzaadas(_felszKategoriak[valodiIndex], valodiIndex);
                                } else if (_kivKategoria == 'Helyszín') {
                                  _helyszinHozzaadasVagySzerkesztes(_helyszinek[valodiIndex], valodiIndex);
                                } else {
                                  _simaAdatHozzaadasVagySzerkesztes(_simaLista[valodiIndex], valodiIndex);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _adatTorlese(valodiIndex),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          if (_folyamatban)
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
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (_kivKategoria == 'Halfaj') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HalfajSzerkesztoScreen(
              mentesCallback: (ujHal) async {
                _halfajok.add(ujHal);
                await AdatTarolo.halfajokMentes(_halfajok);
                _adatokBetoltese(); 
              },
            )));
          } else if (_kivKategoria == 'Felszerelés Tétel') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => TetelSzerkesztoScreen(
              kategoriak: _felszKategoriak,
              mentesCallback: () => _adatokBetoltese(),
            )));
          } else if (_kivKategoria == 'Felszerelés Kategória') {
            _felszerelesKategoriaHozzaadas();
          } else if (_kivKategoria == 'Helyszín') {
            _helyszinHozzaadasVagySzerkesztes();
          } else {
            _simaAdatHozzaadasVagySzerkesztes();
          }
        },
      ),
    );
  }
}

class HalfajSzerkesztoScreen extends StatefulWidget {
  final Halfaj? szerkeszthetoHalfaj;
  final Function(Halfaj) mentesCallback;

  const HalfajSzerkesztoScreen({super.key, this.szerkeszthetoHalfaj, required this.mentesCallback});

  @override
  State<HalfajSzerkesztoScreen> createState() => _HalfajSzerkesztoScreenState();
}

class _HalfajSzerkesztoScreenState extends State<HalfajSzerkesztoScreen> {
  final _nevCtrl = TextEditingController();
  final _meretCtrl = TextEditingController();
  final _darabCtrl = TextEditingController();
  final _tilalomCtrl = TextEditingController();
  final _evCtrl = TextEditingController(text: '2024');
  final _megjegyzesCtrl = TextEditingController();

  String? _kivalasztottKategoria;
  String? _kivalasztottStatusz;
  
  List<String> _kepek = []; 
  
  String? _indexKep; 
  bool _isThumbnailSzerkesztes = false;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _cropperKey = GlobalKey();

  final List<String> _kategoriak = ['Békés', 'Ragadozó'];
  final List<String> _statuszok = ['Fogható (Őshonos)', 'Fogható (Idegenhonos)', 'Inváziós', 'Nem fogható', 'Védett'];

  @override
  void initState() {
    super.initState();
    if (widget.szerkeszthetoHalfaj != null) {
      final h = widget.szerkeszthetoHalfaj!;
      _indexKep = h.indexKep;
      
      _nevCtrl.text = h.nev;
      _kivalasztottKategoria = h.kategoria.isNotEmpty ? h.kategoria : null;
      _kivalasztottStatusz = h.statusz.isNotEmpty ? h.statusz : null;
      
      if (_kivalasztottStatusz == 'Fogható') {
        _kivalasztottStatusz = 'Fogható (Őshonos)';
      }

      _meretCtrl.text = h.meretKorlatozas;
      _darabCtrl.text = h.darabKorlatozas;
      _tilalomCtrl.text = h.tilalmiIdoszak;
      _evCtrl.text = h.szabalyozasEve;
      _megjegyzesCtrl.text = h.megjegyzes;
      _kepek = List.from(h.kepek);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _nevCtrl.dispose();
    _meretCtrl.dispose();
    _darabCtrl.dispose();
    _tilalomCtrl.dispose();
    _evCtrl.dispose();
    _megjegyzesCtrl.dispose();
    super.dispose();
  }

  Future<void> _kepHozzaadasa() async {
    if (_kepek.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 képet adhatsz hozzá!')));
      return;
    }
    
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      int szabadHely = 5 - _kepek.length;
      int hozzaadandoSzam = images.length > szabadHely ? szabadHely : images.length;
      
      for (int i = 0; i < hozzaadandoSzam; i++) {
        String biztonsagosUtvonal = await AdatTarolo.biztonsagosKepMasolas(images[i].path);
        setState(() {
          _kepek.add(biztonsagosUtvonal);
          if (_kepek.length == 1 && _indexKep == null) {
            _indexKep = biztonsagosUtvonal;
          }
        });
      }
      
      if (images.length > szabadHely && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Csak $szabadHely képet lehetett még hozzáadni a limit miatt!'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }
  
  Future<void> _thumbnailMentese() async {
    try {
      RenderRepaintBoundary? boundary = _cropperKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isThumbnailSzerkesztes = false);
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Nem sikerült a kép konvertálása.');
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final appDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${appDir.path}/kepek');
      if (!await thumbDir.exists()) await thumbDir.create(recursive: true);
      
      final thumbPath = '${thumbDir.path}/thumb_halfaj_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(thumbPath).writeAsBytes(pngBytes);

      setState(() {
        _indexKep = thumbPath;
        _isThumbnailSzerkesztes = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indexkép sikeresen frissítve!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba az indexkép mentésekor: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _isThumbnailSzerkesztes = false);
      }
    }
  }

  void _mutassStatuszInfot() {
    final ScrollController scrollController = ScrollController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Státuszok Jelentése', style: TextStyle(color: Colors.greenAccent)),
        content: SizedBox(
          width: double.maxFinite,
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSor(Colors.green, 'Fogható (Őshonos)', 'Megtartható a méret-, tilalmi idő- és darabszám-korlátozások betartásával.'),
                    _buildInfoSor(Colors.lightGreenAccent, 'Fogható (Idegenhonos)', 'Szabadon fogható, betelepített halak. Országos méret-, és darabkorlátozás, valamint tilalmi idő nem vonatkozik rájuk (helyi horgászrend ettől eltérhet).'),
                    _buildInfoSor(Colors.red, 'Inváziós', 'Az inváziós halak olyan halfajok, amelyek egy számukra nem őshonos területre kerülnek, ott elszaporodnak, és közben káros hatással lehetnek a helyi élővilágra. Kifogásuk esetén ezeket a halakat nem szabad visszaengedni, el kell távolítani a víztérből.'),
                    _buildInfoSor(Colors.white70, 'Nem fogható', 'Nem állnak szigorú természetvédelmi oltalom alatt, de a halgazdálkodási törvény (és a MOHOSZ Országos Horgászrendje) állományvédelmi okokból tiltja a kifogásukat és az elvitelüket. Kifogásuk esetén ugyanúgy azonnal és kíméletesen vissza kell őket engedni a vízbe.'),
                    _buildInfoSor(Colors.blue, 'Védett', 'A természetvédelmi törvény hatálya alá tartoznak. Ezeknek a halaknak hivatalos, pénzben kifejezett természetvédelmi (eszmei) értékük van (pl. 10 000 Ft-tól akár 250 000 Ft-ig). Kifejezetten ritka, veszélyeztetett, vagy bennszülött (endemikus) fajok. Nem tartható meg, azonnal és kíméletesen vissza kell engedni.'),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bezárás', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSor(Color szin, String cim, String leiras) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: szin, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(cim, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 4),
          Text(leiras, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3)),
        ],
      ),
    );
  }

  void _mentes() {
    if (_nevCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A hal neve kötelező!')));
      return;
    }

    final ujHalfaj = Halfaj(
      id: widget.szerkeszthetoHalfaj?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nev: _nevCtrl.text.trim(),
      kategoria: _kivalasztottKategoria ?? '',
      statusz: _kivalasztottStatusz ?? '',
      meretKorlatozas: _meretCtrl.text.trim(),
      darabKorlatozas: _darabCtrl.text.trim(),
      tilalmiIdoszak: _tilalomCtrl.text.trim(),
      szabalyozasEve: _evCtrl.text.trim(),
      megjegyzes: _megjegyzesCtrl.text.trim(),
      kepek: _kepek, 
      indexKep: _indexKep,
    );

    widget.mentesCallback(ujHalfaj);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.szerkeszthetoHalfaj == null ? 'Új Halfaj Hozzáadása' : 'Halfaj Szerkesztése')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nevCtrl, 
              autofocus: widget.szerkeszthetoHalfaj == null, 
              textCapitalization: TextCapitalization.sentences, // ÚJ KÓD
              decoration: const InputDecoration(labelText: 'Halfaj neve *', border: OutlineInputBorder())
            ),
            const SizedBox(height: 16),
            
            const Divider(height: 40, color: Colors.white24),

            const Text('Listanézeti Indexkép (Thumbnail)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Állítsd be a borítóképet! Két ujjal nagyíthatod és mozgathatod a fotót a zöld kereten belül. A főképernyőn lévő listákban pontosan az a részlet fog megjelenni, amit most ebben a kockában látsz.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            
            Center(
              child: Container(
                width: 244,
                height: 244,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent, width: 2), 
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), 
                  child: RepaintBoundary(
                    key: _cropperKey,
                    child: Container(
                      width: 240, 
                      height: 240, 
                      color: Colors.black, 
                      child: _isThumbnailSzerkesztes && _kepek.isNotEmpty
                          ? InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 1.0,
                              maxScale: 4.0,
                              boundaryMargin: EdgeInsets.zero,
                              clipBehavior: Clip.none, 
                              child: SizedBox(
                                width: 240,
                                height: 240,
                                child: _kepek.first.startsWith('http')
                                    ? CachedNetworkImage(imageUrl: _kepek.first, fit: BoxFit.contain)
                                    : Image.file(File(_kepek.first), fit: BoxFit.contain),
                              ),
                            )
                          : (_indexKep != null && (_indexKep!.startsWith('http') || File(_indexKep!).existsSync())
                              ? (_indexKep!.startsWith('http') ? CachedNetworkImage(imageUrl: _indexKep!, fit: BoxFit.contain) : Image.file(File(_indexKep!), fit: BoxFit.contain))
                              : (_kepek.isNotEmpty && (_kepek.first.startsWith('http') || File(_kepek.first).existsSync())
                                  ? (_kepek.first.startsWith('http') ? CachedNetworkImage(imageUrl: _kepek.first, fit: BoxFit.contain) : Image.file(File(_kepek.first), fit: BoxFit.contain))
                                  : const Icon(Icons.set_meal, color: Colors.white24, size: 60))),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _isThumbnailSzerkesztes
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      onPressed: _thumbnailMentese,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('OK (Mentés)', style: TextStyle(color: Colors.white)),
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent)),
                      onPressed: () {
                        if (_kepek.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Előbb tölts fel legalább egy képet!')));
                          return;
                        }
                        setState(() => _isThumbnailSzerkesztes = true);
                      },
                      icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                      label: const Text('Indexkép Frissítése / Beállítása', style: TextStyle(color: Colors.greenAccent)),
                    ),
            ),
            
            const Divider(height: 40, color: Colors.white24),

            const Text('Fényképek (Maximum 5 db - Húzd át a sorrendhez!)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _kepek.removeAt(oldIndex);
                    _kepek.insert(newIndex, item);
                  });
                },
                children: [
                  for (int idx = 0; idx < _kepek.length; idx++)
                    Container(
                      key: ValueKey(_kepek[idx]),
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                            clipBehavior: Clip.antiAlias,
                            child: _kepek[idx].startsWith('http')
                                ? CachedNetworkImage(imageUrl: _kepek[idx], fit: BoxFit.cover)
                                : Image.file(File(_kepek[idx]), fit: BoxFit.cover),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _kepek.removeAt(idx)),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                              child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                            ),
                          ),
                          if (idx == 0)
                            Positioned(
                              bottom: 4, left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                child: const Text('thumbnail', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            )
                        ],
                      ),
                    ),
                  if (_kepek.length < 5)
                    GestureDetector(
                      key: const ValueKey('add_button'),
                      onTap: _kepHozzaadasa,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent, width: 2, style: BorderStyle.solid),
                        ),
                        child: const Center(
                          child: Icon(Icons.add_a_photo, color: Colors.greenAccent, size: 30),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _kivalasztottKategoria,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategória', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Válassz kategóriát --')),
                ..._kategoriak.map((k) => DropdownMenuItem(value: k, child: Text(k))),
              ],
              onChanged: (val) => setState(() => _kivalasztottKategoria = val),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _kivalasztottStatusz,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Státusz', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-- Válassz státuszt --')),
                      ..._statuszok.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (val) => setState(() => _kivalasztottStatusz = val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.greenAccent, size: 28),
                  onPressed: _mutassStatuszInfot,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _meretCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Méretkorlátozás (pl. 30 cm)', border: OutlineInputBorder()))), // ÚJ KÓD
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _darabCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Darabkorlát (pl. 3 db)', border: OutlineInputBorder()))), // ÚJ KÓD
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _tilalomCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Tilalmi időszak (pl. 05.02 - 05.31)', border: OutlineInputBorder())), // ÚJ KÓD
            const SizedBox(height: 16),
            TextField(controller: _evCtrl, decoration: const InputDecoration(labelText: 'Szabályozás éve', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _megjegyzesCtrl, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Leírás / Megjegyzés', border: OutlineInputBorder())), // ÚJ KÓD
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _mentes,
              child: const Text('HALFAJ MENTÉSE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
