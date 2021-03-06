{{
   ***************************************
   * Automatic_Polling_Base              *
   ***************************************
   *  See end of file for terms of use.  *               
   ***************************************

   Takes the place of user input to automatically
   poll the remote units. Sets LED state, Buzzer
   frequency and light level. Reads and displays
   RSSI dBm level from incoming data.

   Also controls all remotes using broadcast address.     

   *******************************************************
   * Martin Hebel, Electronic Systems Technologies, SIUC *
   * Version 1.0                                         *
   *******************************************************
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' Set pins and Baud rate for XBee comms  
  XB_Rx     = 0    ' XBee DOUT
  XB_Tx     = 1    ' XBee DIN
  XB_Baud   = 9600 ' XBee Baud Rate

  ' Set pins and baud rate for PC comms 
  PC_Rx     = 31  
  PC_Tx     = 30
  PC_Baud   = 9600    

  DL_Start  = 1    ' First address to poll
  DL_End    = 3    ' Last address to poll

  CR = 13
     
OBJ
   XB    : "XBee_Object"
   PC    : "XBee_Object" ' Using XBee object on PC side for more versatility 

VAR
   long Light, DataIn, DL_Addr, State, Freq ' Make global to keep values 
Pub  Start 
  XB.Delay(2000)
  PC.start(PC_Rx, PC_Tx, 0, PC_Baud) ' Initialize comms for PC
  PC.str(string("Configuring XBee...",CR)) 
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  XB.AT_Init                         ' Set up XBee for fast Command Mode
  XB.AT_Config(string("ATMY 0"))     ' Set base node's address

  repeat
    PC.str(string(CR,CR,"*** Individual Polling of Remotes ***"))
                                     ' Poll nodes from start to end address 
    repeat DL_Addr from DL_Start to DL_End    
      PC.str(string(CR,CR,"*** Controlling Node:         "))
      PC.DEC(DL_Addr)
      XB.AT_ConfigVal(string("ATDL "),DL_Addr)  ' Set remote address
      XB.Delay(100)                             ' Allow OK's buffer
      XB.RxFlush                                ' Empty buffer
      Set_LED                                   ' Send LED settings
      Set_Buzzer                                ' Send buzzer settings
      GetReading                                ' Request Light value
      GetdB                                     ' Read RSSI from remote's data
      XB.Delay(2000)                            ' 2 second delay
                                      ' Control all remotes using broadcast
   PC.str(string(CR,CR,"*** Controlling ALL Nodes ***"))
      DL_Addr := $FFFF                          ' Set broadcast address
      XB.AT_ConfigVal(string("ATDL "),DL_Addr)
      XB.Delay(100)                             ' Allow OK's to buffer
      XB.RxFlush                                ' Flush buffer
      Set_LED                                   ' Control LEDs
      Set_Buzzer                                ' Control Buzzers
      XB.Delay(4000)                            ' 4 second delay before repeating

Pub Set_LED 
  State += 100                                  ' Increase PWM state by 100
  if State > 1000                               ' limit 0 to 1000
    State := 0
  PC.str(string(CR,"Setting LED to:          "))
  PC.Dec(State)                                 
  XB.Tx("L")                                    ' Send L + value
  XB.Dec(State)
  XB.CR
  GetAck                                        ' Accept acknowledgement
  
Pub Set_Buzzer
  Freq += 500                                   ' Increase buzzer freq by 500
  if Freq > 5000                                ' limit freq 0 to 5000
    Freq := 0
  PC.str(string("Setting Frequency to:    "))
  PC.Dec(Freq)
  XB.Tx("B")                                    ' Send B + value
  XB.Dec(Freq)
  XB.CR
  GetAck                                        ' Accept acknowledgement
  
Pub GetReading
   PC.str(string("Getting Light Level:     "))
   XB.Tx("R")                                   ' Send R for light level
   Light := XB.RxDecTime(500)                   ' Accept returned data
   If Light == -1                               ' -1 means timeout
     PC.str(string("No Response"))
   else
     PC.Dec(Light)                              ' Display value

Pub GetdB
   PC.str(string(CR,"Getting RSSI dBm:       "))
   XB.RxFlush                                   ' Empty buffer
   XB.AT_Config(string("ATDB"))                 ' Request RSSI dB
   DataIn := XB.RxHexTime(500)                  ' Accept returning data in HEX
   If DataIn == -1                              ' -1 means timeout
     PC.str(string("No Response",CR))
   else
     PC.Dec(-DataIn)                            ' Display value in hex
               
Pub GetAck | Ack
  Ack := XB.RxTime(1000)                        ' Wait for ack value
  If Ack == -1                                  ' -1 = timeout
    PC.Str(string("-No Ack!",CR))
  elseif Ack == 1                               ' 1 = good value
    PC.str(string("-Ack! ",CR))
  else                                          ' Any other value is problem
    PC.str(string("-Bad Ack!",CR))

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
  