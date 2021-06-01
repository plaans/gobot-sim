import time
import subprocess
import threading 
import sys

from CompleteClient import CompleteClient
from OutputReader import OutputReader

# start simulation
sim = subprocess.Popen("../../Godot_v3.2.3-stable_win64.exe --path ../../simu --scenario simu/scenarios/new_scenario.json", stdout=subprocess.PIPE)
server_wait_done = threading.Event()

output_reader = OutputReader(sim.stdout)
output_reader.bind_function("Server started", lambda _ : server_wait_done.set())

try:
    output_reader.start()
    
    if not(server_wait_done.wait(5)):
            sys.exit("timeout")
    else:

        # start client
        client = CompleteClient("localhost",10000)
    
        try:
            #wait until the StateClient has received at least a first update
            if not(client.StateClient.ready.wait(10)):
                sys.exit("timeout")
            target_parking_area = client.StateClient.parking_areas_list()[0]

            command_done = threading.Event()
            client.ActionClient.navigate_to_area('robot0', target_parking_area, result_callback = lambda _ : command_done.set())
            if not(command_done.wait(10)):
                sys.exit("timeout")
            else:
                assert client.StateClient.robot_in_station('robot0')
            
            target_interact_area = client.StateClient.interact_areas_list()[0]
            command_done.clear()
            client.ActionClient.navigate_to_area('robot0', target_interact_area, result_callback = lambda _ : command_done.set())
            if not(command_done.wait(10)):
                sys.exit("timeout")
            else:
                assert target_interact_area in client.StateClient.robot_in_interact_areas('robot0')

        finally:
            client.kill()

finally:
    sim.kill()
    output_reader.kill()

