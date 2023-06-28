import unittest
import subprocess
import os

from ..clients.python_client.CompleteClient import CompleteClient

from .SimulationTestBase import SimulationTestBase

class Demonstration(SimulationTestBase):

    def setUp(self):
        self.client = CompleteClient("localhost",10000)
        
        self.sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", "gobot-sim/simu/simulation.pck",
            "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario.json",
            "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/new_environment.json",
            "--robot_controller", "teleport", "--time_scale", "3"])

        self.assertTrue(self.client.wait_for_server(10))

    def test_demo(self):
        # demo taking care of processing and delivering every package available

        #wait for information on the first package to be received
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'package0' in state and  'Package.location' in state['package0'], timeout=10))
        
        packages_list = self.client.StateClient.packages_list()

        #do each package one by one
        k=0
        while k<len(packages_list):
            target_package = packages_list[k]
            #first pick the package at the input machine 
            self.take_package(target_package)

            #then do the processes
            while len(self.client.StateClient.package_processes_list(target_package)) > 0:
                self.do_next_process(target_package)

            #then deliver at the output machine
            output_machine = self.find_output_machine()
            self.deliver_package(output_machine)

            packages_list = self.client.StateClient.packages_list()#update list to include new packages
            k += 1

    def find_machine_for_process(self, process_id):
        #finds a machine that can do the process specified
        machines_list = self.client.StateClient.machines_list()
        for machine in machines_list :
            possible_processes = self.client.StateClient.machine_processes_list(machine)
            if process_id in possible_processes:
                return machine

    def find_output_machine(self):
        machines_list = self.client.StateClient.machines_list()
        for machine in machines_list :
            if self.client.StateClient.machine_type(machine) == 'output_machine':
                return machine

    def charge(self):
        #makes the robot go to a charging area and wait until battery is full
        action_id = self.client.ActionClientManager.run_command(['go_charge','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        self.assertTrue(self.client.StateClient.wait_condition(lambda state : state['robot0']['Robot.battery'] == 1, timeout=10))

    def position_robot_to_belt(self, belt):
        #takes as argument a belt
        #makes the robot go to an interact area of the belt and face the belt
        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]
        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

    def take_package(self, package):
        #takes as argument a package in the input machine
        #waits until the package is available on the output belt and then pick it up

        if self.client.StateClient.robot_battery('robot0')<0.4:
            self.charge()

        #if package not yet on a belt wait until it is on the output belt of the machine it is currently in
        if self.client.StateClient.instance_type(self.client.StateClient.package_location(package)) != "Belt.instance":
            machine = self.client.StateClient.package_location(package)
            belt = self.client.StateClient.machine_output_belt(machine)
            self.assertTrue(self.client.StateClient.wait_condition(lambda state : state[package]['Package.location'] == belt, timeout=10))

        belt = self.client.StateClient.package_location(package)
        self.position_robot_to_belt(belt)
        action_id = self.client.ActionClientManager.run_command(['pick','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

    def deliver_package(self, machine):
        #takes as argument a package carried by the robot (which must have all its processes completed) and a machine to deliver it to an output machine
     
        if self.client.StateClient.robot_battery('robot0')<0.4:
            self.charge()

        belt_in = self.client.StateClient.machine_input_belt(machine)
        self.position_robot_to_belt(belt_in)
        action_id = self.client.ActionClientManager.run_command(['place','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))


    def do_next_process(self, package):
        #takes as argument a package with a at least one process left to do, being currently carried by the robot
        #brings the package to a machine that can do the next process and wait until it is done then pick it up again

        if self.client.StateClient.robot_battery('robot0')<0.4:
            self.charge()

        #find a machine for the process and bring the package to its input belt
        process_to_do = self.client.StateClient.package_processes_list(package)[0][0]
        machine = self.find_machine_for_process(process_to_do)
        belt_in = self.client.StateClient.machine_input_belt(machine)

        self.position_robot_to_belt(belt_in)
        action_id = self.client.ActionClientManager.run_command(['place','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #wait for the machine to process the package
        action_id = self.client.ActionClientManager.run_command(['process', machine, package])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        belt_out = self.client.StateClient.machine_output_belt(machine)
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : state[package]['Package.location'] == belt_out, timeout=100))

        #pick the package from the machine output belt
        self.position_robot_to_belt(belt_out)
        action_id = self.client.ActionClientManager.run_command(['pick','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))


if __name__ == '__main__':
    unittest.main()            

