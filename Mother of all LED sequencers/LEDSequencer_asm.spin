{{
OBEX LISTING:
  http://obex.parallax.com/object/399

  This module is a modified copy of my module "Mother of all LED Sequencers"
  In simple terms this software takes bit patterns from memory and passes them to the I/O ports.
  It will work with the Propeller demo Board, The Quickstart board and the PropBOE board.
  It also works with an led driver based on a 74HC595 shift register of my own design
  (See MyLed object for details).The differences between this and the original OBEX module is that
  first this is all spin, second this uses a circular list, and third this is modified to be able
  to wait for an input rather than being strictly timed sequences.

}}
{{        *****      Mother of all Led Pattern Sequencers       *****
          ***** For Demo, Quickstart PropRPM or PropBOE Boards  *****
      
           Copyright Ray Tracy ray0665@tracyfamily.net 2007,2011,2012,2013
              Released under the MIT License - See end of listing for terms.
                 
Update History:
    V1.0   12/30/07 Initial Release
    V1.2   06/08/11 Cleaned up comments
    V1.4   10/13/11 Added Step015 and cleaned up pointer usage
    v1.5   03/26/12 Changed to work with PropBOE and Quickstart.
    v1.6   06/07/13 Cleaned up documentation 

   To reconfigure for the different boards you need to make three changes:
       A) select RotateBits in the constants
       B) select ledmask in the initialized variables section of the dat 
       C) select xormask in the initialized variables section of the dat 
   
   This can be used for sequencing light displays, generating control sequences for animated displays, generate
   wave forms and much more.  With simple changes to the algorythm it can wait for I/O pins to change state such
   as waiting for a switch to open or close before proceeding.  This demo is only using 8 bit patterns, but you
   could use 32 bit patterns. With Clever bit assignments and a little external hardware the number of controlled
   bits can be extended greatly. Staying with my 8 bit example, by assigning 4 bits to address selection/enable
   logic (leaving 4 bits for pattern data) you can select 16 banks of 4 bits or 64 lights.

   Notes about the boards
     Demo and Quickstart boards
        8 Leds are connected to I/O pins 16 to 24
     PropRPM board
        10 Leds are connected to I/O pins 16 to 26
     PropBOE board
        10 Leds are connected to the I/O pins by jumpers, 8 Leds are active high and 2 (D0&D1) are active low
        I have all the LEDs connected to I/O pins 0 to 9 but just to demonstrate, I connected D0&D1 leds to
        pins 8&9. The xormask then has to have a 1 in the pin positions of D0 & D1.

    I originally had just the demo board which has only 8 LEDs so patterns 1 to A have only 8 bits, then I acquired
    the PropRPM board which has 10 LEDs so I added patterns C & D which are 10 bit patterns.  My most recent board
    is the PropBOE which has 10 LEDs but being lazy, I reused all the previous patterns.  For the boards with 10 LEDS
    the last two LEDs are inactive until you get to PatC.  The PropBOE board is a little different you will notice
    that the last two leds appear to be out of sequence because they are connected to I/O pins 8&9.  Pattern E
    was added for the PropBOE board

