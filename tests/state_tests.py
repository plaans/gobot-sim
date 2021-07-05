from typing import List
import unittest
import time

from .SimulationTestBase import SimulationTestBase


class StateTest(SimulationTestBase):

    def test_package_state(self):
        time.sleep(1)
        package = self.client.StateClient.packages_list()[0]
        self.assertIsInstance(package, str)
        self.assertEqual(self.client.StateClient.instance_type(package), 'Package.instance')

        self.assertIsInstance(self.client.StateClient.package_location(package), str)
        self.assertIsInstance(self.client.StateClient.package_processes_list(package), List)

    def test_robot_state(self):
        time.sleep(1)
        robot = self.client.StateClient.robots_list()[0]
        self.assertIsInstance(robot, str)
        self.assertEqual(self.client.StateClient.instance_type(robot), 'Robot.instance')

        self.assertIsInstance(self.client.StateClient.robot_coordinates(robot), List)
        self.assertIsInstance(self.client.StateClient.robot_coordinates_tile(robot), List)
        self.assertNotEqual(self.client.StateClient.robot_rotation(robot), None) #cannot verify if float because it is transmitted as int when 0 for example
        self.assertNotEqual(self.client.StateClient.robot_battery(robot), None)
        self.assertIsInstance(self.client.StateClient.robot_velocity(robot), List)
        self.assertNotEqual(self.client.StateClient.robot_rotation_speed(robot), None)
        self.assertIsInstance(self.client.StateClient.robot_in_station(robot), bool)
        self.assertIsInstance(self.client.StateClient.robot_in_interact_areas(robot), List)


    def test_machine_state(self):
        time.sleep(1)
        machine = self.client.StateClient.machines_list()[0]
        self.assertIsInstance(machine, str)
        self.assertEqual(self.client.StateClient.instance_type(machine), 'Machine.instance')

        self.assertIsInstance(self.client.StateClient.machine_coordinates(machine), List)
        self.assertIsInstance(self.client.StateClient.machine_coordinates_tile(machine), List)
        self.assertIsInstance(self.client.StateClient.machine_input_belt(machine), str)
        self.assertIsInstance(self.client.StateClient.machine_output_belt(machine), str)
        self.assertIsInstance(self.client.StateClient.machine_processes_list(machine), List)
        
    def test_belt_state(self):
        time.sleep(1)
        belt = self.client.StateClient.belts_list()[0]
        self.assertIsInstance(belt, str)
        self.assertEqual(self.client.StateClient.instance_type(belt), 'Belt.instance')

        self.assertIsInstance(self.client.StateClient.belt_type(belt), str)
        self.assertIsInstance(self.client.StateClient.belt_polygons(belt), List)
        self.assertIsInstance(self.client.StateClient.belt_cells(belt), List)
        self.assertIsInstance(self.client.StateClient.belt_interact_areas(belt), List)
        self.assertIsInstance(self.client.StateClient.belt_packages_list(belt), List)
        
    def test_parking_area_state(self):
        time.sleep(1)
        parking_area = self.client.StateClient.parking_areas_list()[0]
        self.assertIsInstance(parking_area, str)
        self.assertEqual(self.client.StateClient.instance_type(parking_area), 'Parking_area.instance')

        self.assertIsInstance(self.client.StateClient.parking_area_polygons(parking_area), List)
        self.assertIsInstance(self.client.StateClient.parking_area_cells(parking_area), List)
  
    def test_interact_area_state(self):
        time.sleep(1)
        interact_area = self.client.StateClient.interact_areas_list()[0]
        self.assertIsInstance(interact_area, str)
        self.assertEqual(self.client.StateClient.instance_type(interact_area), 'Interact_area.instance')

        self.assertIsInstance(self.client.StateClient.interact_area_polygons(interact_area), List)
        self.assertIsInstance(self.client.StateClient.interact_area_cells(interact_area), List)
        self.assertIsInstance(self.client.StateClient.interact_area_belt(interact_area), str)

if __name__ == '__main__':
    unittest.main()
