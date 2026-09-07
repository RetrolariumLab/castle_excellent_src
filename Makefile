PYTHON ?= python
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
DEBUG_SUMMARY := $(BUILD_DIR)/debug_symbols.json
DEBUG_RUNTIME_RESULT := $(BUILD_DIR)/debug_symbols_runtime.txt
SOURCE_FILES := src/main.asm src/input/famicom_data_pulse.asm src/graphics/chr.asm \
	src/input/controllers.asm src/system/ppu.asm \
	src/input/famicom_data_io.asm src/system/startup.asm \
	src/game/player/input_and_movement.asm \
	src/game/rooms/boundary_transitions.asm src/game/rooms/object_state_save.asm \
	src/game/player/animated_cell_displacement.asm \
	src/game/player/object_push.asm src/game/objects/linked_lift_control.asm \
	src/game/objects/inventory_collectible_handlers.asm \
	src/data/unreferenced_runtime_object_clear_tail.asm \
	src/game/objects/collectible_collision_handlers.asm \
	src/game/objects/collectible_type97.asm src/game/scoring/add_score.asm \
	src/game/collision/runtime_type9f.asm src/game/collision/runtime_types81_82.asm \
	src/game/player/death_transition.asm \
	src/game/collision/player_sample.asm \
	src/game/rooms/sample_address.asm \
	src/game/objects/runtime_record_offsets.asm \
	src/game/collision/player_movement_handler_tables.asm \
	src/game/collision/player_handler_tables.asm \
	src/game/collision/player_update.asm \
	src/game/player/transition_reload.asm \
	src/game/collision/player_dispatch.asm \
	src/rendering/room_cell_updates.asm src/game/x_coordinates.asm \
	src/game/rooms/finish_transition.asm src/game/collision/cell_samples.asm \
	src/system/nmi_tasks.asm src/game/objects/update_dispatch.asm \
	src/game/objects/player_span_overlap.asm src/game/objects/pushable_update.asm \
	src/game/objects/lift_update.asm src/game/objects/flying_block_update.asm \
	src/game/objects/walking_enemy_physics.asm src/game/objects/knight_update.asm \
	src/game/objects/fairy_fighter_update.asm \
	src/game/objects/flame_and_movement_helpers.asm \
	src/game/objects/witch_summoning.asm src/game/objects/knight_arrow_update.asm \
	src/game/objects/transient_lifecycle.asm \
	src/game/collision/object_filters.asm src/game/collision/point_sample.asm \
	src/game/collision/room_sample.asm \
	src/game/collision/unreferenced_runtime_only_sample.asm \
	src/game/collision/runtime_overlap.asm src/data/unreferenced_nmi_task_index_bytes.asm \
	src/game/new_game.asm \
	src/rendering/room_palette.asm \
	src/game/rooms/load_room.asm src/game/rooms/runtime_reset.asm \
	src/game/rooms/cell_animation.asm src/rendering/status_format.asm \
	src/data/unreferenced_bit_index_helper.asm \
	src/game/rooms/cell_coordinates.asm src/game/rooms/mutable_cell_actions.asm \
	src/game/rooms/mutable_cell_lookup.asm src/game/collision/cell_pair_index.asm \
	src/game/rooms/mutable_cell_predicates.asm \
	src/game/rooms/mutable_cell_restore.asm src/game/rooms/navigation.asm \
	src/game/player/hazard_state.asm src/game/objects/player_proximity.asm \
	src/input/pause.asm src/game/collision/tables.asm \
	src/game/rooms/room_metadata.asm src/rendering/frame_sprites.asm \
	src/rendering/object_sprite_selectors.asm src/rendering/object_metasprites.asm \
	src/rendering/metasprite_data.asm \
	src/rendering/room_screen.asm src/input/demo_playback.asm \
	src/data/title_demo_input.asm \
	src/audio/track_selection.asm src/audio/track_table.asm \
	src/audio/stream_engine.asm \
	src/data/unreferenced_lowercase_hex_digit_decode_bytes.asm \
	src/audio/channel_configuration.asm \
	src/audio/note_semitone_offsets.asm src/audio/note_length_table.asm \
	src/audio/apu_period_table.asm src/audio/music_mml_data.asm \
	src/audio/sound_effect_starters.asm src/audio/sound_effect_update.asm \
	src/audio/sound_effect_tables.asm src/rendering/horizontal_scroll.asm \
	src/math/divide_unsigned16.asm src/rendering/palette_upload.asm \
	src/rendering/screen_palette_data.asm src/rendering/room_palette_data.asm \
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
	src/game/objects/room_data.asm src/ui/title_screen.asm \
	src/rendering/chr_nametable_copy.asm src/ui/sub_command_input.asm \
	src/ui/sub_command_menu.asm src/data/sub_command_text.asm \
	src/ui/sub_command_room_actions.asm \
	src/game/save_load.asm \
	src/game/rooms/persistent_state_save.asm src/game/end_sequences.asm \
	src/data/prg_tail_padding.asm src/rendering/room_cell_tile_tables.asm \
	src/system/interrupt_vectors.asm \
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
	$(PYTHON) scripts/project.py mkdir --path "$(BUILD_DIR)"

