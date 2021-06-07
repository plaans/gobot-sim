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
            action = client.ActionClient.navigate_to('robot0', 15, 15)
            #action.set_feedback_callback(print)
            #cancel_sent =  threading.Event()
            #action.set_feedback_callback(lambda d : cancel_after_half(d,action, cancel_sent) )
            if not(action.wait_result(10)):
                sys.exit("timeout")
            else:
                final_position = client.StateClient.robot_coordinates('robot0')
                distance_squared = (final_position[0]-15)**2 + (final_position[1]-15)**2
                assert distance_squared<=0.1
            

finally:
    client.kill()
    sim.kill()

