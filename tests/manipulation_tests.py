import time
import subprocess
import threading 
import sys

import unittest
import subprocess
import os

from ..clients.python_client.CompleteClient import CompleteClient

class ManipulationTests(unittest.TestCase):

    def test_pick(self):

        # start simulation
        sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", " Simulation-Factory-Godot/simu/simulation.pck",
         "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario.json",
         "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/new_environment.json"])

        client = CompleteClient("localhost",10000)
        try:
            #try connecting client
            self.assertTrue(client.wait_for_server(10))

            self.assertTrue(client.StateClient.wait_for_message("Package.location", 10))
            
            target_package = client.StateClient.packages_list()[0]
            input_machine_name = client.StateClient.package_location(target_package)
            belt = client.StateClient.machine_output_belt(input_machine_name)
            interact_area = client.StateClient.belt_interact_areas(belt)[0]

            while target_package not in client.StateClient.belt_packages_list(belt):
                input_machine_name = client.StateClient.package_location(target_package)
                belt = client.StateClient.machine_output_belt(input_machine_name)
                interact_area = client.StateClient.belt_interact_areas(belt)[0]
                time.sleep(0.1)

            action_id = client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
            client.ActionClientManager.wait_result(action_id, 10)
            
            action_id = client.ActionClientManager.run_command(['face_object', 'robot0',belt, 5])
            assert client.ActionClientManager.wait_result(action_id, 10)

            action_id = client.ActionClientManager.run_command(['pick','robot0'])
            assert client.ActionClientManager.wait_result(action_id, 10)

            assert client.StateClient.wait_next_dynamic_update(10)

            assert client.StateClient.package_location(target_package) == 'robot0'

            client.kill()

        finally:
            sim.kill()
            sim.wait()

