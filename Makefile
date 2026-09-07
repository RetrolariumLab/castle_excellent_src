PYTHON ?= python
RUN_TOOL := $(PYTHON) scripts/run.py
CA65 ?= bin/ca65.exe
LD65 ?= bin/ld65.exe
REFERENCE_ROM ?= Castle Excellent (J).nes
MANIFEST := assets/manifest.json
SOURCE_1_MANIFEST := config/source_reconstruction_1_0.json
SOURCE_2_MANIFEST := config/source_reconstruction_2_0.json
REVISION_MANIFEST := config/revision_profiles.json
REVISION_PROFILE ?= castlequest-usa
LEVEL_AUTHORING := config/level_authoring.json
AUDIO_AUTHORING := config/audio_authoring.json
GRAPHICS_AUTHORING := config/graphics_authoring.json
LEVEL_PLAYTEST_ROOM ?= 71
LEVEL_PLAYTEST_X ?= 16
LEVEL_PLAYTEST_Y ?= 152
LEVEL_PLAYTEST_RESULT := build/authoring/$(REVISION_PROFILE)/level_playtest.txt
FIXED_LAYOUT_MANIFEST := config/fixed_layout_variants.json
FIXED_LAYOUT_VARIANT ?= start-room-1
FIXED_LAYOUT_RESULT := build/variants/$(FIXED_LAYOUT_VARIANT)/runtime.txt
CASTLEQUEST_RUNTIME_RESULT := build/revisions/castlequest-usa/runtime.txt
VERIFY_ROM := $(RUN_TOOL) build.verify_rom

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
SOURCE_FILES := src/main.asm src/system/famicom_platform.asm src/graphics/chr.asm \
	src/game/player/input_and_movement.asm src/game/player/transitions_and_push.asm \
	src/game/objects/lifts/linked_control.asm \
	src/game/collectibles/pickups_and_rewards.asm \
	src/game/collision/player_pipeline.asm src/game/runtime/frame_pipeline.asm \
	src/game/objects/lifts/movement.asm src/game/objects/enemies/patrol.asm \
	src/game/objects/enemies/special.asm src/game/collision/sampling.asm \
	src/game/session_initialization.asm src/game/rooms/mutable_cells.asm \
	src/game/rooms/navigation_and_rules.asm src/rendering/sprites/frame.asm \
	src/rendering/sprites/selectors.asm src/rendering/sprites/metasprites.asm \
	src/rendering/scenes.asm src/audio/music_engine.asm src/audio/sound_effects.asm \
	src/rendering/frame_pipeline.asm src/rendering/room_rows/top.asm \
	src/rendering/room_rows/upper_middle.asm \
	src/rendering/room_rows/lower_middle.asm src/rendering/room_rows/bottom.asm \
	src/rendering/rooms/upload_and_decode.asm \
	src/rendering/rooms/attributes_and_map.asm src/game/rooms/load_pipeline.asm \
	src/game/rooms/state_and_data.asm src/ui/title_and_subcommands.asm \
	src/game/persistence_and_endings.asm src/system/prg_tail.asm \
	src/memory/hardware.inc src/revisions/profile.inc src/memory/ram.inc

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
TRANSITION_CDL := $(RUNTIME_DIR)/room-transition.cdl
TRANSITION_METADATA := $(RUNTIME_DIR)/room-transition.txt
TRANSITION_REPORT := $(RUNTIME_DIR)/room-transition.json
DEATH_CDL := $(RUNTIME_DIR)/death-game-over.cdl
DEATH_METADATA := $(RUNTIME_DIR)/death-game-over.txt
DEATH_REPORT := $(RUNTIME_DIR)/death-game-over.json
ENDING_CDL := $(RUNTIME_DIR)/completion-ending.cdl
ENDING_METADATA := $(RUNTIME_DIR)/completion-ending.txt
ENDING_REPORT := $(RUNTIME_DIR)/completion-ending.json
SAVE_LOAD_CDL := $(RUNTIME_DIR)/save-load-entry.cdl
SAVE_LOAD_METADATA := $(RUNTIME_DIR)/save-load-entry.txt
SAVE_LOAD_REPORT := $(RUNTIME_DIR)/save-load-entry.json
RUNTIME_CDL := $(RUNTIME_DIR)/suite.cdl
RUNTIME_REPORT := $(RUNTIME_DIR)/suite.json
SOURCE_1_RUNTIME_CDL := $(RUNTIME_DIR)/source-1-suite.cdl
SOURCE_1_RUNTIME_REPORT := $(RUNTIME_DIR)/source-1-suite.json
STATIC_CODE_EVIDENCE := config/static_code_evidence.txt
RUNTIME_EVIDENCE := config/runtime_evidence.txt
PRG_DATA_RANGES := config/prg_data_ranges.txt
FALSE_INSTRUCTION_STARTS := config/false_instruction_starts.txt
BOOT_FRAMES ?= 900
TITLE_FRAMES ?= 1800
TIMEOUT_FRAMES ?= 15000

