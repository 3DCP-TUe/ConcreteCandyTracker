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

"""Connects a camera to an external OPC UA server for data acquisition.

Connects to an external OPC UA server, captures color values, and writes them to the 
server (e.g., an industrial PLC).

Dependencies:
- asyncua: Set up an OPC UA server. 
"""

import asyncio
import logging
import threading
from camera import Camera
from asyncua import Client, ua

# CONSTANTS
SERVER_ENDPOINT = "opc.tcp://10.129.4.30:4840"
CAMERA_IP = "10.129.4.180"
DATABASE = "D:/GitHub/ConcreteCandyTracker/log/test.csv"

async def main():
    
    # Initiate the camera
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

    while True:

        # Get the server client
        client = Client(url=SERVER_ENDPOINT)

        try:
            async with client:

                # Get the free programmable parameters
                nodes = [
                    client.get_node("ns=4;i=116"),  # R0
                    client.get_node("ns=4;i=94"),   # R1
                    client.get_node("ns=4;i=95"),   # R2
                    client.get_node("ns=4;i=96"),   # R3
                    client.get_node("ns=4;i=97"),   # R4
                    client.get_node("ns=4;i=98"),   # R5
                    client.get_node("ns=4;i=99"),   # R6
                    client.get_node("ns=4;i=100"),  # R7
                    client.get_node("ns=4;i=101")   # R8
                ]

                while True:
                    value1 = ua.DataValue(ua.Variant(camera.r, ua.VariantType.Float))
                    value2 = ua.DataValue(ua.Variant(camera.g, ua.VariantType.Float))
                    value3 = ua.DataValue(ua.Variant(camera.b, ua.VariantType.Float))
                    value4 = ua.DataValue(ua.Variant(camera.x, ua.VariantType.Float))
                    value5 = ua.DataValue(ua.Variant(camera.y, ua.VariantType.Float))
                    value6 = ua.DataValue(ua.Variant(camera.z, ua.VariantType.Float))
                    value7 = ua.DataValue(ua.Variant(camera.l_star, ua.VariantType.Float))
                    value8 = ua.DataValue(ua.Variant(camera.a_star, ua.VariantType.Float))
                    value9 = ua.DataValue(ua.Variant(camera.b_star, ua.VariantType.Float))

                    await client.write_values(nodes, [value1, value2, value3, value4, value5, value6, value7, value8, value9])

                    await asyncio.sleep(1)
                    await client.check_connection() # Throws an exception if the connection is lost
                    
        except ua.UaError as e:
            logging.warning("An OPC UA error occurred: {}".format(e))
        except ConnectionError:
            logging.warning("Lost connection to OPC UA server: Reconnecting in 2 seconds")
            await asyncio.sleep(2)


if __name__ == "__main__":
    logging.getLogger('asyncua').setLevel(logging.WARNING)
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main(), debug=False)