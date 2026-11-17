#!/usr/bin/env python3
"""Read Full Energy/VPower status; optionally serve it to HA over loopback."""

import argparse
import fcntl
import json
import os
import select
import struct
import termios
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

DEVICE = "/dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_CPBAb2A6710-if00-port0"
QUERY = b"CMSG\x06INV-HB"


def decode(frame):
    # Byte 4 counts the payload including its final additive checksum.
    if len(frame) < 5 or frame[:4] != b"VPHB":
        raise ValueError("Unexpected inverter response header")
    if len(frame) != 5 + frame[4] or len(frame) < 33:
        raise ValueError("Incomplete inverter status frame")
    if sum(frame[5:-1]) & 0xFF != frame[-1]:
        raise ValueError("Invalid inverter status checksum")
    voltage = lambda offset: struct.unpack_from("<H", frame, offset)[0] / 10
    result = {
        "ac_input_voltage": voltage(17),
        "battery_voltage": voltage(25),
        "battery_charge": frame[27],
        "sample_time": datetime.now(timezone.utc).isoformat(),
    }
    if not 0 <= result["ac_input_voltage"] <= 300:
        raise ValueError("AC input voltage outside expected range")
    if not 10 <= result["battery_voltage"] <= 40:
        raise ValueError("Battery voltage outside expected 24 V system range")
    if not 0 <= result["battery_charge"] <= 100:
        raise ValueError("Battery percentage outside expected range")
    return result


def read_status(device=DEVICE):
    fd = os.open(device, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    original = None
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        original = termios.tcgetattr(fd)
        settings = termios.tcgetattr(fd)
        settings[0] = settings[1] = settings[3] = 0
        settings[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
        settings[4] = settings[5] = termios.B2400
        settings[6][termios.VMIN] = settings[6][termios.VTIME] = 0
        termios.tcsetattr(fd, termios.TCSANOW, settings)
        termios.tcflush(fd, termios.TCIFLUSH)
        if os.write(fd, QUERY) != len(QUERY):
            raise OSError("Incomplete serial query write")
        deadline = time.monotonic() + 3
        frame = bytearray()
        while time.monotonic() < deadline:
            if select.select([fd], [], [], max(0, deadline - time.monotonic()))[0]:
                chunk = os.read(fd, 256)
                if not chunk:
                    raise OSError("Serial adapter disconnected")
                frame.extend(chunk)
                if len(frame) >= 5 and len(frame) >= 5 + frame[4]:
                    return decode(bytes(frame))
        raise TimeoutError("No complete inverter status within 3 seconds")
    finally:
        try:
            if original is not None:
                termios.tcsetattr(fd, termios.TCSANOW, original)
        finally:
            os.close(fd)


def serve(device, port):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path != "/status":
                self.send_error(404)
                return
            try:
                # No stale fallback: failures become unavailable in Home Assistant.
                payload = read_status(device)
                status = 200
            except (OSError, ValueError, TimeoutError) as error:
                payload = {"error": str(error)}
                status = 503
            body = json.dumps(payload).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, fmt, *args):
            if len(args) > 1 and str(args[1]) != "200":
                super().log_message(fmt, *args)

    # A single handler owns the port at a time; no concurrent serial transactions.
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", default=DEVICE)
    parser.add_argument("--serve", action="store_true")
    parser.add_argument("--port", type=int, default=8766)
    args = parser.parse_args()
    if args.serve:
        serve(args.device, args.port)
    else:
        print(json.dumps(read_status(args.device)))


if __name__ == "__main__":
    main()
