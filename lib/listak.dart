import 'package:flutter/material.dart';
import 'adattarolo.dart';
import 'modellek.dart';

class ListakScreen extends StatefulWidget {
  const ListakScreen({super.key});

  @override
  State<ListakScreen> createState() => _ListakScreenState();
}

class _ListakScreenState extends State<ListakScreen> {
  List<Checklista> _listak = [];
  bool _isKeresoMod = false;
  String _keresoKifejezes = '';
  final TextEditingController _keresoCtrl = TextEditingController();
  
  bool _betoltesFolyamatban = true; 

  @override
  void initState() {
    super.initState();
    _adatokBetoltese();
  }

  Future<void> _adatokBetoltese() async {
    final adatok = await AdatTarolo.listakBetoltese();
    setState(() {
      _listak = adatok;
      _betoltesFolyamatban = false; 
    });
  }

  Future<void> _sorrendMentes() async {
    for (int i = 0; i < _listak.length; i++) {
      _listak[i].sorrend = i;
    }
    await AdatTarolo.listakMentes(_listak);
  }

  void _listaNyitasa([Checklista? lista]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaReszletekScreen(
          lista: lista,
          mentesCallback: (modositottLista) async {
            setState(() {
              if (lista != null) {
                final idx = _listak.indexWhere((l) => l.id == modositottLista.id);
                if (idx != -1) _listak[idx] = modositottLista;
              } else {
                modositottLista.sorrend = _listak.length;
                _listak.add(modositottLista);
              }
            });
            await _sorrendMentes();
          },
          torlesCallback: (torlendoId) async {
            setState(() {
              _listak.removeWhere((l) => l.id == torlendoId);
            });
            await _sorrendMentes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Checklista> mutatottListak = _listak;

    if (_keresoKifejezes.trim().isNotEmpty) {
      final keresoSzoveg = _keresoKifejezes.toLowerCase();
      mutatottListak = _listak.where((l) {
        if (l.cim.toLowerCase().contains(keresoSzoveg)) return true;
        if (l.tetelek.any((t) => t.szoveg.toLowerCase().contains(keresoSzoveg))) return true;
        return false;
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
                  hintText: 'Keresés listákban...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _keresoKifejezes = val),
              )
            : const Text('Listák'),
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
      body: _betoltesFolyamatban
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : _listak.isEmpty
              ? const Center(
                  child: Text(
                    'Még nincsenek listáid.\nKattints a + gombra egy újhoz!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : mutatottListak.isEmpty
                  ? const Center(child: Text('Nincs találat a keresésre.', style: TextStyle(color: Colors.white54)))
                  : ReorderableListView(
                      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100),
                      buildDefaultDragHandles: _keresoKifejezes.isEmpty, 
                      onReorder: (oldIndex, newIndex) {
                        if (_keresoKifejezes.isNotEmpty) return;
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _listak.removeAt(oldIndex);
                          _listak.insert(newIndex, item);
                        });
                        _sorrendMentes();
                      },
                      children: mutatottListak.map((lista) {
                        final osszes = lista.tetelek.length;
                        final hianyzik = lista.tetelek.where((t) => !t.isKipipava).length;

                        return Card(
                          key: ValueKey(lista.id),
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _listaNyitasa(lista),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lista.cim.isNotEmpty ? lista.cim : 'Névtelen lista',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), 
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        hianyzik == 0 && osszes > 0 ? Icons.check_circle : Icons.list_alt,
                                        color: hianyzik == 0 && osszes > 0 ? Colors.green : Colors.white54,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$hianyzik tétel (Összesen $osszes)',
                                        style: TextStyle(
                                          color: hianyzik == 0 && osszes > 0 ? Colors.green : Colors.white70,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: osszes > 0 ? (osszes - hianyzik) / osszes : 0.0,
                                      backgroundColor: Colors.black26,
                                      color: hianyzik == 0 && osszes > 0 ? Colors.green : Colors.greenAccent,
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        onPressed: () => _listaNyitasa(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ListaReszletekScreen extends StatefulWidget {
  final Checklista? lista;
  final Function(Checklista) mentesCallback;
  final Function(String) torlesCallback;

  const ListaReszletekScreen({
    super.key,
    this.lista,
    required this.mentesCallback,
    required this.torlesCallback,
  });

  @override
  State<ListaReszletekScreen> createState() => _ListaReszletekScreenState();
}

class _ListaReszletekScreenState extends State<ListaReszletekScreen> {
  late Checklista _aktLista;
  final TextEditingController _cimCtrl = TextEditingController();
  String? _ujTetelId; 

  @override
  void initState() {
    super.initState();
    if (widget.lista != null) {
      _aktLista = Checklista(
        id: widget.lista!.id,
        cim: widget.lista!.cim,
        letrehozva: widget.lista!.letrehozva,
        sorrend: widget.lista!.sorrend,
        tetelek: widget.lista!.tetelek.map((t) => ListaTetel(
          id: t.id,
          szoveg: t.szoveg,
          isKipipava: t.isKipipava,
        )).toList(),
      );
      _cimCtrl.text = _aktLista.cim;
    } else {
      final elsoTetelId = DateTime.now().millisecondsSinceEpoch.toString();
      _ujTetelId = elsoTetelId;
      _aktLista = Checklista(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        letrehozva: DateTime.now(),
        tetelek: [ListaTetel(id: elsoTetelId, szoveg: '')],
      );
    }
  }

  @override
  void dispose() {
    _cimCtrl.dispose();
    super.dispose();
  }

  void _automatikusMentes() {
    _aktLista.cim = _cimCtrl.text.trim();
    widget.mentesCallback(_aktLista);
  }

  void _ujTetelHozzaadasa() {
    final ujId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _ujTetelId = ujId; 
      _aktLista.tetelek.add(ListaTetel(id: ujId, szoveg: ''));
    });
    _automatikusMentes();
  }

  void _tetelTorlese(String id) {
    setState(() {
      _aktLista.tetelek.removeWhere((t) => t.id == id);
    });
    _automatikusMentes();
  }

  void _menupontKivalasztva(String ertek) {
    if (ertek == 'torol_kipipalt') {
      setState(() {
        _aktLista.tetelek.removeWhere((t) => t.isKipipava);
      });
      _automatikusMentes();
    } else if (ertek == 'visszavon_osszes') {
      setState(() {
        for (var t in _aktLista.tetelek) {
          t.isKipipava = false;
        }
      });
      _automatikusMentes();
    } else if (ertek == 'lista_torles') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Lista törlése', style: TextStyle(color: Colors.redAccent)),
          content: const Text('Biztosan törölni szeretnéd a teljes listát? Ez nem vonható vissza!'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégsem')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () {
                widget.torlesCallback(_aktLista.id);
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text('Törlés', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ListaTetel> aktivTetelek = _aktLista.tetelek.where((t) => !t.isKipipava).toList();
    List<ListaTetel> kipipaltTetelek = _aktLista.tetelek.where((t) => t.isKipipava).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szerkesztés'),
        backgroundColor: const Color(0xFF161616),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.greenAccent),
            color: const Color(0xFF1E1E1E),
            onSelected: _menupontKivalasztva,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'torol_kipipalt', child: Text('Kijelöltek törlése')),
              const PopupMenuItem(value: 'visszavon_osszes', child: Text('Kijelölések visszavonása')),
              const PopupMenuItem(value: 'lista_torles', child: Text('Lista törlése', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _cimCtrl,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), // Fehérre módosítva a Jegyzetek stílusához
              decoration: const InputDecoration(
                hintText: 'Lista címe',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onChanged: (val) => _automatikusMentes(),
            ),
            const Divider(color: Colors.white24, height: 20),
            
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final mozgatottId = aktivTetelek[oldIndex].id;
                  final celId = aktivTetelek[newIndex].id;
                  
                  final mozgatottTetel = _aktLista.tetelek.firstWhere((t) => t.id == mozgatottId);
                  _aktLista.tetelek.removeWhere((t) => t.id == mozgatottId);
                  
                  final ujValodiIndex = _aktLista.tetelek.indexWhere((t) => t.id == celId);
                  if (ujValodiIndex != -1) {
                     _aktLista.tetelek.insert(oldIndex < newIndex ? ujValodiIndex + 1 : ujValodiIndex, mozgatottTetel);
                  } else {
                     _aktLista.tetelek.insert(0, mozgatottTetel);
                  }
                });
                _automatikusMentes();
              },
              children: aktivTetelek.map((tetel) {
                return _TetelSor(
                  key: ValueKey(tetel.id),
                  tetel: tetel,
                  isKipipaltNezet: false,
                  autoFocus: tetel.id == _ujTetelId, 
                  onChanged: _automatikusMentes,
                  onTorles: () => _tetelTorlese(tetel.id),
                  onToggle: (bool val) {
                    setState(() {
                      tetel.isKipipava = val;
                    });
                    _automatikusMentes();
                  },
                );
              }).toList(),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0, left: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _ujTetelHozzaadasa,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.greenAccent),
                      SizedBox(width: 16),
                      Text('Új tétel', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            if (kipipaltTetelek.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('${kipipaltTetelek.length} kipipált tétel', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
              Column(
                children: kipipaltTetelek.map((tetel) => _TetelSor(
                  key: ValueKey(tetel.id),
                  tetel: tetel,
                  isKipipaltNezet: true,
                  autoFocus: false,
                  onChanged: _automatikusMentes,
                  onTorles: () => _tetelTorlese(tetel.id),
                  onToggle: (bool val) {
                    setState(() {
                      tetel.isKipipava = val;
                    });
                    _automatikusMentes();
                  },
                )).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _TetelSor extends StatefulWidget {
  final ListaTetel tetel;
  final bool isKipipaltNezet;
  final bool autoFocus; 
  final VoidCallback onChanged;
  final VoidCallback onTorles;
  final Function(bool) onToggle;

  const _TetelSor({
    super.key,
    required this.tetel,
    required this.isKipipaltNezet,
    required this.autoFocus,
    required this.onChanged,
    required this.onTorles,
    required this.onToggle,
  });

  @override
  State<_TetelSor> createState() => _TetelSorState();
}

class _TetelSorState extends State<_TetelSor> {
  late TextEditingController _szovegCtrl;
  bool _isTorlesElesitve = false;

  @override
  void initState() {
    super.initState();
    _szovegCtrl = TextEditingController(text: widget.tetel.szoveg);
  }

  @override
  void didUpdateWidget(covariant _TetelSor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tetel.szoveg != widget.tetel.szoveg && _szovegCtrl.text != widget.tetel.szoveg) {
      _szovegCtrl.text = widget.tetel.szoveg;
    }
  }

  @override
  void dispose() {
    _szovegCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!widget.isKipipaltNezet)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.drag_indicator, color: Colors.white24, size: 20),
            )
          else 
            const SizedBox(width: 28),

          Checkbox(
            value: widget.tetel.isKipipava,
            activeColor: Colors.green[700],
            checkColor: Colors.white,
            side: const BorderSide(color: Colors.white54, width: 2),
            onChanged: (val) {
              if (val != null) widget.onToggle(val);
            },
          ),
          
          Expanded(
            child: TextField(
              controller: _szovegCtrl,
              autofocus: widget.autoFocus, 
              style: TextStyle(
                color: widget.isKipipaltNezet ? Colors.white38 : Colors.white,
                decoration: widget.isKipipaltNezet ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white38,
              ),
              decoration: const InputDecoration(
                hintText: 'Tétel megadása...',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) {
                widget.tetel.szoveg = val;
                widget.onChanged();
              },
            ),
          ),

          TapRegion(
            onTapOutside: (event) {
              if (_isTorlesElesitve) {
                setState(() => _isTorlesElesitve = false);
              }
            },
            child: IconButton(
              icon: Icon(
                Icons.close, 
                size: _isTorlesElesitve ? 28 : 20, 
                color: _isTorlesElesitve ? Colors.redAccent : Colors.white24
              ),
              onPressed: () {
                if (_isTorlesElesitve) {
                  widget.onTorles();
                } else {
                  setState(() => _isTorlesElesitve = true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
