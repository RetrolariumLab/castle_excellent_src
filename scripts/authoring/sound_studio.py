#!/usr/bin/env python3
"""Dependency-free visual editor for Castle Excellent textual music."""

from __future__ import annotations

import argparse
from copy import deepcopy
from pathlib import Path
import sys
import tkinter as tk
from tkinter import messagebox, ttk
from typing import Any, Callable

from scripts.authoring import audio_data
from scripts.authoring import music_editor
from scripts.authoring import room_data
from scripts.authoring import sound_studio_model as studio_model
from scripts.build.project import ProjectError


class SoundStudio(tk.Tk):
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
        self.profile = profile
        self.image = image
        self.prg = prg
        self.chr_data = chr_data
        self.workspace_path = workspace_path
        self.profile_id = profile_id
        self.selected_stream = 0
        self.selected_track = 0
        self.track_choice = tk.StringVar(value=studio_model.track_label(0))
        self.channel_enabled = {
            name: tk.BooleanVar(value=True)
            for name, _offset in studio_model.CHANNELS
        }
        self.undo_stack: list[dict[str, Any]] = []
        self.dirty = False
        self.status = tk.StringVar()
        self.restart = tk.StringVar()
        self.track_streams = [tk.StringVar() for _ in range(3)]
        self.track_parameters = [tk.StringVar() for _ in range(2)]
        self.title(f"Castle Excellent Sound Studio [{profile_id}]")
        self.geometry("1240x820")
        self.minsize(960, 680)
        self.protocol("WM_DELETE_WINDOW", self.close)
        self.build_ui()
        self.bind_all("<Control-s>", lambda _event: self.save())
        self.bind_all("<Control-z>", lambda _event: self.undo())
        self.refresh()

    @property
    def stream(self) -> dict[str, Any]:
        return self.document["streams"][self.selected_stream]

    @property
    def track(self) -> dict[str, Any]:
        return self.document["track_sets"][self.selected_track]

    @property
    def stream_choices(self) -> list[str]:
        return ["None"] + [stream["id"] for stream in self.document["streams"]]

    def build_ui(self) -> None:
        toolbar = ttk.Frame(self, padding=7)
        toolbar.pack(fill="x")
        ttk.Button(toolbar, text="Undo", command=self.undo).pack(side="left")
        ttk.Button(toolbar, text="Save", command=self.save).pack(side="left", padx=3)
        ttk.Button(toolbar, text="Build ROM", command=self.build_rom).pack(side="left")
        ttk.Button(toolbar, text="Validate", command=self.validate).pack(
            side="left", padx=3
        )
        ttk.Label(toolbar, text="Track").pack(side="left", padx=(12, 3))
        self.track_box = ttk.Combobox(
            toolbar,
            textvariable=self.track_choice,
            state="readonly",
            width=27,
            values=[studio_model.track_label(index) for index in range(8)],
        )
        self.track_box.pack(side="left")
        self.track_box.bind("<<ComboboxSelected>>", self.select_track_box)
        ttk.Button(toolbar, text="Preview track", command=self.preview_track).pack(
            side="left", padx=(5, 2)
        )
        ttk.Button(toolbar, text="Stop", command=self.stop_preview).pack(side="left")

        body = ttk.Panedwindow(self, orient="horizontal")
        body.pack(fill="both", expand=True, padx=7, pady=(0, 7))
        navigator = ttk.Frame(body)
        editor = ttk.Frame(body)
        body.add(navigator, weight=2)
        body.add(editor, weight=5)

        streams_frame = ttk.LabelFrame(navigator, text="MML streams", padding=6)
        streams_frame.pack(fill="both", expand=True)
        self.stream_list = tk.Listbox(
            streams_frame,
            exportselection=False,
            font="TkFixedFont",
            width=28,
            height=16,
        )
        stream_scroll = ttk.Scrollbar(
            streams_frame, orient="vertical", command=self.stream_list.yview
        )
        self.stream_list.configure(yscrollcommand=stream_scroll.set)
        self.stream_list.pack(side="left", fill="both", expand=True)
        stream_scroll.pack(side="right", fill="y")
        self.stream_list.bind("<<ListboxSelect>>", self.select_stream)

        tracks_frame = ttk.LabelFrame(navigator, text="Track sets", padding=6)
        tracks_frame.pack(fill="x", pady=(7, 0))
        self.track_list = tk.Listbox(
            tracks_frame, exportselection=False, font="TkFixedFont", height=8
        )
        self.track_list.pack(fill="x")
        self.track_list.bind("<<ListboxSelect>>", self.select_track)

        sequencer = ttk.LabelFrame(editor, text="Track lanes", padding=7)
        sequencer.pack(fill="both", expand=True)
        mixer = ttk.Frame(sequencer)
        mixer.pack(fill="x", pady=(0, 5))
        ttk.Label(mixer, text="Preview channels:").pack(side="left")
        for name, _offset in studio_model.CHANNELS:
            ttk.Checkbutton(
                mixer,
                text=name,
                variable=self.channel_enabled[name],
                command=self.draw_lanes,
            ).pack(side="left", padx=8)
        lane_frame = ttk.Frame(sequencer)
        lane_frame.pack(fill="both", expand=True)
        self.lane_canvas = tk.Canvas(
            lane_frame,
            height=230,
            background="#111824",
            highlightthickness=0,
        )
        lane_scroll = ttk.Scrollbar(
            lane_frame, orient="horizontal", command=self.lane_canvas.xview
        )
        self.lane_canvas.configure(xscrollcommand=lane_scroll.set)
        self.lane_canvas.pack(fill="both", expand=True)
        lane_scroll.pack(fill="x")

        stream_editor = ttk.LabelFrame(editor, text="Textual MML stream", padding=7)
        stream_editor.pack(fill="both", expand=True, pady=(7, 0))
        ttk.Label(
            stream_editor,
            text=(
                "Edit the engine's original ASCII command language. Apply validates "
                "grammar and the complete fixed arena before accepting the change."
            ),
            wraplength=650,
        ).pack(fill="x", pady=(0, 6))
        text_frame = ttk.Frame(stream_editor)
        text_frame.pack(fill="both", expand=True)
        self.mml_text = tk.Text(
            text_frame,
            wrap="word",
            undo=False,
            font="TkFixedFont",
            height=18,
        )
        text_scroll = ttk.Scrollbar(
            text_frame, orient="vertical", command=self.mml_text.yview
        )
        self.mml_text.configure(yscrollcommand=text_scroll.set)
        self.mml_text.pack(side="left", fill="both", expand=True)
        text_scroll.pack(side="right", fill="y")

        stream_actions = ttk.Frame(stream_editor)
        stream_actions.pack(fill="x", pady=(6, 0))
        ttk.Label(stream_actions, text="Restart").pack(side="left")
        self.restart_combo = ttk.Combobox(
            stream_actions,
            textvariable=self.restart,
            state="readonly",
            width=14,
        )
        self.restart_combo.pack(side="left", padx=(5, 10))
        ttk.Button(
            stream_actions, text="Apply stream", command=self.apply_stream
        ).pack(side="left")

        track_editor = ttk.LabelFrame(editor, text="Selected track set", padding=7)
        track_editor.pack(fill="x", pady=(7, 0))
        for column, label in enumerate(("Pulse 1", "Pulse 2", "Triangle")):
            ttk.Label(track_editor, text=label).grid(
                row=0, column=column, sticky="w"
            )
            combo = ttk.Combobox(
                track_editor,
                textvariable=self.track_streams[column],
                state="readonly",
                width=14,
            )
            combo.grid(row=1, column=column, sticky="ew", padx=(0, 6))
            setattr(self, f"track_stream_combo_{column}", combo)
        for column, label in enumerate(("Parameter 1", "Parameter 2")):
            ttk.Label(track_editor, text=label).grid(
                row=2, column=column, sticky="w", pady=(7, 0)
            )
            ttk.Entry(
                track_editor,
                textvariable=self.track_parameters[column],
                width=14,
            ).grid(row=3, column=column, sticky="ew", padx=(0, 6))
        ttk.Button(track_editor, text="Apply track", command=self.apply_track).grid(
            row=3, column=2, sticky="ew"
        )
        for column in range(3):
            track_editor.columnconfigure(column, weight=1)

        ttk.Label(self, textvariable=self.status, anchor="w", padding=7).pack(
            fill="x"
        )

    def guarded(self, action: Callable[[], None]) -> None:
        try:
            action()
        except (
            OSError,
            KeyError,
            TypeError,
            ValueError,
            ProjectError,
            audio_data.AudioDataError,
            room_data.RoomDataError,
        ) as exc:
            messagebox.showerror("Castle Excellent Sound Studio", str(exc))

    def validated_change(self, action: Callable[[], None]) -> None:
        before = deepcopy(self.document)
        try:
            action()
            validated = music_editor.validate_workspace(
                self.document, self.profile_id
            )
            music_editor.compose_music(
                self.image, self.prg, self.chr_data, validated
            )
        except Exception:
            self.document = before
            raise
        self.undo_stack.append(before)
        del self.undo_stack[:-40]
        self.dirty = True
        self.refresh()

    def select_stream(self, _event: tk.Event) -> None:
        selected = self.stream_list.curselection()
        if not selected:
            return
        self.selected_stream = selected[0]
        self.load_stream_editor()
        self.update_status()

    def select_track(self, _event: tk.Event) -> None:
        selected = self.track_list.curselection()
        if not selected:
            return
        self.selected_track = selected[0]
        self.track_choice.set(studio_model.track_label(self.selected_track))
        self.load_track_editor()
        self.draw_lanes()
        self.update_status()

    def select_track_box(self, _event: tk.Event) -> None:
        self.selected_track = self.track_box.current()
        self.track_list.selection_clear(0, "end")
        self.track_list.selection_set(self.selected_track)
        self.track_list.see(self.selected_track)
        self.load_track_editor()
        self.draw_lanes()
        self.update_status()

    def apply_stream(self) -> None:
        def action() -> None:
            text = self.mml_text.get("1.0", "end-1c")
            restart = self.restart.get()
            self.stream["text"] = text
            self.stream["restart"] = None if restart == "None" else restart

        self.guarded(lambda: self.validated_change(action))

    def apply_track(self) -> None:
        def action() -> None:
            self.track["streams"] = [
                None if variable.get() == "None" else variable.get()
                for variable in self.track_streams
            ]
            self.track["channel_parameters"] = [
                studio_model.parse_byte(variable.get(), f"parameter {index + 1}")
                for index, variable in enumerate(self.track_parameters)
            ]

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
        music_editor.validate_workspace(self.document, self.profile_id)
        music_editor.atomic_write_json(self.workspace_path, self.document)
        self.dirty = False
        self.update_status("workspace saved")

    def validate(self) -> None:
        self.guarded(self._validate)

    def _validate(self) -> None:
        validated = music_editor.validate_workspace(self.document, self.profile_id)
        music_editor.compose_music(self.image, self.prg, self.chr_data, validated)
        self.update_status("workspace and fixed arena are valid")

    def build_rom(self) -> None:
        self.guarded(self._build_rom)

    def _build_rom(self) -> None:
        self._save()
        validated = music_editor.validate_workspace(self.document, self.profile_id)
        output, report = music_editor.compose_music(
            self.image, self.prg, self.chr_data, validated
        )
        output_path = music_editor.project_path(self.profile["output_rom"])
        report_path = music_editor.project_path(self.profile["report"])
        music_editor.atomic_write(output_path, output)
        report["profile"] = self.profile_id
        report["workspace"] = self.profile["workspace"]
        music_editor.atomic_write_json(report_path, report)
        self.update_status(
            f"built {output_path.name}: {report['changed_bytes']} changed ROM bytes"
        )

    def preview_prg(self) -> bytes:
        validated = music_editor.validate_workspace(self.document, self.profile_id)
        output, _report = music_editor.compose_music(
            self.image, self.prg, self.chr_data, validated
        )
        preview_prg, _preview_chr = room_data.extract_rom(output)
        return preview_prg

    def draw_lanes(self) -> None:
        if not hasattr(self, "lane_canvas"):
            return
        self.lane_canvas.delete("all")
        lanes = studio_model.track_lanes(
            self.preview_prg(), self.selected_track, max_frames=600
        )
        colors = ("#55b9ff", "#ffcf5a", "#8ef28e")
        frame_width = 2
        left = 82
        lane_height = 72
        for lane_index, lane in enumerate(lanes):
            top = lane_index * lane_height
            enabled = self.channel_enabled[lane.name].get()
            self.lane_canvas.create_rectangle(
                0,
                top,
                left + 600 * frame_width,
                top + lane_height,
                fill="#111824" if enabled else "#1b1d22",
                outline="#334354",
            )
            self.lane_canvas.create_text(
                8,
                top + 12,
                text=lane.name,
                fill="#f1f5f9" if enabled else "#687582",
                anchor="nw",
                font=("TkDefaultFont", 9, "bold"),
            )
            notes = [event for event in lane.events if event.frequency > 0]
            midi_values = [
                round(69 + 12 * __import__("math").log2(event.frequency / 440.0))
                for event in notes
            ]
            low = min(midi_values, default=0)
            high = max(midi_values, default=1)
            span = max(1, high - low)
            for event in lane.events:
                x0 = left + event.start_frame * frame_width
                x1 = x0 + max(2, event.duration_frames * frame_width)
                if event.frequency <= 0:
                    y0 = top + lane_height - 12
                    fill = "#303b48"
                else:
                    midi = round(
                        69 + 12 * __import__("math").log2(event.frequency / 440.0)
                    )
                    y0 = top + 51 - (midi - low) * 38 / span
                    fill = colors[lane_index] if enabled else "#46505a"
                self.lane_canvas.create_rectangle(
                    x0, y0, x1, y0 + 8, fill=fill, outline=""
                )
                if event.frequency > 0 and x1 - x0 >= 30:
                    self.lane_canvas.create_text(
                        x0 + 3,
                        y0 + 4,
                        text=event.note,
                        fill="#071018",
                        anchor="w",
                        font=("TkFixedFont", 7),
                    )
        self.lane_canvas.configure(
            scrollregion=(0, 0, left + 600 * frame_width, len(lanes) * lane_height)
        )

    def preview_track(self) -> None:
        self.guarded(self._preview_track)

    def _preview_track(self) -> None:
        enabled = {
            name for name, variable in self.channel_enabled.items() if variable.get()
        }
        path = self.workspace_path.with_name("preview.wav")
        studio_model.write_track_preview(
            self.preview_prg(),
            self.selected_track,
            path,
            enabled_channels=enabled,
        )
        if sys.platform == "win32":
            import winsound

            winsound.PlaySound(str(path), winsound.SND_FILENAME | winsound.SND_ASYNC)
        self.update_status(
            f"previewing {studio_model.track_label(self.selected_track)}"
        )

    @staticmethod
    def stop_preview() -> None:
        if sys.platform == "win32":
            import winsound

            winsound.PlaySound(None, winsound.SND_PURGE)

    def load_stream_editor(self) -> None:
        self.mml_text.delete("1.0", "end")
        self.mml_text.insert("1.0", self.stream["text"])
        self.restart_combo.configure(values=self.stream_choices)
        self.restart.set(self.stream["restart"] or "None")

    def load_track_editor(self) -> None:
        choices = self.stream_choices
        for index, pointer in enumerate(self.track["streams"]):
            combo = getattr(self, f"track_stream_combo_{index}")
            combo.configure(values=choices)
            self.track_streams[index].set(pointer or "None")
        for index, value in enumerate(self.track["channel_parameters"]):
            self.track_parameters[index].set(f"0x{value:02X}")

    def refresh_lists(self) -> None:
        self.stream_list.delete(0, "end")
        for stream in self.document["streams"]:
            self.stream_list.insert("end", studio_model.stream_label(stream))
        self.stream_list.selection_set(self.selected_stream)
        self.stream_list.see(self.selected_stream)
        self.track_list.delete(0, "end")
        for track in self.document["track_sets"]:
            active = sum(pointer is not None for pointer in track["streams"])
            self.track_list.insert(
                "end",
                f"{studio_model.track_label(track['index'])}  {active}/3",
            )
        self.track_list.selection_set(self.selected_track)
        self.track_choice.set(studio_model.track_label(self.selected_track))

    def update_status(self, suffix: str = "") -> None:
        summary = studio_model.summarize(self.document, self.profile_id)
        marker = "modified" if self.dirty else "saved"
        detail = (
            f"{summary.stream_count} streams | {summary.track_count} track sets | "
            f"{summary.used_bytes}/{summary.capacity_bytes} MML bytes "
            f"({summary.free_bytes} free) | {marker}"
        )
        if suffix:
            detail += f" | {suffix}"
        self.status.set(detail)

    def refresh(self) -> None:
        self.refresh_lists()
        self.load_stream_editor()
        self.load_track_editor()
        self.draw_lanes()
        self.update_status()

    def close(self) -> None:
        if self.dirty and not messagebox.askyesno(
            "Castle Excellent Sound Studio", "Discard unsaved music changes?"
        ):
            return
        self.stop_preview()
        self.destroy()


