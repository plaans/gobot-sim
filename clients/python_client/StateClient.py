import pprint
from typing import Dict, List
import threading 


class StateClient():
	def __init__(self):
		self.state = {}
		self.names_list_by_category = {}
		
		self.ready = threading.Event() #will be set when the StateClient has received its first state update

	def update(self, message : Dict):
		data = message['data']
		for line in data:
			if len(line)==2:#declaration of instance
				name = line[1]
				type = line[0]
				if name not in self.state:
					self.state[name] = {}
				self.state[name]['type'] = type

				if type not in self.names_list_by_category :
					self.names_list_by_category[type] =[]
				self.names_list_by_category[type].append(name)

			if len(line)>=3:#to check the data has the right format
				name = line[1]
				attribute = line[0]
				value = line[2]
				if name not in self.state:
					self.state[name] = {}
				self.state[name][attribute] = value
		if not(self.ready.is_set()):
			self.ready.set()
		#pprint.pprint(self.state)

	def ready_event(self):
		return self.ready



	def get_data(self, key : str, name : str):
		if name in self.state and key in self.state[name]:
			return self.state[name][key]


	# getter functions, that access the state and return some information
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



	def package_location(self, package_name : str) -> str:
		return self.get_data("Package.location",package_name)

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

	def interact_area_Belt(self, interact_area_name : str) -> str:
		return self.get_data("Interact_area.Belt",interact_area_name)


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

