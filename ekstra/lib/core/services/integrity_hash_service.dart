class IntegrityHashService {
  const IntegrityHashService._();

  static final BigInt _offsetBasis = BigInt.parse(
    'cbf29ce484222325',
    radix: 16,
  );

  static final BigInt _prime = BigInt.parse('100000001b3', radix: 16);

  static final BigInt _mask = BigInt.parse('7fffffffffffffff', radix: 16);

  static String hash(String input) {
    BigInt hash = _offsetBasis;

    for (final unit in input.codeUnits) {
      hash ^= BigInt.from(unit);
      hash = (hash * _prime) & _mask;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  static String canonicalMap(Map<dynamic, dynamic> map) {
    final keys = map.keys.map((key) => key.toString()).toList()..sort();

    return keys.map((key) => '$key=${_canonicalValue(map[key])}').join('|');
  }

  static String canonicalList(Iterable<Object?> values) {
    return values.map(_canonicalValue).join('\n');
  }

  static String _canonicalValue(Object? value) {
    if (value == null) return 'null';
    if (value is Map) return '{${canonicalMap(value)}}';
    if (value is Iterable) return '[${canonicalList(value)}]';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }
}
