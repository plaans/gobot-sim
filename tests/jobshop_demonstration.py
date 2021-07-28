import time
import unittest
import subprocess
import os

from ..clients.python_client.CompleteClient import CompleteClient

class OtherTest(unittest.TestCase):

    def setUp(self):
        self.client = CompleteClient("localhost",10000)
        
        self.sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", " Simulation-Factory-Godot/simu/simulation.pck",
            "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario_with_jobshop.json", 
            "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/env_6_machines.json",
            "--jobshop", os.environ["GITHUB_WORKSPACE"] + "/simu/jobshop/instances/ft06.txt",
            "--robot_controller", "teleport",])

        self.assertTrue(self.client.wait_for_server(10))

    def tearDown(self):
        self.client.kill()
        self.sim.kill()
        self.sim.wait()

    def test_jobshop(self):
        self.run_solver()
        self.load_jobshop()

        machines_progressions = [0 for k in range(self.nb_machines)] #id of next package in list of package to be processed by this machine

        jobs_progressions = [0 for k in range(self.nb_jobs)] #for each job (which corresponds to a package in the simulation), 
                                                             #id of the next task to be done, or a value of nb_machines if all tasks done
                                                             # and nb_machines+1 if the package has been delivered
        final_progressions = [self.nb_machines+1 for k in range(self.nb_jobs)] 
        timeout = 500
        start_time= time.time()

        while jobs_progressions!=final_progressions:
            for package_id in range(self.nb_jobs):
                #check next task for each jobs except job where all tasks have been done and package have been delivered
                if jobs_progressions[package_id] == self.nb_machines:
                    #case where all tasks have been done and the package needs to be delivered to the output_machine
                    output_machine = self.find_output_machine()
                    package_name = self.package_name(package_id)

                    is_ready_to_pick = self.client.StateClient.belt_type(self.client.StateClient.package_location(package_name)) == "output"

                    if is_ready_to_pick :
                        self.carry_to_machine(package_name, output_machine)
                        jobs_progressions[package_id] +=1

                        #if all package are done wait for this final one to be processed by the output_machine
                        if jobs_progressions==final_progressions:
                            self.assertTrue(self.client.StateClient.wait_condition(lambda state :  state[package_name]['Package.location'] == output_machine, timeout=100))
                            self.assertTrue(self.client.StateClient.wait_condition(lambda state : state[output_machine]['Machine.progress_rate'] == 1, timeout=100))

                elif jobs_progressions[package_id] < self.nb_machines:
                    #case of standard task where the package needs to be delivered to the corresponding machine
                    package_name = self.package_name(package_id)

                    #find id of next machine the package needs to be processed by
                    job_content = self.machines[package_id] 
                    
                    machine_id = job_content[jobs_progressions[package_id]] -1 #- 1 because in jobshop file machines number start at 1
                    
                    machine_name = self.machine_name(machine_id)
                    machine_order = self.all_machines_order[machine_id]
                    machine_next_task = machine_order[machines_progressions[machine_id]]
                    
                    #check if this task is the next one for this machine in the order found by the solver
                    is_next_one = machine_next_task == (package_id,jobs_progressions[package_id])
                    #check that the package is ready to pick (if it is on an output belt)
                    is_ready_to_pick = self.client.StateClient.belt_type(self.client.StateClient.package_location(package_name)) == "output"

                    if is_next_one and is_ready_to_pick:
                        self.carry_to_machine(package_name, machine_name)
                        machines_progressions[machine_id] +=1
                        jobs_progressions[package_id] +=1


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



    def find_output_machine(self):
        machines_list = self.client.StateClient.machines_list()
        for machine in machines_list :
            if self.client.StateClient.machine_type(machine) == 'output_machine':
                return machine

    def charge(self):
        #makes the robot go to a charging area and wait until battery is full
        action_id = self.client.ActionClientManager.run_command(['go_charge','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))

        self.assertTrue(self.client.StateClient.wait_condition(lambda state : state['robot0']['Robot.battery'] == 1, timeout=10))

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

        belt_in = self.client.StateClient.machine_input_belt(machine)
        self.position_robot_to_belt(belt_in)
        action_id = self.client.ActionClientManager.run_command(['place','robot0'])
        self.assertTrue(self.client.ActionClientManager.wait_result(action_id, timeout=10))


if __name__ == '__main__':
    unittest.main()      
