# Simulation-Factory-Godot

This project is a robotics simulator made with Godot game engine.

The scenarios modeled correspond to a general case of a factory, with packages needing to be processed by machines.  The role of robots is to move and carry packages to bring them to machines.

The simulator uses a high level of abstraction, without taking into account fine aspects. As examples, the environment is modeled in 2D, and the physics of robots (for example manipulation of objects) are also greatly simplified. 

For more information on differents parts of the simulator, please see the files in the [Documentation](Documentation) folder.




## Running the project

There are several possibilities :
- Directly run the project as is, using the Godot game engine
- Exporting the project as a package (unique file), and run this package using the Godot game engine
- Exporting the project as a binary

In all cases, the project can be run from command line  with arguments. For more details on the step of running the project, see [Running the simulation](Documentation/run_simulation.md) file. This contains more information about the command used to run the project, as well as the arguments that can be used.


## How to export

The first and easiest option to export is to directly open the project through the Godot editor, and use the exporting option (located in 'Project' options at the top of the editor). This opens the export menu where export templates can be directly downloaded, and the project can be exported as either a package or a binary file.


It is also possible to export directly from command line. For that, it is necessary to download both the Godot game engine (standard or headless versions can export), as well as the necessary export templates depending on the platform. Both download are available on the [official Downloads page](https://godotengine.org/download).

Then, run the Godot binary with the `--export` or `--export-debug` command line parameters, then the name of the export preset and the destination file. If the binary is being run from a location different than the project, the project location can be specified with `--path project_path`, where project_path is the path of the project folder (the folder containing the project.godot file, which corresponds to the simu folder in the repository).

The export preset argument must correspond to an existing preset that has been defined, with the corresponding template available. For more details on exporting projects, see the ['Exporting projects' page in Godot documentation](https://docs.godotengine.org/en/stable/getting_started/workflow/export/exporting_projects.html).

An example of command to export as a .pck package file is :

    $GODOT_PATH --export "Linux/X11" simulation.pck

This command is used in CI to export the project before running tests.
