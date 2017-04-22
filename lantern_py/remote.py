#!/usr/bin/env python

from threading import Thread
import sys

from mqtt_base import MQTTBase

V3 = sys.version_info[0] >= 3

class Remote(MQTTBase):
    def __init__(self, config_file):
        MQTTBase.__init__(self, config_file=config_file)

    def on_connect(self, client, userdata, flags, rc):
        self.mqtt.subscribe('controller/#')
        self.mqtt.subscribe('trip/#')
        print("Connected")

    def on_message(self, client, userdata, message):
        print('{} {}'.format(message.topic, message.payload.decode('utf-8')))

    def init(self):
        self.mqtt.publish('controller/init')

    def init_done(self):
        self.mqtt.publish('controller/done')

    def reset(self):
        self.mqtt.publish('controller/reset_trips')

    def brightness(self, brightness):
        self.mqtt.publish('controller/brightness', brightness)

def main():
    if len(sys.argv) != 2:
        print("usage: {} config_file.json".format(sys.argv[0]))
        sys.exit(1)
    remote = Remote(config_file=sys.argv[1])
    remote.connect()
    Thread(target=remote.loop).start()
    while True:
        if V3:
            i = input('Lanterns> ').split()
        else:
            i = raw_input('Lanterns> ').split()
        cmd = i[0]
        if cmd == 'init':
            remote.init()
        elif cmd == 'done':
            remote.init_done()
        elif cmd == 'reset':
            remote.reset()
        elif cmd == 'brightness':
            remote.brightness(int(i[1]))
        elif cmd == 'quit' or cmd == 'exit':
            remote.disconnect()
        else:
            print("Unknown command")

if __name__ == "__main__":
    main()
