import unittest
import subprocess
import os

from ..clients.python_client.CompleteClient import CompleteClient

class ConnectionTest(unittest.TestCase):

    def test_connect_simulation(self):

        # start simulation
        sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", " Simulation-Factory-Godot/simu/simulation.pck", "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario_with_environment.json"])

        client = CompleteClient("localhost",10000)
        try:
            #try connecting client
            self.assertTrue(client.wait_for_server(10))
            client.kill()

        finally:
            sim.kill()
            sim.wait()

if __name__ == '__main__':
    unittest.main()
