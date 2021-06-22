from typing import Callable, Dict
import threading 

class OutputReader():
	def __init__(self, stdout):
		self.stdout = stdout
		self.callbacks = {}

		self.stop_thread = threading.Event()
		self.thread = threading.Thread(target=self.read_output)
		self.thread.daemon = True
	
	def start(self):
		self.thread.start()

	def read_output(self):
		for line in self.stdout:
			if self.stop_thread.is_set():
				break
			for key in self.callbacks.keys():
				if key in line.decode('utf-8'):
					self.callbacks[key](line.decode('utf-8'))

	def bind_function(self, text_key : str, callback_function : Callable):
		self.callbacks[text_key] = callback_function

	def kill(self):
		self.stop_thread.set()
		self.thread.join()
