"""Protocol checks using a real frame captured on Crait (no hardware writes)."""
import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("reader", Path(__file__).with_name("inverter-reader.py"))
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
FRAME = bytes.fromhex(
    "5650484251090200000000000000010d1e000000009908f40103016400202b1408e501"
    "0602010100000020147d7d7d7d7d7d0202010150648e87697887dc0201010301020201"
    "00000073820603010a145f326c0000e8"
)

class ProtocolTests(unittest.TestCase):
    def test_captured_reading(self):
        result = reader.decode(FRAME)
        self.assertEqual(result["ac_input_voltage"], 0.0)
        self.assertEqual(result["battery_voltage"], 25.9)
        self.assertEqual(result["battery_charge"], 100)

    def test_corruption_and_truncation_rejected(self):
        corrupt = bytearray(FRAME)
        corrupt[25] ^= 1
        for frame in (FRAME[:-1], bytes(corrupt), b"junk" + FRAME[4:]):
            with self.subTest(frame=frame), self.assertRaises(ValueError):
                reader.decode(frame)

    def test_charge_is_one_byte_followed_by_charge_current(self):
        frame = bytearray(FRAME)
        frame[27] = 72
        frame[28] = 19
        frame[-1] = sum(frame[5:-1]) & 255
        self.assertEqual(reader.decode(frame)["battery_charge"], 72)

if __name__ == "__main__":
    unittest.main()
