import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class IdojarasSzolgaltato {
  static const String _apiKey = '53806ac9c451601b112061b1c699fc0f';

  static Future<double?> getAktualisHomerseklet() async {
    try {
      // 1. Ellenőrizzük, hogy be van-e kapcsolva a GPS a telefonon
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 2. Engedélyek ellenőrzése és kérése
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null; 
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null; 
      }

      // 3. Gyors lekérés: megpróbáljuk a legutolsó ismert helyzetet használni
      Position? position = await Geolocator.getLastKnownPosition();

      // Ha nincs korábbi ismert helyzet, kérünk egy újat, de 10 másodperces időkorláttal!
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Időjárás lekérése
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey'
      );
      
      // Időkorlátot teszünk a hálózati kérésre is
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['main']['temp'].toDouble();
      } else {
        return null;
      }
    } catch (e) {
      print('Hiba a hőmérséklet lekérésekor: $e');
      return null;
    }
  }
}