.PHONY: all build split verify verify-reference verify-built verify-header \
	verify-prg verify-chr verify-payload verify-rom verify-assets check-assets \
	rom-info rom-info-reference rom-info-built inspect format format-check lint \
	lint-asm lint-source lint-project test quality-check scaffold-check \
	release-check check rooms validate-rooms audio validate-audio clean \
	reconstruction-audit release-audit build-toolchain-status static-release-check trace \
	source-1-check source-1-pre-tag-check source-1-tag-check \
	source-2-audit source-2-authoring-check-profile source-2-check \
	source-2-pre-tag-check source-2-tag-check \
	split-profile build-profile verify-profile castlequest-check castlequest-runtime \
	init-levels export-levels validate-levels build-levels roundtrip-levels \
	level-studio level-editor check-level-studio \
	smoke-level-playtest smoke-baseline-level-playtest \
	build-fixed-layout verify-fixed-layout check-fixed-layout \
	init-music export-music validate-music build-music roundtrip-music \
	sound-studio music-editor check-sound-studio \
	init-graphics export-graphics validate-graphics build-graphics roundtrip-graphics \
	graphics-studio check-graphics-studio \
	editor-quality-check-profile editor-quality-check editor-ui-smoke-profile \
	symbols validate-symbols \
	ghidra-bootstrap ghidra-status ghidra-inspect ghidra-analyze disassemble \
	disassembly-check fceux-bootstrap fceux-status trace-boot trace-title \
	trace-timeout trace-suite trace-release-paths trace-source-1 \
	runtime-merge runtime-check runtime-promote \
	reconstruction-check screen-data validate-screen-data validate-input \
	startup-state validate-startup nmi-state validate-nmi oam-state validate-oam \
	status-state validate-status room-row-state validate-room-rows \
	attribute-upload-state validate-attribute-upload castle-map-state \
	validate-castle-map data-io-state validate-data-io save-data \
	validate-save-data room-cell-state validate-room-cells x-coordinate-state \
	validate-x-coordinates transition-state validate-transition \
	collision-state validate-collision object-dispatch-state \
	validate-object-dispatch player-object-span validate-player-object-span \
	transient-object-state validate-transient-objects \
	object-collision-filters validate-object-collision-filters \
	collision-point-sample validate-collision-point-sample \
	room-collision-sample validate-room-collision-sample \
	runtime-overlap-state validate-runtime-overlap \
	new-game-state validate-new-game \
	room-runtime-state validate-room-runtime room-cell-animation-state \
	validate-room-cell-animation hud-format-state validate-hud-format \
	mutable-cell-action-state validate-mutable-cell-actions \
	room-navigation-state validate-room-navigation \
	player-input-movement validate-player-input-movement \
	player-object-push validate-player-object-push \
	room-boundary-transitions validate-room-boundary-transitions \
	room-cell-sample-address validate-room-cell-sample-address \
	player-death-transition validate-player-death-transition \
	player-collision-sample validate-player-collision-sample \
	player-collision-update validate-player-collision-update \
	player-collision-dispatch validate-player-collision-dispatch \
	player-transition-reload validate-player-transition-reload \
	room-object-state-save validate-room-object-state-save \
	player-animated-cell-displacement validate-player-animated-cell-displacement \
	collectible-collision-handlers validate-collectible-collision-handlers \
	inventory-collectible-handlers validate-inventory-collectible-handlers \
	score-award validate-score-award \
	runtime-type9f-collision validate-runtime-type9f-collision \
	runtime-types81-82-collision validate-runtime-types81-82-collision \
	unreferenced-nmi-task-bytes validate-unreferenced-nmi-task-bytes \
	unreferenced-object-clear-tail validate-unreferenced-object-clear-tail \
	unreferenced-runtime-only-sample validate-unreferenced-runtime-only-sample \
	title-sub-command validate-title-sub-command \
	demo-playback validate-demo-playback \
	audio-track-selection validate-audio-track-selection \
	audio-stream-engine validate-audio-stream-engine \
	sound-effect-engine validate-sound-effect-engine \
	scroll-math-palette validate-scroll-math-palette \
	end-sequences validate-end-sequences \
	prg-tail-data validate-prg-tail-data \
	palette-data validate-palette-data \
	player-hazard-state validate-player-hazard object-player-proximity \
	validate-object-player-proximity pause-input-state validate-pause-input \
	collision-table-state validate-collision-tables \
	collision-handler-tables validate-collision-handler-tables \
	frame-sprite-state validate-frame-sprites \
	metasprite-state validate-metasprites object-catalog validate-object-catalog

all: verify

$(BUILD_DIR):
	$(RUN_TOOL) build.project mkdir --path "$(BUILD_DIR)"

$(CHR_ASSET):
	$(RUN_TOOL) build.project require --path "$@" --hint "run 'make split' first"

$(PRG_ASSET):
	$(RUN_TOOL) build.project require --path "$@" --hint "run 'make split' first"

