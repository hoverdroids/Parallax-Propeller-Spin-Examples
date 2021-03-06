''****************************************
''*  Timer32 Demo                        *
''*  Authors: Jean-Marc Spaggiari        *
''*           jean-marc@spaggiari.org    *
''*  See end of file for terms of use.   *
''****************************************



CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  '_xinfreq = 6_250_000


OBJ
  sx : "FullDuplexSingleton"
  timer1 : "Timer32"
  timer2 : "Timer32"

PUB Main
  sx.start(31,30,0,115200)
  sx.str(string($d,"Timer32_Demo",$d))

  sx.str(string($d,"Test frequency is "))
  sx.dec(clkfreq)

  timer1.init ' Not required if you are running at 80Mhz
  timer1.mark
  sx.str(string($d,"Waiting 5 seconds using tick..."))
  repeat until timer1.TimeOutS(5)
    timer1.tick
  sx.str(string("Done",$d))

  sx.str(string($d,"Waiting 5 seconds using tick while using another timer"))
  timer1.mark
  timer2.mark
  repeat until timer1.TimeOutS(5)
    if (timer2.TimeOutS(1))
      timer2.mark
      sx.str(string("."))
    timer1.tick
    timer2.tick
  sx.str(string("Done",$d))

  sx.str(string($d,"Waiting 5 seconds using tickAll..."))
  timer1.init '' Required for TickAll
  timer1.mark
  repeat until timer1.TimeOutS(5)
    timer1.tickAll
  sx.str(string("Done",$d))

  sx.str(string($d,"Waiting 5 seconds using tickAll while using another timer"))
  timer1.mark
  timer2.mark
  timer2.init '' Required for TickAll. Already done previously for timer1. Only once time per timer.
  repeat until timer1.TimeOutS(5)
    if (timer2.TimeOutS(1))
      timer2.mark
      sx.str(string("."))
    timer1.tickAll
  sx.str(string("Done",$d))

  sx.str(string($d,"Waiting 5 seconds using cog ticking while using another timer"))
  '' No need to call init for timer1 and timer2 since it has already been done.
  timer1.mark
  timer2.mark
  timer1.start '' Start the cog.
  repeat until timer1.TimeOutS(5)
    if (timer2.TimeOutS(1))
      timer2.mark
      sx.str(string("."))
  sx.str(string("Done",$d))

  sx.str(string("End of the demo",$d))

  repeat


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