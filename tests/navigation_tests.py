import unittest
import time

from .SimulationTestBase import SimulationTestBase

class NavigationTests(SimulationTestBase):

    def test_do_move(self):
        #get the start position which will be used to compute the expected final position
        start_position = self.client.StateClient.robot_coordinates('robot0')
        while start_position == None:
            start_position = self.client.StateClient.robot_coordinates('robot0')
            time.sleep(0.1)

        angle = 0
        speed = 5
        duration = 1.5

        action_id = self.client.ActionClientManager.run_command(['do_move','robot0', angle, speed, duration])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #get real final position and compute what position was expected, and check they are close enough
        final_position = self.client.StateClient.robot_coordinates('robot0')
        expected_position = [start_position[0] + speed*duration, start_position[1]]

        distance_squared = (final_position[0]-expected_position[0])**2 + (final_position[1]-expected_position[1])**2
        self.assertAlmostEqual(distance_squared, 0, delta=0.1)

    def test_navigate_to(self):
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #check final position is close enough to position asked for 
        final_position = self.client.StateClient.robot_coordinates('robot0')
        distance_squared = (final_position[0]-15)**2 + (final_position[1]-15)**2
        self.assertAlmostEqual(distance_squared, 0, delta=0.1)


    def test_navigate_to_cell(self):
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 3, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #check final position is equal to position asked for 
        #(this time the position asked was given as ids of tile so get the tile position of the robot)
        self.assertEqual(self.client.StateClient.robot_coordinates_tile('robot0'), [3, 5])


    def test_navigate_to_area(self):

        #send the robot to a parking area and check it is an a parking area
        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0','parking_area0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        self.assertTrue(self.client.StateClient.robot_in_station('robot0'))
        
        #send the robot to a interact area and check the area is in the list of interact areas the robot is in
        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0','interact_area0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        self.assertIn('interact_area0', self.client.StateClient.robot_in_interact_areas('robot0'))

    def test_go_charge(self):
        
        #move outside of parking_area
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #send command (that makes the robot go to a parking area) and check the robot is in a parking area
        action_id = self.client.ActionClientManager.run_command(['go_charge','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        self.assertTrue(self.client.StateClient.robot_in_station('robot0'))
            
if __name__ == '__main__':
    unittest.main()