$(OBJECT): $(SOURCE_FILES) $(CHR_ASSET) | $(BUILD_DIR) build-toolchain-status
	$(CA65) --debug-info -g -o "$@" -l "$(BUILD_DIR)/castle_excellent.lst" "src/main.asm"

$(ROM): $(OBJECT) config/linker/cnrom.cfg
	$(LD65) -C config/linker/cnrom.cfg -o "$@" "$<" -Ln "$(LABELS)" -m "$(MAP)" --dbgfile "$(DEBUG)"

build: $(ROM)

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

init-levels: verify-profile
	$(RUN_TOOL) authoring.level_editor init --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

export-levels: verify-profile
	$(RUN_TOOL) authoring.level_editor export --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

validate-levels: verify-profile
	$(RUN_TOOL) authoring.level_editor validate --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

build-levels: verify-profile
	$(RUN_TOOL) authoring.level_editor build --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

roundtrip-levels: verify-profile
	$(RUN_TOOL) authoring.level_editor roundtrip --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

level-studio: init-levels
	$(RUN_TOOL) authoring.level_studio --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

level-editor: level-studio

check-level-studio: verify-profile
	$(RUN_TOOL) authoring.level_studio --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

smoke-level-playtest: fceux-bootstrap build-levels
	$(RUN_TOOL) runtime.level_playtest --fceux "$(FCEUX)" --rom "build/authoring/$(REVISION_PROFILE)/levels.nes" --lua scripts/runtime/level_playtest.lua --room "$(LEVEL_PLAYTEST_ROOM)" --player-x "$(LEVEL_PLAYTEST_X)" --player-y "$(LEVEL_PLAYTEST_Y)" --result "$(LEVEL_PLAYTEST_RESULT)" --check

smoke-baseline-level-playtest: fceux-bootstrap verify-profile
	$(RUN_TOOL) runtime.level_playtest --fceux "$(FCEUX)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --lua scripts/runtime/level_playtest.lua --room "$(LEVEL_PLAYTEST_ROOM)" --player-x "$(LEVEL_PLAYTEST_X)" --player-y "$(LEVEL_PLAYTEST_Y)" --result "$(LEVEL_PLAYTEST_RESULT)" --check

build-fixed-layout: build
	$(RUN_TOOL) build.fixed_layout_variant build --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)"

verify-fixed-layout: build
	$(RUN_TOOL) build.fixed_layout_variant verify --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)"

check-fixed-layout: fceux-bootstrap build
	$(RUN_TOOL) build.fixed_layout_variant runtime --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)" --fceux "$(FCEUX)" --lua scripts/runtime/validate_fixed_layout.lua --result "$(FIXED_LAYOUT_RESULT)"

init-music: verify-profile
	$(RUN_TOOL) authoring.music_editor init --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

export-music: verify-profile
	$(RUN_TOOL) authoring.music_editor export --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

validate-music: verify-profile
	$(RUN_TOOL) authoring.music_editor validate --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

build-music: verify-profile
	$(RUN_TOOL) authoring.music_editor build --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

roundtrip-music: verify-profile
	$(RUN_TOOL) authoring.music_editor roundtrip --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

sound-studio: init-music
	$(RUN_TOOL) authoring.sound_studio --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

music-editor: sound-studio

check-sound-studio: verify-profile
	$(RUN_TOOL) authoring.sound_studio --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

init-graphics: verify-profile
	$(RUN_TOOL) authoring.graphics_editor init --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

export-graphics: verify-profile
	$(RUN_TOOL) authoring.graphics_editor export --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

validate-graphics: verify-profile
	$(RUN_TOOL) authoring.graphics_editor validate --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

build-graphics: verify-profile
	$(RUN_TOOL) authoring.graphics_editor build --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

roundtrip-graphics: verify-profile
	$(RUN_TOOL) authoring.graphics_editor roundtrip --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

graphics-studio: init-graphics
	$(RUN_TOOL) authoring.graphics_studio --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

check-graphics-studio: verify-profile
	$(RUN_TOOL) authoring.graphics_studio --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

editor-quality-check-profile: verify-profile
	$(RUN_TOOL) authoring.level_editor roundtrip --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(RUN_TOOL) authoring.level_studio --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(RUN_TOOL) authoring.music_editor roundtrip --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(RUN_TOOL) authoring.sound_studio --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(RUN_TOOL) authoring.graphics_editor roundtrip --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(RUN_TOOL) authoring.graphics_studio --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

editor-quality-check:
	$(MAKE) lint
	$(PYTHON) -m unittest tests.test_level_studio_model tests.test_sound_studio_model tests.test_graphics_studio_model
	$(MAKE) editor-quality-check-profile REVISION_PROFILE=castle-excellent-japan-hsp-05
	$(MAKE) editor-quality-check-profile REVISION_PROFILE=castlequest-usa

editor-ui-smoke-profile: init-levels init-music init-graphics
	$(RUN_TOOL) authoring.level_studio --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --smoke-ui
	$(RUN_TOOL) authoring.sound_studio --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --smoke-ui
	$(RUN_TOOL) authoring.graphics_studio --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --smoke-ui

