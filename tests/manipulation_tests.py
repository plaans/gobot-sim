import time
import subprocess
import threading 
import sys

import unittest
import subprocess
import os

from ..clients.python_client.CompleteClient import CompleteClient

class ManipulationTests(unittest.TestCase):

    def setUp(self):
        self.sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", " Simulation-Factory-Godot/simu/simulation.pck",
         "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario.json",
         "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/new_environment.json"])

    def tearDown(self):
        self.sim.kill()
        self.sim.wait()

    def test_pick(self):
        client = CompleteClient("localhost",10000)
        self.assertTrue(client.wait_for_server(10))
        try:
            while client.StateClient.packages_list() == None:
                time.sleep(0.1)

            target_package = client.StateClient.packages_list()[0]

            package_parent_node = client.StateClient.package_location(target_package)
            while package_parent_node == None or client.StateClient.instance_type(package_parent_node) != 'Belt.instance':
                package_parent_node = client.StateClient.package_location(target_package)
                time.sleep(0.1)

            interact_area = client.StateClient.belt_interact_areas(package_parent_node)[0]

            action_id = client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))
            
            action_id = client.ActionClientManager.run_command(['face_belt', 'robot0',package_parent_node, 5])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))

            action_id = client.ActionClientManager.run_command(['pick','robot0'])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))

            time.sleep(0.5)

            self.assertTrue(client.StateClient.package_location(target_package) == 'robot0')

        finally:
            client.kill()

    def test_place(self):

        client = CompleteClient("localhost",10000)
        self.assertTrue(client.wait_for_server(10))
        try:
            while client.StateClient.packages_list() == None:
                time.sleep(0.1)

            target_package = client.StateClient.packages_list()[0]

            package_parent_node = client.StateClient.package_location(target_package)
            while package_parent_node == None or client.StateClient.instance_type(package_parent_node) != 'Belt.instance':
                package_parent_node = client.StateClient.package_location(target_package)
                time.sleep(0.1)

            interact_area = client.StateClient.belt_interact_areas(package_parent_node)[0]

            action_id = client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))
            
            action_id = client.ActionClientManager.run_command(['face_belt', 'robot0',package_parent_node, 5])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))

            action_id = client.ActionClientManager.run_command(['pick','robot0'])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))

            time.sleep(0.5)
            self.assertTrue(client.StateClient.package_location(target_package) == 'robot0')

            #now that package was picked find where to place it
            
            process_to_do = client.StateClient.package_processes_list(target_package)[0][0]
            machine_chosen = None
            machines_list = client.StateClient.machines_list()
            for machine in machines_list :
                possible_processes = client.StateClient.machine_processes_list(machine)
                if process_to_do in possible_processes:
                    machine_chosen = machine
                    break
            
            belt = client.StateClient.machine_input_belt(machine_chosen)
            interact_area = client.StateClient.belt_interact_areas(belt)[0]

            action_id = client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))
            
            action_id = client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))

            action_id = client.ActionClientManager.run_command(['place','robot0'])
            self.assertTrue(client.ActionClientManager.wait_result(action_id, 10))

            time.sleep(0.5)
            self.assertTrue(client.StateClient.package_location(target_package) == machine_chosen)

        finally:
            client.kill()

            

