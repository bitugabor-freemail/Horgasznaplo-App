import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'modellek.dart';

class AdatTarolo {
  // Fő adatbázis kulcsok
  static const String _turakKulcs = 'turak_adatok';
  static const String _fogasokKulcs = 'fogasok_adatok';
  
  // Törzsadat kategória kulcsok (10 db)
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

  // --- ÁLTALÁNOS MENTÉS ÉS BETÖLTÉS ---
  static Future<void> _mentes(String kulcs, List<dynamic> adatLista) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> jsonLista = [];
    
    // Ha összetett objektum (Halfaj, Helyszin, Tura, Fogas)
    if (adatLista.isNotEmpty && adatLista.first is! String) {
      jsonLista = adatLista.map((item) => item.toJson()).toList();
    } else {
      // Sima String lista (pl. Botok, Csalik)
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

  // --- MODELLEK MENTÉSE ÉS BETÖLTÉSE ---
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
    final adatok = await _betoltes(_halfajokKulcs);
    return adatok.map((e) => Halfaj.fromJson(e)).toList();
  }

  static Future<void> helyszinekMentes(List<Helyszin> helyszinek) async => await _mentes(_helyszinekKulcs, helyszinek);
  static Future<List<Helyszin>> helyszinekBetoltese() async {
    final adatok = await _betoltes(_helyszinekKulcs);
    return adatok.map((e) => Helyszin.fromJson(e)).toList();
  }

  // --- EGYSZERŰ STRING TÖRZSDATOK MENTÉSE ÉS BETÖLTÉSE ---
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

  // --- 12. PONT: Időjárás előtöltése az első indításkor ---
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

  // --- Hal sorsa törzsadat előtöltése az első indításkor ---
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

  // --- 9. PONT: TÖRZSDATOK VISSZAMENŐLEGES SZINKRONIZÁCIÓJA ---
  
  static Future<void> torzsadatNevFrissites(String kategoria, String regiNev, String ujNev) async {
    // 1. Túrák frissítése
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
          turak[i] = Tura(
            id: t.id,
            kezdoDatum: t.kezdoDatum,
            befejezoDatum: t.befejezoDatum,
            helyszinId: t.helyszinId,
            horgaszhely: t.horgaszhely,
            horgasztarsak: ujTarsak,
            boritoKep: t.boritoKep,
            megjegyzes: t.megjegyzes,
          );
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
    }

