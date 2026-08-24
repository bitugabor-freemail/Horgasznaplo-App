class Tura {
  final String id;
  final DateTime kezdoDatum;
  final DateTime befejezoDatum;
  final String? helyszinId;
  final String horgaszhely;
  final List<String> horgasztarsak;
  final String? boritoKep;
  final List<String> kepek; 
  final String megjegyzes;

  Tura({
    required this.id,
    required this.kezdoDatum,
    required this.befejezoDatum,
    this.helyszinId,
    this.horgaszhely = '',
    this.horgasztarsak = const [],
    this.boritoKep,
    this.kepek = const [], 
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
    'kepek': kepek, 
    'megjegyzes': megjegyzes,
  };

  factory Tura.fromJson(Map<String, dynamic> json) {
    List<String> betoltottKepek = List<String>.from(json['kepek'] ?? []);
    if (betoltottKepek.isEmpty && json['boritoKep'] != null && json['boritoKep'].toString().isNotEmpty) {
      betoltottKepek.add(json['boritoKep']);
    }

    return Tura(
      id: json['id'],
      kezdoDatum: DateTime.parse(json['kezdoDatum']),
      befejezoDatum: DateTime.parse(json['befejezoDatum']),
      helyszinId: json['helyszinId'],
      horgaszhely: json['horgaszhely'] ?? '',
      horgasztarsak: List<String>.from(json['horgasztarsak'] ?? []),
      boritoKep: json['boritoKep'],
      kepek: betoltottKepek,
      megjegyzes: json['megjegyzes'] ?? '',
    );
  }
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
  final List<String> kepek; 
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
    this.kepek = const [], 
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
    'kepek': kepek, 
    'megjegyzes': megjegyzes,
    'isKedvenc': isKedvenc,
  };

  factory FogasModel.fromJson(Map<String, dynamic> json) {
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
      fenykep: json['fenykep'], 
      kepek: betoltottKepek, 
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

// --- ÚJ OSZTÁLYOK A FELSZERELÉSHEZ ---

class FelszerelesElhelyezes {
  String? taska;
  String? pozicio;
  double? mennyiseg;

  FelszerelesElhelyezes({this.taska, this.pozicio, this.mennyiseg});

  Map<String, dynamic> toJson() => {
    'taska': taska,
    'pozicio': pozicio,
    'mennyiseg': mennyiseg,
  };

  factory FelszerelesElhelyezes.fromJson(Map<String, dynamic> json) {
    return FelszerelesElhelyezes(
      taska: json['taska'],
      pozicio: json['pozicio'],
      mennyiseg: json['mennyiseg']?.toDouble(),
    );
  }
}

class FelszerelesTetel {
  final String id;
  final String kategoriaId;
  final String marka;
  final String nev;
  final String jellemzo;
  final String mertekegyseg;
  final String leiras;
  final List<String> kepek;
  final List<FelszerelesElhelyezes> elhelyezesek;

  // --- VISSZAFELÉ KOMPATIBILITÁS MÁS KÉPERNYŐKNEK ---
  // Ezek a "get" függvények megvédik a többi fájlt a hibáktól.
  double? get mennyiseg {
    if (elhelyezesek.isEmpty) return null;
    double sum = 0;
    bool hasValue = false;
    for (var e in elhelyezesek) {
      if (e.mennyiseg != null) {
        sum += e.mennyiseg!;
        hasValue = true;
      }
    }
    return hasValue ? sum : null;
  }

  String? get taska => elhelyezesek.isNotEmpty ? elhelyezesek.first.taska : null;
  String? get pozicio => elhelyezesek.isNotEmpty ? elhelyezesek.first.pozicio : null;

  FelszerelesTetel({
    required this.id,
    required this.kategoriaId,
    this.marka = '',
    required this.nev,
    this.jellemzo = '',
    this.mertekegyseg = '',
    this.leiras = '',
    this.kepek = const [],
    this.elhelyezesek = const [],
  });

  factory FelszerelesTetel.fromJson(Map<String, dynamic> json) {
    List<FelszerelesElhelyezes> helyek = [];

    if (json['elhelyezesek'] != null) {
      helyek = (json['elhelyezesek'] as List).map((e) => FelszerelesElhelyezes.fromJson(e)).toList();
    } else if (json['taska'] != null || json['pozicio'] != null || json['mennyiseg'] != null) {
      // Ha régi adatot talál, csinál belőle egy új listát!
      helyek.add(FelszerelesElhelyezes(
        taska: json['taska'],
        pozicio: json['pozicio'],
        mennyiseg: json['mennyiseg']?.toDouble(),
      ));
    }

    return FelszerelesTetel(
      id: json['id'] ?? '',
      kategoriaId: json['kategoriaId'] ?? '',
      marka: json['marka'] ?? '',
      nev: json['nev'] ?? '',
      jellemzo: json['jellemzo'] ?? '',
      mertekegyseg: json['mertekegyseg'] ?? '',
      leiras: json['leiras'] ?? '',
      kepek: json['kepek'] != null ? List<String>.from(json['kepek']) : [],
      elhelyezesek: helyek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kategoriaId': kategoriaId,
      'marka': marka,
      'nev': nev,
      'jellemzo': jellemzo,
      'mertekegyseg': mertekegyseg,
      'leiras': leiras,
      'kepek': kepek,
      'elhelyezesek': elhelyezesek.map((e) => e.toJson()).toList(),
      // Mentsük el a régi adatokat is biztonsági okokból:
      'mennyiseg': mennyiseg,
      'taska': taska,
      'pozicio': pozicio,
    };
  }
}
