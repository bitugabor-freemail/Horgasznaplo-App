import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'adattarolo.dart';
import 'modellek.dart';

class JegyzetekScreen extends StatefulWidget {
  const JegyzetekScreen({super.key});

  @override
  State<JegyzetekScreen> createState() => _JegyzetekScreenState();
}

class _JegyzetekScreenState extends State<JegyzetekScreen> {
  List<Jegyzet> _jegyzetek = [];
  bool _isKeresoMod = false;
  String _keresoKifejezes = '';
  final TextEditingController _keresoCtrl = TextEditingController();

  final List<Color> _valaszthatoSzinek = [
    const Color(0xFF1E1E1E), // Alap sötétszürke
    const Color(0xFF3E2723), // Sötétbarna
    const Color(0xFF263238), // Kékes-szürke
    const Color(0xFF1B5E20).withOpacity(0.4), // Sötétzöld
    const Color(0xFF01579B).withOpacity(0.4), // Sötétkék
    const Color(0xFFb71c1c).withOpacity(0.4), // Sötétvörös
    const Color(0xFF4A148C).withOpacity(0.4), // Sötétlila
    const Color(0xFFE65100).withOpacity(0.4), // Sötét narancs
  ];

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final adatok = await AdatTarolo.jegyzetekBetoltese();
    setState(() {
      _jegyzetek = adatok;
    });
  }

  Future<void> _sorrendMentes() async {
    for (int i = 0; i < _jegyzetek.length; i++) {
      _jegyzetek[i].sorrend = i;
    }
    await AdatTarolo.jegyzetekMentes(_jegyzetek);
  }

  void _jegyzetTorlese(Jegyzet jegyzet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Jegyzet törlése', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Biztosan törölni szeretnéd ezt a jegyzetet? Ez a művelet nem vonható vissza!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              setState(() {
                _jegyzetek.removeWhere((j) => j.id == jegyzet.id);
              });
              await _sorrendMentes();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _szinValasztas(Jegyzet jegyzet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Háttérszín választása'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _valaszthatoSzinek.map((szin) {
            bool isKivalasztva = jegyzet.szin == szin.value;
            return GestureDetector(
              onTap: () async {
                setState(() {
                  jegyzet.szin = szin.value;
                });
                await _sorrendMentes();
                if (mounted) Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: szin,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isKivalasztva ? Colors.greenAccent : Colors.white24,
                    width: isKivalasztva ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bezár', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  void _jegyzetSzerkesztoNyitasa([Jegyzet? jegyzet]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JegyzetSzerkesztoScreen(
          szerkeszthetoJegyzet: jegyzet,
          mentesCallback: (ujJegyzet) async {
            setState(() {
              if (jegyzet != null) {
                final idx = _jegyzetek.indexWhere((j) => j.id == ujJegyzet.id);
                if (idx != -1) _jegyzetek[idx] = ujJegyzet;
              } else {
                ujJegyzet.sorrend = _jegyzetek.length;
                _jegyzetek.add(ujJegyzet);
              }
            });
            await _sorrendMentes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Jegyzet> mutatottJegyzetek = _jegyzetek;
    
    if (_keresoKifejezes.trim().isNotEmpty) {
      final keresoSzoveg = _keresoKifejezes.toLowerCase();
      mutatottJegyzetek = _jegyzetek.where((j) {
        return j.cim.toLowerCase().contains(keresoSzoveg) || j.szoveg.toLowerCase().contains(keresoSzoveg);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: _isKeresoMod
            ? TextField(
                controller: _keresoCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Keresés jegyzetekben...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _keresoKifejezes = val),
              )
            : const Text('Jegyzetek'),
        actions: [
          IconButton(
            icon: Icon(_isKeresoMod ? Icons.close : Icons.search, color: Colors.greenAccent),
            onPressed: () {
              setState(() {
                _isKeresoMod = !_isKeresoMod;
                if (!_isKeresoMod) {
                  _keresoKifejezes = '';
                  _keresoCtrl.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _jegyzetek.isEmpty
          ? const Center(
              child: Text(
                'Még nincsenek jegyzeteid.\nKattints a + gombra egy újhoz!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : mutatottJegyzetek.isEmpty
              ? const Center(child: Text('Nincs találat a keresésre.', style: TextStyle(color: Colors.white54)))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100), // Alsó térköz a gomb miatt
                  itemCount: mutatottJegyzetek.length,
                  // Keresés közben kikapcsoljuk az átrendezést, mert a szűrt lista indexei eltérnek a valóditól!
                  buildDefaultDragHandles: _keresoKifejezes.isEmpty,
                  onReorder: (oldIndex, newIndex) {
                    if (_keresoKifejezes.isNotEmpty) return; // Szűrés közben ne lehessen
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _jegyzetek.removeAt(oldIndex);
                      _jegyzetek.insert(newIndex, item);
                    });
                    _sorrendMentes();
                  },
                  itemBuilder: (context, index) {
                    final jegyzet = mutatottJegyzetek[index];
                    return Card(
                      key: ValueKey(jegyzet.id),
                      color: Color(jegyzet.szin),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JegyzetReszletekScreen(
                                jegyzet: jegyzet,
                                onEdit: () {
                                  Navigator.pop(context);
                                  _jegyzetSzerkesztoNyitasa(jegyzet);
                                },
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 32.0), // Hely a 3 pontnak
                                    child: Text(
                                      jegyzet.cim.isNotEmpty ? jegyzet.cim : 'Névtelen jegyzet',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    jegyzet.szoveg.isNotEmpty ? jegyzet.szoveg : 'Üres jegyzet...',
                                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  // Ha van kép, jelezzük ikonnal (és hagyjunk neki helyet)
                                  if (jegyzet.kepek.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                  ]
                                ],
                              ),
                              
                              // 3-pontos menü jobb felül
                              Positioned(
                                top: -12,
                                right: -12,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                                  color: const Color(0xFF2C2C2C),
                                  onSelected: (value) {
                                    if (value == 'edit') _jegyzetSzerkesztoNyitasa(jegyzet);
                                    if (value == 'color') _szinValasztas(jegyzet);
                                    if (value == 'delete') _jegyzetTorlese(jegyzet);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Szerkesztés')),
                                    const PopupMenuItem(value: 'color', child: Text('Szín módosítása')),
                                    const PopupMenuItem(value: 'delete', child: Text('Törlés', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              ),

                              // Kép indikátor jobb alul
                              if (jegyzet.kepek.isNotEmpty)
                                Positioned(
                                  bottom: -4,
                                  right: 0,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.attach_file, size: 14, color: Colors.white54),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.image, size: 16, color: Colors.white54),
                                      const SizedBox(width: 4),
                                      Text('${jegyzet.kepek.length}', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _jegyzetSzerkesztoNyitasa(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --- RÉSZLETES NÉZET ---
class JegyzetReszletekScreen extends StatelessWidget {
  final Jegyzet jegyzet;
  final VoidCallback onEdit;
  final PageController _pageCtrl = PageController();

  JegyzetReszletekScreen({super.key, required this.jegyzet, required this.onEdit});

  void _teljesKepernyosGaleria(BuildContext context, int kezdoIndex) {
    final PageController fullPageCtrl = PageController(initialPage: kezdoIndex);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: fullPageCtrl,
            itemCount: jegyzet.kepek.length,
            itemBuilder: (context, i) {
              final utvonal = jegyzet.kepek[i];
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: utvonal.startsWith('http')
                    ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.contain)
                    : Image.file(File(utvonal), fit: BoxFit.contain),
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(jegyzet.szin), // Felvesszük a jegyzet háttérszínét
      appBar: AppBar(
        title: Text(jegyzet.cim.isNotEmpty ? jegyzet.cim : 'Jegyzet Részletei'),
        backgroundColor: Colors.black12,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jegyzet.szoveg.isNotEmpty ? jegyzet.szoveg : 'Nincs szöveg...',
              style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.6),
            ),
            
            if (jegyzet.kepek.isNotEmpty) ...[
              const SizedBox(height: 40),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text('Csatolt képek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: jegyzet.kepek.length,
                      itemBuilder: (context, i) {
                        final utvonal = jegyzet.kepek[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => _teljesKepernyosGaleria(context, i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (utvonal.startsWith('http'))
                                ? CachedNetworkImage(imageUrl: utvonal, fit: BoxFit.cover)
                                : (File(utvonal).existsSync() ? Image.file(File(utvonal), fit: BoxFit.cover) : const Icon(Icons.broken_image, size: 50, color: Colors.white24)),
                            ),
                          ),
                        );
                      },
                    ),
                    if (jegyzet.kepek.length > 1) ...[
                      Positioned(
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () => _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (jegyzet.kepek.length > 1)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Lapozz a többi képért ↔', style: TextStyle(color: Colors.white38, fontSize: 12)),
                )),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: onEdit,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// --- SZERKESZTŐ NÉZET ---
class JegyzetSzerkesztoScreen extends StatefulWidget {
  final Jegyzet? szerkeszthetoJegyzet;
  final Function(Jegyzet) mentesCallback;

  const JegyzetSzerkesztoScreen({super.key, this.szerkeszthetoJegyzet, required this.mentesCallback});

  @override
  State<JegyzetSzerkesztoScreen> createState() => _JegyzetSzerkesztoScreenState();
}

class _JegyzetSzerkesztoScreenState extends State<JegyzetSzerkesztoScreen> {
  final _cimCtrl = TextEditingController();
  final _szovegCtrl = TextEditingController();
  List<String> _kepek = [];
  int _kivalasztottSzin = 0xFF1E1E1E; // Alap szín

  final List<Color> _valaszthatoSzinek = [
    const Color(0xFF1E1E1E), 
    const Color(0xFF3E2723), 
    const Color(0xFF263238), 
    const Color(0xFF1B5E20).withOpacity(0.4), 
    const Color(0xFF01579B).withOpacity(0.4), 
    const Color(0xFFb71c1c).withOpacity(0.4), 
    const Color(0xFF4A148C).withOpacity(0.4), 
    const Color(0xFFE65100).withOpacity(0.4), 
  ];

  @override
  void initState() {
    super.initState();
    if (widget.szerkeszthetoJegyzet != null) {
      _cimCtrl.text = widget.szerkeszthetoJegyzet!.cim;
      _szovegCtrl.text = widget.szerkeszthetoJegyzet!.szoveg;
      _kepek = List.from(widget.szerkeszthetoJegyzet!.kepek);
      _kivalasztottSzin = widget.szerkeszthetoJegyzet!.szin;
    }
  }

  @override
  void dispose() {
    _cimCtrl.dispose();
    _szovegCtrl.dispose();
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
        });
      }
    }
  }

  void _szinValasztas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Háttérszín választása'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _valaszthatoSzinek.map((szin) {
            bool isKivalasztva = _kivalasztottSzin == szin.value;
            return GestureDetector(
              onTap: () {
                setState(() => _kivalasztottSzin = szin.value);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: szin,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isKivalasztva ? Colors.greenAccent : Colors.white24,
                    width: isKivalasztva ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _mentes() {
    if (_cimCtrl.text.trim().isEmpty && _szovegCtrl.text.trim().isEmpty && _kepek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A jegyzet teljesen üres, nincs mit menteni!')));
      return;
    }

    final ujJegyzet = Jegyzet(
      id: widget.szerkeszthetoJegyzet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cim: _cimCtrl.text.trim(),
      szoveg: _szovegCtrl.text.trim(),
      kepek: _kepek,
      szin: _kivalasztottSzin,
      letrehozva: widget.szerkeszthetoJegyzet?.letrehozva ?? DateTime.now(),
      sorrend: widget.szerkeszthetoJegyzet?.sorrend ?? 0,
    );

    widget.mentesCallback(ujJegyzet);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_kivalasztottSzin),
      appBar: AppBar(
        title: Text(widget.szerkeszthetoJegyzet == null ? 'Új Jegyzet' : 'Jegyzet Szerkesztése'),
        backgroundColor: Colors.black12,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette, color: Colors.white),
            tooltip: 'Szín választása',
            onPressed: _szinValasztas,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            tooltip: 'Mentés',
            onPressed: _mentes,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _cimCtrl,
              autofocus: widget.szerkeszthetoJegyzet == null,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Cím',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 22),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white24),
            TextField(
              controller: _szovegCtrl,
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Írd ide a jegyzeted...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Fényképek (Max 5 db)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
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
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white38, width: 2, style: BorderStyle.solid),
                        ),
                        child: const Center(
                          child: Icon(Icons.add_a_photo, color: Colors.white54, size: 30),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Alsó kilógás
          ],
        ),
      ),
    );
  }
}
