## Running the simulation

This document explains how to run the simulation from command line. For a more detailed documentation, see [Command line tutorial](https://docs.godotengine.org/en/stable/getting_started/editor/command_line_tutorial.html)

If running the project without exporting it, download the Godot executable (either the standard version or the server version to run without a window) and, assuming the executable is named godot, run :

`$godot --path project_path`, where project_path is the path of the project folder. Several arguments can be added afterwards :

- `--scenario` followed by the file to use as scenario in the simulation (the file must be a json file, see scenarios folder for examples)

- `--port` followed by the port on which to open the TCP server used for the communication interface (the default value is 10000)
 
- `--seed` followed by the seed to use for the random number generation done in the program

- `--log` followed by the file location to which the logs need to be saved

- `--environment` followed by the file to use as an environment, overriding the environment defined in the scenario

If the project has been exported, either directly run the executable obtained, or use the same command as before but instead of specifying the project path with `--path` use `--main-pack` to specify the package file obtained when exporting (.pck file). In both cases the same arguments as before can be used (`--scenario`, `--port`, etc.)
