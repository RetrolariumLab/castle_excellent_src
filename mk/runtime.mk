# Deterministic FCEUX coverage and evidence promotion.

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

BOOT_FRAMES ?= 900
TITLE_FRAMES ?= 1800
TIMEOUT_FRAMES ?= 15000

.PHONY: trace-boot trace-title trace-timeout trace-release-paths trace-suite \
	trace-source-1 trace runtime-merge runtime-check runtime-promote \
	reconstruction-check

trace-boot: fceux-bootstrap ghidra-analyze $(ROM)
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_boot_cdl.lua --frames "$(BOOT_FRAMES)" --scenario boot-gameplay --cdl "$(BOOT_CDL)" --metadata "$(BOOT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(BOOT_REPORT)"

trace-title: fceux-bootstrap ghidra-analyze $(ROM)
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_title_demo_cdl.lua --frames "$(TITLE_FRAMES)" --scenario title-demo --cdl "$(TITLE_CDL)" --metadata "$(TITLE_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TITLE_REPORT)"

trace-timeout: fceux-bootstrap ghidra-analyze $(ROM)
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_timeout_cdl.lua --frames "$(TIMEOUT_FRAMES)" --scenario idle-timeout --cdl "$(TIMEOUT_CDL)" --metadata "$(TIMEOUT_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TIMEOUT_REPORT)"

trace-release-paths: fceux-bootstrap ghidra-analyze symbols
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_release_paths_cdl.lua --frames 1200 --scenario room-transition --runtime-scenario room-transition --required-hook TransitionToRoomAbove --required-hook LoadRoom --required-hook FinishRoomTransition --cdl "$(TRANSITION_CDL)" --metadata "$(TRANSITION_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(TRANSITION_REPORT)"
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_release_paths_cdl.lua --frames 1800 --scenario death-game-over --runtime-scenario death-game-over --required-hook StartPlayerDeathTransition --required-hook CompletePlayerTransition --required-hook RunGameOverSequence --cdl "$(DEATH_CDL)" --metadata "$(DEATH_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(DEATH_REPORT)"
	$(RUN_TOOL) runtime.runtime_coverage run --fceux "$(FCEUX)" --image "$(ROM)" --lua scripts/runtime/capture_release_paths_cdl.lua --frames 1400 --scenario completion-ending --runtime-scenario completion-ending --required-hook HandlePrincessPlayerCollision --required-hook RunType82CompletionSequence --cdl "$(ENDING_CDL)" --metadata "$(ENDING_METADATA)" --facts "$(GHIDRA_FACTS)" --symbols "$(SYMBOLS)" --manifest "$(MANIFEST)" --output "$(ENDING_REPORT)"
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

reconstruction-check: check trace-suite
