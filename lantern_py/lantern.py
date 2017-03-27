#!/usr/bin/env python

import json
import paho.mqtt.client as paho
from threading import Thread
import random
import sys

class Lantern():
    def __init__(self, id, mqtt):
        self.mqtt_config = mqtt
        self.mqtt = paho.Client()
        self.mqtt.on_connect = self.on_connect
        self.mqtt.on_message = self.on_message
        self.id = id
        self.topic = self.mqtt_config['topic']
    def connect(self):
        print("Connecting to {host}:{port}...".format(**self.mqtt_config))
        self.mqtt.connect(self.mqtt_config['host'], self.mqtt_config['port'])
    def on_connect(self, client, userdata, flags, rc):
        self.mqtt.subscribe("{}/{}/#".format(self.topic, self.id))
        print("Connected")
    def set_color(self, color):
        print("Set my color to {}".format(color))
    def on_message(self, client, userdata, message):
        parts=message.topic.split('/')
        if not parts[0] == self.topic:
            return
        if parts[-1] == 'color':
            self.set_color(message.payload.decode('utf-8'))
        elif parts[-1] == 'motion':
            # self-motion
            pass
        else:
            print("Unhandled message: {m.topic} {m.payload}".format(m=message, u=userdata))

    def loop(self):
        self.mqtt.loop_forever()
    def trigger(self):
        self.mqtt.publish("{}/{}/motion".format(self.topic, self.id), self.id)

def main():
    if len(sys.argv) < 2:
        print("Usage: {} ID".format(sys.argv[0]))
        sys.exit(1)

    id = sys.argv[1]
    config={'host': 'localhost', 'port': 1883, 'topic': 'lantern'}
    l=Lantern(id, config)
    l.connect()
    Thread(target=l.loop).start()
    while True:
        i=input('')
        l.trigger()

if __name__ == "__main__":
    main()