symbols: $(ROM)
	$(RUN_TOOL) validation.debug_symbols --debug "$(DEBUG)" --map "$(MAP)" --labels "$(LABELS)" --rom "$(ROM)" --output-dir "$(BUILD_DIR)" --breakpoints config/debugger_breakpoints.json --watches config/debugger_watches.json --source-layout "$(SOURCE_LAYOUT)" --summary "$(DEBUG_SUMMARY)"

validate-symbols: fceux-bootstrap symbols
	$(RUN_TOOL) runtime.validate_debug_runtime --fceux "$(FCEUX)" --rom "$(ROM)" --lua scripts/runtime/validate_debug_symbols.lua --result "$(DEBUG_RUNTIME_RESULT)"

verify-reference:
	$(RUN_TOOL) build.project verify --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)"

verify-built: $(ROM)
	$(RUN_TOOL) build.project verify --image "$(ROM)" --manifest "$(MANIFEST)"

verify-header: $(ROM)
	$(VERIFY_ROM) compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region header

verify-prg: $(ROM)
	$(VERIFY_ROM) compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region prg

verify-chr: $(ROM)
	$(VERIFY_ROM) compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region chr

verify-payload: $(ROM)
	$(VERIFY_ROM) compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region payload

verify-rom: $(ROM)
	$(VERIFY_ROM) compare --built "$(ROM)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region rom

verify-assets: $(CHR_ASSET)
	$(VERIFY_ROM) asset --asset "$(CHR_ASSET)" --reference "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --region chr

check-assets: verify-assets

verify: verify-reference verify-built verify-header verify-prg verify-chr verify-payload verify-rom verify-assets

split:
	$(RUN_TOOL) build.project split --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)" --output-dir "$(GENERATED_ASSET_DIR)"

rom-info-reference:
	$(VERIFY_ROM) report --image "$(REFERENCE_ROM)" --manifest "$(MANIFEST)"

rom-info-built: $(ROM)
	$(VERIFY_ROM) report --image "$(ROM)" --manifest "$(MANIFEST)"

rom-info: rom-info-reference rom-info-built

inspect: rom-info-reference

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

lint-project: lint-source

lint: lint-asm lint-source

test: ghidra-analyze
	$(PYTHON) -m unittest discover -s tests -v

quality-check: lint test

scaffold-check: quality-check

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

source-2-authoring-check-profile: verify-profile
	$(RUN_TOOL) authoring.level_editor roundtrip --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(RUN_TOOL) authoring.level_studio --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(RUN_TOOL) authoring.music_editor roundtrip --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(RUN_TOOL) authoring.sound_studio --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(RUN_TOOL) authoring.graphics_editor roundtrip --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(RUN_TOOL) authoring.graphics_studio --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

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

trace-boot: fceux-bootstrap ghidra-analyze $(ROM)
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_boot_cdl.lua --frames "$(BOOT_FRAMES)" --scenario boot-gameplay --cdl "$(BOOT_CDL)" --metadata "$(BOOT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(BOOT_REPORT)"

trace-title: fceux-bootstrap ghidra-analyze $(ROM)
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_title_demo_cdl.lua --frames "$(TITLE_FRAMES)" --scenario title-demo --cdl "$(TITLE_CDL)" --metadata "$(TITLE_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TITLE_REPORT)"

trace-timeout: fceux-bootstrap ghidra-analyze $(ROM)
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_timeout_cdl.lua --frames "$(TIMEOUT_FRAMES)" --scenario idle-timeout --cdl "$(TIMEOUT_CDL)" --metadata "$(TIMEOUT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TIMEOUT_REPORT)"

trace-release-paths: fceux-bootstrap ghidra-analyze symbols
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_release_paths_cdl.lua --frames 1200 --scenario room-transition --runtime-scenario room-transition --required-hook TransitionToRoomAbove --required-hook LoadRoom --required-hook FinishRoomTransition --cdl "$(TRANSITION_CDL)" --metadata "$(TRANSITION_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TRANSITION_REPORT)"
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_release_paths_cdl.lua --frames 1800 --scenario death-game-over --runtime-scenario death-game-over --required-hook StartPlayerDeathTransition --required-hook CompletePlayerTransition --required-hook RunGameOverSequence --cdl "$(DEATH_CDL)" --metadata "$(DEATH_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(DEATH_REPORT)"
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_release_paths_cdl.lua --frames 1400 --scenario completion-ending --runtime-scenario completion-ending --required-hook HandleRuntimeType82PlayerCollision --required-hook RunType82CompletionSequence --cdl "$(ENDING_CDL)" --metadata "$(ENDING_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(ENDING_REPORT)"
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_release_paths_cdl.lua --frames 1600 --scenario save-load-entry --runtime-scenario save-load-entry --required-hook OpenSubCommandMenu --required-hook SaveGameState --required-hook SendSaveDataSignature --required-hook LoadGameState --required-hook HandleLoadFailure --cdl "$(SAVE_LOAD_CDL)" --metadata "$(SAVE_LOAD_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(SAVE_LOAD_REPORT)"

