import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdatTarolo {
  // Ezek a kulcsok, amik hivatkoznak a fájlokra a telefonon
  static const String _turakKulcs = 'turak_adatok';
  static const String _fogasokKulcs = 'fogasok_adatok';
  static const String _halfajokKulcs = 'halfajok_adatok';
  static const String _helyszinekKulcs = 'helyszinek_adatok';

  // Általános mentő függvény (Listát vár, és JSON stringet csinál belőle)
  static Future<void> mentes(String kulcs, List<dynamic> adatLista) async {
    final prefs = await SharedPreferences.getInstance();
    // A modelleket Map-pé kell alakítanunk (ezt majd a modellekben megírjuk)
    final jsonLista = adatLista.map((item) => item.toJson()).toList();
    final jsonString = jsonEncode(jsonLista);
    await prefs.setString(kulcs, jsonString);
  }

  // Általános betöltő függvény
  static Future<List<dynamic>> betoltes(String kulcs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(kulcs);
    
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return [];
  }

  // --- Kényelmi függvények a konkrét adatokhoz ---
  
  static Future<void> turakMentes(List<dynamic> turak) async {
    await mentes(_turakKulcs, turak);
  }

  static Future<void> fogasokMentes(List<dynamic> fogasok) async {
    await mentes(_fogasokKulcs, fogasok);
  }

  static Future<void> halfajokMentes(List<dynamic> halfajok) async {
    await mentes(_halfajokKulcs, halfajok);
  }

  static Future<void> helyszinekMentes(List<dynamic> helyszinek) async {
    await mentes(_helyszinekKulcs, helyszinek);
  }
}