    // 2. Fogások frissítése
    final fogasok = await fogasokBetoltese();
    bool fogasChanged = false;
    for (int i = 0; i < fogasok.length; i++) {
      var f = fogasok[i];
      bool changed = false;
      
      String ujHalfaj = f.halfaj;
      String? ujBot = f.bot;
      String? ujModszer = f.modszer;
      String? ujVegszerelek = f.vegszerelek;
      String? ujIdojaras = f.idojaras;
      String? ujSors = f.sors;
      List<String> ujCsali = List.from(f.csali);
      List<String> ujEtetoanyag = List.from(f.etetoanyag);

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
        fogasok[i] = FogasModel(
          id: f.id,
          turaId: f.turaId,
          datum: f.datum,
          idopont: f.idopont,
          halfaj: ujHalfaj,
          suly: f.suly,
          hossz: f.hossz,
          sors: ujSors,
          csali: ujCsali,
          etetoanyag: ujEtetoanyag,
          etetesGyakorisaga: f.etetesGyakorisaga,
          bot: ujBot,
          modszer: ujModszer,
          vegszerelek: ujVegszerelek,
          idojaras: ujIdojaras,
          homerseklet: f.homerseklet,
          megjegyzes: f.megjegyzes,
          fenykep: f.fenykep,
          isKedvenc: f.isKedvenc,
        );
        fogasChanged = true;
      }
    }
    if (fogasChanged) await fogasokMentes(fogasok);
  }

  static Future<void> torzsadatTorles(String kategoria, String toroltNevVagyId) async {
    // 1. Helyszín törlés
    if (kategoria == 'Helyszín') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (int i = 0; i < turak.length; i++) {
        var t = turak[i];
        if (t.helyszinId == toroltNevVagyId) {
          turak[i] = Tura(
            id: t.id,
            kezdoDatum: t.kezdoDatum,
            befejezoDatum: t.befejezoDatum,
            helyszinId: null,
            horgaszhely: t.horgaszhely,
            horgasztarsak: t.horgasztarsak,
            boritoKep: t.boritoKep,
            megjegyzes: t.megjegyzes,
          );
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
      return;
    }

    // 2. Horgásztárs törlés
    if (kategoria == 'Horgásztársak') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (int i = 0; i < turak.length; i++) {
        var t = turak[i];
        if (t.horgasztarsak.contains(toroltNevVagyId)) {
          List<String> ujTarsak = List.from(t.horgasztarsak)..remove(toroltNevVagyId);
          turak[i] = Tura(
            id: t.id,
            kezdoDatum: t.kezdoDatum,
            befejezoDatum: t.befejezoDatum,
            helyszinId: t.helyszinId,
            horgaszhely: t.horgaszhely,
            horgasztarsak: ujTarsak,
            boritoKep: t.boritoKep,
            megjegyzes: t.megjegyzes,
          );
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
    }

    // 3. Fogások adatainak kiürítése
    final fogasok = await fogasokBetoltese();
    bool fogasChanged = false;
    for (int i = 0; i < fogasok.length; i++) {
      var f = fogasok[i];
      bool changed = false;
      
      String ujHalfaj = f.halfaj;
      String? ujBot = f.bot;
      String? ujModszer = f.modszer;
      String? ujVegszerelek = f.vegszerelek;
      String? ujIdojaras = f.idojaras;
      String? ujSors = f.sors;
      List<String> ujCsali = List.from(f.csali);
      List<String> ujEtetoanyag = List.from(f.etetoanyag);

      if (kategoria == 'Halfaj' && f.halfaj == toroltNevVagyId) { ujHalfaj = ''; changed = true; } 
      if (kategoria == 'Horgászbot' && f.bot == toroltNevVagyId) { ujBot = null; changed = true; }
      if (kategoria == 'Módszer' && f.modszer == toroltNevVagyId) { ujModszer = null; changed = true; }
      if (kategoria == 'Végszerelék' && f.vegszerelek == toroltNevVagyId) { ujVegszerelek = null; changed = true; }
      if (kategoria == 'Időjárás' && f.idojaras == toroltNevVagyId) { ujIdojaras = null; changed = true; }
      if (kategoria == 'Hal sorsa' && f.sors == toroltNevVagyId) { ujSors = null; changed = true; }
      
      if (kategoria == 'Csali' && ujCsali.contains(toroltNevVagyId)) { ujCsali.remove(toroltNevVagyId); changed = true; }
      if (kategoria == 'Etetőanyag' && ujEtetoanyag.contains(toroltNevVagyId)) { ujEtetoanyag.remove(toroltNevVagyId); changed = true; }

      if (changed) {
        fogasok[i] = FogasModel(
          id: f.id,
          turaId: f.turaId,
          datum: f.datum,
          idopont: f.idopont,
          halfaj: ujHalfaj,
          suly: f.suly,
          hossz: f.hossz,
          sors: ujSors,
          csali: ujCsali,
          etetoanyag: ujEtetoanyag,
          etetesGyakorisaga: f.etetesGyakorisaga,
          bot: ujBot,
          modszer: ujModszer,
          vegszerelek: ujVegszerelek,
          idojaras: ujIdojaras,
          homerseklet: f.homerseklet,
          megjegyzes: f.megjegyzes,
          fenykep: f.fenykep,
          isKedvenc: f.isKedvenc,
        );
        fogasChanged = true;
      }
    }
    if (fogasChanged) await fogasokMentes(fogasok);
  }
}