$(CHR_ASSET):
	$(PYTHON) scripts/project.py require --path "$@" --hint "run 'make split' first"

$(PRG_ASSET):
	$(PYTHON) scripts/project.py require --path "$@" --hint "run 'make split' first"

$(OBJECT): $(SOURCE_FILES) $(CHR_ASSET) | $(BUILD_DIR) build-toolchain-status
	$(CA65) --debug-info -g -o "$@" -l "$(BUILD_DIR)/castle_excellent.lst" "src/main.asm"

$(ROM): $(OBJECT) config/linker/cnrom.cfg
	$(LD65) -C config/linker/cnrom.cfg -o "$@" "$<" -Ln "$(LABELS)" -m "$(MAP)" --dbgfile "$(DEBUG)"

build: $(ROM)

split-profile:
	$(PYTHON) scripts/revision_profiles.py --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" split

build-profile: build-toolchain-status
	$(PYTHON) scripts/revision_profiles.py --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" build --ca65 "$(CA65)" --ld65 "$(LD65)"

verify-profile: build-profile
	$(PYTHON) scripts/revision_profiles.py --manifest "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" verify

castlequest-check:
	$(MAKE) split-profile REVISION_PROFILE=castlequest-usa
	$(MAKE) verify-profile REVISION_PROFILE=castlequest-usa

castlequest-runtime: fceux-bootstrap castlequest-check
	$(PYTHON) scripts/revision_runtime.py --revisions "$(REVISION_MANIFEST)" --profile castlequest-usa --fceux "$(FCEUX)" --lua scripts/capture_castlequest_runtime.lua --result "$(CASTLEQUEST_RUNTIME_RESULT)"

init-levels: verify-profile
	$(PYTHON) scripts/level_editor.py init --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

export-levels: verify-profile
	$(PYTHON) scripts/level_editor.py export --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

validate-levels: verify-profile
	$(PYTHON) scripts/level_editor.py validate --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

build-levels: verify-profile
	$(PYTHON) scripts/level_editor.py build --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

roundtrip-levels: verify-profile
	$(PYTHON) scripts/level_editor.py roundtrip --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

level-studio: init-levels
	$(PYTHON) scripts/level_studio.py --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

level-editor: level-studio

check-level-studio: verify-profile
	$(PYTHON) scripts/level_studio.py --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

smoke-level-playtest: fceux-bootstrap build-levels
	$(PYTHON) scripts/level_playtest.py --fceux "$(FCEUX)" --rom "build/authoring/$(REVISION_PROFILE)/levels.nes" --lua scripts/level_playtest.lua --room "$(LEVEL_PLAYTEST_ROOM)" --player-x "$(LEVEL_PLAYTEST_X)" --player-y "$(LEVEL_PLAYTEST_Y)" --result "$(LEVEL_PLAYTEST_RESULT)" --check

smoke-baseline-level-playtest: fceux-bootstrap verify-profile
	$(PYTHON) scripts/level_playtest.py --fceux "$(FCEUX)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --lua scripts/level_playtest.lua --room "$(LEVEL_PLAYTEST_ROOM)" --player-x "$(LEVEL_PLAYTEST_X)" --player-y "$(LEVEL_PLAYTEST_Y)" --result "$(LEVEL_PLAYTEST_RESULT)" --check

build-fixed-layout: build
	$(PYTHON) scripts/fixed_layout_variant.py build --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)"

verify-fixed-layout: build
	$(PYTHON) scripts/fixed_layout_variant.py verify --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)"

