import threading
import time
import unittest
import subprocess
import os

from ..clients.python_client.CompleteClient import CompleteClient

class JobshopDemonstration():

    def setUp(self):
        self.client = CompleteClient("localhost",10000)
        
        self.sim = subprocess.Popen([os.environ["GODOT_PATH"], "--main-pack", " Simulation-Factory-Godot/simu/simulation.pck",
            "--scenario", os.environ["GITHUB_WORKSPACE"] + "/simu/scenarios/new_scenario_multirobots.json", 
            "--environment", os.environ["GITHUB_WORKSPACE"] + "/simu/environments/env_6_machines.json",
            "--jobshop", os.environ["GITHUB_WORKSPACE"] + "/simu/jobshop/instances/ft06.txt",
            "--robot_controller", "teleport",])
            #"--robot_controller", "PF",])

        assert self.client.wait_for_server(10)

        self.stop_threads = threading.Event()
        self.threads = []

    def tearDown(self):
        
        #end remaining thread in case it was not already done
        self.stop_threads.set()
        for thread in self.threads:
            try:
                thread.join()
            except:
                pass
        
        self.client.kill()
        self.sim.kill()
        self.sim.wait()

    def run_demonstration(self):
        self.setUp()

        try:
            self.run_solver()
            self.load_jobshop()
            self.apply_solution()
            
        finally:
            self.tearDown()

    def apply_solution(self):
        #main loop where commands will be send to control the robots according to the solution given by the solver
        #wait until static information on robots is received (supposed to be received at same time for all robots so wait only for first robot)
        assert self.client.StateClient.wait_condition(lambda state : 'robot0' in state, timeout=10)
        self.robots_list = self.client.StateClient.robots_list()

        self.lock = threading.Lock()   
        self.packages_ready_lock = threading.Lock()    
        self.commands_to_be_done = []
        self.new_command_available = threading.Event()

        self.packages_ready = []
        self.client.StateClient.set_callback_package_ready(self.callback_package_ready)

        for robot in self.robots_list:
            new_thread = threading.Thread(target=self.robot_thread, args=[robot])
            new_thread.daemon = True
            self.threads.append(new_thread)
            new_thread.start()

        
        self.machines_progressions = [0 for k in range(self.nb_machines)] #id of next package in list of package to be processed by this machine

        self.jobs_progressions = [0 for k in range(self.nb_jobs)] #for each job (which corresponds to a package in the simulation), 
                                                            #id of the next task to be done, or a value of nb_machines if all tasks done
                                                            # and nb_machines+1 if the package has been delivered
        self.final_progressions = [self.nb_machines+1 for k in range(self.nb_jobs)] 
        timeout = 500
        start_time= time.time()

        self.packages_task_in_progress = [False for k in range(self.nb_jobs)] #used to know if each package is currently waiting to have a task done
                                                                            #which if true means in the queue of task to be done by robot there is one linked to this package
        
        #check inital packages created before callbakc was set
        initial_packages = self.client.StateClient.packages_list()
        self.packages_ready_lock.acquire()
        for package in initial_packages:
            if package not in self.packages_ready:
                self.packages_ready.append(package)
        self.packages_ready_lock.release()
        
        self.check_packages()

        for k in range(200):
            self.stop_threads.wait(1)
        #self.stop_threads.wait(200)

        self.stop_threads.set()
        for thread in self.threads:
                thread.join()

    def callback_package_ready(self, package_name):
        self.packages_ready_lock.acquire()
        self.packages_ready.append(package_name)
        self.packages_ready_lock.release()

        self.check_packages()

    def check_packages(self):
        #check all packages ready to see if their next task can be started
        self.packages_ready_lock.acquire()
        i = 0
        while i<len(self.packages_ready):
            package_name = self.packages_ready[i]
            package_id = self.package_id(package_name)
            #check next task for each jobs except job where all tasks have been done and package have been delivered
            if not(self.packages_task_in_progress[package_id]):

                if self.jobs_progressions[package_id] == self.nb_machines:
                    #case where all tasks have been done and the package needs to be delivered to the output_machine
                    output_machine = self.find_output_machine()
                    package_name = self.package_name(package_id)

                    is_ready_to_pick = self.client.StateClient.belt_type(self.client.StateClient.package_location(package_name)) == "output"

                    if is_ready_to_pick :
                        #self.carry_to_machine(package_name, output_machine)
                        self.packages_task_in_progress[package_id] = True
                        self.commands_to_be_done.append((package_id, -1))
                        self.new_command_available.set()

                        self.packages_ready.remove(package_name)
                        i -= 1
                    
                elif self.jobs_progressions[package_id] < self.nb_machines:
                    #case of standard task where the package needs to be delivered to the corresponding machine
                    package_name = self.package_name(package_id)

                    #find id of next machine the package needs to be processed by
                    job_content = self.machines[package_id] 
                    
                    machine_id = job_content[self.jobs_progressions[package_id]] -1 #- 1 because in jobshop file machines number start at 1
                    
                    machine_order = self.all_machines_order[machine_id]
                    machine_next_task = machine_order[self.machines_progressions[machine_id]]
                    
                    #check if this task is the next one for this machine in the order found by the solver
                    is_next_one = machine_next_task == (package_id,self.jobs_progressions[package_id])
                    #check that the package is ready to pick (if it is on an output belt)
                    is_ready_to_pick = self.client.StateClient.belt_type(self.client.StateClient.package_location(package_name)) == "output"

                    if is_next_one and is_ready_to_pick:
                        #self.carry_to_machine(package_name, machine_name)
                        self.packages_task_in_progress[package_id] = True
                        self.commands_to_be_done.append((package_id, machine_id))
                        self.new_command_available.set()

                        self.packages_ready.remove(package_name)
                        i -= 1

            i += 1

        self.packages_ready_lock.release()

    def robot_thread(self, robot_name):
        while not(self.stop_threads.is_set()) and self.new_command_available.wait(10):
            next_command = None
            self.lock.acquire()
            if self.commands_to_be_done != []:
                next_command = self.commands_to_be_done.pop(0)
            else :
                self.new_command_available.clear()
            self.lock.release()

            if next_command != None:
                package_id, machine_id = next_command
                package_name = self.package_name(package_id)

                machine_name = None
                if machine_id==-1: #codes for output machine
                    machine_name = self.find_output_machine()
                else:
                    machine_name = self.machine_name(machine_id)
                self.carry_to_machine(robot_name, package_name, machine_name)

                self.jobs_progressions[package_id] +=1
                if machine_id!=-1:
                    self.machines_progressions[machine_id] +=1
                    self.packages_task_in_progress[package_id] = False
                else:
                    #case of delivery, check if was last one
                    if self.jobs_progressions==self.final_progressions:
                        #if all package are done wait for this final one to be processed by the output_machine
                        assert self.client.StateClient.wait_condition(lambda state :  state[package_name]['Package.location'] == machine_name, timeout=100)
                        assert self.client.StateClient.wait_condition(lambda state : state[machine_name]['Machine.progress_rate'] == 1, timeout=100)
                        self.stop_threads.set()

            self.check_packages() #check packages since the next task might have become possible to do for some packages ready

    def package_id(self, package_name):
        return int(package_name[-1])
    
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

    def charge(self, robot):
        #makes the robot go to a charging area and wait until battery is full
        action_id = self.client.ActionClientManager.run_command(['go_charge',robot])
        assert self.client.ActionClientManager.wait_result(action_id, timeout=10)

        assert self.client.StateClient.wait_condition(lambda state : state[robot]['Robot.battery'] == 1, timeout=10)

    def position_robot_to_belt(self, robot, belt):
        #takes as argument a belt
        #makes the robot go to an interact area of the belt and face the belt
        interact_area = self.client.StateClient.belt_interact_areas(belt)[0]
        action_id = self.client.ActionClientManager.run_command(['navigate_to_area',robot, interact_area])
        assert self.client.ActionClientManager.wait_result(action_id, timeout=10)
        action_id = self.client.ActionClientManager.run_command(['face_belt',robot ,belt, 5])
        assert self.client.ActionClientManager.wait_result(action_id, timeout=10)

    def carry_to_machine(self, robot, package, machine):
        if self.client.StateClient.robot_battery(robot)<0.4:
            self.charge(robot)
        self.take_package(robot, package)
        self.deliver_package(robot, machine)

    def take_package(self, robot, package):

        belt = self.client.StateClient.package_location(package)
        self.position_robot_to_belt(robot, belt)
        action_id = self.client.ActionClientManager.run_command(['pick_package',robot, package])
        assert self.client.ActionClientManager.wait_result(action_id, timeout=10)

    def deliver_package(self, robot, machine):

        belt_in = self.client.StateClient.machine_input_belt(machine)
        self.position_robot_to_belt(robot, belt_in)
        action_id = self.client.ActionClientManager.run_command(['place',robot])
        assert self.client.ActionClientManager.wait_result(action_id, timeout=10)


if __name__ == '__main__':
    demo = JobshopDemonstration()   
    demo.run_demonstration()  
