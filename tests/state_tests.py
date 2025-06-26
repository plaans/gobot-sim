from typing import List
import unittest
import time

from .SimulationTestBase import SimulationTestBase


class StateTest(SimulationTestBase):

    def test_globals_state(self):
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'Globals' in state, timeout=10))
    
        self.assertEqual(len(self.client.StateClient.state["Globals"]), 5)

        self.assertEqual(self.client.StateClient.globals_robot_battery_charge_rate(), 0.8)
        self.assertEqual(self.client.StateClient.globals_robot_battery_drain_rate(), 0.1)
        self.assertEqual(self.client.StateClient.globals_robot_battery_drain_rate_idle(), 0.001)
        self.assertEqual(self.client.StateClient.globals_robot_default_battery_capacity(), 10)
        self.assertEqual(self.client.StateClient.globals_robot_standard_speed(), 1.5625)


    def test_package_state(self):
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'package0' in state, timeout=10))

        #check list of packages is a list and is not empty
        package_list = self.client.StateClient.packages_list()
        self.assertIsInstance(package_list, List)
        self.assertNotEqual(package_list, [])

        #do checks on the first package is in the list based on what is expected
        package = package_list[0]
        self.assertEqual(package, 'package0')
        self.assertEqual(self.client.StateClient.instance_type(package), 'Package.instance')

        #wait for package location information to be received since it comes after the first dynamic update
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'package0' in state and 'Package.location' in state['package0'], timeout=10))

        self.assertEqual(self.client.StateClient.package_location(package), 'input_machine0')
        self.assertEqual(self.client.StateClient.package_all_processes(package), [[0,10],[1,5]])
        
        self.assertEqual(self.client.StateClient.package_processes_list(package), [[0,10],[1,5]])

    def test_robot_state(self):
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'robot0' in state, timeout=10))
        self.client.StateClient.wait_next_dynamic_update(timeout=10)
        self.assertEqual

        #check list of robots
        robot_list = self.client.StateClient.robots_list()
        self.assertIsInstance(robot_list, List)
        self.assertEqual(len(robot_list), 1)

        #do checks on the first robot instance
        robot = robot_list[0]

        #static test
        self.assertEqual(self.client.StateClient.instance_type(robot), 'Robot.instance')
        self.assertEqual(self.client.StateClient.robot_recharge_rate(robot), 0.8 )
        self.assertEqual(self.client.StateClient.robot_drain_rate(robot), 0.1)
        self.assertEqual(self.client.StateClient.robot_standard_speed(robot), 1.5625)

        self.assertEqual(self.client.StateClient.robot_coordinates(robot), [7.8,16.5])
        self.assertEqual(self.client.StateClient.robot_coordinates_tile(robot), [7,16])
        self.assertEqual(self.client.StateClient.robot_rotation(robot), 0)
        self.assertAlmostEqual(self.client.StateClient.robot_battery(robot), 1, delta=0.01)
        self.assertEqual(self.client.StateClient.robot_velocity(robot), [0,0])
        self.assertEqual(self.client.StateClient.robot_rotation_speed(robot), 0)
        self.assertEqual(self.client.StateClient.robot_in_station(robot), True)
        self.assertEqual(self.client.StateClient.robot_in_interact_areas(robot), [])

        self.assertEqual(self.client.StateClient.robot_closest_area(robot), 'parking_area0')
        self.assertEqual(self.client.StateClient.robot_location(robot),'parking_area0')


    def test_machine_state(self):
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'machine0' in state, timeout=10))
        self.client.StateClient.wait_next_dynamic_update(timeout=10)

        #check list of machines
        machines_list = self.client.StateClient.machines_list()
        self.assertIsInstance(machines_list, List)
        self.assertEqual(len(machines_list), 4)

        #do checks on the first machine instance
        machine = machines_list[0]
        self.assertEqual(self.client.StateClient.instance_type(machine), 'Machine.instance')

        self.assertEqual(self.client.StateClient.machine_coordinates(machine), [14.5, 5.5])
        self.assertEqual(self.client.StateClient.machine_coordinates_tile(machine), [14,5])
        self.assertEqual(self.client.StateClient.machine_input_belt(machine), 'belt0')
        self.assertEqual(self.client.StateClient.machine_output_belt(machine), 'belt1')
        self.assertEqual(self.client.StateClient.machine_processes_list(machine), [0,1,2])
        
    def test_belt_state(self):
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'belt0' in state, timeout=10))
        self.client.StateClient.wait_next_dynamic_update(timeout=10)

        #check list of belts
        belts_list = self.client.StateClient.belts_list()
        self.assertIsInstance(belts_list, List)
        self.assertEqual(len(belts_list), 6)

        #do checks on the first belt instance
        belt = belts_list[0]
        self.assertEqual(self.client.StateClient.instance_type(belt), 'Belt.instance')

        self.assertEqual(self.client.StateClient.belt_type(belt), 'input')
        self.assertEqual(self.client.StateClient.belt_polygons(belt), [[[9, 5], [14, 5], [14, 6], [9, 6]]])
        self.assertEqual(self.client.StateClient.belt_cells(belt), [[13, 5], [12, 5], [11, 5], [10, 5], [9, 5]])
        self.assertEqual(self.client.StateClient.belt_interact_areas(belt), ['interact_area0'])
        self.assertEqual(self.client.StateClient.belt_packages_list(belt), [])
        
    def test_parking_area_state(self):
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'parking_area0' in state, timeout=10))
        self.client.StateClient.wait_next_dynamic_update(timeout=10)

        #check list of parking_areas
        parking_areas_list = self.client.StateClient.parking_areas_list()
        self.assertIsInstance(parking_areas_list, List)
        self.assertEqual(len(parking_areas_list), 1)

        #do checks on the first parking_area instance
        parking_area = parking_areas_list[0]
        self.assertEqual(self.client.StateClient.instance_type(parking_area), 'Parking_area.instance')

        expected_polygons = [[[4, 18], [4, 16], [10, 16], [10, 18]],
                            [[21, 18], [21, 16], [26, 16], [26, 18]]]
        self.assertEqual(self.client.StateClient.parking_area_polygons(parking_area), expected_polygons)
        expected_cells = [[4, 16], [5, 16], [4, 17], [6, 16], [5, 17], [7, 16], [6, 17], [8, 16], [7, 17],
                         [9, 16], [8, 17], [9, 17], [21, 16], [22, 16], [21, 17], [23, 16], [22, 17], [24, 16],
                         [23, 17], [25, 16], [24, 17], [25, 17]]
        self.assertEqual(self.client.StateClient.parking_area_cells(parking_area), expected_cells)

    def test_interact_area_state(self):
        self.assertTrue(self.client.StateClient.wait_condition(lambda state : 'interact_area0' in state, timeout=10))

        self.client.StateClient.wait_next_dynamic_update(timeout=10)

        #check list of interact_areas
        interact_areas_list = self.client.StateClient.interact_areas_list()
        self.assertEqual(len(interact_areas_list), 6)

        #do checks on the first interact_area instance
        interact_area = interact_areas_list[0]
        self.assertIsInstance(interact_area, str)
        self.assertEqual(self.client.StateClient.instance_type(interact_area), 'Interact_area.instance')

        self.assertEqual(self.client.StateClient.interact_area_polygons(interact_area), [[[9, 6], [13, 6], [13, 7], [9, 7]]])
        self.assertEqual(self.client.StateClient.interact_area_cells(interact_area), [[12, 6], [11, 6], [10, 6], [9, 6]])
        self.assertEqual(self.client.StateClient.interact_area_belt(interact_area), 'belt0')

if __name__ == '__main__':
    unittest.main()
