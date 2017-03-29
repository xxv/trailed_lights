#!/usr/bin/env python

import json
import paho.mqtt.client as paho
from threading import Thread
import random
import uuid
import sys

v3=sys.version_info[0] >= 3

class Controller():
    def __init__(self, mqtt):
        self.mqtt_config = mqtt
        self.mqtt = paho.Client()
        self.mqtt.on_connect = self.on_connect
        self.mqtt.on_message = self.on_message
        self.topic = self.mqtt_config['topic']

    def connect(self):
        print("Connecting to {host}:{port}...".format(**self.mqtt_config))
        self.mqtt.connect(self.mqtt_config['host'], self.mqtt_config['port'])

    def on_connect(self, client, userdata, flags, rc):
        self.mqtt.subscribe('controller/#')
        self.mqtt.subscribe('trip/#')
        print("Connected")

    def on_message(self, client, userdata, message):
        print('{} {}'.format(message.topic, message.payload.decode('utf-8')))

    def loop(self):
        self.mqtt.loop_forever()

    def init(self):
        self.mqtt.publish('controller/init')

    def init_done(self):
        self.mqtt.publish('controller/done')

def main():
    config={'host': '192.168.1.132', 'port': 1883, 'topic': 'lantern'}
    controller=Controller(config)
    controller.connect()
    Thread(target=controller.loop).start()
    while True:
        if v3:
            i=input('Lanterns> ')
        else:
            i=raw_input('Lanterns> ')
        if i == 'init':
            controller.init()
        elif i == 'done':
            controller.init_done()

if __name__ == "__main__":
    main()
