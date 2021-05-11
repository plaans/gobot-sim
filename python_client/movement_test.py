from CompleteClient import CompleteClient
import time

import subprocess

# start sim
subprocess.Popen("../Godot_v3.2.3-stable_win64.exe --path ../ --scenario scenario.json")

time.sleep(5)

# start client
client = CompleteClient("localhost", 10000)

client.navigate_to("robot1", 50, 60)

time.sleep(10)
assert client.coordinates("robot1") == (50, 60)   

client.kill()
