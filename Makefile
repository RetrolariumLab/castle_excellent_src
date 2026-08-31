PYTHON ?= python
CA65 ?= bin/ca65.exe
LD65 ?= bin/ld65.exe
REFERENCE_ROM ?= Castle Excellent (J).nes
MANIFEST := assets/manifest.json
VERIFY_ROM := scripts/verify_rom.py

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
SOURCE_FILES := src/main.asm src/input/famicom_data_pulse.asm src/graphics/chr.asm \
	src/input/controllers.asm src/system/ppu.asm \
	src/input/famicom_data_io.asm src/system/startup.asm \
	src/preservation/prg_82ce_8f0f.asm \
	src/game/objects/runtime_record_offsets.asm src/preservation/prg_8f29_9577.asm \
	src/system/nmi_tasks.asm src/preservation/prg_9583_a35b.asm \
	src/game/rooms/load_room.asm src/preservation/prg_a3ac_a6d7.asm \
	src/game/rooms/mutable_cell_predicates.asm src/preservation/prg_a70a_ab49.asm \
	src/game/rooms/room_metadata.asm src/preservation/prg_ac13_b64b.asm \
	src/rendering/room_screen.asm src/preservation/prg_b7fd_c55c.asm \
	src/system/nmi.asm src/rendering/oam_dma.asm \
	src/rendering/status_upload.asm src/rendering/room_rows_00_04.asm \
	src/rendering/room_rows_05_09.asm src/rendering/room_rows_10_14.asm \
	src/rendering/room_rows_15_19.asm \
	src/rendering/room_attribute_upload.asm \
	src/game/rooms/decoder.asm src/rendering/room_attributes.asm \
	src/ui/castle_map.asm src/game/rooms/finalize_room.asm \
	src/game/objects/room_loader.asm \
	src/game/rooms/state_orchestration.asm src/game/rooms/persistent_state_apply.asm \
	src/game/objects/stream_seek.asm src/game/rooms/mutable_cell_state_apply.asm \
	src/game/rooms/persistent_state_load.asm \
	src/game/objects/room_data.asm src/preservation/prg_f8fc_fbfd.asm \
	src/game/save_load.asm \
	src/game/rooms/persistent_state_save.asm src/preservation/prg_fe31_ffff.asm \
	src/memory/hardware.inc src/memory/ram.inc

GHIDRA_FACTS := build/ghidra/instructions.tsv
SYMBOLS := config/symbols.json
MEMORY_SYMBOLS := config/memory_symbols.json
OPERAND_OVERRIDES := config/operand_overrides.json
SOURCE_LAYOUT := config/source_layout.json
FCEUX := tools/fceux/fceux64.exe
RUNTIME_DIR := build/runtime
BOOT_CDL := $(RUNTIME_DIR)/boot-gameplay.cdl
BOOT_METADATA := $(RUNTIME_DIR)/boot-gameplay.txt
BOOT_REPORT := $(RUNTIME_DIR)/boot-gameplay.json
TITLE_CDL := $(RUNTIME_DIR)/title-demo.cdl
TITLE_METADATA := $(RUNTIME_DIR)/title-demo.txt
TITLE_REPORT := $(RUNTIME_DIR)/title-demo.json
TIMEOUT_CDL := $(RUNTIME_DIR)/idle-timeout.cdl
TIMEOUT_METADATA := $(RUNTIME_DIR)/idle-timeout.txt
TIMEOUT_REPORT := $(RUNTIME_DIR)/idle-timeout.json
RUNTIME_CDL := $(RUNTIME_DIR)/suite.cdl
RUNTIME_REPORT := $(RUNTIME_DIR)/suite.json
RUNTIME_EVIDENCE := config/runtime_evidence.txt
PRG_DATA_RANGES := config/prg_data_ranges.txt
BOOT_FRAMES ?= 900
TITLE_FRAMES ?= 1800
TIMEOUT_FRAMES ?= 15000

.PHONY: all build split verify verify-reference verify-built verify-header \
	verify-prg verify-chr verify-payload verify-rom verify-assets check-assets \
	rom-info rom-info-reference rom-info-built inspect format format-check lint \
	lint-asm lint-source lint-project test quality-check scaffold-check \
	release-check check rooms validate-rooms audio validate-audio clean \
	reconstruction-audit \
	ghidra-bootstrap ghidra-status ghidra-inspect ghidra-analyze disassemble \
	disassembly-check fceux-bootstrap fceux-status trace-boot trace-title \
	trace-timeout trace-suite runtime-merge runtime-check runtime-promote \
	reconstruction-check screen-data validate-screen-data validate-input \
	startup-state validate-startup nmi-state validate-nmi oam-state validate-oam \
	status-state validate-status room-row-state validate-room-rows \
	attribute-upload-state validate-attribute-upload castle-map-state \
	validate-castle-map data-io-state validate-data-io save-data \
	validate-save-data

