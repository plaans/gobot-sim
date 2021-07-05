from typing import Callable, Dict, List
import threading 
from enum import Enum, auto

class States(Enum):
	PENDING = auto()
	ACTIVE = auto()
	RECALLED = auto()
	REJECTED = auto()
	PREEMPTED = auto()
	ABORTED = auto()
	SUCCEEDED = auto()


class ActionClient():
	def __init__(self, client, id):
		self.id = id
		self.id_attributed = threading.Event()

		self.client = client #used to have access to the client to send cancel requests

		self.feed_back_callback = None

		self.result = None
		self.result_received = threading.Event()
		self.result_callback = None

		self.cancel_callback = None

		self.current_state = States.PENDING

	
	def wait_id_attributed(self, timeout=10):
		if self.id_attributed.wait(timeout):
			return self.id
		else:
			return None

	def set_feedback_callback(self, callback : Callable):
		self.feed_back_callback = callback

	def set_result_callback(self, callback : Callable):
		self.result_callback = callback

	def set_id(self, command_id):
		self.id = command_id

	def accept(self, command_id):
		self.id = command_id
		self.current_state = States.ACTIVE
		self.id_attributed.set()

	def get_state(self):
		return self.current_state

	def reject(self):
		self.current_state = States.REJECTED
		self.id_attributed.set() #in this case the id will stay the temp_id
		self.result = False
		self.result_received.set()
	
	def receive_feedback(self, feedback):
		if callable(self.feed_back_callback):
			self.feed_back_callback(feedback)

	def receive_result(self, result):
		self.result = result
		if not(result):
			self.current_state = States.ABORTED
		else:
			self.current_state = States.SUCCEEDED
		self.result_received.set()

		if callable(self.result_callback):
			self.result_callback(result)
		
	def preempted(self):
		self.current_state = States.PREEMPTED
		self.result = False
		self.result_received.set()

	def cancel(self, cancelled):
		self.current_state = States.RECALLED
		if callable(self.cancel_callback):
			self.cancel_callback(cancelled)
		self.result = False
		self.result_received.set()

	def wait_result(self, timeout : float):
		if self.result_received.wait(timeout):
			return self.result
		else:
			return False
