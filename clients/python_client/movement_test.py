import time
import subprocess

from CompleteClient import CompleteClient

# start sim
sim = subprocess.Popen("../../Godot_v3.2.3-stable_win64.exe --path ../../simu --scenario simu/scenarios/new_scenario.json")

try :
    time.sleep(5)

    # start client
    client = CompleteClient("localhost",10000)

    client.ActionClient.navigate_to('robot0', 15, 15)
    time.sleep(5)

    #client.ActionClient.navigate_to('robot1', 100, 100)

    final_position = client.StateClient.robot_coordinates('robot0')
    distance_squared = (final_position[0]-15)**2 + (final_position[1]-15)**2
    assert distance_squared<=0.1

    client.kill()

finally:
    sim.kill()

