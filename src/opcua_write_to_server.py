"""
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.

Authors: 
- Arjen Deetman
  3D Concrete Printing Research Group a Eindhoven University of Technology.
"""

import asyncio
import logging
import threading
from camera import Camera
from asyncua import Client, Node, ua

# CONSTANTS
SERVER_ENDPOINT = "opc.tcp://10.129.4.30:4840"
CAMERA_IP = "169.254.1.69"
DATABASE = "D:/GitHub/ConcreteCandyTracker/log/test.csv"

async def main():
    
    # Initiate the camera
    camera = Camera(CAMERA_IP)

    # Camera settings
    camera.set_roi(int(1936/2-848/2), 340, 848, 300)
    camera.set_white_balance_ratio(1.0, 0.545, 1.257)
    camera.set_whitepoint(0.938, 0.981, 1.070)
    camera.set_exposure_time(16000)
    camera.set_gain(2.70)
    
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
                node1 = client.get_node("ns=4;i=116")  #R0
                node2 = client.get_node("ns=4;i=94")   #R1
                node3 = client.get_node("ns=4;i=95")   #R2
                node4 = client.get_node("ns=4;i=96")   #R3
                node5 = client.get_node("ns=4;i=97")   #R4
                node6 = client.get_node("ns=4;i=98")   #R5
                node7 = client.get_node("ns=4;i=99")   #R6
                node8 = client.get_node("ns=4;i=100")  #R7
                node9 = client.get_node("ns=4;i=101")  #R8
                
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

                    await node1.write_value(value1)
                    await node2.write_value(value2)
                    await node3.write_value(value3)
                    await node4.write_value(value4)
                    await node5.write_value(value5)
                    await node6.write_value(value6)
                    await node7.write_value(value7)
                    await node8.write_value(value8)
                    await node9.write_value(value9)

                    await asyncio.sleep(1)
                    await client.check_connection() # Throws an exception if the connection is lost
                    
        except ua.UaError as e:
            logging.warning("An OPC UA error occurred: {}".format(e))
        except ConnectionError:
            logging.warning("Lost connection to OPC UA server: Reconnecting in 2 seconds")
            await asyncio.sleep(2)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main(), debug=False)