check-fixed-layout: fceux-bootstrap build
	$(PYTHON) scripts/fixed_layout_variant.py runtime --manifest "$(FIXED_LAYOUT_MANIFEST)" --variant "$(FIXED_LAYOUT_VARIANT)" --fceux "$(FCEUX)" --lua scripts/validate_fixed_layout.lua --result "$(FIXED_LAYOUT_RESULT)"

init-music: verify-profile
	$(PYTHON) scripts/music_editor.py init --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

export-music: verify-profile
	$(PYTHON) scripts/music_editor.py export --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

validate-music: verify-profile
	$(PYTHON) scripts/music_editor.py validate --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

build-music: verify-profile
	$(PYTHON) scripts/music_editor.py build --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

roundtrip-music: verify-profile
	$(PYTHON) scripts/music_editor.py roundtrip --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

sound-studio: init-music
	$(PYTHON) scripts/sound_studio.py --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

music-editor: sound-studio

check-sound-studio: verify-profile
	$(PYTHON) scripts/sound_studio.py --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

init-graphics: verify-profile
	$(PYTHON) scripts/graphics_editor.py init --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

export-graphics: verify-profile
	$(PYTHON) scripts/graphics_editor.py export --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

validate-graphics: verify-profile
	$(PYTHON) scripts/graphics_editor.py validate --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

build-graphics: verify-profile
	$(PYTHON) scripts/graphics_editor.py build --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

roundtrip-graphics: verify-profile
	$(PYTHON) scripts/graphics_editor.py roundtrip --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

graphics-studio: init-graphics
	$(PYTHON) scripts/graphics_studio.py --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

check-graphics-studio: verify-profile
	$(PYTHON) scripts/graphics_studio.py --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

editor-quality-check-profile: verify-profile
	$(PYTHON) scripts/level_editor.py roundtrip --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(PYTHON) scripts/level_studio.py --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(PYTHON) scripts/music_editor.py roundtrip --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(PYTHON) scripts/sound_studio.py --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(PYTHON) scripts/graphics_editor.py roundtrip --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(PYTHON) scripts/graphics_studio.py --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

editor-quality-check:
	$(MAKE) lint
	$(PYTHON) -m unittest tests.test_level_studio_model tests.test_sound_studio_model tests.test_graphics_studio_model
	$(MAKE) editor-quality-check-profile REVISION_PROFILE=castle-excellent-japan-hsp-05
	$(MAKE) editor-quality-check-profile REVISION_PROFILE=castlequest-usa

editor-ui-smoke-profile: init-levels init-music init-graphics
	$(PYTHON) scripts/level_studio.py --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --smoke-ui
	$(PYTHON) scripts/sound_studio.py --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --smoke-ui
	$(PYTHON) scripts/graphics_studio.py --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --smoke-ui

symbols: $(ROM)
	$(PYTHON) scripts/debug_symbols.py --debug "$(DEBUG)" --map "$(MAP)" --labels "$(LABELS)" --rom "$(ROM)" --output-dir "$(BUILD_DIR)" --breakpoints config/debugger_breakpoints.json --watches config/debugger_watches.json --summary "$(DEBUG_SUMMARY)"

validate-symbols: fceux-bootstrap symbols
	$(PYTHON) scripts/validate_debug_runtime.py --fceux "$(FCEUX)" --rom "$(ROM)" --lua scripts/validate_debug_symbols.lua --result "$(DEBUG_RUNTIME_RESULT)"

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

test: ghidra-analyze
	$(PYTHON) -m unittest discover -s tests -v

quality-check: lint test

scaffold-check: quality-check

reconstruction-audit:
	$(PYTHON) scripts/source_reconstruction.py --layout "$(SOURCE_LAYOUT)"

build-toolchain-status:
	$(PYTHON) scripts/release_audit.py --project-root . --manifest "$(SOURCE_1_MANIFEST)" --build-tools-only

release-audit:
	$(PYTHON) scripts/release_audit.py --project-root . --manifest "$(SOURCE_1_MANIFEST)" --require-clean

source-1-check:
	$(MAKE) release-check

source-1-pre-tag-check:
	$(MAKE) release-check
	$(PYTHON) scripts/release_audit.py --project-root . --manifest "$(SOURCE_1_MANIFEST)" --pre-tag

