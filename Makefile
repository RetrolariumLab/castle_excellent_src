# Castle Excellent / Castlequest: build the source back into the original ROMs
# and check it. `make` alone lists the targets.
PYTHON ?= python
RLTOOL ?= rltool
export RLTOOL
# cc65 from Retrolarium Kit, which verifies it; asked once, when a recipe
# first needs it (the recipes' shell wants forward slashes).
CA65 ?= $(eval CA65 := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path nes ca65)))$(CA65)
LD65 ?= $(eval LD65 := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path nes ld65)))$(LD65)

GAME := castle_excellent
BASE_IMAGE := castle-excellent-japan-hsp-05
# The revisions the source builds, one entry file each; REVISION picks one.
REVISIONS := $(basename $(notdir $(wildcard src/revisions/*.asm)))
REVISION ?= $(BASE_IMAGE)
LINKER_CONFIG := config/linker/cnrom.cfg
OUT = build/revisions/$(REVISION)
ROM = $(OUT)/$(GAME).nes
RELOCATED_OUT = build/relocated/$(REVISION)
RELOCATED_ROM = $(RELOCATED_OUT)/$(GAME).nes
# The revisions whose ROM is here (assets/manifest.json names the files).
PRESENT = $(filter $(REVISIONS),$(shell $(RLTOOL) assets images --present))
# The movies each revision's relocated build plays in `make test-full`, by
# name (movies/<name>.check.json, written by `make golden`).
MOVIES_castle-excellent-japan-hsp-05 := attract
MOVIES_castlequest-usa := attract-castlequest
MOVIE_CHECKS = $(foreach movie,$(MOVIES_$(1)),movies/$(movie).check.json)
# The revisions here that have movies.
PLAYED = $(foreach revision,$(PRESENT),$(if $(MOVIES_$(revision)),$(revision)))
MAME_OPTION = $(if $(MAME),--mame "$(MAME)")

define newline


endef

# Assemble and link one entry file: $(call build_rom,<entry>,<output folder>)
build_rom = $(PYTHON) -c "from pathlib import Path; Path('$(2)').mkdir(parents=True, exist_ok=True)"$(newline)\
	$(CA65) -I src --debug-info -g -o "$(2)/$(GAME).o" -l "$(2)/$(GAME).lst" "$(1)"$(newline)\
	$(LD65) -C $(LINKER_CONFIG) -o "$(2)/$(GAME).nes" "$(2)/$(GAME).o" -Ln "$(2)/$(GAME).lbl" \
		-m "$(2)/$(GAME).map" --dbgfile "$(2)/$(GAME).dbg"

.PHONY: help split build verify verify-revisions build-relocated studio-check \
	lint format test test-full golden play hooks clean _revision
.DEFAULT_GOAL := help

split:
	$(RLTOOL) assets split

_revision:
	$(if $(filter $(REVISION),$(REVISIONS)),,$(error REVISION=$(REVISION) is not one of: $(REVISIONS)))
	$(RLTOOL) assets check --image $(REVISION)

# Every build assembles anew: it takes a second, and nothing it reads
# (source, linker config, CHR) can be missed.
build: _revision
	$(call build_rom,src/revisions/$(REVISION).asm,$(OUT))

verify: build
	$(RLTOOL) assets verify --image $(REVISION) --built "$(ROM)"

# Every revision whose ROM is here, byte for byte.
verify-revisions:
	$(if $(PRESENT),,$(error none of the ROMs of $(REVISIONS) is here: copy them beside this Makefile and make split))
	$(foreach revision,$(PRESENT),$(MAKE) --no-print-directory verify REVISION=$(revision)$(newline))

# The source with every PRG module moved by one more byte than the one before
# it (scripts/build/relocate.py), built the same way.
build-relocated: _revision
	$(PYTHON) scripts/build/relocate.py --entry src/revisions/$(REVISION).asm --output-dir "$(RELOCATED_OUT)"
	$(call build_rom,$(RELOCATED_OUT)/$(REVISION).asm,$(RELOCATED_OUT))

# Open the revisions of castle_excellent.rlj whose ROM is here in a throwaway copy
# of the repository the way Retrolarium Studio does, and rebuild each without
# edits.
studio-check:
	$(RLTOOL) studio check castle_excellent.rlj --present

lint:
	$(RLTOOL) lint

format:
	$(RLTOOL) lint --fix

# The quick suite: the unit tests, every revision here byte for byte and
# relocated, and the studio check.
test:
	$(PYTHON) -m unittest discover -s tests -t .
	$(MAKE) --no-print-directory verify-revisions
	$(foreach revision,$(PRESENT),$(MAKE) --no-print-directory build-relocated REVISION=$(revision)$(newline))
	$(MAKE) --no-print-directory studio-check

# The full suite: the quick one, then each relocated build plays its movies
# in MAME (the attract mode with no input: the title and the demo, which
# resets to the title when it ends), compared with what the original ROM
# gives (`make golden`).
test-full: test
	$(foreach revision,$(PLAYED),$(RLTOOL) movie check $(call MOVIE_CHECKS,$(revision)) \
		--rom "build/relocated/$(revision)/$(GAME).nes" $(MAME_OPTION)$(newline))

golden:
	$(foreach revision,$(PLAYED),$(RLTOOL) movie golden $(call MOVIE_CHECKS,$(revision)) \
		--rom "$(shell $(RLTOOL) assets path --image $(revision))" $(MAME_OPTION)$(newline))

# Watch a movie in a MAME window at the game's speed, on the relocated build
# or on ROM=<image>; once the window is closed, its cells are compared with
# the original's. In MAME, F10 lifts the speed limit and Insert fast-forwards.
#   make play [MOVIE=<name>] [REVISION=<id>] [ROM=<image>] [FRAMES=<frame>] [CLOSE=1]
# FRAMES closes MAME at that frame (only the start of the movie), CLOSE=1 when
# the movie ends (else it stays open to play on, the credits say).
MOVIE ?= $(firstword $(MOVIES_$(REVISION)))
PLAY_ROM = $(if $(filter command line,$(origin ROM)),$(ROM),$(RELOCATED_ROM))

play: $(if $(filter command line,$(origin ROM)),,build-relocated)
	$(if $(wildcard movies/$(MOVIE).check.json),,$(error unknown MOVIE "$(MOVIE)": movies/ has \
		$(basename $(basename $(notdir $(wildcard movies/*.check.json))))))
	$(RLTOOL) movie play movies/$(MOVIE).check.json --rom "$(PLAY_ROM)" $(MAME_OPTION) \
		$(if $(FRAMES),--stop-at $(FRAMES)) $(if $(CLOSE),--close)

# `make hooks`, once per clone, makes Git check every commit and push for stop
# words and run `make lint` first (Retrolarium Kit's rltool hooks; the
# stop-word list lives outside the repositories).
hooks:
	$(RLTOOL) hooks install --project .

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

help:
	$(info Castle Excellent / Castlequest source reconstruction: $(REVISIONS))
	$(info REVISION=$(BASE_IMAGE) unless given)
	$(info   make split                  cut the assets out of the ROMs that are here, once)
	$(info   make build [REVISION=id]    build a revision into build/revisions/id/)
	$(info   make verify [REVISION=id]   build it and compare it with its ROM byte for byte)
	$(info   make verify-revisions       every revision whose ROM is here)
	$(info   make build-relocated        the revision with its modules moved)
	$(info   make test                   the quick suite)
	$(info   make test-full              test, then the movies in MAME: MAME=path or the kit's)
	$(info   make golden                 record the movies' checkpoints from the original ROMs)
	$(info   make play [MOVIE=name]      watch a movie in MAME; ROM=image for another build)
	$(info   make studio-check / lint / format / hooks / clean)
	@exit 0
