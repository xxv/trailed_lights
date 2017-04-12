#!/usr/bin/env python

from threading import Thread
import json
import sys
import paho.mqtt.client as paho
from mqtt_base import MQTTBase

class Lantern(MQTTBase):
    def __init__(self, lid, mqtt):
        MQTTBase.__init__(self, mqtt)
        self.lid = lid
    def on_connect(self, client, userdata, flags, conn_result):
        self.mqtt.subscribe("lantern/{}/#".format(self.lid))
        print("Connected")
    def set_color(self, color):
        print("Set my color to {}".format(color))
    def on_message(self, client, userdata, message):
        parts = message.topic.split('/')
        if not parts[0] == 'lantern':
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
        self.mqtt.publish("lantern/{}/motion".format(self.lid), self.lid)

def get_input():
    if sys.version_info[0] >= 3:
        i = input('')
    else:
        i = raw_input('')

def main():
    if len(sys.argv) < 3:
        print("Usage: {} config.json ID".format(sys.argv[0]))
        sys.exit(1)

    config_file_name = sys.argv[1]
    lid = sys.argv[2]
    config = None
    with open(config_file_name) as config_file:
        config = json.load(config_file)
    lantern = Lantern(lid, config)
    lantern.connect()
    Thread(target=lantern.loop).start()
    while True:
        get_input()
        lantern.trigger()

if __name__ == "__main__":
    main()
