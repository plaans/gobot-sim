import time
import subprocess
import threading 
import sys

from CompleteClient import CompleteClient

# start simulation
sim = subprocess.Popen(["../../godot", "--path", " ../../simu", " --scenario simu/scenarios/new_scenario.json"])

try:
    # start client
    client = CompleteClient("localhost",10000)
    
    if not(client.wait_for_server(10)):
            sys.exit("timeout")
    else:
        try:
            if not(client.StateClient.wait_for_message("Parking_area.instance", 10)):
                sys.exit("timeout")
            target_parking_area = client.StateClient.parking_areas_list()[0]

            command = client.ActionClient.navigate_to_area('robot0', target_parking_area)
            if not(command.wait_result(10)):
                sys.exit("timeout")
            else:
                assert client.StateClient.robot_in_station('robot0')
            
            target_interact_area = client.StateClient.interact_areas_list()[0]

            command = client.ActionClient.navigate_to_area('robot0', target_interact_area)
            if not(command.wait_result(10)):
                sys.exit("timeout")
            else:
                assert target_interact_area in client.StateClient.robot_in_interact_areas('robot0')

        finally:
            client.kill()

finally:
    sim.kill()

