import socket
import sys

import math

import socket
import sys

import json
import time
import random

import pprint

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('localhost', 10000)
sock.connect(server_address)
	
def send_command(command_info):
	#command_info is the list containing the command name and the arguments, for example ['navigate_to', 505, 400]
	
	message = json.dumps({'timestamp' : time.time(), 'robot_command': command_info})
	length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
	sock.sendall(length + bytes(message,encoding="utf-8"))
	
	#waiting_for_command_to_be_processed = True
	print(command_info)
	
	return	
	

try:

	#first save environment
	
	environment = None
	length = 0
	while length == 0:
		data = sock.recv(4)#because int32
		length = len(data)
		if len(data)>0:
			size = int.from_bytes(data,'little')
			data = sock.recv(size)
			environment = json.loads(data)
			pprint.pprint(environment) 
			
			liste_machines = environment["machines"]
			
			
	waiting_for_command_to_be_processed = False
	
	while True:
		data = sock.recv(4)
		if len(data)>0:
			size = int.from_bytes(data,'little')
			data = sock.recv(size)
			state = json.loads(data)
			
			pprint.pprint(state) 
			
			if waiting_for_command_to_be_processed:
				if state["command_processed"] == True:
					waiting_for_command_to_be_processed = False
			else:

				
				
				robot = state["robots"][0]
				if robot["battery"]>0 and not(robot["is_moving"]):
					if not(robot["in_station"]):
						#case where the robot is not currently charging so go back if battery too low and else go to random location
						if robot["battery"]<=0.4:
							parking_areas = environment["parking_areas"][:1]
							area = random.sample(parking_areas, k=1)[0]
							destination = area["polygon"]["center"]
							send_command(["navigate_to",robot["id"],destination[0],destination[1]])
						else:
							dest_x = random.randrange(100, 500)
							dest_y = random.randrange(100, 500)
							send_command(["navigate_to",robot["id"],dest_x,dest_y])
					else:
						#case where the robot is currently charging so stay until battery goes overs 0.9 and after that go to a random location
						if robot["battery"]>=0.9:
							dest_x = random.randrange(100, 500)
							dest_y = random.randrange(100, 500)
							send_command(["navigate_to",robot["id"],dest_x,dest_y])
				

finally:
	print('closing socket')
	sock.close()
	

