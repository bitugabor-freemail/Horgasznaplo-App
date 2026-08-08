class Tura {
  final String id;
  final DateTime kezdoDatum;
  final DateTime befejezoDatum;
  final String? helyszinId;
  final String horgaszhely;
  final List<String> horgasztarsak;
  final String? boritoKep;
  final String megjegyzes;

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

class FogasModel {
  final String id;
  final String turaId;
  final DateTime datum;
  final String idopont;
  final String halfaj;
  final double? suly;
  final double? hossz;
  final String? halSorsa;
  final List<String> csali;
  final List<String> etetoanyag;
  final int? etetesGyakorisaga;
  final String? bot;
  final String? horgaszmodszer;
  final String? vegszerelek;
  final String? idojaras;
  final double? homerseklet;
  final String? fenykep;
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
    this.halSorsa,
    this.csali = const [],
    this.etetoanyag = const [],
    this.etetesGyakorisaga,
    this.bot,
    this.horgaszmodszer,
    this.vegszerelek,
    this.idojaras,
    this.homerseklet,
    this.fenykep,
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
    'halSorsa': halSorsa,
    'csali': csali,
    'etetoanyag': etetoanyag,
    'etetesGyakorisaga': etetesGyakorisaga,
    'bot': bot,
    'horgaszmodszer': horgaszmodszer,
    'vegszerelek': vegszerelek,
    'idojaras': idojaras,
    'homerseklet': homerseklet,
    'fenykep': fenykep,
    'megjegyzes': megjegyzes,
    'isKedvenc': isKedvenc,
  };

  factory FogasModel.fromJson(Map<String, dynamic> json) => FogasModel(
    id: json['id'],
    turaId: json['turaId'],
    datum: DateTime.parse(json['datum']),
    idopont: json['idopont'] ?? '00:00',
    halfaj: json['halfaj'],
    suly: json['suly']?.toDouble(),
    hossz: json['hossz']?.toDouble(),
    halSorsa: json['halSorsa'],
    csali: List<String>.from(json['csali'] ?? []),
    etetoanyag: List<String>.from(json['etetoanyag'] ?? []),
    etetesGyakorisaga: json['etetesGyakorisaga'],
    bot: json['bot'],
    horgaszmodszer: json['horgaszmodszer'],
    vegszerelek: json['vegszerelek'],
    idojaras: json['idojaras'],
    homerseklet: json['homerseklet']?.toDouble(),
    fenykep: json['fenykep'],
    megjegyzes: json['megjegyzes'] ?? '',
    isKedvenc: json['isKedvenc'] ?? false,
  );
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