runtime-merge:
	$(RUN_TOOL) runtime.runtime_coverage merge --cdl "$(BOOT_CDL)" --cdl "$(TITLE_CDL)" --cdl "$(TIMEOUT_CDL)" --output "$(RUNTIME_CDL)"
	$(RUN_TOOL) runtime.runtime_coverage analyze --scenario suite --cdl "$(RUNTIME_CDL)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(RUNTIME_REPORT)"

trace-suite: trace-boot trace-title trace-timeout
	$(MAKE) runtime-merge

trace-source-1: trace-suite trace-release-paths
	$(RUN_TOOL) runtime.runtime_coverage merge --cdl "$(BOOT_CDL)" --cdl "$(TITLE_CDL)" --cdl "$(TIMEOUT_CDL)" --cdl "$(TRANSITION_CDL)" --cdl "$(DEATH_CDL)" --cdl "$(ENDING_CDL)" --cdl "$(SAVE_LOAD_CDL)" --output "$(SOURCE_1_RUNTIME_CDL)"
	$(RUN_TOOL) runtime.runtime_coverage analyze --scenario source-1-suite --cdl "$(SOURCE_1_RUNTIME_CDL)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(SOURCE_1_RUNTIME_REPORT)"

trace: trace-source-1

runtime-check:
	$(RUN_TOOL) runtime.runtime_coverage analyze --scenario suite --cdl "$(RUNTIME_CDL)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(RUNTIME_REPORT)"

runtime-promote:
	$(RUN_TOOL) runtime.runtime_coverage promote-evidence --cdl "$(RUNTIME_CDL)" --manifest "$(MANIFEST)" --output "$(RUNTIME_EVIDENCE)"

rooms: $(ROM)
	$(RUN_TOOL) authoring.room_data --image "$(ROM)" --pretty

validate-rooms: $(ROM)
	$(RUN_TOOL) authoring.room_data --image "$(ROM)" --validate

audio: $(ROM)
	$(RUN_TOOL) authoring.audio_data --image "$(ROM)" --pretty

validate-audio: $(ROM)
	$(RUN_TOOL) authoring.audio_data --image "$(ROM)" --validate

screen-data: $(ROM)
	$(RUN_TOOL) validation.rooms.room_screen_data --image "$(ROM)" --pretty

validate-screen-data: $(ROM)
	$(RUN_TOOL) validation.rooms.room_screen_data --image "$(ROM)" --validate

validate-input:
	$(RUN_TOOL) validation.gameplay.controller_input --validate

startup-state: $(ROM)
	$(RUN_TOOL) validation.gameplay.startup_state --image "$(ROM)" --pretty

validate-startup: $(ROM)
	$(RUN_TOOL) validation.gameplay.startup_state --image "$(ROM)" --validate

nmi-state: $(ROM)
	$(RUN_TOOL) validation.system.nmi_scheduler --image "$(ROM)" --pretty

validate-nmi: $(ROM)
	$(RUN_TOOL) validation.system.nmi_scheduler --image "$(ROM)" --validate

oam-state: $(ROM)
	$(RUN_TOOL) validation.system.oam_dma --image "$(ROM)" --pretty

validate-oam: $(ROM)
	$(RUN_TOOL) validation.system.oam_dma --image "$(ROM)" --validate

status-state: $(ROM)
	$(RUN_TOOL) validation.system.status_upload --image "$(ROM)" --pretty

validate-status: $(ROM)
	$(RUN_TOOL) validation.system.status_upload --image "$(ROM)" --validate

room-row-state: $(ROM)
	$(RUN_TOOL) validation.rooms.room_row_upload --image "$(ROM)" --pretty

validate-room-rows: $(ROM)
	$(RUN_TOOL) validation.rooms.room_row_upload --image "$(ROM)" --validate

attribute-upload-state: $(ROM)
	$(RUN_TOOL) validation.rooms.room_attribute_upload --image "$(ROM)" --pretty

validate-attribute-upload: $(ROM)
	$(RUN_TOOL) validation.rooms.room_attribute_upload --image "$(ROM)" --validate

castle-map-state:
	$(RUN_TOOL) validation.rooms.castle_map --pretty

validate-castle-map:
	$(RUN_TOOL) validation.rooms.castle_map --validate

data-io-state:
	$(RUN_TOOL) validation.gameplay.famicom_data_io --pretty

validate-data-io:
	$(RUN_TOOL) validation.gameplay.famicom_data_io --validate

save-data: $(ROM)
	$(RUN_TOOL) validation.gameplay.save_data --image "$(ROM)" --pretty

validate-save-data: $(ROM)
	$(RUN_TOOL) validation.gameplay.save_data --image "$(ROM)" --validate

room-cell-state:
	$(RUN_TOOL) validation.rooms.room_cell_coordinates --pretty

validate-room-cells:
	$(RUN_TOOL) validation.rooms.room_cell_coordinates --validate

x-coordinate-state:
	$(RUN_TOOL) validation.player.x_coordinates --pretty

