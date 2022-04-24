.PHONY: codegen

CFLAGS += -D nix

_echo_os:
	@echo "Running Makefile on *nix"

_setup:
	@sudo apt update
	@sudo apt install beep

codegen:
	@nohup /bin/bash -c ' \
		timeout 60 dart pub get \
		&& timeout 300 dart run build_runner build --delete-conflicting-outputs \
		&& beep -l 250 -f 250 || beep -f 400 -l 500 -r 2' >/dev/null 2>&1 &