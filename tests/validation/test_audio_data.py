from __future__ import annotations

import unittest



from scripts.validation import audio_data
class MmlTests(unittest.TestCase):
    def test_accepts_interpreter_command_grammar(self) -> None:
        counts = audio_data.validate_mml_text(b"t5vfo4l8c+4.r8", 0xBBE7)
        self.assertEqual(counts["t"], 1)
        self.assertEqual(counts["v"], 1)
        self.assertEqual(counts["o"], 1)
        self.assertEqual(counts["l"], 1)
        self.assertEqual(counts["note"], 1)
        self.assertEqual(counts["rest"], 1)
        self.assertEqual(counts["accidental"], 1)
        self.assertEqual(counts["dotted"], 1)

    def test_rejects_unknown_command_byte(self) -> None:
        with self.assertRaisesRegex(audio_data.AudioDataError, "invalid MML byte"):
            audio_data.validate_mml_text(b"c8x", 0xBBE7)

    def test_rejects_missing_command_argument(self) -> None:
        with self.assertRaisesRegex(audio_data.AudioDataError, "missing 'o' argument"):
            audio_data.validate_mml_text(b"o", 0xBBE7)

    def test_parses_stream_terminator_and_restart_pointer(self) -> None:
        prg = bytearray(audio_data.PRG_SIZE)
        offset = audio_data.cpu_offset(audio_data.MML_START_CPU)
        prg[offset:offset + 6] = b"l8c\0\xe7\xbb"
        stream = audio_data.parse_stream(bytes(prg), audio_data.MML_START_CPU)
        self.assertEqual(stream.text, "l8c")
        self.assertEqual(stream.end_address, audio_data.MML_START_CPU + 3)
        self.assertEqual(stream.restart_address, audio_data.MML_START_CPU)


if __name__ == "__main__":
    unittest.main()
