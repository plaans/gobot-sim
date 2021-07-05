import unittest
import time

from .SimulationTestBase import SimulationTestBase

class RotationTests(SimulationTestBase):

    def test_do_rotation(self):
        current_rotation = self.client.StateClient.robot_rotation('robot0')
        while current_rotation == None:
            current_rotation = self.client.StateClient.robot_rotation('robot0')
            time.sleep(0.1)
             
        action_id = self.client.ActionClientManager.run_command(['do_rotation','robot0', -0.3, 1.5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))

        self.assertAlmostEqual(self.client.StateClient.robot_rotation('robot0'), current_rotation - 0.3*1.5, delta=0.01)

    def test_rotate_to(self):
        action_id = self.client.ActionClientManager.run_command(['rotate_to','robot0', 1.5, 0.5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))

        self.assertAlmostEqual(self.client.StateClient.robot_rotation('robot0'), 1.5, delta=0.01)

    def test_face_belt(self):
        action_id = self.client.ActionClientManager.run_command(['face_belt','robot0', 'belt0', 0.5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))
            
if __name__ == '__main__':
    unittest.main()
