# SPDX-License-Identifier: GPL-3.0-or-later
# Concrete Candy Tracker
# Project: https://github.com/3DCP-TUe/ConcreteCandyTracker
#
# Copyright (c) 2023-2025 Endhoven University of Technology
#
# Authors:
#   - Arjen Deetman (2023-2025)
#
# For license details, see the LICENSE file in the project root.

"""Sets up and connects a camera to a local OPC UA server for data acquisition.

Sets up a local OPC UA server, captures color values, and makes them available for 
external access.

Dependencies:
- asyncua: Set up an OPC UA server. 
"""

import asyncio
import logging
import threading
from camera import Camera
from asyncua import Server, ua

# CONSTANTS
CAMERA_IP = "10.129.4.180"
DATABASE = "D:/GitHub/ConcreteCandyTracker/log/test.csv"

async def main():
    
    # Setup the server
    logging.info("Starting the OPC UA server.")
    server = Server()
    await server.init()
    server.set_endpoint("opc.tcp://0.0.0.0:4840/concrete_candy_tracker/")
    server.set_server_name("Concrete Candy Tracker")

    # Set up the name space
    uri = "http://examples.freeopcua.github.io"
    idx = await server.register_namespace(uri)

    # Populate
    myobj = await server.nodes.objects.add_object(idx, "Color values")
    myvar_r = await myobj.add_variable(idx, "R", 0.0, varianttype=ua.VariantType.Double)
    myvar_g = await myobj.add_variable(idx, "G", 0.0, varianttype=ua.VariantType.Double)
    myvar_b = await myobj.add_variable(idx, "B", 0.0, varianttype=ua.VariantType.Double)
    myvar_x = await myobj.add_variable(idx, "X", 0.0, varianttype=ua.VariantType.Double)
    myvar_y = await myobj.add_variable(idx, "Y", 0.0, varianttype=ua.VariantType.Double)
    myvar_z = await myobj.add_variable(idx, "Z", 0.0, varianttype=ua.VariantType.Double)
    myvar_l_star = await myobj.add_variable(idx, "L*", 0.0, varianttype=ua.VariantType.Double)
    myvar_a_star = await myobj.add_variable(idx, "a*", 0.0, varianttype=ua.VariantType.Double)
    myvar_b_star = await myobj.add_variable(idx, "b*", 0.0, varianttype=ua.VariantType.Double)

    # Node ID
    logging.info("Object info       : {}".format(myobj))
    logging.info("Node ID of 'R'    : {}".format(myvar_r.nodeid.to_string()))
    logging.info("Node ID of 'G'    : {}".format(myvar_g.nodeid.to_string()))
    logging.info("Node ID of 'B'    : {}".format(myvar_b.nodeid.to_string()))
    logging.info("Node ID of 'X'    : {}".format(myvar_x.nodeid.to_string()))
    logging.info("Node ID of 'Y'    : {}".format(myvar_y.nodeid.to_string()))
    logging.info("Node ID of 'Z'    : {}".format(myvar_z.nodeid.to_string()))
    logging.info("Node ID of 'L*'   : {}".format(myvar_l_star.nodeid.to_string()))
    logging.info("Node ID of 'a*'   : {}".format(myvar_a_star.nodeid.to_string()))
    logging.info("Node ID of 'b*'   : {}".format(myvar_b_star.nodeid.to_string()))

    # Initiate the camera
    logging.info("Starting the camera")
    
    camera = Camera(CAMERA_IP)

    # Camera settings
    camera.set_roi(int(1936/2-848/2), 340, 848, 300)
    camera.set_white_balance_ratio(1.0, 0.551, 1.287)
    camera.set_whitepoint(0.9313, 0.9716, 1.0598)
    camera.set_exposure_time(16000)
    camera.set_gain(3.95)

    # Camera network settings   
    camera.set_packet_size(8192)
    camera.set_inter_packet_delay(7643)
    
    # Write color values to CSV database
    camera.set_database_path(DATABASE)
    camera.write_to_database = True
    
    # Start data acquisiton
    event = threading.Event()
    thread = threading.Thread(target=camera.start_grabbing, args=(event,))
    thread.start()
    
    async with server:
        
        while True:
            
            logging.info("The OPC UA server is still running...")
            
            await myvar_r.write_value(camera.r)
            await myvar_g.write_value(camera.g)
            await myvar_b.write_value(camera.b)

            await myvar_x.write_value(camera.x)
            await myvar_y.write_value(camera.y)
            await myvar_z.write_value(camera.z)

            await myvar_l_star.write_value(camera.l_star)
            await myvar_a_star.write_value(camera.a_star)
            await myvar_b_star.write_value(camera.b_star)
            
            await asyncio.sleep(1.0)


if __name__ == "__main__":
    logging.getLogger('asyncua').setLevel(logging.WARNING)
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main(), debug=False)