#include "Secrets.h"

#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <WiFiManager.h>
#define FASTLED_ESP8266_RAW_PIN_ORDER
#include <FastLED.h>
#include <Ticker.h>
#include <PubSubClient.h>
#include <Wire.h>

enum DeviceMode {
  booting = 0,
  normal,
  wifi_setup
};

const static byte POWER_MANAGER_ADDR    = 0x50;
const static byte REG_GET_BATTERY_LEVEL = 0x01;
const static byte REG_GET_AMBIENT_LEVEL = 0x02;
const static byte REG_GET_MOTION        = 0x03;
const static byte REG_SET_ESP_ASLEEP    = 0x04;

const static uint8_t STATUS_LED = 0;
// APA102 LEDs
const static uint8_t NUM_LEDS = 2;

// the number of seconds of no motion until lantern sleeps
const static uint8_t DEFAULT_MOTION_TIMEOUT_S = 15;
const static uint8_t POWERDOWN_BATTERY_LEVEL = 10;

const static byte RTC_FINGERPRINT[] = { 'l', 'n' };

WiFiManager wifiManager;
Ticker animationTicker;

WiFiClientSecure wifi;
PubSubClient client(wifi);

CRGB leds[NUM_LEDS];
CRGB prev_leds[NUM_LEDS];
CRGB next_leds[NUM_LEDS];
CRGB default_leds[NUM_LEDS];

fract8 color_fade = 0;

uint8_t mac[WL_MAC_ADDR_LENGTH];
char device_id[9];
char lantern_id[18];
char lantern_id_all[20];
char lantern_id_motion[24];
char lantern_id_status[24];
char lantern_id_sensors[25];

// MQTT-Configurable parameters
int motion_timeout_s = DEFAULT_MOTION_TIMEOUT_S;
bool default_color_on_sleep = 0;

// Transient state
uint8_t ambient = 0;
uint8_t battery = 0;
bool is_motion = false;
int no_motion_since_s = 0;
bool is_fading_off_to_sleep = 0;

byte rtc_state[sizeof(RTC_FINGERPRINT) + NUM_LEDS * 3];

DeviceMode device_mode = booting;

void configModeCallback(WiFiManager *myWiFiManager) {
  device_mode = wifi_setup;
  leds[0] = CRGB::Yellow;
  leds[0].nscale8(127);

  FastLED.show();
}

/**
 * Set the given power manager register to the supplied value.
 */
bool setPMRegister(uint8_t reg, uint8_t value) {
  uint8_t buff[2];

  Wire.beginTransmission(POWER_MANAGER_ADDR);
  buff[0] = reg;
  buff[1] = value;
  Wire.write(buff, 2);
  int result = Wire.endTransmission();

  if (result) {
    Serial.print("Error setting register: ");
    Serial.println(result);

    return false;
  }

  return value;
}

/**
 * Retrieve the given power manager register value.
 */
uint8_t getPMRegister(uint8_t reg) {
  Wire.beginTransmission(POWER_MANAGER_ADDR);
  Wire.write(reg);
  int result = Wire.endTransmission();

  if (result) {
    Serial.print("Error requesting register: ");
    Serial.println(result);

    return 0;
  }

  uint8_t gotBytes = Wire.requestFrom(POWER_MANAGER_ADDR, (uint8_t)1);
  uint8_t value;

  while(Wire.available()) {
    value = Wire.read();
  }

  Wire.endTransmission();

  return value;
}

uint8_t getAmbient() {
  return getPMRegister(REG_GET_AMBIENT_LEVEL);
}

uint8_t getBattery() {
  return getPMRegister(REG_GET_BATTERY_LEVEL);
}

bool getMotion() {
  return getPMRegister(REG_GET_MOTION);
}

void saveLedState() {
  memcpy(rtc_state, RTC_FINGERPRINT, sizeof(RTC_FINGERPRINT));

  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    memcpy(&rtc_state[sizeof(RTC_FINGERPRINT) + i * 3], leds[i].raw, 3);
  }

  if (!system_rtc_mem_write(70, rtc_state, sizeof(rtc_state))) {
    Serial.println("Could not write LED state to RTC");
  }
}

void restoreLedsFromState(CRGB* arr) {
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    memcpy(arr[i].raw, &rtc_state[sizeof(RTC_FINGERPRINT) + i * 3], 3);
  }
}

void restoreLedState() {
  if (!system_rtc_mem_read(70, rtc_state, sizeof(rtc_state))) {
    Serial.println("Could not read LED state from RTC");
    return;
  }

  if (memcmp(rtc_state, RTC_FINGERPRINT, sizeof(RTC_FINGERPRINT)) != 0) {
    Serial.println("RTC memory does not contain fingerprint. Not restoring");
    return;
  }

  restoreLedsFromState(leds);
  restoreLedsFromState(next_leds);
  restoreLedsFromState(prev_leds);
}

void snapshotLeds() {
    prev_leds[0] = leds[0];
    prev_leds[1] = leds[1];
    color_fade = 0;
}

void powerDown() {
  FastLED.clear(true);
  beginSleep(0);
}

void gentleSleep() {
  if (default_color_on_sleep) {
    snapshotLeds();
    next_leds[0] = default_leds[0];
    next_leds[1] = default_leds[1];
    is_fading_off_to_sleep = true;
  } else {
    beginSleep(0);
  }
}

