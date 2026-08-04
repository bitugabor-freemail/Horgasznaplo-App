import 'package:flutter/material.dart';

// ------------------- BŐVÍTETT HALHATÁROZÓ -------------------
class HalhatarozoView extends StatelessWidget {
  const HalhatarozoView({super.key});

  final List<Map<String, String>> _halak = const [
    {
      'nev': 'Ponty',
      'leiras': 'Legelterjedtebb békés halunk. Hátúszója hosszú, száján 4 bajuszszál található.',
      'korlat': 'Min. méret: 30 cm | Tilosalom: 05.02 - 05.31.'
    },
    {
      'nev': 'Amur',
      'leiras': 'Ázsiából származó, növényevő, rendkívül erőteljes torpedó alakú hal.',
      'korlat': 'Min. méret: 40 cm | Nincs országos tilalmi idő'
    },
    {
      'nev': 'Ezüstkárász / Aranykárász',
      'leiras': 'Magas testű békés halak. Az ezüstkárász inváziós faj, visszaengedni tilos egyes vizeken.',
      'korlat': 'Nincs méretkorlátozás és tilalmi idő'
    },
    {
      'nev': 'Dévérkeszeg',
      'leiras': 'Oldalról erősen lapított, magas testű keszegféle, sötét szürke úszókkal.',
      'korlat': 'Min. méret: 20 cm'
    },
    {
      'nev': 'Karikakeszeg / Jászkeszeg',
      'leiras': 'Kisebb termetű keszegfélék, folyó- és állóvizeinkben egyaránt gyakoriak.',
      'korlat': 'Jászkeszeg: Min. méret 20 cm | Tilosalom: 04.15 - 05.31.'
    },
    {
      'nev': 'Bodorka / Vörösszárnyú keszeg',
      'leiras': 'A bodorka szeme narancssárga, a vörösszárnyú keszeg úszói élénkpirosak.',
      'korlat': 'Nincs országos méretkorlátozás'
    },
    {
      'nev': 'Compó',
      'leiras': 'Doktorhal néven is ismert. Apró pikkelyes, zöldes-aranyos színű, lekerekített úszójú hal.',
      'korlat': 'Min. méret: 25 cm | Tilosalom: 05.02 - 06.15.'
    },
    {
      'nev': 'Márna',
      'leiras': 'Folyóvizek erős, áramvonalas hala. Alsó állású száján 4 bajuszszál van.',
      'korlat': 'Min. méret: 40 cm | Tilosalom: 04.15 - 05.31.'
    },
    {
      'nev': 'Süllő',
      'leiras': 'Népszerű ragadozó hal. Hátúszója osztott, szájában ebefogak találhatók.',
      'korlat': 'Min. méret: 30 cm | Tilosalom: 03.01 - 04.30.'
    },
    {
      'nev': 'Kősüllő',
      'leiras': 'A süllőnél kisebb, sötétebb harántcsíkos ragadozó. Ebefogai hiányoznak.',
      'korlat': 'Min. méret: 25 cm | Tilosalom: 03.01 - 06.30.'
    },
    {
      'nev': 'Csuka',
      'leiras': 'Kiváló látású, agresszív ragadozó. Hosszúkás test, kacsa-csőrre emlékeztető fej.',
      'korlat': 'Min. méret: 40 cm | Tilosalom: 02.01 - 03.31.'
    },
    {
      'nev': 'Harcsa',
      'leiras': 'Legnagyobb édesvízi ragadozónk. Hosszú pofaszakáll, apró szemek.',
      'korlat': 'Min. méret: 60 cm | Tilosalom: 05.02 - 06.15.'
    },
    {
      'nev': 'Balin',
      'leiras': 'Gyors úszású ragadozó keszegféle. Fogatlan száj, kemény ragadozó kapás.',
      'korlat': 'Min. méret: 40 cm | Tilosalom: 03.01 - 04.30.'
    },
    {
      'nev': 'Sügér',
      'leiras': 'Kisebb termetű, tüskés hátúszójú ragadozó hal, fekete csíkokkal az oldalán.',
      'korlat': 'Nincs méretkorlátozás | Tilosalom: 03.01 - 04.30.'
    },
    {
      'nev': 'Fekete sügér',
      'leiras': 'Észak-Amerikából származó, nagy szájú, rendkívül sportszerű ragadozó hal.',
      'korlat': 'Min. méret: 30 cm'
    },
    {
      'nev': 'Menyhal',
      'leiras': 'Egyetlen édesvízi tőkehalféle. Télen aktív, állán 1 bajuszszál van.',
      'korlat': 'Min. méret: 25 cm'
    },
    {
      'nev': 'Törpeharcsa (Fekete & Barna)',
      'leiras': 'Inváziós faj! Tüskés úszói miatt óvatosan kezelendő. Visszaengedni TILOS!',
      'korlat': 'Nincs méretkorlátozás / Nem védett'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _halak.length,
      itemBuilder: (context, index) {
        final hal = _halak[index];
        final bool isInvasive = hal['nev']!.contains('Törpeharcsa') || hal['nev']!.contains('Ezüstkárász');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isInvasive ? Colors.red[100] : Colors.blue[100],
              child: Icon(Icons.water, color: isInvasive ? Colors.red : Colors.blue[800]),
            ),
            title: Text(hal['nev']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(hal['leiras']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Text(
                        hal['korlat']!,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------- SZABÁLYZAT -------------------
class SzabalyzatView extends StatelessWidget {
  const SzabalyzatView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          '📜 Országos Horgászrend Alapszabályai',
          '• A horgászat megkezdése előtt kötelező bejegyezni a dátumot és a vízterület kódját a fogási naplóba.\n'
              '• Nemeshal fogása esetén a halat a horogszabadítás után AZONNAL be kell jegyezni a naplóba (faj, súly).\n'
              '• A méret- és darabszámkorlátozásokat, valamint a tilalmi időket szigorúan be kell tartani.',
          Icons.gavel,
          Colors.orange[800]!,
        ),
        _buildInfoCard(
          '🐟 Kíméletes Hal-kezelési Útmutató',
          '• Nedvesített kézzel érj a halhoz, hogy védd a pikkelyeit borító védőréteget.\n'
              '• Pontymatrac vagy bölcső használata kiemelten ajánlott (sok vízen kötelező!).\n'
              '• Mélyre nyelt horog esetén ne rángasd a zsinórt! Vágd el a strófot a szájnyílásnál.\n'
              '• A halat kíméletesen, vízbe helyezve tartsd, amíg magához nem tér.',
          Icons.health_and_safety,
          Colors.green[800]!,
        ),
        _buildInfoCard(
          '⚠️ Inváziós Fajok Szabályozása',
          '• A törpeharcsát és egyéb invazív fajokat (pl. ezüstkárász, naphal) tilos visszaengedni a vízbe az ökológiai egyensúly védelmében.',
          Icons.warning_amber,
          Colors.red[800]!,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

