# Real hardware bridge

GlassBox can mirror its I/O ports to a real board, so a program that writes to the LCD on screen also writes to an LCD on your desk, and a real keypad can type into the program. The simulated devices stay the reference: the board follows them, and after a reset, a step-back or a reconnect GlassBox resets the board and sends it the whole state again.

| Board                          | Firmware                                     | Links              |
| ------------------------------ | -------------------------------------------- | ------------------ |
| Arduino Uno / Nano / Mega      | `firmware/arduino/glassbox_bridge`           | USB serial         |
| ESP32                          | `firmware/arduino/glassbox_bridge`           | USB serial, Wi-Fi  |
| Raspberry Pi Pico              | `firmware/arduino/glassbox_bridge` (arduino-pico core) | USB serial |
| Raspberry Pi (Linux)           | `firmware/raspberry-pi/glassbox_bridge.py`   | Wi-Fi, serial line |

| GlassBox build        | USB serial                              | Wi-Fi (WebSocket)                  |
| --------------------- | --------------------------------------- | ---------------------------------- |
| Desktop (Linux, Windows, macOS) | yes (libserialport)           | yes                                |
| Web                   | Chrome and Edge only (Web Serial)       | yes, if the page is served over http (browsers block `ws://` from an https page) |

## Parts

| Part                                   | Ports       | Bus  | Notes                                                    |
| -------------------------------------- | ----------- | ---- | -------------------------------------------------------- |
| HD44780 16×2 LCD with PCF8574 backpack | 1–2         | I2C  | Address 0x27 (or 0x3F). Detected at boot.                |
| SSD1306 128×64 OLED                    | 0, 1–2, 3–4 | I2C  | Address 0x3C. Shows port 0, the LCD text and the matrix. Detected at boot. |
| MAX7219 8×8 LED matrix module          | 3–4         | SPI  | Not detectable: set `USE_MATRIX` / pass `--matrix`.      |
| 4×4 membrane keypad                    | 5           | GPIO | Not detectable: set `USE_KEYPAD` / pass `--keypad`.      |

Any subset works. A board with only an OLED still shows everything; the board reports what it has when GlassBox connects.

The LCD backpack drives the LCD in 4-bit mode, while GlassBox programs send the 8-bit function set (`0x38`, as for the simulated chip). The firmware rewrites it to `0x28`, keeping the line count and font bits.

## Wiring

Power the LCD and the MAX7219 from 5 V. On 3.3 V boards (ESP32, Pico, Raspberry Pi), the LCD backpack pulls I2C up to 5 V: remove its pull-up resistors or use a level shifter, since those pins are not 5 V tolerant. The MAX7219 usually accepts 3.3 V signals; if the matrix shows garbage, add a level shifter.

Keypad pins are listed left to right as they leave a standard membrane keypad: four rows, then four columns.

| Signal         | Uno / Nano | Mega   | ESP32 DevKit | Pico (GPx) | Raspberry Pi (GPIO, header pin) |
| -------------- | ---------- | ------ | ------------ | ---------- | ------------------------------- |
| I2C SDA        | A4         | 20     | 21           | GP4        | GPIO2 (pin 3)                   |
| I2C SCL        | A5         | 21     | 22           | GP5        | GPIO3 (pin 5)                   |
| MAX7219 DIN    | 12         | 12     | 23           | GP19       | GPIO10 MOSI (pin 19)            |
| MAX7219 CLK    | 11         | 11     | 18           | GP18       | GPIO11 SCLK (pin 23)            |
| MAX7219 CS     | 10         | 10     | 5            | GP17       | GPIO8 CE0 (pin 24)              |
| Keypad rows 1–4 | 9, 8, 7, 6 | 9, 8, 7, 6 | 13, 14, 27, 26 | GP6–GP9 | GPIO 5, 6, 13, 19              |
| Keypad cols 1–4 | 5, 4, 3, 2 | 5, 4, 3, 2 | 25, 33, 32, 4  | GP10–GP13 | GPIO 12, 16, 20, 21          |

The Arduino pins are at the top of the sketch; the Raspberry Pi ones are command-line options.

## Arduino, ESP32 and Pico

1. Install the board support: nothing for AVR; *esp32* by Espressif for ESP32; *Raspberry Pi Pico/RP2040* by Earle Philhower for the Pico.
2. Install the libraries from the Library Manager: *LiquidCrystal I2C* (Frank de Brabander), *U8g2* (olikraus), *LedControl* (Eberhard Fahle), *Keypad* (Mark Stanley), and for ESP32 Wi-Fi *WebSockets* (Markus Sattler).
3. Open `firmware/arduino/glassbox_bridge/glassbox_bridge.ino` and set the options at the top: `USE_MATRIX`, `USE_KEYPAD`, and on ESP32 `WIFI_SSID` / `WIFI_PASSWORD` for Wi-Fi.
4. Upload. The Serial Monitor at 115200 baud shows `# GlassBox bridge ready`, and on ESP32 with Wi-Fi the address to use, e.g. `# Wi-Fi: ws://192.168.1.50:81`. Close the Serial Monitor before connecting GlassBox: only one program can hold the port.

