# Concrete Candy Tracker

Concrete Candy Tracker is a software package developed for conducting tracer experiments in concrete processing. The experiment is described in detail in the paper titled "[An in-line dye tracer experiment to measure the residence time in continuous concrete processing](https://link.springer.com/article/10.1617/s11527-024-02378-y)". 

The tool includes software for data acquisition and template files for analyzing the results, such as deriving residence time functions from the acquired data. The tracer experiment uses a digital image processing (DIP) technique to detect a dye or pigment used as tracer material. The name originates from the dye Rhodamine B, which was initially used during the development of the experiment, as it stained the concrete with a candy cane–like effect.

## Hardware requirements

The software is optimized for use with the following hardware components at TU/e:

- Industrial camera: Basler a2A1920-51gcPRO
- Lens: Edmund Optics 16MM Compact Fixed Focal Length
- UV protection filter: Midwest Optical AC400
- Polarization filter: Midwest Optical PR032-25.5
- Polarized brick light: PL-ELSB-105SW
- Bandpass filter: Midwest Optical Bi550 (optional)

If a different Basler camera is used, the camera class may need to be adjusted. The listed bandpass filter is suitable for Rhodamine B. However, if you are using a different tracer material, you will need to select the appropriate bandpass filter for it.

## Installation

### Python

The current release is tested with Python 3.8 and requires the following libraries:

