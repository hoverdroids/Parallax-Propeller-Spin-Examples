{{
*****************************************
* Memsic 2125 graphic demo v1.1         *
* Author: Beau Schwabe                  *
* Copyright (c) 2007 Parallax           *
* See end of file for terms of use.     *
*****************************************


History:

Version 1.0 - original release
Version 1.1 - modified code to return RAW x and y values

}}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  _stack = ($3000 + $3000 + 100) >> 2                   'accommodate display memory and stack

  x_tiles = 16
  y_tiles = 12

  paramcount = 14       
  bitmap_base = $2000
  display_base = $5000

  Gnum = 3                                              'Number of G's to display on demo screen

VAR

  long  tv_status     '0/1/2 = off/visible/invisible           read-only
  long  tv_enable     '0/? = off/on                            write-only
  long  tv_pins       '%ppmmm = pins                           write-only
  long  tv_mode       '%ccinp = chroma,interlace,ntsc/pal,swap write-only
  long  tv_screen     'pointer to screen (words)               write-only
  long  tv_colors     'pointer to colors (longs)               write-only               
  long  tv_hc         'horizontal cells                        write-only
  long  tv_vc         'vertical cells                          write-only
  long  tv_hx         'horizontal cell expansion               write-only
  long  tv_vx         'vertical cell expansion                 write-only
  long  tv_ho         'horizontal offset                       write-only
  long  tv_vo         'vertical offset                         write-only
  long  tv_broadcast  'broadcast frequency (Hz)                write-only
  long  tv_auralcog   'aural fm cog                            write-only

  word  screen[x_tiles * y_tiles]
  long  colors[64]

  long  clk_scale, G_scale


OBJ

  tv    : "tv"
  gr    : "graphics"
  acc   : "memsic2125"

PUB start | i, dx, dy, raw, mg, deg

  'start tv
  longmove(@tv_status, @tvparams, paramcount)
  tv_screen := @screen
  tv_colors := @colors
  tv.start(@tv_status)

  'init colors
  repeat i from 0 to 63
    colors[i] := $00001010 * (5+4) & $F + $2B060C02

  'init tile screen
  repeat dx from 0 to tv_hc - 1
    repeat dy from 0 to tv_vc - 1
      screen[dy * tv_hc + dx] := display_base >> 6 + dy + dx * tv_vc + ((dy & $3F) << 10)

  'start and setup graphics
  gr.start
  gr.setup(16, 12, 128, 96, bitmap_base)

  acc.start(0, 1)                                       'start memsic 2125                                                      
  waitcnt(clkfreq/10 + cnt)                             'wait for things to settle 
  acc.setlevel                                          'assume at startup that the memsic2125 is level

  clk_scale := clkfreq / 500_000                        'set clk_scale based on system clock



  G_scale := 2000/(256/Gnum)                            'Convert Gnum to G_scale valuable...
                                                        '   G_scale := 2 x 1000mg / (ScreenWidth / [ G's to display ]) 

  repeat

    gr.clear                                            'Clear graphics screen

    gr.colorwidth(3, 0)                                 'Set Color and Width

    G_ring(259)                 '15°                    'Display DEG rings under 1G at 15 deg intervals
    G_ring(500)                 '30°
    G_ring(707)                 '45°
    G_ring(866)                 '60°
    G_ring(966)                 '75°
    G_ring(1000)                '90°
    
    repeat i from 2000 to Gnum*1000 step 1000           'Display a ring for every G above 1G
      G_ring(i)                                         

    gr.colorwidth(1, 0)                                 'draw cross hairs
    gr.plot(0,-100)
    gr.line(0,100)
    gr.plot(-100,0)
    gr.line(100,0)
            
    gr.colorwidth(2,1)                                  'Set Color and Width
    
    raw := acc.ro                                       'Get raw value for acceleration
    mg := raw / clk_scale                               'convert raw acceleration value to mg's
    i := mg / G_scale                                   'scale mg value for screen display                                   '
    
    deg := acc.theta >> 19                              'scale 32-bit value to a 13-bit value

    gr.arc(0, 0, i, i, deg, 0, 1, 3)                    'draw vector


    gr.colorwidth(2, 0)                                 'Set Color and Width
    gr.textmode(1,1,7,%0000)                            'Set text mode
    gr.text(-100,80,string("Memsic2125 Accelerometer Demo"))                    'Display Header Text
    
    gr.text(-100,60,string("G ="))                      'Display acceleration in G's                     
    SimpleNum(-30,60,mg,3)

    gr.text(-100,40,string("Deg ="))                    'Display rotational degree
    SimpleNum(-30,40,deg*3600/8192,1)

    gr.text(-100,-40,string("X ="))                     'Display raw X value                     
    SimpleNum(-30,-40,acc.Mx,-1)

    gr.text(-100,-60,string("Y ="))                     'Display raw Y value                     
    SimpleNum(-30,-60,acc.My,-1)


    gr.copy(display_base)                               'copy bitmap to display

PUB G_ring(Sin)
    gr.arc(0, 0, Sin/G_scale,Sin/G_scale, 0, $100, $21, 2)    

PUB SimpleNum(x,y,DecimalNumber,DecimalPoint)|sign,DecimalIndex,TempNum,spacing,DecimalFlag,Digit
{     x,y           - lower right text coordinate
      DecimalNumber - signed Decimal number
      DecimalPoint  - number of places from the Right the decimal point should be
}
    spacing := 7
    DecimalIndex := 0

    TempNum := DecimalNumber                            'Preserve sign of DecimalNumber
    DecimalNumber := ||DecimalNumber
    if DecimalNumber <> TempNum 
       sign := 1
    else
       sign := 0

    repeat                                              'Print digits
      if DecimalIndex == DecimalPoint
         gr.text(x,y,@DP)                               'Insert decimal point at proper location
         x := x - spacing
         

      TempNum := DecimalNumber                          'Extract the least significant digit
      TempNum := DecimalNumber - ((TempNum / 10) * 10)

      Digit := $30 + TempNum                            'Display the least significant digit
      gr.text(x,y,@Digit)

      x := x - spacing
      DecimalIndex := DecimalIndex + 1
      DecimalNumber := DecimalNumber / 10               'Divide DecimalNumber by 10 

      if DecimalNumber == 0                             'Exit logic
         repeat while DecimalIndex < DecimalPoint       '   Do this if DecimalNumber is less than where the decimal point should be
            gr.text(x,y,@Zero)
            x := x - spacing
            DecimalIndex := DecimalIndex + 1
            DecimalFlag := 1
         if DecimalIndex == DecimalPoint                '   Set flag if DecimalNumber is equal to where the decimal point should be  
            DecimalFlag := 1   
         if DecimalFlag == 1
            gr.text(x,y,@DP)                            '   Insert decimal and leading Zero
            x := x - spacing
            gr.text(x,y,@Zero)                          
            x := x - spacing                
         if sign == 1                                   '   Restore sign of DecimalNumber
            gr.text(x,y,@Hyphen)
         quit

DAT

Zero                    word    $30
DP                      word    $2E
Hyphen                  word    $2D

tvparams                long    0               'status
                        long    1               'enable
                        long    %001_0101       'pins
                        long    %0000           'mode
                        long    0               'screen
                        long    0               'colors
                        long    x_tiles         'hc
                        long    y_tiles         'vc
                        long    10              'hx
                        long    1               'vx
                        long    0               'ho
                        long    0               'vo
                        long    0               'broadcast
                        long    0               'auralcog

DAT
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