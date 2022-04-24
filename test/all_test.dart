// ignore_for_file: unnecessary_lambdas

import 'package:test/test.dart';

import 'unit/iterable_test.dart' as unit_iterable;
import 'unit/list_test.dart' as unit_list;

void main() {
  group('unit', () {
    unit_iterable.main();
    unit_list.main();
  });
}