- The official Python wrapper for the camera from Basler: [PyPylon](https://www.baslerweb.com/en-us/software/pylon/pypylon/)
- To set up an OPC UA server or to write to an OPC UA server: [opcua-asyncio](https://github.com/FreeOpcUa/opcua-asyncio)
- For numerical operations: [numpy](https://numpy.org/)

Additionally, install the [Pylon Viewer](https://www.baslerweb.com/en-us/software/pylon/pylon-viewer/) for visual verification of the region of interest (ROI), calibrating the orientation of the polarization filter and optimization of the network settings.

### Node-RED

[Node-RED](https://nodered.org/) is optional but recommended for creating a simple live dashboard. Install Node-RED along with the following packages:

- [node-red-contrib-opcua](https://flows.nodered.org/node/node-red-contrib-opcua)
- [node-red-dashboard](https://flows.nodered.org/node/node-red-dashboard)

You can start Node-RED by typing `node-red` in the command window and access it at:

- Flow management: http://localhost:1880/
- Dashboard view: http://localhost:1880/ui

## Explanation of the files

### Data acquisition

Files related to data acquisition are located in the **[src/acquisition/](src/acquisition/)** directory and include the following files and folders:

- **[src/acquisition/camera.py](src/acquisition/camera.py):** This file contains the camera class, which provides the implementation for interfacing with an industrial camera using the pypylon library. It includes methods for initializing the camera, capturing images, and managing camera settings. 
- **[src/calibration_auto.py](src/acquisition/calibration_auto.py):** This file is used for autmomatic calibrating the camera. You need to run this script with reasonable starting values. Once you have obtained your settings, make sure to copy them to the script you used for experiments.
- **[src/acquisition/calibration_manual.py](src/acquisition/calibration_manual.py):** This file is used for manually calibrating the camera. You need to run this script and adjust the settings to achieve the target color values. This process typically involves multiple runs and adjustments to fine-tune the settings. For detailed instructions on the calibration procedure, see the section "Calibration Procedure". Once you have finalized the procedure and obtained the settings, make sure to copy them to your script used for experiments.
- **[src/acquisition/opcua_local_server.py](src/acquisition/opcua_local_server.py):** Sets up a local OPC UA server, captures color values, and makes them available for external access.
- **[src/acquisition/opcua_remote_server.py](src/acquisition/opcua_remote_server.py):** Connects to an external OPC UA server, captures color values, and writes them to the server (e.g., an industrial PLC).
- **[src/acquisition/node-red/local_server_dashboard.json](src/acquisition/node-red/local_server_dashboard.json):** A simple dashboard for Node-RED, displaying real-time color values from the local OPC UA server.
- **[src/acquisition/node-red/remote_server_dashboard.json](src/acquisition/node-red/remote_server_dashboard.json):** A simple dashboard for Node-RED, displaying real-time color values from the remote OPC UA server.

### Data analysis

Files related to data analysis are located in the **[src/analysis/](src/analysis/)** directory and include the following files and folders:

- **[lib](src/analysis/lib):** MATLAB library containing standardized functions.
- **[rtd.m](src/analysis/rtd.m):** MATLAB script to extract the residence time distribution and its properties from the acquired data.

The analysis files provided in this folder should be considered as templates and are fully functional with the latest version of the CSV format. You can use these files for data analysis or to quickly gain insights into your data. Store these files together with your dataset and adjust them if needed. If you add new functionality or create new templates please push these updates to this repository so that others can also benefit from them.

## Camera Network Connection (GigE Optimization)

To ensure reliable and high-performance image acquisition from a Basler GigE camera, follow these steps:

1. Enable Jumbo Frames on the used network adapter (if supported):
   - Open the **Device Manager**
   - Go to **Network Adapters**, right-click the Ethernet adapter used, select **Properties**
   - In the **Advanced** tab, find the property labeled "**Jumbo Frame**" or "**Jumbo Packet**" and set it to 9014 bytes (or maximum available value)
   - Click **OK** and restart the network interface

2. Optimize bandwidth settings in Pylon Viewer
   - Open **Pylon Viewer**
   - Connect to your camera
   - Open the [**Bandwidth Manager**](https://docs.baslerweb.com/bandwidth-manager)
   - Select your camera and run the optimization process
   - After optimization, close the **Bandwidth Manager**
   - Go to the **Transport Layer** settings
   - Note the values set for **Packet Size** and **Inter-Packet Delay**
   - Apply the values for **Packet Size** and **Inter-Packet Delay** in your Python script using the appropriate methods on the Camera instance: `set_packet_size` and `set_inter_packet_delay`

**Note**: You may need to re-adjust these values if you change network cables, adapters, or other system hardware, as optimal settings can vary.


## Calibration procedure/checklist

Mounting:

- Mount the camera, lens, and polarized light source.
- Place the camera 100 mm away from the concrete surface (this is the distance between the object and the lens without filters).
- Set the focus length of the lens to 0.1 m.
- Set the aperture of the lens at f/8.
- Mount the UV protection filter.
- Mount the polarization filter.
- Clean the light source and the lens.

Orientation:

- Orient the polarization filter correctly. Verify this by placing a piece of wet concrete in front of the lens: use a piece of hardened concrete and drip a bit of water on it. Rotate the filter to the position in which no glare is visible. Pylon Viewer can assist in this step.

Configuration:

- Set the region of interest (ROI). Verify the ROI with the Pylon Viewer.
- Set the exposure time at 16000.

White Balance Calibration:

- Run the data acquisition for at least one hour to heat the light source and camera. Do this for the calibration procedure and before you perform the experiment.
- Calibrate the white balance with an 18% grey card. For this step, you can use the `calibrate` function in the `Camera` class or adjust the values manually. For the latter, run the data acquisition for a short time each iteration (e.g., acquire 100 images). The goal is to set all linear RGB color values at 46. Adjust the gain value to scale all linear RGB color values. If values are below 46, increase the gain; if above 46, lower the gain. To obtain equally balanced color values: Set the white balance ratio R to 1.0. Adjust the white balance ratio G and B to obtain equal linear RGB color values of 46. If the color value G is below the color value R, increase the white balance G; if the color value G is above the color value R, decrease the white balance ratio G. Do the same for color value B. Note that changing the white balance G and B will affect all color values. Conduct several iterations with small adjustments to achieve linear RGB values of 46. Typical white balance ratios at TU/e are around 1.0, 0.545, and 1.257 for R, G, and B, respectively. Typical gain values are around 2.5-3.0, depending on the position of the light source.

White Point Measurement:

- Measure the white point by placing a white card in front of the lens. Acquire images for a short time (e.g., 100 images). The CIEXYZ color values represent the white point. As a reference, the values for daylight (D65) are 0.9504, 1.00, and 1.0888. Typical white point reference values at TU/e are 0.938, 0.981, and 1.070.
- Finally, set the measured white point values in the camera class. The white point is used to transform the color values from linear RGB color space to CIELAB color space.
If all steps are performed correctly, the measured CIELAB color values of an 18% grey card should come close to 50, 0, 0 for L*, a*, and b*, respectively.

Additional steps in case a bandpass filter is used:

- Remove the polarization filter and UV filter.
- Mount the bandpass filter.
- Reattach the polarization filter.
- Ensure the polarization filter is in the correct orientation.
- Recalibrate the gain value with an 18% grey card. Adjust the gain value to scale the L* value of the CIELAB color space to 50%. Use the already measured white reference point for this step. 

## Version numbering
Concrete Candy Tracker uses the following [Semantic Versioning](https://semver.org/) scheme: 

```
0.x.x ---> MAJOR version when you make incompatible API changes
x.0.x ---> MINOR version when you add functionality in a backward-compatible manner
x.x.0 ---> PATCH version when you make backward-compatible bug fixes
```

## Funding

This software could be developed and maintained with the financial support of the following projects:
- The project _"Additive manufacturing of functional construction materials on-demand"_ (with project number 17895) of the research program _"Materialen NL: Challenges 2018"_ which is financed by the Dutch Research Council (NWO).

## Contact information

If you have any questions or comments about this project, please open an issue on the repository’s issue page. This can include questions about the content, such as missing information, and the data structure. We encourage you to open an issue instead of sending us emails to help establish an open community. By keeping discussions open, everyone can contribute and see the feedback and questions of others. In addition to this, please see our open science statement below.

## Open science statement

We are committed to the principles of open science to ensure that our work can be reproduced and built upon by others, by sharing detailed methodologies, data, and results generated with the unique equipment that is available in our lab. To spread Open Science, we encourage others to do the same to create an (even more) open and collaborative scientific community. 
Since it took a lot of time and effort to make our data and software available, we license our software under the General Public License version 3 or later (free to use, with attribution, share with source code) and our data and documentation under CC BY-SA (free to use, with attribution, share-alike), which requires you to apply the same licenses if you use our resources and share its derivatives with others. 

## License

Copyright (c) 2023-2025 [3D Concrete Printing Research Group at Eindhoven University of Technology](https://www.tue.nl/en/research/research-groups/structural-engineering-and-design/3d-concrete-printing)

Concrete Candy Tracker is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation. 

Concrete Candy Tracker is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Concrete Candy Tracker; If not, see <http://www.gnu.org/licenses/>.

@license GPL-3.0 <https://www.gnu.org/licenses/gpl-3.0.html>