source-1-tag-check:
	$(MAKE) release-check
	$(PYTHON) scripts/release_audit.py --project-root . --manifest "$(SOURCE_1_MANIFEST)" --require-tag

source-2-audit:
	$(PYTHON) scripts/source_2_release_audit.py --project-root . --manifest "$(SOURCE_2_MANIFEST)"

source-2-authoring-check-profile: verify-profile
	$(PYTHON) scripts/level_editor.py roundtrip --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(PYTHON) scripts/level_studio.py --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(PYTHON) scripts/music_editor.py roundtrip --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(PYTHON) scripts/sound_studio.py --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check
	$(PYTHON) scripts/graphics_editor.py roundtrip --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
	$(PYTHON) scripts/graphics_studio.py --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

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
	$(PYTHON) scripts/source_2_release_audit.py --project-root . --manifest "$(SOURCE_2_MANIFEST)" --pre-tag

source-2-tag-check:
	$(MAKE) source-2-check
	$(PYTHON) scripts/source_2_release_audit.py --project-root . --manifest "$(SOURCE_2_MANIFEST)" --require-tag

ghidra-bootstrap:
	$(PYTHON) scripts/bootstrap_ghidra.py install

ghidra-status:
	$(PYTHON) scripts/bootstrap_ghidra.py status

ghidra-inspect: ghidra-bootstrap
	$(PYTHON) scripts/run_ghidra.py inspect --image "$(REFERENCE_ROM)" --output build/ghidra/program.json

ghidra-analyze: ghidra-bootstrap verify-reference
	$(PYTHON) scripts/run_ghidra.py export-facts --image "$(REFERENCE_ROM)" --false-instructions "$(FALSE_INSTRUCTION_STARTS)" --static-evidence "$(STATIC_CODE_EVIDENCE)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --data-ranges "$(PRG_DATA_RANGES)" --output "$(GHIDRA_FACTS)"

disassemble: ghidra-analyze $(PRG_ASSET)
	$(PYTHON) scripts/generate_disassembly.py write --prg "$(PRG_ASSET)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --memory-symbols "$(MEMORY_SYMBOLS)" --operand-overrides "$(OPERAND_OVERRIDES)" --layout "$(SOURCE_LAYOUT)"

disassembly-check: ghidra-analyze $(PRG_ASSET)
	$(PYTHON) scripts/generate_disassembly.py check --prg "$(PRG_ASSET)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --memory-symbols "$(MEMORY_SYMBOLS)" --operand-overrides "$(OPERAND_OVERRIDES)" --layout "$(SOURCE_LAYOUT)"

fceux-bootstrap:
	$(PYTHON) scripts/bootstrap_fceux.py install

fceux-status:
	$(PYTHON) scripts/bootstrap_fceux.py status

trace-boot: fceux-bootstrap ghidra-analyze $(ROM)
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/capture_boot_cdl.lua --frames "$(BOOT_FRAMES)" --scenario boot-gameplay --cdl "$(BOOT_CDL)" --metadata "$(BOOT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(BOOT_REPORT)"

trace-title: fceux-bootstrap ghidra-analyze $(ROM)
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/capture_title_demo_cdl.lua --frames "$(TITLE_FRAMES)" --scenario title-demo --cdl "$(TITLE_CDL)" --metadata "$(TITLE_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TITLE_REPORT)"

trace-timeout: fceux-bootstrap ghidra-analyze $(ROM)
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/capture_timeout_cdl.lua --frames "$(TIMEOUT_FRAMES)" --scenario idle-timeout --cdl "$(TIMEOUT_CDL)" --metadata "$(TIMEOUT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TIMEOUT_REPORT)"

