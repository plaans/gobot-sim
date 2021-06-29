import unittest

from .SimulationTestBase import SimulationTestBase

class RotationTests(SimulationTestBase):

    def test_rotate_to(self):
        action_id = self.client.ActionClientManager.run_command(['rotate_to','robot0', 1.5, 0.5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))

        self.assertAlmostEqual(self.client.StateClient.robot_rotation('robot0'), 1.5, delta=0.01)

    def test_face_belt(self):
        action_id = self.client.ActionClientManager.run_command(['face_belt','robot0', 'belt0', 0.5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))
            
if __name__ == '__main__':
    unittest.main()
