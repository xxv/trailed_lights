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

#define STATUS_LED 0
#define NUM_LEDS 2
// milliseconds
#define RETRIGGER_DELAY 15000

WiFiManager wifiManager;
Ticker animationTicker;

WiFiClientSecure wifi;
PubSubClient client(wifi);

CRGB leds[NUM_LEDS];
CRGB prev_leds[NUM_LEDS];
CRGB next_leds[NUM_LEDS];

fract8 color_fade = 0;

uint8_t mac[WL_MAC_ADDR_LENGTH];
char device_id[9];
char lantern_id[18];
char lantern_id_all[20];
char lantern_id_motion[24];
char lantern_id_status[24];
char lantern_id_ambient[25];
char color_hex[7];

uint8_t ambient = 0;
uint8_t battery = 0;
bool is_motion = false;
uint8_t no_motion_since_s = 0;
const static uint8_t MOTION_TIMEOUT_S = 5;

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
  Serial.print("Setting power manager register ");
  Serial.println(reg);

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
  Serial.print("Requesting power manager register ");
  Serial.println(reg);

  Wire.beginTransmission(POWER_MANAGER_ADDR);
  Wire.write(reg);
  int result = Wire.endTransmission();

  if (result) {
    Serial.print("Error requesting register: ");
    Serial.println(result);

    return 0;
  }

  uint8_t gotBytes = Wire.requestFrom(POWER_MANAGER_ADDR, (uint8_t)1);
  Serial.print("Received: ");
  Serial.println(gotBytes);
  uint8_t value;

  while(Wire.available()) {
    value = Wire.read();
    Serial.print(value);
    Serial.print(", ");
  }
  Serial.println();

  Serial.print("Last byte: ");
  Serial.println(value);

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

byte rtc_state[NUM_LEDS * 3];

void saveLedState() {
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    memcpy(&rtc_state[i * 3], leds[i].raw, 3);
  }

  if (!system_rtc_mem_write(70, rtc_state, sizeof(rtc_state))) {
    Serial.println("Could not write LED state to RTC");
  }
}

void restoreLedsFromState(CRGB* arr) {
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    memcpy(arr[i].raw, &rtc_state[i * 3], 3);
  }
}

void restoreLedState() {
  if (!system_rtc_mem_read(70, rtc_state, sizeof(rtc_state))) {
    Serial.println("Could not read LED state from RTC");
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

void beginSleep(long sleepTimeMs) {
  Serial.println("Sleeping now");
  saveLedState();
  setPMRegister(REG_SET_ESP_ASLEEP, true);
  ESP.deepSleep(sleepTimeMs * 1000);
}

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  std::string payload_str ((char *)payload, length);

  char* subpath = topic + strlen(lantern_id) + 1;

  if (strcmp("color", subpath) == 0) {
    payload_str.replace(0, 1, "0x");
    snapshotLeds();
    next_leds[0] = strtoul(payload_str.c_str(), nullptr, 16);
  } else if (strcmp("white", subpath) == 0) {
    payload_str.replace(0, 1, "0x");
    snapshotLeds();
    next_leds[1] = strtoul(payload_str.c_str(), nullptr, 16);
  } else if (strcmp("sleep", subpath) == 0) {
    long sleepTimeMs = strtoul(payload_str.c_str(), nullptr, 10);
    beginSleep(sleepTimeMs);
  } else if (strcmp("status_query", subpath) == 0) {
    char format_str[64];
    sprintf(format_str, "{\"ambient\":%d,\"battery\":%d}", ambient, battery);
    client.publish(lantern_id_ambient, format_str);
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
  Wire.setClockStretchLimit(10000);
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
  sprintf(lantern_id_ambient, "lantern/%s/ambient", device_id);

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
      client.publish(lantern_id_status, "online", 1);
      client.subscribe(lantern_id_all);
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

    if (is_motion) {
      no_motion_since_s = 0;
    } else {
      no_motion_since_s++;
    }
    Serial.print("No motion since: ");
    Serial.println(no_motion_since_s);
  }

  if (no_motion_since_s >= MOTION_TIMEOUT_S) {
    beginSleep(0);
  }
}
