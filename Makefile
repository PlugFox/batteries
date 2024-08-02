.PHONY: format get outdated test publish deploy coverage analyze check pana

format:
	@echo "Formatting the code"
	@dart format -l 80 --fix .
	@dart fix --apply .

get:
	@dart pub get

outdated:
	@dart pub outdated --show-all --dev-dependencies --dependency-overrides --transitive --no-prereleases

test: get
	@dart test --debug --coverage=coverage --platform chrome,vm test/test.dart

publish:
	@yes | dart pub publish

deploy: publish

coverage: get
	@dart pub global activate coverage
	@dart pub global run coverage:test_with_coverage -fb -o coverage -- \
		--platform vm --compiler=kernel --coverage=coverage \
		--reporter=expanded --file-reporter=json:coverage/tests.json \
		--timeout=10m --concurrency=12 --color \
			test/test.dart
#	@dart test --concurrency=6 --platform vm --coverage=coverage test/
#	@dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
	@mv coverage/lcov.info coverage/lcov.base.info
	@lcov -r coverage/lcov.base.info -o coverage/lcov.base.info "lib/src/protobuf/client.*.dart" "lib/**/*.g.dart"
	@mv coverage/lcov.base.info coverage/lcov.info
	@lcov --list coverage/lcov.info
	@genhtml -o coverage coverage/lcov.info

analyze: get format
	@echo "Analyze the code"
	@dart analyze --fatal-infos --fatal-warnings

check: analyze
	@dart pub publish --dry-run
	@dart pub global activate pana
	@pana --json --no-warning --line-length 80 > log.pana.json

pana: check