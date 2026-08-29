import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'modellek.dart'; 

class VizjelKeszito {
  
  // --- FOGÁS LETÖLTÉSE ---
  static Future<void> fogasLetoltes(BuildContext context, FogasModel fogas, String kepUtvonal, String helyszinNev) async {
    _mutasToltes(context);
    try {
      // ÚJ ELRENDEZÉS: Helyszín felül, dátum alatta
      String formazottDatum = DateFormat('yyyy.MM.dd.').format(fogas.datum);
      final String hely = helyszinNev != 'Ismeretlen helyszín' ? '$helyszinNev\n' : '';
      final textTopLeft = '$hely$formazottDatum'.trim();
      
      // ÚJ ELRENDEZÉS: Súly/Hossz felül, halfaj alatta
      List<String> parameterek = [];
      if (fogas.suly != null && fogas.suly! > 0) parameterek.add('${fogas.suly} kg');
      if (fogas.hossz != null && fogas.hossz! > 0) parameterek.add('${fogas.hossz} cm');
      
      String textBottomLeft = '';
      if (parameterek.isNotEmpty) {
        textBottomLeft += '${parameterek.join(' / ')}\n';
      }
      textBottomLeft += fogas.halfaj;

      final letoltottFajlNev = await _kepGeneralasaEsMentese(kepUtvonal, textTopLeft, textBottomLeft, 'fogas');
      
      if (context.mounted) {
        Navigator.pop(context); // Töltés ablak bezárása
        _sikerUzenet(context, 'Kép sikeresen mentve a Letöltések közé!\n($letoltottFajlNev)');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _hibaUzenet(context, 'Hiba a kép generálásakor: $e');
      }
    }
  }

  // --- TÚRA LETÖLTÉSE ---
  static Future<void> turaLetoltes(BuildContext context, Tura tura, String kepUtvonal, String helyszinNev) async {
    _mutasToltes(context);
    try {
      String kezd = DateFormat('yyyy.MM.dd.').format(tura.kezdoDatum);
      String veg = DateFormat('yyyy.MM.dd.').format(tura.befejezoDatum);
      final textTopLeft = '${helyszinNev != 'Ismeretlen helyszín' ? helyszinNev + '\n' : ''}$kezd - $veg'.trim();
      const textBottomLeft = ''; // Túránál ez üres marad

      final letoltottFajlNev = await _kepGeneralasaEsMentese(kepUtvonal, textTopLeft, textBottomLeft, 'tura');
      
      if (context.mounted) {
        Navigator.pop(context);
        _sikerUzenet(context, 'Kép sikeresen mentve a Letöltések közé!\n($letoltottFajlNev)');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _hibaUzenet(context, 'Hiba a kép generálásakor: $e');
      }
    }
  }

  // --- KÖZÖS KÉPGENERÁLÓ ÉS MENTŐ MOTOR ---
  static Future<String> _kepGeneralasaEsMentese(String alapKepUtvonal, String balFelsoszoveg, String balAlsoSzoveg, String tipus) async {
    // 1. Alapkép betöltése
    final Uint8List imageBytes = await File(alapKepUtvonal).readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image alapKep = frameInfo.image;

    // 2. Vízjel logó betöltése (Ellenőrizd a pubspec.yaml-t!)
    final ByteData logoData = await rootBundle.load('assets/watermark_logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final ui.Codec logoCodec = await ui.instantiateImageCodec(logoBytes);
    final ui.FrameInfo logoFrame = await logoCodec.getNextFrame();
    final ui.Image logoKep = logoFrame.image;

    // 3. Vászon (Canvas) előkészítése
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // Alapkép kirajzolása
    canvas.drawImage(alapKep, Offset.zero, Paint());

    // Alap méretek és margók kiszámítása a képfelbontás alapján (2/3-ra csökkentve az eddigihez képest)
    final double padding = alapKep.width * 0.03; 
    final double fontSize = alapKep.width * 0.033; 

    // Szöveg stílusának beállítása (Hófehér, vastag, sötét drop-shadow-val)
    final ui.TextStyle textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: [
        const Shadow(color: Colors.black87, blurRadius: 8.0, offset: Offset(2.0, 2.0)),
        const Shadow(color: Colors.black87, blurRadius: 4.0, offset: Offset(-1.0, -1.0)),
      ],
    );

    // BAL FELSŐ szöveg megrajzolása
    if (balFelsoszoveg.isNotEmpty) {
      final ui.ParagraphBuilder balBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.left))
        ..pushStyle(textStyle)
        ..addText(balFelsoszoveg);
      final ui.Paragraph balParagraph = balBuilder.build();
      balParagraph.layout(ui.ParagraphConstraints(width: alapKep.width - (padding * 2)));
      canvas.drawParagraph(balParagraph, Offset(padding, padding));
    }

    // BAL ALSÓ szöveg megrajzolása
    if (balAlsoSzoveg.isNotEmpty) {
      final ui.ParagraphBuilder balAlsoBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.left))
        ..pushStyle(textStyle)
        ..addText(balAlsoSzoveg);
      final ui.Paragraph balAlsoParagraph = balAlsoBuilder.build();
      balAlsoParagraph.layout(ui.ParagraphConstraints(width: alapKep.width - (padding * 2)));
      
      // Kiszámoljuk az y pozíciót, hogy a kép aljára kerüljön a margó figyelembevételével
      final double yPozicio = alapKep.height - balAlsoParagraph.height - padding;
      canvas.drawParagraph(balAlsoParagraph, Offset(padding, yPozicio));
    }

    // LOGÓ megrajzolása (Jobb alsó sarok, áttetszően - méret 2/3-ra csökkentve)
    final double logoTargetWidth = alapKep.width * 0.133;
    final double logoScale = logoTargetWidth / logoKep.width;
    final double logoTargetHeight = logoKep.height * logoScale;
    
    final Paint logoPaint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.7); // 70% átlátszatlanság
    
    canvas.save();
    canvas.translate(
      alapKep.width - logoTargetWidth - padding, 
      alapKep.height - logoTargetHeight - padding
    );
    canvas.scale(logoScale, logoScale);
    canvas.drawImage(logoKep, Offset.zero, logoPaint);
    canvas.restore();

    // 4. Kép generálása memóriába
    final ui.Picture picture = recorder.endRecording();
    final ui.Image veglegesKep = await picture.toImage(alapKep.width, alapKep.height);
    final ByteData? byteData = await veglegesKep.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // 5. MENTÉS A LETÖLTÉSEK (Download) KÖNYVTÁRBA
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getApplicationDocumentsDirectory(); 
    }
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    // ÚJ NÉVFORMÁTUM A VÍZJELES KÉPEKHEZ IS
    final String idobelyeg = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
    final fajlNev = 'horgasznaplo_${tipus}_$idobelyeg.png';
    
    final newPath = '${downloadsDir.path}/$fajlNev';
    
    await File(newPath).writeAsBytes(pngBytes);

    return fajlNev; // Visszaadjuk a fájl nevét a sikerüzenethez
  }

  static void _mutasToltes(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );
  }

  static void _hibaUzenet(BuildContext context, String uzenet) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uzenet), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)));
  }

  static void _sikerUzenet(BuildContext context, String uzenet) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uzenet), backgroundColor: Colors.green[700], duration: const Duration(seconds: 4)));
  }
}