validate-x-coordinates:
	$(RUN_TOOL) validation.player.x_coordinates --validate

transition-state:
	$(RUN_TOOL) validation.rooms.room_transition --pretty

validate-transition:
	$(RUN_TOOL) validation.rooms.room_transition --validate

collision-state:
	$(RUN_TOOL) validation.collision.collision_cells --pretty

validate-collision:
	$(RUN_TOOL) validation.collision.collision_cells --validate

object-dispatch-state: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_object_dispatch --image "$(ROM)" --pretty

validate-object-dispatch: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_object_dispatch --image "$(ROM)" --validate

player-object-span: $(ROM)
	$(RUN_TOOL) validation.player.player_object_span --image "$(ROM)" --pretty

validate-player-object-span: $(ROM)
	$(RUN_TOOL) validation.player.player_object_span --image "$(ROM)" --validate

transient-object-state: $(ROM)
	$(RUN_TOOL) validation.objects.transient_object_lifecycle --image "$(ROM)" --pretty

validate-transient-objects: $(ROM)
	$(RUN_TOOL) validation.objects.transient_object_lifecycle --image "$(ROM)" --validate

object-collision-filters: $(ROM)
	$(RUN_TOOL) validation.objects.object_collision_filters --image "$(ROM)" --pretty

validate-object-collision-filters: $(ROM)
	$(RUN_TOOL) validation.objects.object_collision_filters --image "$(ROM)" --validate

collision-point-sample: $(ROM)
	$(RUN_TOOL) validation.collision.collision_point_sample --image "$(ROM)" --pretty

validate-collision-point-sample: $(ROM)
	$(RUN_TOOL) validation.collision.collision_point_sample --image "$(ROM)" --validate

room-collision-sample: $(ROM)
	$(RUN_TOOL) validation.collision.room_collision_sample --image "$(ROM)" --pretty

validate-room-collision-sample: $(ROM)
	$(RUN_TOOL) validation.collision.room_collision_sample --image "$(ROM)" --validate

runtime-overlap-state: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_object_overlap --image "$(ROM)" --pretty

validate-runtime-overlap: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_object_overlap --image "$(ROM)" --validate

new-game-state: $(ROM)
	$(RUN_TOOL) validation.gameplay.new_game_state --image "$(ROM)" --pretty

validate-new-game: $(ROM)
	$(RUN_TOOL) validation.gameplay.new_game_state --image "$(ROM)" --validate

room-runtime-state:
	$(RUN_TOOL) validation.rooms.room_runtime_reset --pretty

validate-room-runtime:
	$(RUN_TOOL) validation.rooms.room_runtime_reset --validate

room-cell-animation-state: $(ROM)
	$(RUN_TOOL) validation.rooms.room_cell_animation --image "$(ROM)" --pretty

validate-room-cell-animation: $(ROM)
	$(RUN_TOOL) validation.rooms.room_cell_animation --image "$(ROM)" --validate

hud-format-state: $(ROM)
	$(RUN_TOOL) validation.system.status_format --image "$(ROM)" --pretty

validate-hud-format: $(ROM)
	$(RUN_TOOL) validation.system.status_format --image "$(ROM)" --validate

mutable-cell-action-state: $(ROM)
	$(RUN_TOOL) validation.rooms.mutable_cell_actions --image "$(ROM)" --pretty

validate-mutable-cell-actions: $(ROM)
	$(RUN_TOOL) validation.rooms.mutable_cell_actions --image "$(ROM)" --validate

room-navigation-state: $(ROM)
	$(RUN_TOOL) validation.rooms.room_navigation --image "$(ROM)" --pretty

validate-room-navigation: $(ROM)
	$(RUN_TOOL) validation.rooms.room_navigation --image "$(ROM)" --validate

player-input-movement: $(ROM)
	$(RUN_TOOL) validation.player.player_input_movement --image "$(ROM)" --pretty

validate-player-input-movement: $(ROM)
	$(RUN_TOOL) validation.player.player_input_movement --image "$(ROM)" --validate

player-object-push: $(ROM)
	$(RUN_TOOL) validation.player.player_object_push --image "$(ROM)" --pretty

validate-player-object-push: $(ROM)
	$(RUN_TOOL) validation.player.player_object_push --image "$(ROM)" --validate

room-boundary-transitions: $(ROM)
	$(RUN_TOOL) validation.rooms.room_boundary_transitions --image "$(ROM)" --pretty

validate-room-boundary-transitions: $(ROM)
	$(RUN_TOOL) validation.rooms.room_boundary_transitions --image "$(ROM)" --validate

room-cell-sample-address: $(ROM)
	$(RUN_TOOL) validation.collision.room_cell_sample_address --image "$(ROM)" --pretty

validate-room-cell-sample-address: $(ROM)
	$(RUN_TOOL) validation.collision.room_cell_sample_address --image "$(ROM)" --validate

player-death-transition: $(ROM)
	$(RUN_TOOL) validation.player.player_death_transition --image "$(ROM)" --pretty

validate-player-death-transition: $(ROM)
	$(RUN_TOOL) validation.player.player_death_transition --image "$(ROM)" --validate

