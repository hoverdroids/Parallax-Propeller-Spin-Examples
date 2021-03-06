{{
   ***************************************
   *  Manual_Polling_Base                *
   ***************************************
   *  See end of file for terms of use.  *               
   ***************************************

   Uses a terminal window to request actions from the user
   to control a remote with LED, buzzer and photo resistor.

   User selects remote node address and choses to control LED using PWM
   value, control buzzer frequency or to read the value of the light sensor.      

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

  CR = 13         ' Carriage Return
     
OBJ
   XB    : "XBee_Object"
   PC    : "XBee_Object" ' Using XBee object on PC side for more versatility 


Pub  Start | Light, DataIn, DL_Addr, State, Freq
  
  XB.Delay(2000)
  PC.start(PC_Rx, PC_Tx, 0, PC_Baud) ' Initialize comms for PC
  PC.str(string("Configuring XBee...",CR)) 
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  XB.AT_Init                         ' Set up for fast Command Mode
  XB.AT_Config(string("ATMY 0"))     ' Set address of base

  repeat
    PC.CR                             ' User defines remote node address
    PC.str(string("*** Enter address of node ***",CR)) 
    PC.str(string("(1 to FFFE or FFFF for all):"))
    DL_Addr := PC.RxHex               ' Accept address in hex and sets XBee DL
    XB.AT_ConfigVal(string("ATDL "),DL_Addr)
                                      ' User choses action to take
    PC.str(string(CR,"***** Choose Action: *****",CR))
    PC.str(string("L - Control LED",CR))
    PC.str(string("B - Contol Buzzer",CR))
    PC.str(string("R - Read Sensor",CR))
    DataIn := PC.Rx                   ' Accept action
    XB.RxFlush
    
    case DataIn                        
       "L","l": PC.str(string(CR,"Enter LED state (0-1023): "))
                State := PC.RxDec      ' Accept value for state
                XB.tx("L")             ' Transmit L followed by State
                XB.Dec(State)
                XB.CR
                GetAck                 ' Check for acknowledgement
                   
       "B","b": PC.str(string(CR,"Enter buzzer Frequency (0-5000): "))
                Freq := PC.RxDec       ' Accept value for frequency       
                XB.tx("B")             ' Transmit F followed by State 
                XB.Dec(Freq)                                          
                XB.CR                                                 
                GetAck                 ' Check for acknowledgement    
                                  
       "R","r": XB.Tx("R")             ' Transmit R to remote
                Light := XB.RxDecTime(500)  ' Accept response
                if Light == -1              ' If no data returned,
                  PC.str(string(CR,"No Response",CR))
                else                        ' Else, good data
                  PC.str(string(CR,"Light Level = "))
                  PC.dec(light)
                  PC.CR
    PC.Delay(2000)
                     
Pub GetAck | Ack
  Ack := XB.RxTime(500)                 ' wait for response
  If Ack == -1                          ' -1, no ack received
    PC.Str(string("-No Ack!",CR))
  elseif Ack == 1                       ' 1, good ack
    PC.str(string("-Good Ack! ",CR))
  else                                  ' any other value - problem
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
  