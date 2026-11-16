#!/usr/bin/env python3
"""GlassBox CPU hardware bridge for a Raspberry Pi (the Linux boards).

GlassBox mirrors its I/O ports to this script, over Wi-Fi (WebSocket) or a
serial line, and the script drives real parts on the Pi's GPIO:

  * HD44780 16x2 LCD with a PCF8574 I2C backpack   (ports 1-2)  --lcd
  * MAX7219 8x8 LED matrix on SPI                  (ports 3-4)  --matrix
  * SSD1306 128x64 OLED on I2C: LCD text, matrix, port 0       --oled
  * 4x4 membrane keypad on GPIO, sent back as port 5           --keypad

The bridge itself needs only the Python standard library. Each part needs
its driver, imported only when the part is enabled:

  pip install RPLCD smbus2          # --lcd
  pip install luma.led_matrix       # --matrix
  pip install luma.oled             # --oled
  pip install gpiozero              # --keypad (preinstalled on Pi OS)

Examples:

  # Wi-Fi: GlassBox connects to ws://<pi address>:8765
  python3 glassbox_bridge.py --ws 0.0.0.0:8765 --lcd --matrix --keypad

  # USB gadget mode (Pi Zero / 4 / 5) or a USB-serial adapter
  python3 glassbox_bridge.py --serial /dev/ttyGS0 --oled

  # No hardware: draws the devices in this terminal, keys typed + Enter
  python3 glassbox_bridge.py --ws 127.0.0.1:8765 --simulate

Protocol: see docs/hardware-bridge.md. Port numbers are those of the
GlassBox Extended CPU.
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import hashlib
import os
import struct
import sys
import threading
import time

PROTOCOL = 1

PORT_DISPLAY = 0
PORT_LCD_CMD = 1
PORT_LCD_DATA = 2
PORT_MATRIX_ROW = 3
PORT_MATRIX_DATA = 4

KEYPAD_LAYOUT = ["123A", "456B", "789C", "*0#D"]


# --------------------------------------------------------------- models


class LcdModel:
    """The HD44780 as GlassBox simulates it, for the OLED and terminal."""

    LINE2 = 0x40
    LINE_LENGTH = 40

    def __init__(self):
        self.reset()

    def reset(self):
        self.ddram = [0x20] * 0x80
        self.cgram = [0] * 64
        self.address = 0
        self.cg_mode = False
        self.display_on = False
        self.cursor_on = False
        self.blink_on = False
        self.move_right = True
        self.shift_on_write = False
        self.two_lines = True
        self.shift = 0

    def char_at(self, row, col):
        return self.ddram[row * self.LINE2 + (col + self.shift) % self.LINE_LENGTH]

    def cursor_column(self, row):
        if self.cg_mode:
            return None
        line = 1 if self.address >= self.LINE2 else 0
        if line != row:
            return None
        offset = self.address - line * self.LINE2
        if offset >= self.LINE_LENGTH:
            return None
        col = (offset - self.shift) % self.LINE_LENGTH
        return col if col < 16 else None

    def glyph(self, code):
        start = (code & 7) * 8
        return self.cgram[start:start + 8]

    def command(self, v):
        if v & 0x80:
            self.address, self.cg_mode = v & 0x7F, False
        elif v & 0x40:
            self.address, self.cg_mode = v & 0x3F, True
        elif v & 0x20:
            self.two_lines = bool(v & 0x08)
        elif v & 0x10:
            right = bool(v & 0x04)
            if v & 0x08:
                self._shift_display(right)
            else:
                self.cg_mode = False
                self._move(right)
        elif v & 0x08:
            self.display_on = bool(v & 0x04)
            self.cursor_on = bool(v & 0x02)
            self.blink_on = bool(v & 0x01)
        elif v & 0x04:
            self.move_right = bool(v & 0x02)
            self.shift_on_write = bool(v & 0x01)
        elif v & 0x02:
            self.address, self.cg_mode, self.shift = 0, False, 0
        elif v & 0x01:
            self.ddram = [0x20] * 0x80
            self.address, self.cg_mode, self.shift = 0, False, 0
            self.move_right = True

    def data(self, v):
        if self.cg_mode:
            self.cgram[self.address] = v & 0x1F
            self.address = (self.address + (1 if self.move_right else -1)) & 0x3F
            return
        self.ddram[self.address] = v
        self._move(self.move_right)
        if self.shift_on_write:
            self._shift_display(not self.move_right)

    def _move(self, right):
        a = self.address
        if not self.two_lines:
            self.address = (a + (1 if right else -1)) % 0x50
        elif right:
            self.address = {0x27: 0x40, 0x67: 0x00}.get(a, (a + 1) & 0x7F)
        else:
            self.address = {0x40: 0x27, 0x00: 0x67}.get(a, (a - 1) & 0x7F)

    def _shift_display(self, right):
        self.shift = (self.shift + (-1 if right else 1)) % self.LINE_LENGTH


class MatrixModel:
    def __init__(self):
        self.reset()

    def reset(self):
        self.rows = [0] * 8
        self.row = 0

    def write(self, port, v):
        if port == PORT_MATRIX_ROW:
            self.row = v % 8
        else:
            self.rows[self.row] = v
            self.row = (self.row + 1) % 8


def lcd_char(code):
    """The character of an HD44780 A00 ROM code, as close as Unicode gets."""
    if 0x20 <= code <= 0x7D:
        return "¥" if code == 0x5C else chr(code)
    if code == 0x7E:
        return "→"
    if code == 0x7F:
        return "←"
    if 0xA1 <= code <= 0xDF:
        return chr(0xFF61 + code - 0xA1)
    if code < 0x10:
        return "□"  # custom character
    return " "


# ------------------------------------------------------------ real parts


class RealLcd:
    """HD44780 behind a PCF8574 I2C backpack, driven with raw bytes."""

    def __init__(self, address, port):
        from RPLCD.i2c import CharLCD  # pip install RPLCD smbus2

        self.lcd = CharLCD("PCF8574", address, port=port, cols=16, rows=2,
                           auto_linebreaks=False)
        self.lcd.backlight_enabled = True
        self.reset()

    def reset(self):
        self.lcd.command(0x01)  # clear; RPLCD waits the 1.6 ms it needs
        time.sleep(0.002)
        self.lcd.command(0x40)  # blank the custom characters
        for _ in range(64):
            self.lcd.write(0)
        self.lcd.command(0x06)
        self.lcd.command(0x80)
        self.lcd.command(0x08)  # display off, as after power-on

    def command(self, v):
        if v & 0xE0 == 0x20:
            # Function set: GlassBox programs ask for the 8-bit interface,
            # but the backpack wires the LCD in 4-bit mode. Keep 4-bit.
            v = 0x20 | (v & 0x0C)
        self.lcd.command(v)
        if v in (0x01, 0x02, 0x03):
            time.sleep(0.002)

    def data(self, v):
        self.lcd.write(v)


class RealMatrix:
    """MAX7219 8x8 module on SPI0 CE0 (MOSI GPIO10, SCLK GPIO11)."""

    def __init__(self, rotate, flip):
        from luma.core.interface.serial import noop, spi
        from luma.led_matrix.device import max7219

        self.device = max7219(spi(port=0, device=0, gpio=noop()),
                              cascaded=1, rotate=rotate)
        self.flip = flip
        self.device.contrast(32)

    def show(self, rows):
        from luma.core.render import canvas

        with canvas(self.device) as draw:
            for r, bits in enumerate(rows):
                for c in range(8):
                    if bits >> (7 - c) & 1:
                        draw.point((7 - c if self.flip else c, r), fill="white")


class Oled:
    """SSD1306 128x64 on I2C: port 0, the LCD's two lines and the matrix."""

    def __init__(self, address, port):
        from luma.core.interface.serial import i2c
        from luma.oled.device import ssd1306

        self.device = ssd1306(i2c(port=port, address=address))

    def show(self, display, lcd, matrix):
        from luma.core.render import canvas

        with canvas(self.device) as draw:
            draw.text((0, 0), f"GLASSBOX  OUT {display:3d}", fill="white")
            draw.line((0, 11, 127, 11), fill="white")
            if lcd.display_on:
                for r in range(2):
                    text = "".join(lcd_char(lcd.char_at(r, c)) for c in range(16))
                    draw.text((0, 14 + r * 10), text, fill="white")
                    col = lcd.cursor_column(r)
                    if col is not None and (lcd.cursor_on or lcd.blink_on):
                        draw.line((col * 6, 23 + r * 10, col * 6 + 5,
                                   23 + r * 10), fill="white")
            else:
                draw.text((0, 18), "LCD off", fill="white")
            for r, bits in enumerate(matrix.rows):
                for c in range(8):
                    if bits >> (7 - c) & 1:
                        x, y = 4 + c * 4, 36 + r * 3
                        draw.rectangle((x, y, x + 2, y + 1), fill="white")
            draw.text((48, 40), f"0x{display:02X}", fill="white")
            draw.text((48, 52), f"{display:08b}", fill="white")


