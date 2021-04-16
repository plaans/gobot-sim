## Running the simulation

This explains how to run the simulation from command line (it focuses on running the project directly without exporting it, the document will be updated after having exported the project)

To run the project, download the Godot executable (either the normal version or the server version to run without a window) and, assuming the executable is named godot and is in PATH, run :

`$godot --path project_path`, where project_path is the path of the project folder. Several arguments can be added afterwards :

- `--port` followed by the port on which to open the TCP server used for the communication interface (the default value is 10000)

- `--pickup-radius` followed by the value of the maximum radius at which robots can pickup and drop packages
 
- `--seed` followed by the seed to use for the random number generation done in the program

- `--log` followed by the file location to which the logs need to be saved