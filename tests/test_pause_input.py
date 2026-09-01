from __future__ import annotations

import unittest

from scripts import pause_input


class PauseInputTests(unittest.TestCase):
    def update(self, **overrides: int) -> pause_input.PauseInputResult:
        values = {
            "current_buttons": 0,
            "previous_buttons": 0,
            "pause_mode": pause_input.PAUSE_INACTIVE,
            "scroll_x": 0x40,
            "scroll_update_pending": 0,
        }
        values.update(overrides)
        return pause_input.update_pause_input(**values)

    def test_new_start_enters_pause_and_disables_apu(self) -> None:
        result = self.update(current_buttons=pause_input.BUTTON_START)
        self.assertEqual(result.pause_mode, pause_input.PAUSE_ACTIVE)
        self.assertEqual(result.apu_status_write, pause_input.APU_CHANNELS_DISABLED)
        self.assertEqual(result.previous_buttons, pause_input.BUTTON_START)

    def test_new_start_resumes_an_active_pause(self) -> None:
        result = self.update(
            current_buttons=pause_input.BUTTON_START,
            pause_mode=pause_input.PAUSE_ACTIVE,
        )
        self.assertEqual(result.pause_mode, pause_input.PAUSE_INACTIVE)
        self.assertEqual(result.action, "resume_start")
        self.assertIsNone(result.apu_status_write)

    def test_new_a_or_b_resumes_but_does_not_enter_pause(self) -> None:
        for button in (pause_input.BUTTON_A, pause_input.BUTTON_B):
            self.assertEqual(
                self.update(
                    current_buttons=button, pause_mode=pause_input.PAUSE_ACTIVE
                ).action,
                "resume_ab",
            )
            self.assertEqual(self.update(current_buttons=button).pause_mode, 0)

    def test_held_start_does_not_retrigger(self) -> None:
        result = self.update(
            current_buttons=pause_input.BUTTON_START,
            previous_buttons=pause_input.BUTTON_START,
        )
        self.assertEqual(result.action, "unpaused_idle")

    def test_unpaused_idle_preserves_previous_button_history(self) -> None:
        result = self.update(current_buttons=0x10, previous_buttons=0x20)
        self.assertEqual(result.previous_buttons, 0x20)

    def test_paused_left_scrolls_and_has_priority_over_right(self) -> None:
        result = self.update(
            current_buttons=pause_input.BUTTON_LEFT | pause_input.BUTTON_RIGHT,
            previous_buttons=pause_input.BUTTON_LEFT | pause_input.BUTTON_RIGHT,
            pause_mode=pause_input.PAUSE_ACTIVE,
        )
        self.assertEqual(result.scroll_x, 0x3C)
        self.assertEqual(result.action, "scroll_left")
        self.assertEqual(result.scroll_update_pending, 0xFF)

    def test_paused_scroll_saturates_inside_normal_domain(self) -> None:
        left = self.update(
            current_buttons=pause_input.BUTTON_LEFT,
            previous_buttons=pause_input.BUTTON_LEFT,
            pause_mode=pause_input.PAUSE_ACTIVE,
            scroll_x=2,
        )
        right = self.update(
            current_buttons=pause_input.BUTTON_RIGHT,
            previous_buttons=pause_input.BUTTON_RIGHT,
            pause_mode=pause_input.PAUSE_ACTIVE,
            scroll_x=0x7F,
        )
        self.assertEqual(left.scroll_x, 0)
        self.assertEqual(right.scroll_x, 0x80)

    def test_right_scroll_preserves_original_out_of_domain_wrap(self) -> None:
        result = self.update(
            current_buttons=pause_input.BUTTON_RIGHT,
            previous_buttons=pause_input.BUTTON_RIGHT,
            pause_mode=pause_input.PAUSE_ACTIVE,
            scroll_x=0xFF,
        )
        self.assertEqual(result.scroll_x, 3)

    def test_rejects_values_outside_machine_byte_width(self) -> None:
        with self.assertRaises(pause_input.PauseInputError):
            self.update(current_buttons=0x100)


if __name__ == "__main__":
    unittest.main()
