#!/usr/bin/env python3
"""Tk rendering surface shared by the Castle Excellent Level Studio."""

from __future__ import annotations

import tkinter as tk

from scripts.authoring import level_studio_model as studio_model
from scripts.authoring import room_data


CELL_SCALE = 2
CELL_WIDTH = 16 * CELL_SCALE
CELL_HEIGHT = 8 * CELL_SCALE
PALETTE_COLUMNS = 10
OVERVIEW_GAP = 6
OVERVIEW_ZOOM_DIVISORS = {"25%": 4, "50%": 2, "100%": 1}


class LevelStudioRenderingMixin:
    def make_cell_image(self, visual: studio_model.CellVisual) -> tk.PhotoImage:
        key = (visual.left_tile, visual.right_tile, visual.palette_index)
        cached = self.image_cache.get(key)
        if cached is not None:
            return cached
        pixels = studio_model.logical_cell_pixels(self.tiles, visual)
        colors = studio_model.pixel_colors(pixels, self.palettes[visual.palette_index])
        expanded = []
        for row in colors:
            scaled_row = [color for color in row for _ in range(CELL_SCALE)]
            expanded.extend([scaled_row] * CELL_SCALE)
        photo = tk.PhotoImage(width=CELL_WIDTH, height=CELL_HEIGHT)
        photo.put(" ".join("{" + " ".join(row) + "}" for row in expanded))
        self.image_cache[key] = photo
        return photo

    def make_sprite_image(self, visual: studio_model.SpriteVisual) -> tk.PhotoImage:
        key = (visual.tile, visual.attributes)
        cached = self.sprite_image_cache.get(key)
        if cached is not None:
            return cached
        pixels = studio_model.sprite_pixels(self.tiles, visual.tile, visual.attributes)
        palette = self.sprite_palettes[visual.attributes & 3]
        colors = studio_model.pixel_colors(pixels, palette)
        expanded = []
        for row in colors:
            scaled_row = [color for color in row for _ in range(CELL_SCALE)]
            expanded.extend([scaled_row] * CELL_SCALE)
        photo = tk.PhotoImage(width=8 * CELL_SCALE, height=16 * CELL_SCALE)
        photo.put(" ".join("{" + " ".join(row) + "}" for row in expanded))
        for y, row in enumerate(pixels):
            for x, value in enumerate(row):
                if value == 0:
                    for scaled_y in range(y * CELL_SCALE, (y + 1) * CELL_SCALE):
                        for scaled_x in range(x * CELL_SCALE, (x + 1) * CELL_SCALE):
                            photo.transparency_set(scaled_x, scaled_y, True)
        self.sprite_image_cache[key] = photo
        return photo

    def make_overview_room_image(self, room_index: int) -> tk.PhotoImage:
        divisor = self.overview_divisor()
        key = (room_index, divisor)
        cached = self.overview_image_cache.get(key)
        if cached is not None:
            return cached
        colors = studio_model.room_thumbnail_colors(
            self.prg,
            self.tiles,
            self.palettes,
            self.sprite_palettes,
            self.document["rooms"][room_index],
            divisor,
        )
        photo = tk.PhotoImage(width=len(colors[0]), height=len(colors))
        photo.put(" ".join("{" + " ".join(row) + "}" for row in colors))
        self.overview_image_cache[key] = photo
        return photo

    def draw_castle_overview(self) -> None:
        self.overview_canvas.delete("all")
        room_width, room_height, pitch_x, pitch_y = self.overview_geometry()
        for room_index in range(room_data.ROOM_COUNT):
            room_number = room_index + 1
            column, row = studio_model.castle_room_position(room_number)
            x = OVERVIEW_GAP + column * pitch_x
            y = OVERVIEW_GAP + row * pitch_y
            self.overview_canvas.create_image(
                x,
                y,
                anchor="nw",
                image=self.make_overview_room_image(room_index),
            )
            selected = room_index == self.room_index
            self.overview_canvas.create_rectangle(
                x,
                y,
                x + room_width - 1,
                y + room_height - 1,
                outline="#ffdc5e" if selected else "#52606a",
                width=3 if selected else 1,
            )
            self.overview_canvas.create_text(
                x + 4,
                y + 4,
                anchor="nw",
                text=str(room_number),
                fill="#000000",
                font=("TkFixedFont", 8, "bold"),
            )
            self.overview_canvas.create_text(
                x + 3,
                y + 3,
                anchor="nw",
                text=str(room_number),
                fill="#ffffff",
                font=("TkFixedFont", 8, "bold"),
            )
        total_width = OVERVIEW_GAP + studio_model.CASTLE_COLUMNS * pitch_x
        total_height = OVERVIEW_GAP + studio_model.CASTLE_ROWS * pitch_y
        self.overview_canvas.configure(
            scrollregion=(0, 0, total_width, total_height)
        )

    def draw_room(self) -> None:
        self.room_canvas.delete("all")
        cells, objects = studio_model.room_visuals(self.prg, self.room)
        for index, visual in enumerate(cells):
            column = index % room_data.ROOM_WIDTH
            row = index // room_data.ROOM_WIDTH
            self.room_canvas.create_image(
                column * CELL_WIDTH,
                row * CELL_HEIGHT,
                anchor="nw",
                image=self.make_cell_image(visual),
            )
        for visual in objects:
            selected = visual.index == self.selected_object
            for sprite in visual.sprites:
                self.room_canvas.create_image(
                    sprite.x * CELL_SCALE,
                    sprite.y * CELL_SCALE,
                    anchor="nw",
                    image=self.make_sprite_image(sprite),
                )
            if selected:
                self.room_canvas.create_rectangle(
                    visual.x * CELL_WIDTH,
                    studio_model.object_preview_y(visual.runtime_type, visual.y)
                    * CELL_SCALE,
                    visual.x * CELL_WIDTH + max(16, len(visual.sprites) * 8) * CELL_SCALE,
                    (
                        studio_model.object_preview_y(visual.runtime_type, visual.y)
                        + 16
                    )
                    * CELL_SCALE,
                    outline="#ffdc5e",
                    width=2,
                )
        for sprite in studio_model.player_sprites(
            self.prg, self.player_x.get(), self.player_y.get()
        ):
            self.room_canvas.create_image(
                sprite.x * CELL_SCALE,
                sprite.y * CELL_SCALE,
                anchor="nw",
                image=self.make_sprite_image(sprite),
            )
        self.room_canvas.configure(
            scrollregion=(
                0,
                0,
                room_data.ROOM_WIDTH * CELL_WIDTH,
                room_data.ROOM_HEIGHT * CELL_HEIGHT,
            )
        )

    def draw_palette(self) -> None:
        self.palette_canvas.delete("all")
        selected = self.brush.get()
        for index, cell_type in enumerate(self.cell_types):
            column = index % PALETTE_COLUMNS
            row = index // PALETTE_COLUMNS
            x = column * CELL_WIDTH
            y = row * (CELL_HEIGHT + 10)
            left, right = studio_model.cell_tile_pair(self.prg, cell_type)
            visual = studio_model.CellVisual(
                cell_type,
                left,
                right,
                studio_model.cell_catalog_palette(self.prg, cell_type),
            )
            self.palette_canvas.create_image(
                x, y, anchor="nw", image=self.make_cell_image(visual)
            )
            self.palette_canvas.create_text(
                x + CELL_WIDTH // 2,
                y + CELL_HEIGHT + 5,
                text=f"{cell_type:02X}",
                fill="#ffffff",
                font=("TkFixedFont", 8),
            )
            if cell_type == selected:
                self.palette_canvas.create_rectangle(
                    x, y, x + CELL_WIDTH - 1, y + CELL_HEIGHT - 1,
                    outline="#ffdc5e", width=3,
                )
        rows = (len(self.cell_types) + PALETTE_COLUMNS - 1) // PALETTE_COLUMNS
        self.palette_canvas.configure(
            scrollregion=(0, 0, PALETTE_COLUMNS * CELL_WIDTH, rows * (CELL_HEIGHT + 10))
        )

    def draw_objects(self) -> None:
        self.object_tree.delete(*self.object_tree.get_children())
        _cells, objects = studio_model.room_visuals(self.prg, self.room)
        for visual in objects:
            self.object_tree.insert(
                "",
                "end",
                iid=str(visual.index),
                values=(
                    f"${visual.encoded_type:02X}",
                    f"${visual.runtime_type:02X}",
                    visual.x,
                    visual.y,
                ),
            )
        if self.selected_object is not None and self.selected_object < len(objects):
            self.object_tree.selection_set(str(self.selected_object))

    def update_status(self, suffix: str = "") -> None:
        flat = bytes(cell for row in self.room["cells"] for cell in row)
        encoded, padding = room_data.encode_prefix_stream(
            flat, room_data.parse_codebook(self.prg)
        )
        marker = "modified" if self.dirty else "saved"
        detail = (
            f"Room {self.room_index + 1}/100 | {len(encoded)} compressed bytes | "
            f"{len(self.room['objects'])} static objects | {padding} padding bits | {marker}"
        )
        if suffix:
            detail += f" | {suffix}"
        self.status.set(detail)
