# Castle Excellent / Castlequest: build the source back into the original ROMs
# and check it. `make help` lists the targets.
PYTHON ?= python
RUN_TOOL := $(PYTHON) scripts/run.py
# cc65 from Retrolarium Kit (RLTOOL, default rltool), asked once per run; the
# recipes' shell needs forward slashes.
RLTOOL ?= rltool
export RLTOOL
CA65 ?= $(eval CA65 := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path nes ca65)))$(CA65)
LD65 ?= $(eval LD65 := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path nes ld65)))$(LD65)
# MAME for `make test-full` and `make golden`.
MAME ?= $(RETROLARIUM_MAME)

REFERENCE_ROM ?= Castle Excellent (J).nes
MANIFEST := assets/manifest.json
REVISION_MANIFEST := config/revision_profiles.json
REVISION_PROFILE ?= castlequest-usa
BUILD_DIR := build/native
GENERATED_ASSET_DIR := assets/generated
CHR_ASSET := $(GENERATED_ASSET_DIR)/chr/castle_excellent.chr
PRG_ASSET := $(GENERATED_ASSET_DIR)/prg/castle_excellent.prg
OBJECT := $(BUILD_DIR)/castle_excellent.o
ROM := $(BUILD_DIR)/castle_excellent.nes
LABELS := $(BUILD_DIR)/castle_excellent.lbl
MAP := $(BUILD_DIR)/castle_excellent.map
DEBUG := $(BUILD_DIR)/castle_excellent.dbg
# Every routine and table before the fixed PRG tail moves by this many bytes
# (src/system/famicom_platform.asm); the tail's padding takes up to $48.
RELOCATION_SHIFT ?= 32
RELOCATED_DIR := build/relocated
RELOCATED_ROM := $(RELOCATED_DIR)/castle_excellent.nes
ATTRACT_CHECK := movies/attract.check.json
VERIFY_ROM := $(RUN_TOOL) build.verify_rom
SOURCE_FILES := $(sort $(wildcard \
	src/*.asm src/*/*.asm src/*/*/*.asm src/*/*/*/*.asm \
	src/*.inc src/*/*.inc src/*/*/*.inc src/*/*/*/*.inc))

.PHONY: all help build clean split check-assets verify verify-reference verify-built \
	verify-header verify-prg verify-chr verify-payload verify-rom verify-assets \
	rom-info rom-info-reference rom-info-built split-profile build-profile verify-profile \
	castlequest-check build-relocated \
	verify-toolchain studio-check lint format format-check test test-full golden hooks

all: verify

$(BUILD_DIR) $(RELOCATED_DIR):
	$(RUN_TOOL) build.project mkdir --path "$@"

$(CHR_ASSET) $(PRG_ASSET):
	$(RUN_TOOL) build.project require --path "$@" --hint "run 'make split' first"

$(OBJECT): $(SOURCE_FILES) $(CHR_ASSET) Makefile | $(BUILD_DIR) verify-toolchain
	$(CA65) --debug-info -g -o "$@" -l "$(BUILD_DIR)/castle_excellent.lst" "src/main.asm"

$(ROM): $(OBJECT) config/linker/cnrom.cfg
	$(LD65) -C config/linker/cnrom.cfg -o "$@" "$<" -Ln "$(LABELS)" -m "$(MAP)" --dbgfile "$(DEBUG)"

build: $(ROM)

split:
	$(RUN_TOOL) build.project split --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --output-dir "$(GENERATED_ASSET_DIR)"

verify-reference:
	$(RUN_TOOL) build.project verify --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)"

verify-built: $(ROM)
	$(RUN_TOOL) build.project verify --image "$(ROM)" --manifest "$(MANIFEST)"

verify-header verify-prg verify-chr verify-payload verify-rom: $(ROM)
	$(VERIFY_ROM) compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region $(subst verify-,,$@)

verify-assets: $(CHR_ASSET)
	$(VERIFY_ROM) asset --asset "$(CHR_ASSET)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region chr

check-assets: verify-assets

verify: verify-reference verify-built verify-header verify-prg verify-chr \
	verify-payload verify-rom verify-assets

rom-info-reference:
	$(VERIFY_ROM) report --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)"

rom-info-built: $(ROM)
	$(VERIFY_ROM) report --image "$(ROM)" --manifest "$(MANIFEST)"

rom-info: rom-info-reference rom-info-built

# Castlequest and the other revisions of config/revision_profiles.json.
split-profile:
	$(RUN_TOOL) build.revision_profiles --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" split

build-profile: verify-toolchain
	$(RUN_TOOL) build.revision_profiles --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" build --ca65 "$(CA65)" --ld65 "$(LD65)"

verify-profile: build-profile
	$(RUN_TOOL) build.revision_profiles --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" verify

castlequest-check:
	$(MAKE) split-profile REVISION_PROFILE=castlequest-usa
	$(MAKE) verify-profile REVISION_PROFILE=castlequest-usa

build-relocated: $(SOURCE_FILES) $(CHR_ASSET) | $(RELOCATED_DIR) verify-toolchain
	$(CA65) -D RELOCATION_TEST_SHIFT=$(RELOCATION_SHIFT) -g -o "$(RELOCATED_DIR)/castle_excellent.o" "src/main.asm"
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

# The quick suite: the unit tests, the ROMs byte for byte, the relocated build
# and the studio check.
test:
	$(PYTHON) -m unittest discover -s tests
	$(MAKE) --no-print-directory verify castlequest-check build-relocated studio-check

# The full suite: the quick one, then the attract mode in MAME (no input, the
# game plays its own demos) on the relocated build, compared with what the
# original ROM gives (movies/attract.check.json, written by `make golden`).
test-full: test
	$(RLTOOL) movie check $(ATTRACT_CHECK) --rom "$(RELOCATED_ROM)" --mame "$(MAME)"

golden:
	$(RLTOOL) movie golden $(ATTRACT_CHECK) --rom "$(REFERENCE_ROM)" --mame "$(MAME)"

# `make hooks`, once per clone, makes Git check every commit and push for stop
# words and run `make lint` and `make format-check` first (Retrolarium Kit's
# rltool hooks; the stop-word list lives outside the repositories).
hooks:
	$(RLTOOL) hooks install --project .

clean:
	$(RUN_TOOL) build.project clean --path build

help:
	@echo "Castle Excellent / Castlequest source reconstruction"
	@echo "  make split                    unpack the assets from your Castle Excellent ROM (once)"
	@echo "  make build / verify           the Japanese ROM / and byte for byte"
	@echo "  make castlequest-check        split and verify Castlequest (USA)"
	@echo "  make verify-profile REVISION_PROFILE=<id>   one revision of config/revision_profiles.json"
	@echo "  make build-relocated          every routine moved by RELOCATION_SHIFT bytes"
	@echo "  make studio-check             open and rebuild every castle_excellent.rlj revision"
	@echo "  make test                     the quick suite"
	@echo "  make test-full                test, then the attract mode in MAME (MAME=<path>)"
	@echo "  make golden                   record the attract mode's checkpoints from the original"
	@echo "  make lint / format / format-check   the house style (Retrolarium Kit)"
	@echo "  make hooks                    install the Git hooks"
	@echo "  make rom-info / verify-toolchain / clean"