How It Works:    
   Pattern data is held in a DAT block in memory (all longs). Each sequence consists of a label (for humans), three
   counts, and a variable number of patterns. The first long is the repetition count which controls how many times
   the pattern repeats, a zero count indicates the end of all the pattern data. The second long is the step timing
   for this sequence. The third long is the count of data elements to follow. Subsequent longs, the pattern elements,
   have a one where an LED will be lighted and zero where an LED is off.
   I am showing and using all 32 bits for for this demo program and not rotating the pattern. In reality your patterns
   need contain only bits corresponding to the active LEDs, the actual bits can be rotated to the proper alignment with
   the I/O pins by setting a value for the RotateBits constant. In addition, the actual logic level sent to the I/O line
   can be inverted by changing the constant (xorbits) in the XOR statement in step050.  Put a one in each I/O pin
   position where you want the logic level of the signal inverted.

   Example Pattern Pat1 (See also ledmask below). This sequence has 12 items as follows:
   0.  5         --> Number of pattern repetitions
   1.  $02625A00 --> This is the step time for this pattern (more below)
   2.  9         --> Number of data items 
   3.  $00810000 --> 0000 0000 1000 0001 0000 0000 0000 0000
   4.  $00420000 --> 0000 0000 0100 0010 0000 0000 0000 0000
   5.  $00240000 --> 0000 0000 0010 0100 0000 0000 0000 0000
   6.  $00180000 --> 0000 0000 0001 1000 0000 0000 0000 0000
   7.  $00000000 --> 0000 0000 0000 0000 0000 0000 0000 0000
   8.  $00180000 --> 0000 0000 0001 1000 0000 0000 0000 0000
   9.  $00240000 --> 0000 0000 0010 0100 0000 0000 0000 0000
  10.  $00420000 --> 0000 0000 0100 0010 0000 0000 0000 0000
  11.  $00810000 --> 0000 0000 1000 0001 0000 0000 0000 0000
   This pattern causes the lighted LED's to start at each end
   and move to the center then back to the ends. The step timing
   is the time between pattern elements.

                The Algorithm  (refer also to the data layout above)
                                                                
                                  <START> ---- [ 000 ]------ [ 010 ] ----------------+            
                                                                  |                                 
                                                                  |                     | 
                                                                                       |  LAST
                                                               [ 015 ] -------------[ 100 ]  
                                                                  |              !LAST    
                                                                  |                     | 
                                                                                       |          
                                                  +---------- [ 020 ]                  |                              
                                                                 |                     |
   000:  Entry point and setup                    |               |                     |  
   010:  Setup the first Sequence                 |               |                     |  
   015:  Save Sequence Start                      |                                    |
   020:  Get Sequence Start & Period delay        |            [ 030 ]                  |
   030:  Get the element count                    |               |                     |
   040:  Get next element                         |               |                     |
   050:  Align pattern and turn on LEDs           |                                    |            
   060:  Wait pattern step time                   |     +---- [ 040 ]                  |
   070:  Test for end of current pattern          |     |         |                     |
   080:  Test for end of repetitions              |     |         |                     |
   090:  Get the next pattern                     |     |                              |            
   100:  Test for last pattern                    |     |      [ 050 ]               [ 090 ]
                                                  |     |         |                     |
                                                  |     |         |                     |
                                                  |     |                              |
                                                  |     |      [ 060 ]                  |
                                                  |     |         |                     |
                                                  |     |         |                     |
                                                  |     |  !END                        |            
                                                  |     + ----[ 070 ]                  |            
                                                  |               |  END                |
                                                  |               |                     |            
                                                  |               |                     |            
                                                  |       !END                         |            
                                                  + ----------[ 080 ]---------------- +         
                                                                        END                                 

}}
CON
  _clkmode = xtal1 + pll16x           ' Configure crystal controled clock
  _xinfreq = 5_000_000                ' 5Mhz * 16 = 80Mhz
  Fini = 0
'=======<< choose one of these to match your board. See also, ledmask & xormask below >========
RotateBits    = 0        ' This is for the Demo, PropRPM and Quickstart Board
'RotateBits    = 16       ' This is for the PropBOE Board

VAR
  byte cog

PUB Start
'' Start   Point to the starting pattern and start the asm routine in a seperate cog   
   Stop
   cog := cognew(@Step000,@Pat1)     ' asm routines always start in a new cog
   
PUB Stop
'' Stop    Stops any running cogs    
  if cog
    cogstop(cog)
    
''
''
DAT
        ORG     0
  { Step000 Initialize   }
Step000 or      DIRA, ledmask            ' Set output lines in the direction register
        mov     Time, delay              ' Setup arbitrary initial Delay
        add     Time, cnt                ' Save the starting time

  { Step010 Setup the first sequence }
:Step010
        mov     P1,par                   ' Get data patterns starting address
        rdlong  Reps,P1                  ' Get Repetition count

  { Step015 Save Sequence Start }
:Step015
        mov     SeqStrt,P1               ' Save Sequence start

  { Step020 Get the sequence start & period timing }
:Step020
        mov     P1,SeqStrt               ' Reset to Sequence Start
        add     P1,#4                    ' Advance pointer to sequence timing
        rdlong  Dly,P1                   ' Get sequence timing
        
  { Step030 Get element count }
:Step030
        add     P1,#4                    ' P2 now points to element count
        rdlong  Ectr,P1                  ' Get element count
        
  { Step040 Get next pattern element }
:Step040
        add     P1,#4                    ' Advance pointer to next element
        rdlong  T1,P1                    ' Get the pattern
        
  { Step050 Turn on leds }
:Step050
        rol     T1,#RotateBits           ' Rotate pattern to match lights
        xor     T1,xormask               ' Set logic level for the board in use
        mov     outa,T1                  ' Output the pattern in T1
        
  { Step060 Wait }