void beginSleep(long sleepTimeMs) {
  Serial.println("Sleeping now");
  saveLedState();
  setPMRegister(REG_SET_ESP_ASLEEP, true);
  ESP.deepSleep(sleepTimeMs * 1000);
}

void publishSensorStatus() {
    char format_str[64];
    sprintf(format_str, "{\"ambient\":%d,\"battery\":%d,\"motion\":%s}",
            ambient, battery, is_motion ? "true" : "false");
    client.publish(lantern_id_sensors, format_str);
}

long decodeColor(std::string &colorString) {
  std::string modifiedColor = colorString;
  modifiedColor.replace(0, 1, "0x");
  return strtoul(modifiedColor.c_str(), nullptr, 16);
}

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  std::string payload_str ((char *)payload, length);

  char* subpath = topic + strlen(lantern_id) + 1;

  if (strcmp("color", subpath) == 0) {
    snapshotLeds();
    next_leds[0] = decodeColor(payload_str);
  } else if (strcmp("white", subpath) == 0) {
    snapshotLeds();
    next_leds[1] = decodeColor(payload_str);
  } else if (strcmp("sleep", subpath) == 0) {
    long sleepTimeMs = strtoul(payload_str.c_str(), nullptr, 10);
    beginSleep(sleepTimeMs);
  } else if (strcmp("status_query", subpath) == 0) {
    publishSensorStatus();
  } else if (strcmp("lanterns/motion_timeout", topic) == 0) {
    motion_timeout_s = strtol(payload_str.c_str(), nullptr, 10);
  } else if (strcmp("lanterns/default_color", topic) == 0) {
    default_leds[0] = decodeColor(payload_str);
  } else if (strcmp("lanterns/default_white", topic) == 0) {
    default_leds[1] = decodeColor(payload_str);
  } else if (strcmp("lanterns/default_color_on_sleep", topic) == 0) {
    default_color_on_sleep = strtol(payload_str.c_str(), nullptr, 10);
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
  Wire.setClockStretchLimit(100000);
  pinMode(STATUS_LED, OUTPUT);
  digitalWrite(STATUS_LED, 1); // LED off

  FastLED.addLeds<APA102, MOSI, SCK, BGR>(leds, NUM_LEDS);
  FastLED.setDither(0);

  wifiManager.setAPCallback(configModeCallback);

  if (!wifiManager.autoConnect("Lantern")) {
    ESP.reset();
    delay(1000);
  }

  if (device_mode == wifi_setup) {
    device_mode = normal;
    FastLED.showColor(CRGB::Black);
  }

  restoreLedState();

  WiFi.macAddress(mac);
  sprintf(device_id, "%02x%02x%02x%02x", mac[2], mac[3], mac[4], mac[5]);
  sprintf(lantern_id, "lantern/%s", device_id);
  sprintf(lantern_id_all, "lantern/%s/#", device_id);
  sprintf(lantern_id_motion, "lantern/%s/motion", device_id);
  sprintf(lantern_id_status, "lantern/%s/status", device_id);
  sprintf(lantern_id_sensors, "lantern/%s/sensors", device_id);

  randomSeed(micros());

  client.setServer(mqtt_host, mqtt_port);
  client.setCallback(mqtt_callback);
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    // Create a random client ID
    String clientId = "lantern-";
    clientId += device_id;

    bool connected;
    if (strlen(mqtt_user) == 0) {
      connected = client.connect(clientId.c_str(), lantern_id_status,
                                 0, 1, "offline");
    } else {
      connected = client.connect(clientId.c_str(), mqtt_user, mqtt_password,
                                 lantern_id_status, 0, 1, "offline");
    }

    if (connected) {
      digitalWrite(STATUS_LED, 1);
      // Once connected, publish an announcement...
      client.subscribe(lantern_id_all);
      client.subscribe("lanterns/#");

      client.publish(lantern_id_status, "online", 1);
      client.publish(lantern_id_motion, "");
    } else {
      digitalWrite(STATUS_LED, 0);
    }
  }
}

void loop() {
  while (!client.connected()) {
    reconnect();
  }

  client.loop();

  EVERY_N_MILLIS(5) {
    if (color_fade < 0xff) {
      color_fade += 1;

      for (uint8_t i = 0; i < NUM_LEDS; i++) {
        leds[i] = prev_leds[i].lerp8(next_leds[i], color_fade);
      }

      // Do this once the color has settled in case there's a stray board reset
      if (color_fade == 0xff) {
        saveLedState();
      }

      FastLED.show();
    }
  }

  EVERY_N_SECONDS(1) {
    ambient = getAmbient();
    battery = getBattery();
    is_motion = getMotion();
    Serial.printf("Ambient: %d, battery: %d, motion: %d\n", ambient, battery, is_motion);

    if (is_motion) {
      no_motion_since_s = 0;
    } else {
      no_motion_since_s++;
    }

    Serial.print("No motion since: ");
    Serial.println(no_motion_since_s);

    if (battery < POWERDOWN_BATTERY_LEVEL) {
      powerDown();
    }
  }

  if (is_fading_off_to_sleep) {
    if (color_fade == 0xff) {
      is_fading_off_to_sleep = 0;
      beginSleep(0);
    }
  } else if (no_motion_since_s >= motion_timeout_s) {
    gentleSleep();
  }
}
