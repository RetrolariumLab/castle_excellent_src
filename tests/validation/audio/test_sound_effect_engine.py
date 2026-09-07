from pathlib import Path
import unittest

from scripts.validation.audio import sound_effect_engine as sound


ROOT = Path(__file__).resolve().parents[3]


class SoundEffectEngineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = sound.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )

    def test_type1_starter_has_exact_ordered_mutations(self) -> None:
        result = sound.start_pulse1_type1(sound.SoundEffectState())
        self.assertEqual(
            result.ram_writes,
            ((sound.PULSE1_BUSY, 1), (sound.PULSE1_REQUEST, 1), (sound.PULSE1_BUSY, 0)),
        )
        self.assertEqual(
            result.apu_writes,
            (
                (sound.APU_STATUS, 0x0F),
                (sound.APU_PULSE1_VOLUME, 0xDF),
                (sound.APU_PULSE1_SWEEP, 0xBA),
                (sound.APU_PULSE1_PERIOD_LOW, 0x40),
                (sound.APU_PULSE1_PERIOD_HIGH, 0xA0),
            ),
        )
        self.assertEqual(result.state.pulse1_request, 1)
        self.assertEqual(result.state.pulse1_busy, 0)

    def test_type2_starter_claims_both_channels_and_resets_pulse_step(self) -> None:
        initial = sound.SoundEffectState(pulse2_step=0x77, noise_step=0x66)
        result = sound.start_pulse2_noise_type2(initial)
        self.assertEqual(
            result.ram_writes,
            (
                (sound.PULSE2_BUSY, 2),
                (sound.NOISE_BUSY, 2),
                (sound.PULSE2_REQUEST, 2),
                (sound.NOISE_REQUEST, 2),
                (sound.PULSE2_STEP, 0),
                (sound.PULSE2_BUSY, 0),
                (sound.NOISE_BUSY, 0),
            ),
        )
        self.assertEqual(
            result.apu_writes,
            (
                (sound.APU_STATUS, 0x0F),
                (sound.APU_PULSE2_VOLUME, 0x83),
                (sound.APU_PULSE2_SWEEP, 0x96),
                (sound.APU_PULSE2_PERIOD_LOW, 0xFF),
                (sound.APU_PULSE2_PERIOD_HIGH, 0xF1),
                (sound.APU_NOISE_VOLUME, 0xC1),
                (sound.APU_NOISE_PERIOD, 0x0F),
                (sound.APU_NOISE_LENGTH, 0xF8),
            ),
        )
        self.assertEqual(result.state.pulse2_step, 0)
        self.assertEqual(result.state.noise_step, 0x66)

    def test_remaining_starters_have_exact_requests_steps_and_busy_release(self) -> None:
        inventory = sound.start_inventory_type3(sound.SoundEffectState(pulse2_step=9))
        self.assertEqual(
            inventory.ram_writes,
            (
                (sound.PULSE2_BUSY, 3),
                (sound.PULSE2_REQUEST, 3),
                (sound.PULSE2_STEP, 0),
                (sound.PULSE2_BUSY, 0),
            ),
        )
        self.assertEqual(
            inventory.apu_writes,
            (
                (sound.APU_STATUS, 0x0F),
                (sound.APU_PULSE2_VOLUME, 0x40),
                (sound.APU_PULSE2_SWEEP, 0x08),
                (sound.APU_PULSE2_PERIOD_LOW, 0x50),
                (sound.APU_PULSE2_PERIOD_HIGH, 0x48),
            ),
        )
        self.assertEqual(inventory.state.pulse2_request, 3)
        self.assertEqual(inventory.state.pulse2_step, 0)
        self.assertEqual(inventory.state.pulse2_busy, 0)

        noise = sound.start_noise_type4(sound.SoundEffectState(noise_step=9))
        self.assertEqual(
            noise.ram_writes,
            (
                (sound.NOISE_BUSY, 4),
                (sound.NOISE_REQUEST, 4),
                (sound.NOISE_STEP, 0),
                (sound.NOISE_BUSY, 0),
            ),
        )
        self.assertEqual(
            noise.apu_writes,
            (
                (sound.APU_STATUS, 0x0F),
                (sound.APU_NOISE_VOLUME, 0x18),
                (sound.APU_NOISE_PERIOD, 0x0C),
                (sound.APU_NOISE_LENGTH, 0x38),
            ),
        )
        self.assertEqual(noise.state.noise_request, 4)
        self.assertEqual(noise.state.noise_step, 0)
        self.assertEqual(noise.state.noise_busy, 0)

        mutable = sound.start_mutable_cell_type5(
            sound.SoundEffectState(triangle_step=9, noise_step=9)
        )
        self.assertEqual(
            mutable.ram_writes,
            (
                (sound.TRIANGLE_BUSY, 5),
                (sound.NOISE_BUSY, 5),
                (sound.TRIANGLE_REQUEST, 5),
                (sound.NOISE_REQUEST, 5),
                (sound.TRIANGLE_STEP, 0),
                (sound.NOISE_STEP, 0),
                (sound.TRIANGLE_BUSY, 0),
                (sound.NOISE_BUSY, 0),
            ),
        )
        self.assertEqual(
            mutable.apu_writes,
            (
                (sound.APU_STATUS, 0x0F),
                (sound.APU_TRIANGLE_LINEAR, 0x30),
                (sound.APU_TRIANGLE_PERIOD_LOW, 0xF0),
                (sound.APU_TRIANGLE_PERIOD_HIGH, 0x60),
                (sound.APU_NOISE_VOLUME, 0x04),
                (sound.APU_NOISE_PERIOD, 0x0F),
                (sound.APU_NOISE_LENGTH, 0x60),
            ),
        )
        self.assertEqual(mutable.state.triangle_request, 5)
        self.assertEqual(mutable.state.noise_request, 5)
        self.assertEqual(mutable.state.triangle_step, 0)
        self.assertEqual(mutable.state.noise_step, 0)
        self.assertEqual(mutable.state.triangle_busy, 0)
        self.assertEqual(mutable.state.noise_busy, 0)

    def test_busy_and_active_apu_channels_block_updater_mutations(self) -> None:
        busy = sound.update_sound_effects(
            sound.SoundEffectState(pulse2_request=3, pulse2_busy=1),
            apu_status_read=0,
        )
        active = sound.update_sound_effects(
            sound.SoundEffectState(pulse2_request=3), apu_status_read=0x02
        )
        self.assertEqual(busy.ram_writes, ())
        self.assertEqual(active.ram_writes, ())
        self.assertEqual(busy.apu_writes, ((sound.APU_STATUS, 0x0F),))
        self.assertEqual(active.apu_writes, ((sound.APU_STATUS, 0x0F),))

    def test_pulse1_and_type2_requests_clear_when_length_counters_expire(self) -> None:
        state = sound.SoundEffectState(
            pulse1_request=1, pulse2_request=2, noise_request=2
        )
        result = sound.update_sound_effects(state, apu_status_read=0)
        self.assertEqual(result.state.pulse1_request, 0)
        self.assertEqual(result.state.pulse2_request, 0)
        self.assertEqual(result.state.noise_request, 0)

    def test_inventory_sequence_uses_table_steps_one_to_three_then_clears(self) -> None:
        state = sound.start_inventory_type3(sound.SoundEffectState()).state
        lows = []
        for _update in range(4):
            result = sound.update_sound_effects(state, apu_status_read=0)
            writes = dict(result.apu_writes)
            if sound.APU_PULSE2_PERIOD_LOW in writes:
                lows.append(writes[sound.APU_PULSE2_PERIOD_LOW])
            state = result.state
        self.assertEqual(lows, [0x3F, 0x3D, 0x35])
        self.assertEqual(state.pulse2_step, 4)
        self.assertEqual(state.pulse2_request, 0)

    def test_triangle_type2_sequence_uses_three_periods_then_clears(self) -> None:
        state = sound.SoundEffectState(triangle_request=2)
        lows = []
        for _update in range(4):
            result = sound.update_sound_effects(state, apu_status_read=0)
            writes = dict(result.apu_writes)
            if sound.APU_TRIANGLE_PERIOD_LOW in writes:
                lows.append(writes[sound.APU_TRIANGLE_PERIOD_LOW])
            state = result.state
        self.assertEqual(lows, [0xE0, 0xD0, 0xC0])
        self.assertEqual(state.triangle_request, 0)

    def test_noise_type4_sequence_uses_all_three_tables_then_clears(self) -> None:
        state = sound.start_noise_type4(sound.SoundEffectState()).state
        frames = []
        for _update in range(4):
            result = sound.update_sound_effects(state, apu_status_read=0)
            writes = dict(result.apu_writes)
            if sound.APU_NOISE_VOLUME in writes:
                frames.append(
                    (
                        writes[sound.APU_NOISE_VOLUME],
                        writes[sound.APU_NOISE_PERIOD],
                        writes[sound.APU_NOISE_LENGTH],
                    )
                )
            state = result.state
        self.assertEqual(
            frames,
            [(0x1B, 0x09, 0x38), (0x1E, 0x06, 0x58), (0x03, 0x02, 0x38)],
        )
        self.assertEqual(state.noise_request, 0)

    def test_type5_channels_write_once_then_clear_on_second_expiration(self) -> None:
        state = sound.start_mutable_cell_type5(sound.SoundEffectState()).state
        first = sound.update_sound_effects(state, apu_status_read=0)
        second = sound.update_sound_effects(first.state, apu_status_read=0)
        first_writes = dict(first.apu_writes)
        self.assertEqual(first_writes[sound.APU_TRIANGLE_PERIOD_LOW], 0xA0)
        self.assertEqual(first_writes[sound.APU_NOISE_PERIOD], 0x0D)
        self.assertEqual(second.state.triangle_request, 0)
        self.assertEqual(second.state.noise_request, 0)

    def test_reference_rom_pins_entrypoints_callers_tables_and_nmi_order(self) -> None:
        report = sound.validate_rom_contract(self.prg)
        self.assertEqual(report["bytes"], 560)
        self.assertEqual(report["starter_bytes"], 236)
        self.assertEqual(report["updater_bytes"], 304)
        self.assertEqual(report["table_bytes"], 20)
        self.assertEqual(report["entrypoints"], 6)
        self.assertEqual(report["callers"], 9)
        self.assertEqual(report["nmi_update"], [0xB923, 0xC2F9])

    def test_exhaustive_arbitration_steps_and_table_bounds(self) -> None:
        self.assertEqual(
            sound.validate_exhaustive_contract(),
            {
                "arbitration_cases": 4_096,
                "step_cases": 1_280,
                "table_indices": [0, 1, 2, 3],
            },
        )


if __name__ == "__main__":
    unittest.main()
