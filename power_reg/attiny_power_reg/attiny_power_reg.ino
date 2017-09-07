#include <avr/sleep.h>

// Pin mapping
const static byte BAT_MON_PIN   = A0;
const static byte ESP_RESET_PIN = 9;
const static byte ESP_RTC_PIN   = 1;
const static byte EXT_WAKE_PIN  = 10;
const static byte INTERRUPT_PIN = 8;

// timings
const static byte RESET_TIME    = 100;

const static byte CMD_GET_BATT   = 0x62;
const static byte CMD_SET_RTC_EN = 0x72;
const static byte CMD_SLEEP_NOW  = 0x7A;

const static int BATTERY_VAL_LOW  = 718;
const static int BATTERY_VAL_HIGH = 956;

static bool wake_on_rtc = true;

volatile uint8_t trigger_source = 0;
volatile bool triggered = false;
volatile unsigned long triggered_time = 0;

ISR(PCINT0_vect) {
  triggered = true;
  trigger_source = ESP_RTC_PIN;
  triggered_time = millis();
}

ISR(PCINT1_vect) {
  triggered = true;
  trigger_source = INTERRUPT_PIN;
  triggered_time = millis();
}

/**
 * Enable Pin Change Interrupt on given pin number.
 */
void pciSetup(byte pin) {
  pinMode(pin, INPUT);
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
  pciSetup(INTERRUPT_PIN);
  pciSetup(EXT_WAKE_PIN);
  pinMode(EXT_WAKE_PIN, INPUT_PULLUP);

  if (wake_on_rtc) {
    pciSetup(ESP_RTC_PIN);
  }
}

void disable_interrupts() {
  // Disable PC interrupt
  bitClear(*digitalPinToPCICR(INTERRUPT_PIN),
            digitalPinToPCICRbit(INTERRUPT_PIN));
  bitClear(*digitalPinToPCICR(EXT_WAKE_PIN),
            digitalPinToPCICRbit(EXT_WAKE_PIN));

  if (wake_on_rtc) {
    bitClear(*digitalPinToPCICR(ESP_RTC_PIN),
              digitalPinToPCICRbit(ESP_RTC_PIN));
  }
}

uint8_t getBattery() {
  return constrain(map(analogRead(BAT_MON_PIN),
                       BATTERY_VAL_LOW, BATTERY_VAL_HIGH, 0, 100),
                   0, 100);
}

void setup() {
  pinMode(ESP_RESET_PIN, OUTPUT);

  // Reset output is active low
  digitalWrite(ESP_RESET_PIN, HIGH);

  enable_interrupts();
}

void loop() {
  if (triggered && (millis() - triggered_time) > 50) {
    // only handle trigger on risen edge
    if ((trigger_source == INTERRUPT_PIN
         && ((digitalRead(INTERRUPT_PIN) || !digitalRead(EXT_WAKE_PIN))))
        || (trigger_source == ESP_RTC_PIN && !digitalRead(ESP_RTC_PIN))) {
      digitalWrite(ESP_RESET_PIN, LOW);
      delay(RESET_TIME);
      digitalWrite(ESP_RESET_PIN, HIGH);
      delay(RESET_TIME);
    }

    triggered = false;
    enable_interrupts();
    sleepNow();
  }

  delay(1);
}