trace-release-paths: fceux-bootstrap ghidra-analyze symbols
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/capture_release_paths_cdl.lua --frames 1200 --scenario room-transition --runtime-scenario room-transition --required-hook TransitionToRoomAbove --required-hook LoadRoom --required-hook FinishRoomTransition --cdl "$(TRANSITION_CDL)" --metadata "$(TRANSITION_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TRANSITION_REPORT)"
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/capture_release_paths_cdl.lua --frames 1800 --scenario death-game-over --runtime-scenario death-game-over --required-hook StartPlayerDeathTransition --required-hook CompletePlayerTransition --required-hook RunGameOverSequence --cdl "$(DEATH_CDL)" --metadata "$(DEATH_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(DEATH_REPORT)"
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/capture_release_paths_cdl.lua --frames 1400 --scenario completion-ending --runtime-scenario completion-ending --required-hook HandleRuntimeType82PlayerCollision --required-hook RunType82CompletionSequence --cdl "$(ENDING_CDL)" --metadata "$(ENDING_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(ENDING_REPORT)"
	$(PYTHON) scripts/runtime_coverage.py run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/capture_release_paths_cdl.lua --frames 1600 --scenario save-load-entry --runtime-scenario save-load-entry --required-hook OpenSubCommandMenu --required-hook SaveGameState --required-hook SendSaveDataSignature --required-hook LoadGameState --required-hook HandleLoadFailure --cdl "$(SAVE_LOAD_CDL)" --metadata "$(SAVE_LOAD_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(SAVE_LOAD_REPORT)"

runtime-merge:
	$(PYTHON) scripts/runtime_coverage.py merge --cdl "$(BOOT_CDL)" --cdl "$(TITLE_CDL)" --cdl "$(TIMEOUT_CDL)" --output "$(RUNTIME_CDL)"
	$(PYTHON) scripts/runtime_coverage.py analyze --scenario suite --cdl "$(RUNTIME_CDL)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(RUNTIME_REPORT)"

trace-suite: trace-boot trace-title trace-timeout
	$(MAKE) runtime-merge

trace-source-1: trace-suite trace-release-paths
	$(PYTHON) scripts/runtime_coverage.py merge --cdl "$(BOOT_CDL)" --cdl "$(TITLE_CDL)" --cdl "$(TIMEOUT_CDL)" --cdl "$(TRANSITION_CDL)" --cdl "$(DEATH_CDL)" --cdl "$(ENDING_CDL)" --cdl "$(SAVE_LOAD_CDL)" --output "$(SOURCE_1_RUNTIME_CDL)"
	$(PYTHON) scripts/runtime_coverage.py analyze --scenario source-1-suite --cdl "$(SOURCE_1_RUNTIME_CDL)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(SOURCE_1_RUNTIME_REPORT)"

trace: trace-source-1

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

player-object-span: $(ROM)
	$(PYTHON) scripts/player_object_span.py --image "$(ROM)" --pretty

validate-player-object-span: $(ROM)
	$(PYTHON) scripts/player_object_span.py --image "$(ROM)" --validate

transient-object-state: $(ROM)
	$(PYTHON) scripts/transient_object_lifecycle.py --image "$(ROM)" --pretty

validate-transient-objects: $(ROM)
	$(PYTHON) scripts/transient_object_lifecycle.py --image "$(ROM)" --validate

object-collision-filters: $(ROM)
	$(PYTHON) scripts/object_collision_filters.py --image "$(ROM)" --pretty

validate-object-collision-filters: $(ROM)
	$(PYTHON) scripts/object_collision_filters.py --image "$(ROM)" --validate

collision-point-sample: $(ROM)
	$(PYTHON) scripts/collision_point_sample.py --image "$(ROM)" --pretty

validate-collision-point-sample: $(ROM)
	$(PYTHON) scripts/collision_point_sample.py --image "$(ROM)" --validate

room-collision-sample: $(ROM)
	$(PYTHON) scripts/room_collision_sample.py --image "$(ROM)" --pretty

validate-room-collision-sample: $(ROM)
	$(PYTHON) scripts/room_collision_sample.py --image "$(ROM)" --validate

runtime-overlap-state: $(ROM)
	$(PYTHON) scripts/runtime_object_overlap.py --image "$(ROM)" --pretty

validate-runtime-overlap: $(ROM)
	$(PYTHON) scripts/runtime_object_overlap.py --image "$(ROM)" --validate

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

player-input-movement: $(ROM)
	$(PYTHON) scripts/player_input_movement.py --image "$(ROM)" --pretty

validate-player-input-movement: $(ROM)
	$(PYTHON) scripts/player_input_movement.py --image "$(ROM)" --validate

player-object-push: $(ROM)
	$(PYTHON) scripts/player_object_push.py --image "$(ROM)" --pretty

validate-player-object-push: $(ROM)
	$(PYTHON) scripts/player_object_push.py --image "$(ROM)" --validate

