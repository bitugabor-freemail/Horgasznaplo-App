import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';

import 'modellek.dart';
import 'halfajok_adatok.dart'; // ÚJ: Behúztuk a külső lexikon fájlt!

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
  static const String _taskakKulcs = 'torzs_taskak'; 
  static const String _felszerelesKategoriakKulcs = 'felszereles_kategoriak';
  static const String _felszerelesTetelekKulcs = 'felszereles_tetelek';
  
  static const String _dokMappakKulcs = 'dok_mappak';
  static const String _dokFajlokKulcs = 'dok_fajlok';

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

  static Future<void> helyszinekMentes(List<Helyszin> helyszinek) async => await _mentes(_helyszinekKulcs, helyszinek);
  static Future<List<Helyszin>> helyszinekBetoltese() async {
    final adatok = await _betoltes(_helyszinekKulcs);
    return adatok.map((e) => Helyszin.fromJson(e)).toList();
  }

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

  static Future<void> felszerelesTetelekMentes(List<FelszerelesTetel> tetelek) async => await _mentes(_felszerelesTetelekKulcs, tetelek);
  static Future<List<FelszerelesTetel>> felszerelesTetelekBetoltese() async {
    final adatok = await _betoltes(_felszerelesTetelekKulcs);
    return adatok.map((e) => FelszerelesTetel.fromJson(e)).toList();
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
  
  static Future<void> taskakMentes(List<String> adatok) async => await _mentes(_taskakKulcs, adatok);
  static Future<List<String>> taskakBetoltese() async => List<String>.from(await _betoltes(_taskakKulcs));

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

  static Future<void> halfajokMentes(List<Halfaj> halfajok) async => await _mentes(_halfajokKulcs, halfajok);
  
  // ÚJ: A betöltésnél a külső fájlra (HalfajAdatok) hivatkozunk
  static Future<List<Halfaj>> halfajokBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    bool init = prefs.getBool('halfaj_init') ?? false;

    if (!init) {
      List<Halfaj> alapHalfajok = HalfajAdatok.getMagyarHalFauna();
      await halfajokMentes(alapHalfajok);
      await prefs.setBool('halfaj_init', true);
      return alapHalfajok;
    }

    return (await _betoltes(_halfajokKulcs)).map((e) => Halfaj.fromJson(e)).toList();
  }

  static Future<void> gyariHalfajokVisszaallitas() async {
    List<Halfaj> jelenlegi = await halfajokBetoltese();
    List<Halfaj> gyari = HalfajAdatok.getMagyarHalFauna();

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
      'taskak': await _betoltes(_taskakKulcs), 
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

  static Future<String?> letrehozTeljesExportZIPFajl(Function(double) onProgress, {bool Function()? isCancelled}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final String idobelyeg = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
    final zipPath = '${appDir.path}/horgasznaplo_teljes_mentes_$idobelyeg.zip';

    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(zipPath);

    final jsonStr = await letrehozExportJson();
    final jsonFile = File('${appDir.path}/temp_adatok.json');
    await jsonFile.writeAsString(jsonStr);
    zipEncoder.addFile(jsonFile, 'adatbazeis.json');

    List<File> csomagolandoFajlok = [];
    
    final kepekMappa = Directory('${appDir.path}/kepek');
    if (await kepekMappa.exists()) {
      for (var f in kepekMappa.listSync()) {
        if (f is File) csomagolandoFajlok.add(f);
      }
    }

    final dokMappa = Directory('${appDir.path}/dokumentumok');
    if (await dokMappa.exists()) {
      for (var f in dokMappa.listSync()) {
        if (f is File) csomagolandoFajlok.add(f);
      }
    }

    int osszesFajl = csomagolandoFajlok.length;
    int feldolgozva = 0;

    if (osszesFajl == 0) {
      onProgress(1.0);
    } else {
      for (var f in csomagolandoFajlok) {
        if (isCancelled != null && isCancelled()) {
          zipEncoder.close();
          if (await jsonFile.exists()) await jsonFile.delete();
          final hibasZip = File(zipPath);
          if (await hibasZip.exists()) await hibasZip.delete();
          return null; 
        }

        String utvonalRendezes = f.path.contains('/kepek/') ? 'kepek' : 'dokumentumok';
        zipEncoder.addFile(f, '$utvonalRendezes/${f.path.split('/').last}');
        
        feldolgozva++;
        onProgress(feldolgozva / osszesFajl);
        
        await Future.delayed(const Duration(milliseconds: 2)); 
      }
    }

    zipEncoder.close();
    if (await jsonFile.exists()) await jsonFile.delete();

    return zipPath;
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
    if (data.containsKey('taskak')) await prefs.setString(_taskakKulcs, jsonEncode(data['taskak'])); 
    if (data.containsKey('dok_mappak')) await prefs.setString(_dokMappakKulcs, jsonEncode(data['dok_mappak']));
    if (data.containsKey('dok_fajlok')) await prefs.setString(_dokFajlokKulcs, jsonEncode(data['dok_fajlok']));

    await prefs.setBool('felszereles_init', true);
    await prefs.setBool('halfaj_init', true);
    await prefs.setBool('idojaras_init', true);
    await prefs.setBool('sors_init', true);
  }

  static Future<void> torzsadatNevFrissites(String kategoria, String regiNev, String ujNev) async {}
  static Future<void> torzsadatTorles(String kategoria, String toroltNevVagyId) async {}
  static Future<void> dlcKepCsomagKicsomagolasa(String zipPath) async {}
}
