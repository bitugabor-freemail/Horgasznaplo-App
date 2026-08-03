import 'package:flutter/material.dart';

void main() {
  runApp(const HorgaszApp());
}

class HorgaszApp extends StatelessWidget {
  const HorgaszApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horgásznapló 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Horgásznapló & Halhatározó'),
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phishing, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  'Horgásznapló App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A rendszer sikeresen felállt! Az alkalmazás felülete és funkciói készen állnak.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