room-boundary-transitions: $(ROM)
	$(PYTHON) scripts/room_boundary_transitions.py --image "$(ROM)" --pretty

validate-room-boundary-transitions: $(ROM)
	$(PYTHON) scripts/room_boundary_transitions.py --image "$(ROM)" --validate

room-cell-sample-address: $(ROM)
	$(PYTHON) scripts/room_cell_sample_address.py --image "$(ROM)" --pretty

validate-room-cell-sample-address: $(ROM)
	$(PYTHON) scripts/room_cell_sample_address.py --image "$(ROM)" --validate

player-death-transition: $(ROM)
	$(PYTHON) scripts/player_death_transition.py --image "$(ROM)" --pretty

validate-player-death-transition: $(ROM)
	$(PYTHON) scripts/player_death_transition.py --image "$(ROM)" --validate

player-collision-sample: $(ROM)
	$(PYTHON) scripts/player_collision_sample.py --image "$(ROM)" --pretty

validate-player-collision-sample: $(ROM)
	$(PYTHON) scripts/player_collision_sample.py --image "$(ROM)" --validate

player-collision-update: $(ROM)
	$(PYTHON) scripts/player_collision_update.py --image "$(ROM)" --pretty

validate-player-collision-update: $(ROM)
	$(PYTHON) scripts/player_collision_update.py --image "$(ROM)" --validate

player-transition-reload: $(ROM)
	$(PYTHON) scripts/player_transition_reload.py --image "$(ROM)" --pretty

validate-player-transition-reload: $(ROM)
	$(PYTHON) scripts/player_transition_reload.py --image "$(ROM)" --validate

room-object-state-save: $(ROM)
	$(PYTHON) scripts/room_object_state_save.py --image "$(ROM)" --pretty

validate-room-object-state-save: $(ROM)
	$(PYTHON) scripts/room_object_state_save.py --image "$(ROM)" --validate

player-animated-cell-displacement: $(ROM)
	$(PYTHON) scripts/player_animated_cell_displacement.py --image "$(ROM)" --pretty

validate-player-animated-cell-displacement: $(ROM)
	$(PYTHON) scripts/player_animated_cell_displacement.py --image "$(ROM)" --validate

collectible-collision-handlers: $(ROM)
	$(PYTHON) scripts/collectible_collision_handlers.py --image "$(ROM)" --pretty

validate-collectible-collision-handlers: $(ROM)
	$(PYTHON) scripts/collectible_collision_handlers.py --image "$(ROM)" --validate

inventory-collectible-handlers: $(ROM)
	$(PYTHON) scripts/inventory_collectible_handlers.py --image "$(ROM)" --pretty

validate-inventory-collectible-handlers: $(ROM)
	$(PYTHON) scripts/inventory_collectible_handlers.py --image "$(ROM)" --validate

score-award: $(ROM)
	$(PYTHON) scripts/score_award.py --image "$(ROM)" --pretty

validate-score-award: $(ROM)
	$(PYTHON) scripts/score_award.py --image "$(ROM)" --validate

runtime-type9f-collision: $(ROM)
	$(PYTHON) scripts/runtime_type9f_collision.py --image "$(ROM)" --pretty

validate-runtime-type9f-collision: $(ROM)
	$(PYTHON) scripts/runtime_type9f_collision.py --image "$(ROM)" --validate

runtime-types81-82-collision: $(ROM)
	$(PYTHON) scripts/runtime_types81_82_collision.py --image "$(ROM)" --pretty

validate-runtime-types81-82-collision: $(ROM)
	$(PYTHON) scripts/runtime_types81_82_collision.py --image "$(ROM)" --validate

unreferenced-nmi-task-bytes: ghidra-analyze $(ROM)
	$(PYTHON) scripts/unreferenced_nmi_task_index_bytes.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --pretty

validate-unreferenced-nmi-task-bytes: ghidra-analyze $(ROM)
	$(PYTHON) scripts/unreferenced_nmi_task_index_bytes.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --validate

unreferenced-object-clear-tail: ghidra-analyze $(ROM)
	$(PYTHON) scripts/unreferenced_runtime_object_clear_tail.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --pretty

validate-unreferenced-object-clear-tail: ghidra-analyze $(ROM)
	$(PYTHON) scripts/unreferenced_runtime_object_clear_tail.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --validate

