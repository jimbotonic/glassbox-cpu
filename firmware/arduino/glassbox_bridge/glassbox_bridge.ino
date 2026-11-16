// GlassBox CPU hardware bridge for Arduino-compatible boards.
//
// GlassBox mirrors its I/O ports to this sketch over USB serial (every
// board) or Wi-Fi (ESP32), and the sketch drives real parts:
//
//   HD44780 16x2 LCD with PCF8574 I2C backpack   ports 1-2   (detected)
//   SSD1306 128x64 OLED on I2C: port 0, LCD text, LED matrix  (detected)
//   MAX7219 8x8 LED matrix                        ports 3-4   USE_MATRIX
//   4x4 membrane keypad, sent back as port 5                  USE_KEYPAD
//
// Boards: Arduino Uno / Nano / Mega (AVR), ESP32, Raspberry Pi Pico with
// the arduino-pico core (Earle Philhower). Libraries, from the Library
// Manager:
//
//   LiquidCrystal I2C  (Frank de Brabander)   for the LCD
//   U8g2               (olikraus)             for the OLED, text mode only
//   LedControl         (Eberhard Fahle)       if USE_MATRIX
//   Keypad             (Mark Stanley)         if USE_KEYPAD
//   WebSockets         (Markus Sattler)       ESP32 Wi-Fi only
//
// Wiring per board: docs/hardware-bridge.md. Protocol: same file.

// ------------------------------------------------------------ settings

#define USE_MATRIX 1  // 0 if no MAX7219 is wired
#define USE_KEYPAD 1  // 0 if no keypad is wired
#define USE_LCD 1     // 0 to drop the LCD code (it is also auto-detected)
#define USE_OLED 1    // 0 to drop the OLED code (it is also auto-detected)

#define BAUD 115200

// Mirror the matrix if your module shows it backwards / upside down.
#define MATRIX_FLIP_X 0
#define MATRIX_FLIP_Y 0

#if defined(ESP32)
// Leave WIFI_SSID empty for USB only. The board prints its address at boot.
#define WIFI_SSID ""
#define WIFI_PASSWORD ""
#define WS_PORT 81
#endif

// ---------------------------------------------------------------- pins

#if defined(ESP32)
#define BOARD_NAME "esp32"
const uint8_t MATRIX_DIN = 23, MATRIX_CLK = 18, MATRIX_CS = 5;
uint8_t keypadRows[4] = {13, 14, 27, 26};
uint8_t keypadCols[4] = {25, 33, 32, 4};
#elif defined(ARDUINO_ARCH_RP2040)
#define BOARD_NAME "pico"
const uint8_t MATRIX_DIN = 19, MATRIX_CLK = 18, MATRIX_CS = 17;
uint8_t keypadRows[4] = {6, 7, 8, 9};
uint8_t keypadCols[4] = {10, 11, 12, 13};
#elif defined(ARDUINO_AVR_MEGA2560)
#define BOARD_NAME "mega"
const uint8_t MATRIX_DIN = 12, MATRIX_CLK = 11, MATRIX_CS = 10;
uint8_t keypadRows[4] = {9, 8, 7, 6};
uint8_t keypadCols[4] = {5, 4, 3, 2};
#else
#define BOARD_NAME "uno"
const uint8_t MATRIX_DIN = 12, MATRIX_CLK = 11, MATRIX_CS = 10;
uint8_t keypadRows[4] = {9, 8, 7, 6};
uint8_t keypadCols[4] = {5, 4, 3, 2};
#endif

// ------------------------------------------------------------ includes

#include <Wire.h>

#if USE_LCD
#include <LiquidCrystal_I2C.h>
#endif
#if USE_OLED
#include <U8x8lib.h>
#endif
#if USE_MATRIX
#include <LedControl.h>
#endif
#if USE_KEYPAD
#include <Keypad.h>
#endif
#if defined(ESP32)
#include <WiFi.h>
#include <WebSocketsServer.h>
#endif

const uint8_t PROTOCOL = 1;
const uint8_t PORT_DISPLAY = 0, PORT_LCD_CMD = 1, PORT_LCD_DATA = 2,
              PORT_MATRIX_ROW = 3, PORT_MATRIX_DATA = 4;

// ---------------------------------------------------------------- state

uint8_t display = 0;      // port 0
uint8_t matrixRows[8];    // ports 3-4, bit 7 = left
uint8_t matrixRow = 0;

#if USE_LCD
uint8_t lcdAddress = 0;   // 0 = not found
LiquidCrystal_I2C *lcd = nullptr;
#endif

#if USE_MATRIX
LedControl matrix(MATRIX_DIN, MATRIX_CLK, MATRIX_CS, 1);
#endif

