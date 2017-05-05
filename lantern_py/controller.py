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
    brightness = 1

    def __init__(self, controller):
        self.controller = controller

    def on_motion(self, lid):
        if len(self.controller.get_lanterns()) == 0:
            print("need to init first")
        elif len(self.controller.get_lanterns()) == 1:
            print("only one known lantern")
            self.controller.send_color(lid, self.get_random_color())
            self.controller.send_trigger(lid)
        elif self.is_first_lantern(lid) or self.is_last_lantern(lid):
            print("first or last lantern")
            if not self.on_interior_motion(lid):
                self.start_trip(lid)
        else:
            print("interior motion")
            if not self.on_interior_motion(lid):
                if len(self.get_trips_for_lantern(lid)) > 0:
                    print("motion at same lantern on trip")
                    self.controller.send_trigger(lid)
                else:
                    self.controller.send_color(lid, '#000000')
                    self.controller.send_trigger(lid)
                    print("motion on unknown trip")

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
        if direction == 1 and self.is_last_lantern(lid):
            return None
        if direction == -1 and self.is_first_lantern(lid):
            return None
        return self.controller.get_lanterns()[position + direction]['lid']

    def get_random_color(self):
        return self.to_hex(colorsys.hsv_to_rgb(self.random.random(), 1, self.brightness))

    def to_hex(self, rgb):
        return '#{:02X}{:02X}{:02X}'.format(int(rgb[0]*255), int(rgb[1]*255), int(rgb[2]*255))

    def from_hex(self, hexrgb):
        return (int(hexrgb[1:3], 16)/255.0, int(hexrgb[3:5], 16)/255.0, int(hexrgb[5:7], 16)/255.0)

    def intermediate_color(self, color1, color2):
        hsv1 = colorsys.rgb_to_hsv(*(self.from_hex(color1)))
        hsv2 = colorsys.rgb_to_hsv(*(self.from_hex(color2)))

        mid_hue = self.mid_hue(hsv1[0] * 360, hsv2[0] * 360) / 360.0

        return self.to_hex(colorsys.hsv_to_rgb(mid_hue, hsv1[1], hsv1[2]))

    def mid_hue(self, hue1, hue2):
        diff = abs(hue1 - hue2)
        if diff > 180:
            hue3 = diff / 2 + min(hue1, hue2)
        else:
            hue3 = ((360 - diff) / 2 + min(hue1, hue2)) % 360

        return hue3

    def start_trip(self, lid):
        color = self.get_random_color()
        direction = 1 if self.is_first_lantern(lid) else -1
        trip = {'start_lid': lid,
                'direction': direction,
                'prev_lid': lid,
                'uuid': uuid.uuid4(),
                'next_lid': self.get_next_lid(lid, direction),
                'color': color}
        self.trips.append(trip)
        self.controller.send_color(lid, color)
        self.controller.send_trigger(lid)
        self.controller.send_trip_begin(trip['uuid'])

    def advance_trip(self, trip):
        trip['prev_lid'] = trip['next_lid']
        trip['next_lid'] = self.get_next_lid(trip['next_lid'], trip['direction'])
        if trip['next_lid'] is None:
            self.controller.send_trip_complete(trip['uuid'])
            print("Trip done!")

    def get_trips_for_lantern(self, lid):
        trips = []
        for trip in self.trips:
            if not trip['next_lid']:
                continue
            if trip['prev_lid'] == lid:
                trips.append(trip)

        return trips

    def get_trips_for_next_motion(self, lid):
        trips = []
        for trip in self.trips:
            if trip['next_lid'] == lid:
                trips.append(trip)

        return trips

    def on_interior_motion(self, lid):
        trips = self.get_trips_for_next_motion(lid)
        if len(trips) == 2 and trips[0]['direction'] != trips[1]['direction']:
            merged_color = self.intermediate_color(trips[0]['color'], trips[1]['color'])
            trips[0]['color'] = merged_color
            trips[1]['color'] = merged_color
            print("two intersecting trips! Setting color to {}".format(merged_color))

        for trip in trips:
            self.controller.send_trip_progress(trip['uuid'], lid)
            self.controller.send_color(lid, trip['color'])
            self.controller.send_trigger(lid)
            self.advance_trip(trip)

        return len(trips)

    def get_trips(self):
        return self.trips

    def get_completed_trips(self):
        completed = 0

        for trip in self.trips:
            if not trip['next_lid']:
                completed += 1

        return completed

    def get_active_trips(self):
        active = 0

        for trip in self.trips:
            if trip['next_lid']:
                active += 1

        return active

    def reset(self):
        self.trips = []
        self.controller.notify_reset()

class Controller(MQTTBase):
    learn_lids = False
    lanterns = []
    def __init__(self, config_file):
        MQTTBase.__init__(self, config_file=config_file)
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
                self.send_color(lid, '#FFFF00')
                self.send_trigger(lid)
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
                self.trip_handler.brightness = int(payload) / 100.0
            elif topic[1] == 'learning':
                if payload == '1':
                    self.init()
                elif payload == '0':
                    self.init_done()
            elif topic[1] == 'reset_trips':
                self.trip_handler.reset()

    def send_color(self, lid, color):
        self.mqtt.publish("lantern/{}/color".format(lid), color, retain=True)

    def send_trigger(self, lid):
        self.mqtt.publish("lantern/{}/trigger".format(lid))

    def send_trip_begin(self, lid):
        self.mqtt.publish('trip/{}/begin'.format(lid))
        self.mqtt.publish('controller/active_trips', self.trip_handler.get_active_trips())

    def send_trip_progress(self, lid, position):
        self.mqtt.publish('trip/{}/progress'.format(lid), position)

    def send_trip_complete(self, lid):
        self.mqtt.publish('trip/{}/complete'.format(lid))
        self.mqtt.publish('controller/completed_trips', self.trip_handler.get_completed_trips())
        self.mqtt.publish('controller/active_trips', self.trip_handler.get_active_trips())

    def notify_reset(self):
        self.mqtt.publish('controller/completed_trips', self.trip_handler.get_completed_trips())
        self.mqtt.publish('controller/active_trips', self.trip_handler.get_active_trips())

    def loop(self):
        self.mqtt.loop_forever()

    def disconnect(self):
        self.mqtt.disconnect()

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
    if len(sys.argv) < 2:
        print("Usage: {} config.json".format(sys.argv[0]))
        sys.exit(1)

    controller = Controller(config_file=sys.argv[1])
    controller.connect()
    controller_thread = Thread(target=controller.loop)
    controller_thread.start()
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
        elif i == 'exit' or i == 'quit':
            controller.disconnect()
            sys.exit(0)
        else:
            print("Unknown command")

if __name__ == "__main__":
    main()
