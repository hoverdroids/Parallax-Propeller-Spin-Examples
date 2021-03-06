{{
OBEX LISTING:
  http://obex.parallax.com/object/26

  i2cObject and device examples. Implements i2c and gives examples of EEPROM's, DS1307, DS1621
  and www.robot-electronics.com products i.e. SRF08 and the MD22.
}}
'' ******************************************************************************
'' * I2C Demo Propeller program                                                 *
'' * James Burrows May 2006                                                     *
'' * Version 1.3                                                                *
'' *                                                                            *
'' * Demos:  i2cObject                                                          *
'' *                                                                            *
'' * by demo'ing:                                                               *
'' *    DS1621, DS1307, MCP23016, SRF08, MD22 and EEPROM objects                *
'' ******************************************************************************
''
'' this object provides the PUBLIC functions:
''  -> Start  
''
'' this object provides the PRIVATE functions:
''  -> DS1307_demo    - read the time for 30secs, demo the set and time/date roll-over
''  -> DS1621_demo    - read the temperature for a few secs
''  -> MD22_demo      - run the motor controller - forward back and turn
''  -> SRF08_demo     - read the distance and light from the sensors
''  -> MCP23016_Demo  - flash some LED's with the the I/O expander
''  -> EERPOM_demo    - write and read back 10 locations (0-9) in the EEPROM
''  -> i2cScan        - scan the bus. Show results on LCD
''
'' Revision History:
''  -> V1 - Release
''      -> V1.1 - Documentation update, slight code tidy-up
''                i2cWrite Changed so the i2cBits parameter is only a shift counter.
''                i2cWrite always outputs 8 bits only.
''                Uses the Parallax Simple numbers library for LCD debug
''      -> V1.2 - Added SRF08, MD22, MCP23016 objects
''                Changed device objects to only initialize if the device is present on the bus (i2cObject.devicePresent)
''                Added 2 extra 1k resistors in the middle of the i2c bus to split the +5 and +3.3 devices!
''      -> V1.3 - Extra i2cObject.Init parameter to allow for the propeller dev board not having pull-up
''                Resistors on the pins 28/29 when used for i2c.  See the i2cObject for more details. 
''
''
'' this object uses the following sub OBJECTS:
''  -> i2cObject
''  -> LCDObject
''  -> DS1621Object
''  -> DS1307Object
''  -> MCP23016Object
''  -> SRF08Object
''  -> MD22Object
''
''
'' Part information:
''  -> DS1307/DS1621/EEPROM/SRF08/MD22/MCP23016 - see the sub-objects documentation
''  -> 24LC256 - see www.microchip.com
''  ->         - page - http://www.microchip.com/stellent/idcplg?IdcService=SS_GET_PAGE&nodeId=1335&dDocName=en010823
''  -> LCD - 4x20 line. serial -9600 (negative) - website is: www.milinst.com
''
''                        4.7K                       3.3V         3.3V           5V                5V   MD22   5V
''                    ┌──────  3.3V      24LC256──┘    DS1621──┘     DS1307-─┘       MCP23016──┘    SRF08──┘  
''                    │ ┌────  3.3V        │ │          │ │            │ │             │ │           │ │
''               1k   │ │                      │ │          │ │            │ │      1k     │ │           │ │
''   Pin21/SDA ────┻─┼──────────────────────┻─┼──────────┻─┼────────────┻─┼──────────┻─┼───────────┘ │
''               1k     │                        │            │              │      1k       │             │
''   Pin20/SCL ──────┻────────────────────────┻────────────┻──────────────┻────────────┻─────────────┘
''
''               1k
''   Pin15  ───────── LCD Serial Pin 
''
''
'' Instructions (brief):
'' (1) - setup the propeller - see the Parallax Documentation (www.parallax.com/propeller)
'' (2) - Use a 5mhz crystal on X1 and X2
'' (3) - Connect the SDA lines to Propeller Pin21, and SCL lines to Propeller Pin20.
''       See diagram above for resistor placements.
''       Note that the DS1307 does not provide enough current to drive from the 5v section
''       OPTIONAL: Connect the DS1307, DS1621, SRF08, MD22 and 24LC256 (EEPROM) devices - the demo will work if they
''                 are not all present!   
''       OPTIONAL: Connect LED's to MCP23016 pins G0.1,2 & 3, GP1.1,2 & 3        
'' (4) - Connect a LCD (you may have to modify my code, or use the Parallax Debug LCD object to work)
''       Connect the LCD to Propeller Pin15 via a 1K resistor
''       Update the LCD_Baud (must not be negative), and the LCD_Lines to be correct
'' (5) - OPTIONAL: Update the i2c Address's for the i2c if you are not using their base address's.
'' (6) - Run the app - watch your LCD
''
''
'' Support:
'' I will support this on the Parallax propeller forum - send me a PM when you post incase i dont see it!
     

CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000
  _stack        = 50
    
  i2cSCL        = 28
  i2cSDA        = 29 

  LCD_Pin       = 15
  LCD_Baud      = 9600
  LCD_Lines     = 20

  MCP23016_Addr = %0100_0000  
  DS1621_Addr   = %1001_0000
  EEPROM_Addr   = %1010_0000  
  DS1307_Addr   = %1101_0000
  SRF08_Addr    = %1110_0010
  MD22_Addr     = %1011_0000  
  
VAR
  long  i2cAddress, i2cSlaveCounter

OBJ
  LCDObject      : "LCDObject"
  i2cObject      : "i2cObject"
  DS1621Object   : "DS1621Obj"
  DS1307Object   : "DS1307Obj"
  MCP23016Object : "MCP23016Object"
  SRF08Object    : "SRF08Object"
  MD22Object     : "MD22Object"
  
  
pub Start
  ' init my LCD
  LCDObject.init(LCD_Pin, LCD_Baud, true, LCD_Lines)
  
  ' setup i2cobject
  i2cObject.Init(i2cSDA, i2cSCL, false)
  
  ' setup the DS1621 thermometer
  DS1621Object.init(DS1621_Addr, i2cSDA, i2cSCL,false)
  
  ' setup the DS1307 clock
  DS1307Object.init(DS1307_Addr, i2cSDA, i2cSCL,false)

  ' setup the MCP32016 I/O Expander
  MCP23016Object.init(MCP23016_Addr, i2cSDA, i2cSCL,false)

  ' setup the SRF08 Distance Sensor - init to CM ranging and 1M max
  SRF08Object.init(SRF08_Addr, srf08Object#_SRF_CM_Range, srf08Object#_SRF_Range1m, i2cSDA, i2cSCL,false)  

  ' setup the MD22 motor controller - set to mode 0 
  MD22Object.init(MD22_Addr, MD22Object#_MD22_Mode0, i2cSDA, i2cSCL,false)

  repeat 
    ' clear LCD
    lcdobject.clearlcd
   
    ' i2c state
    lcdobject.positionlcd(1,0)
    lcdobject.outputstring(string("I2C Demo!"))
    lcdobject.positionlcd(2,0)                   
    if i2cObject.isStarted == true
      lcdObject.outputString(string("Started OK"))
    else
      lcdObject.outputString(string("Start Failed"))
    lcdobject.positionlcd(3,0)
    lcdobject.outputstring(string("i2c Error:"))
    lcdobject.outputnumber(i2cObject.getError)        
    waitcnt(150_000_000+cnt)          

    'demo the i2c scan
    lcdobject.clearlcd  
    i2cScan
    waitcnt(150_000_000+cnt)

    ' demo the EEPROM
    if i2cObject.devicePresent(EEPROM_Addr) == true
      lcdobject.clearlcd  
      lcdObject.changeline(4,string("EEPROM Present"))
      EEPROM_Demo
    else
      lcdobject.clearlcd  
      lcdObject.changeline(4,string("EEPROM Missing"))    
    waitcnt(150_000_000+cnt)    

    ' demo the SRF08 distance Sensor
    if SRF08Object.isStarted == true
      lcdobject.clearlcd
      lcdobject.changeline(4,string("SRF08 Present"))
      SRF08_Demo
    else
      lcdobject.clearlcd    
      lcdobject.changeline(4,string("SRF08 Missing"))    
    waitcnt(150_000_000+cnt)    

    ' demo the MD22 Motor Controller
    if MD22Object.isStarted == true
      lcdobject.clearlcd
      lcdobject.changeline(4,string("MD22 Present"))
      MD22_Demo
    else
      lcdobject.clearlcd    
      lcdobject.changeline(4,string("MD22 Missing"))      
    waitcnt(150_000_000+cnt)
   
    ' demo the MCP23016 I/O expander
    if MCP23016Object.isStarted == true
      lcdobject.clearlcd
      lcdobject.changeline(4,string("MCP23016 Present"))
      MCP23016_Demo
    else
      lcdobject.clearlcd    
      lcdobject.changeline(4,string("MCP23016 Missing"))        
    waitcnt(150_000_000+cnt)

    ' demo the DS1307
    if DS1307Object.isStarted == true
      lcdobject.clearlcd
      lcdobject.changeline(4,string("DS1307 Present"))
      DS1307_demo
    else
      lcdobject.clearlcd    
      lcdobject.changeline(4,string("DS1307 Missing"))    
    waitcnt(150_000_000+cnt)  
   
    ' demo the DS1621
    if DS1621Object.isStarted == true
      lcdobject.clearlcd  
      lcdobject.changeline(4,string("DS1621 Present"))    
      DS1621_Demo
    else
      lcdobject.clearlcd    
      lcdobject.changeline(4,string("DS1621 Missing"))    
    waitcnt(150_000_000+cnt)
    


PRI MD22_Demo
  ' demo the MD22 Motor Controller
  ' MODE 0, forwards, backwards, turn and stopped
    LCDObject.changeline(1,string("MD22 DEMO"))
    LCDObject.positionLCD(4,15)
    LCDObject.output("v")
    LCDObject.outputnumber(MD22Object.getSoftwareRev)    

    ' slow forward    
    LCDObject.changeline(2,string("Forward"))
    MD22Object.setSpeed(128-20,128-20)
    repeat 10
      LCDObject.output(".")
      waitcnt(10_000_000+cnt)
    MD22Object.setSpeed(128,128)

    waitcnt(150_000_000+cnt) 

    ' slow backward
    LCDObject.changeline(2,string("Backwards"))
    MD22Object.setSpeed(128+20,128+20)
    repeat 10
      LCDObject.output(".")
      waitcnt(10_000_000+cnt)      
    MD22Object.setSpeed(128,128)

    waitcnt(150_000_000+cnt)
                                        
    ' slow turn
    LCDObject.changeline(2,string("Turn"))
    MD22Object.setSpeed(128+20,128-20)
    repeat 10
      LCDObject.output(".")
      waitcnt(10_000_000+cnt)      
    MD22Object.setSpeed(128,128)

    waitcnt(150_000_000+cnt)      

    ' Stopped
    LCDObject.changeline(2,string("Stopped"))
    MD22Object.setSpeed(128,128)

    waitcnt(250_000_000+cnt)

    
PRI SRF08_Demo | i2cdata
  ' DEMO the SRF08 Ultrasonic Ranger
  repeat 5
    LCDObject.changeline(1,string("SRF08 Demo"))
    LCDObject.changeline(2,string("Distance is:"))
    LCDObject.changeline(3,string("Light is   :"))
    LCDObject.positionLCD(4,15)
    LCDObject.output("v")
    LCDObject.outputnumber(SRF08Object.getSwVersion)
          
    ' initialize ranging on the SRF08
    SRF08Object.initRanging
    
    ' wait a tick - must be at least 65ms
    waitcnt(50_000_000 + cnt)
     
    ' get the results and display
    LCDObject.positionLCD(2,14)

    ' display it
    LCDObject.outputnumber(SRF08Object.getRange)
    LCDObject.outputstring(string("cm"))    
    LCDObject.positionLCD(3,14)
    LCDObject.outputnumber(SRF08Object.getLight)  
     
    ' wait
    waitcnt(200_000_000+cnt)
     

PRI DS1307_demo | secs
  ' DEMO the DS1307 Real Time Clock (RTC)
  secs := ds1307object.gettime
  if secs == 80
    ' the clock has not been initialised so lets set it
    ' this will demonstrate hour & day roleover. 
    ds1307object.settime(23,59,45)  ' 23:59:45
    ds1307object.setdate(1,1,5,06)  ' 1/5/2006 - day 1  

  ' run for approx 30 secs
  repeat 30
    ' get and display the TIME
    lcdobject.clearline(1)
    lcdObject.outputstring(string("TIME: "))    
    lcdObject.positionlcd(1,7)
    ds1307object.gettime
    lcdobject.outputnumber (ds1307object.getHours)
    lcdobject.output(":")
    lcdobject.outputnumber (ds1307object.getMinutes)
    lcdobject.output(":")                                       
    lcdobject.outputnumber (ds1307object.getSeconds)

    ' get and display the DATE
    lcdObject.clearline(2)
    lcdObject.outputstring(string("DATE: "))    
    lcdObject.positionlcd(2,7)
    ds1307object.getdate
    lcdobject.outputnumber (ds1307object.getDays)
    lcdobject.output("/")
    lcdobject.outputnumber (ds1307object.getMonths)
    lcdobject.output("/")                                       
    lcdobject.outputnumber (ds1307object.getYears)

    ' wait a tick or two
    waitcnt(60_000_000+cnt)
   

    
PRI MCP23016_Demo | counter, mcpstate, ackbit
  ' demo the MCP32016 i2c I/O Expander
  lcdobject.changeline(1,string("Init...."))
  MCP23016Object.WriteIOregister0(%0000_0000)
  MCP23016Object.WriteIOregister1(%0000_0000)

  waitcnt(50_000_000 + cnt)  

  repeat counter from 0 to 8
    lcdobject.changeline(1,string("Counting..."))
    lcdobject.outputnumber(counter)      
    MCP23016Object.writeGP0(counter)
    MCP23016Object.writeGP1(8-counter)

    ' read GP0 state
    mcpState := MCP23016Object.ReadGP0
    lcdobject.changeline(2,string("GP0 State: "))
    lcdobject.outputbinary(mcpState,8)

    ' read GP1 state    
    mcpState := MCP23016Object.ReadGP1
    lcdobject.changeline(3,string("GP1 State: "))
    lcdobject.outputbinary(mcpState,8)    
    
    waitcnt(50_000_000+cnt)    
  
  repeat counter from 0 to 8

    case counter // 3
      0 : ' case 0
        lcdobject.changeline(1,string("GP0 High, GP1 Low"))
        lcdobject.positionlcd(2,0)  
        MCP23016Object.WriteGP0(%1111_1111)
        MCP23016Object.WriteGP1(%0000_0000)         
      1: ' case 1
        lcdobject.changeline(1,string("GP0 Low, GP1 High"))
        lcdobject.positionlcd(2,0)     
        MCP23016Object.WriteGP0(%0000_0000)        
        MCP23016Object.WriteGP1(%1111_1111)
      2: ' case 2
        lcdobject.changeline(1,string("GP0 Low, GP1 Low"))    
        MCP23016Object.WriteGP0(%0000_0000)
        MCP23016Object.WriteGP1(%0000_0000)         

    ' read GP0 and GP1 state
    mcpState := MCP23016Object.ReadGP0
    lcdobject.changeline(2,string("GP0 State: "))
    lcdobject.outputbinary(mcpState,8)

    mcpState := MCP23016Object.ReadGP1
    lcdobject.changeline(3,string("GP1 State: "))
    lcdobject.outputbinary(mcpState,8)    

    waitcnt(100_000_000 + cnt)    


  
PRI EEPROM_Demo | eepromData, eepromLocation, EEPROM_array[10], ackbit
  ' demo the i2c Serial EEPROM (Microchip's 24LC256)
  
  ' ***** EEPROM Random read/Write example *****
  ' each is written to with 100-location, so you'll see the values 99,98,97 etc
  lcdObject.changeline(1,string("Random Read/Write "))
  repeat eepromLocation from 0 to 10 
    ' write the byte to the location
    lcdObject.changeline(2,string("Write "))
    lcdObject.outputNumber(eepromLocation)
    lcdObject.output(" ")         
    i2cObject.writeLocation(EEPROM_ADDR, eepromLocation, 100-eepromLocation, 16, 8)

    ' wait a tick or two
    waitcnt(100_000 + cnt)

    ' read back the same location 
    lcdObject.changeline(3,string("Read: "))
    lcdobject.outputnumber(eepromlocation)
    lcdObject.output(" ")     
    eepromdata := 0                                                                      
    eepromdata := i2cObject.readLocation(EEPROM_ADDR, eepromlocation, 16, 8)
    lcdobject.outputnumber(eepromdata)

    ' wait a tick or two
    waitcnt(30_000_000 + cnt)  
  

    
PRI DS1621_Demo | tempvar,ackbit
  ' DEMO DS1621 i2c Temperature sensor
  lcdObject.positionlcd(1,0)
  lcdobject.outputString(String("Temp is: "))

  ' setup the config - one shot conversion mode
  DS1621Object.writeConfig(ds1621object#_OneShotMode)

  ' wait tick or two
  waitcnt(20_000_000+cnt)

  repeat 5
    ' init temp conversion
    DS1621Object.startConversion

    ' wait a tick or two
    waitcnt(20_000_000+cnt)
     
    ' read temp C
    tempvar := DS1621Object.readTempC
    lcdobject.positionlcd(1,10)
    lcdobject.outputnumber (tempvar)
    lcdObject.outputstring(string("  "))     

    ' read the Config register - it displays 65 - i.e. %0100_0001 - TH and data ready set
    tempvar := DS1621Object.readConfig
    lcdobject.positionlcd(2,0)
    lcdObject.outputstring(string("ConfigReg: "))
    lcdobject.outputbinary (tempvar,8)
    lcdObject.outputstring(string("  "))

    ' wait several ticks
    waitcnt(20_000_000+cnt)  
              

  
PRI i2cScan | value, ackbit
  ' Scan the I2C Bus and debug the LCD
  lcdobject.clearLCD
  lcdobject.positionlcd(1,0)
  lcdobject.outputstring(string("Scanning I2C Bus...."))

  ' initialize variables
  i2cSlaveCounter := 0
  
  ' i2c Scan - scans all the address's on the bus
  ' sends the address byte and listens for the device to ACK (hold the SDA low)
  repeat i2cAddress from 0 to 127
   
    value :=  i2cAddress << 1 | 0
    ackbit := i2cObject.devicePresent(value)

    ' show the scan on the LCD
    lcdobject.changeline(2,string("Scan Addr : "))
    if (value < 10)
      lcdObject.output("0")    
    if (value < 100)
      lcdObject.output("0")    
    lcdObject.OutputNumber(value)
    lcdObject.outputstring(string(" "))
    if ackbit==true
      lcdObject.outputstring(string("ACK"))
    else
      lcdObject.outputstring(string("NAK"))      

    ' the device has set the ACK bit 
    if ackbit == true
      lcdobject.changeline(3,string("Last Dev  : "))
      lcdObject.OutputNumber(value)
      i2cSlaveCounter ++
      waitcnt(50_000_000+cnt)

    ' update the counter
    lcdobject.changeline(4,string("Devices   : "))
    lcdobject.outputnumber(i2cSlaveCounter)    
      
    ' slow the scan so we can read it.    
    waitcnt(20_000_000 + cnt)
