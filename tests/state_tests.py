from typing import List
import unittest
import time

from .SimulationTestBase import SimulationTestBase


class StateTest(SimulationTestBase):

    def test_package_state(self):
        self.client.StateClient.wait_for_message('Package.instance', timeout=10)

        #check list of packages is a list and is not empty
        package_list = self.client.StateClient.packages_list()
        self.assertIsInstance(package_list, List)
        self.assertNotEqual(package_list, [])

        #do checks on the first package is in the list based on what is expected
        package = package_list[0]
        self.assertEqual(package, 'package0')
        self.assertEqual(self.client.StateClient.instance_type(package), 'Package.instance')

        #wait for package location information to be received since it comes after the first dynamic update
        self.client.StateClient.wait_for_message('Package.location', timeout=10)

        self.assertEqual(self.client.StateClient.package_location(package), 'input_machine0')
        self.assertEqual(self.client.StateClient.package_processes_list(package), [[0,10],[1,5]])

    def test_robot_state(self):
        self.client.StateClient.wait_for_message('Robot.instance', timeout=10)
        self.client.StateClient.wait_next_dynamic_update(timeout=10)

        #check list of robots
        robot_list = self.client.StateClient.robots_list()
        self.assertIsInstance(robot_list, List)
        self.assertEqual(len(robot_list), 1)

        #do checks on the first robot instance
        robot = robot_list[0]
        self.assertEqual(self.client.StateClient.instance_type(robot), 'Robot.instance')

        self.assertEqual(self.client.StateClient.robot_coordinates(robot), [7.8,16.5])
        self.assertEqual(self.client.StateClient.robot_coordinates_tile(robot), [7,16])
        self.assertEqual(self.client.StateClient.robot_rotation(robot), 0)
        self.assertEqual(self.client.StateClient.robot_battery(robot), 1)
        self.assertEqual(self.client.StateClient.robot_velocity(robot), [0,0])
        self.assertEqual(self.client.StateClient.robot_rotation_speed(robot), 0)
        self.assertEqual(self.client.StateClient.robot_in_station(robot), True)
        self.assertEqual(self.client.StateClient.robot_in_interact_areas(robot), [])


    def test_machine_state(self):
        self.client.StateClient.wait_for_message('Machine.instance', timeout=10)
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
        self.client.StateClient.wait_for_message('Belt.instance', timeout=10)
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
        self.client.StateClient.wait_for_message('Parking_area.instance', timeout=10)
        self.client.StateClient.wait_next_dynamic_update(timeout=10)

        parking_area = self.client.StateClient.parking_areas_list()[0]
        self.assertIsInstance(parking_area, str)
        self.assertEqual(self.client.StateClient.instance_type(parking_area), 'Parking_area.instance')

        self.assertIsInstance(self.client.StateClient.parking_area_polygons(parking_area), List)
        self.assertIsInstance(self.client.StateClient.parking_area_cells(parking_area), List)
  
    def test_interact_area_state(self):
        self.client.StateClient.wait_for_message('Interact_area.instance', timeout=10)
        self.client.StateClient.wait_next_dynamic_update(timeout=10)

        interact_area = self.client.StateClient.interact_areas_list()[0]
        self.assertIsInstance(interact_area, str)
        self.assertEqual(self.client.StateClient.instance_type(interact_area), 'Interact_area.instance')

        self.assertIsInstance(self.client.StateClient.interact_area_polygons(interact_area), List)
        self.assertIsInstance(self.client.StateClient.interact_area_cells(interact_area), List)
        self.assertIsInstance(self.client.StateClient.interact_area_belt(interact_area), str)

if __name__ == '__main__':
    unittest.main()
