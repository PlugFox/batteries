// ignore_for_file: unnecessary_lambdas

import 'package:batteries/batteries.dart';
import 'package:test/test.dart';

void main() {
  group('unit', () {
    test('placeholder', () {
      expect(() => Placeholder(), returnsNormally);
      expect(Placeholder(), isA<Placeholder>());
    });
  });
}