class Keypad:
    """4x4 membrane keypad: rows driven low one at a time, columns pulled up."""

    def __init__(self, rows, cols, on_key):
        from gpiozero import DigitalInputDevice, DigitalOutputDevice

        self.rows = [DigitalOutputDevice(p, initial_value=True) for p in rows]
        self.cols = [DigitalInputDevice(p, pull_up=True) for p in cols]
        self.on_key = on_key
        threading.Thread(target=self._scan, daemon=True).start()

    def _scan(self):
        down = set()
        while True:
            now = set()
            for r, row in enumerate(self.rows):
                row.off()
                time.sleep(0.0005)
                for c, col in enumerate(self.cols):
                    if not col.value:  # pulled low through the key
                        now.add(KEYPAD_LAYOUT[r][c])
                row.on()
            for key in sorted(now - down):
                self.on_key(key)
            down = now
            time.sleep(0.02)


# ---------------------------------------------------------------- board


class Board:
    """Applies protocol lines to the parts and answers them."""

    def __init__(self, name, lcd=None, matrix=None, oled=None, keypad=False,
                 terminal=False):
        self.name = name
        self.lcd_model = LcdModel()
        self.matrix_model = MatrixModel()
        self.display = 0
        self.lcd, self.matrix, self.oled = lcd, matrix, oled
        self.terminal = terminal
        self.parts = [p for p, on in (("lcd", lcd or terminal),
                                      ("matrix", matrix or terminal),
                                      ("keypad", keypad or terminal),
                                      ("oled", oled)) if on]
        self.dirty = True
        self.lock = threading.Lock()

    def handle(self, line):
        """The answer to one line from GlassBox, or None to stay silent."""
        parts = line.split()
        if not parts:
            return None
        try:
            if parts[0] == "HELLO":
                return f"GLASSBOX {PROTOCOL} {self.name} {' '.join(self.parts)}".rstrip()
            if parts[0] == "RESET" and len(parts) == 1:
                with self.lock:
                    self.reset()
                return "A"
            if parts[0] == "W" and len(parts) == 3:
                port, value = int(parts[1], 16), int(parts[2], 16)
                if not (0 <= port <= 0xFF and 0 <= value <= 0xFF):
                    return "E out of range"
                with self.lock:
                    self.write(port, value)
                return "A"
        except ValueError:
            return "E bad number"
        except Exception as e:  # a part failed (I2C error...): report it
            return f"E {type(e).__name__}: {e}"
        return "E unknown line"

    def reset(self):
        self.lcd_model.reset()
        self.matrix_model.reset()
        self.display = 0
        if self.lcd:
            self.lcd.reset()
        if self.matrix:
            self.matrix.show(self.matrix_model.rows)
        self.dirty = True

    def write(self, port, value):
        if port == PORT_DISPLAY:
            self.display = value
        elif port == PORT_LCD_CMD:
            self.lcd_model.command(value)
            if self.lcd:
                self.lcd.command(value)
        elif port == PORT_LCD_DATA:
            self.lcd_model.data(value)
            if self.lcd:
                self.lcd.data(value)
        elif port in (PORT_MATRIX_ROW, PORT_MATRIX_DATA):
            self.matrix_model.write(port, value)
            if self.matrix and port == PORT_MATRIX_DATA:
                self.matrix.show(self.matrix_model.rows)
        else:
            return
        self.dirty = True

    def refresh(self):
        """Redraws the OLED and terminal if something changed."""
        if not self.dirty:
            return
        with self.lock:
            self.dirty = False
            if self.oled:
                self.oled.show(self.display, self.lcd_model, self.matrix_model)
            if self.terminal:
                sys.stdout.write("\x1b[H\x1b[2J" + self.render_text() + "\n")
                sys.stdout.flush()

    def render_text(self):
        lcd = self.lcd_model
        out = [f"GlassBox bridge (simulated parts)   port 0 = {self.display:3d}"
               f"  0x{self.display:02X}", "", "  +" + "-" * 16 + "+"]
        for r in range(2):
            if lcd.display_on:
                text = "".join(lcd_char(lcd.char_at(r, c)) for c in range(16))
            else:
                text = " " * 16
            out.append(f"  |{text}|")
        out.append("  +" + "-" * 16 + "+" + ("" if lcd.display_on else "  display off"))
        out.append("")
        for r, bits in enumerate(self.matrix_model.rows):
            leds = " ".join("●" if bits >> (7 - c) & 1 else "·"
                            for c in range(8))
            out.append(f"  {leds}   0x{bits:02X}")
        out.append("")
        out.append("  Type keypad keys (0-9 A-D * #) then Enter to press them.")
        return "\n".join(out)


