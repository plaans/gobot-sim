from typing import Callable, Dict, List
import threading 

from TCP_Client import TCP_Client


class ActionServer():
	def __init__(self, client, id):
		self.id = id
		self.client = client #used to have access to the client to send cancel requests

		self.feed_back_callback = None

		self.result = None
		self.result_received = threading.Event()
		self.result_callback = None

		self.cancel_callback = None

		self.current_state = "PENDING"

	def set_feedback_callback(self, callback : Callable):
		self.feed_back_callback = callback

	def set_result_callback(self, callback : Callable):
		self.result_callback = callback

	def set_id(self, command_id):
		self.id = command_id

	def get_state(self):
		return self.current_state

	def reject(self):
		self.current_state = "REJECT"
		self.result = False
		self.result_received.set()
	
	def receive_feedback(self, feedback):
		if callable(self.feed_back_callback):
			self.feed_back_callback(feedback)

	def receive_result(self, result):
		self.result = result
		self.result_received.set()

		if callable(self.result_callback):
			self.result_callback(result)

	def cancel(self, callback_function : Callable):
		self.cancel_callback = callback_function

		self.client.send_cancel_request(self.id)
		

	def receive_cancel_response(self, cancelled):
		if callable(self.cancel_callback):
			self.cancel_callback(cancelled)
		self.receive_result(False)

	def wait_result(self, timeout : float):
		if self.result_received.wait(timeout):
			return self.result
		else:
			return False
	
