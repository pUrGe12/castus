# castus demo harness.  `make help` for the list.
SHELL := /bin/bash
NAME  ?= clean
# ESP-IDF firmware project (the dir with CMakeLists.txt). `idf.py clang-check`
# must run THERE, not in this harness dir. Override: make lint FW=/path/to/project
FW    ?= $(HOME)/esp/esp-tflite-micro/examples/hello_world

.PHONY: help scene verify live lint test-host capture clean

help:
	@echo "make scene NAME=clean|arena|drift   stage a scenario into build/"
	@echo "make verify                         run castus over build/ (replay)"
	@echo "make live                           run castus, booting"
	@echo "make lint [FW=/path/to/firmware]    esp-clang static analysis in the firmware project"
	@echo "make test-host                      compile + run host unit tests (green)"
	@echo "make capture                        regenerate real boot logs"

# Stand-in for `git checkout bug/<name> && idf.py build` on the real box:
# populates build/ with that scenario's captured artifacts.
scene:
	@cp scenarios/$(NAME)/boot.log build/boot.log
	@cp scenarios/$(NAME)/flash.bin build/flash.bin 2>/dev/null || true
	@cp scenarios/$(NAME)/hello_world.elf build/hello_world.elf 2>/dev/null || true
	@echo "staged scenario '$(NAME)' into build/"

verify:
	@./castus --verify .

live:
	@./castus --verify . --live

lint:
	@echo ">> esp-clang static analysis on $(FW)"
	@test -f "$(FW)/CMakeLists.txt" || { echo "no CMakeLists.txt in $(FW) — set FW=/path/to/firmware"; exit 1; }
	@cd "$(FW)" && idf.py clang-check || \
	  echo "(needs esp-clang + pyclang in the idf env; the warnings are noise — none is the real bug)"

test-host:
	@cc -O2 -Wall tests/test_quantize.c -o build/test_quantize -lm && ./build/test_quantize

capture:
	@bash scripts/capture.sh

clean:
	@rm -f build/boot.log build/flash.bin build/hello_world.elf build/test_quantize