all: verify

$(BUILD_DIR):
	$(PYTHON) scripts/project.py mkdir --path "$(BUILD_DIR)"

$(CHR_ASSET):
	$(PYTHON) scripts/project.py require --path "$@" --hint "run 'make split' first"

$(PRG_ASSET):
	$(PYTHON) scripts/project.py require --path "$@" --hint "run 'make split' first"

$(OBJECT): $(SOURCE_FILES) $(CHR_ASSET) | $(BUILD_DIR)
	$(CA65) --debug-info -g -o "$@" -l "$(BUILD_DIR)/castle_excellent.lst" "src/main.asm"

$(ROM): $(OBJECT) config/linker/cnrom.cfg
	$(LD65) -C config/linker/cnrom.cfg -o "$@" "$<" -Ln "$(LABELS)" -m "$(MAP)" --dbgfile "$(DEBUG)"

build: $(ROM)

verify-reference:
	$(PYTHON) scripts/project.py verify --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)"

verify-built: $(ROM)
	$(PYTHON) scripts/project.py verify --image "$(ROM)" --manifest "$(MANIFEST)"

verify-header: $(ROM)
	$(PYTHON) "$(VERIFY_ROM)" compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region header

verify-prg: $(ROM)
	$(PYTHON) "$(VERIFY_ROM)" compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region prg

verify-chr: $(ROM)
	$(PYTHON) "$(VERIFY_ROM)" compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region chr

verify-payload: $(ROM)
	$(PYTHON) "$(VERIFY_ROM)" compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region payload

verify-rom: $(ROM)
	$(PYTHON) "$(VERIFY_ROM)" compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region rom

verify-assets: $(CHR_ASSET)
	$(PYTHON) "$(VERIFY_ROM)" asset --asset "$(CHR_ASSET)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region chr

check-assets: verify-assets

verify: verify-reference verify-built verify-header verify-prg verify-chr verify-payload verify-rom verify-assets

split:
	$(PYTHON) scripts/project.py split --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --output-dir "$(GENERATED_ASSET_DIR)"

rom-info-reference:
	$(PYTHON) "$(VERIFY_ROM)" report --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)"

rom-info-built: $(ROM)
	$(PYTHON) "$(VERIFY_ROM)" report --image "$(ROM)" --manifest "$(MANIFEST)"

rom-info: rom-info-reference rom-info-built

inspect: rom-info-reference

format:
	$(PYTHON) scripts/asm_style.py --fix src
	$(PYTHON) scripts/format_project.py write
	$(MAKE) lint

format-check: lint-asm

lint-asm:
	$(PYTHON) scripts/asm_style.py src

lint-source:
	$(PYTHON) scripts/format_project.py check
	$(PYTHON) scripts/project.py lint

lint-project: lint-source

lint: lint-asm lint-source

test:
	$(PYTHON) -m unittest discover -s tests -v

quality-check: lint test

scaffold-check: quality-check

reconstruction-audit:
	$(PYTHON) scripts/source_reconstruction.py --layout "$(SOURCE_LAYOUT)"

ghidra-bootstrap:
	$(PYTHON) scripts/bootstrap_ghidra.py install

ghidra-status:
	$(PYTHON) scripts/bootstrap_ghidra.py status

ghidra-inspect: ghidra-bootstrap
	$(PYTHON) scripts/run_ghidra.py inspect --image "$(REFERENCE_ROM)" --output build/ghidra/program.json

ghidra-analyze: ghidra-bootstrap
	$(PYTHON) scripts/run_ghidra.py export-facts --image "$(REFERENCE_ROM)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --data-ranges "$(PRG_DATA_RANGES)" --output "$(GHIDRA_FACTS)"

disassemble: ghidra-analyze $(PRG_ASSET)
	$(PYTHON) scripts/generate_disassembly.py write --prg "$(PRG_ASSET)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --memory-symbols "$(MEMORY_SYMBOLS)" --operand-overrides "$(OPERAND_OVERRIDES)" --layout "$(SOURCE_LAYOUT)"

disassembly-check: ghidra-analyze $(PRG_ASSET)
	$(PYTHON) scripts/generate_disassembly.py check --prg "$(PRG_ASSET)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --memory-symbols "$(MEMORY_SYMBOLS)" --operand-overrides "$(OPERAND_OVERRIDES)" --layout "$(SOURCE_LAYOUT)"

fceux-bootstrap:
	$(PYTHON) scripts/bootstrap_fceux.py install

fceux-status:
	$(PYTHON) scripts/bootstrap_fceux.py status

