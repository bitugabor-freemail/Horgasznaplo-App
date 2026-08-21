class Tura {
  final String id;
  final DateTime kezdoDatum;
  final DateTime befejezoDatum;
  final String? helyszinId;
  final String horgaszhely;
  final List<String> horgasztarsak;
  final String? boritoKep;
  final List<String> kepek; // ÚJ: Túra galéria képei
  final String megjegyzes;

  Tura({
    required this.id,
    required this.kezdoDatum,
    required this.befejezoDatum,
    this.helyszinId,
    this.horgaszhely = '',
    this.horgasztarsak = const [],
    this.boritoKep,
    this.kepek = const [], // ÚJ
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
    'kepek': kepek, // ÚJ
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
    kepek: List<String>.from(json['kepek'] ?? []), // ÚJ (Visszafelé kompatibilis)
    megjegyzes: json['megjegyzes'] ?? '',
  );
}

class FogasModel {
  final String id;
  final String turaId;
  final DateTime datum;
  final String idopont;
  final String halfaj;
  final double? suly;
  final double? hossz;
  final String? sors;
  final List<String> csali;
  final List<String> etetoanyag;
  final int? etetesGyakorisaga;
  final String? bot;
  final String? modszer;
  final String? vegszerelek;
  final String? idojaras;
  final double? homerseklet;
  final String? fenykep; 
  final List<String> kepek; // ÚJ: Fogás galéria képei
  final String megjegyzes;
  bool isKedvenc;

  FogasModel({
    required this.id,
    required this.turaId,
    required this.datum,
    required this.idopont,
    required this.halfaj,
    this.suly,
    this.hossz,
    this.sors,
    this.csali = const [],
    this.etetoanyag = const [],
    this.etetesGyakorisaga,
    this.bot,
    this.modszer,
    this.vegszerelek,
    this.idojaras,
    this.homerseklet,
    this.fenykep,
    this.kepek = const [], // ÚJ
    this.megjegyzes = '',
    this.isKedvenc = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'turaId': turaId,
    'datum': datum.toIso8601String(),
    'idopont': idopont,
    'halfaj': halfaj,
    'suly': suly,
    'hossz': hossz,
    'sors': sors,
    'csali': csali,
    'etetoanyag': etetoanyag,
    'etetesGyakorisaga': etetesGyakorisaga,
    'bot': bot,
    'modszer': modszer,
    'vegszerelek': vegszerelek,
    'idojaras': idojaras,
    'homerseklet': homerseklet,
    'fenykep': fenykep,
    'kepek': kepek, // ÚJ
    'megjegyzes': megjegyzes,
    'isKedvenc': isKedvenc,
  };

  factory FogasModel.fromJson(Map<String, dynamic> json) {
    // VISSZAFELÉ KOMPATIBILITÁS LOGIKA: Ha van régi 'fenykep', de nincs 'kepek' lista, akkor konvertáljuk.
    List<String> betoltottKepek = List<String>.from(json['kepek'] ?? []);
    if (betoltottKepek.isEmpty && json['fenykep'] != null && json['fenykep'].toString().isNotEmpty) {
      betoltottKepek.add(json['fenykep']);
    }

    return FogasModel(
      id: json['id'],
      turaId: json['turaId'],
      datum: DateTime.parse(json['datum']),
      idopont: json['idopont'] ?? '00:00',
      halfaj: json['halfaj'],
      suly: json['suly']?.toDouble(),
      hossz: json['hossz']?.toDouble(),
      sors: json['sors'],
      csali: List<String>.from(json['csali'] ?? []),
      etetoanyag: List<String>.from(json['etetoanyag'] ?? []),
      etetesGyakorisaga: json['etetesGyakorisaga'],
      bot: json['bot'],
      modszer: json['modszer'],
      vegszerelek: json['vegszerelek'],
      idojaras: json['idojaras'],
      homerseklet: json['homerseklet']?.toDouble(),
      fenykep: json['fenykep'], // Megtartjuk a biztonság kedvéért
      kepek: betoltottKepek, // ÚJ (Okos betöltés)
      megjegyzes: json['megjegyzes'] ?? '',
      isKedvenc: json['isKedvenc'] ?? false,
    );
  }
}

class Helyszin {
  final String id;
  final String nev;
  final String vizterKod;

  Helyszin({
    required this.id,
    required this.nev,
    this.vizterKod = '',
  });

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

class Halfaj {
  final String id;
  final String nev;
  final String kategoria;
  final String statusz;
  final String meretKorlatozas;
  final String darabKorlatozas;
  final String tilalmiIdoszak;
  final String szabalyozasEve;
  final String megjegyzes;
  final List<String> kepek;

  Halfaj({
    required this.id,
    required this.nev,
    this.kategoria = '',
    this.statusz = '',
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
    kategoria: json['kategoria'] ?? '',
    statusz: json['statusz'] ?? '',
    meretKorlatozas: json['meretKorlatozas'] ?? '',
    darabKorlatozas: json['darabKorlatozas'] ?? '',
    tilalmiIdoszak: json['tilalmiIdoszak'] ?? '',
    szabalyozasEve: json['szabalyozasEve'] ?? '',
    megjegyzes: json['megjegyzes'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
  );
}

class FelszerelesKategoria {
  final String id;
  final String nev;
  int sorrend;

  FelszerelesKategoria({
    required this.id,
    required this.nev,
    this.sorrend = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nev': nev,
    'sorrend': sorrend,
  };

  factory FelszerelesKategoria.fromJson(Map<String, dynamic> json) => FelszerelesKategoria(
    id: json['id'],
    nev: json['nev'],
    sorrend: json['sorrend'] ?? 0,
  );
}

class FelszerelesTetel {
  final String id;
  final String kategoriaId;
  final String marka; 
  final String nev;
  final String jellemzo;
  final double? mennyiseg;
  final String mertekegyseg;
  final String leiras;
  final List<String> kepek;
  final String? taska; // ÚJ
  final String? pozicio; // ÚJ

  FelszerelesTetel({
    required this.id,
    required this.kategoriaId,
    this.marka = '',
    required this.nev,
    this.jellemzo = '',
    this.mennyiseg,
    this.mertekegyseg = '',
    this.leiras = '',
    this.kepek = const [],
    this.taska, // ÚJ
    this.pozicio, // ÚJ
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kategoriaId': kategoriaId,
    'marka': marka,
    'nev': nev,
    'jellemzo': jellemzo,
    'mennyiseg': mennyiseg,
    'mertekegyseg': mertekegyseg,
    'leiras': leiras,
    'kepek': kepek,
    'taska': taska, // ÚJ
    'pozicio': pozicio, // ÚJ
  };

  factory FelszerelesTetel.fromJson(Map<String, dynamic> json) => FelszerelesTetel(
    id: json['id'],
    kategoriaId: json['kategoriaId'],
    marka: json['marka'] ?? '',
    nev: json['nev'],
    jellemzo: json['jellemzo'] ?? '',
    mennyiseg: json['mennyiseg']?.toDouble(),
    mertekegyseg: json['mertekegyseg'] ?? '',
    leiras: json['leiras'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
    taska: json['taska'], // ÚJ
    pozicio: json['pozicio'], // ÚJ
  );
}

// --- ÚJ DOKUMENTUM MODELLEK ---

class DokumentumMappa {
  String id;
  String nev;

  DokumentumMappa({required this.id, required this.nev});

  Map<String, dynamic> toJson() => {'id': id, 'nev': nev};
  factory DokumentumMappa.fromJson(Map<String, dynamic> json) => 
      DokumentumMappa(id: json['id'], nev: json['nev']);
}

class DokumentumFajl {
  String id;
  String mappaId;
  String nev;
  String utvonal;

  DokumentumFajl({required this.id, required this.mappaId, required this.nev, required this.utvonal});

  Map<String, dynamic> toJson() => {'id': id, 'mappaId': mappaId, 'nev': nev, 'utvonal': utvonal};
  factory DokumentumFajl.fromJson(Map<String, dynamic> json) => 
      DokumentumFajl(id: json['id'], mappaId: json['mappaId'], nev: json['nev'], utvonal: json['utvonal']);
}
