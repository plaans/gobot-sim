## Communication interface

The engine runs a TCP server and communicates with Protocol Buffers. It sends a State format that describes the state of the world at a given time and receives a Command format that contains commands to be run in the simulation (see protobuf/messages.proto for the definition of these formats).

When running the simulation through command line, the argument --port can be used to specify the port to be used for the server (if not specified the default is 10000).
