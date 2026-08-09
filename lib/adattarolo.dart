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

  static Future<void> sorsMentes(List<String> adatok) async => await _mentes(_sorsKulcs, adatok);
  static Future<List<String>> sorsBetoltese() async => List<String>.from(await _betoltes(_sorsKulcs));

  // --- 9. PONT: TÖRZSDATOK VISSZAMENŐLEGES SZINKRONIZÁCIÓJA ---
  
  static Future<void> torzsadatNevFrissites(String kategoria, String regiNev, String ujNev) async {
    // 1. Túrák frissítése (csak Horgásztársak érinti)
    if (kategoria == 'Horgásztársak') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (var t in turak) {
        for (int i = 0; i < t.horgasztarsak.length; i++) {
          if (t.horgasztarsak[i] == regiNev) {
            t.horgasztarsak[i] = ujNev;
            changed = true;
          }
        }
      }
      if (changed) await turakMentes(turak);
    }

    // 2. Fogások frissítése (minden más)
    final fogasok = await fogasokBetoltese();
    bool fogasChanged = false;
    for (var f in fogasok) {
      if (kategoria == 'Halfaj' && f.halfaj == regiNev) { f.halfaj = ujNev; fogasChanged = true; } // Ha a halfaj nevét átírtuk
      if (kategoria == 'Horgászbot' && f.bot == regiNev) { f.bot = ujNev; fogasChanged = true; }
      if (kategoria == 'Módszer' && f.modszer == regiNev) { f.modszer = ujNev; fogasChanged = true; }
      if (kategoria == 'Végszerelék' && f.vegszerelek == regiNev) { f.vegszerelek = ujNev; fogasChanged = true; }
      if (kategoria == 'Időjárás' && f.idojaras == regiNev) { f.idojaras = ujNev; fogasChanged = true; }
      if (kategoria == 'Hal sorsa' && f.sors == regiNev) { f.sors = ujNev; fogasChanged = true; }
      
      if (kategoria == 'Csali') {
        for (int i = 0; i < f.csali.length; i++) {
          if (f.csali[i] == regiNev) { f.csali[i] = ujNev; fogasChanged = true; }
        }
      }
      if (kategoria == 'Etetőanyag') {
        for (int i = 0; i < f.etetoanyag.length; i++) {
          if (f.etetoanyag[i] == regiNev) { f.etetoanyag[i] = ujNev; fogasChanged = true; }
        }
      }
    }
    if (fogasChanged) await fogasokMentes(fogasok);
  }

  static Future<void> torzsadatTorles(String kategoria, String toroltNevVagyId) async {
    // 1. Helyszín törlés (Itt ID-t kapunk, és a Túrából kell kivenni)
    if (kategoria == 'Helyszín') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (var t in turak) {
        if (t.helyszinId == toroltNevVagyId) {
          t.helyszinId = null;
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
      return;
    }

    // 2. Horgásztárs törlés (Túrából kivenni)
    if (kategoria == 'Horgásztársak') {
      final turak = await turakBetoltese();
      bool changed = false;
      for (var t in turak) {
        if (t.horgasztarsak.contains(toroltNevVagyId)) {
          t.horgasztarsak.remove(toroltNevVagyId);
          changed = true;
        }
      }
      if (changed) await turakMentes(turak);
    }

    // 3. Fogások adatainak kiürítése
    final fogasok = await fogasokBetoltese();
    bool fogasChanged = false;
    for (var f in fogasok) {
      if (kategoria == 'Halfaj' && f.halfaj == toroltNevVagyId) { f.halfaj = ''; fogasChanged = true; } // Mivel String, üressé tesszük
      if (kategoria == 'Horgászbot' && f.bot == toroltNevVagyId) { f.bot = null; fogasChanged = true; }
      if (kategoria == 'Módszer' && f.modszer == toroltNevVagyId) { f.modszer = null; fogasChanged = true; }
      if (kategoria == 'Végszerelék' && f.vegszerelek == toroltNevVagyId) { f.vegszerelek = null; fogasChanged = true; }
      if (kategoria == 'Időjárás' && f.idojaras == toroltNevVagyId) { f.idojaras = null; fogasChanged = true; }
      if (kategoria == 'Hal sorsa' && f.sors == toroltNevVagyId) { f.sors = null; fogasChanged = true; }
      
      if (kategoria == 'Csali' && f.csali.contains(toroltNevVagyId)) { f.csali.remove(toroltNevVagyId); fogasChanged = true; }
      if (kategoria == 'Etetőanyag' && f.etetoanyag.contains(toroltNevVagyId)) { f.etetoanyag.remove(toroltNevVagyId); fogasChanged = true; }
    }
    if (fogasChanged) await fogasokMentes(fogasok);
  }
}