#if USE_KEYPAD
char keypadKeys[4][4] = {
    {'1', '2', '3', 'A'},
    {'4', '5', '6', 'B'},
    {'7', '8', '9', 'C'},
    {'*', '0', '#', 'D'},
};
Keypad keypad(makeKeymap(keypadKeys), keypadRows, keypadCols, 4, 4);
#endif

#if USE_OLED
bool oledFound = false;
U8X8_SSD1306_128X64_NONAME_HW_I2C oled(U8X8_PIN_NONE);
bool oledDirty = true;
unsigned long oledDrawnAt = 0;

// The HD44780 as GlassBox simulates it, so the OLED can show its text.
struct LcdModel {
  uint8_t ddram[0x80];
  uint8_t cgram[64];
  uint8_t address;
  bool cgMode, displayOn, moveRight, shiftOnWrite, twoLines;
  uint8_t shift;

  void reset() {
    memset(ddram, 0x20, sizeof ddram);
    memset(cgram, 0, sizeof cgram);
    address = 0;
    cgMode = displayOn = shiftOnWrite = false;
    moveRight = twoLines = true;
    shift = 0;
  }

  uint8_t charAt(uint8_t row, uint8_t col) {
    return ddram[row * 0x40 + (col + shift) % 40];
  }

  void move(bool right) {
    if (!twoLines) {
      address = right ? (address + 1) % 0x50 : (address + 0x4F) % 0x50;
    } else if (right) {
      address = address == 0x27 ? 0x40 : address == 0x67 ? 0x00 : (address + 1) & 0x7F;
    } else {
      address = address == 0x40 ? 0x27 : address == 0x00 ? 0x67 : (address - 1) & 0x7F;
    }
  }

  void shiftDisplay(bool right) { shift = (shift + (right ? 39 : 1)) % 40; }

  void command(uint8_t v) {
    if (v & 0x80) {
      address = v & 0x7F;
      cgMode = false;
    } else if (v & 0x40) {
      address = v & 0x3F;
      cgMode = true;
    } else if (v & 0x20) {
      twoLines = v & 0x08;
    } else if (v & 0x10) {
      if (v & 0x08) {
        shiftDisplay(v & 0x04);
      } else {
        cgMode = false;
        move(v & 0x04);
      }
    } else if (v & 0x08) {
      displayOn = v & 0x04;
    } else if (v & 0x04) {
      moveRight = v & 0x02;
      shiftOnWrite = v & 0x01;
    } else if (v & 0x02) {
      address = 0;
      cgMode = false;
      shift = 0;
    } else if (v & 0x01) {
      memset(ddram, 0x20, sizeof ddram);
      address = 0;
      cgMode = false;
      shift = 0;
      moveRight = true;
    }
  }

  void data(uint8_t v) {
    if (cgMode) {
      cgram[address] = v & 0x1F;
      address = (address + (moveRight ? 1 : 63)) & 0x3F;
      return;
    }
    ddram[address] = v;
    move(moveRight);
    if (shiftOnWrite) shiftDisplay(!moveRight);
  }
} lcdModel;
#endif

// ------------------------------------------------------------- devices

bool i2cPresent(uint8_t address) {
  Wire.beginTransmission(address);
  return Wire.endTransmission() == 0;
}

void showMatrixRow(uint8_t row) {
#if USE_MATRIX
  uint8_t bits = matrixRows[row];
  if (MATRIX_FLIP_X) {
    uint8_t r = 0;
    for (uint8_t i = 0; i < 8; i++) r |= ((bits >> i) & 1) << (7 - i);
    bits = r;
  }
  matrix.setRow(0, MATRIX_FLIP_Y ? 7 - row : row, bits);
#endif
}

#if USE_LCD
void lcdCommand(uint8_t v) {
  if ((v & 0xE0) == 0x20) {
    // Function set: GlassBox programs ask for the 8-bit interface, but
    // the backpack wires the LCD in 4-bit mode. Keep 4-bit.
    v = 0x20 | (v & 0x0C);
  }
  if (v == 0x01) {
    lcd->clear();  // waits the 1.6 ms the chip needs
  } else if ((v & 0xFE) == 0x02) {
    lcd->home();
  } else {
    lcd->command(v);
  }
}
#endif

void resetDevices() {
  display = 0;
  memset(matrixRows, 0, sizeof matrixRows);
  matrixRow = 0;
#if USE_MATRIX
  matrix.clearDisplay(0);
#endif
#if USE_LCD
  if (lcd) {
    lcd->clear();
    lcd->command(0x40);  // blank the custom characters
    for (uint8_t i = 0; i < 64; i++) lcd->write(0);
    lcd->command(0x06);
    lcd->command(0x80);
    lcd->command(0x08);  // display off, as after power-on
  }
#endif
#if USE_OLED
  lcdModel.reset();
  oledDirty = true;
#endif
}