# ------------------------------------------------------------ transports


class Clients:
    """Connected GlassBox instances; key presses go to all of them."""

    def __init__(self):
        self.senders = set()
        self.loop = None

    def broadcast(self, line):
        for send in list(self.senders):
            send(line)

    def key(self, key):
        if self.loop:
            self.loop.call_soon_threadsafe(self.broadcast, f"K {ord(key):02X}")


class LineBuffer:
    def __init__(self):
        self.pending = b""

    def feed(self, data):
        self.pending += data
        *lines, self.pending = self.pending.split(b"\n")
        if len(self.pending) > 256:
            self.pending = b""
        return [l.decode("latin-1").strip("\r") for l in lines]


WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


async def ws_session(reader, writer, board, clients):
    """One GlassBox over a WebSocket: a minimal RFC 6455 server."""
    try:
        request = await reader.readuntil(b"\r\n\r\n")
    except (asyncio.IncompleteReadError, asyncio.LimitOverrunError):
        writer.close()
        return
    headers = {}
    for line in request.decode("latin-1").split("\r\n")[1:]:
        if ":" in line:
            k, v = line.split(":", 1)
            headers[k.strip().lower()] = v.strip()
    key = headers.get("sec-websocket-key")
    if not key or "websocket" not in headers.get("upgrade", "").lower():
        writer.write(b"HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n")
        await writer.drain()
        writer.close()
        return
    accept = base64.b64encode(hashlib.sha1((key + WS_GUID).encode()).digest())
    writer.write(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\n"
                 b"Connection: Upgrade\r\nSec-WebSocket-Accept: " + accept +
                 b"\r\n\r\n")

    def frame(opcode, payload):
        n = len(payload)
        if n < 126:
            head = struct.pack("!BB", 0x80 | opcode, n)
        elif n < 65536:
            head = struct.pack("!BBH", 0x80 | opcode, 126, n)
        else:
            head = struct.pack("!BBQ", 0x80 | opcode, 127, n)
        writer.write(head + payload)

    def send(line):
        if not writer.is_closing():
            frame(0x1, (line + "\n").encode("latin-1"))

    peer = writer.get_extra_info("peername")
    log(f"GlassBox connected from {peer}")
    clients.senders.add(send)
    lines = LineBuffer()
    message = b""
    try:
        while True:
            b1, b2 = await reader.readexactly(2)
            opcode, n = b1 & 0x0F, b2 & 0x7F
            if n == 126:
                n = struct.unpack("!H", await reader.readexactly(2))[0]
            elif n == 127:
                n = struct.unpack("!Q", await reader.readexactly(8))[0]
            mask = await reader.readexactly(4) if b2 & 0x80 else b"\0\0\0\0"
            data = bytes(b ^ mask[i % 4] for i, b in
                         enumerate(await reader.readexactly(n)))
            if opcode == 0x8:  # close
                frame(0x8, data[:2])
                break
            if opcode == 0x9:  # ping
                frame(0xA, data)
                continue
            if opcode in (0x0, 0x1, 0x2):
                message += data
                if b1 & 0x80:
                    for line in lines.feed(message):
                        answer = board.handle(line)
                        if answer:
                            send(answer)
                    message = b""
                    await writer.drain()
    except (asyncio.IncompleteReadError, ConnectionError):
        pass
    finally:
        clients.senders.discard(send)
        writer.close()
        log(f"GlassBox disconnected ({peer})")


