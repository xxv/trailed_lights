#include <avr/sleep.h>

#define INTERRUPT_PIN    4
#define ESP_RESET_PIN    3
#define RESET_TIME       100

volatile bool triggered = false;

ISR(PCINT0_vect) {
  triggered = true;
}

/**
 * Enable Pin Change Interrupt on given pin number.
 */
void pciSetup(byte pin) {
    *digitalPinToPCMSK(pin) |= bit (digitalPinToPCMSKbit(pin));  // enable pin
    bitSet(GIFR, PCIF);
    bitSet(GIMSK, PCIE);
}

/**
 * Enable sleep mode and turn on pin change interrupt
 */
void sleepNow() {
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_enable();

  // Enable PC interrupt
  pciSetup(INTERRUPT_PIN);

  // -.- zzz...
  sleep_mode();

  // !! O.O
  sleep_disable();

  // Disable PC interrupt
  bitClear(GIMSK, PCIE);
}

void setup() {
  pinMode(ESP_RESET_PIN, OUTPUT);
  pinMode(INTERRUPT_PIN, INPUT);

  digitalWrite(ESP_RESET_PIN, HIGH);

  pciSetup(INTERRUPT_PIN);
}

void loop() {
  if (triggered) {
    // only handle trigger on risen edge
    if (digitalRead(INTERRUPT_PIN)) {
      digitalWrite(ESP_RESET_PIN, LOW);
      delay(RESET_TIME);
      digitalWrite(ESP_RESET_PIN, HIGH);
      delay(RESET_TIME);
    }

    triggered = false;
  }

  sleepNow();
}
