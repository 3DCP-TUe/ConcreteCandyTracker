"""
Concrete Candy Tracker

This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.

This file is used for calibrating the camera. You need to run this script and adjust the 
settings to achieve the target color values. This process typically involves multiple 
runs and adjustments to fine-tune the settings. 
"""

import logging
from camera import Camera

# CONSTANTS
CAMERA_IP = "10.129.4.180"
DATABASE = "D:/GitHub/ConcreteCandyTracker/log/test.csv"

if __name__ == "__main__":
   
    # Logging
    logging.basicConfig(level=logging.INFO)
    logging.info("Starting the camera.")

    # Initiate the camera
    camera = Camera(CAMERA_IP)

    # Camera settings
    camera.set_roi(int(1936/2-848/2), 340, 848, 300)
    camera.set_white_balance_ratio(1.0, 0.550, 1.285)
    camera.set_whitepoint(0.9225, 0.9583, 1.0468)
    camera.set_exposure_time(16000)
    camera.set_gain(2.52)

    # Write to database
    camera.set_database_path(DATABASE)
    camera.write_to_database = True
    
    # Grab 300 images and calculate the average color value
    camera.grab_average(300)
    
    # End
    logging.info("End")