import time
import unittest

from .SimulationTestBase import SimulationTestBase

class ManipulationTests(SimulationTestBase):

    def test_pick(self):
        self.client.StateClient.wait_for_message('Package.instance', timeout=10)

        #get a package in the list of existing packages
        self.target_package = self.client.StateClient.packages_list()[0]

        #wait until that package is on belt4 (the belt packages arrive on in the scenario and environment loaded)
        self.client.StateClient.wait_for_message('Package.location', instance_name = self.target_package, value='belt4', timeout=10)

        belt = self.client.StateClient.package_location(self.target_package)

        #get an interact area of the belt
        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]

        #make the robot navigate to this interact area, then face the belt
        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #make the robot pick
        action_id = self.client.ActionClientManager.run_command(['pick','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        self.client.StateClient.wait_for_message('Package.location', instance_name = self.target_package, value='robot0', timeout=10)

        #check the package supposed to have been picked (first of the belt) has now the robot as location
        self.assertEqual(self.client.StateClient.package_location(self.target_package), 'robot0')

    def test_pick_package(self):
        self.client.StateClient.wait_for_message('Package.instance', timeout=10)

        #get a package in the list of existing packages
        self.target_package = self.client.StateClient.packages_list()[0]

        #wait until that package is on belt4 (the belt packages arrive on in the scenario and environment loaded)
        self.client.StateClient.wait_for_message('Package.location', instance_name = self.target_package, value='belt4', timeout=10)

        belt = self.client.StateClient.package_location(self.target_package)

        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]

        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        action_id = self.client.ActionClientManager.run_command(['pick_package','robot0', self.target_package])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        time.sleep(0.5)

        self.assertEqual(self.client.StateClient.package_location(self.target_package), 'robot0')


    def test_place(self):
        #first reuse previous pick test to end up with the robot carrying a package
        self.test_pick()

        #now that package was picked find where to place it
        #for that take the first process in the list of processes to be done, and search for a machine that can do this process
        process_to_do = self.client.StateClient.package_processes_list(self.target_package)[0][0]
        machine_chosen = None
        machines_list = self.client.StateClient.machines_list()
        for machine in machines_list :
            possible_processes = self.client.StateClient.machine_processes_list(machine)
            if process_to_do in possible_processes:
                machine_chosen = machine
                break
        
        #then find the input_belt of this machine and procede as for pick test : find the interact area, navigate to it and face the belt
        belt = self.client.StateClient.machine_input_belt(machine_chosen)
        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]

        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #then send place command
        action_id = self.client.ActionClientManager.run_command(['place','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        time.sleep(0.5)

        #check the package is now located in the machine it is supposed to be in
        self.assertEqual(self.client.StateClient.package_location(self.target_package), machine_chosen)

if __name__ == '__main__':
    unittest.main()            

