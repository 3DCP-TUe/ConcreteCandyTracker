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

async def main():
    
    # Logger
    logger = logging.getLogger(__name__)

    # Initiate the camera
    camera = Camera('169.254.1.69')

    # Camera settings
    camera.set_roi(int(1936/2-848/2), 340, 848, 300)
    camera.set_white_balance_ratios(1.0, 0.545, 1.257)
    camera.set_whitepoint(0.938, 0.981, 1.070)
    camera.set_exposure_time(16000)
    camera.set_gain(2.70)
    
    # Collect data
    event = threading.Event()
    thread = threading.Thread(target=camera.start_grabbing, args=(event,))
    thread.start()

    while True:

        # Material delivery PLC / Sensing station
        client = Client(url="opc.tcp://10.129.4.30:4840")

        try:
            async with client:               

                # Get the free programmable parameters
                node1 = client.get_node("ns=4;i=116") #R0
                node2 = client.get_node("ns=4;i=94") #R1
                node3 = client.get_node("ns=4;i=95") #R2
                node4 = client.get_node("ns=4;i=96") #R3
                node5 = client.get_node("ns=4;i=97") #R4
                node6 = client.get_node("ns=4;i=98") #R5
                
                while True:

                    await node1.write_value(camera.r)
                    await node2.write_value(camera.g)
                    await node3.write_value(camera.b)
                    await node4.write_value(camera.l_star)
                    await node5.write_value(camera.a_star)
                    await node6.write_value(camera.b_star)

                    await asyncio.sleep(1)
                    await client.check_connection() # Throws an exception if the connection is lost
        
        except (ConnectionError, ua.UaError):
            logger.warning("Reconnecting in 2 seconds")
            await asyncio.sleep(2)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    asyncio.run(main(), debug=True)