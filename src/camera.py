"""
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.

Authors: 
- Arjen Deetman
"""

import logging
import numpy as np
import threading
import csv
import os
from datetime import datetime
from pypylon import pylon

# CONSTANTS
_B11 = 0.4124
_B12 = 0.3576
_B13 = 0.1805
_B21 = 0.2126
_B22 = 0.7152
_B23 = 0.0722
_B31 = 0.0193
_B32 = 0.1192
_B33 = 0.9505
_DELTA = 16.0/116.0


class Camera:

    """Concrete Candy Tracker Camera."""
    
    def __init__(self, ip: str) -> None:
        
        """
        Initializes the camera instance.

        This class is written for a Basler a2A1920-51gcPRO.
        https://docs.baslerweb.com/a2a1920-51gcpro
        https://docs.baslerweb.com/pylonapi/net/T_Basler_Pylon_Camera
        
        Args:
            ip (str): The IP address of the camera. 

        Returns:
            None
        """
        
        self.__get_camera(ip)
        self.__register_event_handlers()
        self.set_default_camera_settings()
        self.set_whitepoint() # Default: D65
        self.set_roi() # Default: full resolution

        # Latest measured color values
        self.r = 0.0
        self.g = 0.0
        self.b = 0.0
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.l_star = 0.0
        self.a_star = 0.0
        self.b_star = 0.0

        # Write to CSV file
        self.write_to_database = False
        self.__database = ""


    def __str__(self) -> str:

        """
        Print string function.
        
        Args:
            None

        Returns:
            str: Hum readable string represenation of this camera instance.
        """

        return "<Concrete Candy Tracker Camera>"


    def __get_camera(self, ip: str) -> None:

        """
        Gets the Basler camera instance.
        
        Args:
            ip (str): The IP address of the camera. 

        Returns:
            None
        """
        
        factory = pylon.TlFactory.GetInstance()
        tl = factory.CreateTl('BaslerGigE')
        camera_info = tl.CreateDeviceInfo()
        camera_info.SetIpAddress(ip)
        self.camera = pylon.InstantCamera(factory.CreateDevice(camera_info))


    def __register_event_handlers(self) -> None:

        """
        Registers the event handlers.

        Args:
            None

        Returns:
            None
        """

        self.open()
        self.camera.RegisterImageEventHandler(ImageEventHandler(self), pylon.RegistrationMode_Append, pylon.Cleanup_Delete)
        self.camera.RegisterConfiguration(ConfigurationEventHandler(self), pylon.RegistrationMode_Append, pylon.Cleanup_Delete)


    def reset(self) -> None:

        """
        Reset to initial settings.
                
        Args:
            None

        Returns:
            None
        """

        self.open()
        self.set_whitepoint()
        self.set_default_camera_settings()
        self.set_roi()


    def open(self) -> None:

        """
        Opens the camera.
                
        Args:
            None

        Returns:
            None
        """

        if self.camera.IsOpen() == False:
            self.camera.Open()


    def close(self) -> None:

        """Closes the camera.
                
        Args:
            None

        Returns:
            None
        """

        if self.camera.IsOpen():
            self.camera.Close()


    def get_temp(self) -> float:
        
        """
        Returns the sensor temperature.
                
        Args:
            None

        Returns:
            float: The sensor temperature. 
        """

        self.open()
        return self.camera.DeviceTemperature.GetValue()


    def set_roi(self, offset_x: int=0, offset_y: int=0 , width: int=None, height: int=None) -> None:
        
        """
        Sets the region of interest. Default is the full resolution. Values must be divisible by 4.
                
        Args:
            offset_x (int, optional): The offset of the ROI in the x direction in pixels. Defaults to 0.
            offset_y (int, optional): The offset of the ROI in the y direction in pixels. Defaults to 0.
            width (int, optional): The width of the ROI in pixels. Defaults to full width if None.
            height (int, optional): The height of the ROI in pixels. Defaults to full height if None.

        Returns:
            None
        """

        self.open()   

        # Checks
        ## Default width and height
        if width == None:
            width = self.camera.SensorWidth.GetValue()
        if height == None:
            height = self.camera.SensorHeight.GetValue()
        ## Values need to be divisible by 4
        if (offset_x % 4 == 0):
            offset_x = ((int)(np.round(offset_x / 4, 0))) * 4
        if (offset_y % 4 == 0):
            offset_y = ((int)(np.round(offset_y / 4, 0))) * 4
        if (offset_x % 4 == 0):
            width = ((int)(np.round(width / 4, 0))) * 4
        if (offset_x % 4 == 0):
            height = ((int)(np.round(height / 4, 0))) * 4
        # Check maximum width and height
        if (width > self.camera.SensorWidth.GetValue()):
            width = self.camera.SensorWidth.GetValue()
        if (height > self.camera.SensorHeight.GetValue()):
            height = self.camera.SensorHeight.GetValue()
        
        # Set values
        self.camera.OffsetX.SetValue(0)
        self.camera.OffsetY.SetValue(0)
        self.camera.Width.SetValue(width)
        self.camera.Height.SetValue(height)
        self.camera.OffsetX.SetValue(offset_x)
        self.camera.OffsetY.SetValue(offset_y)


    def set_default_camera_settings(self) -> None:

        """
        Sets the default camera settings for the tracer experiment. 

        For all features see: https://docs.baslerweb.com/features
        Follows the structure of the Pylon software package. 

        Args:
            None

        Returns:
            None
        """

        # Open camera
        self.open()

        # Acquisition Mode
        self.camera.AcquisitionMode.SetValue("Continuous")

        # Image format control
        self.camera.ReverseX.SetValue(False)
        self.camera.ReverseY.SetValue(False)
        self.camera.BslMultipleROIRowsEnable.SetValue(False)
        self.camera.PixelFormat.SetValue("RGB8")
        self.camera.TestPattern.SetValue("Off")
        self.camera.ImageCompressionMode.SetValue("Off")
        #self.camera.ImageCompressionRateOption = "Lossless"
        #self.camera.BslImageCompressionRatio = 30.0

        # Acquiston control
        self.camera.BslAcquisitionStopMode.SetValue("CompleteExposure")
        self.camera.BslExposureTimeMode.SetValue("Standard")
        self.camera.ExposureTime.SetValue(16000.0)
        self.camera.ExposureAuto.SetValue("Off")
        self.camera.ExposureMode.SetValue("Timed")
        self.camera.BslSensorBitDepthMode.SetValue("Auto")
        self.camera.AcquisitionFrameRate.SetValue(60.0)
        self.camera.AcquisitionFrameRateEnable.SetValue(True)
        self.camera.TriggerSelector.SetValue("FrameStart")
        self.camera.TriggerMode.SetValue("Off")
        self.camera.TriggerSource.SetValue("Software")
        self.camera.TriggerDelay.SetValue(0.0)
        self.camera.BslAcquisitionBurstMode.SetValue("Standard")
        self.camera.AcquisitionBurstFrameCount.SetValue(1)
        self.camera.AcquisitionStatusSelector.SetValue("AcquisitionActive")

        # Auto function control
        self.camera.AutoTargetBrightness.SetValue(0.500)
        self.camera.AutoFunctionProfile.SetValue("MinimizeGain")
        self.camera.AutoGainLowerLimit.SetValue(0.0)
        self.camera.AutoGainUpperLimit.SetValue(47.999)
        self.camera.AutoExposureTimeLowerLimit.SetValue(1000.0)
        self.camera.AutoExposureTimeUpperLimit.SetValue(64000.0)
        self.camera.AutoFunctionROISelector.SetValue("ROI1")
        self.camera.AutoFunctionROIWidth.SetValue(1920)
        self.camera.AutoFunctionROIHeight.SetValue(1200)
        self.camera.AutoFunctionROIOffsetY.SetValue(0)
        self.camera.AutoFunctionROIOffsetY.SetValue(0)
        self.camera.AutoFunctionROIUseBrightness.SetValue(False)
        self.camera.AutoFunctionROIUseWhiteBalance.SetValue(True)
        self.camera.AutoFunctionROIHighlight.SetValue(False)

        # Analog control
        self.camera.Gain.SetValue(2.5)
        self.camera.GainAuto.SetValue("Off")
        self.camera.BlackLevel.SetValue(0.0)
        self.camera.Gamma.SetValue(1.0)
        self.camera.DigitalShift.SetValue(0)
        self.camera.BslColorSpace.SetValue("Off")

        # Image processing control
        self.camera.BslColorSpace.SetValue("Off")
        self.camera.BslLightSourcePreset.SetValue("Off")
        self.camera.BslLightSourcePresetFeatureSelector.SetValue("WhiteBalance")
        self.camera.BslLightSourcePresetFeatureEnable.SetValue(False)

        self.camera.BslHue.SetValue(0.0)
        self.camera.BslSaturation.SetValue(1.000)
        self.camera.BslContrast.SetValue(0.000)
        self.camera.BslContrastMode.SetValue("Linear")
        self.camera.BslBrightness.SetValue(0.000)

        self.camera.BalanceRatioSelector.SetValue('Red')
        self.camera.BalanceRatio.SetValue(1.0)
        self.camera.BalanceRatioSelector.SetValue('Green')
        self.camera.BalanceRatio.SetValue(1.0)
        self.camera.BalanceRatioSelector.SetValue('Blue')
        self.camera.BalanceRatio.SetValue(1.0)

        self.camera.BalanceWhiteAuto.SetValue("Off")
        self.camera.ColorTransformationSelector.SetValue("RGBtoRGB")
        self.camera.ColorTransformationEnable.SetValue(False)
        self.camera.ColorTransformationValueSelector.SetValue("Gain00")
        self.camera.ColorTransformationValue.SetValue(1.0000)
        self.camera.BslColorAdjustmentEnable.SetValue(False)
        self.camera.BslColorAdjustmentSelector.SetValue("Red")
        self.camera.BslColorAdjustmentHue.SetValue(0.000)
        self.camera.BslColorAdjustmentSaturation.SetValue(1.000)
        self.camera.BslColorAdjustmentSelector.SetValue("Yellow")
        self.camera.BslColorAdjustmentHue.SetValue(0.000)
        self.camera.BslColorAdjustmentSaturation.SetValue(1.000)
        self.camera.BslColorAdjustmentSelector.SetValue("Green")
        self.camera.BslColorAdjustmentHue.SetValue(0.000)
        self.camera.BslColorAdjustmentSaturation.SetValue(1.000)
        self.camera.BslColorAdjustmentSelector.SetValue("Cyan")
        self.camera.BslColorAdjustmentHue.SetValue(0.000)
        self.camera.BslColorAdjustmentSaturation.SetValue(1.000)
        self.camera.BslColorAdjustmentSelector.SetValue("Blue")
        self.camera.BslColorAdjustmentHue.SetValue(0.000)
        self.camera.BslColorAdjustmentSaturation.SetValue(1.000)
        self.camera.BslColorAdjustmentSelector.SetValue("Magenta")
        self.camera.BslColorAdjustmentHue.SetValue(0.000)
        self.camera.BslColorAdjustmentSaturation.SetValue(1.000)

        self.camera.LUTEnable.SetValue(True)
        self.camera.LUTIndex.SetValue(0)
        self.camera.LUTValue.SetValue(0)

        self.camera.BslSharpnessEnhancement.SetValue(1.000)
        self.camera.BslNoiseReduction.SetValue(0.000)
        self.camera.BslScalingFactor.SetValue(1.000)

        # Digital I/O control
        self.camera.LineSelector.SetValue("Line1")
        self.camera.LineInverter.SetValue(False)
        self.camera.LineMode.SetValue("Input")
        self.camera.BslInputFilterTime.SetValue(0.00)
        self.camera.BslInputHoldOffTime.SetValue(0.00)
        self.camera.UserOutputSelector.SetValue("UserOutput1")
        self.camera.UserOutputValue.SetValue(False)
        self.camera.UserOutputValueAll.SetValue(0)

        # Serial communication control
        self.camera.BslSerialRxSource.SetValue("Off")

        # Counter and Timer control
        ## Not used: set to default

        # Software Signal Control
        ## Not used: set to default

        # Chunk Data Control
        self.camera.ChunkModeActive.SetValue(False)

        # Action Control
        ## Not used: set to default

        # Periodic Signal Control
        ## Not used: set to default

        # Event control
        ## Not used: set to default

        # Uset set control
        ## Not used: set to default

        # User definied values
        ## Not used: set to default

        # Device Control
        self.camera.DeviceIndicatorMode.SetValue("Active")
        self.camera.DeviceTemperatureSelector.SetValue("Sensor")

        # Test Control
        ## Not used: set to default

        # Transport Layer Control
        self.camera.GevSCPSPacketSize.SetValue(1500)
        self.camera.GevSCPD.SetValue(512)
        self.camera.GevSCFTD.SetValue(0)
        self.camera.BandwidthReserveMode.SetValue("Standard")
        self.camera.BslPtpProfile.SetValue("DelayRequestResponseDefaultProfile")
        self.camera.BslPtpNetworkMode.SetValue("Multicast")
        self.camera.BslPtpTwoStep.SetValue(False)
        self.camera.BslPtpPriority1.SetValue(128)
        self.camera.BslPtpManagementEnable.SetValue(False)
        self.camera.PtpEnable.SetValue(False)
        
        # Error Report Control
        ## Not used: set to default

        # Stream Parameters
        ## Not used: set to default

        # Device Transport Layer
        ## Not used: set to default

        # Event Grabber Parameters
        ## Not used: set to default

        # Image Format Conversion
        ## Not used: set to default


    def get_resulting_frame_rate(self) -> float:
        
        """
        Returns the resulting frame rate.
                
        Args:
            None

        Returns:
            float: The resulting frame rate in fps. 
        """
        
        return self.camera.ResultingFrameRate.GetValue()
    

    def is_grabbing(self) -> bool:
        
        """
        Returns a boolean indicating if the camera is grabbing images.
                
        Args:
            None

        Returns:
            bool: True if the camera is grabbing, False otherwise.
        """

        return self.camera.IsGrabbing()
    
    
    def grab(self, n : float) -> None:
        
        """
        Grabs a specific number of images. Set a negative value to run without a limit.
                
        Args:
            n (float): The number of images to grab. If set to a negative value, the method will run indefinitely.

        Returns:
            None
        """

        if self.camera != None:
            
            self.camera.StartGrabbing(pylon.GrabStrategy_LatestImageOnly)
            
            counter = 0

            while self.camera.IsGrabbing():

                grab_result = self.camera.RetrieveResult(1000, pylon.TimeoutHandling_Return)

                if grab_result.GrabSucceeded():
                    
                    self.__substract_data(grab_result)

                    counter += 1

                    if counter == n:
                        self.camera.StopGrabbing()


    def grab_average(self, n : float) -> np.ndarray:

        """
        Grabs a specific number of images and calculates the average color value from these images.
                
        Args:
            n (float): The number of images to grab.
        
        Returns:
            np.ndarray: An array containing the average color values in multiple color spaces, including R, G, B, X, Y, Z, L*, a*, and b*.
        """
        
        if (n < 1):
            return np.zeros(9, dtype=float)
        
        if self.camera != None:
            
            self.camera.StartGrabbing(pylon.GrabStrategy_LatestImageOnly)
            color_values_arrays = []
            
            counter = 0

            while self.camera.IsGrabbing():

                grab_result = self.camera.RetrieveResult(1000, pylon.TimeoutHandling_Return)

                if grab_result.GrabSucceeded():
                    
                    color_values = self.__substract_data(grab_result)
                    color_values_arrays.append(color_values)

                    counter += 1

                    if counter == n:
                        self.camera.StopGrabbing()
            
            stacked_color_values = np.stack(color_values_arrays)
            average_color_values = np.mean(stacked_color_values, axis=0)
            
            date = datetime.now()
            r, g, b = average_color_values[0], average_color_values[1], average_color_values[2]
            x, y, z =  average_color_values[3], average_color_values[4], average_color_values[5]
            l_star, a_star, b_star = average_color_values[6], average_color_values[7], average_color_values[8]

            logging.info("Resulting average color value from grabbing {0} images".format(n))
            logging.info("{0}, R={1:.1f}, G={2:.1f}, B={3:.1f}, X={4:.4f}, Y={5:.4f}, Z={6:.4f}, L*={7:.4f}, a*={8:.4f}, b*={9:.4f}".format(date, r, g, b, x, y, z, l_star, a_star, b_star))

            return average_color_values

        return np.zeros(9, dtype=float)


    def stop_grabbing(self) -> None:
        
        """
        Stops grabbing images.
                
        Args:
            None

        Returns:
            None
        """

        if self.camera.IsGrabbing():
            self.camera.StopGrabbing()
    

    def start_grabbing(self, event : threading.Event) -> None:

        """
        Keeps grabbing images until the event parameter is set.

        Example code:
        
        ```python
        # Create a camera
        camera = Camera('168.192.1.1')

        # Create the event
        event = threading.Event()

        # Create the thread
        thread = threading.Thread(target=camera.start_grabbing, args=(event,))

        # Start the thread
        thread.start()

        # Stop the thread by setting the event
        event.set()
        ```

        Args:
            event (threading.Event): The threading event.

        Returns:
            None
        """

        if self.camera != None:
            
            self.open()

            self.camera.StartGrabbing(pylon.GrabStrategy_LatestImageOnly)

            while self.camera.IsGrabbing():

                grab_result = self.camera.RetrieveResult(1000, pylon.TimeoutHandling_Return)

                if grab_result.GrabSucceeded():   
                    self.__substract_data(grab_result)

                if event.is_set():
                    self.camera.StopGrabbing()
                    break

    
    def __substract_data(self, grab_result: pylon.GrabResult) -> np.ndarray:
        
        """
        Processes the grab result and stores the data.
        
        Args:
            grab_result (pylon.GrabResult): The result of a grab operation to be processed.

        Returns:
            np.ndarray: An array containing the average color values in multiple color spaces, including R, G, B, X, Y, Z, L*, a*, and b*.
        """

        # Get the image
        img = grab_result.GetArray().flatten() # shape of [w x b x 3]

        # Get the date and time
        date = datetime.now()
        t = date.strftime("%H:%M:%S.%f")[:-3]

        # RGB values
        rgb = np.array([np.average(img[0::3]), np.average(img[1::3]), np.average(img[2::3])], dtype=float)
        r = np.round(rgb[0], 3)
        g = np.round(rgb[1], 3)
        b = np.round(rgb[2], 3)

        # CIEXYZ values
        xyz = self.rgb2xyz(rgb)
        x = np.round(xyz[0], 6)
        y = np.round(xyz[1], 6)
        z = np.round(xyz[2], 6)

        # CIELAB values
        lab = self.xyz2lab(xyz)
        l_star = np.round(lab[0], 6)
        a_star = np.round(lab[1], 6)
        b_star = np.round(lab[2], 6)
                
        # Set latest measured color values
        self.r = r
        self.g = g
        self.b = b
        self.x = x
        self.y = y
        self.z = z
        self.l_star = l_star
        self.a_star = a_star
        self.b_star = b_star

        # Log
        logging.info("{0}, R={1:.1f}, G={2:.1f}, B={3:.1f}, X={4:.4f}, Y={5:.4f}, Z={6:.4f}, L*={7:.4f}, a*={8:.4f}, b*={9:.4f}".format(date, r, g, b, x, y, z, l_star, a_star, b_star))

        # Write data to CSV database
        if self.write_to_database == True:
            with open(self.__database, 'a', newline='') as file:
                writer = csv.writer(file, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
                writer.writerow([t, "{0:.3f}".format(r), "{0:.3f}".format(g), "{0:.3f}".format(b), "{0:.6f}".format(x), "{0:.6f}".format(y), "{0:.6f}".format(z), "{0:.6f}".format(l_star), "{0:.6f}".format(a_star), "{0:.6f}".format(b_star)])

        return np.concatenate([rgb, xyz, lab])


    def rgb2xyz(self, rgb: np.ndarray) -> np.ndarray:

        """
        Converts the color value from linear RGB to CIEXYZ color space.
                
        Args:
            rgb (np.ndarray): An array containing the color values in linear RGB color space.

        Returns:
            np.ndarray: An array containing the color values in CIEXYZ color space.
        """

        r = rgb[0]/255
        g = rgb[1]/255
        b = rgb[2]/255

        xyz = np.zeros(3)
        xyz[0] = _B11*r + _B12*g + _B13*b
        xyz[1] = _B21*r + _B22*g + _B23*b
        xyz[2] = _B31*r + _B32*g + _B33*b

        return xyz
    

    def xyz2lab(self, xyz: np.ndarray) -> np.ndarray:
    
        """
        Converts the color values from CIEXYZ to CIELAB color space.
                
        Args:
            xyz (np.ndarray): An array containing the color values in CIEXYZ color space.

        Returns:
            np.ndarray: An array containing the color values in CIELAB color space.
        """

        if xyz[0]/self.whitepoint[0] > _DELTA**3.0:
            fx = (xyz[0]/self.whitepoint[0])**(1.0/3.0)
        else:
            fx = (xyz[0]/self.whitepoint[0])/(3.0*_DELTA**2.0) + _DELTA
        
        if xyz[1]/self.whitepoint[1] > _DELTA**3.0:
            fy = (xyz[1]/self.whitepoint[1])**(1.0/3.0)
        else:
            fy = (xyz[1]/self.whitepoint[1])/(3.0*_DELTA**2.0) + _DELTA
        
        if xyz[2]/self.whitepoint[2] > _DELTA**3:
            fz = (xyz[2]/self.whitepoint[2])**(1.0/3.0)
        else:
            fz = (xyz[2]/self.whitepoint[2])/(3.0*_DELTA**2.0) + _DELTA

        lab = np.zeros(3)
        lab[0] = 116.0*fy - 16.0
        lab[1] = 500.0*fx - 500.0*fy
        lab[2] = 200.0*fy - 200.0*fz

        return lab
    

    def rgb2lab(self, rgb: np.ndarray) -> np.ndarray:

        """
        Converts the color values from linear RGB to CIELAB color space.
                
        Args:
            rgb (np.ndarray): An array containing the color values in linear RGB color space.

        Returns:
            np.ndarray: An array containing the color values in CIELAB color space.
        """

        return self.xyz2lab(self.rgb2xyz(rgb))
    
    
    def set_whitepoint(self, x: float=0.94811,  y: float=1.0, z: float=1.07304) -> None:
        
        """
        Sets the white point. Default is D65.
                
        Args:
            x (float, optional): The x coordinate of the white point in the CIEXYZ color space. Defaults to 0.94811.
            y (float, optional): The y coordinate of the white point in the CIEXYZ color space. Defaults to 1.0.
            z (float, optional): The z coordinate of the white point in the CIEXYZ color space. Defaults to 1.07304.

        Returns:
            None
        """

        self.whitepoint = np.ones(3)
        self.whitepoint[0] = x
        self.whitepoint[1] = y
        self.whitepoint[2] = z


    def set_gain(self, gain: float) -> None:

        """
        Sets the gain.
                
        Args:
            gain (float): The gain value to be set. It should be a positive number representing the amplification level.

        Returns:
            None
        """

        self.open()
        self.camera.Gain.SetValue(gain)


    def get_gain(self) -> float:
        
        """
        Gets the gain.
                
        Args:
            None

        Returns:
            float: The current gain value.
        """

        return self.camera.Gain.GetValue()
    

    def set_exposure_time(self, time: float) -> None:

        """
        Sets the exposure time.
        
        Args:
            time (float): The exposure time to set, in ms.

        Returns:
            None
        """
        
        self.open()
        self.camera.ExposureTime.SetValue(time)

    
    def get_exposure_time(self) -> float:
        
        """
        Gets the exposure time.
        
        Args:
            None

        Returns:
            float: the current exposure time, in ms. 
        """

        return self.camera.ExposureTime.GetValue()


    def set_white_balance_ratio(self, r: float, g: float, b: float) -> None:
        
        """
        Sets the white balance ratio.
        
        Args:
            r (float): The white balance ratio for the red channel.
            g (float): The white balance ratio for the green channel.
            b (float): The white balance ratio for the blue channel.

        Returns:
            None
        """

        self.open()
        self.camera.BalanceRatioSelector.SetValue('Red')
        self.camera.BalanceRatio.SetValue(r)
        self.camera.BalanceRatioSelector.SetValue('Green')
        self.camera.BalanceRatio.SetValue(g)
        self.camera.BalanceRatioSelector.SetValue('Blue')
        self.camera.BalanceRatio.SetValue(b)


    def get_white_balance_ratio(self) -> np.ndarray:
        
        """
        Gets the white balance ratio.
                
        Args:
            None

        Returns:
            np.ndarray: An array containing the white balance ratios for the red, green and blue channels.
        """

        balance = np.ones(3)
        self.camera.BalanceRatioSelector.SetValue('Red')
        balance[0] = self.camera.BalanceRatio.GetValue()
        self.camera.BalanceRatioSelector.SetValue('Green')
        balance[1] = self.camera.BalanceRatio.GetValue()
        self.camera.BalanceRatioSelector.SetValue('Blue')
        balance[2] = self.camera.BalanceRatio.GetValue()
        
        return balance
    

    def set_database_path(self, file: str) -> None:
        
        """
        Sets and initiates the CSV database.
                
        Args:
            file (str): The CSV filepath. 

        Returns:
            None
        """

        self.__database = file

        # Initiate file with header (only if file doesn't exist yet)
        if not (os.path.exists(self.__database)):
            try:
                with open(self.__database, 'a', newline='') as file:
                    writer = csv.writer(file, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
                    writer.writerow(["Time", "R", "G", "B", "X", "Y", "Z", "L*", "a*", "b*"])
            except Exception as e:
                logging.error("Error initializing CSV database: {0}".format(e))


    def get_database_path(self) -> str:

        """
        Gets the path of the CSV database.
                
        Args:
            None

        Returns:
            str: The CSV filepath. 
        """

        return self.__database
    
    
class ConfigurationEventHandler(pylon.ConfigurationEventHandler):

    """Handles camera configuration events."""

    def __init__(self, camera: Camera) -> None:

        """Initializes the configuration event handler."""

        super(ConfigurationEventHandler, self).__init__()
        self.camera = camera

    def OnAttach(self, camera: pylon.InstantCamera) -> None:
        logging.debug('Before attaching')
        
    def OnAttached(self, camera: pylon.InstantCamera) -> None:
        logging.debug('After attaching')

    def OnOpen(self, camera: pylon.InstantCamera) -> None:
        logging.debug('Before opening')

    def OnOpened(self, camera: pylon.InstantCamera) -> None:
        logging.debug('After Opening')

    def OnDestroy(self, camera: pylon.InstantCamera) -> None:
        logging.debug('Before destroying')

    def OnDestroyed(self, camera: pylon.InstantCamera) -> None:
        logging.debug('After destroying')

    def OnClosed(self, camera: pylon.InstantCamera) -> None:
        logging.debug('Camera Closed')

    def OnDetach(self, camera: pylon.InstantCamera) -> None:
        logging.debug('Detaching')

    def OnGrabStarted(self, camera: pylon.InstantCamera) -> None:
        logging.debug('Grab started')


class ImageEventHandler(pylon.ImageEventHandler):
    
    """Handles image events."""
    
    def __init__(self, camera: Camera) -> None:

        """Initializes the image event handler."""

        super(ImageEventHandler, self).__init__()
        self.camera = camera
    
    def OnImagesSkipped(self, camera: pylon.InstantCamera, count_of_skipped_images: int) -> None:
        logging.debug('Image skipped')

    def OnImageGrabbed(self, camera: pylon.InstantCamera, grab_result: pylon.GrabResult) -> None:
        logging.debug('Image grabbed')


if __name__ == "__main__":
   
    # Logging
    logging.basicConfig(level=logging.INFO)
    logging.info("Starting the camera.")

    # Initiate the camera
    camera = Camera("10.129.4.180")
    camera.write_to_database = False

    # Camera settings
    camera.set_roi(int(1936/2-848/2), 340, 848, 300)
    camera.set_white_balance_ratio(1.0, 0.550, 1.285)
    camera.set_whitepoint(0.9225, 0.9583, 1.0468)
    camera.set_exposure_time(16000)
    camera.set_gain(2.52)
    
    # Grab 300 images and calculate the average color value
    camera.grab_average(300)
    
    # End
    logging.info("End")