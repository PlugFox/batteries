.PHONY: test coverage check fix format test-beta

test: get
	@(cd ./packages/batteries && dart test --concurrency=6 --platform vm --coverage=coverage test/all_test.dart)

coverage: test
	@(cd ./packages/batteries && dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib)
	@(cd ./packages/batteries && genhtml -o coverage coverage/lcov.info)

check:
	@(cd ./packages/batteries && dart format --set-exit-if-changed .)
	@(cd ./packages/batteries && dart analyze --fatal-infos --fatal-warnings .)
	@(cd ./packages/batteries && pana --json --no-warning --line-length 80)

fix: format

format:
	@dart fix --apply .
	@dart format -l 80 --fix .

test-beta:
	@docker run --rm -it \
		-v ${PWD}/packages/batteries:/package \
		-v ${PWD}/tool/script/test.sh:/package/test_batteries.sh \
		--workdir /package --name dart_beta \
			dart:beta ./test_batteries.sh 1> $(PWD)/.log.txt
