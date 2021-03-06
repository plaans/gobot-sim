## Running the simulation

This document explains how to run the simulation from command line. For a more detailed documentation, see [Command line tutorial](https://docs.godotengine.org/en/stable/getting_started/editor/command_line_tutorial.html)

### Without exporting

If running the project without exporting it, download the Godot binary (either the standard version or the headless/server versions to run without a window) and, assuming the binary is named godot, `godot --path project_path`, where project_path is the path of the project folder (the folder containing the project.godot file, which corresponds to the simu folder in the repository). 

### From an exported package file

If it has been exported as a package file, use the same command as before but instead of specifying the project path with `--path` use `--main-pack` to specify the package file obtained when exporting (.pck file). 

### From an exported binary

If the project has been exported as an binary, simply run the file obtained. 

### Arguments

In all cases, several arguments can be added afterwards :
- `--scenario` followed by the file to use as scenario in the simulation (the file must be a json file, see scenarios folder for examples)

- `--environment` followed by the file to use as an environment, overriding the environment defined in the scenario

- `--jobshop` followed by a file defining a jobshop instance to use the simulation in jobshop mode

- `--port` followed by the port on which to open the TCP server used for the communication interface (the default value is 10000)
 
- `--seed` followed by the seed to use for the random number generation done in the program

- `--log` followed by the file location to which the logs need to be saved

- `--time_scale` to change the speed of the simulation (value is a float, with 1 being the default speed)

- `--robot_controller` to choose the controller used for robot movement, can be "none" for no local collision avoidance, "PF" for local collision avoidance using potential fields, and "teleport" for the robot to instantaneously teleport to the destination. Note that the collisions between robots will only be active when using "PF" 
  




### About collisions

Note that even when using the local collision avoidance using potential fields as a controller, collisions sometimes happen. This is particularly the case when raising the speed of the simulation by using the `--time_scale` argument. When collisions happen they are displayed as a Warning by the Logger, and the robots try continuing their movemement.
