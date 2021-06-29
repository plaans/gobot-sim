import unittest
import subprocess
import os

class SimulationTestBase(unittest.TestCase):

    def setUp(self):
        self.sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", " Simulation-Factory-Godot/simu/simulation.pck",
            "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario.json",
            "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/new_environment.json"])

    def tearDown(self):
        self.sim.kill()
        self.sim.wait()

