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

enum DeviceMode {
  booting = 0,
  normal,
  wifi_setup
};

#define STATUS_LED 0
#define NUM_LEDS 2
// milliseconds
#define RETRIGGER_DELAY 15000

WiFiManager wifiManager;
Ticker animationTicker;

WiFiClientSecure wifi;
PubSubClient client(wifi);

CRGB leds[NUM_LEDS];
uint8_t mac[WL_MAC_ADDR_LENGTH];
char device_id[9];
char lantern_id[18];
char lantern_id_all[20];
char lantern_id_motion[24];
char lantern_id_status[24];
char color_hex[7];

DeviceMode device_mode = booting;

void configModeCallback(WiFiManager *myWiFiManager) {
  device_mode = wifi_setup;
  FastLED.showColor(CRGB::Yellow);
}

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  std::string payload_str ((char *)payload, length);

  char* subpath = topic + strlen(lantern_id) + 1;

  Serial.printf("Subtopic: %s\n", subpath);
  Serial.flush();
  if (strcmp("color", subpath) == 0) {
    payload_str.replace(0, 1, "0x");
    leds[0] = strtoul(payload_str.c_str(), nullptr, 16);
    FastLED.show();
  } else if (strcmp("white", subpath) == 0) {
    payload_str.replace(0, 1, "0x");
    leds[1] = strtoul(payload_str.c_str(), nullptr, 16);
    FastLED.show();
  } else if (strcmp("sleep", subpath) == 0) {
    long sleepTimeMs = strtoul(payload_str.c_str(), nullptr, 10);
    ESP.deepSleep(sleepTimeMs * 1000);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(STATUS_LED, OUTPUT);
  digitalWrite(STATUS_LED, 1); // LED off

  FastLED.addLeds<APA102, MOSI, SCK, BGR>(leds, NUM_LEDS);

  wifiManager.setAPCallback(configModeCallback);

  if (!wifiManager.autoConnect("Lantern")) {
    ESP.reset();
    delay(1000);
  }

  if (device_mode == wifi_setup) {
    device_mode = normal;
    FastLED.showColor(CRGB::Black);
  }

  WiFi.macAddress(mac);
  sprintf(device_id, "%02x%02x%02x%02x", mac[2], mac[3], mac[4], mac[5]);
  sprintf(lantern_id, "lantern/%s", device_id);
  sprintf(lantern_id_all, "lantern/%s/#", device_id);
  sprintf(lantern_id_motion, "lantern/%s/motion", device_id);
  sprintf(lantern_id_status, "lantern/%s/status", device_id);

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
}
