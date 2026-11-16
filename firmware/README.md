# GlassBox hardware firmware

Firmware that lets a real board mirror the GlassBox CPU's I/O ports:

- `arduino/glassbox_bridge/`: Arduino Uno, Nano, Mega, ESP32 (USB and Wi-Fi) and Raspberry Pi Pico (arduino-pico core).
- `raspberry-pi/glassbox_bridge.py`: Raspberry Pi running Linux, over Wi-Fi or a serial line. `--simulate` runs it without hardware.

Wiring, setup and the protocol: [../docs/hardware-bridge.md](../docs/hardware-bridge.md).
