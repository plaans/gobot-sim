import socket
import sys
import messages_pb2
#command = fichier_pb2.command()
#command.command="goto"
#command.posx = 70
#command.posy = 50

import math

import socket
import sys

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect the socket to the port where the server is listening
server_address = ('localhost', 10000)
print('connecting to {} port {}'.format(*server_address))
sock.connect(server_address)

try:

    

    # Send data
    
    Command = messages_pb2.Command()
    Command.command = messages_pb2.Command.Command_types.PICKUP

    message = Command.SerializeToString()
    print('sending {!r}'.format(message))
    print(len(message))
    length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
    print(length)
    print(message)
    #sock.sendall(length)
    sock.sendall(length + message)
    
        # Look for the response
    amount_received = 0
    #amount_expected = len(message)
    
    destination_stand = None

    while True:
        data = sock.recv(4)
        if len(data)>0:
            size = int.from_bytes(data,'little')
            #print('received {!r}'.format(size))
            data = sock.recv(size)
            #print('received {!r}'.format(data))
            state = messages_pb2.State()
            state.ParseFromString(data)
            print(state) 
            #print('robotx :{}, roboty :{}, packagelocation :{}'.format(message.robots_x,message.robots_y,message.packages_location))
            
            if destination_stand == None:
                #then we will fix the destination_stand to the farthest stand 
                stands_x = state.stands_x
                stands_y = state.stands_y
                dist_max=0
                pos_x = state.robots_x[0]
                pos_y = state.robots_y[0]
                for k in range(len(stands_x)):
                    x = stands_x[k]
                    y = stands_y[k]
                    dist = (x-pos_x)**2 + (y-pos_y)**2
                    if dist >= dist_max:
                        dist_max = dist
                        destination_stand = k #index of corresponding stand
            print(state.is_moving[0]) 			
            if not(state.is_moving[0]):
                #send a command only if robot not already moving
                package = state.packages_locations[0]
                print(destination_stand)  
                if package.location_type == messages_pb2.State.Location.Type.STAND:
                    
                    #case where the package is on a stand so needs to be picked up if not destination_stand
                    if package.location_id != destination_stand:
                        pos_x = state.robots_x[0]
                        pos_y = state.robots_y[0]
                        print(package) 
                        stand_x = state.stands_x[package.location_id]
                        stand_y = state.stands_y[package.location_id]
                        distance = (stand_x-pos_x)**2 + (stand_y-pos_y)**2
                        print(distance)
                        if distance > 100**2: #compare to pickup radius, will need to take the right value later
                            
                            #then issue goto command
                            Command = messages_pb2.Command()
                            Command.command = messages_pb2.Command.Command_types.GOTO
							
                            direction_x = stand_x - pos_x
                            direction_y = stand_y - pos_y
                            
                            if direction_x==0:
                                angle = math.pi 
                            elif direction_y ==0:
                                angle =0
                            else :
                                angle = math.acos( abs(direction_x) / math.sqrt(distance) ) 
                                
                            speed = 50.
                            time = math.sqrt(distance)/speed
                            
                            Command.dir = angle
                            Command.speed = speed
                            Command.time = time

                            message = Command.SerializeToString()
                            print('envoi commande goto avec parametres {} {} {}'.format(angle,speed,time))
                            print('sending {}'.format(message))
                            print(len(message))
                            length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
                            print(length)
                            print(message)
                            #sock.sendall(length)
                            sock.sendall(length + message)

finally:
    print('closing socket')
    sock.close()