import time
import unittest

from .SimulationTestBase import SimulationTestBase

class ManipulationTests(SimulationTestBase):

    def test_pick(self):
        while self.client.StateClient.packages_list() == None:
            time.sleep(0.1)

        self.target_package = self.client.StateClient.packages_list()[0]

        package_parent_node = self.client.StateClient.package_location(self.target_package)
        while package_parent_node == None or self.client.StateClient.instance_type(package_parent_node) != 'Belt.instance':
            package_parent_node = self.client.StateClient.package_location(self.target_package)
            time.sleep(0.1)

        interact_area = self.client.StateClient.belt_interact_areas(package_parent_node)[0]

        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))
        
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',package_parent_node, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))

        action_id = self.client.ActionClientManager.run_command(['pick','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))

        time.sleep(0.5)

        self.assertEqual(self.client.StateClient.package_location(self.target_package), 'robot0')

    def test_pick_package(self):
        time.sleep(1)

        self.target_package = self.client.StateClient.packages_list()[0]

        input_machine = self.client.StateClient.package_location(self.target_package)
        belt =  self.client.StateClient.machine_output_belt(input_machine)
        while self.client.StateClient.belt_packages_list(belt) == None or len(self.client.StateClient.belt_packages_list(belt))<2:
            time.sleep(0.1)

        package_to_pick=self.client.StateClient.belt_packages_list(belt)[0]

        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]

        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))
        
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))

        action_id = self.client.ActionClientManager.run_command(['pick_package','robot0', package_to_pick])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))

        time.sleep(0.5)

        self.assertEqual(self.client.StateClient.package_location(package_to_pick), 'robot0')


    def test_place(self):
        self.test_pick()

        #now that package was picked find where to place it
        
        process_to_do = self.client.StateClient.package_processes_list(self.target_package)[0][0]
        machine_chosen = None
        machines_list = self.client.StateClient.machines_list()
        for machine in machines_list :
            possible_processes = self.client.StateClient.machine_processes_list(machine)
            if process_to_do in possible_processes:
                machine_chosen = machine
                break
        
        belt = self.client.StateClient.machine_input_belt(machine_chosen)
        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]

        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))
        
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))

        action_id = self.client.ActionClientManager.run_command(['place','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, 10))

        time.sleep(0.5)
        self.assertEqual(self.client.StateClient.package_location(self.target_package), machine_chosen)

if __name__ == '__main__':
    unittest.main()            

