import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class IdojarasSzolgaltato {
  // Ide kell majd beilleszteni az ingyenes OpenWeatherMap API kulcsodat
  static const String _apiKey = '53806ac9c451601b112061b1c699fc0f';

  static Future<double?> getAktualisHomerseklet() async {
    try {
      // 1. Ellenőrizzük, hogy be van-e kapcsolva a GPS a telefonon
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null; // GPS ki van kapcsolva
      }

      // 2. Engedélyek ellenőrzése és kérése
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null; // Felhasználó elutasította az engedélyt
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null; // Véglegesen elutasítva
      }

      // 3. Jelenlegi koordináták lekérése (magas pontossággal)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 4. Időjárás lekérése a koordináták alapján (metric = Celsius fok)
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['main']['temp'].toDouble();
      } else {
        return null; // Hiba a hálózatban vagy rossz kulcs
      }
    } catch (e) {
      print('Hiba a hőmérséklet lekérésekor: $e');
      return null;
    }
  }
}