unreferenced-runtime-only-sample: ghidra-analyze $(ROM)
	$(PYTHON) scripts/unreferenced_runtime_only_sample.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --pretty

validate-unreferenced-runtime-only-sample: ghidra-analyze $(ROM)
	$(PYTHON) scripts/unreferenced_runtime_only_sample.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)" --validate

title-sub-command: $(ROM)
	$(PYTHON) scripts/title_sub_command.py --image "$(ROM)" --pretty

validate-title-sub-command: $(ROM)
	$(PYTHON) scripts/title_sub_command.py --image "$(ROM)" --validate

demo-playback: $(ROM)
	$(PYTHON) scripts/demo_playback.py --image "$(ROM)" --pretty

validate-demo-playback: $(ROM)
	$(PYTHON) scripts/demo_playback.py --image "$(ROM)" --validate

audio-track-selection: $(ROM)
	$(PYTHON) scripts/audio_track_selection.py --image "$(ROM)" --pretty

validate-audio-track-selection: $(ROM)
	$(PYTHON) scripts/audio_track_selection.py --image "$(ROM)" --validate

audio-stream-engine: $(ROM)
	$(PYTHON) scripts/audio_stream_engine.py --image "$(ROM)" --pretty

validate-audio-stream-engine: $(ROM)
	$(PYTHON) scripts/audio_stream_engine.py --image "$(ROM)" --validate

sound-effect-engine: $(ROM)
	$(PYTHON) scripts/sound_effect_engine.py --image "$(ROM)" --pretty

validate-sound-effect-engine: $(ROM)
	$(PYTHON) scripts/sound_effect_engine.py --image "$(ROM)" --validate

scroll-math-palette: $(ROM)
	$(PYTHON) scripts/scroll_math_palette.py --image "$(ROM)" --pretty

validate-scroll-math-palette: $(ROM)
	$(PYTHON) scripts/scroll_math_palette.py --image "$(ROM)" --validate

end-sequences: $(ROM)
	$(PYTHON) scripts/end_sequences.py --image "$(ROM)" --pretty

validate-end-sequences: $(ROM)
	$(PYTHON) scripts/end_sequences.py --image "$(ROM)" --validate

prg-tail-data: ghidra-analyze $(ROM)
	$(PYTHON) scripts/prg_tail_data.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --pretty

validate-prg-tail-data: ghidra-analyze $(ROM)
	$(PYTHON) scripts/prg_tail_data.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --validate

palette-data: $(ROM)
	$(PYTHON) scripts/palette_data.py --image "$(ROM)" --pretty

validate-palette-data: $(ROM)
	$(PYTHON) scripts/palette_data.py --image "$(ROM)" --validate

player-collision-dispatch: $(ROM)
	$(PYTHON) scripts/player_collision_dispatch.py --image "$(ROM)" --pretty

validate-player-collision-dispatch: $(ROM)
	$(PYTHON) scripts/player_collision_dispatch.py --image "$(ROM)" --validate

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

collision-table-state: $(ROM)
	$(PYTHON) scripts/collision_tables.py --image "$(ROM)" --pretty

validate-collision-tables: $(ROM)
	$(PYTHON) scripts/collision_tables.py --image "$(ROM)" --validate

collision-handler-tables: ghidra-analyze $(ROM)
	$(PYTHON) scripts/player_movement_collision_tables.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --pretty

validate-collision-handler-tables: ghidra-analyze $(ROM)
	$(PYTHON) scripts/player_movement_collision_tables.py --image "$(ROM)" --facts "$(GHIDRA_FACTS)" --validate

frame-sprite-state: $(ROM)
	$(PYTHON) scripts/frame_sprites.py --image "$(ROM)" --pretty

validate-frame-sprites: $(ROM)
	$(PYTHON) scripts/frame_sprites.py --image "$(ROM)" --validate

metasprite-state: $(ROM)
	$(PYTHON) scripts/metasprites.py --image "$(ROM)" --pretty

validate-metasprites: $(ROM)
	$(PYTHON) scripts/metasprites.py --image "$(ROM)" --validate

object-catalog: $(ROM)
	$(PYTHON) scripts/object_catalog.py --image "$(ROM)" --pretty

validate-object-catalog: $(ROM)
	$(PYTHON) scripts/object_catalog.py --image "$(ROM)" --validate

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
	$(PYTHON) scripts/project.py clean --path build