void writePort(uint8_t port, uint8_t value) {
  switch (port) {
    case PORT_DISPLAY:
      display = value;
      break;
    case PORT_LCD_CMD:
#if USE_LCD
      if (lcd) lcdCommand(value);
#endif
#if USE_OLED
      lcdModel.command(value);
#endif
      break;
    case PORT_LCD_DATA:
#if USE_LCD
      if (lcd) lcd->write(value);
#endif
#if USE_OLED
      lcdModel.data(value);
#endif
      break;
    case PORT_MATRIX_ROW:
      matrixRow = value % 8;
      break;
    case PORT_MATRIX_DATA:
      matrixRows[matrixRow] = value;
      showMatrixRow(matrixRow);
      matrixRow = (matrixRow + 1) % 8;
      break;
    default:
      return;  // nothing on that port here
  }
#if USE_OLED
  oledDirty = true;
#endif
}

// ----------------------------------------------------------------- OLED

#if USE_OLED
// One 8x8 tile of the LED matrix drawn 4 px per LED (3 lit, 1 gap):
// tile (tx, ty) covers LEDs tx*2..tx*2+1, ty*2..ty*2+1. A tile byte is a
// pixel column, bit 0 at the top.
void matrixTile(uint8_t tx, uint8_t ty, uint8_t *tile) {
  for (uint8_t px = 0; px < 8; px++) {
    uint8_t col = tx * 2 + px / 4, b = 0;
    if (px % 4 != 3) {
      for (uint8_t py = 0; py < 8; py++) {
        uint8_t row = ty * 2 + py / 4;
        if (py % 4 != 3 && (matrixRows[row] >> (7 - col)) & 1) b |= 1 << py;
      }
    }
    tile[px] = b;
  }
}

// A custom LCD character (5x8, bit 4 on the left) as a tile.
void glyphTile(uint8_t code, uint8_t *tile) {
  const uint8_t *rows = &lcdModel.cgram[(code & 7) * 8];
  for (uint8_t px = 0; px < 8; px++) {
    uint8_t b = 0;
    if (px >= 1 && px <= 5) {
      for (uint8_t py = 0; py < 8; py++) {
        if ((rows[py] >> (5 - px)) & 1) b |= 1 << py;
      }
    }
    tile[px] = b;
  }
}

char asciiFor(uint8_t code) {
  if (code >= 0x20 && code <= 0x7D) return code == 0x5C ? 'Y' : code;
  if (code == 0x7E) return '>';
  if (code == 0x7F) return '<';
  return code >= 0x80 ? '?' : ' ';
}

void drawOled() {
  char line[17];
  snprintf(line, sizeof line, "GLASSBOX OUT%4u", display);
  oled.drawString(0, 0, line);
  for (uint8_t r = 0; r < 2; r++) {
    for (uint8_t c = 0; c < 16; c++) {
      uint8_t code = lcdModel.displayOn ? lcdModel.charAt(r, c) : 0x20;
      if (code < 0x10) {
        uint8_t tile[8];
        glyphTile(code, tile);
        oled.drawTile(c, 2 + r, 1, tile);
      } else {
        char s[2] = {asciiFor(code), 0};
        oled.drawString(c, 2 + r, s);
      }
    }
  }
  for (uint8_t ty = 0; ty < 4; ty++) {
    for (uint8_t tx = 0; tx < 4; tx++) {
      uint8_t tile[8];
      matrixTile(tx, ty, tile);
      oled.drawTile(tx, 4 + ty, 1, tile);
    }
  }
  snprintf(line, sizeof line, "0x%02X", display);
  oled.drawString(6, 5, line);
  for (uint8_t i = 0; i < 8; i++) line[i] = (display >> (7 - i)) & 1 ? '1' : '0';
  line[8] = 0;
  oled.drawString(6, 6, line);
}
#endif

// ------------------------------------------------------------- protocol

// Where a line came from, so its answer goes back there.
typedef void (*Reply)(const char *line);

void replySerial(const char *line) {
  Serial.print(line);
  Serial.print('\n');
}

#if defined(ESP32)
WebSocketsServer *webSocket = nullptr;
uint8_t replyClient = 0;
void replyWebSocket(const char *line) {
  String text = String(line) + "\n";
  webSocket->sendTXT(replyClient, text);
}
#endif

void sendAll(const char *line) {
  replySerial(line);
#if defined(ESP32)
  if (webSocket) {
    String text = String(line) + "\n";
    webSocket->broadcastTXT(text);
  }
#endif
}

int hexByte(const char *s) {
  int v = 0;
  for (uint8_t i = 0; i < 2; i++) {
    char c = s[i];
    v <<= 4;
    if (c >= '0' && c <= '9') v |= c - '0';
    else if (c >= 'A' && c <= 'F') v |= c - 'A' + 10;
    else if (c >= 'a' && c <= 'f') v |= c - 'a' + 10;
    else return -1;
  }
  return v;
}

