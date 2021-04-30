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

	#message = json.dumps({'timestamp' : time.time(), 'robot_command': ['navigate_to', 505, 400]})
	
	#message = json.dumps({'timestamp' : time.time(), 'robot_command': ['pickup', '0']})
	#length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
	#sock.sendall(length + bytes(message,encoding="utf-8"))
	



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
				
				delivery = environment["delivery_area"]
				
				# for robot in state["robots"]:
					# if not(robot["is_moving"]):
						# package = robot["carried"]
						# list_processes = package["processes"]
						# send_command(['navigate_to', 505, 400])
					# else:
						# package_to_get = None
						# for package in state["packages"]:
							# if package["location_type"]!="robot":
								# package_to_get = package
								# processes_to_do = package["processes"]
								# if len(processes_to_do)>0:
									# next_process_id = processes_to_do[0][0]
								
	# 		# if destination_stand == None:
	# 			# #then we will fix the destination_stand to the farthest stand 
	# 			# stands_x = state.stands_x
	# 			# stands_y = state.stands_y
	# 			# dist_max=0
	# 			# pos_x = state.robots_x[0]
	# 			# pos_y = state.robots_y[0]
	# 			# for k in range(len(stands_x)):
	# 				# x = stands_x[k]
	# 				# y = stands_y[k]
	# 				# dist = (x-pos_x)**2 + (y-pos_y)**2
	# 				# if dist >= dist_max:
	# 					# dist_max = dist
	# 					# destination_stand = k #index of corresponding stand
						
	# 		for k in range(2):
	# 		#for now we will try a program making each robot take care of a corresponding package
	# 			package = state.packages[k]
	# 			robot = state.robots[k]					
							
	# 			if not(robot.is_moving):
	# 				#send a command only if robot not already moving
					
	# 				possible_types = messages_pb2.State.Location.Location_Type
					
	# 				if package.location.location_type == possible_types.Value('ARRIVAL') or package.location.location_type == possible_types.Value('MACHINE_OUTPUT'):
						
	# 					#case where the package is on an output stand so needs to be picked up
	# 					if package.location_id != destination_stand:
	# 						pos_x = robot.x
	# 						pos_y = robot.y
							
	# 						#then need to get coordinates of stand where package is located, will depend on if arrival zone or machine output
	# 						stand_x = 0
	# 						stand_y = 0
	# 						if package.location.location_type == possible_types.Value('ARRIVAL'):
	# 							area = environment.arrival_area
	# 							stand_x = area.x
	# 							stand_y = area.y
	# 						else:
	# 							machine_id = package.location.parent_id
	# 							machine = environment.machines[machine_id]
	# 							area = machine.output_area
	# 							stand_x = area.x
	# 							stand_y = area.y
							
							
	# 						distance = (stand_x-pos_x)**2 + (stand_y-pos_y)**2
	# 						print(distance)
							
	# 						if distance > 100**2: #compare to pickup radius, will need to take the right value later

	# 							goto_path_stand(stand_x,stand_y)
								
	# 						else:
	# 							#already close enough so send pickup command
	# 							Command = messages_pb2.Command()
	# 							Command.command = messages_pb2.Command.Command_types.Value('PICKUP')
	# 							#pas besoin de specifier d'autres parametres pour une commande de type pickup
	# 							message = Command.SerializeToString()

	# 							length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
	# 							sock.sendall(length + message)
		
	# 				elif package.location.location_type == possible_types.Value('ROBOT'):
	# 					#case where the robot already picked up the package so needs to deliver it to the objective
	# 					pos_x = state.robots_x[0]
	# 					pos_y = state.robots_y[0]
	# 					stand_x = state.stands_x[destination_stand]
	# 					stand_y = state.stands_y[destination_stand]
	# 					distance = (stand_x-pos_x)**2 + (stand_y-pos_y)**2
						
	# 					if distance > 100**2: #compare to pickup radius, will need to take the right value later
								
	# 						direction_x = stand_x - pos_x
	# 						direction_y = stand_y - pos_y
	# 						goto_stand(direction_x,direction_y)
							
	# 					else:
	# 						#already close enough so send pickup command (this time it will have the effect to drop and not pick up)
	# 						Command = messages_pb2.Command()
	# 						Command.command = messages_pb2.Command.Command_types.Value('PICKUP')
	# 						#pas besoin de specifier d'autres parametres pour une commande de type pickup
	# 						message = Command.SerializeToString()

	# 						length = len(message).to_bytes(4,'little') #4bytes because sending as int32	 
	# 						sock.sendall(length + message)

finally:
	print('closing socket')
	sock.close()
	


