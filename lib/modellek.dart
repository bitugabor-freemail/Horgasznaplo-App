// lib/modellek.dart

class Helyszin {
  String id;
  String nev;

  Helyszin({required this.id, required this.nev});

  Map<String, dynamic> toJson() => {
    'id': id,
    'nev': nev,
  };

  factory Helyszin.fromJson(Map<String, dynamic> json) => Helyszin(
    id: json['id'],
    nev: json['nev'],
  );
}

class Halfaj {
  String id;
  String nev; // Ez az egyetlen kötelező!
  String kategoria;
  String altalanosMeret;
  String elvihetoMennyiseg;
  String meretKorlatozas;
  String tilalmiIdoszak;
  String elohely;
  String taplalek;
  String szabalyzatForras;
  List<String> kepek; // Ide mentjük a fotók útvonalát!

  Halfaj({
    required this.id,
    required this.nev,
    this.kategoria = 'Egyéb',
    this.altalanosMeret = '',
    this.elvihetoMennyiseg = '',
    this.meretKorlatozas = '',
    this.tilalmiIdoszak = '',
    this.elohely = '',
    this.taplalek = '',
    this.szabalyzatForras = '',
    this.kepek = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nev': nev,
    'kategoria': kategoria,
    'altalanosMeret': altalanosMeret,
    'elvihetoMennyiseg': elvihetoMennyiseg,
    'meretKorlatozas': meretKorlatozas,
    'tilalmiIdoszak': tilalmiIdoszak,
    'elohely': elohely,
    'taplalek': taplalek,
    'szabalyzatForras': szabalyzatForras,
    'kepek': kepek,
  };

  factory Halfaj.fromJson(Map<String, dynamic> json) => Halfaj(
    id: json['id'],
    nev: json['nev'],
    kategoria: json['kategoria'] ?? 'Egyéb',
    altalanosMeret: json['altalanosMeret'] ?? '',
    elvihetoMennyiseg: json['elvihetoMennyiseg'] ?? '',
    meretKorlatozas: json['meretKorlatozas'] ?? '',
    tilalmiIdoszak: json['tilalmiIdoszak'] ?? '',
    elohely: json['elohely'] ?? '',
    taplalek: json['taplalek'] ?? '',
    szabalyzatForras: json['szabalyzatForras'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
  );
}

class Tura {
  String id;
  String nev;
  String? helyszinId; // Kérésedre: NEM KÖTELEZŐ! (A kérdőjel miatt lehet null)
  DateTime datum;
  String megjegyzes;

  Tura({
    required this.id,
    required this.nev,
    this.helyszinId,
    required this.datum,
    this.megjegyzes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nev': nev,
    'helyszinId': helyszinId,
    'datum': datum.toIso8601String(),
    'megjegyzes': megjegyzes,
  };

  factory Tura.fromJson(Map<String, dynamic> json) => Tura(
    id: json['id'],
    nev: json['nev'],
    helyszinId: json['helyszinId'],
    datum: DateTime.parse(json['datum']),
    megjegyzes: json['megjegyzes'] ?? '',
  );
}