def open_serial(path, baud):
    """Opens a serial device raw at `baud`, without pyserial."""
    import termios
    import tty

    speed = getattr(termios, f"B{baud}", None)
    if speed is None:
        raise SystemExit(f"Unsupported speed {baud}")
    fd = os.open(path, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    tty.setraw(fd)
    attrs = termios.tcgetattr(fd)
    attrs[4] = attrs[5] = speed
    attrs[2] |= termios.CLOCAL | termios.CREAD
    termios.tcsetattr(fd, termios.TCSANOW, attrs)
    return fd


def serve_serial(path, baud, board, clients, loop):
    fd = open_serial(path, baud)
    lines = LineBuffer()

    def send(line):
        data = (line + "\n").encode("latin-1")
        while data:
            try:
                data = data[os.write(fd, data):]
            except BlockingIOError:
                time.sleep(0.001)

    def readable():
        try:
            data = os.read(fd, 512)
        except BlockingIOError:
            return
        for line in lines.feed(data):
            answer = board.handle(line)
            if answer:
                send(answer)

    clients.senders.add(send)
    loop.add_reader(fd, readable)
    log(f"Listening on {path} at {baud} baud")


def read_terminal_keys(clients):
    """--simulate: keys typed in the terminal act as the keypad."""
    valid = "".join(KEYPAD_LAYOUT)
    for line in sys.stdin:
        for ch in line.strip().upper():
            if ch in valid:
                clients.key(ch)


LOG = []


def log(message):
    LOG.append(message)
    print(message, file=sys.stderr, flush=True)


async def main_async(args):
    if not args.ws and not args.serial:
        raise SystemExit("Give --ws HOST:PORT and/or --serial DEVICE")
    clients = Clients()
    loop = asyncio.get_running_loop()
    clients.loop = loop

    lcd = RealLcd(int(args.lcd_address, 0), args.i2c_bus) if args.lcd else None
    matrix = RealMatrix(args.matrix_rotate, args.matrix_flip) if args.matrix else None
    oled = Oled(int(args.oled_address, 0), args.i2c_bus) if args.oled else None
    board = Board("simulator" if args.simulate and not (lcd or matrix or oled)
                  else "raspberrypi",
                  lcd=lcd, matrix=matrix, oled=oled,
                  keypad=args.keypad, terminal=args.simulate)
    if args.keypad:
        Keypad(args.keypad_rows, args.keypad_cols, clients.key)
    if args.simulate and sys.stdin.isatty():
        threading.Thread(target=read_terminal_keys, args=(clients,),
                         daemon=True).start()

    if args.serial:
        serve_serial(args.serial, args.baud, board, clients, loop)
    if args.ws:
        host, _, port = args.ws.rpartition(":")
        server = await asyncio.start_server(
            lambda r, w: ws_session(r, w, board, clients),
            host or "0.0.0.0", int(port))
        log(f"WebSocket server on ws://{host or '0.0.0.0'}:{port}")
    log(f"Parts: {', '.join(board.parts) or 'none'}")

    while True:
        board.refresh()
        await asyncio.sleep(0.05)


def parse_args(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--ws", metavar="HOST:PORT",
                   help="serve GlassBox over WebSocket, e.g. 0.0.0.0:8765")
    p.add_argument("--serial", metavar="DEVICE",
                   help="serve GlassBox over a serial line, e.g. /dev/ttyGS0")
    p.add_argument("--baud", type=int, default=115200)
    p.add_argument("--simulate", action="store_true",
                   help="draw the devices in this terminal")
    p.add_argument("--lcd", action="store_true", help="HD44780 on I2C")
    p.add_argument("--lcd-address", default="0x27",
                   help="PCF8574 address (0x27, or 0x3F on some backpacks)")
    p.add_argument("--matrix", action="store_true", help="MAX7219 on SPI0")
    p.add_argument("--matrix-rotate", type=int, default=0, choices=range(4))
    p.add_argument("--matrix-flip", action="store_true",
                   help="mirror left/right, for modules wired the other way")
    p.add_argument("--oled", action="store_true", help="SSD1306 on I2C")
    p.add_argument("--oled-address", default="0x3C")
    p.add_argument("--i2c-bus", type=int, default=1)
    p.add_argument("--keypad", action="store_true", help="4x4 keypad on GPIO")
    p.add_argument("--keypad-rows", type=int, nargs=4, default=[5, 6, 13, 19],
                   metavar="BCM", help="row pins, top to bottom")
    p.add_argument("--keypad-cols", type=int, nargs=4, default=[12, 16, 20, 21],
                   metavar="BCM", help="column pins, left to right")
    return p.parse_args(argv)


if __name__ == "__main__":
    try:
        asyncio.run(main_async(parse_args()))
    except KeyboardInterrupt:
        pass
