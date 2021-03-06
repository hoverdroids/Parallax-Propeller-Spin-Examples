{{
OBEX LISTING:
  http://obex.parallax.com/object/413

  Supports upto 4 serial ports with 1 COG. Also supports hardware flow control on any of the ports.

  Fixed issue with 4th port. All 4 ports now tested and working.
  Added additional test programs in download.
  Added comment and version variable if need multiple copies of driver (i.e. more than 4 ports)

}}

'
'This demo uses 3 COGs to process GPS, CMU Camera and write to debug serial port
'
'GPS normally uses 2 COGs - one for serial port and one for processing receive chars
'CMUCamera normally uses 2 COGs - one for serial port and one for processing receive chars
'plus main COG and debug serial port COG, i.e. a total of 6 COGs
'
'This uses 1 COG for all the serial ports, 1 COG to process GPS and camera receive chars
'plus main COG, i.e. a total of 3 COGs
'
con
  _clkmode = xtal1 + pll16x                '
  _xinfreq = 5_000_000                     '

obj
                                                        '2 Cog here 
  uarts         : "pcFullDuplexSerial4FC"               '1 COG for 4 serial ports
  cam           : "CMUCamera"                           'no COG required
  gps           : "GPS_IO"                              'no COG required
  config        : "gpstest_config"                      'no COG required
  
var
  long  stack[50]                                       'requires stack of at least 32
  long  cog
  
pub main | time
  config.Init(@pininfo,0)
  waitcnt(clkfreq*3 + cnt)
  uarts.Init
  uarts.AddPort(0,config.GetPin(CONFIG#DEBUG_RX),config.GetPin(CONFIG#DEBUG_TX),{
}   UARTS#PINNOTUSED,UARTS#PINNOTUSED,UARTS#DEFAULTTHRESHOLD, {
}   UARTS#NOMODE,UARTS#BAUD115200)                      'Add debug port
  uarts.AddPort(1,config.GetPin(CONFIG#GPS_RX),config.GetPin(CONFIG#GPS_TX),{
}   UARTS#PINNOTUSED,UARTS#PINNOTUSED,UARTS#DEFAULTTHRESHOLD, {
}   UARTS#NOMODE,UARTS#BAUD4800)                        'Add gps port
  uarts.Start                                           'Start the ports
  
  uarts.str(0,string("Starting",13))
  gps.Init(1)                                           'use Init and then uses BackGround cog
                                                        'to process GPS receive characters
                                                        'Note the background cog isn't running
                                                        'but it doesn't seem to affect us sending
                                                        'commands to gps
  gps.configbaud                                        'Change GPS baudrate
  waitcnt(clkfreq + cnt)

  uarts.Init                                            'Restart serial ports to change baudrate
  uarts.AddPort(0,config.GetPin(CONFIG#DEBUG_RX),config.GetPin(CONFIG#DEBUG_TX),{
}   UARTS#PINNOTUSED,UARTS#PINNOTUSED,UARTS#DEFAULTTHRESHOLD, {
}   UARTS#NOMODE,UARTS#BAUD115200)                      'Add debug port
  uarts.AddPort(1,config.GetPin(CONFIG#GPS_RX),config.GetPin(CONFIG#GPS_TX),{
}   UARTS#PINNOTUSED,UARTS#PINNOTUSED,UARTS#DEFAULTTHRESHOLD, {
}   UARTS#NOMODE,UARTS#BAUD38400)                       'Add gps port
  uarts.AddPort(2,config.GetPin(CONFIG#CMUCAM_RX),config.GetPin(CONFIG#CMUCAM_TX),{
}   UARTS#PINNOTUSED,UARTS#PINNOTUSED,UARTS#DEFAULTTHRESHOLD, {
}   UARTS#NOMODE,116500)                                'Add camera port
                                                        'The cmucam3 seems to need 116500 rather than
                                                        '115200, same with standard fullduplexserial
  uarts.Start                                           'Start the ports

  gps.configgps                                         'Config rest of gps settings

  cam.Init(2)                                           'use Init and then uses BackGround cog
                                                        'to process Camera receive characters
  
  cog := cognew(BackGround,@stack) + 1                  'Start the background Cog

  cam.ResetCamera                                       ' Reset Camera
  waitcnt(clkfreq*5 + cnt)                              'wait 5 seconds for adjustment
  cam.SetRegister(18,32)                                'auto white balance off
  cam.SetRegister(19,32)                                'auto off (white balance and exposure)
  
  cam.TrackWindow(1)
  time := cnt + clkfreq*2
  repeat
    if time < cnt                                       'every 2 sec check gps and camera
      time := cnt + clkfreq*2
      if byte[gps.valid] == "A"                         'if gps is tracking pring where we are
        GPS_Output                                      
      'cam.GetVersion                                   'test camera by getting version number
      if cam.TconfidenceValue > 128                     'if camera tracking print direction
        uarts.str(0, string("Tracking "))
        uarts.dec(0, cam.ServoX)
        uarts.str(0,string(" "))
        uarts.dec(0, cam.ServoY)
        uarts.newline(0)

