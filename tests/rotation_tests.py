import unittest
import time

from .SimulationTestBase import SimulationTestBase

class RotationTests(SimulationTestBase):

    def test_do_rotation(self):
        #get the start rotation which will be used to compute the expected final rotation
        current_rotation = self.client.StateClient.robot_rotation('robot0')
        while current_rotation == None:
            current_rotation = self.client.StateClient.robot_rotation('robot0')
            time.sleep(0.1)
             
        speed = -0.3
        duration = 1.5
        
        action_id = self.client.ActionClientManager.run_command(['do_rotation','robot0', speed, duration])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #check final rotation is closed enough to rotation expected
        self.assertAlmostEqual(self.client.StateClient.robot_rotation('robot0'), current_rotation + speed*duration, delta=0.01)

    def test_rotate_to(self):
        angle = 1.5
        speed = 0.5

        action_id = self.client.ActionClientManager.run_command(['rotate_to','robot0', angle, speed])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #check final rotation is closed enough to rotation expected
        self.assertAlmostEqual(self.client.StateClient.robot_rotation('robot0'), angle, delta=0.01)

    def test_face_belt(self):
        speed = 0.5

        #make the robot face the belt and check the command ended successfully
        action_id = self.client.ActionClientManager.run_command(['face_belt','robot0', 'belt0', speed])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
            
if __name__ == '__main__':
    unittest.main()
