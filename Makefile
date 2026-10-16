# Castle Excellent / Castlequest: build the source back into the original ROMs
# and check it. `make help` lists the targets.
PYTHON ?= python
# cc65 from Retrolarium Kit (RLTOOL, default rltool), asked once per run; the
# recipes' shell needs forward slashes.
RLTOOL ?= rltool
export RLTOOL
CA65 ?= $(eval CA65 := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path nes ca65)))$(CA65)
LD65 ?= $(eval LD65 := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path nes ld65)))$(LD65)
# MAME for `make test-full`, `make golden` and `make play`; with none named,
# the one `rltool movie mame <path>` remembered.
MAME ?= $(RETROLARIUM_MAME)

# The private assets: assets/manifest.json names the ROMs and what `make split`
# cuts out of them; `rltool assets` (Retrolarium Kit) splits, checks and
# verifies.
ASSETS = $(RLTOOL) assets $(1)
BASE_IMAGE := castle-excellent-japan-hsp-05
REFERENCE_ROM ?= Castle Excellent (J).nes
# The revisions: the image ids of assets/manifest.json, their defines and ROM
# names. The base revision builds into build/native.
REVISION ?= castlequest-usa
REVISION_DEFINES_castlequest-usa := -D CASTLEQUEST_USA=1
REVISION_ROM_castle-excellent-japan-hsp-05 := build/native/castle_excellent.nes
REVISION_ROM_castlequest-usa := build/revisions/castlequest-usa/castlequest.nes
BUILD_DIR := build/native
ROM := $(BUILD_DIR)/castle_excellent.nes
RELOCATED_DIR := build/relocated
RELOCATED_ROM := $(RELOCATED_DIR)/castle_excellent.nes
# The movies by name (make play MOVIE=<name>); test-full plays them in this
# order: the TAS first, then the longplay, then the attract mode.
MOVIE_attract := movies/attract.check.json
MOVIES := attract
MOVIE_CHECKS := $(foreach movie,$(MOVIES),$(MOVIE_$(movie)))
SOURCE_FILES := $(sort $(wildcard \
	src/*.asm src/*/*.asm src/*/*/*.asm src/*/*/*/*.asm \
	src/*.inc src/*/*.inc src/*/*/*.inc src/*/*/*/*.inc))

# One build of src/main.asm: $(call build_rom,<output ROM>,<ca65 defines>)
build_rom = $(PYTHON) -c "from pathlib import Path; Path('$(dir $(1))').mkdir(parents=True, exist_ok=True)" && \
	$(CA65) --debug-info -g $(2) -o "$(basename $(1)).o" -l "$(basename $(1)).lst" "src/main.asm" && \
	$(LD65) -C config/linker/cnrom.cfg -o "$(1)" "$(basename $(1)).o" -Ln "$(basename $(1)).lbl" \
		-m "$(basename $(1)).map" --dbgfile "$(basename $(1)).dbg"

.PHONY: play all help build verify build-revision verify-revision verify-revisions split \
	_require-assets build-relocated verify-toolchain studio-check lint format format-check \
	test test-full golden hooks clean

all: verify

split:
	$(call ASSETS,split)

_require-assets:
	$(call ASSETS,check) --image $(BASE_IMAGE)

$(ROM): $(SOURCE_FILES) Makefile | verify-toolchain _require-assets
	$(call build_rom,$@,)

build: $(ROM)

verify: $(ROM)
	$(call ASSETS,verify) --image $(BASE_IMAGE) --built "$(ROM)"

# One revision (REVISION=<image id>).
build-revision: verify-toolchain
	$(call ASSETS,check) --image $(REVISION)
	$(call build_rom,$(REVISION_ROM_$(REVISION)),$(REVISION_DEFINES_$(REVISION)))

verify-revision: build-revision
	$(call ASSETS,verify) --image $(REVISION) --built "$(REVISION_ROM_$(REVISION))"

# Every revision whose ROM is here.
verify-revisions:
	@for revision in $$($(call ASSETS,images) --present); do \
		$(MAKE) --no-print-directory verify-revision REVISION=$$revision || exit 1; \
	done

build-relocated: $(SOURCE_FILES) | verify-toolchain _require-assets
	$(PYTHON) scripts/build/relocate.py --main src/main.asm --output "$(RELOCATED_DIR)/source/main.asm"
	$(CA65) -g -o "$(RELOCATED_DIR)/castle_excellent.o" "$(RELOCATED_DIR)/source/main.asm"
	$(LD65) -C config/linker/cnrom.cfg -o "$(RELOCATED_ROM)" "$(RELOCATED_DIR)/castle_excellent.o"

verify-toolchain:
	$(PYTHON) scripts/build/toolchain.py --manifest config/toolchain.json

# Open every revision of castle_excellent.rlj in a throwaway copy of the
# repository the way Retrolarium Studio does, and rebuild each without edits.
studio-check:
	$(RLTOOL) studio check castle_excellent.rlj

lint:
	$(RLTOOL) lint

format:
	$(RLTOOL) lint --fix

format-check:
	$(RLTOOL) lint --only assembly

# The quick suite: the unit tests, every revision byte for byte against the
# ROMs that are here, the relocated build and the studio check.
test:
	$(PYTHON) -m unittest discover -s tests
	$(MAKE) --no-print-directory verify verify-revisions build-relocated studio-check

# The full suite: the quick one, then the movies in MAME on the relocated
# build in turn (the first that differs stops it); the attract mode plays with
# no input, the game showing its own demos. Compared with what the original
# ROM gives (movies/*.check.json, written by `make golden`).
test-full: test
	$(RLTOOL) movie check $(MOVIE_CHECKS) --rom "$(RELOCATED_ROM)" --mame "$(MAME)"

golden:
	$(RLTOOL) movie golden $(MOVIE_CHECKS) --rom "$(REFERENCE_ROM)" --mame "$(MAME)"

# Watch a movie in a MAME window at the game's speed, on the relocated build
# or on ROM=<image>; once the window is closed, its cells are compared with
# the original's. In MAME, F10 lifts the speed limit and Insert fast-forwards.
#   make play MOVIE=<name> [ROM=<image>] [FRAMES=<frame>] [CLOSE=1]
# FRAMES closes MAME at that frame (only the start of the movie), CLOSE=1 when
# the movie ends (else it stays open to play on, the credits say).
MOVIE ?= $(firstword $(MOVIES))
PLAY_ROM = $(if $(filter command line,$(origin ROM)),$(ROM),$(RELOCATED_ROM))
ifneq ($(filter play,$(MAKECMDGOALS)),)
ifeq ($(MOVIE_$(MOVIE)),)
$(error unknown MOVIE "$(MOVIE)": this game has $(MOVIES))
endif
endif

play: $(if $(filter command line,$(origin ROM)),,build-relocated)
	$(RLTOOL) movie play $(MOVIE_$(MOVIE)) --rom "$(PLAY_ROM)" --mame "$(MAME)" \
		$(if $(FRAMES),--stop-at $(FRAMES)) $(if $(CLOSE),--close)

# `make hooks`, once per clone, makes Git check every commit and push for stop
# words and run `make lint` and `make format-check` first (Retrolarium Kit's
# rltool hooks; the stop-word list lives outside the repositories).
hooks:
	$(RLTOOL) hooks install --project .

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

help:
	@echo "Castle Excellent / Castlequest source reconstruction"
	@echo "  make split                    cut the assets out of the ROMs that are here (once)"
	@echo "  make build / verify           the Japanese ROM / and byte for byte"
	@echo "  make build-revision REVISION=<id> / verify-revision / verify-revisions"
	@echo "                                the revisions (image ids of assets/manifest.json)"
	@echo "  make build-relocated          every module moved (scripts/build/relocate.py)"
	@echo "  make studio-check             open and rebuild every castle_excellent.rlj revision"
	@echo "  make test                     the quick suite"
	@echo "  make test-full                test, then the attract mode in MAME (MAME=<path>)"
	@echo "  make golden                   record the attract mode's checkpoints from the original"
	@echo "  make play MOVIE=attract       watch a movie in MAME (ROM=<image> for another build)"
	@echo "  make lint / format / format-check   the house style (Retrolarium Kit)"
	@echo "  make hooks                    install the Git hooks"
	@echo "  make verify-toolchain / clean"
