from typing import Callable, Dict

from ActionClientManager import ActionClientManager


class NavClient():
	def __init__(self, manager : ActionClientManager):
		self.manager = manager

		self.id = None

	def set_feedback_callback(self, callback : Callable):
		self.manager.set_feedback_callback(self.id, callback)

	def set_result_callback(self, callback : Callable):
		self.manager.set_result_callback(self.id, callback)

	def get_state(self):
		return self.manager.get_state(self.id)

	def wait_result(self, timeout : float):
		return self.manager.wait_result(self.id, timeout)

	def send_cancel_request(self):
		self.manager.send_cancel_request(self.id)

	def navigate_to(self, robot_name : str, dest_x : float, dest_y : float):
		command_to_send = ["navigate_to", robot_name, dest_x, dest_y]
		self.id = self.manager.run_command(command_to_send)

	def navigate_to_cell(self, robot_name : str, dest_x : float, dest_y : float):
		command_to_send = ["navigate_to_cell", robot_name, dest_x, dest_y]
		self.id = self.manager.run_command(command_to_send)

	def navigate_to_area(self, robot_name : str, area_name : str):
		command_to_send = ["navigate_to_area", robot_name, area_name]
		self.id = self.manager.run_command(command_to_send)
