import 'package:flutter/material.dart';
import 'adattarolo.dart'; 
import 'turak.dart';
import 'kedvencek.dart';
import 'felszereles.dart'; 
import 'lexikon.dart';
import 'statisztika.dart';
import 'adatkezeles.dart';
import 'torzsadatok.dart';
import 'dokumentumok.dart'; 
import 'jegyzetek.dart'; 
import 'listak.dart';    

void main() {
  runApp(const HorgaszNaploApp());
}

class HorgaszNaploApp extends StatelessWidget {
  const HorgaszNaploApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horgásznapló',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primarySwatch: Colors.green,
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.green,
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigalas();
  }

  Future<void> _navigalas() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FomenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/2825.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class FomenuScreen extends StatefulWidget {
  const FomenuScreen({super.key});

  @override
  State<FomenuScreen> createState() => _FomenuScreenState();
}

class _FomenuScreenState extends State<FomenuScreen> {
  int _currentIndex = 0;
  final GlobalKey<FelszerelesScreenState> _felszerelesKey = GlobalKey<FelszerelesScreenState>();
  final GlobalKey<StatisztikaScreenState> _statisztikaKey = GlobalKey<StatisztikaScreenState>();
  
  late List<Widget> _kepernyok; 

  @override
  void initState() {
    super.initState();
    _kepernyok = [
      const TurakScreen(),
      const KedvencekScreen(),
      FelszerelesScreen(key: _felszerelesKey),
      const LexikonScreen(),
      StatisztikaScreen(key: _statisztikaKey), 
    ];
  }

  void _kepernyokFrissitese() {
    setState(() {
      _kepernyok = [
        TurakScreen(key: UniqueKey()),
        KedvencekScreen(key: UniqueKey()),
        FelszerelesScreen(key: _felszerelesKey),
        LexikonScreen(key: UniqueKey()),
        StatisztikaScreen(key: _statisztikaKey), 
      ];
    });
    _felszerelesKey.currentState?.adatokBetoltese();
    _statisztikaKey.currentState?.adatokBetoltese(); 
  }

  final List<String> _cimek = [
    'Horgásztúráim',
    'Kedvenc fogások',
    'Felszerelés', 
    'Halfajok / Lexikon',
    'Statisztika',
  ];

