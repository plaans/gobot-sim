import time
import subprocess

from CompleteClient import CompleteClient


# start sim
sim = subprocess.Popen("../../Godot_v3.2.3-stable_win64.exe --path ../../simu --scenario simu/scenarios/new_scenario.json")

try :
    time.sleep(0.5)

    # start client
    client = CompleteClient("localhost",10000)
    time.sleep(0.5)

    target_parking_area = client.StateClient.parking_areas_list()[0]
    client.ActionClient.navigate_to_area('robot0', target_parking_area)
    time.sleep(5)
    assert client.StateClient.robot_in_station('robot0')

    target_interact_area = client.StateClient.interact_areas_list()[0]
    client.ActionClient.navigate_to_area('robot0', target_interact_area)
    time.sleep(5)

    assert target_interact_area in client.StateClient.robot_in_interact_areas('robot0')

    client.kill()

finally:
    sim.kill()

