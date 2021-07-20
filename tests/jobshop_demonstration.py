import time
import unittest
import subprocess
import os
import pprint

from ..clients.python_client.CompleteClient import CompleteClient

class OtherTest(unittest.TestCase):

    def setUp(self):
        self.client = CompleteClient("localhost",10000)
        
        self.sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", " Simulation-Factory-Godot/simu/simulation.pck",
            "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario_with_jobshop.json", 
            "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/env_6_machines.json",
            "--jobshop", os.environ["GITHUB_WORKSPACE"] + "/simu/jobshop/instances/ft06.txt"])

        self.assertTrue(self.client.wait_for_server(10))

    def tearDown(self):
        self.client.kill()
        self.sim.kill()
        self.sim.wait()

    def test_jobshop(self):
        self.run_solver()
        self.load_jobshop()

        machines_progressions = [0 for k in range(self.nb_machines)] #id of next package in list of package to be processed by this machine

        jobs_progressions = [0 for k in range(self.nb_jobs)] #for each job (which corresponds to a package in the simulation), id of the next task to be done
        final_progressions = [self.nb_machines for k in range(self.nb_jobs)] 
        timeout = 500
        start_time= time.time()

        while jobs_progressions!=final_progressions:
            for k in range(self.nb_machines):
                machine_order = self.all_machines_order[k]
                next_task = machine_order[machines_progressions[k]]
                #print(next_task)

                package_id = next_task[0] 
                package_name = self.package_name(package_id)
                task_nb = next_task[1]

                #check if this task is the next one to do for this package
                is_ready_for_task = jobs_progressions[package_id] == task_nb
                #check that the package is ready to pick (if it is on an output belt)
                is_ready_to_pick = self.client.StateClient.belt_type(self.client.StateClient.package_location(package_name)) == "output"

                if is_ready_for_task and is_ready_to_pick:
                    machine_name = self.machine_name(k)
                    self.carry_to_machine(package_name, machine_name)
                    machines_progressions[k] +=1




            current_time = time.time()
            if current_time - start_time >= timeout:
                break
            time.sleep(0.1)
        
    def package_name(self, package_id):
        return "package" + str(package_id)

    def machine_name(self, machine_id):
        return "machine" + str(machine_id)

    def load_jobshop(self):
        #load the jobshop file and parse it
        lines_split = []
        with open(os.environ["GITHUB_WORKSPACE"] + "/simu/jobshop/instances/ft06.txt") as f:
            line = f.readline()
            while line:
                lines_split.append(line.split(" "))
                line = f.readline()

        self.nb_jobs=int(lines_split[1][0])
        self.nb_machines=int(lines_split[1][1])

        self.times = []
        for k in range(3, 3 + self.nb_jobs):
            new_array = []
            for value in lines_split[k][:-1]:
                new_array.append(float(value))
            self.times.append(new_array)
				
        self.machines = []
        for k in range(4 + self.nb_jobs, 4 + 2*self.nb_jobs):
            new_array = []
            for value in lines_split[k][:-1]:
                new_array.append(int(value))
            self.machines.append(new_array)

        #pprint.pprint( "times : {}".format(self.times))
        #pprint.pprint( "machines : {}".format(self.machines))


    def run_solver(self):
        subprocess.run(["aries/target/release/jobshop",
        os.environ["GITHUB_WORKSPACE"] + "/simu/jobshop/instances/ft06.txt", "-o", "solution.txt"], stdout=subprocess.PIPE)

        self.all_machines_order = []
        with open('solution.txt') as f:
            line = f.readline()
            while line:
                machine_order = []
                print( line)
                line_split = line.split("\t")
                for element in line_split[1:-1]:
                    job, task = int(element[1]), int(element[4])
                    machine_order.append((job, task))
                line = f.readline()   
                self.all_machines_order.append(machine_order)


        #print( self.all_machines_order)

        


    def d_test_jobshop(self):
        #wait for information on the first package to be received
        self.client.StateClient.wait_for_message('Package.instance', timeout=10)
        self.client.StateClient.wait_for_message('Package.location', timeout=10)
        packages_list = self.client.StateClient.packages_list()

        #do each package one by one
        k=0
        while k<len(packages_list):
            target_package = packages_list[k]
            #first pick the package at the input machine 
            self.take_package(target_package)

            #then do the processes
            while len(self.client.StateClient.package_processes_list(target_package)) > 0:
                self.do_next_process(target_package)

            #then deliver at the output machine
            output_machine = self.find_output_machine()
            self.deliver_package(output_machine)

            packages_list = self.client.StateClient.packages_list()#update list to include new packages
            k += 1

    def find_machine_for_process(self, process_id):
        #finds a machine that can do the process specified
        machines_list = self.client.StateClient.machines_list()
        for machine in machines_list :
            possible_processes = self.client.StateClient.machine_processes_list(machine)
            if process_id in possible_processes:
                return machine

    def find_output_machine(self):
        machines_list = self.client.StateClient.machines_list()
        for machine in machines_list :
            if self.client.StateClient.machine_type(machine) == 'output_machine':
                return machine

    def charge(self):
        #makes the robot go to a charging area and wait until battery is full
        action_id = self.client.ActionClientManager.run_command(['go_charge','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        self.client.StateClient.wait_for_message('Robot.battery', instance_name = 'robot0', value=1, timeout=10)

    def position_robot_to_belt(self, belt):
        #takes as argument a belt
        #makes the robot go to an interact area of the belt and face the belt
        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]
        action_id = self.client.ActionClientManager.run_command(['navigate_to_area','robot0', interact_area])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))
        action_id = self.client.ActionClientManager.run_command(['face_belt', 'robot0',belt, 5])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

    def carry_to_machine(self, package, machine):
        if self.client.StateClient.robot_battery('robot0')<0.4:
            self.charge()
        self.take_package(package)
        self.deliver_package(machine)

    def take_package(self, package):

        belt = self.client.StateClient.package_location(package)
        self.position_robot_to_belt(belt)
        action_id = self.client.ActionClientManager.run_command(['pick_package','robot0', package])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

    def deliver_package(self, machine):
        #takes as argument a package carried by the robot and a machine to deliver it to 

        belt_in = self.client.StateClient.machine_input_belt(machine)
        self.position_robot_to_belt(belt_in)
        action_id = self.client.ActionClientManager.run_command(['place','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))


    def do_next_process(self, package):
        #takes as argument a package with a at least one process left to do, being currently carried by the robot
        #brings the package to a machine that can do the next process and wait until it is done then pick it up again

        if self.client.StateClient.robot_battery('robot0')<0.4:
            self.charge()

        #find a machine for the process and bring the package to its input belt
        process_to_do = self.client.StateClient.package_processes_list(package)[0][0]
        machine = self.find_machine_for_process(process_to_do)
        belt_in = self.client.StateClient.machine_input_belt(machine)

        self.position_robot_to_belt(belt_in)
        action_id = self.client.ActionClientManager.run_command(['place','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        #wait for the machine to process the package
        belt_out = self.client.StateClient.machine_output_belt(machine)
        self.client.StateClient.wait_for_message('Package.location', instance_name = package, value=belt_out, timeout=100)

        #pick the package from the machine output belt
        self.position_robot_to_belt(belt_out)
        action_id = self.client.ActionClientManager.run_command(['pick','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

if __name__ == '__main__':
    unittest.main()      
