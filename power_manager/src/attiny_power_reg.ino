#include <avr/sleep.h>
#include <WireS.h>

// Pin mapping (Arduino pin numbers)
const static byte BAT_MON_PIN   = A0;
const static byte AMBIENT_PIN   = A2;
const static byte ESP_RESET_PIN = PIN_B1;
const static byte ESP_RTC_PIN   = PIN_A1;
const static byte EXT_WAKE_PIN  = PIN_B0;
const static byte MOTION_PIN    = PIN_B2;

const static byte MY_I2C_ADDR = 0x50;
const static byte REG_BATTERY_LEVEL = 0x01;
const static byte REG_AMBIENT_LEVEL = 0x02;

// timings
const static byte RESET_TIME    = 100;

const static byte CMD_GET_BATT   = 0x62;
const static byte CMD_SET_RTC_EN = 0x72;
const static byte CMD_SLEEP_NOW  = 0x7A;

// Calibrations
const static int BATTERY_VAL_LOW  = 718;
const static int BATTERY_VAL_HIGH = 956;
const static int AMBIENT_VAL_ON   = 200; // 1.0v
const static int AMBIENT_VAL_OFF  = 100; // 1.0v

static bool wake_on_rtc = true;
static bool wake_on_motion = true;
static bool wake_on_external = true;

bool is_dark = true;
uint8_t last_motion = 0xff;
uint8_t last_ext_wake = 0xff;
uint8_t last_esp_reset = 0xff;
uint8_t current_register = 0;

volatile uint8_t trigger_source = 0;
volatile bool triggered = false;
volatile unsigned long triggered_time = 0;

ISR(PCINT0_vect) {
  triggered = true;
  triggered_time = millis();
}

ISR(PCINT1_vect) {
  triggered = true;
  triggered_time = millis();
}

/**
 * Enable Pin Change Interrupt on given pin number.
 */
void pciSetup(byte pin) {
  bitSet(*digitalPinToPCMSK(pin), digitalPinToPCMSKbit(pin)); // enable pin
  bitSet(*digitalPinToPCICR(pin), digitalPinToPCICRbit(pin)); // enable interrupt
}

/**
 * Enable sleep mode and turn on pin change interrupt
 */
void sleepNow() {
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_enable();

  // -.- zzz...
  sleep_mode();

  // !! O.O
  sleep_disable();

  disable_interrupts();
}

void enable_interrupts() {
  // Enable PC interrupt
  if (wake_on_motion) {
    pciSetup(MOTION_PIN);
  }

  if (wake_on_external) {
    pciSetup(EXT_WAKE_PIN);
    pinMode(EXT_WAKE_PIN, INPUT_PULLUP);
  }

  if (wake_on_rtc) {
    pciSetup(ESP_RTC_PIN);
  }
}

void disable_interrupts() {
  // Disable PC interrupt
  if (wake_on_motion) {
    bitClear(*digitalPinToPCICR(MOTION_PIN),
              digitalPinToPCICRbit(MOTION_PIN));
  }

  if (wake_on_external) {
    bitClear(*digitalPinToPCICR(EXT_WAKE_PIN),
              digitalPinToPCICRbit(EXT_WAKE_PIN));
  }

  if (wake_on_rtc) {
    bitClear(*digitalPinToPCICR(ESP_RTC_PIN),
              digitalPinToPCICRbit(ESP_RTC_PIN));
  }
}

int getAmbient() {
  return analogRead(AMBIENT_PIN);
}

uint8_t getAmbientByte() {
  return map(analogRead(AMBIENT_PIN), 0, 1023, 0, 255);
}

uint8_t getBattery() {
  return constrain(map(analogRead(BAT_MON_PIN),
                       BATTERY_VAL_LOW, BATTERY_VAL_HIGH, 0, 100),
                   0, 100);
}

void onReceive(size_t num_bytes) {
  if (num_bytes == 0) {
    return;
  }

  current_register = Wire.read();
  num_bytes--;

  while (Wire.available()) {
    Wire.read();
  }
}

void onRequest() {
  if (current_register == REG_BATTERY_LEVEL) {
    Wire.write(getBattery());
  } else if (current_register == REG_AMBIENT_LEVEL) {
    Wire.write(getAmbientByte());
  }

  current_register = 0;
}

void wake_esp() {
  digitalWrite(ESP_RESET_PIN, LOW);
  delay(RESET_TIME);
  digitalWrite(ESP_RESET_PIN, HIGH);
  delay(RESET_TIME);
}

void setup() {
  pinMode(ESP_RESET_PIN, OUTPUT);
  pinMode(AMBIENT_PIN, INPUT);
  pinMode(BAT_MON_PIN, INPUT);

  pinMode(MOTION_PIN, INPUT);
  pinMode(EXT_WAKE_PIN, INPUT);
  pinMode(ESP_RTC_PIN, INPUT);

  Wire.begin(MY_I2C_ADDR);
  Wire.onReceive(onReceive);
  Wire.onRequest(onRequest);

  // Reset output is active low
  digitalWrite(ESP_RESET_PIN, HIGH);

  enable_interrupts();
}

void loop() {
  if (triggered && (millis() - triggered_time) > 50) {
    // only handle trigger on risen edge
    uint8_t motion_val = !digitalRead(MOTION_PIN);
    uint8_t ext_wake_val = digitalRead(EXT_WAKE_PIN);
    uint8_t esp_reset_val = digitalRead(ESP_RESET_PIN);
    if (is_dark &&
        ((motion_val != last_motion && last_motion)
          || (ext_wake_val  != last_ext_wake  && ext_wake_val)
          || (esp_reset_val != last_esp_reset && esp_reset_val))) {
        wake_esp();
    }

    triggered = false;
    enable_interrupts();
    last_ext_wake = ext_wake_val;
    last_esp_reset = esp_reset_val;
    last_motion = motion_val;
  }

  int ambient = getAmbient();

  if (!is_dark && ambient >= AMBIENT_VAL_ON) {
    is_dark = true;
  } else if (is_dark && ambient <= AMBIENT_VAL_OFF) {
    is_dark = false;
  }
  delay(10);
}