def load_studio(args: argparse.Namespace) -> tuple[
    dict[str, Any],
    bytes,
    bytes,
    bytes,
    Path,
    dict[str, Any],
]:
    _config, authoring_profile = music_editor.load_authoring(
        Path(args.authoring), args.profile
    )
    _revision, image, prg, chr_data = music_editor.load_base_image(
        Path(args.revisions), args.profile
    )
    workspace_path = music_editor.project_path(authoring_profile["workspace"])
    if workspace_path.is_file():
        document = music_editor.load_json(workspace_path)
    else:
        document = music_editor.decode_workspace(args.profile, prg)
    return authoring_profile, image, prg, chr_data, workspace_path, document


def check_studio(args: argparse.Namespace) -> None:
    music_editor.load_authoring(Path(args.authoring), args.profile)
    _revision, image, prg, chr_data = music_editor.load_base_image(
        Path(args.revisions), args.profile
    )
    document = music_editor.decode_workspace(args.profile, prg)
    summary = studio_model.summarize(document, args.profile)
    validated = music_editor.validate_workspace(document, args.profile)
    music_editor.compose_music(image, prg, chr_data, validated)
    for stream in document["streams"]:
        studio_model.stream_label(stream)
    print(
        f"[OK] sound studio model: {summary.track_count} track sets, "
        f"{summary.stream_count} streams, {summary.used_bytes}/"
        f"{summary.capacity_bytes} MML bytes"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--authoring", default="config/audio_authoring.json")
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
        application = SoundStudio(
            document, profile, image, prg, chr_data, path, args.profile
        )
        if args.smoke_ui:
            application.update_idletasks()
            application.destroy()
            print("[OK] sound studio widgets constructed")
        else:
            application.mainloop()
    except (
        OSError,
        ProjectError,
        music_editor.MusicEditorError,
        studio_model.SoundStudioModelError,
        audio_data.AudioDataError,
        room_data.RoomDataError,
        tk.TclError,
    ) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
