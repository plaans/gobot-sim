import unittest
import time

from .SimulationTestBase import SimulationTestBase
from ..clients.python_client.CompleteClient import CompleteClient
from ..clients.python_client.ActionClient import States


class ConnectionTest(SimulationTestBase):

    def test_connect_simulation(self):
        pass #launching simulation and connecting the client is done in 
            

    def test_send_commands(self):
        #command that should work
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id,10))

        #commands that should not work
        action_id = self.client.ActionClientManager.run_command(['wrong_command','robot0', 15, 15])
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id,10))
        action_id = self.client.ActionClientManager.run_command(['navigate_to','wrong_target', 15, 15])
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id,10))
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0']) #wrong_number of arguments
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id,10))      

    def test_cancel(self):
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
        time.sleep(0.5)
        self.client.ActionClientManager.send_cancel_request(action_id)
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id,10))
        self.assertEqual(self.client.ActionClientManager.get_state(action_id), States.RECALLED)

if __name__ == '__main__':
    unittest.main()
