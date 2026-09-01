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
	src/game/objects/runtime_record_offsets.asm src/preservation/prg_8f29_949b.asm \
	src/rendering/room_cell_updates.asm src/game/x_coordinates.asm \
	src/game/rooms/finish_transition.asm src/game/collision/cell_samples.asm \
	src/system/nmi_tasks.asm src/game/objects/update_dispatch.asm \
	src/preservation/prg_9613_a2b0.asm src/game/new_game.asm \
	src/rendering/room_palette.asm \
	src/game/rooms/load_room.asm src/game/rooms/runtime_reset.asm \
	src/game/rooms/cell_animation.asm src/rendering/status_format.asm \
	src/data/unreferenced_bit_index_helper.asm \
	src/game/rooms/cell_coordinates.asm src/game/rooms/mutable_cell_actions.asm \
	src/game/rooms/mutable_cell_lookup.asm src/game/collision/cell_pair_index.asm \
	src/game/rooms/mutable_cell_predicates.asm \
	src/game/rooms/mutable_cell_restore.asm src/game/rooms/navigation.asm \
	src/game/player/hazard_state.asm src/game/objects/player_proximity.asm \
	src/input/pause.asm src/preservation/prg_a95a_ab49.asm \
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
STATIC_CODE_EVIDENCE := config/static_code_evidence.txt
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
	validate-save-data room-cell-state validate-room-cells x-coordinate-state \
	validate-x-coordinates transition-state validate-transition \
	collision-state validate-collision object-dispatch-state \
	validate-object-dispatch new-game-state validate-new-game \
	room-runtime-state validate-room-runtime room-cell-animation-state \
	validate-room-cell-animation hud-format-state validate-hud-format \
	mutable-cell-action-state validate-mutable-cell-actions \
	room-navigation-state validate-room-navigation \
	player-hazard-state validate-player-hazard object-player-proximity \
	validate-object-player-proximity pause-input-state validate-pause-input

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
	$(PYTHON) scripts/run_ghidra.py export-facts --image "$(REFERENCE_ROM)" --static-evidence "$(STATIC_CODE_EVIDENCE)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --data-ranges "$(PRG_DATA_RANGES)" --output "$(GHIDRA_FACTS)"

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

room-cell-state:
	$(PYTHON) scripts/room_cell_coordinates.py --pretty

validate-room-cells:
	$(PYTHON) scripts/room_cell_coordinates.py --validate

x-coordinate-state:
	$(PYTHON) scripts/x_coordinates.py --pretty

validate-x-coordinates:
	$(PYTHON) scripts/x_coordinates.py --validate

transition-state:
	$(PYTHON) scripts/room_transition.py --pretty

validate-transition:
	$(PYTHON) scripts/room_transition.py --validate

collision-state:
	$(PYTHON) scripts/collision_cells.py --pretty

validate-collision:
	$(PYTHON) scripts/collision_cells.py --validate

object-dispatch-state: $(ROM)
	$(PYTHON) scripts/runtime_object_dispatch.py --image "$(ROM)" --pretty

validate-object-dispatch: $(ROM)
	$(PYTHON) scripts/runtime_object_dispatch.py --image "$(ROM)" --validate

new-game-state: $(ROM)
	$(PYTHON) scripts/new_game_state.py --image "$(ROM)" --pretty

validate-new-game: $(ROM)
	$(PYTHON) scripts/new_game_state.py --image "$(ROM)" --validate

room-runtime-state:
	$(PYTHON) scripts/room_runtime_reset.py --pretty

validate-room-runtime:
	$(PYTHON) scripts/room_runtime_reset.py --validate

room-cell-animation-state: $(ROM)
	$(PYTHON) scripts/room_cell_animation.py --image "$(ROM)" --pretty

validate-room-cell-animation: $(ROM)
	$(PYTHON) scripts/room_cell_animation.py --image "$(ROM)" --validate

hud-format-state: $(ROM)
	$(PYTHON) scripts/status_format.py --image "$(ROM)" --pretty

validate-hud-format: $(ROM)
	$(PYTHON) scripts/status_format.py --image "$(ROM)" --validate

mutable-cell-action-state: $(ROM)
	$(PYTHON) scripts/mutable_cell_actions.py --image "$(ROM)" --pretty

validate-mutable-cell-actions: $(ROM)
	$(PYTHON) scripts/mutable_cell_actions.py --image "$(ROM)" --validate

room-navigation-state: $(ROM)
	$(PYTHON) scripts/room_navigation.py --image "$(ROM)" --pretty

validate-room-navigation: $(ROM)
	$(PYTHON) scripts/room_navigation.py --image "$(ROM)" --validate

player-hazard-state: $(ROM)
	$(PYTHON) scripts/player_hazard_state.py --image "$(ROM)" --pretty

validate-player-hazard: $(ROM)
	$(PYTHON) scripts/player_hazard_state.py --image "$(ROM)" --validate

object-player-proximity: $(ROM)
	$(PYTHON) scripts/object_player_proximity.py --image "$(ROM)" --pretty

validate-object-player-proximity: $(ROM)
	$(PYTHON) scripts/object_player_proximity.py --image "$(ROM)" --validate

pause-input-state: $(ROM)
	$(PYTHON) scripts/pause_input.py --image "$(ROM)" --pretty

validate-pause-input: $(ROM)
	$(PYTHON) scripts/pause_input.py --image "$(ROM)" --validate

release-check: quality-check reconstruction-audit disassembly-check verify validate-rooms validate-audio validate-screen-data validate-input validate-startup validate-nmi validate-oam validate-status validate-room-rows validate-attribute-upload validate-castle-map validate-data-io validate-save-data validate-room-cells validate-x-coordinates validate-transition validate-collision validate-object-dispatch validate-new-game validate-room-runtime validate-room-cell-animation validate-hud-format validate-mutable-cell-actions validate-room-navigation validate-player-hazard validate-object-player-proximity validate-pause-input

check: release-check

reconstruction-check: check trace-suite

clean:
	$(PYTHON) scripts/project.py clean --path build
