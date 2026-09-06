#!/usr/bin/env python3
"""Dependency-free visual editor for Castle Excellent graphics and display data."""

from __future__ import annotations

import argparse
from copy import deepcopy
from pathlib import Path
import sys
import tkinter as tk
from tkinter import messagebox, ttk
from typing import Any, Callable

import graphics_editor
import graphics_studio_model as studio_model
from project import ProjectError
import room_data


PIXEL_SCALE = 40
ATLAS_SCALE = 2


class GraphicsStudio(tk.Tk):
    def __init__(
        self,
        document: dict[str, Any],
        profile: dict[str, Any],
        image: bytes,
        prg: bytes,
        chr_data: bytes,
        workspace_path: Path,
        profile_id: str,
    ) -> None:
        super().__init__()
        self.document = document
        self.original_document = deepcopy(document)
        self.profile = profile
        self.image = image
        self.prg = prg
        self.chr_data = chr_data
        self.workspace_path = workspace_path
        self.profile_id = profile_id
        self.undo_stack: list[dict[str, Any]] = []
        self.dirty = False
        self.status = tk.StringVar()
        self.bank = tk.IntVar(value=0)
        self.pattern_table = tk.IntVar(value=0)
        self.tile_index = tk.IntVar(value=0)
        self.preview_palette = tk.IntVar(value=0)
        self.brush = tk.IntVar(value=1)
        self.cell_index = tk.IntVar(value=0)
        self.cell_left = tk.StringVar()
        self.cell_right = tk.StringVar()
        self.cell_palette = tk.IntVar()
        self.palette_source = tk.StringVar(value="room")
        self.palette_index = tk.IntVar(value=0)
        self.palette_value = tk.StringVar()
        self.descriptor_index = tk.IntVar(value=0)
        self.descriptor_tile = tk.StringVar()
        self.descriptor_attributes = tk.StringVar()
        self.text_index = tk.IntVar(value=0)
        self.text_values = tk.StringVar()
        self.sfx_index = tk.IntVar(value=0)
        self.sfx_values = tk.StringVar()
        self.title(f"Castle Excellent Graphics Studio [{profile_id}]")
        self.geometry("1280x820")
        self.minsize(1020, 680)
        self.protocol("WM_DELETE_WINDOW", self.close)
        self.build_ui()
        self.bind_all("<Control-s>", lambda _event: self.save())
        self.bind_all("<Control-z>", lambda _event: self.undo())
        self.refresh()

    def build_ui(self) -> None:
        toolbar = ttk.Frame(self, padding=7)
        toolbar.pack(fill="x")
        ttk.Button(toolbar, text="Undo", command=self.undo).pack(side="left")
        ttk.Button(toolbar, text="Save", command=self.save).pack(side="left", padx=3)
        ttk.Button(toolbar, text="Build ROM", command=self.build_rom).pack(side="left")
        ttk.Button(toolbar, text="Restore tile", command=self.restore_tile).pack(
            side="left", padx=3
        )
        ttk.Button(toolbar, text="Validate", command=self.validate).pack(
            side="left", padx=3
        )

        notebook = ttk.Notebook(self)
        notebook.pack(fill="both", expand=True, padx=7, pady=(0, 7))
        tile_tab = ttk.Frame(notebook, padding=8)
        cell_tab = ttk.Frame(notebook, padding=8)
        palette_tab = ttk.Frame(notebook, padding=8)
        record_tab = ttk.Frame(notebook, padding=8)
        notebook.add(tile_tab, text="CHR tiles")
        notebook.add(cell_tab, text="Room cells")
        notebook.add(palette_tab, text="Palettes")
        notebook.add(record_tab, text="Descriptors / text / SFX")
        self.build_tile_tab(tile_tab)
        self.build_cell_tab(cell_tab)
        self.build_palette_tab(palette_tab)
        self.build_record_tab(record_tab)
        ttk.Label(self, textvariable=self.status, anchor="w", padding=7).pack(
            fill="x"
        )

    def build_tile_tab(self, parent: ttk.Frame) -> None:
        controls = ttk.Frame(parent)
        controls.pack(fill="x", pady=(0, 7))
        ttk.Label(controls, text="CHR page").pack(side="left")
        bank = ttk.Combobox(
            controls, textvariable=self.bank, values=(0, 1), state="readonly", width=4
        )
        bank.pack(side="left", padx=(4, 10))
        bank.bind("<<ComboboxSelected>>", lambda _event: self.refresh())
        ttk.Label(controls, text="Pattern table").pack(side="left")
        pattern = ttk.Combobox(
            controls,
            textvariable=self.pattern_table,
            values=(0, 1),
            state="readonly",
            width=4,
        )
        pattern.current(0)
        pattern.pack(side="left", padx=(4, 10))
        pattern.bind("<<ComboboxSelected>>", self.change_pattern_table)
        ttk.Label(controls, text="0 sprites / 1 backgrounds").pack(side="left", padx=(0, 10))
        ttk.Label(controls, text="Tile").pack(side="left")
        tile = ttk.Spinbox(
            controls,
            from_=0,
            to=graphics_editor.TILE_COUNT - 1,
            textvariable=self.tile_index,
            width=6,
            command=self.draw_tile,
        )
        tile.pack(side="left", padx=(4, 10))
        tile.bind("<Return>", lambda _event: self.draw_tile())
        ttk.Label(controls, text="Room palette").pack(side="left")
        palette = ttk.Spinbox(
            controls,
            from_=0,
            to=7,
            textvariable=self.preview_palette,
            width=4,
            command=self.draw_tile,
        )
        palette.pack(side="left", padx=(4, 10))
        for value in range(4):
            ttk.Radiobutton(
                controls, text=f"Pixel {value}", variable=self.brush, value=value
            ).pack(side="left", padx=2)
        body = ttk.Panedwindow(parent, orient="horizontal")
        body.pack(fill="both", expand=True)
        atlas_frame = ttk.LabelFrame(body, text="Pattern-table atlas", padding=6)
        pixel_frame = ttk.LabelFrame(body, text="8x8 2bpp pixel editor", padding=6)
        body.add(atlas_frame, weight=3)
        body.add(pixel_frame, weight=2)
        self.atlas_canvas = tk.Canvas(
            atlas_frame,
            width=16 * 8 * ATLAS_SCALE,
            height=16 * 8 * ATLAS_SCALE,
            background="#111820",
            highlightthickness=0,
        )
        self.atlas_canvas.pack(fill="both", expand=True)
        self.atlas_canvas.bind("<Button-1>", self.select_atlas_tile)
        self.atlas_image: tk.PhotoImage | None = None
        self.tile_canvas = tk.Canvas(
            pixel_frame,
            width=8 * PIXEL_SCALE,
            height=8 * PIXEL_SCALE,
            background="#202830",
            highlightthickness=0,
        )
        self.tile_canvas.pack(anchor="center", pady=12)
        self.tile_canvas.bind("<Button-1>", self.paint_pixel)
        self.tile_canvas.bind("<B1-Motion>", self.paint_pixel)

    def build_cell_tab(self, parent: ttk.Frame) -> None:
        editor = ttk.LabelFrame(parent, text="Room-cell visual", padding=8)
        editor.pack(fill="x")
        for row, (label, variable) in enumerate(
            (
                ("Cell index", self.cell_index),
                ("Left tile", self.cell_left),
                ("Right tile", self.cell_right),
                ("Palette 0-3", self.cell_palette),
            )
        ):
            ttk.Label(editor, text=label).grid(row=row, column=0, sticky="w")
            if row == 0:
                widget = ttk.Spinbox(
                    editor,
                    from_=0,
                    to=99,
                    textvariable=variable,
                    width=10,
                    command=self.load_cell,
                )
                widget.bind("<Return>", lambda _event: self.load_cell())
            else:
                widget = ttk.Entry(editor, textvariable=variable, width=12)
            widget.grid(row=row, column=1, sticky="w", padx=(6, 0), pady=2)
        ttk.Button(editor, text="Apply cell", command=self.apply_cell).grid(
            row=4, column=0, columnspan=2, sticky="ew", pady=(7, 0)
        )
        self.cell_canvas = tk.Canvas(
            parent,
            width=16 * 16,
            height=8 * 16,
            background="#202830",
            highlightthickness=0,
        )
        self.cell_canvas.pack(anchor="center", pady=30)

    def build_palette_tab(self, parent: ttk.Frame) -> None:
        editor = ttk.LabelFrame(parent, text="NES palette byte", padding=8)
        editor.pack(fill="x")
        ttk.Label(editor, text="Storage").grid(row=0, column=0, sticky="w")
        source = ttk.Combobox(
            editor,
            textvariable=self.palette_source,
            values=("room", "screen"),
            state="readonly",
            width=12,
        )
        source.grid(row=0, column=1, padx=(6, 0), sticky="w")
        source.bind("<<ComboboxSelected>>", lambda _event: self.load_palette())
        ttk.Label(editor, text="Byte index").grid(row=1, column=0, sticky="w")
        index = ttk.Spinbox(
            editor,
            from_=0,
            to=63,
            textvariable=self.palette_index,
            width=12,
            command=self.load_palette,
        )
        index.grid(row=1, column=1, padx=(6, 0), sticky="w")
        index.bind("<Return>", lambda _event: self.load_palette())
        ttk.Label(editor, text="Value 0-$3F").grid(row=2, column=0, sticky="w")
        ttk.Entry(editor, textvariable=self.palette_value, width=14).grid(
            row=2, column=1, padx=(6, 0), sticky="w"
        )
        ttk.Button(editor, text="Apply palette byte", command=self.apply_palette).grid(
            row=3, column=0, columnspan=2, sticky="ew", pady=(7, 0)
        )
        self.palette_canvas = tk.Canvas(
            parent, width=8 * 68, height=8 * 44, background="#202830", highlightthickness=0
        )
        self.palette_canvas.pack(anchor="center", pady=18)
        self.palette_canvas.bind("<Button-1>", self.select_palette_swatch)
        ttk.Button(parent, text="Choose NES color", command=self.choose_palette_color).pack()

    def build_record_tab(self, parent: ttk.Frame) -> None:
        descriptor = ttk.LabelFrame(parent, text="Metasprite descriptor", padding=8)
        descriptor.pack(fill="x")
        self._record_spin(descriptor, "Index", self.descriptor_index, 202, self.load_descriptor, 0)
        self._record_entry(descriptor, "Tile", self.descriptor_tile, 1)
        self._record_entry(descriptor, "Attributes", self.descriptor_attributes, 2)
        ttk.Button(descriptor, text="Apply descriptor", command=self.apply_descriptor).grid(
            row=3, column=0, columnspan=2, sticky="ew", pady=(6, 0)
        )
        self.descriptor_canvas = tk.Canvas(
            descriptor,
            width=8 * 16,
            height=16 * 16,
            background="#111820",
            highlightthickness=0,
        )
        self.descriptor_canvas.grid(row=0, column=2, rowspan=4, padx=(28, 0))

        text = ttk.LabelFrame(parent, text="Fixed sub-command text block", padding=8)
        text.pack(fill="x", pady=(8, 0))
        self._record_spin(text, "Block", self.text_index, 7, self.load_text, 0)
        self._record_entry(text, "Hex bytes", self.text_values, 1, 72)
        ttk.Button(text, text="Apply text block", command=self.apply_text).grid(
            row=2, column=0, columnspan=2, sticky="ew", pady=(6, 0)
        )

        sfx = ttk.LabelFrame(parent, text="Sound-effect parameter table", padding=8)
        sfx.pack(fill="x", pady=(8, 0))
        self._record_spin(sfx, "Table", self.sfx_index, 4, self.load_sfx, 0)
        self._record_entry(sfx, "Four hex bytes", self.sfx_values, 1, 48)
        ttk.Button(sfx, text="Apply SFX table", command=self.apply_sfx).grid(
            row=2, column=0, columnspan=2, sticky="ew", pady=(6, 0)
        )

    def _record_spin(
        self,
        parent: ttk.LabelFrame,
        label: str,
        variable: tk.IntVar,
        maximum: int,
        command: Callable[[], None],
        row: int,
    ) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w")
        widget = ttk.Spinbox(
            parent,
            from_=0,
            to=maximum,
            textvariable=variable,
            width=10,
            command=command,
        )
        widget.grid(row=row, column=1, sticky="w", padx=(6, 0))
        widget.bind("<Return>", lambda _event: command())

    def _record_entry(
        self,
        parent: ttk.LabelFrame,
        label: str,
        variable: tk.StringVar,
        row: int,
        width: int = 14,
    ) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w")
        ttk.Entry(parent, textvariable=variable, width=width).grid(
            row=row, column=1, sticky="ew", padx=(6, 0), pady=2
        )
        parent.columnconfigure(1, weight=1)

    def guarded(self, action: Callable[[], None]) -> None:
        try:
            action()
        except (
            OSError,
            KeyError,
            TypeError,
            ValueError,
            ProjectError,
            room_data.RoomDataError,
        ) as exc:
            messagebox.showerror("Castle Excellent Graphics Studio", str(exc))

    def validated_change(self, action: Callable[[], None]) -> None:
        before = deepcopy(self.document)
        try:
            action()
            validated = graphics_editor.validate_workspace(
                self.document, self.profile_id
            )
            graphics_editor.compose_graphics(
                self.image, self.prg, self.chr_data, validated
            )
        except Exception:
            self.document = before
            raise
        self.undo_stack.append(before)
        del self.undo_stack[:-40]
        self.dirty = True
        self.refresh()

    def paint_pixel(self, event: tk.Event) -> None:
        column = event.x // PIXEL_SCALE
        row = event.y // PIXEL_SCALE
        if not 0 <= column < 8 or not 0 <= row < 8:
            return
        bank = self.bank.get()
        tile = self.tile_index.get()
        value = self.brush.get()
        if self.document["chr_banks"][bank]["tiles"][tile][row][column] == value:
            return
        self.guarded(
            lambda: self.validated_change(
                lambda: self.document["chr_banks"][bank]["tiles"][tile][row].__setitem__(
                    column, value
                )
            )
        )

    def restore_tile(self) -> None:
        bank = max(0, min(1, self.bank.get()))
        tile = max(0, min(graphics_editor.TILE_COUNT - 1, self.tile_index.get()))
        original = deepcopy(self.original_document["chr_banks"][bank]["tiles"][tile])
        if self.document["chr_banks"][bank]["tiles"][tile] == original:
            return
        self.guarded(
            lambda: self.validated_change(
                lambda: self.document["chr_banks"][bank]["tiles"].__setitem__(
                    tile, original
                )
            )
        )

    def apply_cell(self) -> None:
        def action() -> None:
            index = self.cell_index.get()
            self.document["room_cells"][index] = {
                "index": index,
                "left_tile": studio_model.parse_byte(self.cell_left.get(), "left tile"),
                "right_tile": studio_model.parse_byte(self.cell_right.get(), "right tile"),
                "palette": self.cell_palette.get(),
            }

        self.guarded(lambda: self.validated_change(action))

    def apply_palette(self) -> None:
        def action() -> None:
            field = (
                "room_palette"
                if self.palette_source.get() == "room"
                else "screen_palette_storage"
            )
            index = self.palette_index.get()
            if not 0 <= index < len(self.document[field]):
                raise studio_model.GraphicsStudioModelError("palette index is out of range")
            self.document[field][index] = studio_model.parse_byte(
                self.palette_value.get(), "palette value", 0x3F
            )

        self.guarded(lambda: self.validated_change(action))

    def apply_descriptor(self) -> None:
        def action() -> None:
            index = self.descriptor_index.get()
            self.document["metasprite_descriptors"][index] = {
                "index": index,
                "tile": studio_model.parse_byte(self.descriptor_tile.get(), "tile"),
                "attributes": studio_model.parse_byte(
                    self.descriptor_attributes.get(), "attributes"
                ),
            }

        self.guarded(lambda: self.validated_change(action))

    def apply_text(self) -> None:
        def action() -> None:
            record = self.document["sub_command_text"][self.text_index.get()]
            record["values"] = studio_model.parse_byte_sequence(
                self.text_values.get(), len(record["values"]), record["id"]
            )

        self.guarded(lambda: self.validated_change(action))

    def apply_sfx(self) -> None:
        def action() -> None:
            record = self.document["sound_effect_tables"][self.sfx_index.get()]
            record["values"] = studio_model.parse_byte_sequence(
                self.sfx_values.get(), len(record["values"]), record["id"]
            )

        self.guarded(lambda: self.validated_change(action))

    def undo(self) -> None:
        if not self.undo_stack:
            return
        self.document = self.undo_stack.pop()
        self.dirty = True
        self.refresh()

    def save(self) -> None:
        self.guarded(self._save)

    def _save(self) -> None:
        graphics_editor.validate_workspace(self.document, self.profile_id)
        graphics_editor.atomic_write_json(self.workspace_path, self.document)
        self.dirty = False
        self.update_status("workspace saved")

    def validate(self) -> None:
        self.guarded(self._validate)

    def _validate(self) -> None:
        validated = graphics_editor.validate_workspace(self.document, self.profile_id)
        graphics_editor.compose_graphics(self.image, self.prg, self.chr_data, validated)
        self.update_status("workspace and fixed ranges are valid")

    def build_rom(self) -> None:
        self.guarded(self._build_rom)

    def _build_rom(self) -> None:
        self._save()
        validated = graphics_editor.validate_workspace(self.document, self.profile_id)
        output, report = graphics_editor.compose_graphics(
            self.image, self.prg, self.chr_data, validated
        )
        output_path = graphics_editor.project_path(self.profile["output_rom"])
        report_path = graphics_editor.project_path(self.profile["report"])
        graphics_editor.atomic_write(output_path, output)
        report["profile"] = self.profile_id
        report["workspace"] = self.profile["workspace"]
        graphics_editor.atomic_write_json(report_path, report)
        self.update_status(
            f"built {output_path.name}: {report['changed_bytes']} changed ROM bytes"
        )

    def draw_scaled_tile(
        self, canvas: tk.Canvas, bank: int, tile: int, palette: list[int], scale: int
    ) -> None:
        canvas.delete("all")
        colors = studio_model.tile_colors(self.document, bank, tile, palette)
        for row, values in enumerate(colors):
            for column, color in enumerate(values):
                canvas.create_rectangle(
                    column * scale,
                    row * scale,
                    (column + 1) * scale,
                    (row + 1) * scale,
                    fill=color,
                    outline="#303840",
                )

    def draw_tile(self) -> None:
        bank = max(0, min(1, self.bank.get()))
        tile = max(0, min(graphics_editor.TILE_COUNT - 1, self.tile_index.get()))
        self.pattern_table.set(tile // 256)
        palette_index = max(0, min(7, self.preview_palette.get()))
        palette = self.document["room_palette"][palette_index * 4 : palette_index * 4 + 4]
        self.draw_scaled_tile(self.tile_canvas, bank, tile, palette, PIXEL_SCALE)

    def draw_atlas(self) -> None:
        if not hasattr(self, "atlas_canvas"):
            return
        bank = max(0, min(1, self.bank.get()))
        pattern = max(0, min(1, self.pattern_table.get()))
        palette_index = max(0, min(7, self.preview_palette.get()))
        palette = self.document["room_palette"][palette_index * 4 : palette_index * 4 + 4]
        rows = []
        for tile_row in range(16):
            tile_colors = [
                studio_model.tile_colors(
                    self.document,
                    bank,
                    pattern * 256 + tile_row * 16 + tile_column,
                    palette,
                )
                for tile_column in range(16)
            ]
            for pixel_row in range(8):
                rows.append(
                    [
                        color
                        for colors in tile_colors
                        for color in colors[pixel_row]
                    ]
                )
        raw = tk.PhotoImage(width=128, height=128)
        raw.put(" ".join("{" + " ".join(row) + "}" for row in rows))
        self.atlas_image = raw.zoom(ATLAS_SCALE, ATLAS_SCALE)
        self.atlas_canvas.delete("all")
        self.atlas_canvas.create_image(0, 0, anchor="nw", image=self.atlas_image)
        relative = self.tile_index.get() - pattern * 256
        if 0 <= relative < 256:
            tile_size = 8 * ATLAS_SCALE
            x = (relative % 16) * tile_size
            y = (relative // 16) * tile_size
            self.atlas_canvas.create_rectangle(
                x,
                y,
                x + tile_size,
                y + tile_size,
                outline="#ffdc5e",
                width=2,
            )
        self.atlas_canvas.configure(scrollregion=(0, 0, 256, 256))

    def select_atlas_tile(self, event: tk.Event) -> None:
        tile_size = 8 * ATLAS_SCALE
        column = int(self.atlas_canvas.canvasx(event.x)) // tile_size
        row = int(self.atlas_canvas.canvasy(event.y)) // tile_size
        if 0 <= column < 16 and 0 <= row < 16:
            self.tile_index.set(
                self.pattern_table.get() * 256 + row * 16 + column
            )
            self.refresh()

    def change_pattern_table(self, _event: tk.Event | None = None) -> None:
        self.tile_index.set(max(0, min(1, self.pattern_table.get())) * 256)
        self.refresh()

    def load_cell(self) -> None:
        index = max(0, min(99, self.cell_index.get()))
        record = self.document["room_cells"][index]
        self.cell_left.set(f"0x{record['left_tile']:02X}")
        self.cell_right.set(f"0x{record['right_tile']:02X}")
        self.cell_palette.set(record["palette"])
        self.cell_canvas.delete("all")
        colors = studio_model.room_cell_colors(self.document, index)
        for row in range(8):
            for column, color in enumerate(colors[row]):
                self.cell_canvas.create_rectangle(
                    column * 16,
                    row * 16,
                    (column + 1) * 16,
                    (row + 1) * 16,
                    fill=color,
                    outline="#303840",
                )

    def load_palette(self) -> None:
        field = (
            "room_palette"
            if self.palette_source.get() == "room"
            else "screen_palette_storage"
        )
        maximum = len(self.document[field]) - 1
        index = max(0, min(maximum, self.palette_index.get()))
        value = self.document[field][index]
        self.palette_value.set(f"0x{value:02X}")
        self.draw_palette_grid()

    def draw_palette_grid(self) -> None:
        field = (
            "room_palette"
            if self.palette_source.get() == "room"
            else "screen_palette_storage"
        )
        self.palette_canvas.delete("all")
        selected = max(0, min(len(self.document[field]) - 1, self.palette_index.get()))
        for index, value in enumerate(self.document[field]):
            x = (index % 8) * 68
            y = (index // 8) * 44
            self.palette_canvas.create_rectangle(
                x,
                y,
                x + 64,
                y + 40,
                fill=studio_model.NES_RGB[value],
                outline="#ffdc5e" if index == selected else "#45515d",
                width=3 if index == selected else 1,
            )
            self.palette_canvas.create_text(
                x + 32,
                y + 20,
                text=f"{index:02X}:${value:02X}",
                fill="#ffffff" if value < 0x20 else "#101010",
                font=("TkFixedFont", 8, "bold"),
            )

    def select_palette_swatch(self, event: tk.Event) -> None:
        field = (
            "room_palette"
            if self.palette_source.get() == "room"
            else "screen_palette_storage"
        )
        index = (event.y // 44) * 8 + event.x // 68
        if 0 <= index < len(self.document[field]):
            self.palette_index.set(index)
            self.load_palette()

    def choose_palette_color(self) -> None:
        picker = tk.Toplevel(self)
        picker.title("Choose NES color")
        for value, color in enumerate(studio_model.NES_RGB):
            tk.Button(
                picker,
                bg=color,
                text=f"{value:02X}",
                width=4,
                height=2,
                command=lambda selected=value: self.set_palette_color(
                    selected, picker
                ),
            ).grid(row=value // 8, column=value % 8)

    def set_palette_color(self, value: int, picker: tk.Toplevel) -> None:
        self.palette_value.set(f"0x{value:02X}")
        picker.destroy()
        self.apply_palette()

    def load_descriptor(self) -> None:
        index = max(0, min(202, self.descriptor_index.get()))
        record = self.document["metasprite_descriptors"][index]
        self.descriptor_tile.set(f"0x{record['tile']:02X}")
        self.descriptor_attributes.set(f"0x{record['attributes']:02X}")
        self.draw_descriptor()

    def draw_descriptor(self) -> None:
        if not hasattr(self, "descriptor_canvas"):
            return
        self.descriptor_canvas.delete("all")
        colors = studio_model.descriptor_colors(
            self.document, max(0, min(202, self.descriptor_index.get()))
        )
        scale = 16
        for row, values in enumerate(colors):
            for column, color in enumerate(values):
                if color is not None:
                    self.descriptor_canvas.create_rectangle(
                        column * scale,
                        row * scale,
                        (column + 1) * scale,
                        (row + 1) * scale,
                        fill=color,
                        outline="#28333d",
                    )

    def load_text(self) -> None:
        index = max(0, min(7, self.text_index.get()))
        record = self.document["sub_command_text"][index]
        self.text_values.set(studio_model.format_byte_sequence(record["values"]))

    def load_sfx(self) -> None:
        index = max(0, min(4, self.sfx_index.get()))
        record = self.document["sound_effect_tables"][index]
        self.sfx_values.set(studio_model.format_byte_sequence(record["values"]))

    def update_status(self, suffix: str = "") -> None:
        summary = studio_model.summarize(self.document, self.profile_id)
        marker = "modified" if self.dirty else "saved"
        detail = (
            f"{summary.tile_count} tiles | {summary.room_cell_count} room cells | "
            f"{summary.metasprite_descriptor_count} descriptors | {marker}"
        )
        if suffix:
            detail += f" | {suffix}"
        self.status.set(detail)

    def refresh(self) -> None:
        self.draw_tile()
        self.draw_atlas()
        self.load_cell()
        self.load_palette()
        self.load_descriptor()
        self.load_text()
        self.load_sfx()
        self.update_status()

    def close(self) -> None:
        if self.dirty and not messagebox.askyesno(
            "Castle Excellent Graphics Studio", "Discard unsaved graphics changes?"
        ):
            return
        self.destroy()


def load_studio(args: argparse.Namespace) -> tuple[
    dict[str, Any], bytes, bytes, bytes, Path, dict[str, Any]
]:
    _config, authoring_profile = graphics_editor.load_authoring(
        Path(args.authoring), args.profile
    )
    _revision, image, prg, chr_data = graphics_editor.load_base_image(
        Path(args.revisions), args.profile
    )
    workspace_path = graphics_editor.project_path(authoring_profile["workspace"])
    document = (
        graphics_editor.load_json(workspace_path)
        if workspace_path.is_file()
        else graphics_editor.decode_workspace(args.profile, prg, chr_data)
    )
    return authoring_profile, image, prg, chr_data, workspace_path, document


def check_studio(args: argparse.Namespace) -> None:
    graphics_editor.load_authoring(Path(args.authoring), args.profile)
    _revision, image, prg, chr_data = graphics_editor.load_base_image(
        Path(args.revisions), args.profile
    )
    document = graphics_editor.decode_workspace(args.profile, prg, chr_data)
    summary = studio_model.summarize(document, args.profile)
    validated = graphics_editor.validate_workspace(document, args.profile)
    graphics_editor.compose_graphics(image, prg, chr_data, validated)
    palettes = studio_model.palette_groups(document, "room")
    for bank in range(summary.bank_count):
        for tile in range(graphics_editor.TILE_COUNT):
            studio_model.tile_colors(document, bank, tile, palettes[0])
    for cell in range(summary.room_cell_count):
        studio_model.room_cell_colors(document, cell)
    for descriptor in range(summary.metasprite_descriptor_count):
        studio_model.descriptor_colors(document, descriptor)
    print(
        f"[OK] graphics studio model: {summary.tile_count} tiles, "
        f"{summary.room_cell_count} room cells, "
        f"{summary.metasprite_descriptor_count} descriptors"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--authoring", default="config/graphics_authoring.json")
    parser.add_argument("--revisions", default="config/revision_profiles.json")
    parser.add_argument("--profile", required=True)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--smoke-ui", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.check:
            check_studio(args)
            return 0
        profile, image, prg, chr_data, path, document = load_studio(args)
        application = GraphicsStudio(
            document, profile, image, prg, chr_data, path, args.profile
        )
        if args.smoke_ui:
            application.update_idletasks()
            application.destroy()
            print("[OK] graphics studio widgets constructed")
        else:
            application.mainloop()
    except (
        OSError,
        ProjectError,
        graphics_editor.GraphicsEditorError,
        studio_model.GraphicsStudioModelError,
        room_data.RoomDataError,
        tk.TclError,
    ) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