player-collision-sample: $(ROM)
	$(RUN_TOOL) validation.player.player_collision_sample --image "$(ROM)" --pretty

validate-player-collision-sample: $(ROM)
	$(RUN_TOOL) validation.player.player_collision_sample --image "$(ROM)" --validate

player-collision-update: $(ROM)
	$(RUN_TOOL) validation.player.player_collision_update --image "$(ROM)" --pretty

validate-player-collision-update: $(ROM)
	$(RUN_TOOL) validation.player.player_collision_update --image "$(ROM)" --validate

player-transition-reload: $(ROM)
	$(RUN_TOOL) validation.player.player_transition_reload --image "$(ROM)" --pretty

validate-player-transition-reload: $(ROM)
	$(RUN_TOOL) validation.player.player_transition_reload --image "$(ROM)" --validate

room-object-state-save: $(ROM)
	$(RUN_TOOL) validation.rooms.room_object_state_save --image "$(ROM)" --pretty

validate-room-object-state-save: $(ROM)
	$(RUN_TOOL) validation.rooms.room_object_state_save --image "$(ROM)" --validate

player-animated-cell-displacement: $(ROM)
	$(RUN_TOOL) validation.player.player_animated_cell_displacement --image "$(ROM)" --pretty

validate-player-animated-cell-displacement: $(ROM)
	$(RUN_TOOL) validation.player.player_animated_cell_displacement --image "$(ROM)" --validate

collectible-collision-handlers: $(ROM)
	$(RUN_TOOL) validation.objects.collectible_collision_handlers --image "$(ROM)" --pretty

validate-collectible-collision-handlers: $(ROM)
	$(RUN_TOOL) validation.objects.collectible_collision_handlers --image "$(ROM)" --validate

inventory-collectible-handlers: $(ROM)
	$(RUN_TOOL) validation.objects.inventory_collectible_handlers --image "$(ROM)" --pretty

validate-inventory-collectible-handlers: $(ROM)
	$(RUN_TOOL) validation.objects.inventory_collectible_handlers --image "$(ROM)" --validate

score-award: $(ROM)
	$(RUN_TOOL) validation.gameplay.score_award --image "$(ROM)" --pretty

validate-score-award: $(ROM)
	$(RUN_TOOL) validation.gameplay.score_award --image "$(ROM)" --validate

runtime-type9f-collision: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_type9f_collision --image "$(ROM)" --pretty

validate-runtime-type9f-collision: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_type9f_collision --image "$(ROM)" --validate

runtime-types81-82-collision: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_types81_82_collision --image "$(ROM)" --pretty

validate-runtime-types81-82-collision: $(ROM)
	$(RUN_TOOL) validation.objects.runtime_types81_82_collision --image "$(ROM)" --validate

unreferenced-nmi-task-bytes: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.unreferenced_nmi_task_index_bytes --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --pretty

validate-unreferenced-nmi-task-bytes: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.unreferenced_nmi_task_index_bytes --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --validate

unreferenced-object-clear-tail: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.unreferenced_runtime_object_clear_tail --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --pretty

validate-unreferenced-object-clear-tail: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.unreferenced_runtime_object_clear_tail --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --validate

unreferenced-runtime-only-sample: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.unreferenced_runtime_only_sample --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --pretty

validate-unreferenced-runtime-only-sample: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.unreferenced_runtime_only_sample --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --validate

title-sub-command: $(ROM)
	$(RUN_TOOL) validation.gameplay.title_sub_command --image "$(ROM)" --pretty

validate-title-sub-command: $(ROM)
	$(RUN_TOOL) validation.gameplay.title_sub_command --image "$(ROM)" --validate

demo-playback: $(ROM)
	$(RUN_TOOL) validation.gameplay.demo_playback --image "$(ROM)" --pretty

validate-demo-playback: $(ROM)
	$(RUN_TOOL) validation.gameplay.demo_playback --image "$(ROM)" --validate

audio-track-selection: $(ROM)
	$(RUN_TOOL) validation.audio.audio_track_selection --image "$(ROM)" --pretty

validate-audio-track-selection: $(ROM)
	$(RUN_TOOL) validation.audio.audio_track_selection --image "$(ROM)" --validate

audio-stream-engine: $(ROM)
	$(RUN_TOOL) validation.audio.audio_stream_engine --image "$(ROM)" --pretty

validate-audio-stream-engine: $(ROM)
	$(RUN_TOOL) validation.audio.audio_stream_engine --image "$(ROM)" --validate

sound-effect-engine: $(ROM)
	$(RUN_TOOL) validation.audio.sound_effect_engine --image "$(ROM)" --pretty

validate-sound-effect-engine: $(ROM)
	$(RUN_TOOL) validation.audio.sound_effect_engine --image "$(ROM)" --validate

scroll-math-palette: $(ROM)
	$(RUN_TOOL) validation.system.scroll_math_palette --image "$(ROM)" --pretty

