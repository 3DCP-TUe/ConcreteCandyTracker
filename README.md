# Concrete Candy Tracker

Concrete Candy Tracker is a software package developed for conducting tracer experiments in concrete processing. The experiment is described in detailed in the paper titled "An In-line Dye Tracer Experiment for Mixing and Pumping Concrete." The experiment uses a digital image processing (DIP) technique to detect a dye — Rhomadine B — which stains the concrete with a candy cane-like effect.

## Hardware requirements

The software is optimized for use with the following hardware components at TU/e:

- Industrial camera: Basler a2A1920-51gcPRO
- Lens: Edmund Optics 16MM Compact Fixed Focal Length
- UV protection filter: Midwest Optical AC400
- Polarization filter: Midwest Optical PR032-25.5
- Polarized brick light: PL-ELSB-105SW

If a different Basler camera is used, it may need adjustments to the camera class.

## Installation

### Python

The current release is tested with Python 3.8 and requires the following libraries:

- The offical Python wrapper for the camera from Basler: PyPylon
- To set up an OPC UA server or to write to an OPC UA server: opcua-asyncio
- For numerical operations: numpy

Additionally, install the Pylon Viewer for visual verification of the region of interest (ROI) and calibrating the orientaton of the polarization filter. 

### Node-red

Node-Red is optional but recommended for creating a simple live dashboard. Install Node-Red along with the following packages:

- node-red-contrib-opcua
- node-red-dashboard

Access Node-Red at:

- Flow management: http://localhost:1880/
- Dashboard view: http://localhost:1880/ui

# Explanation of the files

src/camera.py: Contains the camera class. 

src/opcua_local_server.py: Sets up a local OPC UA server, captures color values, and makes them available for external access.

src/opcua_write_to_server.py: Connects to an external OPC UA server, captures color values, and writes them to the server (e.g., an industrial PLC).

scr/node-red/fows.json: A simple dashboard for Node-Red, displaying real-time color values from the local OPC UA server.

scr/benchmarks/color_transformations.m: MATLAB script for checking the implemented color transformations in the camera class from linear RGB to CIEXYZ and CIELAB color values.

## Calibration procedure / checklist

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

- Run the data acquisition for at least one hour to heat up the light source and camera. Do this for the calibration prodecure and before you perform the experiment.
- Calibrate the white balance with an 18% grey card. For this step, run the data acquisition for a short time each iteration (e.g., acquire 100 images). The goal is to set all linear RGB color values at 46. Adjust the gain value to scale all linear RGB color values. If values are below 46, increase the gain; if above 46, lower the gain. To obtain equally balanced color values: Set the white balance ratio R to 1.0. Adjust the white balance ratio G and B to obtain equal linear RGB color values of 46. If the color value G is below the color value R, increase the white balance G; if the color value G is above the color value R, decrease the white balance ratio G. Do the same for color value B. Note that changing the white balance G and B will affect all color values. Conduct several iterations with small adjustments to achieve linear RGB values of 46. Typical white balance ratios at TU/e are around 1.0, 0.545, and 1.257 for R, G, and B, respectively. Typical gain values are around 2.5-3.0, depending on the position of the light source.

White Point Measurement:

- Measure the white point by placing a white card in front of the lens. Acquire images for a short time (e.g., 100 images). The CIEXYZ color values represent the white point. As a reference, the values for daylight (D65) are 0.9504, 1.00, and 1.0888. Typical white point reference values at TU/e are 0.938, 0.981, and 1.070.
- Finally, set the measured white point values in the camera class. The white point is used to transform the color values from linear RGB color space to CIELAB color space.
If all steps are performed correctly, the measured CIELAB color values of an 18% grey card should come close to 50, 0, 0 for L*, a*, and b*, respectively.

## Cite

TODO: Make a zenodo page with DOI. 

## License
Copyright (c) 2023 3D Concrete Printing Research Group at Eindhoven University of Technology

Concrete Candy Tracker is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation. 

Concrete Candy Tracker is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Concrete Candy Tracker; If not, see <http://www.gnu.org/licenses/>.

@license GPL-3.0 <https://www.gnu.org/licenses/gpl-3.0.html>
