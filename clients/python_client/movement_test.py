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
#output_reader.bind_function("", print)

try:

    
    output_reader.start()
    
    if not(server_wait_done.wait(5)):
            sys.exit("timeout")
    else:

        # start client
        client = CompleteClient("localhost",10000)

        try :
            command_done = threading.Event()
            client.ActionClient.navigate_to('robot0', 15, 15, result_callback = lambda _ : command_done.set())
            if not(command_done.wait(10)):
                sys.exit("timeout")
            else:
                final_position = client.StateClient.robot_coordinates('robot0')
                distance_squared = (final_position[0]-15)**2 + (final_position[1]-15)**2
                assert distance_squared<=0.1
        finally:
            client.kill()

finally:
    sim.kill()
    output_reader.kill()

