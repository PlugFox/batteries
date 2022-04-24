.PHONY: codegen

CFLAGS += -D win

_echo_os:
	@echo "Running Makefile on Windows"

_setup:
	@echo "Placeholder for Windows setup"

codegen:
	@dart pub get
	@dart run build_runner build --delete-conflicting-outputs