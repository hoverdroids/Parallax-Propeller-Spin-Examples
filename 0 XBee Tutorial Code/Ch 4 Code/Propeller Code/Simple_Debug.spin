{{
   ***************************************
   * Simple_Debug                        *
   ***************************************
   *  See end of file for terms of use.  *               
   ***************************************

   Demonstrates debugging to PC terminal

   *******************************************************
   * Martin Hebel, Electronic Systems Technologies, SIUC *
   * Version 1.0                                         *
   *******************************************************
     
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' Set pins and Baud rate for XBee comms  
  XB_Rx     = 0        ' XBee Dout
  XB_Tx     = 1        ' Xbee Din
  XB_Baud   = 9600


  CR        = 13  ' Carriage Return value      
   
Var
  word stack[50]
                                                                       
OBJ
   XB    : "FullDuplexSerial"

Pub  Start | Counter
XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  
Delay (1000)                       ' one second delay
repeat Counter from 1 to 20        ' count up to 20

  ' Send to Base
  XB.str(string("Count is:"))      ' send string
  XB.dec(Counter)                  ' send decimal value
  XB.Tx(CR)                        ' send Carriage Return

  Delay(250)                       ' Short delay 

pub Delay(mS)       ' Delay in milliseconds  
   waitcnt(clkfreq / 1000 * mS + cnt)

  
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