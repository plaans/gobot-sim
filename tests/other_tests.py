import time
import unittest
import subprocess
import os

from ..clients.python_client.CompleteClient import CompleteClient

class OtherTest(unittest.TestCase):

    def setUp(self):
        self.client = CompleteClient("localhost",10000)
        
        self.sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", "gobot-sim/simu/simulation.pck",
            "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario_with_two_robots.json", #use different scenario to have multiple robots
            "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/new_environment.json"])

        self.assertTrue(self.client.wait_for_server(10))

    def tearDown(self):
        self.client.kill()
        self.sim.kill()
        self.sim.wait()

    def test_two_robots(self):
        self.client.StateClient.wait_next_dynamic_update(timeout=10)
        robot0 = self.client.StateClient.robots_list()[0]
        robot1 = self.client.StateClient.robots_list()[1]

        action_id_0 = self.client.ActionClientManager.run_command(['navigate_to', robot0, 5, 15])
        action_id_1 = self.client.ActionClientManager.run_command(['navigate_to', robot1, 15, 15])

        self.assertTrue(self.client.ActionClientManager.wait_result(action_id_0,10))
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id_1,10))

        final_position0 = self.client.StateClient.robot_coordinates(robot0)
        distance_squared0 = (final_position0[0]-5)**2 + (final_position0[1]-15)**2
        self.assertAlmostEqual(distance_squared0, 0, delta=0.1)

        final_position1 = self.client.StateClient.robot_coordinates(robot1)
        distance_squared1 = (final_position1[0]-15)**2 + (final_position1[1]-15)**2
        self.assertAlmostEqual(distance_squared1, 0, delta=0.1)