validate-scroll-math-palette: $(ROM)
	$(RUN_TOOL) validation.system.scroll_math_palette --image "$(ROM)" --validate

end-sequences: $(ROM)
	$(RUN_TOOL) validation.gameplay.end_sequences --image "$(ROM)" --pretty

validate-end-sequences: $(ROM)
	$(RUN_TOOL) validation.gameplay.end_sequences --image "$(ROM)" --validate

prg-tail-data: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.prg_tail_data --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --pretty

validate-prg-tail-data: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.preservation.prg_tail_data --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --validate

palette-data: $(ROM)
	$(RUN_TOOL) validation.system.palette_data --image "$(ROM)" --pretty

validate-palette-data: $(ROM)
	$(RUN_TOOL) validation.system.palette_data --image "$(ROM)" --validate

player-collision-dispatch: $(ROM)
	$(RUN_TOOL) validation.player.player_collision_dispatch --image "$(ROM)" --pretty

validate-player-collision-dispatch: $(ROM)
	$(RUN_TOOL) validation.player.player_collision_dispatch --image "$(ROM)" --validate

player-hazard-state: $(ROM)
	$(RUN_TOOL) validation.player.player_hazard_state --image "$(ROM)" --pretty

validate-player-hazard: $(ROM)
	$(RUN_TOOL) validation.player.player_hazard_state --image "$(ROM)" --validate

object-player-proximity: $(ROM)
	$(RUN_TOOL) validation.objects.object_player_proximity --image "$(ROM)" --pretty

validate-object-player-proximity: $(ROM)
	$(RUN_TOOL) validation.objects.object_player_proximity --image "$(ROM)" --validate

pause-input-state: $(ROM)
	$(RUN_TOOL) validation.gameplay.pause_input --image "$(ROM)" --pretty

validate-pause-input: $(ROM)
	$(RUN_TOOL) validation.gameplay.pause_input --image "$(ROM)" --validate

collision-table-state: $(ROM)
	$(RUN_TOOL) validation.collision.collision_tables --image "$(ROM)" --pretty

validate-collision-tables: $(ROM)
	$(RUN_TOOL) validation.collision.collision_tables --image "$(ROM)" --validate

collision-handler-tables: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.player.player_movement_collision_tables --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --pretty

validate-collision-handler-tables: ghidra-analyze $(ROM)
	$(RUN_TOOL) validation.player.player_movement_collision_tables --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --validate

frame-sprite-state: $(ROM)
	$(RUN_TOOL) authoring.frame_sprites --image "$(ROM)" --pretty

validate-frame-sprites: $(ROM)
	$(RUN_TOOL) authoring.frame_sprites --image "$(ROM)" --validate

metasprite-state: $(ROM)
	$(RUN_TOOL) authoring.metasprites --image "$(ROM)" --pretty

validate-metasprites: $(ROM)
	$(RUN_TOOL) authoring.metasprites --image "$(ROM)" --validate

object-catalog: $(ROM)
	$(RUN_TOOL) validation.objects.object_catalog --image "$(ROM)" --pretty

validate-object-catalog: $(ROM)
	$(RUN_TOOL) validation.objects.object_catalog --image "$(ROM)" --validate

static-release-check: quality-check reconstruction-audit disassembly-check verify symbols validate-rooms validate-audio validate-screen-data validate-input validate-startup validate-nmi validate-oam validate-status validate-room-rows validate-attribute-upload validate-castle-map validate-data-io validate-save-data validate-room-cells validate-x-coordinates validate-transition validate-collision validate-object-dispatch validate-player-object-span validate-transient-objects validate-object-collision-filters validate-collision-point-sample validate-room-collision-sample validate-runtime-overlap validate-new-game validate-room-runtime validate-room-cell-animation validate-hud-format validate-mutable-cell-actions validate-room-navigation validate-player-input-movement validate-player-object-push validate-room-boundary-transitions validate-room-cell-sample-address validate-player-death-transition validate-player-collision-sample validate-player-collision-update validate-player-collision-dispatch validate-player-transition-reload validate-room-object-state-save validate-player-animated-cell-displacement validate-collectible-collision-handlers validate-inventory-collectible-handlers validate-score-award validate-runtime-type9f-collision validate-runtime-types81-82-collision validate-unreferenced-nmi-task-bytes validate-unreferenced-object-clear-tail validate-unreferenced-runtime-only-sample validate-title-sub-command validate-demo-playback validate-audio-track-selection validate-audio-stream-engine validate-sound-effect-engine validate-scroll-math-palette validate-end-sequences validate-prg-tail-data validate-palette-data validate-player-hazard validate-object-player-proximity validate-pause-input validate-collision-tables validate-collision-handler-tables validate-frame-sprites validate-metasprites validate-object-catalog

check: static-release-check

release-check:
	$(MAKE) clean
	$(MAKE) verify-reference verify-assets build-toolchain-status
	$(MAKE) check
	$(MAKE) validate-symbols
	$(MAKE) trace
	$(MAKE) release-audit

reconstruction-check: check trace-suite

clean:
	$(RUN_TOOL) build.project clean --path build
