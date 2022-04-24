import 'package:batteries/src/iterable.dart' show UTF8CodeUnitsX;

/// {@template string.string_extensions}
/// String extensions.
/// {@endtemplate}
extension StringX on String {
  /// Split string to numbers
  List<int> splitToNumbers([int max = 8]) => codeUnits
      .fold<List<int>>(
        List<int>.generate(max + 1, (i) => i < max ? -1 : 0, growable: false),
        (r, c) => (c < 48 || c > 57 || r[max] >= max)
            ? ((r[max] >= max || r[r[max]] < 0) ? r : (r..[max] += 1))
            : (r..[r[max]] = (r[r[max]] < 0 ? 0 : (r[r[max]] * 10)) + c - 48),
      )
      .take(max)
      .map<int>((i) => i < 0 ? 0 : i)
      .toList(growable: false);

  /// Get only latin characters
  String get onlyLatin => String.fromCharCodes(codeUnits.onlyLatin);

  /// Get only cyrillic characters
  String get onlyCyrillic => String.fromCharCodes(codeUnits.onlyCyrillic);

  /// Get only digits
  String get onlyDigit => String.fromCharCodes(codeUnits.onlyDigits);

  /// Transliteration
  String get transliteration => String.fromCharCodes(
        codeUnits.expand<int>((e) => _transliterationDictionary[e] ?? <int>[e]),
      );
}

/// Transliteration dictionary
const Map<int, List<int>> _transliterationDictionary = <int, List<int>>{
  /// Ё -> Yo
  1025: <int>[89, 111],

  /// А -> A
  1040: <int>[65],

  /// Б -> B
  1041: <int>[66],

  /// В -> V
  1042: <int>[86],

  /// Г -> G
  1043: <int>[71],

  /// Д -> D
  1044: <int>[68],

  /// Е -> E
  1045: <int>[69],

  /// Ж -> Zh
  1046: <int>[90, 104],

  /// З -> Z
  1047: <int>[90],

  /// И -> I
  1048: <int>[73],

  /// Й -> J
  1049: <int>[74],

  /// К -> K
  1050: <int>[75],

  /// Л -> L
  1051: <int>[76],

  /// М -> M
  1052: <int>[77],

  /// Н -> N
  1053: <int>[78],

  /// О -> O
  1054: <int>[79],

  /// П -> P
  1055: <int>[80],

  /// Р -> R
  1056: <int>[82],

  /// С -> S
  1057: <int>[83],

  /// Т -> T
  1058: <int>[84],

  /// У -> U
  1059: <int>[85],

  /// Ф -> F
  1060: <int>[70],

  /// Х -> H
  1061: <int>[72],

  /// Ц -> C
  1062: <int>[67],

  /// Ч -> Ch
  1063: <int>[67, 104],

  /// Ш -> Shh
  1064: <int>[83, 104, 104],

  /// Щ -> Shhch
  1065: <int>[83, 104, 104, 99, 104],

  /// Ы -> Y
  1067: <int>[89],

  /// Э -> Eh'
  1069: <int>[69, 104, 39],

  /// Ю -> Yu
  1070: <int>[89, 117],

  /// Я -> Ya
  1071: <int>[89, 97],

  /// а -> a
  1072: <int>[97],

  /// б -> b
  1073: <int>[98],

  /// в -> v
  1074: <int>[118],

  /// г -> g
  1075: <int>[103],

  /// д -> d
  1076: <int>[100],

  /// е -> e
  1077: <int>[101],

  /// ж -> zh
  1078: <int>[122, 104],

  /// з -> z
  1079: <int>[122],

  /// и -> i
  1080: <int>[105],

  /// й -> j
  1081: <int>[106],

  /// к -> k
  1082: <int>[107],

  /// л -> l
  1083: <int>[108],

  /// м -> m
  1084: <int>[109],

  /// н -> n
  1085: <int>[110],

  /// о -> o
  1086: <int>[111],

  /// п -> p
  1087: <int>[112],

  /// р -> r
  1088: <int>[114],

  /// с -> s
  1089: <int>[115],

  /// т -> t
  1090: <int>[116],

  /// у -> u
  1091: <int>[117],

  /// ф -> f
  1092: <int>[102],

  /// х -> h
  1093: <int>[104],

  /// ц -> c
  1094: <int>[99],

  /// ч -> ch
  1095: <int>[99, 104],

  /// ш -> shh
  1096: <int>[115, 104, 104],

  /// щ -> shhch
  1097: <int>[115, 104, 104, 99, 104],

  /// ъ -> "
  1098: <int>[34],

  /// ы -> y
  1099: <int>[121],

  /// ь -> '
  1100: <int>[39],

  /// э -> eh'
  1101: <int>[101, 104, 39],

  /// ю -> yu
  1102: <int>[121, 117],

  /// я -> ya
  1103: <int>[121, 97],

  /// ё -> yo
  1105: <int>[121, 111],
};
