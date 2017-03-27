#!/usr/bin/env python

import json
import paho.mqtt.client as paho
from threading import Thread
import random

class TripHandler():
    trips=[]
    random = random.Random()
    def __init__(self, lanterns, controller):
        self.lanterns = lanterns
        self.controller = controller

    def on_motion(self, id):
        if len(self.lanterns) == 0:
            print("need to init first")
        elif len(self.lanterns) == 1:
            print("only one known lantern")
        elif self.is_first_lantern(id) or self.is_last_lantern(id):
            if not self.on_interior_motion(id):
                self.start_trip(id)
        else:
            self.on_interior_motion(id)

    def is_first_lantern(self, id):
        return self.lanterns[0]['id'] == id 

    def is_last_lantern(self, id):
        return self.lanterns[-1]['id'] == id

    def get_position(self, id):
        for i, lantern in enumerate(self.lanterns):
            if lantern['id'] == id:
                return i
        return None

    def get_next_id(self, id, direction):
        position = self.get_position(id)
        if direction == 1 and position == len(self.lanterns) - 1:
            return None
        elif direction == -1 and position  == 0:
            return None
        return self.lanterns[position + direction]['id']

    def start_trip(self, id):
        color = self.random.randint(0, 16)
        direction = 1 if self.is_first_lantern(id) else -1
        trip = { 'start_id': id,
                 'direction': direction, 
                 'last_id': id, 
                 'next_id': self.get_next_id(id, direction), 
                 'color': color }
        self.trips.append(trip)
        self.controller.send_color(id, color)

    def advance_trip(self, trip):
        trip['next_id'] = self.get_next_id(trip['next_id'], trip['direction'])
        if trip['next_id'] is None:
            print("Trip done!")

    def on_interior_motion(self, id):
        for trip in self.trips:
            if trip['next_id'] == id:
                self.controller.send_color(id, trip['color'])
                self.advance_trip(trip)
                return True
        return None
    def get_trips(self):
        return self.trips

class Controller():
    lanterns=[]
    learn_ids=False
    def __init__(self, mqtt):
        self.mqtt_config = mqtt
        self.mqtt = paho.Client()
        self.mqtt.on_connect = self.on_connect
        self.mqtt.on_message = self.on_message
        self.topic = self.mqtt_config['topic']
        self.trip_handler=TripHandler(self.lanterns, self)
        
    def connect(self):
        print("Connecting to {host}:{port}...".format(**self.mqtt_config))
        self.mqtt.connect(self.mqtt_config['host'], self.mqtt_config['port'])
    def on_connect(self, client, userdata, flags, rc):
        self.mqtt.subscribe(self.mqtt_config['topic'] + '/#')
        print("Connected")
    def on_message(self, client, userdata, message):
        parts=message.topic.split('/')
        if not parts[0] == self.topic:
            return
        if parts[-1] == 'motion':
            id = message.payload.decode('utf-8')
            if self.learn_ids:
                self.lanterns.append({'id': id})
                print("Learned lantern {}".format(id))
            else:
                self.trip_handler.on_motion(id)
    def send_color(self, id, color):
        self.mqtt.publish("{}/{}/color".format(self.topic, id), color, retain=True)
    def loop(self):
        self.mqtt.loop_forever()
    def init(self):
        self.lanterns.clear()
        self.learn_ids = True
    def init_done(self):
        self.learn_ids = False
    def get_lanterns(self):
        return self.lanterns

def main():
    config={'host': 'localhost', 'port': 1883, 'topic': 'lantern'}
    controller=Controller(config)
    controller.connect()
    Thread(target=controller.loop).start()
    while True:
        i=input('Lanterns> ')
        if i == 'init':
            controller.init()
        elif i == 'initdone':
            controller.init_done()
        elif i == 'list':
            for lantern in controller.get_lanterns():
                print(lantern)
        elif i == 'trips':
            for trip in controller.trip_handler.get_trips():
                print(trip)

if __name__ == "__main__":
    main()
