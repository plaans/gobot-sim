import socket
import sys

import math

import socket
import sys

import json
import time
import random
import numpy

import pprint

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('localhost', 10000)
sock.connect(server_address)

environment = None
	
def send_command(command_info):
	#command_info is the list containing the command name and the arguments, for example ['navigate_to', 505, 400]
	
	message = json.dumps({'timestamp' : time.time(), 'robot_command': command_info})
	length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
	sock.sendall(length + bytes(message,encoding="utf-8"))
	
	#waiting_for_command_to_be_processed = True
	print(command_info)
	
	return	
	
def distance(position, destination):
	return math.sqrt((position[0]-destination[0])**2 + (position[1]-destination[1])**2)
					
def angle(position, destination):
	vector_x = destination[0] - position[0]
	vector_y = destination[1] - position[1]
	angle = (numpy.angle(vector_x + vector_y * 1j)) % (2*math.pi)
	if angle > math.pi:
		angle -= 2*math.pi
	
	return angle

def position(package):
	#finds the position of a package by finding its parent
	if package["location_type"] == "arrival":
		return environment["arrival_area"]["center"]
	else:
		destination_id = package["location_id"]
		for machine in environment["machines"]:
			if destination_id == machine["id"]:
				return  machine["output_area"]["center"]

try:

	#message = json.dumps({'timestamp' : time.time(), 'robot_command': ['navigate_to', 505, 400]})
	
	#message = json.dumps({'timestamp' : time.time(), 'robot_command': ['pickup', '0']})
	#length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
	#sock.sendall(length + bytes(message,encoding="utf-8"))
	



	#first save environment
	
	
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

				
				
				# robot = state["robots"][0]
				# if robot["battery"]>0 and not(robot["is_moving"]):
					# if not(robot["in_station"]):
						# #case where the robot is not currently charging so go back if battery too low and else go to random location
						# if robot["battery"]<=0.4:
							# parking_areas = environment["parking_areas"][:1]
							# area = random.sample(parking_areas, k=1)[0]
							# destination = area["polygon"]["center"]
							# send_command(["navigate_to",robot["id"],destination[0],destination[1]])
						# else:
							# dest_x = random.randrange(100, 500)
							# dest_y = random.randrange(100, 500)
							# send_command(["navigate_to",robot["id"],dest_x,dest_y])
					# else:
						# #case where the robot is currently charging so stay until battery goes overs 0.9 and after that go to a random location
						# if robot["battery"]>=0.9:
							# dest_x = random.randrange(100, 500)
							# dest_y = random.randrange(100, 500)
							# send_command(["navigate_to",robot["id"],dest_x,dest_y])
				
				# delivery = environment["delivery_area"]
				
				for robot in state["robots"]:
				
					if robot["battery"]>0 and not(robot["is_moving"]):
					
						if not(robot["in_station"]) and robot["battery"]<=0.4:
							#case where the robot is not currently charging so go back if battery too low and else go to random location
						
							parking_areas = environment["parking_areas"][:1]
							area = random.sample(parking_areas, k=1)[0]
							destination = area["polygon"]["center"]
							send_command(["navigate_to",robot["id"],destination[0],destination[1]])
							
						elif not(robot["in_station"]) or robot["battery"]>=0.9:
					
							package_id = robot["carried"]
							carried_package = None
							
							if package_id!=-1:
								#then robot is carrying a package, need to find it in package list and see where it needs to be delivered
								
								for package in state["packages"]:
									if package["id"] == package_id:
										carried_package = package
										break
										
							if carried_package != None:
								destination = None
								
								list_processes = package["processes"]
								if len(list_processes) == 0:
									destination = environment["delivery_area"]["center"]
								else:
									next_process_id = list_processes[0]["id"]
									possible_machines=[]
									for machine in environment["machines"]:
										if next_process_id in machine["processes_list"]:
											if distance(robot["position"],machine["input_area"]["center"])<40:
												#machine already close enough so directly chose it as destination
												destination = machine["input_area"]["center"]
											else:
												possible_machines.append(machine)
									
									if destination == None and len(possible_machines)>0:
										chosed_machine = random.sample(possible_machines,1)[0]
										destination = chosed_machine["input_area"]["center"]
								
								if destination != None:
									if distance(robot["position"],destination) >=40:
										send_command(["navigate_to",robot["id"]]+destination)
									elif not(robot["is_rotating"]):
										#already close enough, check if right angle or not
										rotation = robot["rotation"]
										target_rotation = angle(robot["position"],destination)
										if abs(target_rotation-rotation)<=0.1:
											send_command(["pickup",robot["id"]])
										else:
											send_command(["do_rotation",robot["id"],target_rotation - rotation, 1.5])
							else:
								#then robot is not carrying a package so check if there is one to go get
								destination = None
								
								possible_packages = []
								for package in state["packages"]:
									if package["location_type"] in ["machine_output","arrival"]:
										if distance(robot["position"],position(package))<100:
											#package already close enough so directly chose it as destination
											destination = position(package)
										else:
											possible_packages.append(package)
										
								if destination == None and len(possible_packages)>0:
									chosed_package = random.sample(possible_packages,1)[0]
									destination = position(chosed_package)
											
								if destination != None:
									if distance(robot["position"],destination) >=100:
										send_command(["navigate_to",robot["id"]]+destination)
									elif not(robot["is_rotating"]):
										#already close enough, check if right angle or not
										rotation = robot["rotation"]
										target_rotation = angle(robot["position"],destination)
										if abs(target_rotation-rotation)<=0.1:
											send_command(["pickup",robot["id"]])
										else:
											send_command(["do_rotation",robot["id"],target_rotation - rotation, 1.5])
					
														
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
	


