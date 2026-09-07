from pathlib import Path
import unittest

from scripts.validation.audio import audio_stream_engine as engine


ROOT = Path(__file__).resolve().parent.parent


class AudioStreamEngineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = engine.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )

    def test_stop_and_clear_have_exact_write_sets(self) -> None:
        self.assertEqual(
            engine.stop_audio_stream_writes(),
            {
                0x4015: 0,
                0xDB: 0,
                0xDC: 0,
                0xDF: 0,
                0xE0: 0,
                0xE3: 0,
                0xE4: 0,
            },
        )
        self.assertEqual(
            engine.clear_sound_effect_request_writes(),
            {0xEC: 0, 0xEF: 0, 0xF2: 0, 0xF5: 0},
        )

    def test_sound_request_routing_and_invalid_channel_sentinel(self) -> None:
        values = {
            x: engine.read_channel_sound_request(
                x, pulse1=0x11, pulse2=0x22, triangle=0x33
            )
            for x in (0, 4, 8, 1, 0xFF)
        }
        self.assertEqual(values, {0: 0x11, 4: 0x22, 8: 0x33, 1: 0xFF, 0xFF: 0xFF})

    def test_pointer_increment_carries_and_wraps(self) -> None:
        self.assertEqual(engine.advance_audio_stream(0xB8FF), 0xB900)
        self.assertEqual(engine.advance_audio_stream(0xFFFF), 0)

    def test_tick_gates_only_at_three_when_sound_effect_is_idle(self) -> None:
        idle = engine.tick_audio_stream(
            pointer=0xBBE7, ticks_remaining=4, x=4, sound_effect_request=0
        )
        busy = engine.tick_audio_stream(
            pointer=0xBBE7, ticks_remaining=4, x=4, sound_effect_request=1
        )
        expired = engine.tick_audio_stream(
            pointer=0xBBE7, ticks_remaining=1, x=4, sound_effect_request=0
        )
        stopped = engine.tick_audio_stream(
            pointer=0, ticks_remaining=4, x=4, sound_effect_request=0
        )
        self.assertEqual(idle.apu_status_write, 0x0D)
        self.assertIsNone(busy.apu_status_write)
        self.assertTrue(expired.parse_event)
        self.assertEqual(stopped.ticks_remaining, 4)

    def test_channel_configuration_uses_channel_specific_registers(self) -> None:
        self.assertEqual(
            engine.configure_audio_channel(
                0, pulse1_parameters=0xA1, pulse2_parameters=0xB2
            ),
            {0x4015: 0x0F, 0x4000: 0xA1, 0x4001: 0x08},
        )
        self.assertEqual(
            engine.configure_audio_channel(
                4, pulse1_parameters=0xA1, pulse2_parameters=0xB2
            ),
            {0x4015: 0x0F, 0x4004: 0xB2, 0x4005: 0x08},
        )
        self.assertEqual(
            engine.configure_audio_channel(
                8, pulse1_parameters=0xA1, pulse2_parameters=0xB2
            ),
            {0x4015: 0x0F, 0x4008: 0xFF},
        )

    def test_commands_note_accidental_length_and_dot_are_consumed(self) -> None:
        prg = bytearray(self.prg)
        start = 0xBBE7
        data = b"t2o4l8vfc+4.\0\0\0"
        prg[start - engine.PRG_BASE:start - engine.PRG_BASE + len(data)] = data
        result = engine.decode_next_audio_event(
            bytes(prg),
            engine.AudioStreamState(start, 1, 0, 0),
            tempo_offset=0,
            x=0,
            sound_effect_request=0,
            pulse1_parameters=0x3F,
        )
        self.assertEqual(result.event, "note")
        self.assertEqual(result.commands_consumed, 4)
        self.assertEqual(result.tempo_offset, 16)
        self.assertEqual(result.state.octave_offset, 24)
        self.assertEqual(result.state.default_length_index, 1)
        self.assertEqual(result.period_table_index, 0x34)
        self.assertEqual(result.state.ticks_remaining, 42)
        self.assertEqual(result.apu_writes[0x4000], 0x3F)
        self.assertEqual(result.apu_writes[0x4002], 0x94)
        self.assertEqual(result.apu_writes[0x4003], 0x01)

    def test_rest_and_triangle_note_period_domains(self) -> None:
        prg = bytearray(self.prg)
        start = 0xBBE7
        prg[start - engine.PRG_BASE:start - engine.PRG_BASE + 8] = b"l2r8\0\0\0\0"
        rest = engine.decode_next_audio_event(
            bytes(prg),
            engine.AudioStreamState(start, 1, 0, 0),
            tempo_offset=0,
            x=8,
            sound_effect_request=0,
        )
        self.assertEqual(rest.event, "rest")
        self.assertEqual(rest.period_table_index, 0)
        self.assertEqual(rest.state.ticks_remaining, 10)
        self.assertEqual(rest.apu_writes[0x400A], 0)
        self.assertEqual(rest.apu_writes[0x400B], 0)

        prg[start - engine.PRG_BASE:start - engine.PRG_BASE + 7] = b"o4c1\0\0\0"
        note = engine.decode_next_audio_event(
            bytes(prg),
            engine.AudioStreamState(start, 1, 0, 0),
            tempo_offset=0,
            x=8,
            sound_effect_request=0,
        )
        self.assertEqual(note.period_table_index, 0x4A)

    def test_sound_effect_suppresses_apu_writes_but_not_duration(self) -> None:
        prg = bytearray(self.prg)
        start = 0xBBE7
        prg[start - engine.PRG_BASE:start - engine.PRG_BASE + 6] = b"l4c8\0\0"
        result = engine.decode_next_audio_event(
            bytes(prg),
            engine.AudioStreamState(start, 1, 0, 0),
            tempo_offset=0,
            x=0,
            sound_effect_request=1,
        )
        self.assertEqual(result.apu_writes, {})
        self.assertEqual(result.state.ticks_remaining, 10)

    def test_zero_restart_stops_and_nonzero_restart_continues(self) -> None:
        prg = bytearray(self.prg)
        start = 0xBBE7
        offset = start - engine.PRG_BASE
        prg[offset:offset + 3] = b"\0\0\0"
        stopped = engine.decode_next_audio_event(
            bytes(prg),
            engine.AudioStreamState(start, 7, 0, 0),
            tempo_offset=0,
            x=0,
            sound_effect_request=1,
        )
        self.assertTrue(stopped.ended)
        self.assertEqual(stopped.state.pointer, 0)

        restart = 0xBBF0
        prg[offset:offset + 3] = bytes((0, restart & 0xFF, restart >> 8))
        restart_offset = restart - engine.PRG_BASE
        prg[restart_offset:restart_offset + 2] = b"c1"
        continued = engine.decode_next_audio_event(
            bytes(prg),
            engine.AudioStreamState(start, 7, 0, 0),
            tempo_offset=0,
            x=0,
            sound_effect_request=1,
        )
        self.assertFalse(continued.ended)
        self.assertEqual(continued.event, "note")
        self.assertEqual(continued.state.pointer, restart + 2)

    def test_reference_rom_contract_and_all_music_streams(self) -> None:
        report = engine.validate_rom_contract(self.prg)
        self.assertEqual(report["bytes"], 528)
        self.assertEqual(report["code_bytes"], 517)
        self.assertEqual(report["orphan_data_bytes"], 11)
        self.assertEqual(report["call_sites"], 16)
        self.assertEqual(
            report["music_streams"],
            {
                "streams": 21,
                "characters": 1_511,
                "events": 801,
                "notes": 772,
                "rests": 29,
            },
        )

    def test_exhaustive_pointer_request_configure_and_gate_domains(self) -> None:
        self.assertEqual(
            engine.validate_exhaustive_contract(),
            {
                "pointer_cases": 196_608,
                "request_cases": 256,
                "configure_cases": 256,
                "gate_cases": 1_536,
            },
        )


if __name__ == "__main__":
    unittest.main()
