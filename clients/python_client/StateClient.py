import pprint
from typing import Dict, List
import threading 


class StateClient():
	def __init__(self):
		self.state = {}
		self.names_list_by_category = {}

		self.waited_conditions = []
		self.callback_package_ready = None

		self.wait_dynamic_update_event = threading.Event()

	def update(self, message : Dict):
		# if message['type']=='static':
		# 	pprint.pprint( message['data'])
		if message['type']=='dynamic':
			self.wait_dynamic_update_event.set()
		data = message['data']
		for line in data:
			attribute: str = line[0]
			if "Globals" in attribute:
				attribute=attribute.replace("Globals.", "")
				if "Globals" not in self.state:
					self.state["Globals"] = {}
				self.state["Globals"][attribute] = line[1]
			else:
				name = line[1]
				value = line[2]

				if ".instance" in attribute:#declaration of instance
					if name not in self.state:
						self.state[name] = {}
					self.state[name]['type'] = attribute

					if attribute not in self.names_list_by_category :
						self.names_list_by_category[attribute] =[]
					self.names_list_by_category[attribute].append(name)

				
				if name not in self.state:
					self.state[name] = {}

				if self.callback_package_ready!=None:
					#check if a package became ready
					if attribute == "Package.location" and attribute in self.state[name]:
						previous_value = self.state[name][attribute]
						#new_value_is_output_belt = 'Belt.belt_type' in self.state[value] and self.state[value]['Belt.belt_type'] == "output"

						new_value_is_output_belt = (self.belt_type(value) == "output") #will return None if not a belt

						previous_value = self.package_location(name) #will return None if does not exist

						if new_value_is_output_belt and value != previous_value:
							#if package is on a output_belt and was at a different location previously it has become ready
							self.callback_package_ready(name)


				self.state[name][attribute] = value

		self.check_conditions()


		# pprint.pprint(self.state)
	

	def check_conditions(self):
		k = 0
		while k < len(self.waited_conditions):
			condition = self.waited_conditions[k]
			condition_function, event, _=condition
			try:
				if condition_function(self.state):
					condition[2] = True
					event.set()
					self.waited_conditions.remove(condition)
				else:
					k+=1
			except:
				print( "Exception raised while checking for a condition")
				condition[2] = False
				event.set()
				self.waited_conditions.remove(condition)


	def get_data(self, key : str, name : str):
		if name in self.state and key in self.state[name]:
			return self.state[name][key]


	def wait_condition(self, condition_function, timeout = 60):
		#condition_function must be a function which takes as argument a dictionary (reprenting the state)
		#and outputs a boolean, with the wait ending when the function returns True 
		wait_event = threading.Event()
		condition = [condition_function, wait_event, True]
		self.waited_conditions.append(condition)
		
		if wait_event.wait(timeout):
			result = condition[2]
			return result
		else:
			print( "Timeout while waiting for a condition")
			return False
		
	def wait_next_dynamic_update(self, timeout = 60):
		#waits until the StateClient receives a message containing token 
		#for example to wait until a robot instance is declared token would be Robot.instance
		self.wait_dynamic_update_event.clear()
		return self.wait_dynamic_update_event.wait(timeout)

	def set_callback_package_ready(self, callback_function):
		self.callback_package_ready = callback_function

	# getter functions, that access the state and return some information

	def globals_robot_default_battery_capacity(self) -> float:
		return self.get_data("robot_default_battery_capacity", "Globals")

	def globals_robot_battery_charge_rate(self) -> float:
		return self.get_data("robot_battery_charge_rate", "Globals")
	
	def globals_robot_battery_drain_rate(self) -> float:
		return self.get_data("robot_battery_drain_rate", "Globals")
	
	def globals_robot_battery_drain_rate_idle(self) -> float:
		return self.get_data("robot_battery_drain_rate_idle", "Globals")
	
	def globals_robot_standard_speed(self) -> float:
		return self.get_data("robot_standard_speed", "Globals")

	
	def robot_recharge_rate(self, name: str) -> float:
		return self.get_data("Robot.charge_rate", name)
	
	def robot_drain_rate(self, name: str) -> float:
		return self.get_data("Robot.drain_rate", name)
	
	def robot_standard_speed(self, name: str) -> float:
		return self.get_data("Robot.standard_speed", name)

	def robot_coordinates(self, name : str) -> List[float]:
		return self.get_data("Robot.coordinates",name)

	def robot_coordinates_tile(self, name : str) -> List[int]:
		return self.get_data("Robot.coordinates_tile",name)

	def robot_rotation(self, robot_name : str) -> float:
		return self.get_data("Robot.rotation",robot_name)

	def robot_battery(self, robot_name : str) -> float:
		return self.get_data("Robot.battery",robot_name)

	def robot_velocity(self, robot_name : str) -> List[float]:
		return self.get_data("Robot.velocity",robot_name)

	def robot_rotation_speed(self, robot_name : str) -> float:
		return self.get_data("Robot.rotation_speed",robot_name)

	def robot_in_station(self, robot_name : str) -> bool:
		return self.get_data("Robot.in_station",robot_name)

	def robot_in_interact_areas(self, robot_name : str) -> List[str]:
		return self.get_data("Robot.in_interact_areas",robot_name)
	
	def robot_closest_area(self, robot_name: str) -> str:
		return self.get_data("Robot.closest_area", robot_name)


	def robot_location(self, robot_name: str) -> str:
		return self.get_data("Robot.location", robot_name)

	def machine_coordinates(self, name : str) -> List[float]:
		return self.get_data("Machine.coordinates",name)

	def machine_coordinates_tile(self, name : str) -> List[int]:
		return self.get_data("Machine.coordinates_tile",name)

	def machine_input_belt(self, machine_name : str) -> str:
		return self.get_data("Machine.input_belt",machine_name)

	def machine_output_belt(self, machine_name : str) -> str:
		return self.get_data("Machine.output_belt",machine_name)

	def machine_processes_list(self, machine_name : str) -> List[int]:
		return self.get_data("Machine.processes_list", machine_name)

	def machine_type(self, machine_name : str) -> str:
		return self.get_data("Machine.type", machine_name)

	def machine_progress_rate(self, machine_name : str) -> float:
		return self.get_data("Machine.progress_rate", machine_name)


	def package_location(self, package_name : str) -> str:
		return self.get_data("Package.location",package_name)
	
	def package_all_processes(self, package_name: str) -> str:
		return self.get_data("Package.all_processes", package_name)

	def package_processes_list(self, package_name : str) -> List:
		return self.get_data("Package.processes_list", package_name)



	def belt_type(self, belt_name : str) -> str:
		return self.get_data("Belt.belt_type",belt_name)

	def belt_polygons(self, belt_name : str) -> List:
		return self.get_data("Belt.polygons",belt_name)

	def belt_cells(self, belt_name : str) -> List[int]:
		return self.get_data("Belt.cells",belt_name)

	def belt_interact_areas(self, belt_name : str) -> List[str]:
		return self.get_data("Belt.interact_areas",belt_name)

	def belt_packages_list(self, belt_name : str) -> List[str]:
		return self.get_data("Belt.packages_list",belt_name)

	def parking_area_polygons(self, parking_area_name : str) -> List:
		return self.get_data("Parking_area.polygons",parking_area_name)

	def parking_area_cells(self, parking_area_name : str) -> List:
		return self.get_data("Parking_area.cells",parking_area_name)



	def interact_area_polygons(self, interact_area_name : str) -> List:
		return self.get_data("Interact_area.polygons",interact_area_name)

	def interact_area_cells(self, interact_area_name : str) -> List:
		return self.get_data("Interact_area.cells",interact_area_name)

	def interact_area_belt(self, interact_area_name : str) -> str:
		return self.get_data("Interact_area.belt",interact_area_name)



	def get_instances_list(self, category_name : str):
		if category_name in self.names_list_by_category:
			return self.names_list_by_category[category_name]	

	def robots_list(self) -> List[str]:
		return self.get_instances_list("Robot.instance")

	def machines_list(self) -> List[str]:
		return self.get_instances_list("Machine.instance")

	def packages_list(self) -> List[str]:
		return self.get_instances_list("Package.instance")
	
	def belts_list(self) -> List[str]:
		return self.get_instances_list("Belt.instance")
	
	def parking_areas_list(self) -> List[str]:
		return self.get_instances_list("Parking_area.instance")
	
	def interact_areas_list(self) -> List[str]:
		return self.get_instances_list("Interact_area.instance")

	def instance_type(self, node_name : str) -> str:
		return self.get_data("type",node_name)

