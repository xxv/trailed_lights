#!/usr/bin/env python

import json
import paho.mqtt.client as paho
from threading import Thread
import random

class Lantern():
    def __init__(self, mqtt):
        self.mqtt_config = mqtt
        self.mqtt = paho.Client()
        self.mqtt.on_connect = self.on_connect
        self.mqtt.on_message = self.on_message
        self.id = str(random.Random().randint(0, 1000000))
        self.topic = self.mqtt_config['topic']
    def connect(self):
        print("Connecting to {host}:{port}...".format(**self.mqtt_config))
        self.mqtt.connect(self.mqtt_config['host'], self.mqtt_config['port'])
    def on_connect(self, client, userdata, flags, rc):
        #self.mqtt.subscribe(self.topic + '/#')
        self.mqtt.subscribe("{}/{}/#".format(self.topic, self.id))
        print("Connected")
    def on_message(self, client, userdata, message):
        parts=message.topic.split('/')
        if not parts[0] == self.topic:
            return
        if parts[-1] == 'color':
            print("Color of {}: {}".format(parts[1], message.payload))
        else:
            print("{m.topic} {m.payload}".format(m=message, u=userdata))

    def loop(self):
        self.mqtt.loop_forever()
    def trigger(self):
        self.mqtt.publish(self.mqtt_config['topic'] + '/motion', self.id)

def main():
    config={'host': 'localhost', 'port': 1883, 'topic': 'lantern'}
    l=Lantern(config)
    l.connect()
    Thread(target=l.loop).start()
    while True:
        i=input('')
        l.trigger()



if __name__ == "__main__":
    main()
