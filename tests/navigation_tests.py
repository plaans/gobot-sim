import unittest
import time

from .SimulationTestBase import SimulationTestBase

class NavigationTests(SimulationTestBase):

    def test_do_move(self):
        start_position = self.client.StateClient.robot_coordinates('robot0')
        while start_position == None:
            start_position = self.client.StateClient.robot_coordinates('robot0')
            time.sleep(0.1)

        action_id = self.client.ActionClientManager.run_command(['do_move','robot0', 0, 5, 1.5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))

        final_position = self.client.StateClient.robot_coordinates('robot0')
        distance_squared = (final_position[0]-(start_position[0] + 5*1.5))**2 + (final_position[1]-start_position[1])**2
        self.assertAlmostEqual(distance_squared, 0, delta=0.1)

    def test_navigate_to(self):
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))

        final_position = self.client.StateClient.robot_coordinates('robot0')
        distance_squared = (final_position[0]-15)**2 + (final_position[1]-15)**2
        self.assertAlmostEqual(distance_squared, 0, delta=0.1)


    def test_navigate_to_cell(self):
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 3, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))

        self.assertEqual(self.client.StateClient.robot_coordinates_tile('robot0'), [3, 5])


    def test_navigate_to_area(self):
        self.assertTrue(self.client.StateClient.wait_for_message("Parking_area.instance", 10))
        target_parking_area = self.client.StateClient.parking_areas_list()[0]

        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0',target_parking_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))
        self.assertTrue(self.client.StateClient.robot_in_station('robot0'))
        

        target_interact_area = self.client.StateClient.interact_areas_list()[0]

        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0',target_interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))
        self.assertIn(target_interact_area, self.client.StateClient.robot_in_interact_areas('robot0'))
            
if __name__ == '__main__':
    unittest.main()