trace-boot: fceux-bootstrap ghidra-analyze
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(REFERENCE_ROM)" --lua scripts/capture_boot_cdl.lua --frames "$(BOOT_FRAMES)" --scenario boot-gameplay --cdl "$(BOOT_CDL)" --metadata "$(BOOT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(BOOT_REPORT)"

trace-title: fceux-bootstrap ghidra-analyze
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(REFERENCE_ROM)" --lua scripts/capture_title_demo_cdl.lua --frames "$(TITLE_FRAMES)" --scenario title-demo --cdl "$(TITLE_CDL)" --metadata "$(TITLE_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TITLE_REPORT)"

trace-timeout: fceux-bootstrap ghidra-analyze
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(REFERENCE_ROM)" --lua scripts/capture_timeout_cdl.lua --frames "$(TIMEOUT_FRAMES)" --scenario idle-timeout --cdl "$(TIMEOUT_CDL)" --metadata "$(TIMEOUT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TIMEOUT_REPORT)"

runtime-merge:
	$(PYTHON) scripts/runtime_coverage.py merge --cdl "$(BOOT_CDL)" --cdl "$(TITLE_CDL)" --cdl "$(TIMEOUT_CDL)" --output "$(RUNTIME_CDL)"
	$(PYTHON) scripts/runtime_coverage.py analyze --scenario suite --cdl "$(RUNTIME_CDL)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(RUNTIME_REPORT)"

trace-suite: trace-boot trace-title trace-timeout
	$(MAKE) runtime-merge

runtime-check:
	$(PYTHON) scripts/runtime_coverage.py analyze --scenario suite --cdl "$(RUNTIME_CDL)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(RUNTIME_REPORT)"

runtime-promote:
	$(PYTHON) scripts/runtime_coverage.py promote-evidence --cdl "$(RUNTIME_CDL)" --manifest "$(MANIFEST)" --output "$(RUNTIME_EVIDENCE)"

rooms: $(ROM)
	$(PYTHON) scripts/room_data.py --image "$(ROM)" --pretty

validate-rooms: $(ROM)
	$(PYTHON) scripts/room_data.py --image "$(ROM)" --validate

audio: $(ROM)
	$(PYTHON) scripts/audio_data.py --image "$(ROM)" --pretty

validate-audio: $(ROM)
	$(PYTHON) scripts/audio_data.py --image "$(ROM)" --validate

screen-data: $(ROM)
	$(PYTHON) scripts/room_screen_data.py --image "$(ROM)" --pretty

validate-screen-data: $(ROM)
	$(PYTHON) scripts/room_screen_data.py --image "$(ROM)" --validate

validate-input:
	$(PYTHON) scripts/controller_input.py --validate

startup-state: $(ROM)
	$(PYTHON) scripts/startup_state.py --image "$(ROM)" --pretty

validate-startup: $(ROM)
	$(PYTHON) scripts/startup_state.py --image "$(ROM)" --validate

nmi-state: $(ROM)
	$(PYTHON) scripts/nmi_scheduler.py --image "$(ROM)" --pretty

validate-nmi: $(ROM)
	$(PYTHON) scripts/nmi_scheduler.py --image "$(ROM)" --validate

oam-state: $(ROM)
	$(PYTHON) scripts/oam_dma.py --image "$(ROM)" --pretty

validate-oam: $(ROM)
	$(PYTHON) scripts/oam_dma.py --image "$(ROM)" --validate

status-state: $(ROM)
	$(PYTHON) scripts/status_upload.py --image "$(ROM)" --pretty

validate-status: $(ROM)
	$(PYTHON) scripts/status_upload.py --image "$(ROM)" --validate

room-row-state: $(ROM)
	$(PYTHON) scripts/room_row_upload.py --image "$(ROM)" --pretty

validate-room-rows: $(ROM)
	$(PYTHON) scripts/room_row_upload.py --image "$(ROM)" --validate

attribute-upload-state: $(ROM)
	$(PYTHON) scripts/room_attribute_upload.py --image "$(ROM)" --pretty

validate-attribute-upload: $(ROM)
	$(PYTHON) scripts/room_attribute_upload.py --image "$(ROM)" --validate

castle-map-state:
	$(PYTHON) scripts/castle_map.py --pretty

validate-castle-map:
	$(PYTHON) scripts/castle_map.py --validate

data-io-state:
	$(PYTHON) scripts/famicom_data_io.py --pretty

validate-data-io:
	$(PYTHON) scripts/famicom_data_io.py --validate

save-data: $(ROM)
	$(PYTHON) scripts/save_data.py --image "$(ROM)" --pretty

validate-save-data: $(ROM)
	$(PYTHON) scripts/save_data.py --image "$(ROM)" --validate

release-check: quality-check reconstruction-audit disassembly-check verify validate-rooms validate-audio validate-screen-data validate-input validate-startup validate-nmi validate-oam validate-status validate-room-rows validate-attribute-upload validate-castle-map validate-data-io validate-save-data

check: release-check

reconstruction-check: check trace-suite

clean:
	$(PYTHON) scripts/project.py clean --path build
