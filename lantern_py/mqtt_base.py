"""MQTTBase"""

import ssl

import paho.mqtt.client as paho

class MQTTBase():
    def __init__(self, mqtt):
        self.mqtt_config = mqtt
        self.mqtt = paho.Client()
        self.mqtt.on_connect = self.on_connect
        self.mqtt.on_message = self.on_message

    def connect(self):
        print("Connecting to {host}:{port}...".format(**self.mqtt_config))
        if 'ca_certs' in self.mqtt_config:
            self.mqtt.tls_set(self.mqtt_config['ca_certs'], tls_version=ssl.PROTOCOL_TLSv1_2)

        if 'user' in self.mqtt_config:
            self.mqtt.username_pw_set(self.mqtt_config['user'], self.mqtt_config['password'])
        self.mqtt.connect(self.mqtt_config['host'], self.mqtt_config['port'])

    def loop(self):
        self.mqtt.loop_forever()

    def on_connect(self, client, userdata, flags, conn_result):
        pass

    def on_message(self, client, userdata, message):
        pass
