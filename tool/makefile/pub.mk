.PHONY: clean get upgrade upgrade-major outdated deploy

clean:
	@rm -rf coverage .dart_tool .packages pubspec.lock

get:
	@timeout 60 dart pub get

upgrade:
	@timeout 60 dart pub upgrade

upgrade-major:
	@timeout 60 dart pub upgrade --major-versions

outdated: upgrade
	@timeout 120 dart pub outdated --dependency-overrides \
		--dev-dependencies --prereleases --show-all --transitive

deploy:
	@dart pub publish
