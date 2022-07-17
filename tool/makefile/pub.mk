.PHONY: version doctor clean get codegen upgrade upgrade-major outdated dependencies deploy

version:
	@timeout 60 flutter --version

doctor:
	@timeout 60 flutter doctor

clean:
	@(cd ./packages/batteries && rm -rf coverage .dart_tool .packages pubspec.lock)
	@(cd ./packages/flutter_batteries && rm -rf coverage .dart_tool .packages pubspec.lock)

get:
	@timeout 60 dart pub get -C ./packages/batteries
	@(cd ./packages/flutter_batteries && timeout 60 flutter pub get)

codegen: get
	@timeout 60 dart pub run build_runner build --delete-conflicting-outputs -C ./packages/batteries
	@(cd ./packages/flutter_batteries && timeout 60 flutter pub run build_runner build --delete-conflicting-outputs)

upgrade: get
	@timeout 60 dart pub upgrade --major-versions -C ./packages/batteries
	@(cd ./packages/flutter_batteries && timeout 60 flutter pub upgrade)

upgrade-major:
	@timeout 60 dart pub upgrade --major-versions -C ./packages/batteries
	@(cd ./packages/flutter_batteries && timeout 60 flutter pub upgrade --major-versions)

outdated: get
	@timeout 120 dart pub outdated --dependency-overrides --dev-dependencies \
		--prereleases --show-all --transitive -C ./packages/batteries
	@(cd ./packages/flutter_batteries && timeout 120 flutter pub outdated \
		 --dependency-overrides --dev-dependencies--prereleases --show-all --transitive)

dependencies: upgrade
	@timeout 60 dart pub outdated --dependency-overrides --dev-dependencies \
		--prereleases --show-all --transitive -C ./packages/batteries
	@(cd ./packages/flutter_batteries && timeout 60 flutter pub outdated \
		  --dependency-overrides--dev-dependencies--prereleases --show-all --transitive)

deploy-batteries:
	@dart pub publish -C ./packages/batteries

deploy-flutter-batteries:
	@(cd ./packages/flutter_batteries && flutter pub publish -C ./packages/flutter_batteries)