:Step060                                 ' wait, until wakeup time, then add Dly
        waitcnt Time, Dly                ' to time which becomes time of next wakeup
        
  { Step070 Test for end of current sequence }
:Step070
        djnz    ECtr,#:step040            ' Go back to Step040 if not done  
                                           
  { Step080 Test for end of repetitions }
:Step080
        djnz    Reps,#:step020            ' Go back to Step020 if not done

  { Step090 Get Next Sequence }
:Step090
        add     P1,#4                    ' Advance pointer to Reps of next sequence
        rdlong  Reps,P1                  ' Get Repetition count
                       
  { Step100 Test for last sequence }
:Step100
        tjz     Reps,#:Step010           ' If end of patterns start all over again
        jmp     #:Step015                ' Repeat This pattern

        
' ===========================================================================================
' in the data below the sequence delay is calculated by dividing clkfreq by the desired period
' and converting to hex  for example: 1/4 second = clkfreq/4 = HEX(80_000_000/4) = $01312D00
'----------------- < I have precalculated some common clock periods here > ----------------
'    1/2  --> $02625A00      1/3 --> $0196E6AA        1/4 --> $01312D00       1/5 --> $00F42400
'    1/6  --> $00C67355      1/7 --> $00AE62DB        1/8 --> $00989680       1/9 --> $0087A238
'   1/10  --> $007A1200     1/16 --> $004C4640       1/20 --> $003D0900      1/25 --> $0030D400
'   1/30  --> $002860AA     1/32 --> $002625A0       1/40 --> $001E8480      1/50 --> $00186A00
'   1/64  --> $001312D0    1/100 --> $000C3500      1/128 --> $00098968     1/200 --> $00061A80
'  1/256  --> $0004C464    1/500 --> $00027100      1/512 --> $0002625A    1/1000 --> $00013880
' 1/1024  --> $0001312D   1/2000 --> $00009C40     1/2048 --> $00009896    1/2500 --> $00007D00

'          ------------ << PATTERN DATA >> ---------------
'
'Label long Repetitions, Delay, NumElements, Element1, Element2, ..., ElementN
'
' One light from each edge to center and back 5 times
Pat1  long  5, $01312D00, 9                   ' 1/4 second
      long  $00810000, $00420000, $00240000, $00180000, $00000000, $00180000, $00240000, $00420000
      long  $00810000
' Two lights from each edge to center and back 5 times
Pat2  long  5, $00989680, 11                   ' 1/8 second
      long  $00810000, $00C30000, $00660000, $003C0000, $00180000, $00000000, $00180000, $003C0000
      long  $00660000, $00C30000, $00810000
' Shift from all off to all on 5 times
Pat3  long  5, $004C4640, 32                   '$002625A0 = 1/32 second
      long  $00010000, $00030000, $00070000, $000F0000, $001F0000, $003F0000, $007F0000, $00FF0000
      long  $00FE0000, $00FC0000, $00F80000, $00F00000, $00E00000, $00C00000, $00800000, $00000000
      long  $00800000, $00C00000, $00E00000, $00F00000, $00F80000, $00FC0000, $00FE0000, $00FF0000
      long  $007F0000, $003F0000, $001F0000, $000F0000, $00070000, $00030000, $00010000, $00000000
' Alternate between left 4 and right four 5 times
Pat4  long  5, $01312D00,  2              '$01312D00 = 1/4 second
      long  $000F0000, $00F00000
' Four lights shifting left and right 5 times
Pat5  long  5, $01312D00,  9
      long  $000F0000, $001E0000, $003C0000, $00780000, $00F00000, $00780000, $003C0000, $001E0000
      long  $000F0000
' Light one at a time from left to right and back 5 times
Pat6  long  5, $01312D00, 16
      long  $00010000, $00020000, $00040000, $00080000, $00100000, $00200000, $00400000, $00800000
      long  $00800000, $00400000, $00200000, $00100000, $00080000, $00040000, $00020000, $00010000
'One light sliding left and right leaving a light on at each direction change till all on and then reverse
Pat7  long  5, $0196E6AA, 57                 
      long  $00800000, $00C00000, $00A00000, $00900000, $00880000, $00840000, $00820000, $00810000
      long  $00830000, $00850000, $00890000, $00910000, $00A10000, $00C10000, $00E10000, $00D10000
      long  $00C90000, $00C50000, $00C30000, $00C70000, $00CB0000, $00D30000, $00E30000, $00F30000
      long  $00EB0000, $00E70000, $00EF0000, $00F70000, $00FF0000, $00F70000, $00EF0000, $00E70000
      long  $00EB0000, $00F30000, $00E30000, $00D30000, $00CB0000, $00C70000, $00C30000, $00C50000
      long  $00C90000, $00D10000, $00E10000, $00C10000, $00A10000, $00910000, $00890000, $00850000
      long  $00830000, $00810000, $00820000, $00840000, $00880000, $00900000, $00A00000, $00C00000
      long  $00800000
