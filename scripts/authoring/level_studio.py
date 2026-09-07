#!/usr/bin/env python3
"""Dependency-free visual editor for Castle Excellent rooms and objects."""

from __future__ import annotations

import argparse
from copy import deepcopy
from pathlib import Path
import sys
import tkinter as tk
from tkinter import messagebox, ttk
from typing import Any, Callable

from scripts.authoring import level_editor
from scripts.authoring import level_studio_model as studio_model
from scripts.authoring import room_data
from scripts.build.project import ProjectError
from scripts.runtime import level_playtest


CELL_SCALE = 2
CELL_WIDTH = 16 * CELL_SCALE
CELL_HEIGHT = 8 * CELL_SCALE
PALETTE_COLUMNS = 10
OVERVIEW_GAP = 6
OVERVIEW_ZOOM_DIVISORS = {"25%": 4, "50%": 2, "100%": 1}


class LevelStudio(tk.Tk):
    def __init__(
        self,
        document: dict[str, Any],
        config: dict[str, Any],
        profile: dict[str, Any],
        image: bytes,
        prg: bytes,
        chr_data: bytes,
        workspace_path: Path,
        profile_id: str,
    ) -> None:
        super().__init__()
        self.document = document
        self.config = config
        self.profile = profile
        self.image = image
        self.prg = prg
        self.chr_data = chr_data
        self.workspace_path = workspace_path
        self.profile_id = profile_id
        self.tiles = studio_model.decode_chr_bank(chr_data)
        self.palettes = studio_model.room_palette(prg)
        self.sprite_palettes = studio_model.sprite_palette(prg)
        self.cell_types = studio_model.compression_symbols(prg)
        self.room_number = tk.IntVar(value=1)
        self.brush = tk.IntVar(value=self.cell_types[0])
        self.object_type = tk.StringVar(value="0x0E")
        self.object_x = tk.StringVar(value="0")
        self.object_y = tk.StringVar(value="0")
        self.player_x = tk.IntVar(value=16)
        self.player_y = tk.IntVar(value=152)
        self.overview_zoom = tk.StringVar(value="25%")
        self.status = tk.StringVar()
        self.object_placement = False
        self.player_placement = False
        self.selected_object: int | None = None
        self.undo_stack: list[dict[str, Any]] = []
        self.dirty = False
        self.last_painted: tuple[int, int, int] | None = None
        self.image_cache: dict[tuple[int, int, int], tk.PhotoImage] = {}
        self.sprite_image_cache: dict[tuple[int, int], tk.PhotoImage] = {}
        self.overview_image_cache: dict[tuple[int, int], tk.PhotoImage] = {}
        self.overview_drag_origin: tuple[int, int] | None = None
        self.overview_is_panning = False
        self.title(f"Castle Excellent Level Studio [{profile_id}]")
        self.geometry("1180x760")
        self.minsize(920, 620)
        self.protocol("WM_DELETE_WINDOW", self.close)
        self.build_ui()
        self.bind_all("<Control-s>", lambda _event: self.save())
        self.bind_all("<Control-z>", lambda _event: self.undo())
        self.refresh()

    @property
    def room_index(self) -> int:
        return max(0, min(room_data.ROOM_COUNT - 1, self.room_number.get() - 1))

    @property
    def room(self) -> dict[str, Any]:
        return self.document["rooms"][self.room_index]

    def build_ui(self) -> None:
        toolbar = ttk.Frame(self, padding=7)
        toolbar.pack(fill="x")
        ttk.Button(toolbar, text="Previous", command=lambda: self.change_room(-1)).pack(side="left")
        ttk.Label(toolbar, text="Room").pack(side="left", padx=(8, 3))
        room_spin = ttk.Spinbox(
            toolbar,
            from_=1,
            to=room_data.ROOM_COUNT,
            textvariable=self.room_number,
            width=5,
            command=self.select_room,
        )
        room_spin.pack(side="left")
        room_spin.bind("<Return>", lambda _event: self.select_room())
        room_spin.bind("<FocusOut>", lambda _event: self.select_room())
        ttk.Button(toolbar, text="Next", command=lambda: self.change_room(1)).pack(
            side="left", padx=(3, 12)
        )
        ttk.Button(toolbar, text="Undo", command=self.undo).pack(side="left")
        ttk.Button(toolbar, text="Save", command=self.save).pack(side="left", padx=3)
        ttk.Button(toolbar, text="Build ROM", command=self.build_rom).pack(side="left")
        ttk.Button(toolbar, text="Validate", command=self.validate).pack(side="left", padx=3)
        ttk.Button(toolbar, text="Place player", command=self.arm_player).pack(side="left")
        ttk.Button(toolbar, text="Play", command=self.play).pack(side="left", padx=3)
        ttk.Label(toolbar, text="X").pack(side="left", padx=(8, 2))
        ttk.Spinbox(toolbar, from_=0, to=319, textvariable=self.player_x, width=4).pack(
            side="left"
        )
        ttk.Label(toolbar, text="Y").pack(side="left", padx=(5, 2))
        ttk.Spinbox(toolbar, from_=0, to=159, textvariable=self.player_y, width=4).pack(
            side="left"
        )

        body = ttk.Panedwindow(self, orient="horizontal")
        body.pack(fill="both", expand=True, padx=7, pady=(0, 7))
        self.map_notebook = ttk.Notebook(body)
        room_frame = ttk.Frame(self.map_notebook, padding=6)
        self.overview_frame = ttk.Frame(self.map_notebook, padding=6)
        self.map_notebook.add(room_frame, text="Room editor")
        self.map_notebook.add(self.overview_frame, text="Castle overview")
        self.map_notebook.bind("<<NotebookTabChanged>>", self.map_view_changed)
        side = ttk.Frame(body, padding=(7, 0, 0, 0))
        body.add(self.map_notebook, weight=5)
        body.add(side, weight=2)

        self.room_canvas = tk.Canvas(
            room_frame,
            width=room_data.ROOM_WIDTH * CELL_WIDTH,
            height=room_data.ROOM_HEIGHT * CELL_HEIGHT,
            background="#101820",
            highlightthickness=0,
        )
        self.room_canvas.pack(fill="both", expand=True)
        self.room_canvas.bind("<Button-1>", self.room_click)
        self.room_canvas.bind("<B1-Motion>", self.room_drag)
        self.room_canvas.bind("<ButtonRelease-1>", self.room_release)
        self.room_canvas.bind("<Button-3>", self.sample_cell)

        overview_toolbar = ttk.Frame(self.overview_frame)
        overview_toolbar.pack(fill="x", pady=(0, 5))
        ttk.Label(overview_toolbar, text="Scale").pack(side="left")
        zoom = ttk.Combobox(
            overview_toolbar,
            textvariable=self.overview_zoom,
            values=tuple(OVERVIEW_ZOOM_DIVISORS),
            width=6,
            state="readonly",
        )
        zoom.pack(side="left", padx=(4, 8))
        zoom.bind("<<ComboboxSelected>>", self.overview_zoom_changed)
        ttk.Button(
            overview_toolbar, text="Center selected", command=self.center_selected_room
        ).pack(side="left")
        ttk.Button(
            overview_toolbar, text="Open room", command=self.open_selected_room
        ).pack(side="left", padx=4)
        ttk.Label(
            overview_toolbar,
            text="Drag to pan; click selects; double-click opens",
        ).pack(side="right")

        overview_body = ttk.Frame(self.overview_frame)
        overview_body.pack(fill="both", expand=True)
        overview_body.rowconfigure(0, weight=1)
        overview_body.columnconfigure(0, weight=1)
        self.overview_canvas = tk.Canvas(
            overview_body,
            background="#101820",
            highlightthickness=0,
        )
        overview_x_scroll = ttk.Scrollbar(
            overview_body, orient="horizontal", command=self.overview_canvas.xview
        )
        overview_y_scroll = ttk.Scrollbar(
            overview_body, orient="vertical", command=self.overview_canvas.yview
        )
        self.overview_canvas.configure(
            xscrollcommand=overview_x_scroll.set,
            yscrollcommand=overview_y_scroll.set,
        )
        self.overview_canvas.grid(row=0, column=0, sticky="nsew")
        overview_y_scroll.grid(row=0, column=1, sticky="ns")
        overview_x_scroll.grid(row=1, column=0, sticky="ew")
        self.overview_canvas.bind("<ButtonPress-1>", self.overview_press)
        self.overview_canvas.bind("<B1-Motion>", self.overview_drag)
        self.overview_canvas.bind("<ButtonRelease-1>", self.overview_release)
        self.overview_canvas.bind("<Double-Button-1>", self.overview_open_at)
        self.overview_canvas.bind("<MouseWheel>", self.overview_mousewheel)

        notebook = ttk.Notebook(side)
        notebook.pack(fill="both", expand=True)
        cell_frame = ttk.Frame(notebook, padding=5)
        object_frame = ttk.Frame(notebook, padding=5)
        notebook.add(cell_frame, text="Cells")
        notebook.add(object_frame, text="Objects")

        ttk.Label(
            cell_frame,
            text="Left-drag paints. Right-click samples. Only symbols in the original room codebook are offered.",
            wraplength=330,
        ).pack(fill="x", pady=(0, 5))
        self.palette_canvas = tk.Canvas(
            cell_frame,
            width=PALETTE_COLUMNS * CELL_WIDTH,
            height=10 * (CELL_HEIGHT + 10),
            background="#202830",
            highlightthickness=0,
        )
        palette_scroll = ttk.Scrollbar(
            cell_frame, orient="vertical", command=self.palette_canvas.yview
        )
        self.palette_canvas.configure(yscrollcommand=palette_scroll.set)
        self.palette_canvas.pack(side="left", fill="both", expand=True)
        palette_scroll.pack(side="right", fill="y")
        self.palette_canvas.bind("<Button-1>", self.select_brush)

        actions = ttk.Frame(object_frame)
        actions.pack(fill="x", pady=(0, 5))
        ttk.Button(actions, text="Place object", command=self.arm_object).pack(side="left")
        ttk.Button(actions, text="Delete", command=self.delete_object).pack(
            side="left", padx=3
        )
        self.object_tree = ttk.Treeview(
            object_frame,
            columns=("encoded", "runtime", "x", "y"),
            show="headings",
            height=13,
        )
        for column, heading, width in (
            ("encoded", "Encoded", 70),
            ("runtime", "Runtime", 70),
            ("x", "X", 35),
            ("y", "Y", 35),
        ):
            self.object_tree.heading(column, text=heading)
            self.object_tree.column(column, width=width, stretch=False)
        self.object_tree.pack(fill="both", expand=True)
        self.object_tree.bind("<<TreeviewSelect>>", self.select_object)

        editor = ttk.LabelFrame(object_frame, text="Selected object", padding=6)
        editor.pack(fill="x", pady=(7, 0))
        for row, (label, variable) in enumerate((
            ("Encoded type", self.object_type),
            ("X cell", self.object_x),
            ("Y row", self.object_y),
        )):
            ttk.Label(editor, text=label).grid(row=row, column=0, sticky="w")
            ttk.Entry(editor, textvariable=variable, width=12).grid(
                row=row, column=1, sticky="ew", padx=(5, 0)
            )
        ttk.Button(editor, text="Apply", command=self.apply_object).grid(
            row=3, column=0, columnspan=2, sticky="ew", pady=(5, 0)
        )
        ttk.Label(
            editor,
            text="Values accept decimal, 0x-prefixed, or $-prefixed hexadecimal input.",
            wraplength=300,
        ).grid(row=4, column=0, columnspan=2, sticky="w", pady=(6, 0))

        ttk.Label(self, textvariable=self.status, anchor="w", padding=7).pack(fill="x")

    def parse_number(self, value: str, name: str) -> int:
        text = value.strip()
        if text.startswith("$"):
            text = "0x" + text[1:]
        try:
            return int(text, 0)
        except ValueError as exc:
            raise level_editor.LevelEditorError(f"invalid {name}: {value!r}") from exc

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
            messagebox.showerror("Castle Excellent Level Studio", str(exc))

    def validated_change(self, action: Callable[[], None]) -> None:
        before = deepcopy(self.document)
        changed_room = self.room_index
        try:
            action()
            rooms = level_editor.validate_workspace(
                self.document, self.profile_id, self.prg
            )
            level_editor.compose_levels(
                self.image, self.prg, self.chr_data, rooms, self.config
            )
        except Exception:
            self.document = before
            raise
        self.undo_stack.append(before)
        del self.undo_stack[:-40]
        self.invalidate_overview_room(changed_room)
        self.dirty = True
        self.refresh()

    def select_room(self) -> None:
        self.guarded(self._select_room)

    def _select_room(self) -> None:
        number = self.room_number.get()
        if not 1 <= number <= room_data.ROOM_COUNT:
            raise level_editor.LevelEditorError("room number must be between 1 and 100")
        self.selected_object = None
        self.object_placement = False
        self.player_placement = False
        self.refresh()

    def change_room(self, delta: int) -> None:
        self.room_number.set((self.room_index + delta) % room_data.ROOM_COUNT + 1)
        self._select_room()

    def map_view_changed(self, _event: tk.Event) -> None:
        if self.overview_visible():
            self.draw_castle_overview()

    def overview_visible(self) -> bool:
        return self.map_notebook.select() == str(self.overview_frame)

    def overview_divisor(self) -> int:
        return OVERVIEW_ZOOM_DIVISORS[self.overview_zoom.get()]

    def overview_zoom_changed(self, _event: tk.Event | None = None) -> None:
        self.draw_castle_overview()
        self.center_selected_room()

    def overview_geometry(self) -> tuple[int, int, int, int]:
        divisor = self.overview_divisor()
        room_width = room_data.ROOM_WIDTH * 16 // divisor
        room_height = room_data.ROOM_HEIGHT * 8 // divisor
        return room_width, room_height, room_width + OVERVIEW_GAP, room_height + OVERVIEW_GAP

    def overview_room_at(self, event: tk.Event) -> int | None:
        room_width, room_height, pitch_x, pitch_y = self.overview_geometry()
        x = int(self.overview_canvas.canvasx(event.x)) - OVERVIEW_GAP
        y = int(self.overview_canvas.canvasy(event.y)) - OVERVIEW_GAP
        if x < 0 or y < 0:
            return None
        column, local_x = divmod(x, pitch_x)
        row, local_y = divmod(y, pitch_y)
        if (
            column >= studio_model.CASTLE_COLUMNS
            or row >= studio_model.CASTLE_ROWS
            or local_x >= room_width
            or local_y >= room_height
        ):
            return None
        return row * studio_model.CASTLE_COLUMNS + column + 1

    def overview_press(self, event: tk.Event) -> None:
        self.overview_drag_origin = (event.x, event.y)
        self.overview_is_panning = False
        self.overview_canvas.scan_mark(event.x, event.y)

    def overview_drag(self, event: tk.Event) -> None:
        if self.overview_drag_origin is None:
            return
        delta_x = event.x - self.overview_drag_origin[0]
        delta_y = event.y - self.overview_drag_origin[1]
        if abs(delta_x) + abs(delta_y) >= 4:
            self.overview_is_panning = True
        if self.overview_is_panning:
            self.overview_canvas.scan_dragto(event.x, event.y, gain=1)

    def overview_release(self, event: tk.Event) -> None:
        if not self.overview_is_panning:
            room_number = self.overview_room_at(event)
            if room_number is not None:
                self.room_number.set(room_number)
                self._select_room()
        self.overview_drag_origin = None
        self.overview_is_panning = False

    def overview_open_at(self, event: tk.Event) -> None:
        room_number = self.overview_room_at(event)
        if room_number is not None:
            self.room_number.set(room_number)
            self._select_room()
            self.open_selected_room()

    def overview_mousewheel(self, event: tk.Event) -> None:
        units = -1 if event.delta > 0 else 1
        if event.state & 0x0001:
            self.overview_canvas.xview_scroll(units, "units")
        else:
            self.overview_canvas.yview_scroll(units, "units")

    def open_selected_room(self) -> None:
        self.map_notebook.select(self.map_notebook.tabs()[0])

    def center_selected_room(self) -> None:
        room_width, room_height, pitch_x, pitch_y = self.overview_geometry()
        column, row = studio_model.castle_room_position(self.room_index + 1)
        center_x = OVERVIEW_GAP + column * pitch_x + room_width / 2
        center_y = OVERVIEW_GAP + row * pitch_y + room_height / 2
        region = self.overview_canvas.cget("scrollregion").split()
        if len(region) != 4:
            return
        total_width = float(region[2])
        total_height = float(region[3])
        viewport_width = max(1, self.overview_canvas.winfo_width())
        viewport_height = max(1, self.overview_canvas.winfo_height())
        if total_width > viewport_width:
            self.overview_canvas.xview_moveto(
                max(0.0, min(1.0, (center_x - viewport_width / 2) / total_width))
            )
        if total_height > viewport_height:
            self.overview_canvas.yview_moveto(
                max(0.0, min(1.0, (center_y - viewport_height / 2) / total_height))
            )

    def invalidate_overview_room(self, room_index: int) -> None:
        for key in tuple(self.overview_image_cache):
            if key[0] == room_index:
                del self.overview_image_cache[key]

    def cell_at(self, event: tk.Event) -> tuple[int, int] | None:
        column = int(self.room_canvas.canvasx(event.x)) // CELL_WIDTH
        row = int(self.room_canvas.canvasy(event.y)) // CELL_HEIGHT
        if 0 <= column < room_data.ROOM_WIDTH and 0 <= row < room_data.ROOM_HEIGHT:
            return column, row
        return None

    def room_click(self, event: tk.Event) -> None:
        point = self.cell_at(event)
        if point is None:
            return
        if self.player_placement:
            column, row = point
            self.player_x.set(column * 16)
            self.player_y.set(row * 8)
            self.player_placement = False
            self.refresh()
            return
        if self.object_placement:
            self.guarded(lambda: self.place_object(*point))
            return
        self.paint_cell(*point)

    def room_drag(self, event: tk.Event) -> None:
        if self.object_placement:
            return
        point = self.cell_at(event)
        if point is not None:
            self.paint_cell(*point)

    def room_release(self, _event: tk.Event) -> None:
        self.last_painted = None

    def paint_cell(self, column: int, row: int) -> None:
        cell_type = self.brush.get()
        marker = (column, row, cell_type)
        if marker == self.last_painted or self.room["cells"][row][column] == cell_type:
            return
        self.last_painted = marker
        self.guarded(
            lambda: self.validated_change(
                lambda: self.room["cells"][row].__setitem__(column, cell_type)
            )
        )

    def sample_cell(self, event: tk.Event) -> None:
        point = self.cell_at(event)
        if point is None:
            return
        column, row = point
        self.brush.set(self.room["cells"][row][column])
        self.draw_palette()

    def select_brush(self, event: tk.Event) -> None:
        column = int(self.palette_canvas.canvasx(event.x)) // CELL_WIDTH
        row = int(self.palette_canvas.canvasy(event.y)) // (CELL_HEIGHT + 10)
        index = row * PALETTE_COLUMNS + column
        if 0 <= index < len(self.cell_types):
            self.brush.set(self.cell_types[index])
            self.draw_palette()

    def arm_object(self) -> None:
        self.object_placement = True
        self.player_placement = False
        self.status.set("Click a room cell to place the new object")

    def arm_player(self) -> None:
        self.player_placement = True
        self.object_placement = False
        self.status.set("Click a room cell to choose the playtest player position")

    def place_object(self, column: int, row: int) -> None:
        encoded_type = self.parse_number(self.object_type.get(), "encoded type")

        def action() -> None:
            self.room["objects"].append(
                {"encoded_type": encoded_type, "x": column, "y": row}
            )

        self.validated_change(action)
        self.object_placement = False
        self.selected_object = len(self.room["objects"]) - 1
        self.refresh()

    def select_object(self, _event: tk.Event) -> None:
        selected = self.object_tree.selection()
        if not selected:
            return
        index = int(selected[0])
        record = self.room["objects"][index]
        self.selected_object = index
        self.object_type.set(f"0x{record['encoded_type']:02X}")
        self.object_x.set(str(record["x"]))
        self.object_y.set(str(record["y"]))
        self.draw_room()

    def apply_object(self) -> None:
        def action() -> None:
            if self.selected_object is None:
                raise level_editor.LevelEditorError("select an object first")
            self.room["objects"][self.selected_object] = {
                "encoded_type": self.parse_number(self.object_type.get(), "encoded type"),
                "x": self.parse_number(self.object_x.get(), "object X"),
                "y": self.parse_number(self.object_y.get(), "object Y"),
            }

        self.guarded(lambda: self.validated_change(action))

    def delete_object(self) -> None:
        def action() -> None:
            if self.selected_object is None:
                raise level_editor.LevelEditorError("select an object first")
            del self.room["objects"][self.selected_object]
            self.selected_object = None

        self.guarded(lambda: self.validated_change(action))

    def undo(self) -> None:
        if not self.undo_stack:
            return
        self.document = self.undo_stack.pop()
        self.overview_image_cache.clear()
        self.dirty = True
        self.selected_object = None
        self.refresh()

    def save(self) -> None:
        self.guarded(self._save)

    def _save(self) -> None:
        level_editor.validate_workspace(self.document, self.profile_id, self.prg)
        level_editor.atomic_write_json(self.workspace_path, self.document)
        self.dirty = False
        self.update_status("workspace saved")

    def validate(self) -> None:
        self.guarded(self._validate)

    def _validate(self) -> None:
        rooms = level_editor.validate_workspace(self.document, self.profile_id, self.prg)
        level_editor.compose_levels(self.image, self.prg, self.chr_data, rooms, self.config)
        self.update_status("workspace and fixed capacities are valid")

    def build_rom(self) -> None:
        self.guarded(self._build_rom)

    def _build_rom(self) -> None:
        self._save()
        rooms = level_editor.validate_workspace(self.document, self.profile_id, self.prg)
        output, report = level_editor.compose_levels(
            self.image, self.prg, self.chr_data, rooms, self.config
        )
        output_path = level_editor.project_path(self.profile["output_rom"])
        report_path = level_editor.project_path(self.profile["report"])
        level_editor.atomic_write(output_path, output)
        report["profile"] = self.profile_id
        report["workspace"] = self.profile["workspace"]
        level_editor.atomic_write_json(report_path, report)
        self.update_status(
            f"built {output_path.name}: {report['changed_bytes']} changed ROM bytes"
        )

    def play(self) -> None:
        self.guarded(self._play)

    def _play(self) -> None:
        studio_model.validate_playtest_position(
            self.room_index + 1, self.player_x.get(), self.player_y.get()
        )
        self._build_rom()
        output_path = level_editor.project_path(self.profile["output_rom"])
        fceux = level_editor.ROOT / "tools" / "fceux" / "fceux64.exe"
        lua = studio_model.LEVEL_PLAYTEST_SCRIPT
        if not fceux.is_file():
            raise level_editor.LevelEditorError(
                "pinned FCEUX is not installed; run make fceux-bootstrap"
            )
        level_playtest.launch_interactive(
            fceux,
            output_path,
            lua,
            self.room_index + 1,
            self.player_x.get(),
            self.player_y.get(),
        )
        self.update_status(f"launched room {self.room_index + 1} in FCEUX")

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

    def refresh(self) -> None:
        self.draw_room()
        self.draw_palette()
        self.draw_objects()
        if self.overview_visible():
            self.draw_castle_overview()
        self.update_status()

    def close(self) -> None:
        if self.dirty and not messagebox.askyesno(
            "Castle Excellent Level Studio", "Discard unsaved level changes?"
        ):
            return
        self.destroy()


