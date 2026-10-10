# Focused inspection/validation pairs and the static aggregate gate.

define DEFINE_VALIDATION_PAIR
.PHONY: $(1) $(2)
$(1): $(4)
	$$(RUN_TOOL) $(3)$(if $(5), $(5)) --pretty
$(2): $(4)
	$$(RUN_TOOL) $(3)$(if $(5), $(5)) --validate
endef

$(eval $(call DEFINE_VALIDATION_PAIR,rooms,validate-rooms,validation.room_data,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,audio,validate-audio,validation.audio_data,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,screen-data,validate-screen-data,validation.rooms.room_screen_data,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,startup-state,validate-startup,validation.gameplay.startup_state,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,nmi-state,validate-nmi,validation.system.nmi_scheduler,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,oam-state,validate-oam,validation.system.oam_dma,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,status-state,validate-status,validation.system.status_upload,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-row-state,validate-room-rows,validation.rooms.room_row_upload,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,attribute-upload-state,validate-attribute-upload,validation.rooms.room_attribute_upload,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,castle-map-state,validate-castle-map,validation.rooms.castle_map,,))
$(eval $(call DEFINE_VALIDATION_PAIR,data-io-state,validate-data-io,validation.gameplay.famicom_data_io,,))
$(eval $(call DEFINE_VALIDATION_PAIR,save-data,validate-save-data,validation.gameplay.save_data,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-cell-state,validate-room-cells,validation.rooms.room_cell_coordinates,,))
$(eval $(call DEFINE_VALIDATION_PAIR,x-coordinate-state,validate-x-coordinates,validation.player.x_coordinates,,))
$(eval $(call DEFINE_VALIDATION_PAIR,transition-state,validate-transition,validation.rooms.room_transition,,))
$(eval $(call DEFINE_VALIDATION_PAIR,collision-state,validate-collision,validation.collision.collision_cells,,))
$(eval $(call DEFINE_VALIDATION_PAIR,object-dispatch-state,validate-object-dispatch,validation.objects.runtime_object_dispatch,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-object-span,validate-player-object-span,validation.player.player_object_span,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,transient-object-state,validate-transient-objects,validation.objects.transient_object_lifecycle,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,object-collision-filters,validate-object-collision-filters,validation.objects.object_collision_filters,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,collision-point-sample,validate-collision-point-sample,validation.collision.collision_point_sample,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-collision-sample,validate-room-collision-sample,validation.collision.room_collision_sample,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,runtime-overlap-state,validate-runtime-overlap,validation.objects.runtime_object_overlap,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,new-game-state,validate-new-game,validation.gameplay.new_game_state,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-runtime-state,validate-room-runtime,validation.rooms.room_runtime_reset,,))
$(eval $(call DEFINE_VALIDATION_PAIR,room-cell-animation-state,validate-room-cell-animation,validation.rooms.room_cell_animation,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,hud-format-state,validate-hud-format,validation.system.status_format,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,mutable-cell-action-state,validate-mutable-cell-actions,validation.rooms.mutable_cell_actions,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-navigation-state,validate-room-navigation,validation.rooms.room_navigation,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-input-movement,validate-player-input-movement,validation.player.player_input_movement,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-object-push,validate-player-object-push,validation.player.player_object_push,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-boundary-transitions,validate-room-boundary-transitions,validation.rooms.room_boundary_transitions,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-cell-sample-address,validate-room-cell-sample-address,validation.collision.room_cell_sample_address,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-death-transition,validate-player-death-transition,validation.player.player_death_transition,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-collision-sample,validate-player-collision-sample,validation.player.player_collision_sample,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-collision-update,validate-player-collision-update,validation.player.player_collision_update,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-collision-dispatch,validate-player-collision-dispatch,validation.player.player_collision_dispatch,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-transition-reload,validate-player-transition-reload,validation.player.player_transition_reload,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,room-object-state-save,validate-room-object-state-save,validation.rooms.room_object_state_save,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-animated-cell-displacement,validate-player-animated-cell-displacement,validation.player.player_animated_cell_displacement,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,collectible-collision-handlers,validate-collectible-collision-handlers,validation.objects.collectible_collision_handlers,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,inventory-collectible-handlers,validate-inventory-collectible-handlers,validation.objects.inventory_collectible_handlers,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,score-award,validate-score-award,validation.gameplay.score_award,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,runtime-type9f-collision,validate-runtime-type9f-collision,validation.objects.runtime_type9f_collision,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,runtime-types81-82-collision,validate-runtime-types81-82-collision,validation.objects.runtime_types81_82_collision,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,unreferenced-nmi-task-bytes,validate-unreferenced-nmi-task-bytes,validation.preservation.unreferenced_nmi_task_index_bytes,ghidra-analyze $(ROM),--image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)"))
$(eval $(call DEFINE_VALIDATION_PAIR,unreferenced-object-clear-tail,validate-unreferenced-object-clear-tail,validation.preservation.unreferenced_runtime_object_clear_tail,ghidra-analyze $(ROM),--image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)"))
$(eval $(call DEFINE_VALIDATION_PAIR,unreferenced-runtime-only-sample,validate-unreferenced-runtime-only-sample,validation.preservation.unreferenced_runtime_only_sample,ghidra-analyze $(ROM),--image "$(ROM)" --facts "$(GHIDRA_FACTS)" --runtime-evidence "$(RUNTIME_EVIDENCE)"))
$(eval $(call DEFINE_VALIDATION_PAIR,title-sub-command,validate-title-sub-command,validation.gameplay.title_sub_command,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,demo-playback,validate-demo-playback,validation.gameplay.demo_playback,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,audio-track-selection,validate-audio-track-selection,validation.audio.audio_track_selection,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,audio-stream-engine,validate-audio-stream-engine,validation.audio.audio_stream_engine,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,sound-effect-engine,validate-sound-effect-engine,validation.audio.sound_effect_engine,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,scroll-math-palette,validate-scroll-math-palette,validation.system.scroll_math_palette,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,end-sequences,validate-end-sequences,validation.gameplay.end_sequences,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,prg-tail-data,validate-prg-tail-data,validation.preservation.prg_tail_data,ghidra-analyze $(ROM),--image "$(ROM)" --facts "$(GHIDRA_FACTS)"))
$(eval $(call DEFINE_VALIDATION_PAIR,palette-data,validate-palette-data,validation.system.palette_data,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,player-hazard-state,validate-player-hazard,validation.player.player_hazard_state,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,object-player-proximity,validate-object-player-proximity,validation.objects.object_player_proximity,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,pause-input-state,validate-pause-input,validation.gameplay.pause_input,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,collision-table-state,validate-collision-tables,validation.collision.collision_tables,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,collision-handler-tables,validate-collision-handler-tables,validation.player.player_movement_collision_tables,ghidra-analyze $(ROM),--image "$(ROM)" --facts "$(GHIDRA_FACTS)"))
$(eval $(call DEFINE_VALIDATION_PAIR,frame-sprite-state,validate-frame-sprites,validation.frame_sprites,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,metasprite-state,validate-metasprites,validation.metasprites,$(ROM),--image "$(ROM)"))
$(eval $(call DEFINE_VALIDATION_PAIR,object-catalog,validate-object-catalog,validation.objects.object_catalog,$(ROM),--image "$(ROM)"))

.PHONY: validate-input static-release-check

validate-input:
	$(RUN_TOOL) validation.gameplay.controller_input --validate

STATIC_VALIDATORS := \
	validate-rooms validate-audio validate-screen-data validate-input \
	validate-startup validate-nmi validate-oam validate-status \
	validate-room-rows validate-attribute-upload validate-castle-map \
	validate-data-io validate-save-data validate-room-cells \
	validate-x-coordinates validate-transition validate-collision \
	validate-object-dispatch validate-player-object-span \
	validate-transient-objects validate-object-collision-filters \
	validate-collision-point-sample validate-room-collision-sample \
	validate-runtime-overlap validate-new-game validate-room-runtime \
	validate-room-cell-animation validate-hud-format \
	validate-mutable-cell-actions validate-room-navigation \
	validate-player-input-movement validate-player-object-push \
	validate-room-boundary-transitions validate-room-cell-sample-address \
	validate-player-death-transition validate-player-collision-sample \
	validate-player-collision-update validate-player-collision-dispatch \
	validate-player-transition-reload validate-room-object-state-save \
	validate-player-animated-cell-displacement \
	validate-collectible-collision-handlers \
	validate-inventory-collectible-handlers validate-score-award \
	validate-runtime-type9f-collision validate-runtime-types81-82-collision \
	validate-unreferenced-nmi-task-bytes \
	validate-unreferenced-object-clear-tail \
	validate-unreferenced-runtime-only-sample validate-title-sub-command \
	validate-demo-playback validate-audio-track-selection \
	validate-audio-stream-engine validate-sound-effect-engine \
	validate-scroll-math-palette validate-end-sequences validate-prg-tail-data \
	validate-palette-data validate-player-hazard \
	validate-object-player-proximity validate-pause-input \
	validate-collision-tables validate-collision-handler-tables \
	validate-frame-sprites validate-metasprites validate-object-catalog

static-release-check: quality-check reconstruction-audit disassembly-check verify symbols $(STATIC_VALIDATORS)
