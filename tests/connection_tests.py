import unittest

from .SimulationTestBase import SimulationTestBase
from ..clients.python_client.CompleteClient import CompleteClient


class ConnectionTest(SimulationTestBase):

    def test_connect_simulation(self):

        client = CompleteClient("localhost",10000)
        self.assertTrue(client.wait_for_server(10))
        client.kill()
            

    def test_send_commands(self):

        client = CompleteClient("localhost",10000)
        self.assertTrue(client.wait_for_server(10))
        try:
            #command that should work
            action_id = client.ActionClientManager.run_command(['navigate_to','robot0', 15, 15])
            self.assertTrue(client.ActionClientManager.wait_result(action_id,10))

            #commands that should not work
            action_id = client.ActionClientManager.run_command(['wrong_command','robot0', 15, 15])
            self.assertFalse(client.ActionClientManager.wait_result(action_id,10))
            action_id = client.ActionClientManager.run_command(['navigate_to','wrong_target', 15, 15])
            self.assertFalse(client.ActionClientManager.wait_result(action_id,10))
            action_id = client.ActionClientManager.run_command(['navigate_to','robot0']) #wrong_number of arguments
            self.assertFalse(client.ActionClientManager.wait_result(action_id,10))      
        finally:
            client.kill()

if __name__ == '__main__':
    unittest.main()
