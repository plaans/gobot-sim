# Scenarios

JSON files defining the objects in the simulation and their properties.

## File structure
```json
{
	"robots": [
		{
            "position": [...],

            "max_battery": ...,
            "battery_drain_rate": ...,
            "battery_charge_rate": ...,
        }
	],
	"machines": [
		{
            "position": [...],
            "possible_processes": [...],

            "input_belt_size": ...,
            "output_belt_size": ...
        }
	],
    "input_machines":[
        {
            "position": [...],
            "packages": [...],

            "infinite": ..., 
            "create_order": ..., 
            "create_time": ..., 
            "time_step": ...,
            "output_belt_size": ...
        }
    ],
    "output_machines":[
        {
            "position": [...],

            "time_step": ...,
            "input_belt_size": ...
        }
    ],
	"packages":[...],
	"environment": "..."
}
```

## Fields
Field | Example of format | Description
---|---|---
*(legacy)* Packages | `[[[process_id, process_time],[...], ...], ...]` | array of package templates, made of multiple processes defined by an array of a process ID and their processing time. This field will be used instead when no InputMachine is defined in the scenario (legacy format) or when an InputMachine doesn't specify an array of packages
Environment | `"res://path/to/environment"` | path to the environment file.

### Robots
Field | Example of format | Description
---|---|---
Position | `[x,y]` | Position of the robot in meters
*(optional)* Max Battery | `max_battery` | float
*(optional)* Battery Drain Rate | `battery_drain_rate` | float between 0 and 1
*(optional)* Battery Charge Rate | `battery_charge_rate` | float between 0 and 1

### Machines
Field | Example of format | Description
---|---|---
Position | `[x,y]` | Position to search for the machine
Possible Processes | `[process_id, ...]` | array of ints, process IDs the machine can process.
*(optional)* Input Belt Size | `input_belt_size` | int, overrides the size of the belt calculated from its number of tiles
*(optional)* Output Belt Size | `output_belt_size` | int, overrides the size of the belt calculated from its number of tiles

### *(Optional)* InputMachines
Field | Example of format | Description
---|---|---
Position | `[x,y]` | Position to search for the machine
Packages | `[[[process_id, process_time],[...], ...], ...]` | array of package templates, made of multiple processes defined by an array of a process ID and their processing time.
*(optional)* Infinite | `infinite` | boolean
*(optional)* Create Order | `create_order` | int, can only take the values 0, 1, 2 for NORMAL, REVERSED and RANDOM
*(optional)* Create Time | `create_time` | int, can only take the values 0, 1 for FIXED and RANDOM
*(optional)* Time Step | `time_step` | float, time it takes to create a new package
*(optional)* Output Belt Size | `output_belt_size` | int, overrides the size of the belt calculated from its number of tiles

### *(Optional)* OutputMachines
Field | Example of format | Description
---|---|---
Position | `[x,y]` | Position to search for the machine
*(optional)* Time Step | `time_step` | float, time it takes to delete a package
*(optional)* Input Belt Size | `input_belt_size` | int, overrides the size of the belt calculated from its number of tiles