void handleLine(char *line, Reply reply) {
  size_t n = strlen(line);
  while (n && (line[n - 1] == '\r' || line[n - 1] == ' ')) line[--n] = 0;
  if (n == 0) return;
  if (strncmp(line, "HELLO", 5) == 0) {
    char hello[64];
    snprintf(hello, sizeof hello, "GLASSBOX %u %s%s%s%s%s", PROTOCOL, BOARD_NAME,
#if USE_LCD
             lcd ? " lcd" : "",
#else
             "",
#endif
             USE_MATRIX ? " matrix" : "", USE_KEYPAD ? " keypad" : "",
#if USE_OLED
             oledFound ? " oled" : ""
#else
             ""
#endif
    );
    reply(hello);
  } else if (strcmp(line, "RESET") == 0) {
    resetDevices();
    reply("A");
  } else if (n == 7 && line[0] == 'W' && line[1] == ' ' && line[4] == ' ') {
    int port = hexByte(line + 2), value = hexByte(line + 5);
    if (port < 0 || value < 0) {
      reply("E bad number");
      return;
    }
    writePort(port, value);
    reply("A");
  } else {
    reply("E unknown line");
  }
}

char serialLine[40];
uint8_t serialLength = 0;

void readSerial() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n') {
      serialLine[serialLength] = 0;
      handleLine(serialLine, replySerial);
      serialLength = 0;
    } else if (serialLength < sizeof serialLine - 1) {
      serialLine[serialLength++] = c;
    } else {
      serialLength = 0;  // too long: not a protocol line
    }
  }
}

#if defined(ESP32)
void onWebSocket(uint8_t client, WStype_t type, uint8_t *payload, size_t length) {
  if (type == WStype_CONNECTED) {
    Serial.printf("# GlassBox connected over Wi-Fi (client %u)\n", client);
  } else if (type == WStype_TEXT || type == WStype_BIN) {
    replyClient = client;
    // A frame may hold several lines.
    char line[40];
    uint8_t len = 0;
    for (size_t i = 0; i < length; i++) {
      char c = payload[i];
      if (c == '\n') {
        line[len] = 0;
        handleLine(line, replyWebSocket);
        len = 0;
      } else if (len < sizeof line - 1) {
        line[len++] = c;
      }
    }
    if (len) {
      line[len] = 0;
      handleLine(line, replyWebSocket);
    }
  }
}
#endif

// ---------------------------------------------------------------- setup

void setup() {
  Serial.begin(BAUD);
  Wire.begin();

#if USE_LCD
  const uint8_t lcdAddresses[] = {0x27, 0x3F};  // PCF8574 / PCF8574A
  for (uint8_t i = 0; i < 2 && !lcdAddress; i++) {
    if (i2cPresent(lcdAddresses[i])) lcdAddress = lcdAddresses[i];
  }
  if (lcdAddress) {
    lcd = new LiquidCrystal_I2C(lcdAddress, 16, 2);
    lcd->init();
    lcd->backlight();
  }
#endif

#if USE_OLED
  oledFound = i2cPresent(0x3C);
  if (oledFound) {
    oled.begin();
    oled.setFont(u8x8_font_chroma48medium8_r);
    oled.clearDisplay();
  }
#endif

#if USE_MATRIX
  matrix.shutdown(0, false);
  matrix.setIntensity(0, 4);
#endif

  resetDevices();

#if defined(ESP32)
  if (strlen(WIFI_SSID) > 0) {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("# Wi-Fi: connecting to " WIFI_SSID "\n");
    for (int i = 0; i < 40 && WiFi.status() != WL_CONNECTED; i++) delay(250);
    if (WiFi.status() == WL_CONNECTED) {
      webSocket = new WebSocketsServer(WS_PORT);
      webSocket->begin();
      webSocket->onEvent(onWebSocket);
      Serial.printf("# Wi-Fi: ws://%s:%u\n", WiFi.localIP().toString().c_str(), WS_PORT);
    } else {
      Serial.print("# Wi-Fi: could not connect; USB only\n");
    }
  }
#endif

  Serial.print("# GlassBox bridge ready\n");
}

// ----------------------------------------------------------------- loop

void loop() {
  readSerial();
#if defined(ESP32)
  if (webSocket) webSocket->loop();
#endif

#if USE_KEYPAD
  char key = keypad.getKey();
  if (key) {
    char line[8];
    snprintf(line, sizeof line, "K %02X", (uint8_t)key);
    sendAll(line);
  }
#endif

#if USE_OLED
  // Redraw when idle, or at least 5 times a second while busy.
  if (oledFound && oledDirty &&
      (!Serial.available() || millis() - oledDrawnAt > 200)) {
    oledDirty = false;
    oledDrawnAt = millis();
    drawOled();
  }
#endif
}
