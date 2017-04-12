#!/usr/bin/env python

from threading import Thread
import sys
import paho.mqtt.client as paho
from mqtt_base import MQTTBase

class Lantern(MQTTBase):
    def __init__(self, lid, mqtt):
        super(Lantern, self).__init__(mqtt)
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

def main():
    if len(sys.argv) < 2:
        print("Usage: {} ID".format(sys.argv[0]))
        sys.exit(1)

    lid = sys.argv[1]
    config = { 'host': 'localhost', 'port': 1883 }
    lantern = Lantern(lid, config)
    lantern.connect()
    Thread(target=lantern.loop).start()
    while True:
        input('')
        lantern.trigger()

if __name__ == "__main__":
    main()
