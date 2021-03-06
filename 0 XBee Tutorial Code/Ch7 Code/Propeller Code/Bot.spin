{{
   ***************************************
   * Bot code for networked bot example  *
   * Martin Hebel                        *
   * Version 1.0     Copyright 2009      *
   ***************************************
   *  See end of file for terms of use.  *               
   ***************************************

   Accept control information on node 0.
   Sends drive, range and bearing distance
   to all nodes on network.
    
}}
CON                          
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
  ' I/O and Baud rate for XBee comms 
  XB_Rx     = 16       ' XBee Dout
  XB_Tx     = 17       ' XBee Din
  XB_Baud   = 9600

  ' XBee addresses
  DL_Addr = $ffff     ' Send data to this address (both controller)
  MY_Addr = 1          ' This units address

  ' Set PING ))) I/O
  Ping_Pin  = 5

  ' Set HM55B Compass I/O
  Enable = 0
  Clock  = 1
  Data   = 2

  ' Set LED I/O
  grnLED = 3
  redLED = 4
  
  ' Servo outputs
  Pan   = 8
  Left  = 9
  Right = 10
  
VAR
  long  Range, Theta, PanOffset, dataIn, Value, IO
  long  Left_Dr, Right_Dr, Pan_Dr
  long  mapping , Stack[100]
    
OBJ
  XB    : "XBee_Object"
  Ping  : "ping"
  HM55B : "HM55B Compass Module Asm"
  SERVO : "Servo32v3"

  
PUB Start
  ' Initialize XBee Comms
  XB.Start(XB_Rx, XB_Tx ,0, XB_Baud)

  
  SERVO.Set(Pan,1500)                  ' Configure Servos 
  SERVO.Set(Left,1500)
  SERVO.Set(Right,1500)

  Left_Dr :=1500                       ' Set default values
  Right_Dr := 1500
  mapping := false
  
  dira[grnLED]~~                       ' Set LED directions
  dira[redLED]~~

  ' Enable XBee for fast configation changes &
  ' set MY and DL (destinaton) address.
  XB.AT_Init
  XB.AT_ConfigVal(string("ATMY"), MY_Addr)   
  XB.AT_ConfigVal(string("ATDL"),DL_Addr)

  
  SERVO.Start                         ' Start servo's

  cognew(SendUpdate,@stack)             ' Start cog to send values
  
  repeat
    XB.RxFlush                        ' clear data in buffer

       DataIn := XB.RxTime(1500)      ' wait for incoming byte
       If DataIn == -1                ' if no data after 1.5 seconds
           SERVO.Set(Right, 1500)     ' stop drive servos
           SERVO.Set(Left, 1500)
           repeat 5                   ' blink red LED 5 times
             outa[redLED]~~
             XB.delay(50)
             outa[redLED]~
             XB.delay(50)  

    case DataIn                       ' test acccepted data

      "i":                            ' i = I/O control
         IO := XB.Rx                  ' Accept IO number as byte value
         Value := XB.Rx               ' Accept state (1/0) as byte
         dira[IO]~~                   ' Set direction of pin
         outa[IO] := Value            ' Set state of pin

      "d":                            ' if drive data
           Right_dr    := XB.RxDEC    ' get right and left drive
           Left_dr     := XB.RxDEC
           SERVO.Set(Right, Right_dr) ' drive servos based on data
           SERVO.Set(Left, Left_Dr)

      "p":                            ' p = pan and map command
           mapping := true            ' set flag for mapping
           outa[grnLED]~~             ' turn on green LED
           Map                        ' go map
           outa[grnLED]~              ' turn off green LED
           repeat                     ' Blink greeen until m recv'd
             dataIn := XB.RxTime(100) ' accept data with 100mS timeout
             outa[grnLED]~~           ' blink green LED
             XB.delay(50)
             outa[grnLED]~
             XB.delay(50)
           while dataIn <> "p"        ' If data not 'm', repeat
           XB.Tx("c")                 ' done mapping - clear TV code
           XB.Delay(500)
           XB.rxFlush
           mapping := false           ' clear flag for mapping


Pub SendUpdate
  '' reads HM55B compass and sends all data update
  '' updates sent if not mapping

   HM55B.start(Enable,Clock,Data)     ' start compass
   
   Repeat
    if mapping == false               ' if not mapping
      XB.Delay(250)
      Range := Ping.Millimeters(PING_Pin)  ' read range
      theta := HM55B.theta                 ' Read Compass
      XB.TX("u")                           ' send "update" command
      XB.DEC(Range)             ' Send range as decimal string
      XB.CR
      XB.DEC(8191-theta)        ' Send theta of bearing (0-8191)
      XB.CR 
      xb.DEC(Right_Dr)          ' send right drive
      XB.CR 
      XB.DEC(Left_Dr)           ' send left drive
      XB.CR
                 

Pub Map | panValue
 '' turns servo from -45 to + 45 drees from center in increments
 '' gets ping range and returns m value at each
    
    SERVO.Set(Right, 1500)      ' stop servos
    SERVO.Set(Left, 1500)
    
    SERVO.Set(Pan, 1000)        ' pan full right
    XB.Delay(1000)
                                ' pan right to left
    repeat panValue from 1000 to 2000 step 15
      SERVO.Set(Pan,panValue)
      Range := Ping.Millimeters(PING_Pin)   ' get range calculate
                                            ' based on compass
                                            ' and pan
      PanOffset := ((panValue-1500) * 2047/1000)//8192 
      XB.TX("m")                            ' send map data command
      XB.DEC(Range)                         ' Send range as decimal
      XB.CR                                                              
      XB.DEC((8191-Theta) +PanOffset)       ' Send theta of bearing
      XB.CR
      XB.delay(50)
    XB.delay(1000)

    SERVO.SET(Pan,1500)                  ' recenter pan servo
    
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
  


      