The OLED uses U8g2's text mode, which needs no frame buffer, so all four parts fit in an Uno's 2 KB of RAM.

## Raspberry Pi

The bridge script needs Python 3.9+ and only the standard library; each part needs its driver:

```sh
sudo raspi-config nonint do_i2c 0      # LCD, OLED
sudo raspi-config nonint do_spi 0      # MAX7219
pip install RPLCD smbus2 luma.led_matrix luma.oled   # gpiozero is preinstalled

python3 firmware/raspberry-pi/glassbox_bridge.py --ws 0.0.0.0:8765 --lcd --matrix --oled --keypad
```

In GlassBox, choose Wi-Fi and enter the Pi's address with port 8765, e.g. `192.168.1.60:8765`.

To use a cable instead, put a Pi Zero, 4 or 5 in USB gadget mode (`dtoverlay=dwc2` in `config.txt`, `modules-load=dwc2,g_serial` in `cmdline.txt`). It then appears as a serial port on the computer, and the script listens with `--serial /dev/ttyGS0`. A USB-serial adapter on the Pi's UART works the same way with `--serial /dev/serial0`.

Without any hardware, `--simulate` draws the devices in the terminal and turns keys typed there (then Enter) into keypad presses. This is handy for trying the link:

```sh
python3 firmware/raspberry-pi/glassbox_bridge.py --ws 127.0.0.1:8765 --simulate
```

Other options: `--lcd-address 0x3F`, `--oled-address`, `--i2c-bus`, `--matrix-rotate 0-3`, `--matrix-flip`, `--keypad-rows`/`--keypad-cols` (BCM numbers), `--baud`.

To start it at boot, a systemd unit such as:

```ini
# /etc/systemd/system/glassbox.service
[Unit]
Description=GlassBox hardware bridge
After=network-online.target

[Service]
User=pi
ExecStart=/usr/bin/python3 /home/pi/glassbox-cpu/firmware/raspberry-pi/glassbox_bridge.py --ws 0.0.0.0:8765 --lcd --matrix --keypad
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## In GlassBox

Switch to the Extended CPU. The *Real hardware* button in the I/O devices panel opens the connection dialog:

- **USB serial:** on desktop, pick the port (refresh after plugging the board in) and keep 115200 baud. On the web, Connect opens the browser's port picker. On Linux, your user must be in the `dialout` group to open serial ports.
- **Wi-Fi:** enter the board's address. The port defaults to 81, the ESP32 sketch's.

Opening the serial port of an Uno or Nano reboots it, so the first connection takes about two seconds. Once connected, the button shows the board's name; *Resend state* in the dialog resets the board and sends everything again (for example after replugging a part). The dialog's log shows the board's own messages and any refused lines.

## Protocol

ASCII lines ending in `\n` (`\r\n` accepted), identical over serial and WebSocket. Numbers are two hex digits. Version 1 assumes the Extended CPU's port map: 0 display, 1–2 LCD, 3–4 LED matrix, 5 keypad.

GlassBox to board:

| Line      | Meaning                                    |
| --------- | ------------------------------------------ |
| `HELLO 1` | handshake, protocol version 1              |
| `W pp vv` | the CPU wrote `vv` to port `pp`            |
| `RESET`   | put every device in its power-on state     |

Board to GlassBox:

| Line                         | Meaning                                                        |
| ---------------------------- | -------------------------------------------------------------- |
| `GLASSBOX 1 <board> <parts>` | answer to `HELLO`, e.g. `GLASSBOX 1 esp32 lcd matrix keypad oled` |
| `A`                          | a `W` or `RESET` line was carried out                          |
| `E <text>`                   | a line was refused; counts as its answer                       |
| `K xx`                       | key with ASCII code `xx` pressed on the keypad                 |
| `# <text>`                   | a log line, shown in the connection dialog                     |

The board answers each `W` and `RESET` with exactly one `A` or `E`, in order. GlassBox keeps at most 4 lines unanswered over serial (32 bytes, half an Uno's receive buffer) and 32 over Wi-Fi. A slow part therefore delays the board instead of overflowing it. If answers stop for 3 seconds, GlassBox sends the whole state again. `K` and `#` lines may arrive at any time; anything else, such as boot noise from an ESP32, is ignored.

GlassBox sends `HELLO` every 0.8 s until it gets an answer, for up to 6 seconds; that covers boards that reboot when the port opens. The state it sends after connecting, resetting or stepping back is `RESET`, then `W 00` with the display value, then port writes that rebuild each device from power-on. For the LCD that means custom characters, both lines of display memory, then the display shift, cursor, entry mode and display control.
