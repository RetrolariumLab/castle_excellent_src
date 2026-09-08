# Profile-aware level, audio, and graphics authoring.

.PHONY: init-levels export-levels validate-levels build-levels \
	roundtrip-levels level-studio level-editor check-level-studio \
	smoke-level-playtest smoke-baseline-level-playtest \
	init-music export-music validate-music build-music roundtrip-music \
	sound-studio music-editor check-sound-studio \
	init-graphics export-graphics validate-graphics build-graphics \
	roundtrip-graphics graphics-studio check-graphics-studio \
	editor-quality-check-profile editor-quality-check editor-ui-smoke-profile

init-levels export-levels validate-levels build-levels roundtrip-levels: verify-profile
	$(RUN_TOOL) authoring.level_editor $(subst -levels,,$@) --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

level-studio: init-levels
	$(RUN_TOOL) authoring.level_studio --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

level-editor: level-studio

check-level-studio: verify-profile
	$(RUN_TOOL) authoring.level_studio --authoring "$(LEVEL_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

smoke-level-playtest: fceux-bootstrap build-levels
	$(RUN_TOOL) runtime.level_playtest --fceux "$(FCEUX)" --rom "build/authoring/$(REVISION_PROFILE)/levels.nes" --lua scripts/runtime/level_playtest.lua --room "$(LEVEL_PLAYTEST_ROOM)" --player-x "$(LEVEL_PLAYTEST_X)" --player-y "$(LEVEL_PLAYTEST_Y)" --result "$(LEVEL_PLAYTEST_RESULT)" --check

smoke-baseline-level-playtest: fceux-bootstrap verify-profile
	$(RUN_TOOL) runtime.level_playtest --fceux "$(FCEUX)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --lua scripts/runtime/level_playtest.lua --room "$(LEVEL_PLAYTEST_ROOM)" --player-x "$(LEVEL_PLAYTEST_X)" --player-y "$(LEVEL_PLAYTEST_Y)" --result "$(LEVEL_PLAYTEST_RESULT)" --check

init-music export-music validate-music build-music roundtrip-music: verify-profile
	$(RUN_TOOL) authoring.music_editor $(subst -music,,$@) --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

sound-studio: init-music
	$(RUN_TOOL) authoring.sound_studio --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

music-editor: sound-studio

check-sound-studio: verify-profile
	$(RUN_TOOL) authoring.sound_studio --authoring "$(AUDIO_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)" --check

init-graphics export-graphics validate-graphics build-graphics roundtrip-graphics: verify-profile
	$(RUN_TOOL) authoring.graphics_editor $(subst -graphics,,$@) --authoring "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"

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
	$(PYTHON) -m unittest tests.authoring.test_level_studio_model tests.authoring.test_sound_studio_model tests.authoring.test_graphics_studio_model
	$(MAKE) editor-quality-check-profile REVISION_PROFILE=castle-excellent-japan-hsp-05
	$(MAKE) editor-quality-check-profile REVISION_PROFILE=castlequest-usa

editor-ui-smoke-profile: fceux-bootstrap init-levels init-music init-graphics
	$(RUN_TOOL) authoring.editor_workstation_smoke --levels "$(LEVEL_AUTHORING)" --audio "$(AUDIO_AUTHORING)" --graphics "$(GRAPHICS_AUTHORING)" --revisions "$(REVISION_MANIFEST)" --profile "$(REVISION_PROFILE)"
