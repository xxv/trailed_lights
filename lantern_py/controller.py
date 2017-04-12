#!/usr/bin/env python3

import colorsys
import json
from threading import Thread
from random import Random
import uuid
import sys
import paho.mqtt.client as paho
from mqtt_base import MQTTBase

V3 = sys.version_info[0] >= 3

class TripHandler():
    trips = []
    random = Random()
    brightness = 0.1

    def __init__(self, controller):
        self.controller = controller

    def on_motion(self, lid):
        if len(self.controller.get_lanterns()) == 0:
            print("need to init first")
        elif len(self.controller.get_lanterns()) == 1:
            print("only one known lantern")
        elif len(self.get_trips_for_lantern(lid)) > 0:
            print("motion at same lantern on trip")
        elif self.is_first_lantern(lid) or self.is_last_lantern(lid):
            if not self.on_interior_motion(lid):
                self.start_trip(lid)
        else:
            self.on_interior_motion(lid)

    def is_first_lantern(self, lid):
        return self.controller.get_lanterns()[0]['lid'] == lid

    def is_last_lantern(self, lid):
        return self.controller.get_lanterns()[-1]['lid'] == lid

    def get_position(self, lid):
        for i, lantern in enumerate(self.controller.get_lanterns()):
            if lantern['lid'] == lid:
                return i
        return None

    def get_next_lid(self, lid, direction):
        position = self.get_position(lid)
        if direction == 1 and position == len(self.controller.get_lanterns()) - 1:
            return None
        elif direction == -1 and position == 0:
            return None
        return self.controller.get_lanterns()[position + direction]['lid']

    def get_random_color(self):
        (r, g, b) = colorsys.hsv_to_rgb(self.random.random(), 1, self.brightness)
        return '#{:02X}{:02X}{:02X}'.format(int(r*255), int(g*255), int(b*255))

    def start_trip(self, lid):
        color = self.get_random_color()
        direction = 1 if self.is_first_lantern(lid) else -1
        trip = {'start_lid': lid,
                'direction': direction,
                'last_lid': lid,
                'uuid': uuid.uuid4(),
                'next_lid': self.get_next_lid(lid, direction),
                'color': color}
        self.trips.append(trip)
        self.controller.send_color(lid, color)
        self.controller.send_trip_begin(trip['uuid'])

    def advance_trip(self, trip):
        trip['next_lid'] = self.get_next_lid(trip['next_lid'], trip['direction'])
        if trip['next_lid'] is None:
            self.controller.send_trip_complete(trip['uuid'])
            print("Trip done!")

    def get_trips_for_lantern(self, lid):
        trips = []
        for trip in self.trips:
            if trip['last_lid'] == lid:
                trips.append(trip)

        return trips

    def on_interior_motion(self, lid):
        for trip in self.trips:
            if trip['next_lid'] == lid:
                self.controller.send_trip_progress(trip['uuid'], lid)
                self.controller.send_color(lid, trip['color'])
                self.advance_trip(trip)
                return True
        return None
    def get_trips(self):
        return self.trips

class Controller(MQTTBase):
    learn_lids = False
    lanterns = []
    def __init__(self, mqtt):
        super(Controller, self).__init__(mqtt)
        self.trip_handler = TripHandler(self)

    def on_connect(self, client, userdata, flags, conn_result):
        self.mqtt.subscribe('lantern/#')
        self.mqtt.subscribe('controller/#')
        self.mqtt.publish('controller/status', 'uninitialized', retain=True)
        print("Connected")

    def on_message(self, client, userdata, message):
        parts = message.topic.split('/')
        if parts[0] == 'controller':
            return self.on_controller_message(client, userdata, message, parts)
        if not parts[0] == 'lantern':
            return
        if parts[-1] == 'motion':
            lid = parts[1]
            if self.learn_lids:
                self.lanterns.append({'lid': lid})
                print("Learned lantern {}".format(lid))
                self.mqtt.publish('controller/added', '{}'.format(lid))
            else:
                self.trip_handler.on_motion(lid)

    def on_controller_message(self, client, userdata, message, topic):
        if len(topic) > 1:
            payload = message.payload.decode('utf-8')
            if topic[1] == 'init':
                self.init()
            elif topic[1] == 'done':
                self.init_done()
            elif topic[1] == 'brightness':
                self.trip_handler.brightness = int(payload) / 100
            elif topic[1] == 'learning':
                if payload == '1':
                    self.init()
                elif payload == '0':
                    self.init_done()

    def send_color(self, lid, color):
        self.mqtt.publish("lantern/{}/color".format(lid), color, retain=True)

    def send_trip_begin(self, lid):
        self.mqtt.publish('trip/{}/begin'.format(lid))

    def send_trip_progress(self, lid, position):
        self.mqtt.publish('trip/{}/progress'.format(lid), position)

    def send_trip_complete(self, lid):
        self.mqtt.publish('trip/{}/complete'.format(lid))

    def loop(self):
        self.mqtt.loop_forever()

    def init(self):
        self.lanterns = []
        self.learn_lids = True
        self.mqtt.publish('controller/status', 'learning', retain=True)

    def init_done(self):
        self.learn_lids = False
        self.mqtt.publish('controller/status', 'ready', retain=True)
        self.mqtt.publish('controller/lanterns', json.dumps(self.lanterns))

    def get_lanterns(self):
        return self.lanterns

def main():
    config = {'host': 'localhost', 'port': 1883}
    controller = Controller(config)
    controller.connect()
    Thread(target=controller.loop).start()
    while True:
        if V3:
            i = input('Lanterns> ')
        else:
            i = raw_input('Lanterns> ')
        if i == 'init':
            controller.init()
        elif i == 'done':
            controller.init_done()
        elif i == 'list':
            for lantern in controller.get_lanterns():
                print(lantern)
        elif i == 'trips':
            for trip in controller.trip_handler.get_trips():
                print(trip)

if __name__ == "__main__":
    main()
