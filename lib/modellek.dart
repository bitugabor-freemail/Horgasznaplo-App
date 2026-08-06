// lib/modellek.dart

// --- 1. HELYSZÍN (Törzsadat) ---
class Helyszin {
  String id;
  String nev;
  String vizterKod; // Új mező

  Helyszin({required this.id, required this.nev, this.vizterKod = ''});

  Map<String, dynamic> toJson() => {
    'id': id,
    'nev': nev,
    'vizterKod': vizterKod,
  };

  factory Helyszin.fromJson(Map<String, dynamic> json) => Helyszin(
    id: json['id'],
    nev: json['nev'],
    vizterKod: json['vizterKod'] ?? '',
  );
}

// --- 2. HALFAJ (Törzsadat és Lexikon) ---
class Halfaj {
  String id;
  String nev;
  String kategoria; // Békés vagy Ragadozó
  String statusz; // Fogható, Védett, Inváziós, Nem fogható
  String meretKorlatozas;
  String darabKorlatozas; // Új mező
  String tilalmiIdoszak;
  String szabalyozasEve; // Új mező
  String megjegyzes; // Élőhely, táplálék, stb.
  List<String> kepek;

  Halfaj({
    required this.id,
    required this.nev,
    this.kategoria = 'Békés',
    this.statusz = 'Fogható',
    this.meretKorlatozas = '',
    this.darabKorlatozas = '',
    this.tilalmiIdoszak = '',
    this.szabalyozasEve = '',
    this.megjegyzes = '',
    this.kepek = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nev': nev,
    'kategoria': kategoria,
    'statusz': statusz,
    'meretKorlatozas': meretKorlatozas,
    'darabKorlatozas': darabKorlatozas,
    'tilalmiIdoszak': tilalmiIdoszak,
    'szabalyozasEve': szabalyozasEve,
    'megjegyzes': megjegyzes,
    'kepek': kepek,
  };

  factory Halfaj.fromJson(Map<String, dynamic> json) => Halfaj(
    id: json['id'],
    nev: json['nev'],
    kategoria: json['kategoria'] ?? 'Békés',
    statusz: json['statusz'] ?? 'Fogható',
    meretKorlatozas: json['meretKorlatozas'] ?? '',
    darabKorlatozas: json['darabKorlatozas'] ?? '',
    tilalmiIdoszak: json['tilalmiIdoszak'] ?? '',
    szabalyozasEve: json['szabalyozasEve'] ?? '',
    megjegyzes: json['megjegyzes'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
  );
}

// --- 3. TÚRA ---
class Tura {
  String id;
  DateTime kezdoDatum; // Új: Csak ez és a befejező kötelező
  DateTime befejezoDatum;
  String? helyszinId; // Opcionális
  String horgaszhely;
  List<String> horgasztarsak; // Törzsadatból, több is lehet
  String? boritoKep;
  String megjegyzes;

  Tura({
    required this.id,
    required this.kezdoDatum,
    required this.befejezoDatum,
    this.helyszinId,
    this.horgaszhely = '',
    this.horgasztarsak = const [],
    this.boritoKep,
    this.megjegyzes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kezdoDatum': kezdoDatum.toIso8601String(),
    'befejezoDatum': befejezoDatum.toIso8601String(),
    'helyszinId': helyszinId,
    'horgaszhely': horgaszhely,
    'horgasztarsak': horgasztarsak,
    'boritoKep': boritoKep,
    'megjegyzes': megjegyzes,
  };

  factory Tura.fromJson(Map<String, dynamic> json) => Tura(
    id: json['id'],
    kezdoDatum: DateTime.parse(json['kezdoDatum']),
    befejezoDatum: DateTime.parse(json['befejezoDatum']),
    helyszinId: json['helyszinId'],
    horgaszhely: json['horgaszhely'] ?? '',
    horgasztarsak: List<String>.from(json['horgasztarsak'] ?? []),
    boritoKep: json['boritoKep'],
    megjegyzes: json['megjegyzes'] ?? '',
  );
}

// --- 4. FOGÁS ---
class FogasModel {
  String id;
  String turaId;
  DateTime datum;
  // A TimeOfDay-t manuálisan Stringbe mentjük és olvassuk, mert a JSON nem ismeri
  String idopontString; 
  String halfaj; // Kötelező
  double? suly; // Mostantól opcionális
  int? hossz; // Mostantól opcionális
  String sors; // Alap: Visszaengedtem
  List<String> csali;
  List<String> etetoanyag;
  String etetesGyakorisag;
  String bot;
  String modszer;
  String szerelek;
  String idojaras;
  String homerseklet;
  String? kepUtvonal;
  String megjegyzes;
  bool isKedvenc;

  FogasModel({
    required this.id,
    required this.turaId,
    required this.datum,
    required this.idopontString,
    required this.halfaj,
    this.suly,
    this.hossz,
    this.sors = 'Visszaengedtem',
    this.csali = const [],
    this.etetoanyag = const [],
    this.etetesGyakorisag = '',
    this.bot = '',
    this.modszer = '',
    this.szerelek = '',
    this.idojaras = '',
    this.homerseklet = '',
    this.kepUtvonal,
    this.megjegyzes = '',
    this.isKedvenc = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'turaId': turaId,
    'datum': datum.toIso8601String(),
    'idopontString': idopontString,
    'halfaj': halfaj,
    'suly': suly,
    'hossz': hossz,
    'sors': sors,
    'csali': csali,
    'etetoanyag': etetoanyag,
    'etetesGyakorisag': etetesGyakorisag,
    'bot': bot,
    'modszer': modszer,
    'szerelek': szerelek,
    'idojaras': idojaras,
    'homerseklet': homerseklet,
    'kepUtvonal': kepUtvonal,
    'megjegyzes': megjegyzes,
    'isKedvenc': isKedvenc,
  };

  factory FogasModel.fromJson(Map<String, dynamic> json) => FogasModel(
    id: json['id'],
    turaId: json['turaId'],
    datum: DateTime.parse(json['datum']),
    idopontString: json['idopontString'],
    halfaj: json['halfaj'],
    suly: json['suly']?.toDouble(),
    hossz: json['hossz']?.toInt(),
    sors: json['sors'] ?? 'Visszaengedtem',
    csali: List<String>.from(json['csali'] ?? []),
    etetoanyag: List<String>.from(json['etetoanyag'] ?? []),
    etetesGyakorisag: json['etetesGyakorisag'] ?? '',
    bot: json['bot'] ?? '',
    modszer: json['modszer'] ?? '',
    szerelek: json['szerelek'] ?? '',
    idojaras: json['idojaras'] ?? '',
    homerseklet: json['homerseklet'] ?? '',
    kepUtvonal: json['kepUtvonal'],
    megjegyzes: json['megjegyzes'] ?? '',
    isKedvenc: json['isKedvenc'] ?? false,
  );
}
