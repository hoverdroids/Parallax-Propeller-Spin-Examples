''This code example is from Propeller Education Kit Labs: Fundamentals, v1.2.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
{{
CountEdgeTest.spin
Transmit NCO signal with Counter A 
Use Counter B to keep track of the signal's negative edges and stop the signal
after 2000.
}}

CON
   
  _clkmode = xtal1 + pll16x                   'System clock → 80 MHz
  _xinfreq = 5_000_000

OBJ
   
  SqrWave      : "SquareWave"

PUB TestFrequency 
  
  ' Configure counter modules.

  ctra[30..26] := %00100                     'ctra module to NCO mode
  ctra[5..0] := 27               

  ctrb[30..26] := %01110                     'ctrb module to NEGEDGE detector         
  ctrb[8..0] := 27
  frqb~
  phsb~

  'Transmit signal for 2000 NCO signal cycles

  outa[27]~                                  ' P27 → output-low 
  dira[27]~~ 

  frqb := 1                                  ' Start the signal
  frqa := SqrWave.NcoFrqReg(2000) 

  repeat while phsb < 2000                   ' Wait for 2 k reps    

  frqa~                                      ' Stop the signal