' Every other light alternating 5 times
Pat8  long  5, $01312D00,  2
      long  $00AA0000, $00550000
' right four (low nibble) count up 0-15 & left four (high nibble) count down 15-0
Pat9  long  5, $0196E6AA, 16               ' 1/64 second
      long  $00810000, $00420000, $00c30000, $00240000, $00a50000, $00660000, $00e70000, $00180000
      long  $00990000, $005a0000, $00db0000, $003c0000, $00bd0000, $007e0000, $00ff0000, $00000000
' fill from center left and right to the edge and back
PatA  long  1, $0196E6AA,  8
      long  $00180000, $003c0000, $007f0000, $00ff0000, $007f0000, $003c0000, $00180000, $00000000
'left right left right moving towards center each time
PatB  long  30, $0030D400,  8
      long  $00800000, $00010000, $00400000, $00020000, $00200000, $00040000, $00100000, $00080000

' =========< The next three patterns are 10 bits wide for the PropRPM and PropBOE boards >============      

' one on moving from one end to the other and repeat
PatC  long  5, $01312D00, 10
      long  $00010000, $00020000, $00040000, $00080000, $00100000, $00200000, $00400000, $00800000
      long  $01000000, $02000000      
' one off moving from one end to the other and repeat
PatD  long  3, $02625A00, 10                '$02625A00 = 1/2 second
      long  $03FE0000, $03FD0000, $03FB0000, $03F70000, $03EF0000, $03DF0000, $03BF0000, $037F0000
      long  $02FF0000, $01FF0000
PatEnd  long  Fini

' ================< This one was added for my PropBOE board >============

' Blink all Reds all Greens, all Blues, and all Yellows
PatE  long  5, $02625A00, 32                '$02625A00 = 1/2 second
      long  $01C00000, $00000000, $01C00000, $00000000, $01C00000, $00000000, $01C00000, $00000000   ' Reds
      long  $00300000, $00000000, $00300000, $00000000, $00300000, $00000000, $00300000, $00000000   ' Greens
      long  $020C0000, $00000000, $020C0000, $00000000, $020C0000, $00000000, $020C0000, $00000000   ' Blues
      long  $00030000, $00000000, $00030000, $00000000, $00030000, $00000000, $00030000, $00000000   ' Yellows
      long  Fini
      
' This marks the end of all the patterns
'PatEnd  long  Fini

'  We can generate waveforms too:
' Generate this waveform by passing Wave as the starting pattern. Set RotateBits and ledmask as desired.
' For a 10 millisecond period waveform, the timing word is 72_727 clocks calculated as follows:
'   72_727 = clkfreq * period (seconds)/element count = 80_000_000*0.010/11
'       <-- channel 1, I/O Pin n
'       <-- channel 2, 10 ms rising edge to rising edge, I/O Pin n+1
Wave    long  6_000_000, 72_727, 11         ' 10ms waveform for 60 seconds
        long  1,0,0,1,0,0,1,3,1,0,0
        long  0

'   INITIALIZED VARIABLES        
delay   long  $01312D00         ' Totally arbitrary startup delay

'=======<< choose one of these to match the board you are using >========
ledmask  long $00FF0000         ' Demo and Quickstart Boards 8 LED's at I/O pins 16 to 23
xormask  long $00000000         ' XOR mask for Demo & Quickstart boards
'ledmask  long $03FF0000         ' PropRPM 10 LED's at I/O pins 16 to 25
'xormask  long $03FF0000         ' XOR mask for PropRPM board
'ledmask  long $000003FF         ' PropBOE Board 10 LEDs at I/O pins 0 to 9 set jumpers accordingly
'xormask  long $00000300         ' XOR mask for PropBOE board

'   UNINITIALIZED VARIABLES
P1      res   1         'Working pointer
SeqStrt res   1         'Current Sequence start address
ECtr    res   1         'Element counter
Reps    res   1         'Element repetition count
Dly     res   1         'Sequence Timing clock period
Time    res   1         'Holds the next wakeup time
T1      res   1         'Temp variable
        FIT

{{


                               TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject
to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}}        
