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

const static byte POWER_MANAGER_ADDR = 0x50;
const static byte REG_BATTERY_LEVEL = 0x01;
const static byte REG_AMBIENT_LEVEL = 0x02;

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

fract8 color_fade = 0xff;

uint8_t mac[WL_MAC_ADDR_LENGTH];
char device_id[9];
char lantern_id[18];
char lantern_id_all[20];
char lantern_id_motion[24];
char lantern_id_status[24];
char lantern_id_battery[25];
char color_hex[7];

DeviceMode device_mode = booting;

void configModeCallback(WiFiManager *myWiFiManager) {
  device_mode = wifi_setup;
  leds[0] = CRGB::Yellow;
  leds[0].nscale8(127);

  FastLED.show();
}

uint8_t getBattery() {
  Wire.beginTransmission(POWER_MANAGER_ADDR);
  Wire.write(REG_BATTERY_LEVEL);
  Wire.endTransmission();
  Wire.requestFrom(POWER_MANAGER_ADDR, 1);

  return Wire.read();
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
}

void snapshotLeds() {
    prev_leds[0] = leds[0];
    prev_leds[1] = leds[1];
    color_fade = 0;
}

void beginSleep(long sleepTimeMs) {
  saveLedState();
  ESP.deepSleep(sleepTimeMs * 1000);
}

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  std::string payload_str ((char *)payload, length);

  char* subpath = topic + strlen(lantern_id) + 1;

  Serial.printf("Subtopic: %s\n", subpath);
  Serial.flush();
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
    char* battery_level = "1000";
    sprintf(battery_level, "%d", getBattery());
    client.publish(lantern_id_battery, battery_level);
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
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
  sprintf(lantern_id_battery, "lantern/%s/battery", device_id);

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
      FastLED.show();
    }
  }
}
