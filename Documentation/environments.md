# Environment

The environment in which the robot moves, defined by a JSON file.

## File structure
```json
{
    "data": [...],
    "offset": [...]
}
```

## Fields
Field | Example of format | Description
---|---|---
Data | `[[tile_id,tile_id,...], ... ]`| 2D matrix of tile IDs, which are ints that can take the values -1, 3, 4, 5, 8, 9, 10, 11, 12, 13
Offset | `[x,y]` | Offset of the environment in meters

## Tile IDs
ID | Tile | Description
---|---|---
-1 | air | 
3 | floor |
4 | parking_area | 
5 | interact_area | if a group is not in contact with a belt, won't create an InteractArea
8 | wall | has collision, avoided by navigation
9 | machine | avoided by navigation
10 | input_belt | avoided by navigation. If not in contact with a machine, won't create a Belt
11 | output_belt | avoided by navigation. If not in contact with a machine, won't create a Belt
12 | input_machine | avoided by navigation
13 | output_machine | avoided by navigation

# Creating an environment

Environments can be created either manually, by writing inside a JSON file, or by using the TileWorldExporter node inside the Godot editor which exports the environment drawn inside the editor as a JSON file. In the main scene, the TileWorldExporter is a child of the WorldMap node. 

To create a new environment, first select the WorldMap and draw the environment with the tiles available. Then, select the TileWorldExporter and set the path to a JSON file (the file will be created if it doesn't exist already), and click the boolean property `Export Environment`.

If there was an error during the export, `Export Environment` will deactivate and output an error message in the console. Else, it will stay active.

## Important informations

The simulator can't create a navigation shape and will stop if any tile avoided by the navigation makes a loop, or if multiple machines close together make an enclosed area. This is due to the creation of the navigation shape being unable to handle holes in a shape. *This is an issue that should be resolved.*

Belts are created by getting the input and output belt tiles connected to a machine. Only one input_belt and output_belt can be created by machine - if multiple tiles of the same type of belt are connected to the machine, the first tile clockwise from the left will be used to create the belt. Belts are created as a series of straight lines, rotating clockwise from the left when hitting a wall. Belts take the number of tiles as their size, but it can also be defined by a scenario. *This is the intended behavior, but could be upgraded to support multiple belts*