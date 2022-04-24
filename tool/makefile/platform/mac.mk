.PHONY: codegen

CFLAGS += -D osx

_echo_os:
	@echo "Running Makefile on macOS"

_setup:
	@brew update
	@brew install coreutils

codegen:
	@nohup /bin/bash -c ' \
		gtimeout 60 dart pub get \
		&& gtimeout 300 dart run build_runner build --delete-conflicting-outputs \
		&& say "Code generation completed" || say "Code generation failed!" ' >/dev/null 2>&1 &
