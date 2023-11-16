"""
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.

Authors: 
- Arjen Deetman
  3D Concrete Printing Research Group a Eindhoven University of Technology.
"""

import logging
import numpy as np
import threading
import csv

from datetime import datetime
from pypylon import pylon

class EventPrinter(pylon.ConfigurationEventHandler):

    """"""

    def OnAttach(self, camera):
        print('Before attaching')

    def OnAttached(self, camera):
        print('After attaching')

    def OnOpen(self, camera):
        print('Before opening')

    def OnOpened(self, camera):
        print('After Opening')

    def OnDestroy(self, camera):
        print('Before destroying')

    def OnDestroyed(self, camera):
        print('After destroying')

    def OnClosed(self, camera):
        print('Camera Closed')

    def OnDetach(self, camera):
        print('Detaching')

    def OnGrabStarted(self, camera):
        print('Grab started')


class ImageEventPrinter(pylon.ImageEventHandler):
    
    """"""
    
    def OnImagesSkipped(self, camera, countOfSkippedImages):
        print('Image skipped')

    def OnImageGrabbed(self, camera, grabResult):
        print('Image grabbed')
        

class Camera:
    
    def __init__(self, ip: str) -> None:
        
        """
        Initializes the camera instance.

        This class is written for a Basler a2A1920-51gcPRO.
        https://docs.baslerweb.com/a2a1920-51gcpro
        https://docs.baslerweb.com/pylonapi/net/T_Basler_Pylon_Camera
        """
        
        self.get_camera(ip)
        self.open()
        self.set_default_camera_settings()
        self.set_whitepoint()
        self.set_roi()

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

        # Write to .csv file
        self.write = True
        self.file_name = "D:/GitHub/TracerLogger/log/test.csv"

        # Write header
        if self.write == True:
            with open(self.file_name, 'a', newline='') as file:
                writer = csv.writer(file, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
                writer.writerow(["Time", "R", "G", "B", "X", "Y", "Z", "L*", "a*", "b*"])
        
        # Constants for color transformations
        ## RGB to XYZ
        self.__b11 = 0.4124
        self.__b12 = 0.3576
        self.__b13 = 0.1805
        self.__b21 = 0.2126
        self.__b22 = 0.7152
        self.__b23 = 0.0722
        self.__b31 = 0.0193
        self.__b32 = 0.1192
        self.__b33 = 0.9505
        ## XYZ to LAB
        self.__DELTA = 16.0/116.0


    def __str__(self) -> str:

        """
        Print string function.
        """

        return "<" + "Camera" +  ">"


    def reset(self) -> None:

        """
        Reset to initial settings.
        """

        self.open()
        self.set_whitepoint()
        self.set_default_camera_settings()
        self.set_roi()


    def get_camera(self, ip: str) -> None:

        """
        Gets the Basler camera instance.
        """
        
        factory = pylon.TlFactory.GetInstance()
        tl = factory.CreateTl('BaslerGigE')
        camera_info = tl.CreateDeviceInfo()
        camera_info.SetIpAddress(ip)
        self.camera = pylon.InstantCamera(factory.CreateDevice(camera_info))


    def register_event_handlers(self) -> None:

        """
        Registers the event handlers. 
        """
            
        self.open()
        self.camera.RegisterImageEventHandler(ImageEventPrinter(), pylon.RegistrationMode_Append, pylon.Cleanup_Delete)
        self.camera.RegisterConfiguration(EventPrinter(), pylon.RegistrationMode_Append, pylon.Cleanup_Delete)


    def open(self) -> None:

        """
        Opens the camera.
        """

        if self.camera.IsOpen() == False:
            self.camera.Open()


    def close(self) -> None:

        """
        Closes the camera. 
        """

        if self.camera.IsOpen():
            self.camera.Close()


    def get_temp(self) -> float:
        
        """
        Returns the sensor temperature.
        """

        return self.camera.DeviceTemperature.GetValue()


    def set_roi(self, offset_x: int=0, offset_y: int=0 , width: int=None, height: int=None) -> None:
        
        """
        Default is the full resolution.
        Values must be divisible by 4. 
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
        """
        
        return self.camera.ResultingFrameRate.GetValue()
    
    
    def grab(self, n : float) -> None:
        
        """
        This function grabs a certain amount of images. 
        Set a negative value to run without a limit. 
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


    def start_grabbing(self, event : threading.Event) -> None:

        """
        This functions keeps grabbing images until the event parameter is set. 

        Example code:
        
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

    
    def __substract_data(self, grab_result: pylon.GrabResult) -> None:

        # Get the image
        img = grab_result.GetArray().flatten() # shape of [w x b x 3]

        # Get the date and time
        date = datetime.now()

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

        # Print data (debug): replace for logger.DEBUG?
        print(date, r, g, b, x, y, z, l_star, a_star, b_star)

        # Write data to .csv file
        if self.write == True:
            with open(self.file_name, 'a', newline='') as file:
                writer = csv.writer(file, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
                writer.writerow([date, r, g, b, x, y, z, l_star, a_star, b_star])


    def stop_grabbing(self) -> None:
        
        """
        Stops grabbing images.
        """

        if self.camera.IsGrabbing():
            self.camera.StopGrabbing()


    def rgb2xyz(self, rgb: np.ndarray) -> np.ndarray:

        """
        Converts the color from linear RGB to CIEXYZ color space.
        """

        r = rgb[0]/255
        g = rgb[1]/255
        b = rgb[2]/255

        xyz = np.zeros(3)
        xyz[0] = self.__b11*r + self.__b12*g + self.__b13*b
        xyz[1] = self.__b21*r + self.__b22*g + self.__b23*b
        xyz[2] = self.__b31*r + self.__b32*g + self.__b33*b

        return xyz
    

    def xyz2lab(self, xyz: np.ndarray) -> np.ndarray:
    
        """
        Converts the color from CIEXYZ to CIELAB color space.
        """

        if xyz[0]/self.whitepoint[0] > self.__DELTA**3.0:
            fx = (xyz[0]/self.whitepoint[0])**(1.0/3.0)
        else:
            fx = (xyz[0]/self.whitepoint[0])/(3.0*self.__DELTA**2.0) + self.__DELTA
        
        if xyz[1]/self.whitepoint[1] > self.__DELTA**3.0:
            fy = (xyz[1]/self.whitepoint[1])**(1.0/3.0)
        else:
            fy = (xyz[1]/self.whitepoint[1])/(3.0*self.__DELTA**2.0) + self.__DELTA
        
        if xyz[2]/self.whitepoint[2] > self.__DELTA**3:
            fz = (xyz[2]/self.whitepoint[2])**(1.0/3.0)
        else:
            fz = (xyz[2]/self.whitepoint[2])/(3.0*self.__DELTA**2.0) + self.__DELTA

        lab = np.zeros(3)
        lab[0] = 116.0*fy - 16.0
        lab[1] = 500.0*fx - 500.0*fy
        lab[2] = 200.0*fy - 200.0*fz

        return lab
    

    def rgb2lab(self, rgb: np.ndarray) -> np.ndarray:

        """
        Converts the color from linear RGB to CIELAB color space.
        """

        return self.xyz2lab(self.rgb2xyz(rgb))
    
    
    def set_whitepoint(self, x: float=0.94811,  y: float=1.0, z: float=1.07304) -> None:
        
        """
        Sets the white point. Default is D65. 
        """

        self.whitepoint = np.ones(3)
        self.whitepoint[0] = x
        self.whitepoint[1] = y
        self.whitepoint[2] = z

    def set_gain(self, gain: float) -> None:

        """
        Sets the gain.
        """

        self.open()
        self.camera.Gain.SetValue(gain)


    def get_gain(self) -> float:
        
        """
        Gets the gain.
        """

        return self.camera.Gain.GetValue()
    

    def set_exposure_time(self, time: float) -> None:

        """
        Sets the exposure time. 
        """
        
        self.open()
        self.camera.ExposureTime.SetValue(time)

    
    def get_exposure_time(self) -> float:
        
        """
        Gets the exposure time.
        """

        return self.camera.ExposureTime.GetValue()


    def set_white_balance_ratios(self, r: float, g: float, b: float) -> None:
        
        """
        Sets the white balance ratio.
        """

        self.open()
        self.camera.BalanceRatioSelector.SetValue('Red')
        self.camera.BalanceRatio.SetValue(r)
        self.camera.BalanceRatioSelector.SetValue('Green')
        self.camera.BalanceRatio.SetValue(g)
        self.camera.BalanceRatioSelector.SetValue('Blue')
        self.camera.BalanceRatio.SetValue(b)


    def get_white_balance_ratios(self) -> np.ndarray:
        
        """
        Gets the white balance ratio.
        """

        balance = np.ones(3)
        self.camera.BalanceRatioSelector.SetValue('Red')
        balance[0] = self.camera.BalanceRatio.GetValue()
        self.camera.BalanceRatioSelector.SetValue('Green')
        balance[1] = self.camera.BalanceRatio.GetValue()
        self.camera.BalanceRatioSelector.SetValue('Blue')
        balance[2] = self.camera.BalanceRatio.GetValue()
        
        return balance


if __name__ == "__main__":

    # Initiate the logger
    _logger = logging.getLogger(__name__)
    _logger.log("Start")
    
    # Initiate the camera
    camera = Camera('169.254.1.69')

    # Camera settings
    camera.set_roi(int(1936/2-848/2), 340, 848, 300)
    camera.set_white_balance_ratios(1.0, 0.545, 1.257)
    camera.set_whitepoint(0.938, 0.981, 1.070)
    camera.set_exposure_time(16000)
    camera.set_gain(2.70)
    
    # Grab 2000 images
    camera.grab(2000)
    
    # End
    _logger.log("End")