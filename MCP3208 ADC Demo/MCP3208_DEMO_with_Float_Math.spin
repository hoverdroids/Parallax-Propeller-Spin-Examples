{{
OBEX LISTING:
  http://obex.parallax.com/object/371

  This demo demonstrates the Microchip MCP3208 8 channel adc chip connected to the Parallax Propeller Demo Board. It uses the MCP3208.spin object Written by Chip Gracey and outputs the adc value (0-4096) of all 8 channels (labeled as 0-7) in Parallax Serial Terminal.
  *MODIFIED by Chris Sprague
}}
{{
File: MCP3208_DEMO.spin
Author: Mike Rector, KF4IXM
Version: 1.0
Copyright (c) Mike Rector, KF4IXM
See end of file for Terms of Use.
}}

{{
This demo demonstrates the Microchip MCP3208 8 channel adc chip connected to the Parallax
Propeller Demo Board. It uses the MCP3208.spin object Written by Chip Gracey and outputs the adc
value (0-4096) of all 8 channels (labeled as 0-7) in Parallax Serial Terminal.
The Datasheet of the MCP3208 can be found here:
http://ww1.microchip.com/downloads/en/devicedoc/21298c.pdf
Connect both AGnd (pin 14) and DGnd (pin 9) of the MCP3208 to the Vss of the demo board.


}}

CON
    _clkmode = xtal1 + pll16x                           
    _xinfreq = 6_000_000

OBJ
adc     : "MCP3208"
pst     : "Parallax Serial Terminal"
math    : "FloatMath"
fstring : "FloatString"

CON
dpin = 26'0       'both din and dout of the mcp3208 are connected to this pin on the prop demo board.
cpin = 27'1       'the clock pin of the mcp3208 is connected to this pin on the prop demo board.
spin = 28'2       'the chip select pin of the mcp 3208 is connected to this pin on the prop demo board.
var
long volts[8]
byte i

pub go
pst.start(115200)   'Start the Parallax Serial Terminal object at 115200 baud
adc.start(dpin, cpin, spin, 255)  'Start the MCP3208 object and enable all 8 channels as
i:=0                                  'single-ended inputs.


repeat
  repeat 8
    volts[i]:=math.FFloat(adc.in(i))         'first convert the integer to a float
    volts[i]:=math.FDiv(math.FMul(volts[i], 20.15),4096.0)       'convert the float to a voltage 
    i++                                                          'NOTE:20.15 is the multiply factor for the battery and voltage divider circuit on the AIQB
                                                                 'the 4096.0 is top bin number of the ADC and the .0 is required for the floating point math
  i:=0
  pst.Str(String(pst#cs, pst#NL, pst#HM, "adc channel 0= "))
  pst.Str(fstring.FloatToString(volts[0]))
  'pst.dec(adc.in(0))
  pst.Str(String(pst#NL, "adc channel 1= "))
  pst.Str(fstring.FloatToString(volts[1])) 
  'pst.dec(adc.in(1))
  pst.Str(String(pst#NL, "adc channel 2= "))
  pst.Str(fstring.FloatToString(volts[2])) 
  'pst.dec(adc.in(2))
  pst.Str(String(pst#NL, "adc channel 3= "))
  pst.Str(fstring.FloatToString(volts[3])) 
  'pst.dec(adc.in(3))
  pst.Str(String(pst#NL, "adc channel 4= "))
  pst.Str(fstring.FloatToString(volts[4])) 
  'pst.dec(adc.in(4))
  pst.Str(String(pst#NL, "adc channel 5= "))
  pst.Str(fstring.FloatToString(volts[5])) 
  'pst.dec(adc.in(5))
  pst.Str(String(pst#NL, "adc channel 6= "))
  pst.Str(fstring.FloatToString(volts[6])) 
  'pst.dec(adc.in(6))
  pst.Str(String(pst#NL, "adc channel 7= "))
  pst.Str(fstring.FloatToString(volts[7])) 
  'pst.dec(adc.in(7))
 waitcnt(clkfreq/10 + cnt)        '10Hz screen refresh

 {{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}
