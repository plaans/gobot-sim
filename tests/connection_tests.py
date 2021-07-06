import unittest
import time

from .SimulationTestBase import SimulationTestBase
from ..clients.python_client.CompleteClient import CompleteClient
from ..clients.python_client.ActionClient import States


class ConnectionTest(SimulationTestBase):

    def test_connect_simulation(self):
        #the setUp function already starts the simulation and check the client connected successfully
        pass

    def test_connect_multiple_clients(self):
        #create another client and check it connect successfully (the first one already connected in the setUp function)
        other_client = CompleteClient("localhost",10000)
        try:
            self.assertTrue(other_client.wait_for_server(timeout=10))
        finally:
           other_client.kill()
            

    def test_send_commands(self):
        #command that should work
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        self.assertEqual(self.client.ActionClientManager.get_state(action_id), States.SUCCEEDED)

        #commands that are not valid
        action_id = self.client.ActionClientManager.run_command(['wrong_command','robot0', 15, 15])
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        self.assertEqual(self.client.ActionClientManager.get_state(action_id), States.REJECTED)

        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0']) #wrong_number of arguments
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id, timeout=10))   
        self.assertEqual(self.client.ActionClientManager.get_state(action_id), States.REJECTED)   

        #command that is valid but should not work
        action_id = self.client.ActionClientManager.run_command(['pick','robot0'])
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        self.assertEqual(self.client.ActionClientManager.get_state(action_id), States.ABORTED)


    def test_cancel(self):
        #send a command then cancel it and check it was correctly canceled
        action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
        time.sleep(0.5)
        self.client.ActionClientManager.send_cancel_request(action_id)
        self.assertFalse(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        self.assertEqual(self.client.ActionClientManager.get_state(action_id), States.RECALLED)

    def test_preempt(self):
        #send a navigate_to and using the other client connected resend a navigate_to command and check the first one was preempted
        other_client = CompleteClient("localhost",10000)
        try:
            self.assertTrue(other_client.wait_for_server(10))

            action_id = self.client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
            time.sleep(0.5)
            other_client.ActionClientManager.run_command(['navigate_to','robot0', 5, 20])

            self.assertFalse(self.client.ActionClientManager.wait_result(action_id, timeout=10))
            self.assertEqual(self.client.ActionClientManager.get_state(action_id), States.PREEMPTED)
        finally:
           other_client.kill()

if __name__ == '__main__':
    unittest.main()