  void _mutassHalStatuszInfot() {
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

  List<Widget> _buildAppBarActions() {
    if (_currentIndex == 2) {
      bool isTaskaNezet = _felszerelesKey.currentState?.isTaskaNezet ?? false;
      Color aktivSzin = isTaskaNezet ? Colors.orangeAccent : Colors.greenAccent;

      return [
        IconButton(
          icon: Icon(Icons.search, color: aktivSzin),
          tooltip: 'Keresés',
          onPressed: () {
            _felszerelesKey.currentState?.toggleKereso();
            setState(() {}); 
          },
        ),
        IconButton(
          icon: Icon(Icons.compare_arrows, color: aktivSzin),
          tooltip: 'Nézet váltása',
          onPressed: () {
            _felszerelesKey.currentState?.toggleNezet();
            setState(() {}); 
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: aktivSzin),
          color: const Color(0xFF1E1E1E),
          onSelected: (value) async {
            if (value == 'kategoriak') {
              final kategoriak = await AdatTarolo.felszerelesKategoriakBetoltese();
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KategoriakSzerkesztoScreen(
                    kategoriak: kategoriak,
                    mentesCallback: () {
                      setState(() {});
                      _felszerelesKey.currentState?.adatokBetoltese();
                    },
                  ),
                ),
              );
            } else if (value == 'taskak') {
              final taskak = await AdatTarolo.taskakBetoltese();
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskakSzerkesztoScreen(
                    taskak: taskak,
                    mentesCallback: () {
                      setState(() {});
                      _felszerelesKey.currentState?.adatokBetoltese();
                    },
                  ),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'kategoriak',
              child: Text('Kategóriák szerkesztése'),
            ),
            const PopupMenuItem(
              value: 'taskak',
              child: Text('Táskák szerkesztése'),
            ),
          ],
        )
      ];
    } else if (_currentIndex == 3) {
      return [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.greenAccent),
          onPressed: _mutassHalStatuszInfot,
        ),
      ];
    } else if (_currentIndex == 4) { 
      return [
        IconButton(
          icon: const Icon(Icons.brightness_2, color: Colors.greenAccent),
          tooltip: 'Holdnaptár & Elemzés',
          onPressed: () {
            _statisztikaKey.currentState?.mutassHoldnaptar();
          },
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        title: Text(_cimek[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: _buildAppBarActions(),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF161616),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // A fejléc egy kicsivel nagyobb belső margót kapott (vertical: 24) a jobb arányokért
                  Container(
                    width: double.infinity,
                    color: Colors.green[900]?.withOpacity(0.5),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Horgásznapló', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Verzió 1.6.0', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // TELJESEN KIVETTEM A SŰRÍTÉST! Itt már az eredeti, szellős és kényelmes Flutter alapméret van!
                  Column(
                    children: [
                      // FŐ FUNKCIÓK
                      ListTile(
                        leading: const Icon(Icons.map_outlined, color: Colors.greenAccent),
                        title: const Text('1. Horgásztúráim', style: TextStyle(fontSize: 16)),
                        onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.greenAccent),
                        title: const Text('2. Kedvenc fogások', style: TextStyle(fontSize: 16)),
                        onTap: () { setState(() => _currentIndex = 1); Navigator.pop(context); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.backpack_outlined, color: Colors.greenAccent),
                        title: const Text('3. Felszerelés', style: TextStyle(fontSize: 16)),
                        onTap: () { setState(() => _currentIndex = 2); Navigator.pop(context); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.library_books_outlined, color: Colors.greenAccent),
                        title: const Text('4. Halfajok', style: TextStyle(fontSize: 16)),
                        onTap: () { setState(() => _currentIndex = 3); Navigator.pop(context); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.bar_chart, color: Colors.greenAccent),
                        title: const Text('5. Statisztika', style: TextStyle(fontSize: 16)),
                        onTap: () { setState(() => _currentIndex = 4); Navigator.pop(context); },
                      ),
                      
                      const Divider(color: Colors.white24, height: 16),
                      
                      // SZEMÉLYES ASSZISZTENS
                      ListTile(
                        leading: const Icon(Icons.notes, color: Colors.greenAccent),
                        title: const Text('6. Jegyzetek', style: TextStyle(fontSize: 16)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const JegyzetekScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.checklist, color: Colors.greenAccent),
                        title: const Text('7. Listák', style: TextStyle(fontSize: 16)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ListakScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.folder_shared_outlined, color: Colors.greenAccent),
                        title: const Text('8. Dokumentumok', style: TextStyle(fontSize: 16)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const DokumentumokScreen()));
                        },
                      ),
                      
                        const Divider(color: Colors.white24, height: 16),
                      
                      // RENDSZER
                      ListTile(
                        leading: const Icon(Icons.category, color: Colors.greenAccent),
                        title: const Text('9. Törzsadatok', style: TextStyle(fontSize: 16)),
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const TorzsadatokScreen()));
                          _kepernyokFrissitese();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings, color: Colors.greenAccent),
                        title: const Text('10. Adatkezelés', style: TextStyle(fontSize: 16)),
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AdatkezelesScreen()));
                          _kepernyokFrissitese();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // A logó biztosan a legszélén landol
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0, right: 24.0, top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text('© ', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('by B2', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: _kepernyok[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 4 ? 0 : _currentIndex, 
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF161616),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Túrák'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Kedvencek'),
          BottomNavigationBarItem(icon: Icon(Icons.backpack_outlined), label: 'Felszerelés'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Halfajok'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statisztika'), 
        ],
      ),
    );
  }
}
