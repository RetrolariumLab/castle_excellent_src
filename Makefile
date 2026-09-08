PYTHON ?= python
RUN_TOOL := $(PYTHON) scripts/run.py
CA65 ?= bin/ca65.exe
LD65 ?= bin/ld65.exe

REFERENCE_ROM ?= Castle Excellent (J).nes
MANIFEST := assets/manifest.json
SOURCE_1_MANIFEST := config/source_reconstruction_1_0.json
SOURCE_2_MANIFEST := config/source_reconstruction_2_0.json
SOURCE_2_MINOR_MANIFEST := config/source_reconstruction_2_1.json
REVISION_MANIFEST := config/revision_profiles.json
FIXED_LAYOUT_MANIFEST := config/fixed_layout_variants.json

REVISION_PROFILE ?= castlequest-usa
FIXED_LAYOUT_VARIANT ?= start-room-1
LEVEL_PLAYTEST_ROOM ?= 71
LEVEL_PLAYTEST_X ?= 16
LEVEL_PLAYTEST_Y ?= 152

ROMLESS_TEST_MODULES := \
	tests.test_script_runner \
	tests.build.test_make_help \
	tests.build.test_project \
	tests.build.test_revision_profiles \
	tests.build.test_verify_rom \
	tests.build.test_fixed_layout_variant \
	tests.workflow.test_generate_disassembly \
	tests.workflow.test_run_ghidra \
	tests.validation.test_release_audit \
	tests.validation.test_source_2_release_audit \
	tests.validation.test_release_history \
	tests.validation.test_source_2_minor_release_audit \
	tests.validation.test_public_command_smoke \
	tests.validation.test_python_source

LEVEL_AUTHORING := config/authoring/levels.json
AUDIO_AUTHORING := config/authoring/audio.json
GRAPHICS_AUTHORING := config/authoring/graphics.json
SYMBOLS := config/reconstruction/symbols.json
MEMORY_SYMBOLS := config/reconstruction/memory_symbols.json
OPERAND_OVERRIDES := config/reconstruction/operand_overrides.json
SOURCE_LAYOUT := config/reconstruction/source_layout.json
STATIC_CODE_EVIDENCE := config/reconstruction/static_code_evidence.txt
RUNTIME_EVIDENCE := config/reconstruction/runtime_evidence.txt
PRG_DATA_RANGES := config/reconstruction/prg_data_ranges.txt
FALSE_INSTRUCTION_STARTS := config/reconstruction/false_instruction_starts.txt

BUILD_DIR := build/native
GENERATED_ASSET_DIR := assets/generated
HEADER_ASSET := $(GENERATED_ASSET_DIR)/header/castle_excellent.hdr
PRG_ASSET := $(GENERATED_ASSET_DIR)/prg/castle_excellent.prg
CHR_ASSET := $(GENERATED_ASSET_DIR)/chr/castle_excellent.chr
OBJECT := $(BUILD_DIR)/castle_excellent.o
ROM := $(BUILD_DIR)/castle_excellent.nes
LABELS := $(BUILD_DIR)/castle_excellent.lbl
MAP := $(BUILD_DIR)/castle_excellent.map
DEBUG := $(BUILD_DIR)/castle_excellent.dbg
DEBUG_SUMMARY := $(BUILD_DIR)/debug_symbols.json
DEBUG_RUNTIME_RESULT := $(BUILD_DIR)/debug_symbols_runtime.txt
GHIDRA_FACTS := build/ghidra/instructions.tsv
FCEUX := tools/fceux/fceux64.exe

LEVEL_PLAYTEST_RESULT := build/authoring/$(REVISION_PROFILE)/level_playtest.txt
FIXED_LAYOUT_RESULT := build/variants/$(FIXED_LAYOUT_VARIANT)/runtime.txt
CASTLEQUEST_RUNTIME_RESULT := build/revisions/castlequest-usa/runtime.txt
VERIFY_ROM := $(RUN_TOOL) build.verify_rom

