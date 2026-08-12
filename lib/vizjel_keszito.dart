import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'modellek.dart'; // Ide importáld a modelljeidet (Tura, Fogas stb.)

class VizjelKeszito {
  
  // --- FOGÁS MEGOSZTÁSA ---
  static Future<void> fogasMegosztasa(BuildContext context, Fogas fogas, String kepUtvonal) async {
    _mutasToltes(context);
    try {
      final textTopLeft = '${fogas.datum}\n${fogas.helyszin.isNotEmpty ? fogas.helyszin : ''}'.trim();
      
      String textTopRight = fogas.halfaj;
      List<String> parameterek = [];
      if (fogas.suly > 0) parameterek.add('${fogas.suly} kg');
      if (fogas.hossz > 0) parameterek.add('${fogas.hossz} cm');
      if (parameterek.isNotEmpty) {
        textTopRight += '\n${parameterek.join(' / ')}';
      }

      final file = await _kepGeneralasa(kepUtvonal, textTopLeft, textTopRight);
      
      if (context.mounted) Navigator.pop(context); // Töltés ablak bezárása
      await Share.shareXFiles([XFile(file.path)], text: 'Nézd meg ezt a fogásomat!');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _hibaUzenet(context, 'Hiba a kép generálásakor: $e');
    }
  }

  // --- TÚRA MEGOSZTÁSA ---
  static Future<void> turaMegosztasa(BuildContext context, Tura tura, String kepUtvonal) async {
    _mutasToltes(context);
    try {
      final textTopLeft = '${tura.kezdoDatum} - ${tura.zaroDatum}\n${tura.helyszin.isNotEmpty ? tura.helyszin : ''}'.trim();
      final textTopRight = ''; // Túránál ez üres marad

      final file = await _kepGeneralasa(kepUtvonal, textTopLeft, textTopRight);
      
      if (context.mounted) Navigator.pop(context);
      await Share.shareXFiles([XFile(file.path)], text: 'Horgásztúra emlék!');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _hibaUzenet(context, 'Hiba a kép generálásakor: $e');
    }
  }

  // --- KÖZÖS KÉPGENERÁLÓ MOTOR ---
  static Future<File> _kepGeneralasa(String alapKepUtvonal, String balFelsoszoveg, String jobbFelsoSzoveg) async {
    // 1. Alapkép betöltése
    final Uint8List imageBytes = await File(alapKepUtvonal).readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image alapKep = frameInfo.image;

    // 2. Vízjel logó betöltése (az új megadott fájlból!)
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

    // Alap méretek és margók kiszámítása a képfelbontás alapján
    final double padding = alapKep.width * 0.04; 
    final double fontSize = alapKep.width * 0.05; // Dinamikus betűméret (5%)

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

    // JOBB FELSŐ szöveg megrajzolása
    if (jobbFelsoSzoveg.isNotEmpty) {
      final ui.ParagraphBuilder jobbBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right))
        ..pushStyle(textStyle)
        ..addText(jobbFelsoSzoveg);
      final ui.Paragraph jobbParagraph = jobbBuilder.build();
      jobbParagraph.layout(ui.ParagraphConstraints(width: alapKep.width - (padding * 2)));
      canvas.drawParagraph(jobbParagraph, Offset(alapKep.width - jobbParagraph.maxIntrinsicWidth - padding, padding));
    }

    // LOGÓ megrajzolása (Jobb alsó sarok, áttetszően)
    // A logó méretét a kép szélességének 20%-ára skálázzuk
    final double logoTargetWidth = alapKep.width * 0.20;
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

    // 4. Kép kimentése
    final ui.Picture picture = recorder.endRecording();
    final ui.Image veglegesKep = await picture.toImage(alapKep.width, alapKep.height);
    final ByteData? byteData = await veglegesKep.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Temp mappába írás a megosztáshoz
    final directory = await getTemporaryDirectory();
    final File tempFile = File('${directory.path}/megosztas_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(pngBytes);

    return tempFile;
  }

  static void _mutasToltes(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );
  }

  static void _hibaUzenet(BuildContext context, String uzenet) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uzenet), backgroundColor: Colors.red));
  }
}
