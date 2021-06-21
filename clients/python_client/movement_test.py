import time
import subprocess
import threading 
import sys

from CompleteClient import CompleteClient

def cancel_after_half(progress, action, cancel_sent):
    if progress>=0.3 and not(cancel_sent.is_set()):
        cancel_sent.set()
        action.cancel(print)

# start simulation
sim = subprocess.Popen(["../../godot.exe", "--path", " ../../simu", " --scenario simu/scenarios/new_scenario.json"])
client = CompleteClient("localhost",10000)
try:
    
    if not(client.wait_for_server(10)):
            sys.exit("timeout")
    else:
            action_id = client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])

            #client.ActionClientManager.set_feedback_callback(action_id, print)
            #cancel_sent =  threading.Event()
            #client.ActionClientManager.set_feedback_callback(action_id, lambda d : cancel_after_half(d,action, cancel_sent) )
            if not(client.ActionClientManager.wait_result(action_id,10)):
                sys.exit("timeout")
            else:
                final_position = client.StateClient.robot_coordinates('robot0')
                distance_squared = (final_position[0]-15)**2 + (final_position[1]-15)**2
                assert distance_squared<=0.1
            

finally:
    client.kill()
    sim.kill()

