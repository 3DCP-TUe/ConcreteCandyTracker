# SPDX-License-Identifier: GPL-3.0-or-later
# Concrete Candy Tracker
# Project: https://github.com/3DCP-TUe/ConcreteCandyTracker
#
# Copyright (c) 2023-2025 Eindhoven University of Technology
#
# Authors:
#   - Arjen Deetman (2023-2025)
#
# For license details, see the LICENSE file in the project root.

"""Automatic calibration of the camera for color detection.

This file is used for calibrating the camera. You need to run this script and adjust the 
settings to achieve the target color values. This process typically involves multiple 
runs and adjustments to fine-tune the settings. 
"""

import logging
from camera import Camera

# CONSTANTS
CAMERA_IP = "10.129.4.180"
DATABASE_GREY = "D:/GitHub/ConcreteCandyTracker/log/grey_card_auto_calibration.csv"
DATABASE_WHITE = "D:/GitHub/ConcreteCandyTracker/log/white_card_auto_calibration.csv"

if __name__ == "__main__":
   
    # Logging
    logging.basicConfig(level=logging.INFO)
    logging.info("Starting the camera.")

    # Initiate the camera
    camera = Camera(CAMERA_IP)

    # Camera settings
    camera.set_roi(int(1936/2-848/2), 340, 848, 300)
    camera.set_exposure_time(16000)
    camera.set_white_balance_ratio(1.0, 1.0, 1.0) # Initial setting
    camera.set_gain(5.0) # Initial setting
    camera.set_whitepoint() # Inital setting D65
    camera.write_to_database = True

    # Camera network settings   
    camera.set_packet_size(8192)
    camera.set_inter_packet_delay(7643)

    # Calibrate gain and white balance ratio
    input("Place the grey card and press Enter to continue...")
    camera.set_database_path(DATABASE_GREY)
    camera.color_calibration()

    # Calibrate white_point
    input("Place the white card and press Enter to continue...")
    camera.set_database_path(DATABASE_WHITE)
    camera.calibrate_white_point()

    # End
    logging.info("End")