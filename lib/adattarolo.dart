import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
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
  static const String _felszerelesKategoriakKulcs = 'felszereles_kategoriak';
  static const String _felszerelesTetelekKulcs = 'felszereles_tetelek';
  
  // DOKUMENTUMOK KULCSAI
  static const String _dokMappakKulcs = 'dok_mappak';
  static const String _dokFajlokKulcs = 'dok_fajlok';

  // --- BIZTONSÁGOS KÉPKEZELÉS ---
  static Future<String> biztonsagosKepMasolas(String eredetiUtvonal, {String? egyediNev}) async {
    if (eredetiUtvonal.startsWith('http')) return eredetiUtvonal; 
    
    final eredetiFajl = File(eredetiUtvonal);
    if (!await eredetiFajl.exists()) return eredetiUtvonal;

    final appDir = await getApplicationDocumentsDirectory();
    final kepekMappa = Directory('${appDir.path}/kepek');
    if (!await kepekMappa.exists()) {
      await kepekMappa.create(recursive: true);
    }

    final fajlNev = egyediNev ?? '${DateTime.now().millisecondsSinceEpoch}_${eredetiUtvonal.split('/').last}';
    final ujUtvonal = '${kepekMappa.path}/$fajlNev';

    if (eredetiUtvonal != ujUtvonal) {
      await eredetiFajl.copy(ujUtvonal);
    }
    
    return ujUtvonal;
  }

  // --- BIZTONSÁGOS PDF KEZELÉS ---
  static Future<String> biztonsagosDokumentumMasolas(String eredetiUtvonal) async {
    final eredetiFajl = File(eredetiUtvonal);
    if (!await eredetiFajl.exists()) return eredetiUtvonal;

    final appDir = await getApplicationDocumentsDirectory();
    final dokMappa = Directory('${appDir.path}/dokumentumok');
    if (!await dokMappa.exists()) {
      await dokMappa.create(recursive: true);
    }

    final fajlNev = '${DateTime.now().millisecondsSinceEpoch}_${eredetiUtvonal.split('/').last}';
    final ujUtvonal = '${dokMappa.path}/$fajlNev';

    if (eredetiUtvonal != ujUtvonal) {
      await eredetiFajl.copy(ujUtvonal);
    }
    return ujUtvonal;
  }

  // --- ALAPVETŐ MENTÉS ÉS BETÖLTÉS LOKÁLISAN ---
  static Future<void> _mentes(String kulcs, List<dynamic> adatLista) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> jsonLista = [];
    if (adatLista.isNotEmpty && (adatLista.first is! String && adatLista.first is! num && adatLista.first is! bool)) {
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

  // --- TÚRÁK ÉS FOGÁSOK ---
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

  // --- HELYSZÍNEK ---
  static Future<void> helyszinekMentes(List<Helyszin> helyszinek) async => await _mentes(_helyszinekKulcs, helyszinek);
  static Future<List<Helyszin>> helyszinekBetoltese() async {
    final adatok = await _betoltes(_helyszinekKulcs);
    return adatok.map((e) => Helyszin.fromJson(e)).toList();
  }

  // --- DOKUMENTUMOK MENTÉSE ÉS BETÖLTÉSE ---
  static Future<void> dokMappakMentes(List<DokumentumMappa> mappak) async => await _mentes(_dokMappakKulcs, mappak);
  static Future<List<DokumentumMappa>> dokMappakBetoltese() async {
    final adatok = await _betoltes(_dokMappakKulcs);
    return adatok.map((e) => DokumentumMappa.fromJson(e)).toList();
  }

  static Future<void> dokFajlokMentes(List<DokumentumFajl> fajlok) async => await _mentes(_dokFajlokKulcs, fajlok);
  static Future<List<DokumentumFajl>> dokFajlokBetoltese() async {
    final adatok = await _betoltes(_dokFajlokKulcs);
    return adatok.map((e) => DokumentumFajl.fromJson(e)).toList();
  }

  static Future<void> dokumentumTorles(DokumentumFajl fajl) async {
    try {
      final f = File(fajl.utvonal);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    final fajlok = await dokFajlokBetoltese();
    fajlok.removeWhere((x) => x.id == fajl.id);
    await dokFajlokMentes(fajlok);
  }

  static Future<void> mappaTorles(DokumentumMappa mappa) async {
    final fajlok = await dokFajlokBetoltese();
    final mappaFajljai = fajlok.where((f) => f.mappaId == mappa.id).toList();
    
    for(var f in mappaFajljai) {
      try {
        final file = File(f.utvonal);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    
    fajlok.removeWhere((f) => f.mappaId == mappa.id);
    await dokFajlokMentes(fajlok);
    
    final mappak = await dokMappakBetoltese();
    mappak.removeWhere((m) => m.id == mappa.id);
    await dokMappakMentes(mappak);
  }

  // --- FELSZERELÉSEK ---
  static Future<void> felszerelesKategoriakMentes(List<FelszerelesKategoria> kategoriak) async => await _mentes(_felszerelesKategoriakKulcs, kategoriak);
  static Future<List<FelszerelesKategoria>> felszerelesKategoriakBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    bool init = prefs.getBool('felszereles_init') ?? false;
    
    if (!init) {
      List<FelszerelesKategoria> alap = [
        FelszerelesKategoria(id: 'kat_1', nev: 'Botok', sorrend: 1),
        FelszerelesKategoria(id: 'kat_2', nev: 'Orsók', sorrend: 2),
        FelszerelesKategoria(id: 'kat_3', nev: 'Zsinórok', sorrend: 3),
        FelszerelesKategoria(id: 'kat_4', nev: 'Szerelékek', sorrend: 4),
        FelszerelesKategoria(id: 'kat_5', nev: 'Csalik', sorrend: 5),
        FelszerelesKategoria(id: 'kat_6', nev: 'Egyéb', sorrend: 6),
      ];
      await felszerelesKategoriakMentes(alap);
      await prefs.setBool('felszereles_init', true);
      return alap;
    }
    
    final adatok = await _betoltes(_felszerelesKategoriakKulcs);
    List<FelszerelesKategoria> list = adatok.map((e) => FelszerelesKategoria.fromJson(e)).toList();
    list.sort((a, b) => a.sorrend.compareTo(b.sorrend));
    return list;
  }

  static Future<void> felszerelesTetelekMentes(List<FelszerelesTetel> tetelek) async => await _mentes(_felszerelesTetelekKulcs, tetelek);
  static Future<List<FelszerelesTetel>> felszerelesTetelekBetoltese() async {
    final adatok = await _betoltes(_felszerelesTetelekKulcs);
    return adatok.map((e) => FelszerelesTetel.fromJson(e)).toList();
  }

  // --- TÖRZSDATOK (EGYSZERŰ LISTÁK) ---
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

  // --- IDŐJÁRÁS & HAL SORSA VISSZAÁLLÍTÁSOK ---
  static Future<void> idojarasMentes(List<String> adatok) async => await _mentes(_idojarasKulcs, adatok);
  static Future<List<String>> idojarasBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    bool init = prefs.getBool('idojaras_init') ?? false;
    if (!init) {
      await gyariIdojarasVisszaallitas();
      await prefs.setBool('idojaras_init', true);
    }
    return List<String>.from(await _betoltes(_idojarasKulcs));
  }
  static Future<void> gyariIdojarasVisszaallitas() async {
    List<String> gyari = [
      'Derült, tiszta', 'Változóan felhős', 'Borult, felhős', 'Szemerkélő eső',
      'Tartós eső', 'Zápor', 'Zivatar, vihar', 'Jégeső', 'Ködös, párás',
      'Viharos szél', 'Havazás', 'Havas eső'
    ];
    List<String> jelenlegi = List<String>.from(await _betoltes(_idojarasKulcs));
    for (String g in gyari) { if (!jelenlegi.contains(g)) jelenlegi.add(g); }
    await idojarasMentes(jelenlegi);
  }

  static Future<void> sorsMentes(List<String> adatok) async => await _mentes(_sorsKulcs, adatok);
  static Future<List<String>> sorsBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    bool init = prefs.getBool('sors_init') ?? false;
    if (!init) {
      await gyariSorsVisszaallitas();
      await prefs.setBool('sors_init', true);
    }
    return List<String>.from(await _betoltes(_sorsKulcs));
  }
  static Future<void> gyariSorsVisszaallitas() async {
    List<String> gyari = ['Visszaengedtem', 'Elvittem', 'Elajándékoztam', 'Elpusztult'];
    List<String> jelenlegi = List<String>.from(await _betoltes(_sorsKulcs));
    for (String g in gyari) { if (!jelenlegi.contains(g)) jelenlegi.add(g); }
    await sorsMentes(jelenlegi);
  }

  static Future<void> gyariFelszerelesKategoriakVisszaallitas() async {
    List<FelszerelesKategoria> gyari = [
      FelszerelesKategoria(id: 'kat_1', nev: 'Botok', sorrend: 1),
      FelszerelesKategoria(id: 'kat_2', nev: 'Orsók', sorrend: 2),
      FelszerelesKategoria(id: 'kat_3', nev: 'Zsinórok', sorrend: 3),
      FelszerelesKategoria(id: 'kat_4', nev: 'Szerelékek', sorrend: 4),
      FelszerelesKategoria(id: 'kat_5', nev: 'Csalik', sorrend: 5),
      FelszerelesKategoria(id: 'kat_6', nev: 'Egyéb', sorrend: 6),
    ];
    List<FelszerelesKategoria> jelenlegi = await felszerelesKategoriakBetoltese();
    for (var g in gyari) {
      if (!jelenlegi.any((k) => k.id == g.id)) {
        jelenlegi.add(g);
      } else {
        final idx = jelenlegi.indexWhere((k) => k.id == g.id);
        jelenlegi[idx] = g;
      }
    }
    await felszerelesKategoriakMentes(jelenlegi);
  }

  // --- HALFAJOK (Okos visszaállítás beépítve) ---
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

    return (await _betoltes(_halfajokKulcs)).map((e) => Halfaj.fromJson(e)).toList();
  }

  static Future<void> gyariHalfajokVisszaallitas() async {
    List<Halfaj> jelenlegi = await halfajokBetoltese();
    List<Halfaj> gyari = _getMagyarHalFauna();

    for (var gyHal in gyari) {
      int idx = jelenlegi.indexWhere((h) => h.id == gyHal.id);
      if (idx == -1) {
        jelenlegi.add(gyHal);
      } else {
        List<String> meglevoKepek = jelenlegi[idx].kepek;
        List<String> ujKepek = List.from(meglevoKepek);

        for (var gyKep in gyHal.kepek) {
          if (!ujKepek.contains(gyKep) && ujKepek.length < 5) {
            ujKepek.add(gyKep);
          }
        }

        jelenlegi[idx] = Halfaj(
          id: gyHal.id, nev: gyHal.nev, kategoria: gyHal.kategoria,
          statusz: gyHal.statusz, meretKorlatozas: gyHal.meretKorlatozas,
          darabKorlatozas: gyHal.darabKorlatozas, tilalmiIdoszak: gyHal.tilalmiIdoszak,
          szabalyozasEve: gyHal.szabalyozasEve, megjegyzes: gyHal.megjegyzes, kepek: ujKepek,
        );
      }
    }
    await halfajokMentes(jelenlegi);
  }

  // --- EXPORT / IMPORT (ZIP & JSON) ---
  static Future<String> letrehozExportJson() async {
    Map<String, dynamic> exportData = {
      'verzio': 1,
      'turak': await _betoltes(_turakKulcs),
      'fogasok': await _betoltes(_fogasokKulcs),
      'halfajok': await _betoltes(_halfajokKulcs),
      'helyszinek': await _betoltes(_helyszinekKulcs),
      'felszerelesKategoriak': await _betoltes(_felszerelesKategoriakKulcs),
      'felszerelesTetelek': await _betoltes(_felszerelesTetelekKulcs),
      'botok': await _betoltes(_botokKulcs),
      'modszerek': await _betoltes(_modszerekKulcs),
      'szerelekek': await _betoltes(_szerelekekKulcs),
      'csalik': await _betoltes(_csalikKulcs),
      'etetoanyagok': await _betoltes(_etetoanyagokKulcs),
      'tarsak': await _betoltes(_tarsakKulcs),
      'idojaras': await _betoltes(_idojarasKulcs),
      'sors': await _betoltes(_sorsKulcs),
      'dok_mappak': await _betoltes(_dokMappakKulcs),
      'dok_fajlok': await _betoltes(_dokFajlokKulcs),
    };
    return jsonEncode(exportData);
  }

  static Future<String> letrehozGyorsExportJSONFajl() async {
    final appDir = await getApplicationDocumentsDirectory();
    final jsonStr = await letrehozExportJson();
    final String idobelyeg = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
    final fajlNev = 'horgasznaplo_gyors_mentes_$idobelyeg.json';
    final path = '${appDir.path}/$fajlNev';
    await File(path).writeAsString(jsonStr);
    return path;
  }

  static Future<String> letrehozTeljesExportZIPFajl() async {
    final appDir = await getApplicationDocumentsDirectory();
    final archive = Archive();

    final jsonStr = await letrehozExportJson();
    final jsonData = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('adatbazeis.json', jsonData.length, jsonData));

    final kepekMappa = Directory('${appDir.path}/kepek');
    if (await kepekMappa.exists()) {
      for (var f in kepekMappa.listSync()) {
        if (f is File) {
          final nev = f.path.split('/').last;
          final bytok = await f.readAsBytes();
          archive.addFile(ArchiveFile('kepek/$nev', bytok.length, bytok));
        }
      }
    }

    final dokMappa = Directory('${appDir.path}/dokumentumok');
    if (await dokMappa.exists()) {
      for (var f in dokMappa.listSync()) {
        if (f is File) {
          final nev = f.path.split('/').last;
          final bytok = await f.readAsBytes();
          archive.addFile(ArchiveFile('dokumentumok/$nev', bytok.length, bytok));
        }
      }
    }

    final zipEncoder = ZipEncoder();
    final zipAdat = zipEncoder.encode(archive);
    final String idobelyeg = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
    final path = '${appDir.path}/horgasznaplo_teljes_mentes_$idobelyeg.zip';
    await File(path).writeAsBytes(zipAdat!);
    return path;
  }

  static Future<void> importalas(String fajlUtvonal) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonTartalom = '';

    if (fajlUtvonal.toLowerCase().endsWith('.zip')) {
      final bytes = await File(fajlUtvonal).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final appDir = await getApplicationDocumentsDirectory();
      
      final kepekMappa = Directory('${appDir.path}/kepek');
      if (!await kepekMappa.exists()) await kepekMappa.create(recursive: true);

      final dokMappa = Directory('${appDir.path}/dokumentumok');
      if (!await dokMappa.exists()) await dokMappa.create(recursive: true);

      for (final file in archive) {
        if (file.isFile) {
          if (file.name == 'adatbazeis.json') {
            jsonTartalom = utf8.decode(file.content as List<int>);
          } else if (file.name.startsWith('kepek/')) {
            final fileNev = file.name.replaceFirst('kepek/', '');
            await File('${kepekMappa.path}/$fileNev').writeAsBytes(file.content as List<int>);
          } else if (file.name.startsWith('dokumentumok/')) {
            final fileNev = file.name.replaceFirst('dokumentumok/', '');
            await File('${dokMappa.path}/$fileNev').writeAsBytes(file.content as List<int>);
          }
        }
      }
    } else if (fajlUtvonal.toLowerCase().endsWith('.json')) {
      jsonTartalom = await File(fajlUtvonal).readAsString();
    } else {
      throw Exception('Nem támogatott fájlformátum!');
    }

    final Map<String, dynamic> data = jsonDecode(jsonTartalom);
    if (data.containsKey('turak')) await prefs.setString(_turakKulcs, jsonEncode(data['turak']));
    if (data.containsKey('fogasok')) await prefs.setString(_fogasokKulcs, jsonEncode(data['fogasok']));
    if (data.containsKey('halfajok')) await prefs.setString(_halfajokKulcs, jsonEncode(data['halfajok']));
    if (data.containsKey('helyszinek')) await prefs.setString(_helyszinekKulcs, jsonEncode(data['helyszinek']));
    if (data.containsKey('felszerelesKategoriak')) await prefs.setString(_felszerelesKategoriakKulcs, jsonEncode(data['felszerelesKategoriak']));
    if (data.containsKey('felszerelesTetelek')) await prefs.setString(_felszerelesTetelekKulcs, jsonEncode(data['felszerelesTetelek']));
    if (data.containsKey('botok')) await prefs.setString(_botokKulcs, jsonEncode(data['botok']));
    if (data.containsKey('modszerek')) await prefs.setString(_modszerekKulcs, jsonEncode(data['modszerek']));
    if (data.containsKey('szerelekek')) await prefs.setString(_szerelekekKulcs, jsonEncode(data['szerelekek']));
    if (data.containsKey('csalik')) await prefs.setString(_csalikKulcs, jsonEncode(data['csalik']));
    if (data.containsKey('etetoanyagok')) await prefs.setString(_etetoanyagokKulcs, jsonEncode(data['etetoanyagok']));
    if (data.containsKey('tarsak')) await prefs.setString(_tarsakKulcs, jsonEncode(data['tarsak']));
    if (data.containsKey('idojaras')) await prefs.setString(_idojarasKulcs, jsonEncode(data['idojaras']));
    if (data.containsKey('sors')) await prefs.setString(_sorsKulcs, jsonEncode(data['sors']));
    if (data.containsKey('dok_mappak')) await prefs.setString(_dokMappakKulcs, jsonEncode(data['dok_mappak']));
    if (data.containsKey('dok_fajlok')) await prefs.setString(_dokFajlokKulcs, jsonEncode(data['dok_fajlok']));
  }

  static Future<void> torzsadatNevFrissites(String kategoria, String regiNev, String ujNev) async {}
  static Future<void> torzsadatTorles(String kategoria, String toroltNevVagyId) async {}
  static Future<void> dlcKepCsomagKicsomagolasa(String zipPath) async {}

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
        id: 'hal_23', nev: 'Tokhal (Hibridek)', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Ősi, cápaszerű megjelenés, csontvértek, alsó állású száj. Fenékről porszívózza a táplálékot. Halibut pelletekkel fogható intenzíven telepített tavakon.',
        kepek: [_ph('Tokhal (Hibrid) 1'), _ph('Tokhal 2'), _ph('Tokhal 3')],
      ),
      Halfaj(
        id: 'hal_24', nev: 'Fekete amur', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Az amurhoz hasonló, de sötétebb, feketés pikkelyzetű. Kizárólag puhatestűeket (csigákat, kagylókat) roppant össze. GLM (zöldkagylós) bojlival fogható.',
        kepek: [_ph('Fekete amur 1'), _ph('Fekete amur 2'), _ph('Fekete amur 3')],
      ),
      Halfaj(
        id: 'hal_25', nev: 'Buffalo (Nagyszájú buffalo)', kategoria: 'Békés', statusz: 'Fogható (Idegenhonos)',
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
        id: 'hal_37', nev: 'Kecsege', kategoria: 'Békés', statusz: 'Nem fogható',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Pikkelytelen dunai tokféle, hátán csontos vértekkel, felkunkorodó orral. Horgászata és megtartása tilos (kivéve éves, személyre szóló eseti engedéllyel).',
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
      Halfaj(
        id: 'hal_41', nev: 'Magyar bucó', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Megnyúlt, hengeres testű, sárgás-barnás csíkos hal. Teljesen a mederfenékre lapulva él a gyors folyókban. Védett!',
        kepek: [_ph('Magyar bucó 1'), _ph('Magyar bucó 2'), _ph('Magyar bucó 3')],
      ),
      Halfaj(
        id: 'hal_42', nev: 'Német bucó', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A magyar bucóhoz hasonló, fenéklakó folyóvízi hal. Szigorúan védett!',
        kepek: [_ph('Német bucó 1'), _ph('Német bucó 2'), _ph('Német bucó 3')],
      ),
      Halfaj(
        id: 'hal_43', nev: 'Tarka géb', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Őshonos és védett gébféle (csövesorrú géb). Nagyon hasonlít az inváziós rokonaira, de orrnyílásaiból kis csövecskék állnak ki.',
        kepek: [_ph('Tarka géb 1'), _ph('Tarka géb 2'), _ph('Tarka géb 3')],
      ),
      Halfaj(
        id: 'hal_44', nev: 'Réti csík', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Kígyószerű, csúszós testű hal bajuszszálakkal. Iszapos, mocsaras holtágakban él. Szigorúan védett!',
        kepek: [_ph('Réti csík 1'), _ph('Réti csík 2'), _ph('Réti csík 3')],
      ),
      Halfaj(
        id: 'hal_45', nev: 'Vágó csík', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A réti csíkhoz hasonló, lapítottabb testű, fenéklakó hal. Védett faj!',
        kepek: [_ph('Vágó csík 1'), _ph('Vágó csík 2'), _ph('Vágó csík 3')],
      ),
      Halfaj(
        id: 'hal_46', nev: 'Pénzes pér', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Hatalmas, vitorlaszerű, színpompás hátúszója van. Hegyi folyókban, patakokban él. Szigorúan védett!',
        kepek: [_ph('Pénzes pér 1'), _ph('Pénzes pér 2'), _ph('Pénzes pér 3')],
      ),
      Halfaj(
        id: 'hal_47', nev: 'Lápi póc', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Apró, barna, kerekded uszonyú halacska. Kisebb, növényzettel benőtt csatornákban él. Fokozottan védett, endemikus fajunk!',
        kepek: [_ph('Lápi póc 1'), _ph('Lápi póc 2'), _ph('Lápi póc 3')],
      ),
      Halfaj(
        id: 'hal_48', nev: 'Viza', kategoria: 'Ragadozó', statusz: 'Nem fogható',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A tokfélék egykori óriása, hatalmasra növő porcos hal. Ma már extrém ritka, megtartása szigorúan tilos!',
        kepek: [_ph('Viza 1'), _ph('Viza 2'), _ph('Viza 3')],
      ),
      Halfaj(
        id: 'hal_49', nev: 'Vágó tok', kategoria: 'Békés', statusz: 'Nem fogható',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Őshonos, a Dunában és Tiszában élő tokféle. A hibrid tokhalakkal ellentétben a természetes vizekben nem fogható!',
        kepek: [_ph('Vágó tok 1'), _ph('Vágó tok 2'), _ph('Vágó tok 3')],
      ),
      Halfaj(
        id: 'hal_50', nev: 'Sima tok', kategoria: 'Békés', statusz: 'Nem fogható',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Ritka, őshonos tokfélénk. Természetes vizeinkben tilos megtartani.',
        kepek: [_ph('Sima tok 1'), _ph('Sima tok 2'), _ph('Sima tok 3')],
      ),
      Halfaj(
        id: 'hal_51', nev: 'Sőregtok', kategoria: 'Ragadozó', statusz: 'Nem fogható',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Ritka, őshonos dunai tokféle. Kifogása esetén azonnal vissza kell engedni.',
        kepek: [_ph('Sőregtok 1'), _ph('Sőregtok 2'), _ph('Sőregtok 3')],
      ),
      Halfaj(
        id: 'hal_52', nev: 'Vágó durbincs', kategoria: 'Ragadozó', statusz: 'Nem fogható',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Apró, a sügérfélékhez tartozó tüskés hal. Folyókon gilisztás fenekezésnél gyakori. Megtartani és csalihalként használni tilos!',
        kepek: [_ph('Vágó durbincs 1'), _ph('Vágó durbincs 2'), _ph('Vágó durbincs 3')],
      ),
      Halfaj(
        id: 'hal_53', nev: 'Selymes durbincs', kategoria: 'Ragadozó', statusz: 'Nem fogható',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A vágó durbinchoz hasonló apró folyóvízi hal. Állományvédelmi okokból nem fogható.',
        kepek: [_ph('Selymes durbincs 1'), _ph('Selymes durbincs 2'), _ph('Selymes durbincs 3')],
      ),
      Halfaj(
        id: 'hal_54', nev: 'Feketeszájú géb', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Kisméretű, kártékony betelepült hal. Nevét a hímek fekete szájáról kapta. Visszaengedni tilos!',
        kepek: [_ph('Feketeszájú géb 1'), _ph('Feketeszájú géb 2'), _ph('Feketeszájú géb 3')],
      ),
      Halfaj(
        id: 'hal_55', nev: 'Csupasztorkú géb', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Apró inváziós gébféle. Hazai halaink ikráit pusztítja, visszaengedni tilos!',
        kepek: [_ph('Csupasztorkú géb 1'), _ph('Csupasztorkú géb 2'), _ph('Csupasztorkú géb 3')],
      ),
      Halfaj(
        id: 'hal_56', nev: 'Kessler-géb', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'A legnagyobb méretű inváziós gébféle hazánkban. Lapos fej és nagy száj jellemzi. Visszaengedni tilos!',
        kepek: [_ph('Kessler-géb 1'), _ph('Kessler-géb 2'), _ph('Kessler-géb 3')],
      ),
      Halfaj(
        id: 'hal_57', nev: 'Szélhajtó küsz (Sneci)', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Leggyakoribb felszíni apróhalunk, népszerű csalihal süllőzéshez és balinozáshoz.',
        kepek: [_ph('Szélhajtó küsz 1'), _ph('Szélhajtó küsz 2'), _ph('Szélhajtó küsz 3')],
      ),
      Halfaj(
        id: 'hal_58', nev: 'Bagolykeszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Nyúlánkabb, nagypikkelyű keszegféle, gyakran a dévérrel együtt fogható folyóvizeken.',
        kepek: [_ph('Bagolykeszeg 1'), _ph('Bagolykeszeg 2'), _ph('Bagolykeszeg 3')],
      ),
      Halfaj(
        id: 'hal_59', nev: 'Lánykeszeg', kategoria: 'Békés', statusz: 'Fogható (Őshonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs (egyéb hal)', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Folyóvízi keszegféle, paduccal és szilvaorrúval egy áramlatban úszik.',
        kepek: [_ph('Lánykeszeg 1'), _ph('Lánykeszeg 2'), _ph('Lánykeszeg 3')],
      ),
      Halfaj(
        id: 'hal_60', nev: 'Naphal', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Korong alakú, színpompás amerikai apróhal, kopoltyúján fekete-piros folttal ("füllel"). Kártékony ikrapusztító, visszaengedni tilos!',
        kepek: [_ph('Naphal 1'), _ph('Naphal 2'), _ph('Naphal 3')],
      ),
      Halfaj(
        id: 'hal_61', nev: 'Kínai razbóra', kategoria: 'Békés', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Apró, ezüstös-barnás betelepült hal. Csalitolvaj apróhal, melyet szigorúan tilos visszaengedni!',
        kepek: [_ph('Kínai razbóra 1'), _ph('Kínai razbóra 2'), _ph('Kínai razbóra 3')],
      ),
      Halfaj(
        id: 'hal_62', nev: 'Amurgéb', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Távol-Keletről származó, rendkívül kártékony, ragadozó életmódú apróhal. Visszaengedni tilos!',
        kepek: [_ph('Amurgéb 1'), _ph('Amurgéb 2'), _ph('Amurgéb 3')],
      ),
      Halfaj(
        id: 'hal_63', nev: 'Szivárványos ökle', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Kékes-lilás apróhal, a szaporodásához elengedhetetlen a tavi kagyló (abba rakja ikráit). Szigorúan védett!',
        kepek: [_ph('Szivárványos ökle 1'), _ph('Szivárványos ökle 2'), _ph('Szivárványos ökle 3')],
      ),
      Halfaj(
        id: 'hal_64', nev: 'Galóca', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Hazánk legnagyobb méretű lazacféléje a hegyi folyókban. Hatalmas ragadozó, de megtartani tilos, védett!',
        kepek: [_ph('Galóca 1'), _ph('Galóca 2'), _ph('Galóca 3')],
      ),
      Halfaj(
        id: 'hal_65', nev: 'Fenékjáró küllő', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Apró, márnához hasonló, pettyes fenéklakó hal. Védett faj, azonnal vissza kell engedni.',
        kepek: [_ph('Fenékjáró küllő 1'), _ph('Fenékjáró küllő 2'), _ph('Fenékjáró küllő 3')],
      ),
      Halfaj(
        id: 'hal_66', nev: 'Kövi csík', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Köves, hegyvidéki patakokban előforduló védett csíkféle.',
        kepek: [_ph('Kövi csík 1'), _ph('Kövi csík 2'), _ph('Kövi csík 3')],
      ),
      Halfaj(
        id: 'hal_67', nev: 'Fürge cselle', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Hűvös patakokban élő apró, áramlatkedvelő védett halfaj.',
        kepek: [_ph('Fürge cselle 1'), _ph('Fürge cselle 2'), _ph('Fürge cselle 3')],
      ),
      Halfaj(
        id: 'hal_68', nev: 'Botos kölönte', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Kövek alatt rejtőző, hegyi vizekben élő fenéklakó ragadozó apróhal. Védett!',
        kepek: [_ph('Botos kölönte 1'), _ph('Botos kölönte 2'), _ph('Botos kölönte 3')],
      ),
      Halfaj(
        id: 'hal_69', nev: 'Fekete törpeharcsa', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Észak-amerikai eredetű inváziós faj. Hasonlít a törpeharcsára, de sötétebb, feketés színezetű. Ikrapusztító, visszaengedni tilos!',
        kepek: [_ph('Fekete törpeharcsa 1'), _ph('Fekete törpeharcsa 2'), _ph('Fekete törpeharcsa 3')],
      ),
      Halfaj(
        id: 'hal_70', nev: 'Pataki szajbling', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Észak-amerikai pisztrángféle. Hideg, tiszta vizű hegyi patakokban él. Pergetve vagy műléggyel fogható.',
        kepek: [_ph('Pataki szajbling 1'), _ph('Pataki szajbling 2'), _ph('Pataki szajbling 3')],
      ),
      Halfaj(
        id: 'hal_71', nev: 'Tüskés pikó', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Apró, védett halacska, hátán 3-4 jellegzetes tüskével. Ikrarabló, de őshonos ritkaság lévén védett.',
        kepek: [_ph('Tüskés pikó 1'), _ph('Tüskés pikó 2'), _ph('Tüskés pikó 3')],
      ),
      Halfaj(
        id: 'hal_72', nev: 'Folyami géb', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Kártékony, inváziós gébféle. Folyóvizeink kövezésein tömegesen fordul elő. Visszaengedni tilos!',
        kepek: [_ph('Folyami géb 1'), _ph('Folyami géb 2'), _ph('Folyami géb 3')],
      ),
      Halfaj(
        id: 'hal_73', nev: 'Kaukázusi törpegéb', kategoria: 'Ragadozó', statusz: 'Inváziós',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Apró méretű, nagyon szapora inváziós gébféle. Kiszorítja az őshonos halakat, visszaengedni tilos!',
        kepek: [_ph('Kaukázusi törpegéb 1'), _ph('Kaukázusi törpegéb 2'), _ph('Kaukázusi törpegéb 3')],
      ),
      Halfaj(
        id: 'hal_74', nev: 'Gyöngyös koncér', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Közepes méretű, áramlatkedvelő pontyféle. Sötét pikkelyszélei hálózatos mintát adnak. Védett folyóvízi hal!',
        kepek: [_ph('Gyöngyös koncér 1'), _ph('Gyöngyös koncér 2'), _ph('Gyöngyös koncér 3')],
      ),
      Halfaj(
        id: 'hal_75', nev: 'Nyúldomolykó', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A domolykóhoz hasonló, de nyúlánkabb testű, kisebb szájú folyóvízi hal. Szigorúan védett!',
        kepek: [_ph('Nyúldomolykó 1'), _ph('Nyúldomolykó 2'), _ph('Nyúldomolykó 3')],
      ),
      Halfaj(
        id: 'hal_76', nev: 'Petényi-márna', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Kisméretű, patakokban élő márnaféle. Nevét Petényi Salamon Jánosról kapta. Fokozottan védett!',
        kepek: [_ph('Petényi-márna 1'), _ph('Petényi-márna 2'), _ph('Petényi-márna 3')],
      ),
      Halfaj(
        id: 'hal_77', nev: 'Kurta baing', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A balinhoz hasonló, kisméretű, felszínközeli ragadozó. Védett faj, azonnal vissza kell engedni!',
        kepek: [_ph('Kurta baing 1'), _ph('Kurta baing 2'), _ph('Kurta baing 3')],
      ),
      Halfaj(
        id: 'hal_78', nev: 'Sujtásos küsz', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'A szélhajtó küsz rokona, testén sötét, sujtásszerű sáv fut végig. Tiszta folyókban él, védett faj!',
        kepek: [_ph('Sujtásos küsz 1'), _ph('Sujtásos küsz 2'), _ph('Sujtásos küsz 3')],
      ),
      Halfaj(
        id: 'hal_79', nev: 'Vaskos csabak', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Zömök testű, ezüstös-sárgás folyóvízi hal. Hegyi és dombvidéki patakokban él. Védett!',
        kepek: [_ph('Vaskos csabak 1'), _ph('Vaskos csabak 2'), _ph('Vaskos csabak 3')],
      ),
      Halfaj(
        id: 'hal_80', nev: 'Dunai nagyhering', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Tengerből a Dunába felúszó, heringalakú hal. Valaha hatalmas csapatokban vándorolt, ma rendkívül ritka és védett!',
        kepek: [_ph('Dunai nagyhering 1'), _ph('Dunai nagyhering 2'), _ph('Dunai nagyhering 3')],
      ),
      Halfaj(
        id: 'hal_81', nev: 'Széles durbincs', kategoria: 'Ragadozó', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Magas hátú, a vágó durbinccsal rokon, sügérféle apróhal. Folyók mélyebb részein él, védett faj!',
        kepek: [_ph('Széles durbincs 1'), _ph('Széles durbincs 2'), _ph('Széles durbincs 3')],
      ),
      Halfaj(
        id: 'hal_82', nev: 'Halványfoltú küllő', kategoria: 'Békés', statusz: 'Védett',
        meretKorlatozas: '-', darabKorlatozas: '-', tilalmiIdoszak: 'Egész évben', szabalyozasEve: '2024',
        megjegyzes: 'Apró, fenéklakó hal, testén halvány foltokkal. Homokos, kavicsos medrű folyókban él. Védett!',
        kepek: [_ph('Halványfoltú küllő 1'), _ph('Halványfoltú küllő 2'), _ph('Halványfoltú küllő 3')],
      ),
      Halfaj(
        id: 'hal_83', nev: 'Lénai tok', kategoria: 'Ragadozó', statusz: 'Fogható (Idegenhonos)',
        meretKorlatozas: 'Nincs', darabKorlatozas: 'Nincs', tilalmiIdoszak: 'Nincs', szabalyozasEve: '2024',
        megjegyzes: 'Szibériából származó, tógazdaságokban és horgásztavakban gyakori tokféle. Intenzív tavakon pellettel fogható.',
        kepek: [_ph('Lénai tok 1'), _ph('Lénai tok 2'), _ph('Lénai tok 3')],
      ),
    ];
  }
}