def load_studio(args: argparse.Namespace) -> tuple[
    dict[str, Any],
    dict[str, Any],
    dict[str, Any],
    bytes,
    bytes,
    bytes,
    Path,
    dict[str, Any],
]:
    config, authoring_profile = level_editor.load_authoring(
        Path(args.authoring), args.profile
    )
    revision, image, prg, chr_data = level_editor.load_base_image(
        Path(args.revisions), args.profile
    )
    workspace_path = level_editor.project_path(authoring_profile["workspace"])
    if workspace_path.is_file():
        document = level_editor.load_json(workspace_path)
    else:
        document = level_editor.decode_workspace(args.profile, prg, chr_data)
    return config, authoring_profile, revision, image, prg, chr_data, workspace_path, document


def check_studio(args: argparse.Namespace) -> None:
    config, _profile = level_editor.load_authoring(Path(args.authoring), args.profile)
    _revision, image, prg, chr_data = level_editor.load_base_image(
        Path(args.revisions), args.profile
    )
    document = level_editor.decode_workspace(args.profile, prg, chr_data)
    rooms = level_editor.validate_workspace(document, args.profile, prg)
    level_editor.compose_levels(image, prg, chr_data, rooms, config)
    tiles = studio_model.decode_chr_bank(chr_data)
    if len(tiles) != studio_model.TILES_PER_BANK:
        raise studio_model.LevelStudioModelError("gameplay CHR tile count changed")
    background_palettes = studio_model.room_palette(prg)
    sprite_palettes = studio_model.sprite_palette(prg)
    for room in document["rooms"]:
        studio_model.room_thumbnail_colors(
            prg,
            tiles,
            background_palettes,
            sprite_palettes,
            room,
            4,
        )
    print(
        f"[OK] level studio model: {len(rooms)} rooms, "
        f"{len(studio_model.compression_symbols(prg))} paintable cell types, "
        "complete castle overview"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--authoring", default="config/level_authoring.json")
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
        config, profile, _revision, image, prg, chr_data, path, document = load_studio(args)
        application = LevelStudio(
            document, config, profile, image, prg, chr_data, path, args.profile
        )
        if args.smoke_ui:
            application.map_notebook.select(application.overview_frame)
            application.draw_castle_overview()
            application.update_idletasks()
            if len(application.overview_image_cache) != room_data.ROOM_COUNT:
                raise studio_model.LevelStudioModelError(
                    "castle overview did not render all 100 rooms"
                )
            application.destroy()
            print("[OK] level studio widgets and 100-room overview constructed")
        else:
            application.mainloop()
    except (
        OSError,
        ProjectError,
        level_editor.LevelEditorError,
        studio_model.LevelStudioModelError,
        room_data.RoomDataError,
        tk.TclError,
    ) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
