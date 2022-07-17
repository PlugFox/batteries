// ignore_for_file: unnecessary_lambdas

import 'package:test/test.dart';

import 'unit/iterable_test.dart' as unit_iterable;
import 'unit/list_test.dart' as unit_list;
import 'unit/stream_test.dart' as unit_stream;
import 'unit/string_test.dart' as unit_string;

void main() {
  group(
    'unit',
    () {
      unit_iterable.main();
      unit_list.main();
      unit_string.main();
      unit_stream.main();
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
