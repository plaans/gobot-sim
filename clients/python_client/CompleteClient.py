import pprint

from multiprocessing import Process


from StateClient import StateClient
from ActionClient import ActionClient

class CompleteClient( StateClient, ActionClient):
	def __init__(self, address, port):
		StateClient.__init__(self, address, port)
		ActionClient.__init__(self, address, port)
		p = Process(target=listen_to_server, args=())
		p.start()


	def listen_to_server(self):
		while True:
			data = self.read_data()
			
			if data["type"] == "response":
				ActionClient.receive_response(self,data)
			elif data["type"] == "state" or data["type"] == "environment":
				StateClient.update(self,data["data"])

		
    

	def kill(self):
		p.join()
		StateClient.kill(self)
		ActionClient.kill(self)
		


if __name__ == "__main__":

	client = StateClient("localhost",10000)

	

	client.kill()

