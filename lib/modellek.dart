class Tura {
  String id;
  String datum;
  String helyszin;
  String idojaras;
  String megjegyzes;
  List<String> kepek;
  String? indexKep; // ÚJ: Egyedi indexkép a túrához

  Tura({
    required this.id,
    required this.datum,
    required this.helyszin,
    required this.idojaras,
    required this.megjegyzes,
    required this.kepek,
    this.indexKep,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'datum': datum,
    'helyszin': helyszin,
    'idojaras': idojaras,
    'megjegyzes': megjegyzes,
    'kepek': kepek,
    'indexKep': indexKep,
  };

  factory Tura.fromJson(Map<String, dynamic> json) => Tura(
    id: json['id'] ?? '',
    datum: json['datum'] ?? '',
    helyszin: json['helyszin'] ?? '',
    idojaras: json['idojaras'] ?? '',
    megjegyzes: json['megjegyzes'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
    indexKep: json['indexKep'],
  );
}

class FogasModel {
  String id;
  String turaId;
  String halfaj;
  double suly;
  double hossz;
  String sors;
  String megjegyzes;
  List<String> kepek;
  String? indexKep; // ÚJ

  FogasModel({
    required this.id,
    required this.turaId,
    required this.halfaj,
    required this.suly,
    required this.hossz,
    required this.sors,
    required this.megjegyzes,
    required this.kepek,
    this.indexKep,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'turaId': turaId,
    'halfaj': halfaj,
    'suly': suly,
    'hossz': hossz,
    'sors': sors,
    'megjegyzes': megjegyzes,
    'kepek': kepek,
    'indexKep': indexKep,
  };

  factory FogasModel.fromJson(Map<String, dynamic> json) => FogasModel(
    id: json['id'] ?? '',
    turaId: json['turaId'] ?? '',
    halfaj: json['halfaj'] ?? '',
    suly: (json['suly'] ?? 0).toDouble(),
    hossz: (json['hossz'] ?? 0).toDouble(),
    sors: json['sors'] ?? '',
    megjegyzes: json['megjegyzes'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
    indexKep: json['indexKep'],
  );
}

class Halfaj {
  String id;
  String nev;
  String kategoria;
  String statusz;
  String meretKorlatozas;
  String darabKorlatozas;
  String tilalmiIdoszak;
  String szabalyozasEve;
  String megjegyzes;
  List<String> kepek;
  String? indexKep; // ÚJ

  Halfaj({
    required this.id,
    required this.nev,
    required this.kategoria,
    required this.statusz,
    required this.meretKorlatozas,
    required this.darabKorlatozas,
    required this.tilalmiIdoszak,
    required this.szabalyozasEve,
    required this.megjegyzes,
    required this.kepek,
    this.indexKep,
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
    'indexKep': indexKep,
  };

  factory Halfaj.fromJson(Map<String, dynamic> json) => Halfaj(
    id: json['id'] ?? '',
    nev: json['nev'] ?? '',
    kategoria: json['kategoria'] ?? '',
    statusz: json['statusz'] ?? '',
    meretKorlatozas: json['meretKorlatozas'] ?? '',
    darabKorlatozas: json['darabKorlatozas'] ?? '',
    tilalmiIdoszak: json['tilalmiIdoszak'] ?? '',
    szabalyozasEve: json['szabalyozasEve'] ?? '',
    megjegyzes: json['megjegyzes'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
    indexKep: json['indexKep'],
  );
}

class FelszerelesKategoria {
  String id;
  String nev;
  int sorrend;

  FelszerelesKategoria({required this.id, required this.nev, required this.sorrend});

  Map<String, dynamic> toJson() => {'id': id, 'nev': nev, 'sorrend': sorrend};

  factory FelszerelesKategoria.fromJson(Map<String, dynamic> json) => FelszerelesKategoria(
    id: json['id'] ?? '',
    nev: json['nev'] ?? '',
    sorrend: json['sorrend'] ?? 0,
  );
}

class FelszerelesElhelyezes {
  String? taska;
  String? pozicio;
  double? mennyiseg;

  FelszerelesElhelyezes({this.taska, this.pozicio, this.mennyiseg});

  Map<String, dynamic> toJson() => {'taska': taska, 'pozicio': pozicio, 'mennyiseg': mennyiseg};

  factory FelszerelesElhelyezes.fromJson(Map<String, dynamic> json) => FelszerelesElhelyezes(
    taska: json['taska'],
    pozicio: json['pozicio'],
    mennyiseg: json['mennyiseg'] != null ? (json['mennyiseg'] as num).toDouble() : null,
  );
}

class FelszerelesTetel {
  String id;
  String kategoriaId;
  String marka;
  String nev;
  String jellemzo;
  String mertekegyseg;
  String leiras;
  List<String> kepek;
  List<FelszerelesElhelyezes> elhelyezesek;
  String? indexKep; // ÚJ

  FelszerelesTetel({
    required this.id,
    required this.kategoriaId,
    required this.marka,
    required this.nev,
    required this.jellemzo,
    required this.mertekegyseg,
    required this.leiras,
    required this.kepek,
    required this.elhelyezesek,
    this.indexKep,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kategoriaId': kategoriaId,
    'marka': marka,
    'nev': nev,
    'jellemzo': jellemzo,
    'mertekegyseg': mertekegyseg,
    'leiras': leiras,
    'kepek': kepek,
    'elhelyezesek': elhelyezesek.map((e) => e.toJson()).toList(),
    'indexKep': indexKep,
  };

  factory FelszerelesTetel.fromJson(Map<String, dynamic> json) => FelszerelesTetel(
    id: json['id'] ?? '',
    kategoriaId: json['kategoriaId'] ?? '',
    marka: json['marka'] ?? '',
    nev: json['nev'] ?? '',
    jellemzo: json['jellemzo'] ?? '',
    mertekegyseg: json['mertekegyseg'] ?? '',
    leiras: json['leiras'] ?? '',
    kepek: List<String>.from(json['kepek'] ?? []),
    elhelyezesek: (json['elhelyezesek'] as List? ?? []).map((e) => FelszerelesElhelyezes.fromJson(e)).toList(),
    indexKep: json['indexKep'],
  );
}

class DokumentumMappa {
  String id;
  String nev;
  DokumentumMappa({required this.id, required this.nev});
  Map<String, dynamic> toJson() => {'id': id, 'nev': nev};
  factory DokumentumMappa.fromJson(Map<String, dynamic> json) => DokumentumMappa(id: json['id'] ?? '', nev: json['nev'] ?? '');
}

class DokumentumFajl {
  String id;
  String mappaId;
  String nev;
  String utvonal;
  bool isPdf;
  DokumentumFajl({required this.id, required this.mappaId, required this.nev, required this.utvonal, required this.isPdf});
  Map<String, dynamic> toJson() => {'id': id, 'mappaId': mappaId, 'nev': nev, 'utvonal': utvonal, 'isPdf': isPdf};
  factory DokumentumFajl.fromJson(Map<String, dynamic> json) => DokumentumFajl(
    id: json['id'] ?? '', mappaId: json['mappaId'] ?? '', nev: json['nev'] ?? '', utvonal: json['utvonal'] ?? '', isPdf: json['isPdf'] ?? false,
  );
}