PRI GPS_Output
  uarts.str(0,string("GPS available",13))
  uarts.str(0,string("Latitude "))
  uarts.str(0,gps.latitude)
  uarts.str(0,string(", Longitude "))
  uarts.str(0,gps.longitude)
  uarts.str(0,string(", GPS Altitude "))
  uarts.strln(0,gps.GPSaltitude)
  uarts.str(0,string("Speed "))
  uarts.str(0,gps.speed)
  uarts.str(0,string(", Heading "))
  uarts.str(0,gps.heading)
  uarts.str(0,string(" "))
  uarts.str(0,gps.N_S)
  uarts.str(0,gps.e_w)    
  uarts.str(0,string(", Satellites "))
  uarts.strln(0,gps.satellites)
  uarts.str(0,string("Time GMT "))
  uarts.str(0,gps.time)
  uarts.str(0,string(", Date "))
  uarts.strln(0,gps.date)

pub BackGround
'Process gps and camera receive characters
'minimize processing in this cog, i.e. dont send to serial ports e.g. debug
'dont call waitcnt, etc. Dont call blocking receives from serial ports - use rxcheck
  repeat
    cam.GetCameraInput
    gps.GetNMEALine

DAT
pininfo       word CONFIG#GPS_RX                'pin 0
              word CONFIG#GPS_TX                'pin 1
              word CONFIG#NOT_USED              'pin 2
              word CONFIG#NOT_USED              'pin 3
              word CONFIG#SERVO1                'pin 4
              word CONFIG#SERVO2                'pin 5
              word CONFIG#CMUCAM_TX             'pin 6
              word CONFIG#CMUCAM_RX             'pin 7
              word CONFIG#IPR_TX                'pin 8
              word CONFIG#IPR_RX                'pin 9
              word CONFIG#NOT_USED              'pin 10
              word CONFIG#NOT_USED              'pin 11
              word CONFIG#NOT_USED              'pin 12
              word CONFIG#NOT_USED              'pin 13
              word CONFIG#NOT_USED              'pin 14
              word CONFIG#NOT_USED              'pin 15
              word CONFIG#NOT_USED              'pin 16
              word CONFIG#NOT_USED              'pin 17
              word CONFIG#NOT_USED              'pin 18
              word CONFIG#NOT_USED              'pin 19
              word CONFIG#NOT_USED              'pin 20
              word CONFIG#NOT_USED              'pin 21
              word CONFIG#NOT_USED              'pin 22
              word CONFIG#NOT_USED              'pin 23
              word CONFIG#NOT_USED              'pin 24
              word CONFIG#NOT_USED              'pin 25
              word CONFIG#NOT_USED              'pin 26
              word CONFIG#NOT_USED              'pin 27
              word CONFIG#I2C_SCL1              'pin 28
              word CONFIG#I2C_SDA1              'pin 29
              word CONFIG#DEBUG_TX              'pin 30
              word CONFIG#DEBUG_RX              'pin 31
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}            
