import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'modellek.dart';

class AdatTarolo {
  static const String _turakKulcs = 'turak_adatok';
  static const String _fogasokKulcs = 'fogasok_adatok';
  static const String _halfajokKulcs = 'halfajok_adatok';
  static const String _helyszinekKulcs = 'helyszinek_adatok';
  static const String _botokKulcs = 'torzs_botok';
  static const String _modszerekKulcs = 'torzs_modszerek';
  static const String _szerelekekKulcs = 'torzs_szerelekek';
  static const String _csalikKulcs = 'torzs_csalik';
  static const String _etetoanyagokKulcs = 'torzs_etetoanyagok';
  static const String _tarsakKulcs = 'torzs_tarsak';
  static const String _idojarasKulcs = 'torzs_idojaras';
  static const String _sorsKulcs = 'torzs_sors';

  static Future<void> _mentes(String kulcs, List<dynamic> adatLista) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> jsonLista = [];
    if (adatLista.isNotEmpty && adatLista.first is! String) {
      jsonLista = adatLista.map((item) => item.toJson()).toList();
    } else {
      jsonLista = adatLista;
    }
    await prefs.setString(kulcs, jsonEncode(jsonLista));
  }

  static Future<List<dynamic>> _betoltes(String kulcs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(kulcs);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return [];
  }

  static Future<void> turakMentes(List<Tura> turak) async => await _mentes(_turakKulcs, turak);
  static Future<List<Tura>> turakBetoltese() async {
    final adatok = await _betoltes(_turakKulcs);
    return adatok.map((e) => Tura.fromJson(e)).toList();
  }

  static Future<void> fogasokMentes(List<FogasModel> fogasok) async => await _mentes(_fogasokKulcs, fogasok);
  static Future<List<FogasModel>> fogasokBetoltese() async {
    final adatok = await _betoltes(_fogasokKulcs);
    return adatok.map((e) => FogasModel.fromJson(e)).toList();
  }

  static Future<void> halfajokMentes(List<Halfaj> halfajok) async => await _mentes(_halfajokKulcs, halfajok);
  static Future<List<Halfaj>> halfajokBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    bool init = prefs.getBool('halfaj_init') ?? false;

    if (!init) {
      List<Halfaj> alapHalfajok = _getMagyarHalFauna();
      await halfajokMentes(alapHalfajok);
      await prefs.setBool('halfaj_init', true);
      return alapHalfajok;
    }

    final adatok = await _betoltes(_halfajokKulcs);
    List<Halfaj> betoltott = adatok.map((e) => Halfaj.fromJson(e)).toList();

    // --- AUTOMATIKUS MIGRÁCIÓ: A meglévő adatbázisban átírja a régi státuszt ---
    bool valtozott = false;
    for (int i = 0; i < betoltott.length; i++) {
      if (betoltott[i].statusz == 'Fogható') {
        betoltott[i] = Halfaj(
          id: betoltott[i].id,
          nev: betoltott[i].nev,
          kategoria: betoltott[i].kategoria,
          statusz: 'Fogható (Őshonos)',
          meretKorlatozas: betoltott[i].meretKorlatozas,
          darabKorlatozas: betoltott[i].darabKorlatozas,
          tilalmiIdoszak: betoltott[i].tilalmiIdoszak,
          szabalyozasEve: betoltott[i].szabalyozasEve,
          megjegyzes: betoltott[i].megjegyzes,
          kepek: betoltott[i].kepek,
        );
        valtozott = true;
      }
    }
    
    if (valtozott) {
      await halfajokMentes(betoltott);
    }

    return betoltott;
  }

  static Future<void> helyszinekMentes(List<Helyszin> helyszinek) async => await _mentes(_helyszinekKulcs, helyszinek);
  static Future<List<Helyszin>> helyszinekBetoltese() async {
    final adatok = await _betoltes(_helyszinekKulcs);
    return adatok.map((e) => Helyszin.fromJson(e)).toList();
  }

  static Future<void> botokMentes(List<String> adatok) async => await _mentes(_botokKulcs, adatok);
  static Future<List<String>> botokBetoltese() async => List<String>.from(await _betoltes(_botokKulcs));

  static Future<void> modszerekMentes(List<String> adatok) async => await _mentes(_modszerekKulcs, adatok);
  static Future<List<String>> modszerekBetoltese() async => List<String>.from(await _betoltes(_modszerekKulcs));

  static Future<void> szerelekekMentes(List<String> adatok) async => await _mentes(_szerelekekKulcs, adatok);
  static Future<List<String>> szerelekekBetoltese() async => List<String>.from(await _betoltes(_szerelekekKulcs));

  static Future<void> csalikMentes(List<String> adatok) async => await _mentes(_csalikKulcs, adatok);
  static Future<List<String>> csalikBetoltese() async => List<String>.from(await _betoltes(_csalikKulcs));

  static Future<void> etetoanyagokMentes(List<String> adatok) async => await _mentes(_etetoanyagokKulcs, adatok);
  static Future<List<String>> etetoanyagokBetoltese() async => List<String>.from(await _betoltes(_etetoanyagokKulcs));

  static Future<void> tarsakMentes(List<String> adatok) async => await _mentes(_tarsakKulcs, adatok);
  static Future<List<String>> tarsakBetoltese() async => List<String>.from(await _betoltes(_tarsakKulcs));

  static Future<void> idojarasMentes(List<String> adatok) async => await _mentes(_idojarasKulcs, adatok);
  static Future<List<String>> idojarasBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    bool init = prefs.getBool('idojaras_init') ?? false;
    
    if (!init) {
      List<String> alapIdojarasok = [
        'Napsütés', 'Közepesen felhős', 'Erősen felhős', 'Borult', 
        'Szemerkélő eső', 'Eső', 'Zápor', 'Erős szél', 'Vihar', 
        'Zivatar', 'Jégeső', 'Havazás', 'Havaseső', 'Köd'
      ];
      await idojarasMentes(alapIdojarasok);
      await prefs.setBool('idojaras_init', true);
      return alapIdojarasok;
    }
    
    return List<String>.from(await _betoltes(_idojarasKulcs));
  }

  static Future<void> sorsMentes(List<String> adatok) async => await _mentes(_sorsKulcs, adatok);
  static Future<List<String>> sorsBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    bool init = prefs.getBool('sors_init') ?? false;
    
    if (!init) {
      List<String> alapSorsok = ['Visszaengedtem', 'Elvittem', 'Elpusztult'];
      await sorsMentes(alapSorsok);
      await prefs.setBool('sors_init', true);
      return alapSorsok;
    }
    
    return List<String>.from(await _betoltes(_sorsKulcs));
  }

  static Future<void> torzsadatNevFrissites(String kategoria, String regiNev, String ujNev) async {
    if (kategoria == 'Horgásztársak') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (int i = 0; i < turak.length; i++) {
        var t = turak[i];
        if (t.horgasztarsak.contains(regiNev)) {
          List<String> ujTarsak = List.from(t.horgasztarsak);
          for (int j = 0; j < ujTarsak.length; j++) {
            if (ujTarsak[j] == regiNev) ujTarsak[j] = ujNev;
          }
          turak[i] = Tura(id: t.id, kezdoDatum: t.kezdoDatum, befejezoDatum: t.befejezoDatum, helyszinId: t.helyszinId, horgaszhely: t.horgaszhely, horgasztarsak: ujTarsak, boritoKep: t.boritoKep, megjegyzes: t.megjegyzes);
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
    }

    final fogasok = await fogasokBetoltese();
    bool fogasChanged = false;
    for (int i = 0; i < fogasok.length; i++) {
      var f = fogasok[i];
      bool changed = false;
      
      String ujHalfaj = f.halfaj; String? ujBot = f.bot; String? ujModszer = f.modszer; String? ujVegszerelek = f.vegszerelek; String? ujIdojaras = f.idojaras; String? ujSors = f.sors;
      List<String> ujCsali = List.from(f.csali); List<String> ujEtetoanyag = List.from(f.etetoanyag);

      if (kategoria == 'Halfaj' && f.halfaj == regiNev) { ujHalfaj = ujNev; changed = true; }
      if (kategoria == 'Horgászbot' && f.bot == regiNev) { ujBot = ujNev; changed = true; }
      if (kategoria == 'Módszer' && f.modszer == regiNev) { ujModszer = ujNev; changed = true; }
      if (kategoria == 'Végszerelék' && f.vegszerelek == regiNev) { ujVegszerelek = ujNev; changed = true; }
      if (kategoria == 'Időjárás' && f.idojaras == regiNev) { ujIdojaras = ujNev; changed = true; }
      if (kategoria == 'Hal sorsa' && f.sors == regiNev) { ujSors = ujNev; changed = true; }
      
      if (kategoria == 'Csali' && ujCsali.contains(regiNev)) {
        for (int j = 0; j < ujCsali.length; j++) { if (ujCsali[j] == regiNev) ujCsali[j] = ujNev; }
        changed = true;
      }
      if (kategoria == 'Etetőanyag' && ujEtetoanyag.contains(regiNev)) {
        for (int j = 0; j < ujEtetoanyag.length; j++) { if (ujEtetoanyag[j] == regiNev) ujEtetoanyag[j] = ujNev; }
        changed = true;
      }

      if (changed) {
        fogasok[i] = FogasModel(id: f.id, turaId: f.turaId, datum: f.datum, idopont: f.idopont, halfaj: ujHalfaj, suly: f.suly, hossz: f.hossz, sors: ujSors, csali: ujCsali, etetoanyag: ujEtetoanyag, etetesGyakorisaga: f.etetesGyakorisaga, bot: ujBot, modszer: ujModszer, vegszerelek: ujVegszerelek, idojaras: ujIdojaras, homerseklet: f.homerseklet, megjegyzes: f.megjegyzes, fenykep: f.fenykep, isKedvenc: f.isKedvenc);
        fogasChanged = true;
      }
    }
    if (fogasChanged) await fogasokMentes(fogasok);
  }

  static Future<void> torzsadatTorles(String kategoria, String toroltNevVagyId) async {
    if (kategoria == 'Helyszín') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (int i = 0; i < turak.length; i++) {
        var t = turak[i];
        if (t.helyszinId == toroltNevVagyId) {
          turak[i] = Tura(id: t.id, kezdoDatum: t.kezdoDatum, befejezoDatum: t.befejezoDatum, helyszinId: null, horgaszhely: t.horgaszhely, horgasztarsak: t.horgasztarsak, boritoKep: t.boritoKep, megjegyzes: t.megjegyzes);
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
      return;
    }

    if (kategoria == 'Horgásztársak') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (int i = 0; i < turak.length; i++) {
        var t = turak[i];
        if (t.horgasztarsak.contains(toroltNevVagyId)) {
          List<String> ujTarsak = List.from(t.horgasztarsak)..remove(toroltNevVagyId);
          turak[i] = Tura(id: t.id, kezdoDatum: t.kezdoDatum, befejezoDatum: t.befejezoDatum, helyszinId: t.helyszinId, horgaszhely: t.horgaszhely, horgasztarsak: ujTarsak, boritoKep: t.boritoKep, megjegyzes: t.megjegyzes);
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
    }

    final fogasok = await fogasokBetoltese();
    bool fogasChanged = false;
    for (int i = 0; i < fogasok.length; i++) {
      var f = fogasok[i];
      bool changed = false;
      
      String ujHalfaj = f.halfaj; String? ujBot = f.bot; String? ujModszer = f.modszer; String? ujVegszerelek = f.vegszerelek; String? ujIdojaras = f.idojaras; String? ujSors = f.sors;
      List<String> ujCsali = List.from(f.csali); List<String> ujEtetoanyag = List.from(f.etetoanyag);

      if (kategoria == 'Halfaj' && f.halfaj == toroltNevVagyId) { ujHalfaj = ''; changed = true; } 
      if (kategoria == 'Horgászbot' && f.bot == toroltNevVagyId) { ujBot = null; changed = true; }
      if (kategoria == 'Módszer' && f.modszer == toroltNevVagyId) { ujModszer = null; changed = true; }
      if (kategoria == 'Végszerelék' && f.vegszerelek == toroltNevVagyId) { ujVegszerelek = null; changed = true; }
      if (kategoria == 'Időjárás' && f.idojaras == toroltNevVagyId) { ujIdojaras = null; changed = true; }
      if (kategoria == 'Hal sorsa' && f.sors == toroltNevVagyId) { ujSors = null; changed = true; }
      
      if (kategoria == 'Csali' && ujCsali.contains(toroltNevVagyId)) { ujCsali.remove(toroltNevVagyId); changed = true; }
      if (kategoria == 'Etetőanyag' && ujEtetoanyag.contains(toroltNevVagyId)) { ujEtetoanyag.remove(toroltNevVagyId); changed = true; }

      if (changed) {
        fogasok[i] = FogasModel(id: f.id, turaId: f.turaId, datum: f.datum, idopont: f.idopont, halfaj: ujHalfaj, suly: f.suly, hossz: f.hossz, sors: ujSors, csali: ujCsali, etetoanyag: ujEtetoanyag, etetesGyakorisaga: f.etetesGyakorisaga, bot: ujBot, modszer: ujModszer, vegszerelek: ujVegszerelek, idojaras: ujIdojaras, homerseklet: f.homerseklet, megjegyzes: f.megjegyzes, fenykep: f.fenykep, isKedvenc: f.isKedvenc);
        fogasChanged = true;
      }
    }
    if (fogasChanged) await fogasokMentes(fogasok);
  }

  static String _ph(String nev) => 'https://placehold.co/600x400/161616/69F0AE?text=${Uri.encodeComponent(nev)}';

  static List<Halfaj> _getMagyarHalFauna() {
    return [
      Halfaj(
        id: 'hal_01', nev: 'Ponty', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '30 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '05.02 - 05.31.', szabalyozasEve: '2024',
        megjegyzes: 'Zömök testű, sárgás-barnás hal, 4 bajuszszála van. A mederfenéken turkálva férgeket, csigákat, rovarlárvákat eszik. Édes (eper, ananász), büdös-halas (krill) vagy fűszeres bojlikkal, pelletekkel, kukoricával fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Cyprinus_carpio_02.jpg/800px-Cyprinus_carpio_02.jpg', _ph('Ponty 2'), _ph('Ponty 3')],
      ),
      Halfaj(
        id: 'hal_02', nev: 'Compó', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '25 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '05.02 - 06.15.', szabalyozasEve: '2024',
        megjegyzes: 'Gyönyörű, zöldes-aranyfényű, apró pikkelyes, nyálkás bőrű hal. Iszapos fenéken keresi csigákból, férgekből álló táplálékát. Édes etetőanyagokkal, gilisztával, csontival és csemegekukoricával fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Tinca_tinca_Prague.jpg/800px-Tinca_tinca_Prague.jpg', _ph('Compó 2'), _ph('Compó 3')],
      ),
      Halfaj(
        id: 'hal_03', nev: 'Márna', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '40 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '04.15 - 05.31.', szabalyozasEve: '2024',
        megjegyzes: 'Izmos, folyóvízi hal, alsó állású húsos szájjal és 4 bajusszal. Férgeket, rákokat, apróhalakat eszik. Sajtos, kolbászos pelletek, és csonti/giliszta csokor a nyerő. Ikrája mérgező!',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barbus_barbus.jpg/800px-Barbus_barbus.jpg', _ph('Márna 2'), _ph('Márna 3')],
      ),
      Halfaj(
        id: 'hal_04', nev: 'Paduc', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '20 cm', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: '04.15 - 05.31.', szabalyozasEve: '2024',
        megjegyzes: 'Nyúlánk ezüstös hal, jellegzetes alsó állású "véső" szájjal. Folyóvizek kavicsairól kaparja az algát. Sajtos etetőanyaggal, kenyérrózsával vagy csontival fogható folyóvízen, úszózva.',
        kepek: [_ph('Paduc 1'), _ph('Paduc 2'), _ph('Paduc 3')],
      ),
      Halfaj(
        id: 'hal_05', nev: 'Dévérkeszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Magas hátú, oldalról lapított, ezüstös hal. Az iszapból túrja ki a szúnyoglárvákat. Édes-fűszeres, fahéjas etetőanyagokkal, gilisztával, pinkivel kiválóan fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Abramis_brama_Prague_Vltava_1.jpg/800px-Abramis_brama_Prague_Vltava_1.jpg', _ph('Dévérkeszeg 2'), _ph('Dévérkeszeg 3')],
      ),
      Halfaj(
        id: 'hal_06', nev: 'Bodorka', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Kisebb ezüstös hal, narancssárga/piros írisszel a szemében. Növényi törmeléket, algát eszik. Édes, pörkölt magvas finom etetőanyaggal, 1-2 szem csontival fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Rutilus_rutilus_Prague_Vltava_2.jpg/800px-Rutilus_rutilus_Prague_Vltava_2.jpg', _ph('Bodorka 2'), _ph('Bodorka 3')],
      ),
      Halfaj(
        id: 'hal_07', nev: 'Vörösszárnyú keszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Felső állású szája és vérvörös úszói vannak. A felszín közelében vadászik rovarokra. Vízfelszíni horgászattal, kenyérrel, csontival könnyen horogra csalható nádasok szélén.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Scardinius_erythrophthalmus_Prague_Vltava_1.jpg/800px-Scardinius_erythrophthalmus_Prague_Vltava_1.jpg', _ph('Vörösszárnyú 2'), _ph('Vörösszárnyú 3')],
      ),
      Halfaj(
        id: 'hal_08', nev: 'Karikakeszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Magas hátú, nagy szemű, világos úszójú hal. Lárvákat eszik. Hagyományos sötétebb keszegező etetőanyagokkal, csontkukaccal jól fogható fenéken vagy vízközt.',
        kepek: [_ph('Karikakeszeg 1'), _ph('Karikakeszeg 2'), _ph('Karikakeszeg 3')],
      ),
      Halfaj(
        id: 'hal_09', nev: 'Jászkeszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '20 cm', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: '04.15 - 05.31.', szabalyozasEve: '2024',
        megjegyzes: 'A bodorkához hasonló, de vaskosabb, apróbb pikkelyű. A felszín közelében eszik rovarokat. Csontival, műléggyel, apró villantóval (ragadozó hajlama van) fogható.',
        kepek: [_ph('Jászkeszeg 1'), _ph('Jászkeszeg 2'), _ph('Jászkeszeg 3')],
      ),
      Halfaj(
        id: 'hal_10', nev: 'Laposkeszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Lapos testű, ferde szájrésű keszegféle. Zooplanktonokat szűröget. Édes keszegező kajákkal, szúnyoglárvával fogható.',
        kepek: [_ph('Laposkeszeg 1'), _ph('Laposkeszeg 2'), _ph('Laposkeszeg 3')],
      ),
      Halfaj(
        id: 'hal_11', nev: 'Szilvaorrú keszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '20 cm', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: '04.15 - 05.31.', szabalyozasEve: '2024',
        megjegyzes: 'Szürkéskék hát, narancssárgás száj, húsos "szilva" orr. Folyóvízi kövekről algát és rovarokat csipeget. Fűszeres ízekkel, csontival, gilisztával fogható.',
        kepek: [_ph('Szilvaorrú 1'), _ph('Szilvaorrú 2'), _ph('Szilvaorrú 3')],
      ),
      Halfaj(
        id: 'hal_12', nev: 'Domolykó', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '25 cm', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: '04.15 - 05.31.', szabalyozasEve: '2024',
        megjegyzes: 'Vastag pikkelyű, nagy szájú, óvatos folyóvízi hal. Mindenevő: gyümölcstől a kishalakig mindent megeszik. Gyümölcsökkel (meggy), sajttal, vagy apró wobblerekkel fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Squalius_cephalus_Prague_Vltava_1.jpg/800px-Squalius_cephalus_Prague_Vltava_1.jpg', _ph('Domolykó 2'), _ph('Domolykó 3')],
      ),
      Halfaj(
        id: 'hal_13', nev: 'Garda', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '20 cm', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: '04.15 - 05.31.', szabalyozasEve: '2024',
        megjegyzes: 'Kardszerűen lapos test, görbült oldalvonal. A vízfelszín közelében rabol. Élő csontival süllyedő úszóval, vagy apró műcsalikkal, műléggyel pergetve fogják.',
        kepek: [_ph('Garda 1'), _ph('Garda 2'), _ph('Garda 3')],
      ),
      Halfaj(
        id: 'hal_14', nev: 'Csuka', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '40 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '02.01 - 03.31.', szabalyozasEve: '2024',
        megjegyzes: 'Nyílvessző alakú, zöldes foltos test, kacsacsőr száj, tűhegyes fogak. Élő kishallal, vagy élénk színű műcsalik pergetésével fogható. A harapásálló előke (drót) kötelező!',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Esox_lucius_Prague_Vltava_1.jpg/800px-Esox_lucius_Prague_Vltava_1.jpg', _ph('Csuka 2'), _ph('Csuka 3')],
      ),
      Halfaj(
        id: 'hal_15', nev: 'Süllő (Fogas)', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '30 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '03.01 - 04.30.', szabalyozasEve: '2024',
        megjegyzes: 'Nyúlánk, ezüstös test, hatalmas ebfogakkal. Éjszaka a felszínen, nappal fenéken vadászik. Taposott kishallal, jigfejes gumihalakkal fogható. 1.5 kg felett "fogas".',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Sander_lucioperca_1.jpg/800px-Sander_lucioperca_1.jpg', _ph('Süllő 2'), _ph('Süllő 3')],
      ),
      Halfaj(
        id: 'hal_16', nev: 'Kősüllő', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '25 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '03.01 - 06.30.', szabalyozasEve: '2024',
        megjegyzes: 'A süllőhöz hasonló, de csíkozata határozottabb, nincsenek ebfogai. (Tilalmi ideje hosszabb!). Vékony gilisztával, apró taposott hallal és kis plasztikokkal fogható.',
        kepek: [_ph('Kősüllő 1'), _ph('Kősüllő 2'), _ph('Kősüllő 3')],
      ),
      Halfaj(
        id: 'hal_17', nev: 'Harcsa (Európai)', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '60 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '05.02 - 06.15.', szabalyozasEve: '2024',
        megjegyzes: 'Vizeink legnagyobb ragadozója. Pikkelytelen bőr, hatalmas fej, hosszú bajszok. Éjszaka vadászik. Kuttyogatva, nagy élő hallal, piócával, vagy erős pergető felszereléssel fogható. (100 cm felett tilalom idején is vihető).',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Silurus_glanis_01.jpg/800px-Silurus_glanis_01.jpg', _ph('Harcsa 2'), _ph('Harcsa 3')],
      ),
      Halfaj(
        id: 'hal_18', nev: 'Balin', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '40 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '03.01 - 04.30.', szabalyozasEve: '2024',
        megjegyzes: 'Ezüstös torpedó, ragadozó életmódú pontyféle (fogak nélkül). A felszínen rabol a küszcsapatokra. Gyorsan húzott ezüstös műcsalikkal vagy élő küsszel fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Aspius_aspius_Prague_Vltava_1.jpg/800px-Aspius_aspius_Prague_Vltava_1.jpg', _ph('Balin 2'), _ph('Balin 3')],
      ),
      Halfaj(
        id: 'hal_19', nev: 'Sügér (Csapósügér)', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '15 cm', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: '03.01 - 04.30.', szabalyozasEve: '2024',
        megjegyzes: 'Pici, zöldes-bronzos ragadozó, tüskés hátúszóval és piros hasúszóval. Bandákban vadászik. Finom pergetéssel vagy gilisztával, csontival rendkívül szórakoztató.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Perca_fluviatilis_Prague_Vltava_1.jpg/800px-Perca_fluviatilis_Prague_Vltava_1.jpg', _ph('Sügér 2'), _ph('Sügér 3')],
      ),
      Halfaj(
        id: 'hal_20', nev: 'Menyhal', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '25 cm', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: '01.01 - 02.28.', szabalyozasEve: '2024',
        megjegyzes: 'Kígyószerű, márványos test, az állán egyetlen bajuszszál lóg. Kizárólag télen, a leghidegebb vizekben aktív. Taposott kishallal, halszelettel horgásznak rá fenekezve.',
        kepek: [_ph('Menyhal 1'), _ph('Menyhal 2'), _ph('Menyhal 3')],
      ),
      Halfaj(
        id: 'hal_21', nev: 'Amur', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Hatalmas, torpedó alakú távol-keleti hal. Szigorúan növényevő. Erjesztett kukoricával, fokhagymás és lucernás pelletekkel fogható. Fárasztáskor a partnál robbanásszerűen védekezik.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Ctenopharyngodon_idella.jpg/800px-Ctenopharyngodon_idella.jpg', _ph('Amur 2'), _ph('Amur 3')],
      ),
      Halfaj(
        id: 'hal_22', nev: 'Afrikai harcsa', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Csupasz bőrű hal, feje tetején csontos lemezzel (levegőt is tud venni). Hőkedvelő. Pellet, büdös máj, csirkebél, pióca – nagyon falánk mindenevő.',
        kepek: [_ph('Afrikai harcsa 1'), _ph('Afrikai harcsa 2'), _ph('Afrikai harcsa 3')],
      ),
      Halfaj(
        id: 'hal_23', nev: 'Tokhal (Vágó és hibridek)', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Ősi, cápaszerű megjelenés, csontvértek, alsó állású száj. Fenékről porszívózza a táplálékot. Halibut pelletekkel fogható intenzíven telepített tavakon.',
        kepek: [_ph('Tokhal 1'), _ph('Tokhal 2'), _ph('Tokhal 3')],
      ),
      Halfaj(
        id: 'hal_24', nev: 'Fekete amur', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Az amurhoz hasonló, de sötétebb, feketés pikkelyzetű. Kizárólag puhatestűeket (csigákat, kagylókat) roppant össze. GLM (zöldkagylós) bojlival fogható.',
        kepek: [_ph('Fekete amur 1'), _ph('Fekete amur 2'), _ph('Fekete amur 3')],
      ),
      Halfaj(
        id: 'hal_25', nev: 'Buffalo', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Amerikai pontyféle, a kárász és a busa keverékére emlékeztet. Fenékközelben zooplanktont eszik. Édes bojlival pontyozás közben akad horogra.',
        kepek: [_ph('Buffalo 1'), _ph('Buffalo 2'), _ph('Buffalo 3')],
      ),
      Halfaj(
        id: 'hal_26', nev: 'Sebes pisztráng', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: '22 cm', darabKorlatozas: '3 db/nap', tilalmiIdoszak: '10.01 - 03.31.', szabalyozasEve: '2024',
        megjegyzes: 'Hegyi patakjaink csodája, testén fekete és piros pettyekkel. Rovarokra, apróhalakra rabol. Szinte csak műléggyel vagy apró körforgóval engedélyezett fogni.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Salmo_trutta_fario_in_Genoa.jpg/800px-Salmo_trutta_fario_in_Genoa.jpg', _ph('Sebes pisztráng 2'), _ph('Sebes pisztráng 3')],
      ),
      Halfaj(
        id: 'hal_27', nev: 'Szivárványos pisztráng', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Amerikából betelepített, testén rózsaszínes csík fut végig. Tavakon pergetve (gumik, kanalak), műléggyel vagy speciális pisztrángpasztával fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Oncorhynchus_mykiss_01.jpg/800px-Oncorhynchus_mykiss_01.jpg', _ph('Szivárványos 2'), _ph('Szivárványos 3')],
      ),
      Halfaj(
        id: 'hal_28', nev: 'Pisztrángsügér (Black Bass)', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Zömök, zöldes-mintás test, hatalmasra nyitható száj. A vízinövények közül rabol. Gumirákokkal, felszíni békákkal, jerkbaitekkel pergetik.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Micropterus_salmoides.jpg/800px-Micropterus_salmoides.jpg', _ph('Pisztrángsügér 2'), _ph('Pisztrángsügér 3')],
      ),
      Halfaj(
        id: 'hal_29', nev: 'Pettyes harcsa', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Amerikai eredetű, a szürkeharcsához hasonlít, de világosabb, barnásan pettyes bőre van. Büdös húsokkal, májjal, pelletel fogható.',
        kepek: [_ph('Pettyes harcsa 1'), _ph('Pettyes harcsa 2'), _ph('Pettyes harcsa 3')],
      ),
      Halfaj(
        id: 'hal_30', nev: 'Csíkos sügér', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Magas hátú, ezüstös amerikai sügérféle, vízszintes fekete csíkokkal. Nyílt vízen bandákban vadászik. Kishallal vagy pergetve fogható.',
        kepek: [_ph('Csíkos sügér 1'), _ph('Csíkos sügér 2'), _ph('Csíkos sügér 3')],
      ),
      Halfaj(
        id: 'hal_31', nev: 'Lapátorrú tok', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Kréta-kori dinoszauruszokra emlékeztető faj, hatalmas evezőlapát orral. Planktonszűrő. Hagyományos csalival szinte lehetetlen megfogni (kívülről akad a horogba).',
        kepek: [_ph('Lapátorrú tok 1'), _ph('Lapátorrú tok 2'), _ph('Lapátorrú tok 3')],
      ),
      Halfaj(
        id: 'hal_32', nev: 'Aranyhal', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Az ezüstkárász színmutációja (narancssárga színű). Általában kerti tavakból szabadulnak ki. Táplálkozása és horgászata megegyezik a kárászéval (csonti, giliszta).',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Goldfish_in_aquarium.jpg/800px-Goldfish_in_aquarium.jpg', _ph('Aranyhal 2'), _ph('Aranyhal 3')],
      ),
      Halfaj(
        id: 'hal_33', nev: 'Angolna', kategoria: 'Ragadozó', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Kígyószerű testalkatú, nyálkás, éjszakai ragadozó hal. Fenéken rovarokat, dögöt, kishalat eszik. Földigiliszta, halszelet a legnyerőbb.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Anguilla_anguilla.jpg/800px-Anguilla_anguilla.jpg', _ph('Angolna 2'), _ph('Angolna 3')],
      ),
      Halfaj(
        id: 'hal_34', nev: 'Törpeharcsa', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Apró, 8 bajuszszálas ikrapusztító. Mellúszóján és hátúszóján veszélyes bognártüske van. Visszaengedni tilos! Földigilisztára, csontira perceken belül rárabol.',
        kepek: [_ph('Törpeharcsa 1'), _ph('Törpeharcsa 2'), _ph('Törpeharcsa 3')],
      ),
      Halfaj(
        id: 'hal_35', nev: 'Ezüstkárász', kategoria: 'Békés', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Zömök, ezüstös hal, bajsza nincs. Őshonos fajainkat kiszorítja. Visszaengedése tilos! Szinte bármilyen csalival (fokhagyma, eper, csonti, kenyér) fogható.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Carassius_gibelio_2008_G1.jpg/800px-Carassius_gibelio_2008_G1.jpg', _ph('Ezüstkárász 2'), _ph('Ezüstkárász 3')],
      ),
      Halfaj(
        id: 'hal_36', nev: 'Busa (Fehér és Pettyes)', kategoria: 'Békés', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Hatalmasra növő, széles fejű hal. A vízben lebegő fitoplanktont szűri. Visszaengedni tilos! Kifejezetten technoplanktonnal, lebegtetett pufival horgásznak rá.',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Hypophthalmichthys_nobilis.jpg/800px-Hypophthalmichthys_nobilis.jpg', _ph('Busa 2'), _ph('Busa 3')],
      ),
      Halfaj(
        id: 'hal_37', nev: 'Kecsege', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Pikkelytelen dunai tokféle, hátán csontos vértekkel, felkunkorodó orral. Horgászata és megtartása szigorúan tilos (kivéve éves, személyre szóló eseti engedéllyel).',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/Acipenser_ruthenus.jpg/800px-Acipenser_ruthenus.jpg', _ph('Kecsege 2'), _ph('Kecsege 3')],
      ),
      Halfaj(
        id: 'hal_38', nev: 'Széles kárász (Aranykárász)', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Az egyetlen őshonos kárászfajunk. Magas hátú, arany-barnás színű, úszói lekerekítettek. Fogása esetén azonnal kíméletesen vissza kell engedni!',
        kepek: ['https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Carassius_carassius_Prague_Vltava_1.jpg/800px-Carassius_carassius_Prague_Vltava_1.jpg', _ph('Széles kárász 2'), _ph('Széles kárász 3')],
      ),
      Halfaj(
        id: 'hal_39', nev: 'Leánykoncér', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A márnára és a paducra emlékeztető testalkatú folyóvízi hal (bajsza nincs). Szigorúan védett, fogása esetén azonnal vissza kell helyezni a vízbe!',
        kepek: [_ph('Leánykoncér 1'), _ph('Leánykoncér 2'), _ph('Leánykoncér 3')],
      ),
      Halfaj(
        id: 'hal_40', nev: 'Koi ponty', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'A ponty tógazdasági, vagy kerti-tavi színmutációja (általában fehér-piros-fekete foltos). Táplálkozása és horgászata teljesen megegyezik a pontyéval (bojli, pelletek, kukorica).',
        kepek: [_ph('Koi ponty 1'), _ph('Koi ponty 2'), _ph('Koi ponty 3')],
      ),
    ];
  }
}
