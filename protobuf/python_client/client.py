import socket
import sys
import messages_pb2

import math

import socket
import sys

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect the socket to the port where the server is listening
server_address = ('localhost', 10000)
print('connecting to {} port {}'.format(*server_address))
sock.connect(server_address)

def goto_stand(direction_x,direction_y):
    #given robot position and position of stand to go to computes and sends instructions to move it to objective
    #then issue goto command
    Command = messages_pb2.Command()
    Command.command = messages_pb2.Command.Command_types.GOTO
    
    if direction_y==0:
        angle = 0
    else :
        angle = math.acos( direction_x / math.sqrt(distance) ) 
        if direction_y<0 and direction_x!=0:
            angle -= math.pi/2 * direction_x/abs(direction_x)
        
    speed = 50.
    time = (math.sqrt(distance)-90)/speed
    
    Command.dir = angle
    Command.speed = speed
    Command.time = time

    message = Command.SerializeToString()
    print('envoi commande goto avec parametres {} {} {}'.format(angle,speed,time))
    length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
    sock.sendall(length + message)
    
    return
    

try:

    
    destination_stand = None

    while True:
        data = sock.recv(4)
        if len(data)>0:
            size = int.from_bytes(data,'little')
            data = sock.recv(size)
            state = messages_pb2.State()
            state.ParseFromString(data)
            #print(state) 
            
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
                        
                        
            if not(state.is_moving[0]):
                #send a command only if robot not already moving
                
                package = state.packages_locations[0]
                if package.location_type == messages_pb2.State.Location.Type.STAND:
                    
                    #case where the package is on a stand so needs to be picked up if not destination_stand
                    if package.location_id != destination_stand:
                        pos_x = state.robots_x[0]
                        pos_y = state.robots_y[0]
                        stand_x = state.stands_x[package.location_id]
                        stand_y = state.stands_y[package.location_id]
                        distance = (stand_x-pos_x)**2 + (stand_y-pos_y)**2
                        
                        if distance > 100**2: #compare to pickup radius, will need to take the right value later
                                
                            direction_x = stand_x - pos_x
                            direction_y = stand_y - pos_y
                            goto_stand(direction_x,direction_y)
                            
                        else:
                            #already close enough so send pickup command
                            Command = messages_pb2.Command()
                            Command.command = messages_pb2.Command.Command_types.PICKUP
                            #pas besoin de specifier d'autres parametres pour une commande de type pickup
                            message = Command.SerializeToString()

                            length = len(message).to_bytes(4,'little') #4bytes because sending as int32 
                            sock.sendall(length + message)
    
                else:
                    #case where the robot already picked up the package so needs to deliver it to the objective
                    pos_x = state.robots_x[0]
                    pos_y = state.robots_y[0]
                    stand_x = state.stands_x[destination_stand]
                    stand_y = state.stands_y[destination_stand]
                    distance = (stand_x-pos_x)**2 + (stand_y-pos_y)**2
                    
                    if distance > 100**2: #compare to pickup radius, will need to take the right value later
                            
                        direction_x = stand_x - pos_x
                        direction_y = stand_y - pos_y
                        goto_stand(direction_x,direction_y)
                        
                    else:
                        #already close enough so send pickup command (this time it will have the effect to drop and not pick up)
                        Command = messages_pb2.Command()
                        Command.command = messages_pb2.Command.Command_types.PICKUP
                        #pas besoin de specifier d'autres parametres pour une commande de type pickup
                        message = Command.SerializeToString()

                        length = len(message).to_bytes(4,'little') #4bytes because sending as int32  
                        sock.sendall(length + message)

finally:
    print('closing socket')
    sock.close()
    