SOURCE_FILES := $(sort $(wildcard \
	src/*.asm src/*/*.asm src/*/*/*.asm src/*/*/*/*.asm \
	src/*.inc src/*/*.inc src/*/*/*.inc src/*/*/*/*.inc))
MAKE_FRAGMENTS := mk/authoring.mk mk/runtime.mk mk/validation.mk

.PHONY: all help build clean split inspect rom-info rom-info-reference \
	rom-info-built verify verify-reference verify-built verify-header \
	verify-prg verify-chr verify-payload verify-rom verify-assets check-assets \
	split-profile build-profile verify-profile castlequest-check \
	castlequest-runtime build-fixed-layout verify-fixed-layout \
	check-fixed-layout symbols validate-symbols format format-check lint-asm \
	lint-source lint-python lint-project lint test quality-check scaffold-check \
	reconstruction-audit build-toolchain-status release-audit source-1-check \
	source-1-pre-tag-check source-1-tag-check source-2-audit \
	source-2-authoring-check-profile source-2-check source-2-pre-tag-check \
	source-2-tag-check public-command-smoke source-2-minor-audit source-2-minor-check \
	source-2-minor-pre-tag-check source-2-minor-tag-check \
	ghidra-bootstrap ghidra-status ghidra-inspect \
	ghidra-analyze disassemble disassembly-check fceux-bootstrap fceux-status \
	check release-check

all: verify

help:
	@$(RUN_TOOL) build.make_help

$(BUILD_DIR):
	$(RUN_TOOL) build.project mkdir --path "$(BUILD_DIR)"

$(CHR_ASSET):
	$(RUN_TOOL) build.project require --path "$@" --hint "run 'make split' first"

$(PRG_ASSET):
	$(RUN_TOOL) build.project require --path "$@" --hint "run 'make split' first"

$(OBJECT): $(SOURCE_FILES) $(CHR_ASSET) Makefile $(MAKE_FRAGMENTS) | $(BUILD_DIR) build-toolchain-status
	$(CA65) --debug-info -g -o "$@" -l "$(BUILD_DIR)/castle_excellent.lst" "src/main.asm"

$(ROM): $(OBJECT) config/linker/cnrom.cfg
	$(LD65) -C config/linker/cnrom.cfg -o "$@" "$<" -Ln "$(LABELS)" -m "$(MAP)" --dbgfile "$(DEBUG)"

build: $(ROM)

split:
	$(RUN_TOOL) build.project split --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --output-dir "$(GENERATED_ASSET_DIR)"

split-profile:
	$(RUN_TOOL) build.revision_profiles --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" split

build-profile: build-toolchain-status
	$(RUN_TOOL) build.revision_profiles --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" build --ca65 "$(CA65)" --ld65 "$(LD65)"

verify-profile: build-profile
	$(RUN_TOOL) build.revision_profiles --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" verify

castlequest-check:
	$(MAKE) split-profile REVISION_PROFILE=castlequest-usa
	$(MAKE) verify-profile REVISION_PROFILE=castlequest-usa

castlequest-runtime: fceux-bootstrap castlequest-check
	$(RUN_TOOL) runtime.revision_runtime --revisions "$(REVISION_MANIFEST)" --profile castlequest-usa --fceux "$(FCEUX)" --lua scripts/runtime/capture_castlequest_runtime.lua --result "$(CASTLEQUEST_RUNTIME_RESULT)"

build-fixed-layout: build
	$(RUN_TOOL) build.fixed_layout_variant build --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)"

verify-fixed-layout: build
	$(RUN_TOOL) build.fixed_layout_variant verify --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)"

check-fixed-layout: fceux-bootstrap build
	$(RUN_TOOL) build.fixed_layout_variant runtime --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)" --fceux "$(FCEUX)" --lua scripts/runtime/validate_fixed_layout.lua --result "$(FIXED_LAYOUT_RESULT)"

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

inspect: rom-info-reference

symbols: $(ROM)
	$(RUN_TOOL) validation.debug_symbols --debug "$(DEBUG)" --map "$(MAP)" --labels "$(LABELS)" --rom "$(ROM)" --output-dir "$(BUILD_DIR)" --breakpoints config/debugger/breakpoints.json --watches config/debugger/watches.json --source-layout "$(SOURCE_LAYOUT)" --summary "$(DEBUG_SUMMARY)"

validate-symbols: fceux-bootstrap symbols
	$(RUN_TOOL) runtime.validate_debug_runtime --fceux "$(FCEUX)" --rom "$(ROM)" --lua scripts/runtime/validate_debug_symbols.lua --result "$(DEBUG_RUNTIME_RESULT)"

format:
	$(RUN_TOOL) validation.asm_style --fix src
	$(RUN_TOOL) validation.format_project write
	$(MAKE) lint

format-check: lint-asm

lint-asm:
	$(RUN_TOOL) validation.asm_style src

lint-source:
	$(RUN_TOOL) validation.format_project check
	$(RUN_TOOL) build.project lint

lint-python:
	$(RUN_TOOL) validation.python_source --project-root .

lint-project: lint-source

lint: lint-asm lint-source lint-python

test: ghidra-analyze
	$(PYTHON) -m unittest discover -s tests -v

quality-check: lint test

scaffold-check: lint
	$(PYTHON) -m unittest $(ROMLESS_TEST_MODULES) -v

reconstruction-audit:
	$(RUN_TOOL) validation.source_reconstruction --layout "$(SOURCE_LAYOUT)"

build-toolchain-status:
	$(RUN_TOOL) validation.release_audit --project-root . --manifest "$(SOURCE_1_MANIFEST)" --build-tools-only

release-audit:
	$(RUN_TOOL) validation.release_audit --project-root . --manifest "$(SOURCE_1_MANIFEST)" --require-clean

source-1-check:
	$(MAKE) release-check

source-1-pre-tag-check:
	$(MAKE) release-check
	$(RUN_TOOL) validation.release_audit --project-root . --manifest "$(SOURCE_1_MANIFEST)" --pre-tag

source-1-tag-check:
	$(MAKE) release-check
	$(RUN_TOOL) validation.release_audit --project-root . --manifest "$(SOURCE_1_MANIFEST)" --require-tag

source-2-audit:
	$(RUN_TOOL) validation.source_2_release_audit --project-root . --manifest "$(SOURCE_2_MANIFEST)"

source-2-authoring-check-profile: editor-quality-check-profile

source-2-check:
	$(MAKE) source-1-check
	$(MAKE) castlequest-runtime
	$(MAKE) check-fixed-layout
	$(MAKE) source-2-authoring-check-profile REVISION_PROFILE=castle-excellent-japan-hsp-05
	$(MAKE) source-2-authoring-check-profile REVISION_PROFILE=castlequest-usa
	$(MAKE) smoke-baseline-level-playtest REVISION_PROFILE=castle-excellent-japan-hsp-05
	$(MAKE) smoke-baseline-level-playtest REVISION_PROFILE=castlequest-usa
	$(MAKE) source-2-audit

source-2-pre-tag-check:
	$(MAKE) source-2-check
	$(RUN_TOOL) validation.source_2_release_audit --project-root . --manifest "$(SOURCE_2_MANIFEST)" --pre-tag

source-2-tag-check:
	$(MAKE) source-2-check
	$(RUN_TOOL) validation.source_2_release_audit --project-root . --manifest "$(SOURCE_2_MANIFEST)" --require-tag

source-2-minor-audit:
	$(RUN_TOOL) validation.source_2_minor_release_audit --project-root . --manifest "$(SOURCE_2_MINOR_MANIFEST)"

public-command-smoke:
	$(RUN_TOOL) validation.public_command_smoke --project-root . --target lint

source-2-minor-check:
	$(MAKE) source-2-check
	$(MAKE) editor-ui-smoke-profile REVISION_PROFILE=castle-excellent-japan-hsp-05
	$(MAKE) editor-ui-smoke-profile REVISION_PROFILE=castlequest-usa
	$(MAKE) public-command-smoke
	$(MAKE) source-2-minor-audit

source-2-minor-pre-tag-check:
	$(MAKE) source-2-minor-check
	$(RUN_TOOL) validation.source_2_minor_release_audit --project-root . --manifest "$(SOURCE_2_MINOR_MANIFEST)" --pre-tag

source-2-minor-tag-check:
	$(MAKE) source-2-minor-check
	$(RUN_TOOL) validation.source_2_minor_release_audit --project-root . --manifest "$(SOURCE_2_MINOR_MANIFEST)" --require-tag

ghidra-bootstrap:
	$(RUN_TOOL) workflow.bootstrap_ghidra install

ghidra-status:
	$(RUN_TOOL) workflow.bootstrap_ghidra status

ghidra-inspect: ghidra-bootstrap
	$(RUN_TOOL) workflow.run_ghidra inspect --image "$(REFERENCE_ROM)" --output build/ghidra/program.json

ghidra-analyze: ghidra-bootstrap verify-reference
	$(RUN_TOOL) workflow.run_ghidra export-facts --image "$(REFERENCE_ROM)" --false-instructions "$(FALSE_INSTRUCTION_STARTS)" --static-evidence "$(STATIC_CODE_EVIDENCE)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --data-ranges "$(PRG_DATA_RANGES)" --output "$(GHIDRA_FACTS)"

disassemble: ghidra-analyze $(PRG_ASSET)
	$(RUN_TOOL) workflow.generate_disassembly write --prg "$(PRG_ASSET)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --memory-symbols "$(MEMORY_SYMBOLS)" --operand-overrides "$(OPERAND_OVERRIDES)" --layout "$(SOURCE_LAYOUT)"

disassembly-check: ghidra-analyze $(PRG_ASSET)
	$(RUN_TOOL) workflow.generate_disassembly check --prg "$(PRG_ASSET)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --memory-symbols "$(MEMORY_SYMBOLS)" --operand-overrides "$(OPERAND_OVERRIDES)" --layout "$(SOURCE_LAYOUT)"

fceux-bootstrap:
	$(RUN_TOOL) runtime.bootstrap_fceux install

fceux-status:
	$(RUN_TOOL) runtime.bootstrap_fceux status

include $(MAKE_FRAGMENTS)

check: static-release-check

release-check:
	$(MAKE) clean
	$(MAKE) verify-reference verify-assets build-toolchain-status
	$(MAKE) check
	$(MAKE) validate-symbols
	$(MAKE) trace
	$(MAKE) release-audit

clean:
	$(RUN_TOOL) build.project clean --path build
